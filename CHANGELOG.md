# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Official Claude Code plugin format with `.claude-plugin/plugin.json` manifests
- `workflows/` directory for operational tooling (working-tree)
- `skills/` directory for domain knowledge (terraform)
- Each plugin now self-contained with its own `.claude-plugin/plugin.json`
- `make manifest` target to auto-populate plugin.json from directory contents
- Terraform skill with Proxmox-specific references

### Changed

- **BREAKING**: Reorganized repository structure into workflows vs skills
  - `working-tree/` → `workflows/working-tree/`
  - `terraform/` (agent + skill) → `skills/terraform/`
- Root plugin now serves as index pointing to sub-plugins
- Makefile updated with module path mappings for new structure
- Claire remains at root level as meta-tooling

### Migration

If you have existing symlinks, run `make fix` to update them to the new paths.

## [0.1.0] - 2025-11-23

### Added

- Initial release
- Working-tree module for git worktree management with AI context
- Claire module for Claude Code component authoring
- Makefile-based installation system (symlink/copy modes)
- Support for agents, commands, and skills
