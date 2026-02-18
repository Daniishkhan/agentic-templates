#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BOOTSTRAP_SCRIPT="$ROOT_DIR/.agents/skills/project-scaffold/scripts/bootstrap.sh"

PROJECT=""
ORG="${GITHUB_ORG:-}"
DEST_DIR="$(dirname "$ROOT_DIR")"
DRY_RUN=false
HERE_MODE=false

usage() {
  cat <<'USAGE'
Create a new project from the templates operating system.

Usage:
  ./scripts/new-project.sh --project <name> [--org <github_org>] [--dest <directory>] [--here] [--dry-run]
  ./scripts/new-project.sh <name> [github_org]

Defaults:
  - org: from GITHUB_ORG env var (or interactive prompt)
  - dest: parent directory of this templates repo
  - --here: scaffold directly into the current directory (must be empty)

Examples:
  ./scripts/new-project.sh --project acme-api --org mycompany
  ./scripts/new-project.sh acme-api mycompany
  ./scripts/new-project.sh --project acme-api --org mycompany --here
  make new PROJECT=acme-api ORG=mycompany
USAGE
}

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project|-p)
      PROJECT="$2"
      shift 2
      ;;
    --org|-o)
      ORG="$2"
      shift 2
      ;;
    --dest|-d)
      DEST_DIR="$2"
      shift 2
      ;;
    --here)
      HERE_MODE=true
      shift
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --)
      shift
      break
      ;;
    -* )
      fail "Unknown option: $1"
      ;;
    *)
      if [[ -z "$PROJECT" ]]; then
        PROJECT="$1"
      elif [[ -z "$ORG" ]]; then
        ORG="$1"
      else
        fail "Unexpected argument: $1"
      fi
      shift
      ;;
  esac
done

[[ -n "$PROJECT" ]] || fail "Project name is required. Use --project <name>."
[[ -f "$BOOTSTRAP_SCRIPT" ]] || fail "Bootstrap script not found: $BOOTSTRAP_SCRIPT"

if [[ -z "$ORG" ]]; then
  if [[ -t 0 ]]; then
    read -r -p "GitHub org/user for new repo: " ORG
  fi
fi
[[ -n "$ORG" ]] || fail "GitHub org is required. Use --org <name> or set GITHUB_ORG."

if [[ ! -d "$DEST_DIR" ]]; then
  fail "Destination directory does not exist: $DEST_DIR"
fi

if [[ ! "$PROJECT" =~ ^[a-zA-Z0-9._-]+$ ]]; then
  fail "Invalid project name '$PROJECT'. Use letters, numbers, dot, underscore, or dash."
fi

ABS_DEST="$(cd "$DEST_DIR" && pwd)"
TARGET_PATH="$ABS_DEST/$PROJECT"

if [[ "$HERE_MODE" == "true" ]]; then
  TARGET_PATH="$(pwd -P)"

  if [[ "$DRY_RUN" != "true" ]] && find "$TARGET_PATH" -mindepth 1 -maxdepth 1 | read -r _; then
    fail "Current directory is not empty: $TARGET_PATH (required for --here)"
  fi
else
  if [[ -e "$TARGET_PATH" ]]; then
    fail "Target path already exists: $TARGET_PATH"
  fi
fi

if [[ "$DRY_RUN" == "true" ]]; then
  echo "Dry run:"
  echo "  template root : $ROOT_DIR"
  echo "  bootstrap     : $BOOTSTRAP_SCRIPT"
  echo "  project       : $PROJECT"
  echo "  github org    : $ORG"
  echo "  destination   : $ABS_DEST"
  echo "  mode          : $([[ "$HERE_MODE" == "true" ]] && echo "here" || echo "new-directory")"
  echo "  target path   : $TARGET_PATH"
  exit 0
fi

if [[ "$HERE_MODE" == "true" ]]; then
  TMP_PARENT="$(mktemp -d)"
  trap 'rm -rf "$TMP_PARENT"' EXIT

  echo "Scaffolding project '$PROJECT' in current directory '$TARGET_PATH' (org: $ORG)"
  (
    cd "$TMP_PARENT"
    "$BOOTSTRAP_SCRIPT" "$PROJECT" "$ORG"
  )

  shopt -s dotglob nullglob
  mv "$TMP_PARENT/$PROJECT"/* "$TARGET_PATH"/
  shopt -u dotglob nullglob

  rm -rf "$TMP_PARENT"
  trap - EXIT

  echo
  echo "Done."
  echo "Now run: make workflow ARGS='context brief'"
else
  echo "Scaffolding project '$PROJECT' in '$ABS_DEST' (org: $ORG)"
  (
    cd "$ABS_DEST"
    "$BOOTSTRAP_SCRIPT" "$PROJECT" "$ORG"
  )

  echo

  echo "Done."
  echo "Next: cd $TARGET_PATH"
  echo "Then: make workflow ARGS='context brief'"
fi
