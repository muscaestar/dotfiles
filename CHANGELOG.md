# Changelog

All notable changes to this repository are documented in this file.

## 2026-02-25

### Changed
- Refactored repository layout: moved legacy root-level dotfiles/assets into `archive/`.
- Rewrote `README.md` to focus on the new Ubuntu-first minimal workflow.
- Standardized setup order: vim -> bash -> tmux -> fzf -> mosh -> opencode.

### Added
- Added `setup.sh` as the single entrypoint for bootstrap.
- Added `vim/vimrc` minimal baseline configuration (4-space indent, practical defaults).
- Added `bash/bashrc` minimal baseline configuration (interactive-only, vi mode, history/path/aliases).

### setup.sh behavior
- Added preview/apply modes (`default` vs `--apply`).
- Added optional `--apt-update` flag (disabled by default).
- Added optional `OPENCODE_INSTALL_CMD` support for opencode installation.
- Implemented `setup_vim` with:
  - undo directory creation
  - backup of unmanaged existing `~/.vimrc`
  - managed symlink to repository config
- Implemented `setup_bash` with marker-based idempotency:
  - checks `## MARK: HAS SETUP BY MUSCA`
  - if marker missing, appends full copied content of repository bashrc into existing `~/.bashrc`
  - writes marker to prevent duplicate append

### Notes
- `tmux`, `fzf`, `mosh`, and full `opencode` setup remain TODO in `setup.sh`.
