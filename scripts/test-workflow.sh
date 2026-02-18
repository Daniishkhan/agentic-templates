#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORKFLOW="$ROOT_DIR/scripts/workflow.sh"
BASE_EPIC="$ROOT_DIR/docs/epic.md"
BASE_PROGRESS="$ROOT_DIR/progress.md"

[[ -x "$WORKFLOW" ]] || {
  echo "workflow script not found or not executable: $WORKFLOW" >&2
  exit 1
}

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

assert_contains() {
  local haystack="$1"
  local needle="$2"
  local msg="$3"
  if [[ "$haystack" != *"$needle"* ]]; then
    echo "ASSERTION FAILED: $msg" >&2
    echo "expected to contain: $needle" >&2
    echo "in: $haystack" >&2
    exit 1
  fi
}

run_workflow() {
  local epic_file="$1"
  local progress_file="$2"
  shift 2

  STORY_OP_EPIC_FILE="$epic_file" STORY_OP_PROGRESS_FILE="$progress_file" "$WORKFLOW" "$@"
}

new_fixture() {
  local dir="$TMP_DIR/fx"
  mkdir -p "$dir"
  cp "$BASE_EPIC" "$dir/epic.md"
  cp "$BASE_PROGRESS" "$dir/progress.md"
  echo "$dir"
}

echo "[1/4] workflow story passthrough"
F1="$(new_fixture)"
READY_JSON="$(run_workflow "$F1/epic.md" "$F1/progress.md" story ready --json)"
assert_contains "$READY_JSON" '[' "story ready returns json array"
run_workflow "$F1/epic.md" "$F1/progress.md" story start --story US-000 >/dev/null
DONE_JSON="$(run_workflow "$F1/epic.md" "$F1/progress.md" story done --story US-000 --summary "done via workflow" --json)"
assert_contains "$DONE_JSON" '"story":"US-000"' "story done should return mutation json"

echo "[2/4] workflow doctor"
DOCTOR_JSON="$(cd "$ROOT_DIR" && ./scripts/workflow.sh doctor --json)"
assert_contains "$DOCTOR_JSON" '"ok":true' "doctor should pass on template"

echo "[3/4] workflow llm providers"
PROVIDERS="$(cd "$ROOT_DIR" && ./scripts/workflow.sh llm providers)"
assert_contains "$PROVIDERS" 'openai' "providers should include openai"
assert_contains "$PROVIDERS" 'llm' "providers should include llm"

echo "[4/4] workflow incident list passthrough"
if ! (cd "$ROOT_DIR" && ./scripts/workflow.sh incident list >/dev/null); then
  echo "ASSERTION FAILED: workflow incident list should execute successfully" >&2
  exit 1
fi

echo "All workflow tests passed."
