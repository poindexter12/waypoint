# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.1.0] - 2026-01-09

### Added

- **Claude Code 2.1.x Features**
  - PreToolUse/PostToolUse/Stop hooks on agents and commands
  - Wildcard patterns (`{a,b,c}`, `**`) in tool permission matrices
  - `agent` field in skills for explicit agent delegation

- **New Technology Agents**
  - `tofu-expert` - OpenTofu infrastructure-as-code (Terraform fork)
  - `packer-expert` - HashiCorp Packer machine image building

- **New Technology Skills**
  - `tofu` - OpenTofu reference with Terraform migration guide
  - `packer` - Packer reference with Proxmox builder, cloud-init, provisioners

- **CLI Tool Validation Hooks**
  - All technology agents validate their CLI tool is installed before use
  - Hooks use `once: true` for minimal overhead (check once per session)
  - Provides clear error messages with install URLs when tools missing

- **Working-tree Command Hooks**
  - Git repository validation on all commands
  - JSON validation on metadata creation
  - Uncommitted changes warning on destroy

### Changed

- All technology skills now include `agent` field for delegation
- Tool permission matrices updated with 2.1.x wildcard syntax
- Technologies plugin version bumped to 1.1.0

## [1.0.0] - 2025-11-27

### Added

- Official Claude Code plugin format with `.claude-plugin/plugin.json` manifests
- `workflows/` directory for operational tooling (working-tree)
- `technologies/` directory for domain knowledge (terraform, ansible, docker, proxmox)
- Each plugin now self-contained with its own `.claude-plugin/plugin.json`
- `make manifest` target to auto-populate plugin.json from directory contents
- Terraform skill with Proxmox-specific references

### Changed

- **BREAKING**: Reorganized repository structure into workflows vs technologies
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
