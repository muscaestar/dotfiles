#!/usr/bin/env bash
set -euo pipefail

# dotfiles setup entrypoint
#
# 设计目标：
# - 默认安全：只做检查与提示，不直接改系统
# - 显式执行：传入 --apply 才进行实际安装动作
# - 可扩展：每个模块都预留了独立函数，后续逐步填充

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APPLY_MODE=0
RUN_APT_UPDATE=0
OPENCODE_INSTALL_CMD="${OPENCODE_INSTALL_CMD:-}"
PACKAGES=(vim tmux mosh bash fzf)
TOOLS=(vim bash tmux fzf mosh opencode)

log() {
	printf '[dotfiles/setup] %s\n' "$*"
}

warn() {
	printf '[dotfiles/setup][warn] %s\n' "$*"
}

usage() {
	cat <<'EOF'
Usage:
	bash ./setup.sh          # 仅检查与提示（默认）
	bash ./setup.sh --apply  # 执行安装步骤（当前仅基础包安装）
	bash ./setup.sh --apply --apt-update
	                        # 执行前先 apt update（默认不执行）

Optional env:
	OPENCODE_INSTALL_CMD="<your install command>"
	                        # 例如: OPENCODE_INSTALL_CMD="npm i -g @foo/opencode"
EOF
}

parse_args() {
	for arg in "$@"; do
		case "$arg" in
			--apply)
				APPLY_MODE=1
				;;
			--apt-update)
				RUN_APT_UPDATE=1
				;;
			-h|--help)
				usage
				exit 0
				;;
			*)
				warn "Unknown argument: $arg"
				usage
				exit 1
				;;
		esac
	done
}

require_command() {
	local cmd="$1"
	if ! command -v "$cmd" >/dev/null 2>&1; then
		warn "Missing required command: $cmd"
		return 1
	fi
}

check_environment() {
	log "Repository root: $REPO_ROOT"
	require_command bash
	require_command grep
}

install_base_packages() {
	local install_prefix=()

	if ! command -v apt >/dev/null 2>&1; then
		warn "apt not found. This script currently targets Ubuntu/Debian systems."
		return 0
	fi

	if [[ "$APPLY_MODE" -eq 0 ]]; then
		log "Preview mode: would install packages: ${PACKAGES[*]}"
		return 0
	fi

	if [[ "$EUID" -eq 0 ]]; then
		install_prefix=()
	elif command -v sudo >/dev/null 2>&1; then
		install_prefix=(sudo)
	else
		warn "No root permission and sudo is unavailable; skip package install."
		warn "You can install manually: apt install -y ${PACKAGES[*]}"
		return 0
	fi

	if [[ "$RUN_APT_UPDATE" -eq 1 ]]; then
		log "Running apt update..."
		"${install_prefix[@]}" apt update
	else
		log "Skip apt update (default). Use --apt-update to enable it."
	fi

	log "Installing base packages: ${PACKAGES[*]}"
	"${install_prefix[@]}" apt install -y "${PACKAGES[@]}"
}

setup_bash() {
	# 仓库中的 Bash 配置源文件，以及用户主目录目标位置
	local source_bashrc="$REPO_ROOT/bash/bashrc"
	local target_bashrc="$HOME/.bashrc"
	local setup_mark="## MARK: HAS SETUP BY MUSCA"

	# 若源文件不存在，则直接跳过，避免脚本中断
	if [[ ! -f "$source_bashrc" ]]; then
		warn "Bash source config not found: $source_bashrc"
		return 0
	fi

	# 如果没有 .bashrc，则创建一个空文件作为基础
	if [[ ! -e "$target_bashrc" ]]; then
		if [[ "$APPLY_MODE" -eq 0 ]]; then
			log "Preview: would create $target_bashrc"
		else
			touch "$target_bashrc"
			log "Created $target_bashrc"
		fi
	fi

	# 幂等：如果已有标识，说明已经注入过，直接跳过
	if [[ -f "$target_bashrc" ]] && grep -Fq "$setup_mark" "$target_bashrc"; then
		log "[ok] bash already configured (marker found), skip append"
		return 0
	fi

	# 预览模式：只显示将追加的动作
	if [[ "$APPLY_MODE" -eq 0 ]]; then
		log "Preview: would append full content of $source_bashrc into $target_bashrc"
		return 0
	fi

	# 直接复制仓库 bashrc 内容到现有 .bashrc 末尾，并写入标识保证幂等
	printf "\n# --- musca dotfiles bash config (copied) ---\n" >> "$target_bashrc"
	cat "$source_bashrc" >> "$target_bashrc"
	printf "\n%s\n" "$setup_mark" >> "$target_bashrc"

	log "[ok] bash configured by content copy: $target_bashrc"
}

setup_vim() {
	# 仓库中的 Vim 配置源文件，以及用户主目录目标位置
	local source_vimrc="$REPO_ROOT/vim/vimrc"
	local target_vimrc="$HOME/.vimrc"
	local undo_dir="$HOME/.vim/undo"
	local backup_path=""

	# 若源文件不存在，则直接跳过，避免脚本中断
	if [[ ! -f "$source_vimrc" ]]; then
		warn "Vim source config not found: $source_vimrc"
		return 0
	fi

	# 仅当目标不是当前仓库托管链接时，才准备备份
	if [[ -e "$target_vimrc" || -L "$target_vimrc" ]]; then
		if [[ "$(readlink -f "$target_vimrc" 2>/dev/null || true)" != "$source_vimrc" ]]; then
			backup_path="$target_vimrc.bak.$(date +%Y%m%d%H%M%S)"
		fi
	fi

	# 预览模式只输出将执行的动作，不改动系统
	if [[ "$APPLY_MODE" -eq 0 ]]; then
		log "Preview: would create directory $undo_dir"
		if [[ -n "$backup_path" ]]; then
			log "Preview: would backup existing $target_vimrc to $backup_path"
		fi
		log "Preview: would link $target_vimrc -> $source_vimrc"
		return 0
	fi

	# 应用模式：创建 undo 目录，并在必要时备份原有 vimrc
	mkdir -p "$undo_dir"

	if [[ -n "$backup_path" ]]; then
		mv "$target_vimrc" "$backup_path"
		log "Backed up existing vimrc to $backup_path"
	fi

	# 建立（或覆盖）软链接，统一由仓库管理 ~/.vimrc
	ln -sfn "$source_vimrc" "$target_vimrc"
	log "[ok] vim configured: $target_vimrc -> $source_vimrc"
}

setup_tmux() {
	# TODO: 后续在这里放 tmux.conf 的链接与同步逻辑
	log "[todo] setup_tmux not implemented yet"
}

setup_mosh() {
	# TODO: 后续在这里放 mosh 相关默认参数与说明
	log "[todo] setup_mosh not implemented yet"
}

setup_fzf() {
	# TODO: 后续在这里放 fzf 默认快捷键/补全初始化
	log "[todo] setup_fzf not implemented yet"
}

setup_opencode() {
	if command -v opencode >/dev/null 2>&1; then
		log "[ok] opencode already installed"
		return 0
	fi

	if [[ "$APPLY_MODE" -eq 0 ]]; then
		warn "[missing] opencode"
		log "Preview: set OPENCODE_INSTALL_CMD then rerun with --apply"
		return 0
	fi

	if [[ -z "$OPENCODE_INSTALL_CMD" ]]; then
		warn "opencode install command is not configured."
		warn "Set OPENCODE_INSTALL_CMD and rerun in apply mode."
		return 0
	fi

	log "Installing opencode with OPENCODE_INSTALL_CMD..."
	bash -lc "$OPENCODE_INSTALL_CMD"

	if command -v opencode >/dev/null 2>&1; then
		log "[ok] opencode installed"
	else
		warn "Install command finished but opencode is still not in PATH."
		warn "Check your install command and shell PATH settings."
	fi
}

report_status() {
	log "Checking tool availability..."
	for tool in "${TOOLS[@]}"; do
		if command -v "$tool" >/dev/null 2>&1; then
			log "[ok] $tool"
		else
			warn "[missing] $tool"
		fi
	done
}

main() {
	parse_args "$@"
	check_environment

	if [[ "$APPLY_MODE" -eq 0 ]]; then
		log "Running in preview mode (no system changes)."
	else
		log "Running in apply mode (system changes enabled)."
	fi

	install_base_packages
	setup_vim
	setup_bash
	setup_tmux
	setup_fzf
	setup_mosh
	setup_opencode
	report_status

	log "Done."
}

main "$@"
