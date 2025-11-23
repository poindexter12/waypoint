# Working-Tree Module Makefile
# Installs git worktree management agents and commands

MODULE_NAME := working-tree
MODULE_DIR := $(shell pwd)
CLAUDE_DIR ?= $(HOME)/.claude
MODE ?= symlink

# Directories
AGENTS_SRC := $(MODULE_DIR)/agents
COMMANDS_SRC := $(MODULE_DIR)/commands
AGENTS_DEST := $(CLAUDE_DIR)/agents/$(MODULE_NAME)
COMMANDS_DEST := $(CLAUDE_DIR)/commands/$(MODULE_NAME)

# Files to install
AGENT_FILES := $(wildcard $(AGENTS_SRC)/*.md)
COMMAND_FILES := $(wildcard $(COMMANDS_SRC)/*.md)

# Colors
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
NC := \033[0m

.PHONY: install uninstall check fix list

# Install agents and commands
install:
	@echo "$(BLUE)  Installing $(MODULE_NAME) to $(CLAUDE_DIR)$(NC)"
	@mkdir -p $(AGENTS_DEST)
	@mkdir -p $(COMMANDS_DEST)
	@for file in $(AGENT_FILES); do \
		dest=$(AGENTS_DEST)/$$(basename $$file); \
		if [ "$(MODE)" = "copy" ]; then \
			cp -f $$file $$dest; \
			echo "$(GREEN)    ✓ Copied agent: $$(basename $$file)$(NC)"; \
		else \
			ln -sf $$file $$dest; \
			echo "$(GREEN)    ✓ Linked agent: $$(basename $$file)$(NC)"; \
		fi; \
	done
	@for file in $(COMMAND_FILES); do \
		dest=$(COMMANDS_DEST)/$$(basename $$file); \
		if [ "$(MODE)" = "copy" ]; then \
			cp -f $$file $$dest; \
			echo "$(GREEN)    ✓ Copied command: $$(basename $$file)$(NC)"; \
		else \
			ln -sf $$file $$dest; \
			echo "$(GREEN)    ✓ Linked command: $$(basename $$file)$(NC)"; \
		fi; \
	done
	@echo "$(GREEN)  ✓ $(MODULE_NAME) installed$(NC)"

# Uninstall agents and commands
uninstall:
	@echo "$(BLUE)  Uninstalling $(MODULE_NAME) from $(CLAUDE_DIR)$(NC)"
	@if [ -d "$(AGENTS_DEST)" ]; then \
		rm -rf $(AGENTS_DEST); \
		echo "$(GREEN)    ✓ Removed $(AGENTS_DEST)$(NC)"; \
	else \
		echo "$(YELLOW)    - $(AGENTS_DEST) not found$(NC)"; \
	fi
	@if [ -d "$(COMMANDS_DEST)" ]; then \
		rm -rf $(COMMANDS_DEST); \
		echo "$(GREEN)    ✓ Removed $(COMMANDS_DEST)$(NC)"; \
	else \
		echo "$(YELLOW)    - $(COMMANDS_DEST) not found$(NC)"; \
	fi
	@echo "$(GREEN)  ✓ $(MODULE_NAME) uninstalled$(NC)"

# Check installation status
check:
	@echo "$(BLUE)  Checking $(MODULE_NAME)...$(NC)"
	@if [ -d "$(AGENTS_DEST)" ]; then \
		echo "$(GREEN)    ✓ Directory exists: agents$(NC)"; \
	else \
		echo "$(RED)    ✗ Directory missing: agents$(NC)"; \
	fi
	@if [ -d "$(COMMANDS_DEST)" ]; then \
		echo "$(GREEN)    ✓ Directory exists: commands$(NC)"; \
	else \
		echo "$(RED)    ✗ Directory missing: commands$(NC)"; \
	fi
	@for file in $(AGENT_FILES); do \
		dest=$(AGENTS_DEST)/$$(basename $$file); \
		if [ ! -e "$$dest" ]; then \
			echo "$(RED)    ✗ Missing agent: $$(basename $$file)$(NC)"; \
		elif [ "$(MODE)" = "symlink" ] && [ -L "$$dest" ]; then \
			target=$$(readlink "$$dest"); \
			if [ "$$target" = "$$file" ]; then \
				echo "$(GREEN)    ✓ Valid agent: $$(basename $$file)$(NC)"; \
			else \
				echo "$(YELLOW)    ⚠ Wrong target agent: $$(basename $$file) → $$target$(NC)"; \
			fi; \
		elif [ "$(MODE)" = "symlink" ] && [ ! -L "$$dest" ]; then \
			echo "$(YELLOW)    ⚠ Not a symlink agent: $$(basename $$file)$(NC)"; \
		else \
			echo "$(GREEN)    ✓ Exists agent: $$(basename $$file)$(NC)"; \
		fi; \
	done
	@for file in $(COMMAND_FILES); do \
		dest=$(COMMANDS_DEST)/$$(basename $$file); \
		if [ ! -e "$$dest" ]; then \
			echo "$(RED)    ✗ Missing command: $$(basename $$file)$(NC)"; \
		elif [ "$(MODE)" = "symlink" ] && [ -L "$$dest" ]; then \
			target=$$(readlink "$$dest"); \
			if [ "$$target" = "$$file" ]; then \
				echo "$(GREEN)    ✓ Valid command: $$(basename $$file)$(NC)"; \
			else \
				echo "$(YELLOW)    ⚠ Wrong target command: $$(basename $$file) → $$target$(NC)"; \
			fi; \
		elif [ "$(MODE)" = "symlink" ] && [ ! -L "$$dest" ]; then \
			echo "$(YELLOW)    ⚠ Not a symlink command: $$(basename $$file)$(NC)"; \
		else \
			echo "$(GREEN)    ✓ Exists command: $$(basename $$file)$(NC)"; \
		fi; \
	done

# Fix broken or missing installations
fix:
	@echo "$(BLUE)  Fixing $(MODULE_NAME)...$(NC)"
	@$(MAKE) install CLAUDE_DIR=$(CLAUDE_DIR) MODE=$(MODE)

# List what would be installed
list:
	@echo "$(BLUE)  Agents → $(AGENTS_DEST)/$(NC)"
	@for file in $(AGENT_FILES); do \
		echo "    $(MODE): $$(basename $$file)"; \
	done
	@echo "$(BLUE)  Commands → $(COMMANDS_DEST)/$(NC)"
	@for file in $(COMMAND_FILES); do \
		echo "    $(MODE): $$(basename $$file)"; \
	done
