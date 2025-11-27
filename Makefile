# Waypoint - Modular Claude Configuration Manager
# Root Makefile - Handles all module operations

# Configuration
CLAUDE_DIR ?= $(HOME)/.claude
MODE ?= symlink
MODULES := working-tree claire terraform

# Colors for output
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
NC := \033[0m

# Default target
.PHONY: help
help:
	@echo "$(BLUE)Waypoint - Claude Configuration Manager$(NC)"
	@echo ""
	@echo "$(GREEN)Usage:$(NC)"
	@echo "  make [target] [MODULE]                   Operate on all or specific module"
	@echo "  make [target] CLAUDE_DIR=/path           Override installation directory"
	@echo "  make [target] MODE=copy                  Copy files instead of symlinking"
	@echo ""
	@echo "$(GREEN)Targets:$(NC)"
	@echo "  help              Show this help message (default)"
	@echo "  install [MOD]     Install modules to $(CLAUDE_DIR)"
	@echo "  uninstall [MOD]   Remove installed modules"
	@echo "  check [MOD]       Verify installation is correct"
	@echo "  fix [MOD]         Repair broken or missing symlinks"
	@echo "  list [MOD]        Show what would be installed (dry-run)"
	@echo "  manifest          Update plugin.json files from directory contents"
	@echo "  changelog-preview Show commits since last version tag"
	@echo "  version V=x.y.z   Bump version in all plugin.json files"
	@echo "  clean             Remove local build artifacts"
	@echo ""
	@echo "$(GREEN)Testing:$(NC)"
	@echo "  Run tests with:   make -f Makefile.test test"
	@echo ""
	@echo "$(GREEN)Available Modules:$(NC)"
	@echo "  working-tree      Git worktree management with AI context"
	@echo "  claire            Claude agent/command/skill optimizer with doc-fetching"
	@echo "  terraform         Terraform workflow support for infrastructure as code"
	@echo ""
	@echo "$(GREEN)Examples:$(NC)"
	@echo "  make install                             Install everything to ~/.claude/"
	@echo "  make install working-tree                Install just working-tree module"
	@echo "  make CLAUDE_DIR=./.claude install        Install to project directory"
	@echo "  make MODE=copy install                   Copy instead of symlink"
	@echo "  make check                               Verify all installations"
	@echo "  make fix working-tree                    Repair working-tree module"
	@echo ""
	@echo "$(YELLOW)Current Configuration:$(NC)"
	@echo "  CLAUDE_DIR = $(CLAUDE_DIR)"
	@echo "  MODE       = $(MODE)"

# Parse arguments for module-specific operations
MODULE_ARG := $(filter $(MODULES),$(MAKECMDGOALS))
ifneq ($(MODULE_ARG),)
SELECTED_MODULES := $(MODULE_ARG)
else
SELECTED_MODULES := $(MODULES)
endif

# Helper function to install a module
define install_module
	@echo "$(BLUE)→ Installing module: $(1)$(NC)"
	@mkdir -p $(CLAUDE_DIR)/agents/$(1)
	@mkdir -p $(CLAUDE_DIR)/commands/$(1)
	@mkdir -p $(CLAUDE_DIR)/skills/$(1)
	@if [ -d "$(1)/agents" ]; then \
		for file in $(1)/agents/*.md; do \
			[ -f "$$file" ] || continue; \
			dest=$(CLAUDE_DIR)/agents/$(1)/$$(basename $$file); \
			if [ "$(MODE)" = "copy" ]; then \
				cp -f $$file $$dest; \
				echo "$(GREEN)    ✓ Copied agent: $$(basename $$file)$(NC)"; \
			else \
				ln -sf $$(pwd)/$$file $$dest; \
				echo "$(GREEN)    ✓ Linked agent: $$(basename $$file)$(NC)"; \
			fi; \
		done; \
	fi
	@if [ -d "$(1)/commands" ]; then \
		for file in $(1)/commands/*.md; do \
			[ -f "$$file" ] || continue; \
			dest=$(CLAUDE_DIR)/commands/$(1)/$$(basename $$file); \
			if [ "$(MODE)" = "copy" ]; then \
				cp -f $$file $$dest; \
				echo "$(GREEN)    ✓ Copied command: $$(basename $$file)$(NC)"; \
			else \
				ln -sf $$(pwd)/$$file $$dest; \
				echo "$(GREEN)    ✓ Linked command: $$(basename $$file)$(NC)"; \
			fi; \
		done; \
	fi
	@if [ -d "$(1)/skills" ]; then \
		for skilldir in $(1)/skills/*/; do \
			[ -d "$$skilldir" ] || continue; \
			skillname=$$(basename $$skilldir); \
			dest=$(CLAUDE_DIR)/skills/$(1)/$$skillname; \
			if [ "$(MODE)" = "copy" ]; then \
				mkdir -p $$dest; \
				cp -rf $$skilldir* $$dest/; \
				echo "$(GREEN)    ✓ Copied skill: $$skillname$(NC)"; \
			else \
				ln -sf $$(pwd)/$$skilldir $$dest; \
				echo "$(GREEN)    ✓ Linked skill: $$skillname$(NC)"; \
			fi; \
		done; \
	fi
endef

# Helper function to uninstall a module
define uninstall_module
	@echo "$(BLUE)→ Uninstalling module: $(1)$(NC)"
	@if [ -d "$(CLAUDE_DIR)/agents/$(1)" ]; then \
		rm -rf $(CLAUDE_DIR)/agents/$(1); \
		echo "$(GREEN)    ✓ Removed $(CLAUDE_DIR)/agents/$(1)$(NC)"; \
	else \
		echo "$(YELLOW)    - $(CLAUDE_DIR)/agents/$(1) not found$(NC)"; \
	fi
	@if [ -d "$(CLAUDE_DIR)/commands/$(1)" ]; then \
		rm -rf $(CLAUDE_DIR)/commands/$(1); \
		echo "$(GREEN)    ✓ Removed $(CLAUDE_DIR)/commands/$(1)$(NC)"; \
	else \
		echo "$(YELLOW)    - $(CLAUDE_DIR)/commands/$(1) not found$(NC)"; \
	fi
	@if [ -d "$(CLAUDE_DIR)/skills/$(1)" ]; then \
		rm -rf $(CLAUDE_DIR)/skills/$(1); \
		echo "$(GREEN)    ✓ Removed $(CLAUDE_DIR)/skills/$(1)$(NC)"; \
	else \
		echo "$(YELLOW)    - $(CLAUDE_DIR)/skills/$(1) not found$(NC)"; \
	fi
endef

# Helper function to check a module
define check_module
	@echo "$(BLUE)→ Checking module: $(1)$(NC)"
	@if [ -d "$(CLAUDE_DIR)/agents/$(1)" ]; then \
		echo "$(GREEN)    ✓ Directory exists: agents$(NC)"; \
	else \
		echo "$(RED)    ✗ Directory missing: agents$(NC)"; \
	fi
	@if [ -d "$(CLAUDE_DIR)/commands/$(1)" ]; then \
		echo "$(GREEN)    ✓ Directory exists: commands$(NC)"; \
	else \
		echo "$(RED)    ✗ Directory missing: commands$(NC)"; \
	fi
	@if [ -d "$(1)/agents" ]; then \
		for file in $(1)/agents/*.md; do \
			[ -f "$$file" ] || continue; \
			dest=$(CLAUDE_DIR)/agents/$(1)/$$(basename $$file); \
			if [ ! -e "$$dest" ]; then \
				echo "$(RED)    ✗ Missing agent: $$(basename $$file)$(NC)"; \
			elif [ "$(MODE)" = "symlink" ] && [ -L "$$dest" ]; then \
				target=$$(readlink "$$dest"); \
				if [ "$$target" = "$$(pwd)/$$file" ]; then \
					echo "$(GREEN)    ✓ Valid agent: $$(basename $$file)$(NC)"; \
				else \
					echo "$(YELLOW)    ⚠ Wrong target agent: $$(basename $$file) → $$target$(NC)"; \
				fi; \
			elif [ "$(MODE)" = "symlink" ] && [ ! -L "$$dest" ]; then \
				echo "$(YELLOW)    ⚠ Not a symlink agent: $$(basename $$file)$(NC)"; \
			else \
				echo "$(GREEN)    ✓ Exists agent: $$(basename $$file)$(NC)"; \
			fi; \
		done; \
	fi
	@if [ -d "$(1)/commands" ]; then \
		for file in $(1)/commands/*.md; do \
			[ -f "$$file" ] || continue; \
			dest=$(CLAUDE_DIR)/commands/$(1)/$$(basename $$file); \
			if [ ! -e "$$dest" ]; then \
				echo "$(RED)    ✗ Missing command: $$(basename $$file)$(NC)"; \
			elif [ "$(MODE)" = "symlink" ] && [ -L "$$dest" ]; then \
				target=$$(readlink "$$dest"); \
				if [ "$$target" = "$$(pwd)/$$file" ]; then \
					echo "$(GREEN)    ✓ Valid command: $$(basename $$file)$(NC)"; \
				else \
					echo "$(YELLOW)    ⚠ Wrong target command: $$(basename $$file) → $$target$(NC)"; \
				fi; \
			elif [ "$(MODE)" = "symlink" ] && [ ! -L "$$dest" ]; then \
				echo "$(YELLOW)    ⚠ Not a symlink command: $$(basename $$file)$(NC)"; \
			else \
				echo "$(GREEN)    ✓ Exists command: $$(basename $$file)$(NC)"; \
			fi; \
		done; \
	fi
	@if [ -d "$(1)/skills" ]; then \
		for skilldir in $(1)/skills/*/; do \
			[ -d "$$skilldir" ] || continue; \
			skillname=$$(basename $$skilldir); \
			dest=$(CLAUDE_DIR)/skills/$(1)/$$skillname; \
			if [ ! -e "$$dest" ]; then \
				echo "$(RED)    ✗ Missing skill: $$skillname$(NC)"; \
			elif [ "$(MODE)" = "symlink" ] && [ -L "$$dest" ]; then \
				target=$$(readlink "$$dest"); \
				if [ "$$target" = "$$(pwd)/$$skilldir" ]; then \
					echo "$(GREEN)    ✓ Valid skill: $$skillname$(NC)"; \
				else \
					echo "$(YELLOW)    ⚠ Wrong target skill: $$skillname → $$target$(NC)"; \
				fi; \
			else \
				echo "$(GREEN)    ✓ Exists skill: $$skillname$(NC)"; \
			fi; \
		done; \
	fi
endef

# Helper function to list module files
define list_module
	@echo "$(BLUE)→ Module: $(1)$(NC)"
	@echo "$(BLUE)  Agents → $(CLAUDE_DIR)/agents/$(1)/$(NC)"
	@if [ -d "$(1)/agents" ]; then \
		for file in $(1)/agents/*.md; do \
			[ -f "$$file" ] || continue; \
			echo "    $(MODE): $$(basename $$file)"; \
		done; \
	fi
	@echo "$(BLUE)  Commands → $(CLAUDE_DIR)/commands/$(1)/$(NC)"
	@if [ -d "$(1)/commands" ]; then \
		for file in $(1)/commands/*.md; do \
			[ -f "$$file" ] || continue; \
			echo "    $(MODE): $$(basename $$file)"; \
		done; \
	fi
	@echo "$(BLUE)  Skills → $(CLAUDE_DIR)/skills/$(1)/$(NC)"
	@if [ -d "$(1)/skills" ]; then \
		for skilldir in $(1)/skills/*/; do \
			[ -d "$$skilldir" ] || continue; \
			echo "    $(MODE): $$(basename $$skilldir)"; \
		done; \
	fi
endef

# Install all or specific module(s)
.PHONY: install $(MODULES)
install: $(SELECTED_MODULES)
ifeq ($(SELECTED_MODULES),$(MODULES))
	@echo "$(GREEN)✓ All modules installed successfully$(NC)"
endif

$(MODULES):
ifeq ($(filter install,$(MAKECMDGOALS)),install)
	$(call install_module,$@)
endif

# Uninstall all or specific module(s)
.PHONY: uninstall
uninstall:
	@$(foreach mod,$(SELECTED_MODULES),$(MAKE) uninstall-module MODULE=$(mod) CLAUDE_DIR=$(CLAUDE_DIR) MODE=$(MODE);)
	@echo "$(GREEN)✓ Modules uninstalled successfully$(NC)"

.PHONY: uninstall-module
uninstall-module:
	$(call uninstall_module,$(MODULE))

# Check installation status
.PHONY: check
check:
	@echo "$(BLUE)Checking installation status...$(NC)"
	@$(foreach mod,$(SELECTED_MODULES),$(MAKE) check-module MODULE=$(mod) CLAUDE_DIR=$(CLAUDE_DIR) MODE=$(MODE);)

.PHONY: check-module
check-module:
	$(call check_module,$(MODULE))

# Fix broken symlinks
.PHONY: fix
fix:
	@echo "$(BLUE)Repairing installations...$(NC)"
	@$(foreach mod,$(SELECTED_MODULES),$(MAKE) fix-module MODULE=$(mod) CLAUDE_DIR=$(CLAUDE_DIR) MODE=$(MODE);)
	@echo "$(GREEN)✓ Repairs complete$(NC)"

.PHONY: fix-module
fix-module:
	$(call install_module,$(MODULE))

# List what would be installed (dry-run)
.PHONY: list
list:
	@echo "$(BLUE)Installation preview for: $(CLAUDE_DIR)$(NC)"
	@$(foreach mod,$(SELECTED_MODULES),$(MAKE) list-module MODULE=$(mod) CLAUDE_DIR=$(CLAUDE_DIR) MODE=$(MODE);)

.PHONY: list-module
list-module:
	$(call list_module,$(MODULE))

# Clean build artifacts
.PHONY: clean
clean:
	@echo "$(BLUE)Cleaning build artifacts...$(NC)"
	@find . -name "*.tmp" -type f -delete
	@find . -name ".DS_Store" -type f -delete
	@echo "$(GREEN)✓ Clean complete$(NC)"

# Update plugin.json manifests from directory contents
.PHONY: manifest
manifest:
	@echo "$(BLUE)Updating plugin manifests...$(NC)"
	@# Root plugin
	@echo "$(BLUE)→ Root plugin (.claude-plugin/plugin.json)$(NC)"
	@agents=$$(find agents -maxdepth 1 -name "*.md" 2>/dev/null | sort | sed 's/^/.\//' | jq -R . | jq -s .); \
	commands=$$(find commands -maxdepth 1 -name "*.md" 2>/dev/null | sort | sed 's/^/.\//' | jq -R . | jq -s .); \
	jq --argjson agents "$$agents" --argjson commands "$$commands" \
		'.agents = (if ($$agents | length) > 0 then $$agents else null end) | .commands = (if ($$commands | length) > 0 then $$commands else null end) | del(.agents | nulls) | del(.commands | nulls)' \
		.claude-plugin/plugin.json > .claude-plugin/plugin.json.tmp && \
	mv .claude-plugin/plugin.json.tmp .claude-plugin/plugin.json
	@echo "$(GREEN)    ✓ Updated root manifest$(NC)"
	@# Claire plugin
	@echo "$(BLUE)→ Claire plugin (claire/.claude-plugin/plugin.json)$(NC)"
	@agents=$$(find claire/agents -maxdepth 1 -name "*.md" 2>/dev/null | sort | sed 's/^claire\//.\//g' | jq -R . | jq -s .); \
	commands=$$(find claire/commands -maxdepth 1 -name "*.md" 2>/dev/null | sort | sed 's/^claire\//.\//g' | jq -R . | jq -s .); \
	jq --argjson agents "$$agents" --argjson commands "$$commands" \
		'.agents = (if ($$agents | length) > 0 then $$agents else null end) | .commands = (if ($$commands | length) > 0 then $$commands else null end) | del(.agents | nulls) | del(.commands | nulls)' \
		claire/.claude-plugin/plugin.json > claire/.claude-plugin/plugin.json.tmp && \
	mv claire/.claude-plugin/plugin.json.tmp claire/.claude-plugin/plugin.json
	@echo "$(GREEN)    ✓ Updated claire manifest$(NC)"
	@echo "$(GREEN)✓ Manifests updated$(NC)"

# Show unreleased changes for changelog
.PHONY: changelog-preview
changelog-preview:
	@echo "$(BLUE)Unreleased changes since last version:$(NC)"
	@echo ""
	@last_tag=$$(git describe --tags --abbrev=0 2>/dev/null || echo ""); \
	if [ -n "$$last_tag" ]; then \
		echo "$(YELLOW)Since $$last_tag:$(NC)"; \
		git log --oneline $$last_tag..HEAD; \
	else \
		echo "$(YELLOW)All commits (no tags found):$(NC)"; \
		git log --oneline; \
	fi

# Bump version in plugin.json files
.PHONY: version
version:
	@if [ -z "$(V)" ]; then \
		echo "$(RED)Usage: make version V=x.y.z$(NC)"; \
		exit 1; \
	fi
	@echo "$(BLUE)Bumping version to $(V)...$(NC)"
	@jq '.version = "$(V)"' .claude-plugin/plugin.json > .claude-plugin/plugin.json.tmp && \
		mv .claude-plugin/plugin.json.tmp .claude-plugin/plugin.json
	@echo "$(GREEN)    ✓ Updated root plugin$(NC)"
	@jq '.version = "$(V)"' claire/.claude-plugin/plugin.json > claire/.claude-plugin/plugin.json.tmp && \
		mv claire/.claude-plugin/plugin.json.tmp claire/.claude-plugin/plugin.json
	@echo "$(GREEN)    ✓ Updated claire plugin$(NC)"
	@echo "$(GREEN)✓ Version bumped to $(V)$(NC)"
	@echo "$(YELLOW)Don't forget to update CHANGELOG.md!$(NC)"

# Prevent module names from being interpreted as files
.PHONY: $(MODULES)
