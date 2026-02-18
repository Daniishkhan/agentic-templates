#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

usage() {
  cat <<'USAGE'
Directive-first incident learning.

Record a major incident (default mode):
  ./scripts/incident-learn.sh --story US-001 --title "Migration blocked" \
    --signal "migrate failed with duplicate key" \
    --root-cause "old migration edited in place" \
    --correction "added append-only migration" \
    --prevention-rule "Never edit old migrations" \
    --checks "make migrate && make validate" \
    [--severity major|critical] [--with-snapshot] [--minutes 30] [--no-memory]

Capture raw logs only (optional evidence):
  ./scripts/incident-learn.sh --snapshot-only --story US-001 [--minutes 30]

Query directive store:
  ./scripts/incident-learn.sh --list [--limit 20]
  ./scripts/incident-learn.sh --show INC-YYYYMMDD-HHMMSS
  ./scripts/incident-learn.sh --list-rules [--limit 20]

Options:
  --db PATH           SQLite path (default: logs/learning.db)
USAGE
}

MODE="record"
DB_PATH="logs/learning.db"
STORY_ID="UNSCOPED"
TITLE=""
SIGNAL=""
ROOT_CAUSE=""
CORRECTION=""
PREVENTION_RULE=""
CHECKS=""
SEVERITY="major"
MINUTES=30
WITH_SNAPSHOT=false
LIST_LIMIT=20
SHOW_ID=""
WRITE_MEMORY=true

ensure_sqlite() {
  if ! command -v sqlite3 >/dev/null 2>&1; then
    echo "sqlite3 is required. Install sqlite3 before using incident learning." >&2
    exit 1
  fi
}

sql_escape() {
  local s="$1"
  s="${s//\'/\'\'}"
  printf '%s' "$s"
}

sqlite_run() {
  sqlite3 -cmd ".timeout 5000" "$DB_PATH" "$@"
}

sqlite_query() {
  sqlite3 -cmd ".timeout 5000" -header -column "$DB_PATH" "$@"
}

init_db() {
  ensure_sqlite
  mkdir -p "$(dirname "$DB_PATH")" logs/runtime logs/snapshots

  sqlite_run <<'SQL' >/dev/null
PRAGMA journal_mode=WAL;
PRAGMA busy_timeout=5000;
PRAGMA foreign_keys=ON;

CREATE TABLE IF NOT EXISTS incidents (
  incident_id TEXT PRIMARY KEY,
  ts_utc TEXT NOT NULL,
  story_id TEXT NOT NULL,
  severity TEXT NOT NULL CHECK (severity IN ('major', 'critical')),
  title TEXT NOT NULL,
  signal TEXT NOT NULL,
  root_cause TEXT NOT NULL,
  correction TEXT NOT NULL,
  prevention_rule TEXT NOT NULL,
  checks TEXT NOT NULL,
  snapshot_path TEXT,
  git_branch TEXT,
  git_commit TEXT
);

CREATE TABLE IF NOT EXISTS lessons (
  lesson_id INTEGER PRIMARY KEY AUTOINCREMENT,
  incident_id TEXT NOT NULL UNIQUE,
  prevention_rule TEXT NOT NULL UNIQUE,
  checks TEXT NOT NULL,
  added_on TEXT NOT NULL,
  FOREIGN KEY(incident_id) REFERENCES incidents(incident_id)
);

CREATE TABLE IF NOT EXISTS snapshots (
  snapshot_id TEXT PRIMARY KEY,
  ts_utc TEXT NOT NULL,
  story_id TEXT NOT NULL,
  minutes INTEGER NOT NULL,
  path TEXT NOT NULL,
  git_branch TEXT,
  git_commit TEXT
);

CREATE INDEX IF NOT EXISTS idx_incidents_story_ts ON incidents(story_id, ts_utc DESC);
CREATE INDEX IF NOT EXISTS idx_lessons_added_on ON lessons(added_on DESC);
SQL
}

capture_snapshot() {
  local snapshot_id="$1"
  local ts_utc="$2"
  local story_id="$3"
  local severity="$4"
  local minutes="$5"
  local git_branch="$6"
  local git_commit="$7"

  local snapshot_path="logs/snapshots/${snapshot_id}.log"

  {
    echo "# ${snapshot_id}"
    echo "timestamp_utc: ${ts_utc}"
    echo "story: ${story_id}"
    echo "severity: ${severity}"
    echo
    echo "## Git"
    echo "branch: ${git_branch}"
    echo "commit: ${git_commit}"
    echo "status:"
    git status --short 2>/dev/null || true
    echo

    if [[ -f infra/docker-compose.yml ]] && command -v docker >/dev/null 2>&1; then
      echo "## Docker compose ps"
      docker compose -f infra/docker-compose.yml ps 2>&1 || true
      echo

      echo "## Docker compose logs (last ${minutes}m, tail 300)"
      docker compose -f infra/docker-compose.yml logs --no-color --since "${minutes}m" --tail 300 2>&1 || true
      echo
    else
      echo "## Docker compose logs"
      echo "docker compose unavailable or infra/docker-compose.yml missing"
      echo
    fi

    if ls logs/runtime/*.log >/dev/null 2>&1; then
      for f in logs/runtime/*.log; do
        echo "## Runtime tail: ${f}"
        tail -n 200 "$f" 2>&1 || true
        echo
      done
    else
      echo "## Runtime logs"
      echo "No logs/runtime/*.log files found"
      echo
    fi
  } > "$snapshot_path"

  sqlite_run "INSERT INTO snapshots (snapshot_id, ts_utc, story_id, minutes, path, git_branch, git_commit) VALUES ('$(sql_escape "$snapshot_id")', '$(sql_escape "$ts_utc")', '$(sql_escape "$story_id")', ${minutes}, '$(sql_escape "$snapshot_path")', '$(sql_escape "$git_branch")', '$(sql_escape "$git_commit")');"

  printf '%s' "$snapshot_path"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --story)
      STORY_ID="$2"
      shift 2
      ;;
    --title)
      TITLE="$2"
      shift 2
      ;;
    --signal)
      SIGNAL="$2"
      shift 2
      ;;
    --root-cause)
      ROOT_CAUSE="$2"
      shift 2
      ;;
    --correction)
      CORRECTION="$2"
      shift 2
      ;;
    --prevention-rule)
      PREVENTION_RULE="$2"
      shift 2
      ;;
    --checks)
      CHECKS="$2"
      shift 2
      ;;
    --severity)
      SEVERITY="$2"
      shift 2
      ;;
    --minutes)
      MINUTES="$2"
      shift 2
      ;;
    --with-snapshot)
      WITH_SNAPSHOT=true
      shift
      ;;
    --no-memory)
      WRITE_MEMORY=false
      shift
      ;;
    --snapshot-only)
      MODE="snapshot"
      shift
      ;;
    --list)
      MODE="list"
      shift
      ;;
    --show)
      MODE="show"
      SHOW_ID="$2"
      shift 2
      ;;
    --list-rules)
      MODE="rules"
      shift
      ;;
    --limit)
      LIST_LIMIT="$2"
      shift 2
      ;;
    --db)
      DB_PATH="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ "$SEVERITY" != "major" && "$SEVERITY" != "critical" ]]; then
  echo "--severity must be major or critical" >&2
  exit 1
fi

if ! [[ "$MINUTES" =~ ^[0-9]+$ ]]; then
  echo "--minutes must be a positive integer" >&2
  exit 1
fi

if ! [[ "$LIST_LIMIT" =~ ^[0-9]+$ ]]; then
  echo "--limit must be a positive integer" >&2
  exit 1
fi

init_db

case "$MODE" in
  list)
    INCIDENT_COUNT="$(sqlite_run "SELECT COUNT(*) FROM incidents;")"
    if [[ "${INCIDENT_COUNT}" == "0" ]]; then
      echo "(no incident directives yet)"
    else
      sqlite_query "SELECT incident_id, story_id, severity, ts_utc, title, COALESCE(snapshot_path, '-') AS snapshot FROM incidents ORDER BY ts_utc DESC LIMIT ${LIST_LIMIT};"
    fi
    exit 0
    ;;
  show)
    if [[ -z "$SHOW_ID" ]]; then
      echo "--show requires an incident id" >&2
      exit 1
    fi
    FOUND="$(sqlite_run "SELECT COUNT(*) FROM incidents WHERE incident_id='$(sql_escape "$SHOW_ID")';")"
    if [[ "${FOUND}" == "0" ]]; then
      echo "Incident not found: ${SHOW_ID}" >&2
      exit 1
    fi
    sqlite_query "SELECT * FROM incidents WHERE incident_id='$(sql_escape "$SHOW_ID")';"
    exit 0
    ;;
  rules)
    RULE_COUNT="$(sqlite_run "SELECT COUNT(*) FROM lessons;")"
    if [[ "${RULE_COUNT}" == "0" ]]; then
      echo "(no prevention rules yet)"
    else
      sqlite_query "SELECT lesson_id, added_on, prevention_rule, checks, incident_id FROM lessons ORDER BY lesson_id DESC LIMIT ${LIST_LIMIT};"
    fi
    exit 0
    ;;
  snapshot)
    TS_UTC="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
    TS_ID="$(date -u '+%Y%m%d-%H%M%S')"
    SNAPSHOT_ID="SNP-${TS_ID}"
    GIT_BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo n/a)"
    GIT_COMMIT="$(git rev-parse --short HEAD 2>/dev/null || echo n/a)"

    SNAPSHOT_PATH="$(capture_snapshot "$SNAPSHOT_ID" "$TS_UTC" "$STORY_ID" "$SEVERITY" "$MINUTES" "$GIT_BRANCH" "$GIT_COMMIT")"
    echo "Created snapshot: ${SNAPSHOT_PATH}"
    echo "Recorded snapshot directive in: ${DB_PATH}"
    exit 0
    ;;
  record)
    ;;
  *)
    echo "Unsupported mode: $MODE" >&2
    exit 1
    ;;
esac

for req in TITLE SIGNAL ROOT_CAUSE CORRECTION PREVENTION_RULE CHECKS; do
  if [[ -z "${!req}" ]]; then
    req_flag="$(echo "$req" | tr '[:upper:]' '[:lower:]' | tr '_' '-')"
    echo "Missing required argument for record mode: --${req_flag}" >&2
    usage
    exit 1
  fi
done

TS_UTC="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
TS_ID="$(date -u '+%Y%m%d-%H%M%S')"
INCIDENT_ID="INC-${TS_ID}"
ADDED_ON="$(date '+%Y-%m-%d')"
GIT_BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo n/a)"
GIT_COMMIT="$(git rev-parse --short HEAD 2>/dev/null || echo n/a)"
SNAPSHOT_PATH=""

if [[ "$WITH_SNAPSHOT" = true ]]; then
  SNAPSHOT_PATH="$(capture_snapshot "$INCIDENT_ID" "$TS_UTC" "$STORY_ID" "$SEVERITY" "$MINUTES" "$GIT_BRANCH" "$GIT_COMMIT")"
fi

ESC_RULE="$(sql_escape "$PREVENTION_RULE")"
RULE_EXISTS="$(sqlite_run "SELECT 1 FROM lessons WHERE prevention_rule='${ESC_RULE}' LIMIT 1;")"

sqlite_run <<SQL
INSERT INTO incidents (
  incident_id, ts_utc, story_id, severity, title, signal, root_cause, correction,
  prevention_rule, checks, snapshot_path, git_branch, git_commit
) VALUES (
  '$(sql_escape "$INCIDENT_ID")',
  '$(sql_escape "$TS_UTC")',
  '$(sql_escape "$STORY_ID")',
  '$(sql_escape "$SEVERITY")',
  '$(sql_escape "$TITLE")',
  '$(sql_escape "$SIGNAL")',
  '$(sql_escape "$ROOT_CAUSE")',
  '$(sql_escape "$CORRECTION")',
  '$(sql_escape "$PREVENTION_RULE")',
  '$(sql_escape "$CHECKS")',
  $(if [[ -n "$SNAPSHOT_PATH" ]]; then echo "'$(sql_escape "$SNAPSHOT_PATH")'"; else echo "NULL"; fi),
  '$(sql_escape "$GIT_BRANCH")',
  '$(sql_escape "$GIT_COMMIT")'
);
SQL

if [[ -z "$RULE_EXISTS" ]]; then
  sqlite_run "INSERT INTO lessons (incident_id, prevention_rule, checks, added_on) VALUES ('$(sql_escape "$INCIDENT_ID")', '$(sql_escape "$PREVENTION_RULE")', '$(sql_escape "$CHECKS")', '$(sql_escape "$ADDED_ON")');"

  if [[ "$WRITE_MEMORY" = true ]]; then
    if [[ ! -f memory.md ]]; then
      cat > memory.md <<'MEMORY_EOF'
# Memory

> Durable AI lessons learned from major incidents only.
MEMORY_EOF
    fi

    if [[ -n "$SNAPSHOT_PATH" ]]; then
      EVIDENCE="incident_id=${INCIDENT_ID}, db=${DB_PATH}, snapshot=${SNAPSHOT_PATH}"
    else
      EVIDENCE="incident_id=${INCIDENT_ID}, db=${DB_PATH}"
    fi

    cat >> memory.md <<LESSON_EOF

## LESSON-${TS_ID} ${TITLE}
- incident: ${INCIDENT_ID}
- story: ${STORY_ID}
- severity: ${SEVERITY}
- signal: ${SIGNAL}
- root_cause: ${ROOT_CAUSE}
- correction: ${CORRECTION}
- prevention_rule: ${PREVENTION_RULE}
- checks: ${CHECKS}
- evidence: ${EVIDENCE}
- added_on: ${ADDED_ON}
LESSON_EOF

    echo "Recorded incident directive: ${INCIDENT_ID}"
    echo "Added new lesson to memory.md"
  else
    echo "Recorded incident directive: ${INCIDENT_ID}"
    echo "Stored lesson in SQLite only (--no-memory)"
  fi
else
  echo "Recorded incident directive: ${INCIDENT_ID}"
  echo "Prevention rule already exists; skipped lesson append in memory.md"
fi

if [[ -n "$SNAPSHOT_PATH" ]]; then
  echo "Captured snapshot: ${SNAPSHOT_PATH}"
fi

echo "SQLite store: ${DB_PATH}"
