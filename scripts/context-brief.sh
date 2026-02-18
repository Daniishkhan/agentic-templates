#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

print_section() {
  local regex="$1"
  local file="$2"
  awk -v regex="$regex" '
    $0 ~ regex {in_section=1; print; next}
    in_section && /^## / {exit}
    in_section {print}
  ' "$file"
}

print_between_markers() {
  local start="$1"
  local end="$2"
  local file="$3"
  awk -v s="$start" -v e="$end" '
    $0 ~ s {in_block=1; next}
    $0 ~ e {in_block=0; exit}
    in_block {print}
  ' "$file"
}

echo "== Context Brief =="
echo "repo: $(basename "$ROOT_DIR")"
echo "time: $(date '+%Y-%m-%d %H:%M:%S %Z')"
echo

if [[ -f progress.md ]]; then
  echo "-- progress.md --"
  print_section "^## Done$" "progress.md" || true
  echo
  print_section "^## Inactive / Blocked$" "progress.md" || true
  echo
  print_section "^## Needs Rework$" "progress.md" || true
  echo
  print_section "^## Next Up$" "progress.md" || true
  echo
else
  echo "progress.md not found"
  echo
fi

if [[ -f memory.md ]]; then
  echo "-- memory.md (latest lessons) --"
  if command -v rg >/dev/null 2>&1; then
    rg '^## LESSON-[0-9]{8}-[0-9]{6}' memory.md | tail -n 5 || echo "(no lessons yet)"
  else
    grep -E '^## LESSON-[0-9]{8}-[0-9]{6}' memory.md | tail -n 5 || echo "(no lessons yet)"
  fi
  echo
fi

if [[ -f logs/learning.db ]] && command -v sqlite3 >/dev/null 2>&1; then
  if sqlite3 logs/learning.db "SELECT 1 FROM sqlite_master WHERE type='table' AND name='incidents';" | grep -q 1; then
    echo "-- incident directives (latest) --"
    sqlite3 -header -column logs/learning.db "SELECT incident_id, story_id, severity, ts_utc, title FROM incidents ORDER BY ts_utc DESC LIMIT 5;" || true
    echo
  fi
fi

if [[ -f docs/epic.md ]]; then
  echo "-- Story Index (docs/epic.md) --"
  print_between_markers "^<!-- STORY_INDEX_START -->$" "^<!-- STORY_INDEX_END -->$" "docs/epic.md" || true
  echo

  if [[ -x scripts/story-op.sh ]]; then
    echo "-- Ready Queue (story-op) --"
    ./scripts/story-op.sh ready || echo "(story-op ready check unavailable)"
    echo
  fi

  echo "-- Epic Stories (docs/epic.md) --"
  if command -v rg >/dev/null 2>&1; then
    rg -n "^## US-" docs/epic.md || echo "(no US-* sections found)"
  else
    grep -n "^## US-" docs/epic.md || echo "(no US-* sections found)"
  fi
  echo
fi

echo "-- Git Snapshot --"
git status --short
echo
git log --oneline -10
