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

if [[ -f docs/epic.md ]]; then
  echo "-- Story Index (docs/epic.md) --"
  print_between_markers "^<!-- STORY_INDEX_START -->$" "^<!-- STORY_INDEX_END -->$" "docs/epic.md" || true
  echo

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
