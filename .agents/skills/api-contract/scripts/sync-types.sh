#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../../" && pwd)"
cd "$ROOT_DIR"

make generate-types

if command -v pnpm >/dev/null 2>&1; then
  (cd web && pnpm typecheck)
fi

echo "API contract types regenerated and web typecheck completed."
