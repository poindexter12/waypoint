# Waypoint - Plugin Management Tools
# Manages plugin.json manifests, versions, and changelog

# Colors for output
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
NC := \033[0m

# Default target
.PHONY: help
help:
	@echo "$(BLUE)Waypoint - Plugin Management Tools$(NC)"
	@echo ""
	@echo "$(GREEN)Targets:$(NC)"
	@echo "  help              Show this help message (default)"
	@echo "  manifest          Update plugin.json files from directory contents"
	@echo "  version V=x.y.z   Bump version in all plugin.json files"
	@echo "  changelog-preview Show commits since last version tag"
	@echo "  clean             Remove build artifacts"
	@echo ""
	@echo "$(GREEN)Examples:$(NC)"
	@echo "  make manifest                  Update all plugin.json files"
	@echo "  make version V=1.2.0           Bump all versions to 1.2.0"
	@echo "  make changelog-preview         Show unreleased commits"

# Update plugin.json manifests from directory contents
.PHONY: manifest
manifest:
	@echo "$(BLUE)Updating plugin manifests...$(NC)"
	@# Claire plugin
	@echo "$(BLUE)→ Claire plugin$(NC)"
	@agents=$$(find claire/agents -maxdepth 1 -name "*.md" 2>/dev/null | sort | sed 's/^claire\//.\//g' | jq -R . | jq -s .); \
	commands=$$(find claire/commands -maxdepth 1 -name "*.md" 2>/dev/null | sort | sed 's/^claire\//.\//g' | jq -R . | jq -s .); \
	jq --argjson agents "$$agents" --argjson commands "$$commands" \
		'.agents = (if ($$agents | length) > 0 then $$agents else null end) | .commands = (if ($$commands | length) > 0 then $$commands else null end) | del(.agents | nulls) | del(.commands | nulls)' \
		claire/.claude-plugin/plugin.json > claire/.claude-plugin/plugin.json.tmp && \
	mv claire/.claude-plugin/plugin.json.tmp claire/.claude-plugin/plugin.json
	@echo "$(GREEN)    ✓ Updated claire$(NC)"
	@# Workflows plugin
	@echo "$(BLUE)→ Workflows plugin$(NC)"
	@agents=$$(find workflows/agents -maxdepth 1 -name "*.md" 2>/dev/null | sort | sed 's/^workflows\//.\//g' | jq -R . | jq -s .); \
	commands=$$(find workflows/commands -maxdepth 1 -name "*.md" 2>/dev/null | sort | sed 's/^workflows\//.\//g' | jq -R . | jq -s .); \
	jq --argjson agents "$$agents" --argjson commands "$$commands" \
		'.agents = (if ($$agents | length) > 0 then $$agents else null end) | .commands = (if ($$commands | length) > 0 then $$commands else null end) | del(.agents | nulls) | del(.commands | nulls)' \
		workflows/.claude-plugin/plugin.json > workflows/.claude-plugin/plugin.json.tmp && \
	mv workflows/.claude-plugin/plugin.json.tmp workflows/.claude-plugin/plugin.json
	@echo "$(GREEN)    ✓ Updated workflows$(NC)"
	@# Technologies plugin
	@echo "$(BLUE)→ Technologies plugin$(NC)"
	@agents=$$(find technologies/agents -maxdepth 1 -name "*.md" 2>/dev/null | sort | sed 's/^technologies\//.\//g' | jq -R . | jq -s .); \
	jq --argjson agents "$$agents" \
		'.agents = (if ($$agents | length) > 0 then $$agents else null end) | del(.agents | nulls)' \
		technologies/.claude-plugin/plugin.json > technologies/.claude-plugin/plugin.json.tmp && \
	mv technologies/.claude-plugin/plugin.json.tmp technologies/.claude-plugin/plugin.json
	@echo "$(GREEN)    ✓ Updated technologies$(NC)"
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
	@echo "$(GREEN)    ✓ Root plugin$(NC)"
	@jq '.version = "$(V)"' claire/.claude-plugin/plugin.json > claire/.claude-plugin/plugin.json.tmp && \
		mv claire/.claude-plugin/plugin.json.tmp claire/.claude-plugin/plugin.json
	@echo "$(GREEN)    ✓ Claire$(NC)"
	@jq '.version = "$(V)"' workflows/.claude-plugin/plugin.json > workflows/.claude-plugin/plugin.json.tmp && \
		mv workflows/.claude-plugin/plugin.json.tmp workflows/.claude-plugin/plugin.json
	@echo "$(GREEN)    ✓ Workflows$(NC)"
	@jq '.version = "$(V)"' technologies/.claude-plugin/plugin.json > technologies/.claude-plugin/plugin.json.tmp && \
		mv technologies/.claude-plugin/plugin.json.tmp technologies/.claude-plugin/plugin.json
	@echo "$(GREEN)    ✓ Technologies$(NC)"
	@echo "$(GREEN)✓ Version bumped to $(V)$(NC)"
	@echo "$(YELLOW)Don't forget to update CHANGELOG.md!$(NC)"

# Clean build artifacts
.PHONY: clean
clean:
	@echo "$(BLUE)Cleaning build artifacts...$(NC)"
	@find . -name "*.tmp" -type f -delete
	@find . -name ".DS_Store" -type f -delete
	@echo "$(GREEN)✓ Clean complete$(NC)"
