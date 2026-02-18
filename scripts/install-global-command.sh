#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_BASENAME="$(basename "$ROOT_DIR")"

CMD_NAME="bio"
BIN_DIR="$HOME/.local/bin"
MODE="here"
DEFAULT_TEMPLATE="mobile"

WEB_ROOT=""
MOBILE_ROOT=""

if [[ "$REPO_BASENAME" == "templates" ]]; then
  DEFAULT_TEMPLATE="web"
  WEB_ROOT="$ROOT_DIR"
  if [[ -d "$ROOT_DIR/../templates-mobile" ]]; then
    MOBILE_ROOT="$(cd "$ROOT_DIR/../templates-mobile" && pwd)"
  fi
elif [[ "$REPO_BASENAME" == "templates-mobile" ]]; then
  DEFAULT_TEMPLATE="mobile"
  MOBILE_ROOT="$ROOT_DIR"
  if [[ -d "$ROOT_DIR/../templates" ]]; then
    WEB_ROOT="$(cd "$ROOT_DIR/../templates" && pwd)"
  fi
fi

usage() {
  cat <<'USAGE'
Install a global scaffold command that can run from any directory.

Usage:
  ./scripts/install-global-command.sh \
    [--name <command>] [--bin-dir <dir>] [--mode here|new-dir] \
    [--default-template web|mobile] [--web-root <path>] [--mobile-root <path>]

Defaults:
  --name bio
  --bin-dir ~/.local/bin
  --mode here                 # scaffold into current directory
  --default-template auto     # web in templates repo, mobile in templates-mobile repo
  --web-root auto-detected sibling templates repo
  --mobile-root auto-detected sibling templates-mobile repo

Runtime usage (after install):
  <command> --template web|mobile --project <name> --org <org>

Examples:
  ./scripts/install-global-command.sh
  ./scripts/install-global-command.sh --name bio --mode here --default-template mobile
  ./scripts/install-global-command.sh --web-root /path/templates --mobile-root /path/templates-mobile
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
    --default-template)
      DEFAULT_TEMPLATE="$2"
      shift 2
      ;;
    --web-root)
      WEB_ROOT="$2"
      shift 2
      ;;
    --mobile-root)
      MOBILE_ROOT="$2"
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

[[ "$MODE" == "here" || "$MODE" == "new-dir" ]] || fail "--mode must be 'here' or 'new-dir'"
[[ "$DEFAULT_TEMPLATE" == "web" || "$DEFAULT_TEMPLATE" == "mobile" ]] || fail "--default-template must be 'web' or 'mobile'"

WEB_NEW_PROJECT_SCRIPT=""
MOBILE_NEW_PROJECT_SCRIPT=""

if [[ -n "$WEB_ROOT" ]]; then
  [[ -d "$WEB_ROOT" ]] || fail "--web-root does not exist: $WEB_ROOT"
  WEB_NEW_PROJECT_SCRIPT="$WEB_ROOT/scripts/new-project.sh"
fi

if [[ -n "$MOBILE_ROOT" ]]; then
  [[ -d "$MOBILE_ROOT" ]] || fail "--mobile-root does not exist: $MOBILE_ROOT"
  MOBILE_NEW_PROJECT_SCRIPT="$MOBILE_ROOT/scripts/new-project.sh"
fi

if [[ "$DEFAULT_TEMPLATE" == "web" ]]; then
  [[ -x "$WEB_NEW_PROJECT_SCRIPT" ]] || fail "web template script missing/executable: $WEB_NEW_PROJECT_SCRIPT"
else
  [[ -x "$MOBILE_NEW_PROJECT_SCRIPT" ]] || fail "mobile template script missing/executable: $MOBILE_NEW_PROJECT_SCRIPT"
fi

mkdir -p "$BIN_DIR"
TARGET="$BIN_DIR/$CMD_NAME"

cat > "$TARGET" <<EOF_LAUNCHER
#!/usr/bin/env bash
set -euo pipefail

WEB_NEW_PROJECT_SCRIPT="${WEB_NEW_PROJECT_SCRIPT}"
MOBILE_NEW_PROJECT_SCRIPT="${MOBILE_NEW_PROJECT_SCRIPT}"
DEFAULT_TEMPLATE="${DEFAULT_TEMPLATE}"
MODE="${MODE}"

print_help() {
  cat <<'USAGE'
Scaffold a project from web or mobile templates.

Usage:
  ${CMD_NAME} --template web|mobile --project <name> --org <org> [other new-project args]

Notes:
- --template defaults to installer default if omitted.
- Remaining args are forwarded to scripts/new-project.sh for the selected template.
USAGE
}

TEMPLATE="\$DEFAULT_TEMPLATE"
FORWARD_ARGS=()

while [[ \$# -gt 0 ]]; do
  case "\$1" in
    --template)
      TEMPLATE="\$2"
      shift 2
      ;;
    --template=*)
      TEMPLATE="\${1#*=}"
      shift
      ;;
    -h|--help)
      print_help
      exit 0
      ;;
    *)
      FORWARD_ARGS+=("\$1")
      shift
      ;;
  esac
done

TARGET_SCRIPT=""
case "\$TEMPLATE" in
  web)
    TARGET_SCRIPT="\$WEB_NEW_PROJECT_SCRIPT"
    ;;
  mobile)
    TARGET_SCRIPT="\$MOBILE_NEW_PROJECT_SCRIPT"
    ;;
  *)
    echo "ERROR: --template must be 'web' or 'mobile'" >&2
    exit 1
    ;;
esac

if [[ -z "\$TARGET_SCRIPT" ]]; then
  echo "ERROR: Template '\$TEMPLATE' is not configured in this launcher" >&2
  exit 1
fi

if [[ ! -x "\$TARGET_SCRIPT" ]]; then
  echo "ERROR: Template command is missing or not executable: \$TARGET_SCRIPT" >&2
  exit 1
fi

if [[ "\$MODE" == "here" ]]; then
  exec "\$TARGET_SCRIPT" --here "\${FORWARD_ARGS[@]}"
else
  exec "\$TARGET_SCRIPT" "\${FORWARD_ARGS[@]}"
fi
EOF_LAUNCHER

chmod +x "$TARGET"

echo "Installed: $TARGET"
echo "Default template: $DEFAULT_TEMPLATE"
if [[ -n "$WEB_NEW_PROJECT_SCRIPT" ]]; then
  echo "Web template: $WEB_NEW_PROJECT_SCRIPT"
else
  echo "Web template: not configured"
fi
if [[ -n "$MOBILE_NEW_PROJECT_SCRIPT" ]]; then
  echo "Mobile template: $MOBILE_NEW_PROJECT_SCRIPT"
else
  echo "Mobile template: not configured"
fi
if command -v "$CMD_NAME" >/dev/null 2>&1; then
  echo "Command available now: $CMD_NAME"
else
  echo "Command not currently on PATH in this shell. Ensure '$BIN_DIR' is in PATH."
fi

echo "Example:"
if [[ "$MODE" == "here" ]]; then
  echo "  cd /path/to/empty-folder && $CMD_NAME --template mobile --project myapp --org myorg"
  echo "  cd /path/to/empty-folder && $CMD_NAME --template web --project myapp --org myorg"
else
  echo "  cd /path/to/parent && $CMD_NAME --template mobile --project myapp --org myorg"
  echo "  cd /path/to/parent && $CMD_NAME --template web --project myapp --org myorg"
fi
