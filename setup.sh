#!/usr/bin/env bash
set -euo pipefail

# dotfiles setup entrypoint
#
# 设计目标：
# - 默认安全：只做检查与提示，不直接改系统
# - 显式执行：传入 --apply 才进行实际安装动作
# - 可扩展：每个模块都预留了独立函数，后续逐步填充

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 运行模式与可选参数
APPLY_MODE=0
RUN_APT_UPDATE=0

# opencode 安装命令：支持环境变量覆盖 + 默认官方安装命令
OPENCODE_INSTALL_CMD="${OPENCODE_INSTALL_CMD:-}"
OPENCODE_DEFAULT_INSTALL_CMD='curl -fsSL https://opencode.ai/install | bash'

# 基础包与最终检查工具列表
PACKAGES=(vim tmux mosh bash fzf)
TOOLS=(vim bash tmux fzf mosh opencode)

# 日志输出函数
log() {
	printf '[dotfiles/setup] %s\n' "$*"
}

# 警告输出函数
warn() {
	printf '[dotfiles/setup][warn] %s\n' "$*"
}

# 帮助信息
usage() {
	cat <<'EOF'
Usage:
	bash ./setup.sh          # 仅检查与提示（默认）
	bash ./setup.sh --apply  # 执行安装步骤（当前仅基础包安装）
	bash ./setup.sh --apply --apt-update
	                        # 执行前先 apt update（默认不执行）

Optional env:
	OPENCODE_INSTALL_CMD="<your install command>"
	                        # 默认: curl -fsSL https://opencode.ai/install | bash
	BAILIAN_API_KEY="<your api key>"
	                        # opencode provider 配置中使用的 API Key 环境变量
EOF
}

parse_args() {
	# 解析命令行参数
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
	# 校验依赖命令是否存在
	local cmd="$1"
	if ! command -v "$cmd" >/dev/null 2>&1; then
		warn "Missing required command: $cmd"
		return 1
	fi
}

check_environment() {
	# 启动前环境检查
	log "Repository root: $REPO_ROOT"
	require_command bash
	require_command grep
}

install_base_packages() {
	# 基础包安装阶段（仅 apply 模式执行）
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
	# bash 模块：复制仓库 bashrc 内容到 ~/.bashrc（带幂等标记）
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
	# vim 模块：管理 ~/.vimrc 软链接并准备 undo 目录
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
	# tmux 模块：管理 ~/.tmux.conf 软链接
	# 仓库中的 tmux 配置源文件，以及用户主目录目标位置
	local source_tmux_conf="$REPO_ROOT/tmux/tmux.conf"
	local target_tmux_conf="$HOME/.tmux.conf"
	local backup_path=""

	# 若源文件不存在，则直接跳过，避免脚本中断
	if [[ ! -f "$source_tmux_conf" ]]; then
		warn "tmux source config not found: $source_tmux_conf"
		return 0
	fi

	# 仅当目标不是当前仓库托管链接时，才准备备份
	if [[ -e "$target_tmux_conf" || -L "$target_tmux_conf" ]]; then
		if [[ "$(readlink -f "$target_tmux_conf" 2>/dev/null || true)" != "$source_tmux_conf" ]]; then
			backup_path="$target_tmux_conf.bak.$(date +%Y%m%d%H%M%S)"
		fi
	fi

	# 预览模式只输出将执行的动作，不改动系统
	if [[ "$APPLY_MODE" -eq 0 ]]; then
		if [[ -n "$backup_path" ]]; then
			log "Preview: would backup existing $target_tmux_conf to $backup_path"
		fi
		log "Preview: would link $target_tmux_conf -> $source_tmux_conf"
		return 0
	fi

	# 应用模式：在必要时备份原有 tmux.conf
	if [[ -n "$backup_path" ]]; then
		mv "$target_tmux_conf" "$backup_path"
		log "Backed up existing tmux config to $backup_path"
	fi

	# 建立（或覆盖）软链接，统一由仓库管理 ~/.tmux.conf
	ln -sfn "$source_tmux_conf" "$target_tmux_conf"
	log "[ok] tmux configured: $target_tmux_conf -> $source_tmux_conf"
}

setup_mosh() {
	# mosh 模块（预留）
	# TODO: 后续在这里放 mosh 相关默认参数与说明
	log "[todo] setup_mosh not implemented yet"
}

setup_fzf() {
	# fzf 模块（预留）
	# TODO: 后续在这里放 fzf 默认快捷键/补全初始化
	log "[todo] setup_fzf not implemented yet"
}

setup_opencode() {
	# opencode 安装与配置入口
	#
	# 行为概述：
	# 1) 安装 opencode（若系统中尚未存在）
	#    - 默认执行 OPENCODE_DEFAULT_INSTALL_CMD
	#    - 若设置 OPENCODE_INSTALL_CMD，则优先使用用户自定义命令
	# 2) 初始化 opencode 配置文件（仅首次）
	#    - 仓库模板：$REPO_ROOT/opencode/opencode.json
	#    - 目标路径：~/.config/opencode/opencode.json
	#    - 若目标文件已存在，则跳过（不覆盖用户已有配置）
	# 3) 预览模式（默认）仅输出将执行动作，不改动系统
	#
	# 相关环境变量：
	# - OPENCODE_INSTALL_CMD：可选，自定义安装命令
	# - BAILIAN_API_KEY：provider 配置中引用的 API Key（在 opencode.json 中使用）

	# 解析安装命令：优先用户传入，回退到默认命令
	local install_cmd="${OPENCODE_INSTALL_CMD:-$OPENCODE_DEFAULT_INSTALL_CMD}"

	# 定义 opencode 配置模板源路径与用户侧目标路径
	local source_config="$REPO_ROOT/opencode/opencode.json"
	local target_config="$HOME/.config/opencode/opencode.json"

	# 预先声明目录变量
	local target_config_dir

	# 计算目标配置目录（通常为 ~/.config/opencode）
	target_config_dir="$(dirname "$target_config")"

	# 阶段 1：安装 opencode（二进制不存在时才尝试安装）
	if command -v opencode >/dev/null 2>&1; then
		log "[ok] opencode already installed"
	else
		# 预览模式：仅展示将执行的安装命令
		if [[ "$APPLY_MODE" -eq 0 ]]; then
			warn "[missing] opencode"
			log "Preview: would run opencode install command: $install_cmd"
		else
			# 应用模式：执行安装命令
			log "Installing opencode..."
			bash -lc "$install_cmd"
		fi
	fi

	# 阶段 2：检查仓库中的 provider 配置模板是否存在
	if [[ ! -f "$source_config" ]]; then
		warn "opencode provider config template not found: $source_config"
		return 0
	fi

	# 阶段 3：若用户已有配置，则严格跳过，不做覆盖
	if [[ -e "$target_config" || -L "$target_config" ]]; then
		log "[ok] opencode config already exists, keep as-is: $target_config"
		return 0
	fi

	# 阶段 4：预览模式下输出首次初始化动作，不做实际修改
	if [[ "$APPLY_MODE" -eq 0 ]]; then
		log "Preview: would create directory $target_config_dir"
		log "Preview: would create initial opencode config from template: $source_config -> $target_config"
		return 0
	fi

	# 阶段 5：应用模式下创建目标目录
	mkdir -p "$target_config_dir"

	# 阶段 6：首次初始化时复制模板文件到用户配置路径
	cp "$source_config" "$target_config"
	log "[ok] opencode config initialized: $target_config"

	# 阶段 7：安装结果复检（PATH 生效可能受当前 shell 会话影响）
	if command -v opencode >/dev/null 2>&1; then
		log "[ok] opencode installed"
	else
		warn "Install command finished but opencode is still not in PATH."
		warn "Check your install command and shell PATH settings."
	fi
}

report_status() {
	# 汇总检查所有工具可用性
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
	# 主流程：参数解析 -> 环境检查 -> 安装基础包 -> 配置各模块 -> 最终状态汇总
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
