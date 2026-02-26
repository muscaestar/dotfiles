# Changelog

All notable changes to this repository are documented in this file.

## 2026-02-26

### Added
- Added `CHEATSHEET.md` for quick daily reference.
- Added `tmux/tmux.conf` with `C-a` prefix, mouse support, pane split bindings, and reload shortcut.
- Added `opencode` section in `CHEATSHEET.md` (install/check/version quick commands).
- Added `opencode/opencode.json` provider template with `bailian-coding-plan-test` models.

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
- Added `tmux` troubleshooting notes in `CHEATSHEET.md`:
  - `tmux attach` does not auto-reload updated `~/.tmux.conf`
  - use `tmux source-file ~/.tmux.conf` or restart server with `tmux kill-server`
- Updated `tmux/tmux.conf` to use explicit window option scope for current window style:
  - `set -w -g window-status-current-style fg=white,bold,bg=red`
- Implemented default `opencode` install command in `setup.sh`:
  - `curl -fsSL https://opencode.ai/install | bash`
  - still supports `OPENCODE_INSTALL_CMD` override
- Updated `README.md` progress: marked `opencode` as done.
- Implemented `setup_opencode` config management:
  - creates `~/.config/opencode` when needed
  - backups unmanaged existing `~/.config/opencode/opencode.json`
  - managed symlink to repository `opencode/opencode.json`
- Updated docs for provider API key env var: `BAILIAN_API_KEY`.

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
