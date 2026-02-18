#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

STORY_OP_SCRIPT="scripts/story-op.sh"
INCIDENT_SCRIPT="scripts/incident-learn.sh"
CONTEXT_SCRIPT="scripts/context-brief.sh"

usage() {
  cat <<'USAGE'
Unified workflow CLI for agent and human execution.

Usage:
  ./scripts/workflow.sh context brief
  ./scripts/workflow.sh story ready [--json]
  ./scripts/workflow.sh story start --story US-XXX [--owner <name>] [--note "..."] [--json]
  ./scripts/workflow.sh story done --story US-XXX --summary "..." [--json]
  ./scripts/workflow.sh story block --story US-XXX --reason "..." [--json]

  ./scripts/workflow.sh incident learn --story US-XXX --title "..." --signal "..." \
    --root-cause "..." --correction "..." --prevention-rule "..." --checks "..." [--with-snapshot]
  ./scripts/workflow.sh incident list [--limit N]
  ./scripts/workflow.sh incident rules [--limit N]
  ./scripts/workflow.sh incident show INC-YYYYMMDD-HHMMSS

  ./scripts/workflow.sh doctor [--json]

  ./scripts/workflow.sh llm providers
  ./scripts/workflow.sh llm prompt --provider openai --prompt "..." [--model gpt-5.2] [--system "..."] [--json]
  ./scripts/workflow.sh llm prompt --provider llm --prompt "..." [--model <model>] [--system "..."]

Notes:
- Story operations and incident logging remain delegated to existing scripts.
- Use explicit commands; no implicit git hooks mutate planning state.
USAGE
}

die() {
  echo "ERROR: $*" >&2
  exit 1
}

require_exec() {
  local path="$1"
  [[ -x "$path" ]] || die "missing executable: $path"
}

file_has_line_regex() {
  local pattern="$1"
  local file="$2"
  if command -v rg >/dev/null 2>&1; then
    rg -q "$pattern" "$file"
  else
    grep -Eq "$pattern" "$file"
  fi
}

json_escape() {
  local s="$1"
  s=${s//\\/\\\\}
  s=${s//\"/\\\"}
  s=${s//$'\n'/\\n}
  s=${s//$'\r'/\\r}
  s=${s//$'\t'/\\t}
  printf '%s' "$s"
}

doctor_run() {
  local as_json="false"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --json)
        as_json="true"
        shift
        ;;
      *)
        die "unknown doctor argument: $1"
        ;;
    esac
  done

  local -a errors=()
  local error_count=0

  add_error() {
    local msg="$1"
    errors+=("$msg")
    error_count=$((error_count + 1))
  }

  if [[ ! -x "$STORY_OP_SCRIPT" ]]; then
    add_error "missing_executable:scripts/story-op.sh"
  fi
  if [[ ! -x "$INCIDENT_SCRIPT" ]]; then
    add_error "missing_executable:scripts/incident-learn.sh"
  fi
  if [[ ! -x "$CONTEXT_SCRIPT" ]]; then
    add_error "missing_executable:scripts/context-brief.sh"
  fi

  if [[ ! -f docs/epic.md ]]; then
    add_error "missing_file:docs/epic.md"
  else
    if ! file_has_line_regex '^<!-- STORY_INDEX_START -->$' docs/epic.md; then
      add_error "missing_marker:docs/epic.md:STORY_INDEX_START"
    fi
    if ! file_has_line_regex '^<!-- STORY_INDEX_END -->$' docs/epic.md; then
      add_error "missing_marker:docs/epic.md:STORY_INDEX_END"
    fi
  fi

  if [[ ! -f progress.md ]]; then
    add_error "missing_file:progress.md"
  else
    for section in '^## Done$' '^## Inactive / Blocked$' '^## Needs Rework$'; do
      if ! file_has_line_regex "$section" progress.md; then
        add_error "missing_section:progress.md:${section}"
      fi
    done
  fi

  if [[ -x "$STORY_OP_SCRIPT" && -f docs/epic.md ]]; then
    if ! ./scripts/story-op.sh ready --json >/dev/null 2>&1; then
      add_error "story_op_ready_failed"
    fi
  fi

  if [[ "$as_json" == "true" ]]; then
    printf '{'
    if [[ $error_count -eq 0 ]]; then
      printf '"ok":true,'
    else
      printf '"ok":false,'
    fi
    printf '"errors":['
    if [[ $error_count -gt 0 ]]; then
      local first=1
      local e
      for e in "${errors[@]}"; do
        if [[ $first -eq 0 ]]; then
          printf ','
        fi
        first=0
        printf '"%s"' "$(json_escape "$e")"
      done
    fi
    printf ']}'
    printf '\n'
  else
    if [[ $error_count -eq 0 ]]; then
      echo "workflow doctor: ok"
    else
      echo "workflow doctor: failed"
      local e
      for e in "${errors[@]}"; do
        echo "- ${e}"
      done
    fi
  fi

  [[ $error_count -eq 0 ]]
}

llm_providers() {
  cat <<'EOF_PROVIDERS'
Supported providers:
- openai  (direct Responses API call via curl + OPENAI_API_KEY)
- llm     (delegates to Simon Willison's llm CLI)
EOF_PROVIDERS
}

llm_prompt_openai() {
  local prompt="$1"
  local model="$2"
  local system="$3"
  local as_json="$4"

  command -v curl >/dev/null 2>&1 || die "curl is required for --provider openai"
  command -v jq >/dev/null 2>&1 || die "jq is required for --provider openai"
  [[ -n "${OPENAI_API_KEY:-}" ]] || die "OPENAI_API_KEY is required for --provider openai"

  local payload
  payload="$(jq -n \
    --arg model "$model" \
    --arg prompt "$prompt" \
    --arg system "$system" '
    {
      model: $model,
      input: [
        {
          role: "user",
          content: [
            {type: "input_text", text: $prompt}
          ]
        }
      ]
    }
    + (if ($system|length) > 0 then {instructions: $system} else {} end)
  ')"

  local response
  response="$(curl -sS -L 'https://api.openai.com/v1/responses' \
    -H 'Content-Type: application/json' \
    -H "Authorization: Bearer $OPENAI_API_KEY" \
    -d "$payload")"

  if [[ "$as_json" == "true" ]]; then
    printf '%s\n' "$response"
  else
    printf '%s\n' "$response" | jq -r '.output_text // ""'
  fi
}

llm_prompt_llm_cli() {
  local prompt="$1"
  local model="$2"
  local system="$3"

  command -v llm >/dev/null 2>&1 || die "llm CLI is required for --provider llm"

  local -a cmd=(llm)
  if [[ -n "$model" ]]; then
    cmd+=(-m "$model")
  fi
  if [[ -n "$system" ]]; then
    cmd+=(-s "$system")
  fi
  cmd+=("$prompt")

  "${cmd[@]}"
}

llm_prompt() {
  local provider="${WORKFLOW_LLM_PROVIDER:-openai}"
  local model=""
  local prompt=""
  local system=""
  local as_json="false"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --provider)
        provider="$2"
        shift 2
        ;;
      --model)
        model="$2"
        shift 2
        ;;
      --prompt)
        prompt="$2"
        shift 2
        ;;
      --system)
        system="$2"
        shift 2
        ;;
      --json)
        as_json="true"
        shift
        ;;
      *)
        die "unknown llm prompt argument: $1"
        ;;
    esac
  done

  if [[ -z "$prompt" ]]; then
    if [[ -t 0 ]]; then
      die "llm prompt requires --prompt or stdin"
    fi
    prompt="$(cat)"
  fi

  case "$provider" in
    openai)
      if [[ -z "$model" ]]; then
        model="gpt-5.2"
      fi
      llm_prompt_openai "$prompt" "$model" "$system" "$as_json"
      ;;
    llm)
      if [[ "$as_json" == "true" ]]; then
        die "--json is only supported for --provider openai"
      fi
      llm_prompt_llm_cli "$prompt" "$model" "$system"
      ;;
    *)
      die "unsupported provider: ${provider}. Use './scripts/workflow.sh llm providers'."
      ;;
  esac
}

main() {
  [[ $# -ge 1 ]] || {
    usage
    exit 1
  }

  local group="$1"
  shift

  case "$group" in
    context)
      local cmd="${1:-}"
      [[ -n "$cmd" ]] || die "context requires a command (brief)"
      shift
      case "$cmd" in
        brief)
          require_exec "$CONTEXT_SCRIPT"
          "$CONTEXT_SCRIPT" "$@"
          ;;
        *)
          die "unknown context command: $cmd"
          ;;
      esac
      ;;

    story)
      require_exec "$STORY_OP_SCRIPT"
      local cmd="${1:-}"
      [[ -n "$cmd" ]] || die "story requires a command (ready|start|done|block)"
      shift
      "$STORY_OP_SCRIPT" "$cmd" "$@"
      ;;

    incident)
      require_exec "$INCIDENT_SCRIPT"
      local cmd="${1:-}"
      [[ -n "$cmd" ]] || die "incident requires a command (learn|list|rules|show)"
      shift
      case "$cmd" in
        learn)
          "$INCIDENT_SCRIPT" "$@"
          ;;
        list)
          "$INCIDENT_SCRIPT" --list "$@"
          ;;
        rules)
          "$INCIDENT_SCRIPT" --list-rules "$@"
          ;;
        show)
          local id="${1:-}"
          [[ -n "$id" ]] || die "incident show requires incident id"
          shift
          "$INCIDENT_SCRIPT" --show "$id" "$@"
          ;;
        *)
          die "unknown incident command: $cmd"
          ;;
      esac
      ;;

    doctor)
      doctor_run "$@"
      ;;

    llm)
      local cmd="${1:-}"
      [[ -n "$cmd" ]] || die "llm requires a command (providers|prompt)"
      shift
      case "$cmd" in
        providers)
          llm_providers
          ;;
        prompt)
          llm_prompt "$@"
          ;;
        *)
          die "unknown llm command: $cmd"
          ;;
      esac
      ;;

    help|-h|--help)
      usage
      ;;

    *)
      die "unknown command group: ${group}"
      ;;
  esac
}

main "$@"
