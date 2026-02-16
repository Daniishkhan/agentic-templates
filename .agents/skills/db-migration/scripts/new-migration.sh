#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: .agents/skills/db-migration/scripts/new-migration.sh <migration_name>"
  exit 1
fi

NAME="$1"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../../" && pwd)"
cd "$ROOT_DIR"

make migrate-new NAME="$NAME"

echo "Created migration: $NAME"
echo "Next: make migrate && make schema-dump && make generate-sqlc"
