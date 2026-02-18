.PHONY: help new bootstrap bio install-global

help: ## Show available template commands
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-12s\033[0m %s\n", $$1, $$2}'

new: ## Create a new project repo (usage: make new PROJECT=myapp [ORG=myorg] [DEST=/path] [DRY_RUN=1])
	@if [ -z "$(PROJECT)" ]; then \
		echo "Usage: make new PROJECT=myapp [ORG=myorg] [DEST=/path] [DRY_RUN=1]"; \
		exit 1; \
	fi
	@set -- --project "$(PROJECT)"; \
	if [ -n "$(ORG)" ]; then set -- "$$@" --org "$(ORG)"; fi; \
	if [ -n "$(DEST)" ]; then set -- "$$@" --dest "$(DEST)"; fi; \
	if [ "$(DRY_RUN)" = "1" ]; then set -- "$$@" --dry-run; fi; \
	./scripts/new-project.sh "$$@"

bootstrap: new ## Alias for new

bio: new ## Short alias for new (requested shortcut)

install-global: ## Install global scaffold command (usage: make install-global [CMD=bio] [MODE=here|new-dir] [BIN_DIR=~/.local/bin])
	@set --; \
	if [ -n "$(CMD)" ]; then set -- "$$@" --name "$(CMD)"; fi; \
	if [ -n "$(MODE)" ]; then set -- "$$@" --mode "$(MODE)"; fi; \
	if [ -n "$(BIN_DIR)" ]; then set -- "$$@" --bin-dir "$(BIN_DIR)"; fi; \
	./scripts/install-global-command.sh "$$@"
