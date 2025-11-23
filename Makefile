# Waypoint - Modular Claude Configuration Manager
# Root Makefile - Delegates to module-specific Makefiles

# Configuration
CLAUDE_DIR ?= $(HOME)/.claude
MODE ?= symlink
MODULES := working-tree

# Colors for output
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[0;33m
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
	@echo "  clean             Remove local build artifacts"
	@echo ""
	@echo "$(GREEN)Available Modules:$(NC)"
	@echo "  working-tree      Git worktree management with AI context"
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

# Install all or specific module(s)
.PHONY: install $(MODULES)
install: $(SELECTED_MODULES)
ifeq ($(SELECTED_MODULES),$(MODULES))
	@echo "$(GREEN)✓ All modules installed successfully$(NC)"
endif

$(MODULES):
	@echo "$(BLUE)→ Installing module: $@$(NC)"
	@$(MAKE) -C $@ install CLAUDE_DIR=$(CLAUDE_DIR) MODE=$(MODE)

# Uninstall all or specific module(s)
.PHONY: uninstall
uninstall:
	@$(foreach mod,$(SELECTED_MODULES),\
		echo "$(BLUE)→ Uninstalling module: $(mod)$(NC)"; \
		$(MAKE) -C $(mod) uninstall CLAUDE_DIR=$(CLAUDE_DIR) MODE=$(MODE); \
	)
	@echo "$(GREEN)✓ Modules uninstalled successfully$(NC)"

# Check installation status
.PHONY: check
check:
	@echo "$(BLUE)Checking installation status...$(NC)"
	@$(foreach mod,$(SELECTED_MODULES),\
		echo "$(BLUE)→ Checking module: $(mod)$(NC)"; \
		$(MAKE) -C $(mod) check CLAUDE_DIR=$(CLAUDE_DIR) MODE=$(MODE) || true; \
	)

# Fix broken symlinks
.PHONY: fix
fix:
	@echo "$(BLUE)Repairing installations...$(NC)"
	@$(foreach mod,$(SELECTED_MODULES),\
		echo "$(BLUE)→ Fixing module: $(mod)$(NC)"; \
		$(MAKE) -C $(mod) fix CLAUDE_DIR=$(CLAUDE_DIR) MODE=$(MODE); \
	)
	@echo "$(GREEN)✓ Repairs complete$(NC)"

# List what would be installed (dry-run)
.PHONY: list
list:
	@echo "$(BLUE)Installation preview for: $(CLAUDE_DIR)$(NC)"
	@$(foreach mod,$(SELECTED_MODULES),\
		echo "$(BLUE)→ Module: $(mod)$(NC)"; \
		$(MAKE) -C $(mod) list CLAUDE_DIR=$(CLAUDE_DIR) MODE=$(MODE); \
	)

# Clean build artifacts
.PHONY: clean
clean:
	@echo "$(BLUE)Cleaning build artifacts...$(NC)"
	@find . -name "*.tmp" -type f -delete
	@find . -name ".DS_Store" -type f -delete
	@echo "$(GREEN)✓ Clean complete$(NC)"

# Prevent module names from being interpreted as files
.PHONY: $(MODULES)
