#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NEW_PROJECT_SCRIPT="$ROOT_DIR/scripts/new-project.sh"

CMD_NAME="bio"
BIN_DIR="$HOME/.local/bin"
MODE="here"

usage() {
  cat <<'USAGE'
Install a global scaffold command that can run from any directory.

Usage:
  ./scripts/install-global-command.sh [--name <command>] [--bin-dir <dir>] [--mode here|new-dir]

Defaults:
  --name bio
  --bin-dir ~/.local/bin
  --mode here        # scaffold into current directory

Examples:
  ./scripts/install-global-command.sh
  ./scripts/install-global-command.sh --name bio --mode here
  ./scripts/install-global-command.sh --name tpl-new --mode new-dir
USAGE
}

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --name)
      CMD_NAME="$2"
      shift 2
      ;;
    --bin-dir)
      BIN_DIR="$2"
      shift 2
      ;;
    --mode)
      MODE="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      fail "Unknown option: $1"
      ;;
  esac
done

[[ -x "$NEW_PROJECT_SCRIPT" ]] || fail "Missing executable: $NEW_PROJECT_SCRIPT"
[[ "$MODE" == "here" || "$MODE" == "new-dir" ]] || fail "--mode must be 'here' or 'new-dir'"

mkdir -p "$BIN_DIR"
TARGET="$BIN_DIR/$CMD_NAME"

if [[ "$MODE" == "here" ]]; then
  MODE_ARGS='--here'
else
  MODE_ARGS=''
fi

cat > "$TARGET" <<EOF_LAUNCHER
#!/usr/bin/env bash
set -euo pipefail
exec "$NEW_PROJECT_SCRIPT" $MODE_ARGS "\$@"
EOF_LAUNCHER

chmod +x "$TARGET"

echo "Installed: $TARGET"
if command -v "$CMD_NAME" >/dev/null 2>&1; then
  echo "Command available now: $CMD_NAME"
else
  echo "Command not currently on PATH in this shell. Ensure '$BIN_DIR' is in PATH."
fi

echo "Example:"
if [[ "$MODE" == "here" ]]; then
  echo "  cd /path/to/empty-folder && $CMD_NAME --project myapp --org myorg"
else
  echo "  cd /path/to/parent && $CMD_NAME --project myapp --org myorg"
fi
