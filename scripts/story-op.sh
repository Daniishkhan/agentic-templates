#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

EPIC_FILE="${STORY_OP_EPIC_FILE:-docs/epic.md}"
PROGRESS_FILE="${STORY_OP_PROGRESS_FILE:-progress.md}"

usage() {
  cat <<'USAGE'
Closed-vocabulary story operations for docs/epic.md.

Usage:
  ./scripts/story-op.sh ready [--json]
  ./scripts/story-op.sh start --story US-XXX [--owner <name>] [--note "..."] [--json]
  ./scripts/story-op.sh done --story US-XXX --summary "..." [--json]
  ./scripts/story-op.sh block --story US-XXX --reason "..." [--json]

Environment overrides (for testing):
  STORY_OP_EPIC_FILE
  STORY_OP_PROGRESS_FILE
USAGE
}

error() {
  echo "ERROR: $*" >&2
  exit 1
}

require_file() {
  local file="$1"
  [[ -f "$file" ]] || error "file not found: $file"
}

sanitize_single_line() {
  local text="$1"
  text="${text//$'\n'/ }"
  text="${text//$'\r'/ }"
  # shellcheck disable=SC2001
  text="$(printf '%s' "$text" | sed 's/[[:space:]]\+/ /g; s/^ //; s/ $//')"
  printf '%s' "$text"
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

utc_timestamp() {
  date -u '+%Y-%m-%dT%H:%M:%SZ'
}

today_date() {
  date '+%Y-%m-%d'
}

ensure_progress_section() {
  local section="$1"
  require_file "$PROGRESS_FILE"
  if command -v rg >/dev/null 2>&1; then
    if ! rg -q "^${section}$" "$PROGRESS_FILE"; then
      error "missing progress section: ${section} in ${PROGRESS_FILE}"
    fi
  else
    if ! grep -q "^${section}$" "$PROGRESS_FILE"; then
      error "missing progress section: ${section} in ${PROGRESS_FILE}"
    fi
  fi
}

get_story_index_row() {
  local target_story="$1"
  awk -v target="$target_story" '
    function trim(s) {
      sub(/^[ \t]+/, "", s)
      sub(/[ \t]+$/, "", s)
      return s
    }
    BEGIN {
      in_index = 0
      in_fence = 0
      saw_start = 0
      saw_end = 0
      cur_id = ""
      cur_title = ""
      cur_status = ""
      cur_deps = ""
    }
    function flush_story() {
      if (cur_id == target) {
        print cur_id "\t" cur_status "\t" cur_title "\t" cur_deps
        found = 1
      }
      cur_id = ""
      cur_title = ""
      cur_status = ""
      cur_deps = ""
    }
    /^<!-- STORY_INDEX_START -->[ \t]*$/ {
      saw_start = 1
      in_index = 1
      next
    }
    /^<!-- STORY_INDEX_END -->[ \t]*$/ {
      saw_end = 1
      if (in_index) {
        flush_story()
      }
      in_index = 0
      in_fence = 0
      next
    }
    !in_index {
      next
    }
    in_index && /^```/ {
      if (in_fence == 0) {
        in_fence = 1
      } else {
        in_fence = 0
      }
      next
    }
    !in_fence {
      next
    }
    {
      if ($0 ~ /^[ \t]*-[ \t]*id:[ \t]*[A-Za-z0-9.-]+/) {
        flush_story()
        cur_id = $0
        sub(/^[ \t]*-[ \t]*id:[ \t]*/, "", cur_id)
        sub(/[ \t].*$/, "", cur_id)
        next
      }
      if (cur_id == "") {
        next
      }
      if ($0 ~ /^[ \t]*title:[ \t]*/) {
        cur_title = $0
        sub(/^[ \t]*title:[ \t]*/, "", cur_title)
        cur_title = trim(cur_title)
        next
      }
      if ($0 ~ /^[ \t]*status:[ \t]*[a-z-]+/) {
        cur_status = $0
        sub(/^[ \t]*status:[ \t]*/, "", cur_status)
        sub(/[ \t].*$/, "", cur_status)
        next
      }
      if ($0 ~ /^[ \t]*depends_on:[ \t]*\[[^]]*\][ \t]*$/) {
        deps = $0
        sub(/^[ \t]*depends_on:[ \t]*\[/, "", deps)
        sub(/\][ \t]*$/, "", deps)
        deps = trim(deps)
        gsub(/[ \t]/, "", deps)
        cur_deps = deps
        next
      }
    }
    END {
      if (!saw_start || !saw_end) {
        print "ERROR: missing STORY_INDEX markers in " FILENAME > "/dev/stderr"
        exit 3
      }
      if (!found) {
        exit 4
      }
    }
  ' "$EPIC_FILE"
}

list_ready_tsv() {
  awk '
    function trim(s) {
      sub(/^[ \t]+/, "", s)
      sub(/[ \t]+$/, "", s)
      return s
    }
    BEGIN {
      in_index = 0
      in_fence = 0
      saw_start = 0
      saw_end = 0
      cur_id = ""
      cur_title = ""
      cur_status = ""
      cur_deps = ""
      n = 0
    }
    function flush_story() {
      if (cur_id != "") {
        n++
        order[n] = cur_id
        title[cur_id] = cur_title
        status[cur_id] = cur_status
        deps_on[cur_id] = cur_deps
      }
      cur_id = ""
      cur_title = ""
      cur_status = ""
      cur_deps = ""
    }
    /^<!-- STORY_INDEX_START -->[ \t]*$/ {
      saw_start = 1
      in_index = 1
      next
    }
    /^<!-- STORY_INDEX_END -->[ \t]*$/ {
      saw_end = 1
      if (in_index) {
        flush_story()
      }
      in_index = 0
      in_fence = 0
      next
    }
    !in_index {
      next
    }
    in_index && /^```/ {
      if (in_fence == 0) {
        in_fence = 1
      } else {
        in_fence = 0
      }
      next
    }
    !in_fence {
      next
    }
    {
      if ($0 ~ /^[ \t]*-[ \t]*id:[ \t]*[A-Za-z0-9.-]+/) {
        flush_story()
        cur_id = $0
        sub(/^[ \t]*-[ \t]*id:[ \t]*/, "", cur_id)
        sub(/[ \t].*$/, "", cur_id)
        next
      }
      if (cur_id == "") {
        next
      }
      if ($0 ~ /^[ \t]*title:[ \t]*/) {
        cur_title = $0
        sub(/^[ \t]*title:[ \t]*/, "", cur_title)
        cur_title = trim(cur_title)
        next
      }
      if ($0 ~ /^[ \t]*status:[ \t]*[a-z-]+/) {
        cur_status = $0
        sub(/^[ \t]*status:[ \t]*/, "", cur_status)
        sub(/[ \t].*$/, "", cur_status)
        next
      }
      if ($0 ~ /^[ \t]*depends_on:[ \t]*\[[^]]*\][ \t]*$/) {
        deps = $0
        sub(/^[ \t]*depends_on:[ \t]*\[/, "", deps)
        sub(/\][ \t]*$/, "", deps)
        deps = trim(deps)
        gsub(/[ \t]/, "", deps)
        cur_deps = deps
        next
      }
    }
    END {
      if (!saw_start || !saw_end) {
        print "ERROR: missing STORY_INDEX markers in " FILENAME > "/dev/stderr"
        exit 3
      }

      for (i = 1; i <= n; i++) {
        id = order[i]
        if (status[id] != "ready") {
          continue
        }

        deps = deps_on[id]
        ready = 1
        if (deps != "") {
          dep_count = split(deps, dep_arr, ",")
          for (d = 1; d <= dep_count; d++) {
            dep = dep_arr[d]
            gsub(/[ \t]/, "", dep)
            if (dep == "") {
              continue
            }
            if (status[dep] != "done") {
              ready = 0
              break
            }
          }
        }

        if (ready) {
          print id "\t" title[id] "\t" deps_on[id]
        }
      }
    }
  ' "$EPIC_FILE"
}

validate_story_id() {
  local story="$1"
  [[ "$story" =~ ^US-[0-9A-Za-z-]+$ ]] || error "invalid story id: ${story} (expected US-XXX)"
}

validate_transition() {
  local op="$1"
  local from_status="$2"
  local to_status="$3"

  case "$op" in
    start)
      [[ "$to_status" == "in-progress" ]] || error "internal error: start target must be in-progress"
      case "$from_status" in
        ready|backlog|blocked) ;;
        *) error "illegal transition for ${op}: ${from_status} -> ${to_status}" ;;
      esac
      ;;
    done)
      [[ "$to_status" == "done" ]] || error "internal error: done target must be done"
      case "$from_status" in
        in-progress|ready) ;;
        *) error "illegal transition for ${op}: ${from_status} -> ${to_status}" ;;
      esac
      ;;
    block)
      [[ "$to_status" == "blocked" ]] || error "internal error: block target must be blocked"
      case "$from_status" in
        ready|in-progress) ;;
        *) error "illegal transition for ${op}: ${from_status} -> ${to_status}" ;;
      esac
      ;;
    *)
      error "unknown operation for transition validation: ${op}"
      ;;
  esac
}

update_epic_story() {
  local target_story="$1"
  local new_status="$2"
  local owner_value="${3:-}"
  local owner_set="false"
  local tmp

  if [[ -n "$owner_value" ]]; then
    owner_set="true"
  fi

  tmp="$(mktemp "${EPIC_FILE}.tmp.XXXXXX")"

  awk -v target="$target_story" -v to_status="$new_status" -v owner_set="$owner_set" -v owner_value="$owner_value" '
    function fail(msg, code) {
      print "ERROR: " msg > "/dev/stderr"
      exit code
    }

    BEGIN {
      in_index = 0
      in_fence = 0
      saw_start = 0
      saw_end = 0

      idx_cur = ""
      idx_found = 0
      idx_status_updated = 0
      idx_owner_updated = 0

      heading_id = ""
      in_target_story = 0
      after_story_meta = 0
      in_meta_yaml = 0
      meta_status_updated = 0
      meta_owner_updated = 0
    }

    {
      line = $0

      if (line ~ /^<!-- STORY_INDEX_START -->[ \t]*$/) {
        saw_start = 1
        in_index = 1
        print line
        next
      }

      if (line ~ /^<!-- STORY_INDEX_END -->[ \t]*$/) {
        saw_end = 1
        in_index = 0
        in_fence = 0
        idx_cur = ""
        print line
        next
      }

      if (in_index) {
        if (line ~ /^```/) {
          if (in_fence == 0) {
            in_fence = 1
          } else {
            in_fence = 0
          }
          print line
          next
        }

        if (in_fence && line ~ /^[ \t]*-[ \t]*id:[ \t]*US-[0-9A-Za-z-]+/) {
          idx_cur = line
          sub(/^[ \t]*-[ \t]*id:[ \t]*/, "", idx_cur)
          sub(/[ \t].*$/, "", idx_cur)
          if (idx_cur == target) {
            idx_found = 1
          }
          print line
          next
        }

        if (in_fence && idx_cur == target && line ~ /^[ \t]*status:[ \t]*[a-z-]+[ \t]*$/) {
          status_indent = line
          sub(/status:.*/, "", status_indent)
          print status_indent "status: " to_status
          idx_status_updated = 1
          next
        }

        if (owner_set == "true" && in_fence && idx_cur == target && line ~ /^[ \t]*owner:[ \t]*.*$/) {
          owner_indent = line
          sub(/owner:.*/, "", owner_indent)
          print owner_indent "owner: " owner_value
          idx_owner_updated = 1
          next
        }

        print line
        next
      }

      if (line ~ /^##[ \t]+US-[0-9A-Za-z-]+/) {
        heading_id = line
        sub(/^##[ \t]+/, "", heading_id)
        sub(/[ \t].*$/, "", heading_id)
        in_target_story = (heading_id == target)
        after_story_meta = 0
        in_meta_yaml = 0
      }

      if (in_target_story) {
        if (line ~ /^\*\*Story Meta\*\*[ \t]*$/) {
          after_story_meta = 1
          print line
          next
        }

        if (after_story_meta && line ~ /^```yaml[ \t]*$/) {
          in_meta_yaml = 1
          print line
          next
        }

        if (in_meta_yaml && line ~ /^```[ \t]*$/) {
          in_meta_yaml = 0
          after_story_meta = 0
          print line
          next
        }

        if (in_meta_yaml && line ~ /^[ \t]*status:[ \t]*[a-z-]+[ \t]*$/) {
          meta_status_indent = line
          sub(/status:.*/, "", meta_status_indent)
          print meta_status_indent "status: " to_status
          meta_status_updated = 1
          next
        }

        if (owner_set == "true" && in_meta_yaml && line ~ /^[ \t]*owner:[ \t]*.*$/) {
          meta_owner_indent = line
          sub(/owner:.*/, "", meta_owner_indent)
          print meta_owner_indent "owner: " owner_value
          meta_owner_updated = 1
          next
        }
      }

      print line
    }

    END {
      if (!saw_start || !saw_end) {
        fail("missing STORY_INDEX markers in epic file", 21)
      }
      if (!idx_found) {
        fail("story " target " not found in Story Index", 22)
      }
      if (!idx_status_updated) {
        fail("status line not found for " target " in Story Index", 23)
      }
      if (!meta_status_updated) {
        fail("status line not found for " target " in Story Meta", 24)
      }
      if (owner_set == "true" && !idx_owner_updated) {
        fail("owner line not found for " target " in Story Index", 25)
      }
      if (owner_set == "true" && !meta_owner_updated) {
        fail("owner line not found for " target " in Story Meta", 26)
      }
    }
  ' "$EPIC_FILE" > "$tmp" || {
    rm -f "$tmp"
    return 1
  }

  mv "$tmp" "$EPIC_FILE"
}

append_progress_line() {
  local section_heading="$1"
  local line_to_append="$2"
  local tmp

  tmp="$(mktemp "${PROGRESS_FILE}.tmp.XXXXXX")"

  awk -v section="$section_heading" -v entry="$line_to_append" '
    BEGIN {
      found = 0
      in_section = 0
      inserted = 0
    }

    $0 == section {
      found = 1
      in_section = 1
      print
      next
    }

    in_section && /^## / {
      if (!inserted) {
        print entry
        inserted = 1
      }
      in_section = 0
      print
      next
    }

    {
      print
    }

    END {
      if (!found) {
        print "ERROR: missing section " section " in progress file" > "/dev/stderr"
        exit 31
      }
      if (found && !inserted) {
        print entry
      }
    }
  ' "$PROGRESS_FILE" > "$tmp" || {
    rm -f "$tmp"
    return 1
  }

  mv "$tmp" "$PROGRESS_FILE"
}

emit_mutation_json() {
  local story="$1"
  local from_status="$2"
  local to_status="$3"
  local files_csv="$4"

  local ts
  ts="$(utc_timestamp)"

  printf '{'
  printf '"story":"%s",' "$(json_escape "$story")"
  printf '"from":"%s",' "$(json_escape "$from_status")"
  printf '"to":"%s",' "$(json_escape "$to_status")"
  printf '"updated_files":['

  local first=1
  local file
  IFS=',' read -r -a _files <<< "$files_csv"
  for file in "${_files[@]}"; do
    if [[ $first -eq 0 ]]; then
      printf ','
    fi
    first=0
    printf '"%s"' "$(json_escape "$file")"
  done

  printf '],'
  printf '"timestamp":"%s"' "$(json_escape "$ts")"
  printf '}'
  printf '\n'
}

handle_ready() {
  local as_json="false"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --json)
        as_json="true"
        shift
        ;;
      --epic-file)
        EPIC_FILE="$2"
        shift 2
        ;;
      *)
        error "unknown argument for ready: $1"
        ;;
    esac
  done

  require_file "$EPIC_FILE"

  local tsv
  tsv="$(list_ready_tsv)"

  if [[ "$as_json" == "true" ]]; then
    printf '['
    local first_story=1
    while IFS=$'\t' read -r id title deps; do
      [[ -z "$id" ]] && continue
      if [[ $first_story -eq 0 ]]; then
        printf ','
      fi
      first_story=0

      printf '{'
      printf '"id":"%s",' "$(json_escape "$id")"
      printf '"title":"%s",' "$(json_escape "$title")"
      printf '"status":"ready",'
      printf '"depends_on":['

      local first_dep=1
      local dep
      IFS=',' read -r -a _deps <<< "$deps"
      for dep in "${_deps[@]}"; do
        [[ -z "$dep" ]] && continue
        if [[ $first_dep -eq 0 ]]; then
          printf ','
        fi
        first_dep=0
        printf '"%s"' "$(json_escape "$dep")"
      done

      printf ']'
      printf '}'
    done <<< "$tsv"

    printf ']\n'
    return 0
  fi

  if [[ -z "$tsv" ]]; then
    echo "(no ready stories)"
    return 0
  fi

  echo "Ready stories:"
  while IFS=$'\t' read -r id title deps; do
    [[ -z "$id" ]] && continue
    if [[ -n "$deps" ]]; then
      echo "- ${id}: ${title} (depends_on: [${deps}])"
    else
      echo "- ${id}: ${title}"
    fi
  done <<< "$tsv"
}

handle_start() {
  local story=""
  local owner=""
  local note=""
  local as_json="false"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --story)
        story="$2"
        shift 2
        ;;
      --owner)
        owner="$2"
        shift 2
        ;;
      --note)
        note="$2"
        shift 2
        ;;
      --json)
        as_json="true"
        shift
        ;;
      --epic-file)
        EPIC_FILE="$2"
        shift 2
        ;;
      --progress-file)
        PROGRESS_FILE="$2"
        shift 2
        ;;
      *)
        error "unknown argument for start: $1"
        ;;
    esac
  done

  [[ -n "$story" ]] || error "start requires --story US-XXX"
  validate_story_id "$story"
  require_file "$EPIC_FILE"

  local row
  if ! row="$(get_story_index_row "$story")"; then
    error "story not found in Story Index: ${story}"
  fi

  local _id from_status _title _deps
  IFS=$'\t' read -r _id from_status _title _deps <<< "$row"

  validate_transition "start" "$from_status" "in-progress"

  update_epic_story "$story" "in-progress" "$owner"

  if [[ "$as_json" == "true" ]]; then
    emit_mutation_json "$story" "$from_status" "in-progress" "$EPIC_FILE"
  else
    echo "Updated ${story}: ${from_status} -> in-progress"
    if [[ -n "$owner" ]]; then
      echo "Owner set to: ${owner}"
    fi
    if [[ -n "$note" ]]; then
      echo "Note: $(sanitize_single_line "$note")"
    fi
  fi
}

handle_done() {
  local story=""
  local summary=""
  local as_json="false"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --story)
        story="$2"
        shift 2
        ;;
      --summary)
        summary="$2"
        shift 2
        ;;
      --json)
        as_json="true"
        shift
        ;;
      --epic-file)
        EPIC_FILE="$2"
        shift 2
        ;;
      --progress-file)
        PROGRESS_FILE="$2"
        shift 2
        ;;
      *)
        error "unknown argument for done: $1"
        ;;
    esac
  done

  [[ -n "$story" ]] || error "done requires --story US-XXX"
  [[ -n "$summary" ]] || error "done requires --summary"
  validate_story_id "$story"

  require_file "$EPIC_FILE"
  ensure_progress_section "## Done"

  local row
  if ! row="$(get_story_index_row "$story")"; then
    error "story not found in Story Index: ${story}"
  fi

  local _id from_status _title _deps
  IFS=$'\t' read -r _id from_status _title _deps <<< "$row"

  validate_transition "done" "$from_status" "done"

  update_epic_story "$story" "done"

  local day summary_line
  day="$(today_date)"
  summary_line="- ${day} ${story}: $(sanitize_single_line "$summary")"
  append_progress_line "## Done" "$summary_line"

  if [[ "$as_json" == "true" ]]; then
    emit_mutation_json "$story" "$from_status" "done" "$EPIC_FILE,$PROGRESS_FILE"
  else
    echo "Updated ${story}: ${from_status} -> done"
    echo "Progress updated in ${PROGRESS_FILE}"
  fi
}

handle_block() {
  local story=""
  local reason=""
  local as_json="false"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --story)
        story="$2"
        shift 2
        ;;
      --reason)
        reason="$2"
        shift 2
        ;;
      --json)
        as_json="true"
        shift
        ;;
      --epic-file)
        EPIC_FILE="$2"
        shift 2
        ;;
      --progress-file)
        PROGRESS_FILE="$2"
        shift 2
        ;;
      *)
        error "unknown argument for block: $1"
        ;;
    esac
  done

  [[ -n "$story" ]] || error "block requires --story US-XXX"
  [[ -n "$reason" ]] || error "block requires --reason"
  validate_story_id "$story"

  require_file "$EPIC_FILE"
  ensure_progress_section "## Inactive / Blocked"

  local row
  if ! row="$(get_story_index_row "$story")"; then
    error "story not found in Story Index: ${story}"
  fi

  local _id from_status _title _deps
  IFS=$'\t' read -r _id from_status _title _deps <<< "$row"

  validate_transition "block" "$from_status" "blocked"

  update_epic_story "$story" "blocked"

  local day reason_line
  day="$(today_date)"
  reason_line="- ${day} ${story}: $(sanitize_single_line "$reason")"
  append_progress_line "## Inactive / Blocked" "$reason_line"

  if [[ "$as_json" == "true" ]]; then
    emit_mutation_json "$story" "$from_status" "blocked" "$EPIC_FILE,$PROGRESS_FILE"
  else
    echo "Updated ${story}: ${from_status} -> blocked"
    echo "Progress updated in ${PROGRESS_FILE}"
  fi
}

main() {
  [[ $# -ge 1 ]] || {
    usage
    exit 1
  }

  local cmd="$1"
  shift

  case "$cmd" in
    ready)
      handle_ready "$@"
      ;;
    start)
      handle_start "$@"
      ;;
    done)
      handle_done "$@"
      ;;
    block)
      handle_block "$@"
      ;;
    -h|--help|help)
      usage
      ;;
    *)
      error "unknown command: ${cmd}"
      ;;
  esac
}

main "$@"
