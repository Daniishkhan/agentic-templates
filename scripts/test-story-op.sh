#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STORY_OP="$ROOT_DIR/scripts/story-op.sh"
BASE_EPIC="$ROOT_DIR/docs/epic.md"
BASE_PROGRESS="$ROOT_DIR/progress.md"

[[ -x "$STORY_OP" ]] || {
  echo "story-op script not found or not executable: $STORY_OP" >&2
  exit 1
}

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

assert_eq() {
  local actual="$1"
  local expected="$2"
  local msg="$3"
  if [[ "$actual" != "$expected" ]]; then
    echo "ASSERTION FAILED: $msg" >&2
    echo "  expected: $expected" >&2
    echo "  actual:   $actual" >&2
    exit 1
  fi
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  local msg="$3"
  if [[ "$haystack" != *"$needle"* ]]; then
    echo "ASSERTION FAILED: $msg" >&2
    echo "  expected to contain: $needle" >&2
    echo "  in: $haystack" >&2
    exit 1
  fi
}

assert_file_contains() {
  local file="$1"
  local pattern="$2"
  local msg="$3"
  if ! rg -q "$pattern" "$file"; then
    echo "ASSERTION FAILED: $msg" >&2
    echo "  missing pattern: $pattern" >&2
    echo "  file: $file" >&2
    exit 1
  fi
}

story_index_status() {
  local epic_file="$1"
  local story="$2"

  awk -v target="$story" '
    BEGIN { in_index=0; in_fence=0; cur="" }
    /^<!-- STORY_INDEX_START -->$/ { in_index=1; next }
    /^<!-- STORY_INDEX_END -->$/ { in_index=0; in_fence=0; cur=""; next }
    !in_index { next }
    /^```/ {
      if (in_fence==0) in_fence=1; else in_fence=0
      next
    }
    !in_fence { next }
    {
      if ($0 ~ /^[ \t]*-[ \t]*id:[ \t]*US-[0-9A-Za-z-]+/) {
        cur=$0
        sub(/^[ \t]*-[ \t]*id:[ \t]*/, "", cur)
        sub(/[ \t].*$/, "", cur)
        next
      }
      if (cur == target && $0 ~ /^[ \t]*status:[ \t]*[a-z-]+/) {
        status=$0
        sub(/^[ \t]*status:[ \t]*/, "", status)
        sub(/[ \t].*$/, "", status)
        print status
        exit
      }
    }
  ' "$epic_file"
}

story_meta_status() {
  local epic_file="$1"
  local story="$2"

  awk -v target="$story" '
    BEGIN { in_story=0; after_meta=0; in_yaml=0 }
    {
      if ($0 ~ /^##[ \t]+US-[0-9A-Za-z-]+/) {
        heading=$0
        sub(/^##[ \t]+/, "", heading)
        sub(/[ \t].*$/, "", heading)
        in_story=(heading==target)
        after_meta=0
        in_yaml=0
      }
      if (!in_story) next
      if ($0 ~ /^\*\*Story Meta\*\*$/) { after_meta=1; next }
      if (after_meta && $0 ~ /^```yaml$/) { in_yaml=1; next }
      if (in_yaml && $0 ~ /^```$/) { in_yaml=0; after_meta=0; next }
      if (in_yaml && $0 ~ /^[ \t]*status:[ \t]*[a-z-]+/) {
        status=$0
        sub(/^[ \t]*status:[ \t]*/, "", status)
        sub(/[ \t].*$/, "", status)
        print status
        exit
      }
    }
  ' "$epic_file"
}

story_owner_status() {
  local epic_file="$1"
  local story="$2"

  awk -v target="$story" '
    BEGIN { in_story=0; after_meta=0; in_yaml=0 }
    {
      if ($0 ~ /^##[ \t]+US-[0-9A-Za-z-]+/) {
        heading=$0
        sub(/^##[ \t]+/, "", heading)
        sub(/[ \t].*$/, "", heading)
        in_story=(heading==target)
        after_meta=0
        in_yaml=0
      }
      if (!in_story) next
      if ($0 ~ /^\*\*Story Meta\*\*$/) { after_meta=1; next }
      if (after_meta && $0 ~ /^```yaml$/) { in_yaml=1; next }
      if (in_yaml && $0 ~ /^```$/) { in_yaml=0; after_meta=0; next }
      if (in_yaml && $0 ~ /^[ \t]*owner:[ \t]*.*/) {
        owner=$0
        sub(/^[ \t]*owner:[ \t]*/, "", owner)
        print owner
        exit
      }
    }
  ' "$epic_file"
}

new_fixture() {
  local name="$1"
  local dir="$TMP_DIR/$name"
  mkdir -p "$dir"
  cp "$BASE_EPIC" "$dir/epic.md"
  cp "$BASE_PROGRESS" "$dir/progress.md"
  echo "$dir"
}

run_story_op() {
  local epic_file="$1"
  local progress_file="$2"
  shift 2

  STORY_OP_EPIC_FILE="$epic_file" STORY_OP_PROGRESS_FILE="$progress_file" "$STORY_OP" "$@"
}

echo "[1/6] start transition updates index + meta + owner"
F1="$(new_fixture t1)"
START_JSON="$(run_story_op "$F1/epic.md" "$F1/progress.md" start --story US-000 --owner ali --json)"
assert_eq "$(story_index_status "$F1/epic.md" US-000)" "in-progress" "Story Index status should be in-progress"
assert_eq "$(story_meta_status "$F1/epic.md" US-000)" "in-progress" "Story Meta status should be in-progress"
assert_eq "$(story_owner_status "$F1/epic.md" US-000)" "ali" "Story Meta owner should be updated"
assert_contains "$START_JSON" '"story":"US-000"' "start json includes story"
assert_contains "$START_JSON" '"from":"backlog"' "start json includes from"
assert_contains "$START_JSON" '"to":"in-progress"' "start json includes to"
assert_contains "$START_JSON" '"updated_files"' "start json includes updated_files"
assert_contains "$START_JSON" '"timestamp"' "start json includes timestamp"

echo "[2/6] done transition updates progress and rejects invalid transition"
DONE_JSON="$(run_story_op "$F1/epic.md" "$F1/progress.md" done --story US-000 --summary "Scaffold complete" --json)"
assert_eq "$(story_index_status "$F1/epic.md" US-000)" "done" "Story Index status should be done"
assert_eq "$(story_meta_status "$F1/epic.md" US-000)" "done" "Story Meta status should be done"
assert_file_contains "$F1/progress.md" 'US-000: Scaffold complete' "Done entry should be appended"
assert_contains "$DONE_JSON" '"story":"US-000"' "done json includes story"
assert_contains "$DONE_JSON" '"from":"in-progress"' "done json includes from"
assert_contains "$DONE_JSON" '"to":"done"' "done json includes to"

EPIC_HASH_BEFORE="$(shasum "$F1/epic.md" | awk '{print $1}')"
PROGRESS_HASH_BEFORE="$(shasum "$F1/progress.md" | awk '{print $1}')"
if run_story_op "$F1/epic.md" "$F1/progress.md" block --story US-000 --reason "should fail" >/dev/null 2>&1; then
  echo "ASSERTION FAILED: block after done should fail" >&2
  exit 1
fi
EPIC_HASH_AFTER="$(shasum "$F1/epic.md" | awk '{print $1}')"
PROGRESS_HASH_AFTER="$(shasum "$F1/progress.md" | awk '{print $1}')"
assert_eq "$EPIC_HASH_BEFORE" "$EPIC_HASH_AFTER" "epic should not change on invalid transition"
assert_eq "$PROGRESS_HASH_BEFORE" "$PROGRESS_HASH_AFTER" "progress should not change on invalid transition"

echo "[3/6] block transition updates blocked section"
F2="$(new_fixture t2)"
run_story_op "$F2/epic.md" "$F2/progress.md" start --story US-000 >/dev/null
BLOCK_JSON="$(run_story_op "$F2/epic.md" "$F2/progress.md" block --story US-000 --reason "Docker not healthy" --json)"
assert_eq "$(story_index_status "$F2/epic.md" US-000)" "blocked" "Story Index status should be blocked"
assert_eq "$(story_meta_status "$F2/epic.md" US-000)" "blocked" "Story Meta status should be blocked"
assert_file_contains "$F2/progress.md" 'US-000: Docker not healthy' "Blocked entry should be appended"
assert_contains "$BLOCK_JSON" '"to":"blocked"' "block json includes target status"

echo "[4/6] ready queue respects dependency completion"
F3="$TMP_DIR/t3"
mkdir -p "$F3"
cat > "$F3/epic.md" <<'EPIC_EOF'
---
id: EPIC-BACKLOG
---

## Story Index (machine-readable, update first)

<!-- STORY_INDEX_START -->
```yaml
stories:
  - id: US-100
    title: Foundation
    epic: EPIC-01
    status: done
    owner: unassigned
    depends_on: []

  - id: US-101
    title: API
    epic: EPIC-01
    status: ready
    owner: unassigned
    depends_on: [US-100]

  - id: US-102
    title: UI
    epic: EPIC-01
    status: ready
    owner: unassigned
    depends_on: [US-101]
```
<!-- STORY_INDEX_END -->

## US-100 Foundation

**Story Meta**
```yaml
id: US-100
status: done
priority: high
depends_on: []
owner: unassigned
```

## US-101 API

**Story Meta**
```yaml
id: US-101
status: ready
priority: high
depends_on: [US-100]
owner: unassigned
```

## US-102 UI

**Story Meta**
```yaml
id: US-102
status: ready
priority: high
depends_on: [US-101]
owner: unassigned
```
EPIC_EOF

cp "$BASE_PROGRESS" "$F3/progress.md"
READY_TXT="$(run_story_op "$F3/epic.md" "$F3/progress.md" ready)"
READY_JSON="$(run_story_op "$F3/epic.md" "$F3/progress.md" ready --json)"
assert_contains "$READY_TXT" 'US-101' "ready text should include US-101"
if [[ "$READY_TXT" == *"US-102"* ]]; then
  echo "ASSERTION FAILED: ready text should not include US-102" >&2
  exit 1
fi
assert_contains "$READY_JSON" '"id":"US-101"' "ready json should include US-101"
if [[ "$READY_JSON" == *"US-102"* ]]; then
  echo "ASSERTION FAILED: ready json should not include US-102" >&2
  exit 1
fi

echo "[5/6] unknown story fails with no file mutation"
F4="$(new_fixture t4)"
EPIC_HASH_BEFORE="$(shasum "$F4/epic.md" | awk '{print $1}')"
PROGRESS_HASH_BEFORE="$(shasum "$F4/progress.md" | awk '{print $1}')"
if run_story_op "$F4/epic.md" "$F4/progress.md" done --story US-999 --summary "Nope" >/dev/null 2>&1; then
  echo "ASSERTION FAILED: unknown story should fail" >&2
  exit 1
fi
EPIC_HASH_AFTER="$(shasum "$F4/epic.md" | awk '{print $1}')"
PROGRESS_HASH_AFTER="$(shasum "$F4/progress.md" | awk '{print $1}')"
assert_eq "$EPIC_HASH_BEFORE" "$EPIC_HASH_AFTER" "epic should remain unchanged for unknown story"
assert_eq "$PROGRESS_HASH_BEFORE" "$PROGRESS_HASH_AFTER" "progress should remain unchanged for unknown story"

echo "[6/6] missing markers fail before write"
F5="$(new_fixture t5)"
# Remove Story Index markers to simulate malformed epic
sed '/STORY_INDEX_START/d; /STORY_INDEX_END/d' "$F5/epic.md" > "$F5/epic-malformed.md"
EPIC_HASH_BEFORE="$(shasum "$F5/epic-malformed.md" | awk '{print $1}')"
if STORY_OP_EPIC_FILE="$F5/epic-malformed.md" STORY_OP_PROGRESS_FILE="$F5/progress.md" "$STORY_OP" start --story US-000 >/dev/null 2>&1; then
  echo "ASSERTION FAILED: malformed epic should fail" >&2
  exit 1
fi
EPIC_HASH_AFTER="$(shasum "$F5/epic-malformed.md" | awk '{print $1}')"
assert_eq "$EPIC_HASH_BEFORE" "$EPIC_HASH_AFTER" "malformed epic should remain unchanged"

echo "All story-op tests passed."
