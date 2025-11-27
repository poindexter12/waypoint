# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Official Claude Code plugin format with `.claude-plugin/plugin.json` manifests
- Root waypoint plugin with terraform agent and skill
- Claire as standalone sub-plugin
- `make manifest` target to auto-populate plugin.json from directory contents
- Terraform skill with Proxmox-specific references

### Changed
- Reorganized structure: technology-specific content at root level
- Claire agents optimized for component authoring

## [0.1.0] - 2025-11-23

### Added
- Initial release
- Working-tree module for git worktree management with AI context
- Claire module for Claude Code component authoring
- Makefile-based installation system (symlink/copy modes)
- Support for agents, commands, and skills
