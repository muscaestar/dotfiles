# Changelog

All notable changes to this repository are documented in this file.

## 2026-02-26

### Added
- Added `CHEATSHEET.md` for quick daily reference.
- Added `tmux/tmux.conf` with `C-a` prefix, mouse support, pane split bindings, and reload shortcut.

### Changed
- Updated `README.md` cheatsheet section to link to `CHEATSHEET.md`.
- Expanded Vim section in `CHEATSHEET.md` to match `vim/vimrc` behavior:
  - 4-space indentation defaults
  - line number / relative number / cursorline
  - smart search (`ignorecase` + `smartcase` + `incsearch` + `hlsearch`)
  - split direction defaults (`splitright`, `splitbelow`)
  - persistent undo and `<C-l>` nohlsearch mapping
- Implemented `setup_tmux` in `setup.sh`:
  - backup unmanaged existing `~/.tmux.conf`
  - managed symlink to repository `tmux/tmux.conf`
- Updated progress in `README.md`: marked `tmux` as done.
- Expanded `CHEATSHEET.md` with `tmux` usage and keybindings.

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

### Changed (prompt)
- Updated `bash/bashrc` prompt to show current git branch in prompt.
- Simplified prompt path display to current directory only.
- Removed host from prompt and added color distinction for user, directory, and git branch.
