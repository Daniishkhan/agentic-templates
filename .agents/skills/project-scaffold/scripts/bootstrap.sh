#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# bootstrap.sh — Generate a complete Go + TypeScript monorepo from scratch.
#
# Requires: macOS with Homebrew installed. All other tools auto-installed.
#
# Usage:
#   ./.agents/skills/project-scaffold/scripts/bootstrap.sh <project_name> <github_org>
#
# Example:
#   ./.agents/skills/project-scaffold/scripts/bootstrap.sh rideshare mycompany
#
# What it does:
#   1. Installs missing tools via brew (go, node, sqlc, migrate, air, etc.)
#   2. Creates directory structure
#   3. Writes all config files, stubs, and starter code
#   4. Initializes Go module + frontend packages (Tailwind v4, shadcn/ui, Zustand, tests)
#   5. Creates initial git commit
#
# After running: make dev-infra && make migrate && make dev
# ============================================================================

# ---------------------------------------------------------------------------
# Args + validation
# ---------------------------------------------------------------------------
if [[ $# -lt 2 ]]; then
  echo "Usage: ./.agents/skills/project-scaffold/scripts/bootstrap.sh <project_name> <github_org>"
  echo "Example: ./.agents/skills/project-scaffold/scripts/bootstrap.sh rideshare mycompany"
  exit 1
fi

PROJECT="$1"
ORG="$2"
PG_PORT=55432
REDIS_PORT=56379
MINIO_PORT=59000
MINIO_CONSOLE_PORT=59001

if [[ -d "$PROJECT" ]]; then
  echo "Error: directory '$PROJECT' already exists."
  exit 1
fi

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
info()  { echo -e "${GREEN}[✓]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
fail()  { echo -e "${RED}[✗]${NC} $1"; exit 1; }
step()  { echo -e "\n${CYAN}=== $1 ===${NC}"; }

write_modern_minimal_theme_css() {
  cat > web/src/index.css << 'EOF'
@import "tailwindcss";

:root {
  --background: oklch(1.0000 0 0);
  --foreground: oklch(0.3211 0 0);
  --card: oklch(1.0000 0 0);
  --card-foreground: oklch(0.3211 0 0);
  --popover: oklch(1.0000 0 0);
  --popover-foreground: oklch(0.3211 0 0);
  --primary: oklch(0.6231 0.1880 259.8145);
  --primary-foreground: oklch(1.0000 0 0);
  --secondary: oklch(0.9670 0.0029 264.5419);
  --secondary-foreground: oklch(0.4461 0.0263 256.8018);
  --muted: oklch(0.9846 0.0017 247.8389);
  --muted-foreground: oklch(0.5510 0.0234 264.3637);
  --accent: oklch(0.9514 0.0250 236.8242);
  --accent-foreground: oklch(0.3791 0.1378 265.5222);
  --destructive: oklch(0.6368 0.2078 25.3313);
  --destructive-foreground: oklch(1.0000 0 0);
  --border: oklch(0.9276 0.0058 264.5313);
  --input: oklch(0.9276 0.0058 264.5313);
  --ring: oklch(0.6231 0.1880 259.8145);
  --chart-1: oklch(0.6231 0.1880 259.8145);
  --chart-2: oklch(0.5461 0.2152 262.8809);
  --chart-3: oklch(0.4882 0.2172 264.3763);
  --chart-4: oklch(0.4244 0.1809 265.6377);
  --chart-5: oklch(0.3791 0.1378 265.5222);
  --sidebar: oklch(0.9846 0.0017 247.8389);
  --sidebar-foreground: oklch(0.3211 0 0);
  --sidebar-primary: oklch(0.6231 0.1880 259.8145);
  --sidebar-primary-foreground: oklch(1.0000 0 0);
  --sidebar-accent: oklch(0.9514 0.0250 236.8242);
  --sidebar-accent-foreground: oklch(0.3791 0.1378 265.5222);
  --sidebar-border: oklch(0.9276 0.0058 264.5313);
  --sidebar-ring: oklch(0.6231 0.1880 259.8145);
  --font-sans: Inter, sans-serif;
  --font-serif: Source Serif 4, serif;
  --font-mono: JetBrains Mono, monospace;
  --radius: 0.375rem;
  --shadow-x: 0;
  --shadow-y: 1px;
  --shadow-blur: 3px;
  --shadow-spread: 0px;
  --shadow-opacity: 0.1;
  --shadow-color: oklch(0 0 0);
  --shadow-2xs: 0 1px 3px 0px hsl(0 0% 0% / 0.05);
  --shadow-xs: 0 1px 3px 0px hsl(0 0% 0% / 0.05);
  --shadow-sm: 0 1px 3px 0px hsl(0 0% 0% / 0.10), 0 1px 2px -1px hsl(0 0% 0% / 0.10);
  --shadow: 0 1px 3px 0px hsl(0 0% 0% / 0.10), 0 1px 2px -1px hsl(0 0% 0% / 0.10);
  --shadow-md: 0 1px 3px 0px hsl(0 0% 0% / 0.10), 0 2px 4px -1px hsl(0 0% 0% / 0.10);
  --shadow-lg: 0 1px 3px 0px hsl(0 0% 0% / 0.10), 0 4px 6px -1px hsl(0 0% 0% / 0.10);
  --shadow-xl: 0 1px 3px 0px hsl(0 0% 0% / 0.10), 0 8px 10px -1px hsl(0 0% 0% / 0.10);
  --shadow-2xl: 0 1px 3px 0px hsl(0 0% 0% / 0.25);
  --tracking-normal: 0em;
  --spacing: 0.25rem;
}

.dark {
  --background: oklch(0.2046 0 0);
  --foreground: oklch(0.9219 0 0);
  --card: oklch(0.2686 0 0);
  --card-foreground: oklch(0.9219 0 0);
  --popover: oklch(0.2686 0 0);
  --popover-foreground: oklch(0.9219 0 0);
  --primary: oklch(0.6231 0.1880 259.8145);
  --primary-foreground: oklch(1.0000 0 0);
  --secondary: oklch(0.2686 0 0);
  --secondary-foreground: oklch(0.9219 0 0);
  --muted: oklch(0.2393 0 0);
  --muted-foreground: oklch(0.7155 0 0);
  --accent: oklch(0.3791 0.1378 265.5222);
  --accent-foreground: oklch(0.8823 0.0571 254.1284);
  --destructive: oklch(0.6368 0.2078 25.3313);
  --destructive-foreground: oklch(1.0000 0 0);
  --border: oklch(0.3715 0 0);
  --input: oklch(0.3715 0 0);
  --ring: oklch(0.6231 0.1880 259.8145);
  --chart-1: oklch(0.7137 0.1434 254.6240);
  --chart-2: oklch(0.6231 0.1880 259.8145);
  --chart-3: oklch(0.5461 0.2152 262.8809);
  --chart-4: oklch(0.4882 0.2172 264.3763);
  --chart-5: oklch(0.4244 0.1809 265.6377);
  --sidebar: oklch(0.2046 0 0);
  --sidebar-foreground: oklch(0.9219 0 0);
  --sidebar-primary: oklch(0.6231 0.1880 259.8145);
  --sidebar-primary-foreground: oklch(1.0000 0 0);
  --sidebar-accent: oklch(0.3791 0.1378 265.5222);
  --sidebar-accent-foreground: oklch(0.8823 0.0571 254.1284);
  --sidebar-border: oklch(0.3715 0 0);
  --sidebar-ring: oklch(0.6231 0.1880 259.8145);
  --font-sans: Inter, sans-serif;
  --font-serif: Source Serif 4, serif;
  --font-mono: JetBrains Mono, monospace;
  --radius: 0.375rem;
  --shadow-x: 0;
  --shadow-y: 1px;
  --shadow-blur: 3px;
  --shadow-spread: 0px;
  --shadow-opacity: 0.1;
  --shadow-color: oklch(0 0 0);
  --shadow-2xs: 0 1px 3px 0px hsl(0 0% 0% / 0.05);
  --shadow-xs: 0 1px 3px 0px hsl(0 0% 0% / 0.05);
  --shadow-sm: 0 1px 3px 0px hsl(0 0% 0% / 0.10), 0 1px 2px -1px hsl(0 0% 0% / 0.10);
  --shadow: 0 1px 3px 0px hsl(0 0% 0% / 0.10), 0 1px 2px -1px hsl(0 0% 0% / 0.10);
  --shadow-md: 0 1px 3px 0px hsl(0 0% 0% / 0.10), 0 2px 4px -1px hsl(0 0% 0% / 0.10);
  --shadow-lg: 0 1px 3px 0px hsl(0 0% 0% / 0.10), 0 4px 6px -1px hsl(0 0% 0% / 0.10);
  --shadow-xl: 0 1px 3px 0px hsl(0 0% 0% / 0.10), 0 8px 10px -1px hsl(0 0% 0% / 0.10);
  --shadow-2xl: 0 1px 3px 0px hsl(0 0% 0% / 0.25);
}

@theme inline {
  --color-background: var(--background);
  --color-foreground: var(--foreground);
  --color-card: var(--card);
  --color-card-foreground: var(--card-foreground);
  --color-popover: var(--popover);
  --color-popover-foreground: var(--popover-foreground);
  --color-primary: var(--primary);
  --color-primary-foreground: var(--primary-foreground);
  --color-secondary: var(--secondary);
  --color-secondary-foreground: var(--secondary-foreground);
  --color-muted: var(--muted);
  --color-muted-foreground: var(--muted-foreground);
  --color-accent: var(--accent);
  --color-accent-foreground: var(--accent-foreground);
  --color-destructive: var(--destructive);
  --color-destructive-foreground: var(--destructive-foreground);
  --color-border: var(--border);
  --color-input: var(--input);
  --color-ring: var(--ring);
  --color-chart-1: var(--chart-1);
  --color-chart-2: var(--chart-2);
  --color-chart-3: var(--chart-3);
  --color-chart-4: var(--chart-4);
  --color-chart-5: var(--chart-5);
  --color-sidebar: var(--sidebar);
  --color-sidebar-foreground: var(--sidebar-foreground);
  --color-sidebar-primary: var(--sidebar-primary);
  --color-sidebar-primary-foreground: var(--sidebar-primary-foreground);
  --color-sidebar-accent: var(--sidebar-accent);
  --color-sidebar-accent-foreground: var(--sidebar-accent-foreground);
  --color-sidebar-border: var(--sidebar-border);
  --color-sidebar-ring: var(--sidebar-ring);

  --font-sans: var(--font-sans);
  --font-mono: var(--font-mono);
  --font-serif: var(--font-serif);

  --radius-sm: calc(var(--radius) - 4px);
  --radius-md: calc(var(--radius) - 2px);
  --radius-lg: var(--radius);
  --radius-xl: calc(var(--radius) + 4px);

  --shadow-2xs: var(--shadow-2xs);
  --shadow-xs: var(--shadow-xs);
  --shadow-sm: var(--shadow-sm);
  --shadow: var(--shadow);
  --shadow-md: var(--shadow-md);
  --shadow-lg: var(--shadow-lg);
  --shadow-xl: var(--shadow-xl);
  --shadow-2xl: var(--shadow-2xl);
}
EOF
}

# ---------------------------------------------------------------------------
# Prereq check + install via Homebrew
# ---------------------------------------------------------------------------
step "Checking prerequisites"

command -v brew &>/dev/null || fail "Homebrew not found. Install from https://brew.sh"

# Ensure brew-installed binaries are on PATH (Apple Silicon + Intel)
eval "$(brew shellenv 2>/dev/null)" || true

# install_if_missing <command_name> <brew_formula> [<brew_flags>]
install_if_missing() {
  local cmd="$1" formula="$2"; shift 2
  if command -v "$cmd" &>/dev/null; then
    info "$cmd available"
  else
    warn "$cmd not found — brew install $formula..."
    brew install "$@" "$formula"
    info "$cmd installed"
  fi
}

# Core tools
install_if_missing go         go
install_if_missing node       node@22
install_if_missing docker     --cask docker
install_if_missing make       make

# pnpm via corepack (ships with Node, cleaner than a separate brew formula)
if command -v pnpm &>/dev/null; then
  info "pnpm available"
else
  warn "pnpm not found — enabling via corepack..."
  corepack enable
  corepack prepare pnpm@latest --activate
  info "pnpm installed"
fi

# Dev tools (all have Homebrew formulae)
install_if_missing sqlc           sqlc
install_if_missing migrate        golang-migrate
install_if_missing air            air
install_if_missing golangci-lint  golangci-lint

# oapi-codegen (no brew formula — go install)
if command -v oapi-codegen &>/dev/null; then
  info "oapi-codegen available"
else
  warn "oapi-codegen not found — go install..."
  go install github.com/oapi-codegen/oapi-codegen/v2/cmd/oapi-codegen@latest
  info "oapi-codegen installed"
fi

info "All prerequisites satisfied"

# ---------------------------------------------------------------------------
# Directory structure
# ---------------------------------------------------------------------------
step "Creating directory structure"

mkdir -p "$PROJECT" && cd "$PROJECT"
git init --quiet

mkdir -p cmd/{api,worker,seed}
mkdir -p internal
mkdir -p internal/store
mkdir -p pkg/{httputil,middleware,errors,validate}
mkdir -p migrations
mkdir -p web/src/{features,components,hooks,layouts,lib/{api,store},test}
mkdir -p web/e2e
mkdir -p ui/src/{components,lib}
mkdir -p mobile
mkdir -p docs
mkdir -p infra
mkdir -p .github/workflows

info "Directories created"

# ---------------------------------------------------------------------------
# Helper: write file (cat with heredoc). Handles all file creation below.
# ---------------------------------------------------------------------------
DATE=$(date +%Y-%m-%d)

# ---------------------------------------------------------------------------
# Root configs
# ---------------------------------------------------------------------------
step "Writing config files"

# --- .env.example ---
cat > .env.example << EOF
# — Database —
DATABASE_URL=postgresql://postgres:postgres@localhost:${PG_PORT}/${PROJECT}?sslmode=disable

# — Redis —
REDIS_URL=redis://localhost:${REDIS_PORT}

# — Auth —
JWT_SECRET=local-dev-secret-change-in-prod
JWT_ACCESS_TTL=15m
JWT_REFRESH_TTL=7d

# — Object Storage —
S3_ENDPOINT=http://localhost:${MINIO_PORT}
S3_BUCKET=${PROJECT}-media
S3_ACCESS_KEY=minioadmin
S3_SECRET_KEY=minioadmin

# — API —
API_PORT=3000
APP_ENV=development

# — Frontend —
VITE_API_URL=http://localhost:3000
EOF
cp .env.example .env

# --- .gitignore ---
cat > .gitignore << 'EOF'
# Go
bin/
tmp/
*.exe

# Node / pnpm
node_modules/
web/dist/
ui/dist/

# Environment
.env
*.env.local

# IDE
.idea/
.vscode/
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db

# Infrastructure volumes
pgdata/
miniodata/

# LLM agent / personal tooling artifacts
.agents/
.claude/
.cursor/
.aider/
.copilot/
*.skill
.claude_history
CLAUDE.md
.cursorignore
.cursorules
.aiderignore
EOF

# --- pnpm-workspace.yaml ---
cat > pnpm-workspace.yaml << 'EOF'
packages:
  - "web"
  - "ui"
EOF

# --- package.json (root) ---
cat > package.json << EOF
{
  "name": "${PROJECT}",
  "private": true,
  "packageManager": "pnpm@10.29.3",
  "scripts": {
    "dev:web": "pnpm --filter web dev",
    "build:web": "pnpm --filter web build",
    "lint:web": "pnpm --filter web lint",
    "test:web": "pnpm --filter web test"
  },
  "engines": {
    "node": ">=22"
  }
}
EOF

# --- sqlc.yaml ---
cat > sqlc.yaml << 'EOF'
version: "2"
sql:
  - engine: "postgresql"
    queries: "internal/**/queries.sql"
    schema: "migrations/"
    gen:
      go:
        package: "store"
        out: "internal/store"
        sql_package: "pgx/v5"
        emit_json_tags: true
        emit_empty_slices: true
        emit_result_struct_pointers: true
        overrides:
          - db_type: "uuid"
            go_type: "github.com/google/uuid.UUID"
          - db_type: "timestamptz"
            go_type: "time.Time"
EOF

# --- .air.toml ---
cat > .air.toml << 'EOF'
root = "."
tmp_dir = "tmp"

[build]
  cmd = "go build -o ./tmp/api ./cmd/api"
  bin = "./tmp/api"
  full_bin = "./tmp/api"
  include_ext = ["go", "sql", "yaml"]
  exclude_dir = ["tmp", "web", "ui", "mobile", "node_modules", "infra"]
  delay = 1000

[log]
  time = false

[misc]
  clean_on_exit = true
EOF

# --- api.yaml ---
cat > api.yaml << EOF
openapi: "3.1.0"
info:
  title: "${PROJECT} API"
  version: "0.1.0"
  description: "${PROJECT} API"
servers:
  - url: http://localhost:3000
    description: Local development
paths:
  /api/health:
    get:
      summary: Health check
      operationId: healthCheck
      responses:
        "200":
          description: Service is healthy
          content:
            application/json:
              schema:
                type: object
                properties:
                  status:
                    type: string
                    example: ok
components:
  schemas:
    Error:
      type: object
      required: [code, message]
      properties:
        code:
          type: string
        message:
          type: string
        details:
          type: object
    PaginationMeta:
      type: object
      required: [page, page_size, total]
      properties:
        page:
          type: integer
        page_size:
          type: integer
        total:
          type: integer
  securitySchemes:
    bearerAuth:
      type: http
      scheme: bearer
      bearerFormat: JWT
EOF

# --- Makefile ---
# NOTE: Makefile requires real tabs. Using printf to be explicit.
cat > Makefile << 'MAKEFILE_EOF'
.PHONY: help dev dev-infra dev-api dev-web migrate migrate-new migrate-down seed schema-dump generate generate-sqlc generate-types lint test test-integration test-e2e validate build
COMPOSE_PROJECT_NAME ?= $(notdir $(CURDIR))
DOCKER_COMPOSE = docker compose -p $(COMPOSE_PROJECT_NAME) -f infra/docker-compose.yml

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

dev-infra: ## Start local infrastructure (Postgres, Redis, MinIO)
	$(DOCKER_COMPOSE) up -d
	@echo "Waiting for Postgres..."
	@until $(DOCKER_COMPOSE) exec -T postgres pg_isready -U postgres > /dev/null 2>&1; do sleep 1; done
	@echo "Infrastructure ready."

dev-infra-down: ## Stop local infrastructure
	$(DOCKER_COMPOSE) down

dev: dev-infra ## Run full stack (API + web + worker)
	@make -j3 dev-api dev-web dev-worker

dev-api: ## Run Go API with hot reload
	air -c .air.toml

dev-web: ## Run frontend dev server
	cd web && pnpm dev

dev-worker: ## Run background worker
	go run ./cmd/worker/main.go

migrate: ## Apply pending migrations
	migrate -path migrations -database "$${DATABASE_URL}" up

migrate-new: ## Create new migration (usage: make migrate-new NAME=create_users)
	migrate create -ext sql -dir migrations -seq $(NAME)

migrate-down: ## Roll back last migration
	migrate -path migrations -database "$${DATABASE_URL}" down 1

seed: ## Seed database with test data
	go run ./cmd/seed/main.go

schema-dump: ## Dump current schema to schema.sql
	pg_dump --schema-only --no-owner --no-privileges "$${DATABASE_URL}" | sed '/^\\restrict /d; /^\\unrestrict /d' > schema.sql

generate: generate-sqlc schema-dump generate-types ## Run ALL code generation

generate-sqlc: ## Generate Go code from SQL queries
	sqlc generate

generate-types: ## Generate TypeScript types from api.yaml
	cd web && pnpm exec openapi-typescript ../api.yaml -o src/lib/api/schema.d.ts

lint: ## Lint Go + TypeScript
	golangci-lint run ./...
	cd web && pnpm typecheck
	cd web && pnpm lint

test: ## Run unit tests (Go + TypeScript)
	go test ./... -short
	cd web && pnpm test

test-integration: ## Run integration tests (requires running DB)
	go test ./... -run Integration

test-e2e: ## Run Playwright E2E tests
	cd web && pnpm exec playwright test

validate: generate ## Regenerate everything and check for drift
	@if [ -n "$$(git diff --name-only)" ]; then \
		echo "ERROR: Generated files are out of sync. Run 'make generate' and commit the results."; \
		git diff --name-only; \
		exit 1; \
	fi
	@echo "All generated files are in sync."

build: ## Build Go binaries + web assets
	CGO_ENABLED=0 go build -o bin/api ./cmd/api
	CGO_ENABLED=0 go build -o bin/worker ./cmd/worker
	cd web && pnpm build
MAKEFILE_EOF

info "Config files written"

# ---------------------------------------------------------------------------
# Docker Compose
# ---------------------------------------------------------------------------
step "Writing infrastructure config"

cat > infra/docker-compose.yml << EOF
services:
  postgres:
    image: postgres:17-alpine
    ports:
      - "${PG_PORT}:5432"
    environment:
      POSTGRES_DB: ${PROJECT}
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
    volumes:
      - pgdata:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 5s
      timeout: 3s
      retries: 5

  redis:
    image: redis:7-alpine
    ports:
      - "${REDIS_PORT}:6379"
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 5s
      timeout: 3s
      retries: 5

  minio:
    image: minio/minio
    ports:
      - "${MINIO_PORT}:9000"
      - "${MINIO_CONSOLE_PORT}:9001"
    environment:
      MINIO_ROOT_USER: minioadmin
      MINIO_ROOT_PASSWORD: minioadmin
    command: server /data --console-address ":9001"
    volumes:
      - miniodata:/data

volumes:
  pgdata:
  miniodata:
EOF

info "Docker Compose written"

# ---------------------------------------------------------------------------
# Go code
# ---------------------------------------------------------------------------
step "Writing Go source files"

# --- cmd/api/main.go ---
cat > cmd/api/main.go << EOF
package main

import (
	"context"
	"fmt"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/cors"
	chiMiddleware "github.com/go-chi/chi/v5/middleware"
	"github.com/joho/godotenv"
)

func main() {
	_ = godotenv.Load()

	port := os.Getenv("API_PORT")
	if port == "" {
		port = "3000"
	}
	dbURL := os.Getenv("DATABASE_URL")
	if dbURL == "" {
		slog.Error("DATABASE_URL is required")
		os.Exit(1)
	}

	// TODO: Initialize database connection pool
	// TODO: Initialize Redis client (if needed)
	// TODO: Initialize services and handlers
	// TODO: Register module routes

	r := chi.NewRouter()
	r.Use(chiMiddleware.RequestID)
	r.Use(chiMiddleware.RealIP)
	r.Use(chiMiddleware.Recoverer)
	r.Use(cors.Handler(cors.Options{
		AllowedOrigins:   []string{"http://localhost:5173", "http://127.0.0.1:5173"},
		AllowedMethods:   []string{"GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"},
		AllowedHeaders:   []string{"Accept", "Authorization", "Content-Type"},
		ExposedHeaders:   []string{"Link"},
		AllowCredentials: true,
		MaxAge:           300,
	}))

	r.Get("/api/health", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		if _, err := w.Write([]byte(\`{"status":"ok"}\`)); err != nil {
			slog.Error("failed to write health response", "err", err)
		}
	})

	srv := &http.Server{
		Addr:         ":" + port,
		Handler:      r,
		ReadTimeout:  10 * time.Second,
		WriteTimeout: 30 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	go func() {
		slog.Info(fmt.Sprintf("API server starting on :%s", port))
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			slog.Error("server error", "err", err)
			os.Exit(1)
		}
	}()

	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	slog.Info("Shutting down server...")
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	if err := srv.Shutdown(ctx); err != nil {
		slog.Error("shutdown error", "err", err)
	}
}
EOF

# --- cmd/worker/main.go ---
cat > cmd/worker/main.go << 'EOF'
package main

import (
	"log/slog"
	"os"
	"os/signal"
	"syscall"

	"github.com/joho/godotenv"
)

func main() {
	_ = godotenv.Load()
	slog.Info("Worker starting...")

	// TODO: Initialize worker processing loop

	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit
	slog.Info("Worker shutting down...")
}
EOF

# --- cmd/seed/main.go ---
cat > cmd/seed/main.go << 'EOF'
package main

import (
	"log/slog"

	"github.com/joho/godotenv"
)

func main() {
	_ = godotenv.Load()
	slog.Info("Seeding database...")

	// TODO: Connect to DB and insert deterministic test data

	slog.Info("Seed complete.")
}
EOF

# --- pkg/httputil/response.go ---
cat > pkg/httputil/response.go << 'EOF'
package httputil

import (
	"encoding/json"
	"net/http"
)

type DataResponse struct {
	Data interface{} `json:"data"`
}

type PagedResponse struct {
	Data interface{} `json:"data"`
	Meta PageMeta    `json:"meta"`
}

type PageMeta struct {
	Page     int `json:"page"`
	PageSize int `json:"page_size"`
	Total    int `json:"total"`
}

type ErrorBody struct {
	Code    string      `json:"code"`
	Message string      `json:"message"`
	Details interface{} `json:"details,omitempty"`
}

type ErrorResponse struct {
	Error ErrorBody `json:"error"`
}

func writeJSON(w http.ResponseWriter, payload interface{}) {
	if err := json.NewEncoder(w).Encode(payload); err != nil {
		http.Error(w, `{"error":{"code":"INTERNAL_ERROR","message":"Failed to encode response"}}`, http.StatusInternalServerError)
	}
}

func JSON(w http.ResponseWriter, status int, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	writeJSON(w, DataResponse{Data: data})
}

func PagedJSON(w http.ResponseWriter, data interface{}, page, pageSize, total int) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	writeJSON(w, PagedResponse{
		Data: data,
		Meta: PageMeta{Page: page, PageSize: pageSize, Total: total},
	})
}

func Error(w http.ResponseWriter, status int, code, message string) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	writeJSON(w, ErrorResponse{
		Error: ErrorBody{Code: code, Message: message},
	})
}

func ValidationError(w http.ResponseWriter, details interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusUnprocessableEntity)
	writeJSON(w, ErrorResponse{
		Error: ErrorBody{
			Code:    "VALIDATION_ERROR",
			Message: "Request validation failed",
			Details: details,
		},
	})
}
EOF

# --- pkg/errors/codes.go ---
cat > pkg/errors/codes.go << 'EOF'
package errors

const (
	CodeInternalError   = "INTERNAL_ERROR"
	CodeNotFound        = "NOT_FOUND"
	CodeValidationError = "VALIDATION_ERROR"
	CodeDuplicate       = "DUPLICATE"
	CodeUnauthenticated = "UNAUTHENTICATED"
	CodeForbidden       = "FORBIDDEN"
	CodeTokenExpired    = "TOKEN_EXPIRED"
	CodeRateLimited     = "RATE_LIMITED"
)
EOF

# --- internal/system/queries.sql ---
mkdir -p internal/system
cat > internal/system/queries.sql << 'EOF'
-- Placeholder query so sqlc generation succeeds on a fresh scaffold.
-- Replace with module-specific queries as features are implemented.

-- name: Ping :one
SELECT 1;
EOF

info "Go source files written"

# ---------------------------------------------------------------------------
# Frontend code
# ---------------------------------------------------------------------------
step "Writing frontend source files"

# --- web/package.json ---
cat > web/package.json << EOF
{
  "name": "@${PROJECT}/web",
  "private": true,
  "version": "0.1.0",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "tsc --noEmit && vite build",
    "preview": "vite preview",
    "lint": "eslint .",
    "typecheck": "tsc --noEmit",
    "test": "vitest run",
    "test:watch": "vitest",
    "test:coverage": "vitest run --coverage"
  }
}
EOF

# --- ui/package.json ---
cat > ui/package.json << EOF
{
  "name": "@${PROJECT}/ui",
  "private": true,
  "version": "0.1.0",
  "type": "module"
}
EOF

# --- web/index.html ---
cat > web/index.html << EOF
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>${PROJECT}</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.tsx"></script>
  </body>
</html>
EOF

# --- web/tsconfig.json ---
cat > web/tsconfig.json << 'EOF'
{
  "compilerOptions": {
    "baseUrl": ".",
    "paths": {
      "@/*": ["./src/*"],
      "@ui/*": ["../ui/src/*"]
    }
  },
  "files": [],
  "references": [
    { "path": "./tsconfig.app.json" },
    { "path": "./tsconfig.node.json" }
  ]
}
EOF

# --- web/tsconfig.app.json ---
cat > web/tsconfig.app.json << 'EOF'
{
  "compilerOptions": {
    "composite": true,
    "target": "ES2022",
    "module": "ESNext",
    "moduleResolution": "bundler",
    "lib": ["ES2022", "DOM", "DOM.Iterable"],
    "jsx": "react-jsx",
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "skipLibCheck": true,
    "noEmit": true,
    "types": ["vite/client"],
    "baseUrl": ".",
    "paths": {
      "@/*": ["./src/*"],
      "@ui/*": ["../ui/src/*"]
    }
  },
  "include": ["src"]
}
EOF

# --- web/tsconfig.node.json ---
cat > web/tsconfig.node.json << 'EOF'
{
  "compilerOptions": {
    "composite": true,
    "target": "ES2023",
    "module": "ESNext",
    "moduleResolution": "bundler",
    "lib": ["ES2023"],
    "strict": true,
    "skipLibCheck": true,
    "noEmit": true,
    "types": ["node"]
  },
  "include": ["vite.config.ts", "vitest.config.ts", "eslint.config.js"]
}
EOF

# --- web/vite.config.ts ---
cat > web/vite.config.ts << 'EOF'
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import tailwindcss from '@tailwindcss/vite';
import { fileURLToPath, URL } from 'node:url';

export default defineConfig({
  plugins: [react(), tailwindcss()],
  resolve: {
    alias: {
      '@': fileURLToPath(new URL('./src', import.meta.url)),
      '@ui': fileURLToPath(new URL('../ui/src', import.meta.url)),
    },
  },
  server: {
    port: 5173,
    proxy: {
      '/api': {
        target: 'http://localhost:3000',
        changeOrigin: true,
      },
    },
  },
});
EOF

# --- web/vitest.config.ts ---
cat > web/vitest.config.ts << 'EOF'
import { defineConfig } from 'vitest/config';
import react from '@vitejs/plugin-react';
import tailwindcss from '@tailwindcss/vite';
import { fileURLToPath, URL } from 'node:url';

export default defineConfig({
  plugins: [react(), tailwindcss()],
  resolve: {
    alias: {
      '@': fileURLToPath(new URL('./src', import.meta.url)),
      '@ui': fileURLToPath(new URL('../ui/src', import.meta.url)),
    },
  },
  test: {
    environment: 'jsdom',
    setupFiles: './src/test/setup.ts',
    globals: true,
    css: true,
    coverage: {
      provider: 'v8',
      reporter: ['text', 'html'],
    },
  },
});
EOF

# --- web/eslint.config.js ---
cat > web/eslint.config.js << 'EOF'
import js from '@eslint/js';
import globals from 'globals';
import tsParser from '@typescript-eslint/parser';
import tsPlugin from '@typescript-eslint/eslint-plugin';
import reactHooks from 'eslint-plugin-react-hooks';
import reactRefresh from 'eslint-plugin-react-refresh';

export default [
  {
    ignores: ['dist', 'coverage'],
  },
  js.configs.recommended,
  {
    files: ['**/*.{ts,tsx}'],
    languageOptions: {
      parser: tsParser,
      parserOptions: {
        ecmaVersion: 'latest',
        sourceType: 'module',
        ecmaFeatures: { jsx: true },
      },
      globals: {
        ...globals.browser,
        ...globals.node,
        ...globals.vitest,
      },
    },
    plugins: {
      '@typescript-eslint': tsPlugin,
      'react-hooks': reactHooks,
      'react-refresh': reactRefresh,
    },
    rules: {
      ...tsPlugin.configs.recommended.rules,
      ...reactHooks.configs.recommended.rules,
      'no-undef': 'off',
      'react-refresh/only-export-components': ['warn', { allowConstantExport: true }],
    },
  },
  {
    files: ['src/components/ui/**/*.{ts,tsx}'],
    rules: {
      'react-refresh/only-export-components': 'off',
    },
  },
];
EOF

# --- web/src/main.tsx ---
cat > web/src/main.tsx << 'EOF'
import React from 'react';
import ReactDOM from 'react-dom/client';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { ReactQueryDevtools } from '@tanstack/react-query-devtools';
import App from './App';
import './index.css';

const queryClient = new QueryClient();

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <QueryClientProvider client={queryClient}>
      <App />
      <ReactQueryDevtools initialIsOpen={false} />
    </QueryClientProvider>
  </React.StrictMode>
);
EOF

# --- web/src/App.tsx ---
cat > web/src/App.tsx << EOF
import { useAppStore } from '@/lib/store/app-store';

export default function App() {
  const sidebarOpen = useAppStore((s) => s.sidebarOpen);
  const toggleSidebar = useAppStore((s) => s.toggleSidebar);

  return (
    <div className="min-h-screen flex items-center justify-center bg-slate-50 p-6">
      <div className="w-full max-w-xl rounded-xl border bg-white p-8 shadow-sm">
        <h1 className="text-2xl font-bold text-slate-900">${PROJECT}</h1>
        <p className="mt-2 text-slate-600">
          Scaffolded with React, TanStack Query, Zustand, Tailwind v4, shadcn/ui, and the modern-minimal theme baseline.
        </p>
        <button
          type="button"
          className="mt-6 rounded-md bg-slate-900 px-4 py-2 text-sm font-medium text-white hover:bg-slate-700"
          onClick={toggleSidebar}
        >
          Toggle state store (sidebarOpen: {String(sidebarOpen)})
        </button>
      </div>
    </div>
  );
}
EOF

# --- web/src/index.css ---
cat > web/src/index.css << 'EOF'
@import "tailwindcss";
EOF

# --- web/src/lib/utils.ts ---
cat > web/src/lib/utils.ts << 'EOF'
import { type ClassValue, clsx } from 'clsx';
import { twMerge } from 'tailwind-merge';

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}
EOF

# --- web/src/lib/store/app-store.ts ---
cat > web/src/lib/store/app-store.ts << 'EOF'
import { create } from 'zustand';

type AppState = {
  sidebarOpen: boolean;
  toggleSidebar: () => void;
};

export const useAppStore = create<AppState>((set) => ({
  sidebarOpen: false,
  toggleSidebar: () =>
    set((state) => ({
      sidebarOpen: !state.sidebarOpen,
    })),
}));
EOF

# --- web/src/test/setup.ts ---
cat > web/src/test/setup.ts << 'EOF'
import '@testing-library/jest-dom/vitest';
EOF

# --- web/src/App.test.tsx ---
cat > web/src/App.test.tsx << 'EOF'
import { render, screen } from '@testing-library/react';
import App from './App';

describe('App', () => {
  it('renders project title', () => {
    render(<App />);
    expect(screen.getByText(/Scaffolded with React/i)).toBeInTheDocument();
  });
});
EOF

# --- web/src/lib/api/schema.d.ts (placeholder) ---
cat > web/src/lib/api/schema.d.ts << 'EOF'
// GENERATED — do not edit. Run `make generate-types` to regenerate from api.yaml.
// Placeholder so TypeScript compiles before first generation.
export interface paths {
  '/api/health': {
    get: {
      responses: {
        200: {
          content: {
            'application/json': { status: string };
          };
        };
      };
    };
  };
}
EOF

info "Frontend source files written"

# ---------------------------------------------------------------------------
# CI
# ---------------------------------------------------------------------------
step "Writing CI pipeline"

cat > .github/workflows/ci.yml << EOF
name: CI

on:
  pull_request:
    branches: [main]
  push:
    branches: [main]

jobs:
  validate:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:17-alpine
        env:
          POSTGRES_DB: ${PROJECT}_test
          POSTGRES_USER: postgres
          POSTGRES_PASSWORD: postgres
        ports:
          - 5432:5432
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5

    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-go@v5
        with:
          go-version: '1.24'
      - uses: actions/setup-node@v4
        with:
          node-version: '22'
      - uses: pnpm/action-setup@v4
        with:
          version: 10

      - name: Install Go tools
        run: |
          go install github.com/sqlc-dev/sqlc/cmd/sqlc@latest
          go install -tags 'postgres' github.com/golang-migrate/migrate/v4/cmd/migrate@latest

      - name: Install frontend dependencies
        run: pnpm install --frozen-lockfile

      - name: Run migrations
        env:
          DATABASE_URL: postgresql://postgres:postgres@localhost:5432/${PROJECT}_test?sslmode=disable
        run: make migrate

      - name: Validate (generate check)
        run: make validate

      - name: Lint
        run: make lint

      - name: Test
        run: make test

      - name: Test (integration)
        env:
          DATABASE_URL: postgresql://postgres:postgres@localhost:5432/${PROJECT}_test?sslmode=disable
        run: make test-integration

      - name: Build
        run: make build
EOF

info "CI pipeline written"

# ---------------------------------------------------------------------------
# Documentation stubs
# ---------------------------------------------------------------------------
step "Writing documentation stubs"

# --- progress.md ---
cat > progress.md << EOF
# Progress

> Keep this short. Pull story IDs and scope from docs/epic.md.
> Last updated: ${DATE}

## Done
- (none yet)

## Inactive / Blocked
- (none)

## Needs Rework
- (none)

## Next Up
- (none)
EOF

# --- empty doc stubs (content comes from PM / tech lead) ---
for doc in docs/epic.md docs/prd.md docs/onepager.md docs/architecture.md; do
  if [[ ! -f "$doc" ]]; then
    echo "# $(basename "$doc" .md) — TODO" > "$doc"
  fi
done

info "Documentation stubs written"

# ---------------------------------------------------------------------------
# Placeholder migration (empty — user fills in from epic data model)
# ---------------------------------------------------------------------------
step "Creating placeholder migration"

cat > migrations/000001_initial.up.sql << 'EOF'
-- Initial migration: create MVP tables here.
-- See docs/epic.md data model section for planning intent.
-- After editing, run: make migrate && make schema-dump && make generate-sqlc
EOF

cat > migrations/000001_initial.down.sql << 'EOF'
-- Reverse the initial migration.
-- Drop tables in reverse dependency order.
EOF

info "Placeholder migration created"

# ---------------------------------------------------------------------------
# Initialize Go module + deps
# ---------------------------------------------------------------------------
step "Initializing Go module"

go mod init "github.com/${ORG}/${PROJECT}"

go get github.com/go-chi/chi/v5
go get github.com/go-chi/cors
go get github.com/go-playground/validator/v10
go get github.com/jackc/pgx/v5
go get github.com/jackc/pgx/v5/pgxpool
go get github.com/redis/go-redis/v9
go get github.com/google/uuid
go get github.com/golang-jwt/jwt/v5
go get github.com/joho/godotenv
go get github.com/stretchr/testify

# Register codegen tools (Go 1.24+ tool directive)
go get -tool github.com/oapi-codegen/oapi-codegen/v2/cmd/oapi-codegen@latest 2>/dev/null || true
go get -tool github.com/sqlc-dev/sqlc/cmd/sqlc@latest 2>/dev/null || true

go mod tidy

info "Go module initialized"

# ---------------------------------------------------------------------------
# Initialize frontend
# ---------------------------------------------------------------------------
step "Initializing frontend packages"

# web runtime dependencies
pnpm --dir web add react react-dom react-router-dom
pnpm --dir web add @tanstack/react-query @tanstack/react-query-devtools
pnpm --dir web add zustand zod react-hook-form @hookform/resolvers
pnpm --dir web add clsx tailwind-merge class-variance-authority lucide-react

# web development dependencies
pnpm --dir web add -D typescript vite @vitejs/plugin-react @tailwindcss/vite tailwindcss
pnpm --dir web add -D @types/react @types/react-dom @types/node
pnpm --dir web add -D openapi-typescript
pnpm --dir web add -D eslint@^9 @eslint/js@^9 globals
pnpm --dir web add -D @typescript-eslint/parser @typescript-eslint/eslint-plugin
pnpm --dir web add -D eslint-plugin-react-hooks eslint-plugin-react-refresh
pnpm --dir web add -D vitest @vitest/coverage-v8 jsdom @testing-library/react @testing-library/jest-dom @testing-library/user-event
pnpm --dir web add -D @playwright/test

# Install from root to link workspaces
pnpm install

# Initialize shadcn/ui (non-interactive when supported by CLI flags).
if (cd web && pnpm dlx shadcn@latest init --yes --base-color zinc); then
  info "shadcn/ui initialized"
else
  warn "shadcn init did not complete automatically; generating fallback components config."
fi

# Ensure components config exists so add/theme commands never prompt for first-run setup.
if [[ ! -f web/components.json ]]; then
  warn "web/components.json missing after init; writing fallback config."
  cat > web/components.json << 'EOF'
{
  "$schema": "https://ui.shadcn.com/schema.json",
  "style": "new-york",
  "rsc": false,
  "tsx": true,
  "tailwind": {
    "config": "",
    "css": "src/index.css",
    "baseColor": "zinc",
    "cssVariables": true,
    "prefix": ""
  },
  "aliases": {
    "components": "@/components",
    "utils": "@/lib/utils",
    "ui": "@/components/ui",
    "lib": "@/lib",
    "hooks": "@/hooks"
  },
  "iconLibrary": "lucide"
}
EOF
fi

# Add common starter components if CLI supports non-interactive add.
if (cd web && pnpm dlx shadcn@latest add button card input form sonner --yes); then
  info "shadcn/ui starter components added"
else
  warn "shadcn add components did not run automatically."
fi

# Apply default theme from tweakcn (modern-minimal) for consistent baseline.
if (cd web && pnpm dlx shadcn@latest add https://tweakcn.com/r/themes/modern-minimal.json --yes); then
  info "shadcn/ui modern-minimal theme applied"
else
  warn "Theme install via shadcn CLI failed — writing modern-minimal theme tokens directly to web/src/index.css"
  write_modern_minimal_theme_css
  info "modern-minimal theme tokens applied to web/src/index.css"
fi

info "Frontend packages initialized"

# ---------------------------------------------------------------------------
# Initial commit
# ---------------------------------------------------------------------------
step "Creating initial commit"

git add -A
git commit -m "chore: scaffold ${PROJECT} repo

Generated by bootstrap.sh. Stack: Go + TypeScript + PostgreSQL + Redis.
Slice 0 foundation — run 'make dev-infra && make migrate && make dev' to start."

info "Initial commit created"

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}  Project '${PROJECT}' scaffolded successfully.${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""
echo "Next steps:"
echo "  1. cd ${PROJECT}"
echo "  2. Edit migrations/000001_initial.up.sql with your data model"
echo "  3. Edit migrations/000001_initial.down.sql with the reverse"
echo "  4. Copy AGENTS.md into the repo root"
echo "  5. Fill in docs/epic.md, docs/prd.md, docs/onepager.md"
echo "  6. Run:"
echo "       make dev-infra"
echo "       make migrate"
echo "       make schema-dump"
echo "       make generate"
echo "       make dev"
echo "  7. Optional (for E2E): cd web && pnpm exec playwright install"
echo "  8. Verify: curl http://localhost:3000/api/health"
echo ""
