# dotfiles

这是一个个人 dotfiles 仓库，用来管理当前正在维护的开发环境配置。

目标是：在最基础的 Ubuntu 系统上，最快速搭建一套精简但实用的命令行工作环境。

设计原则：

- 只用基础、稳定、易获取的工具
- 优先开箱即用与低维护成本
- 不使用 Neovim / Zsh 等额外复杂方案

## 模块目录

### 1) 涉及的软件

- Vim
- bash
- tmux
- fzf
- mosh
- opencode

### 1.1 配置进度（To-Do）

- [x] vim
- [x] bash
- [x] tmux
- [ ] fzf
- [ ] mosh
- [x] opencode
- [ ] opencode配置逻辑：不能覆盖已有配置


### 2) 依赖的环境变量

- `HOME`：配置文件和软链接目标的基础路径
- `SHELL`：默认 shell（本仓库目标为 bash）
- `TERM`：终端能力声明（影响 tmux/vim 显示）
- `EDITOR`：命令行默认编辑器（建议设为 `vim`）
- `OPENCODE_INSTALL_CMD`：`opencode` 的安装命令（可选，默认使用 `curl -fsSL https://opencode.ai/install | bash`）
- `BAILIAN_API_KEY`：`opencode` provider 配置中引用的 API Key 环境变量


### 3) 如何使用

1. 克隆仓库

	```bash
	git clone git@github.com:muscaestar/dotfiles.git
	cd dotfiles
	```

2. 执行一键初始化脚本

	```bash
	bash ./setup.sh
	```

	- 需要实际安装时使用：`bash ./setup.sh --apply`
	- 默认不会执行 `apt update`；如需执行可加：`--apt-update`
	- 安装 `opencode` 默认执行：
	  `curl -fsSL https://opencode.ai/install | bash`
	- 如需自定义安装命令可临时传入：
	  `OPENCODE_INSTALL_CMD="<your install command>" bash ./setup.sh --apply`

3. 当前状态（预留位）

	- `setup.sh` 已作为统一入口
	- `vim` 已实现：创建 `~/.vim/undo`，并将 `~/.vimrc` 软链接到仓库配置
	- `bash` 已实现：在已有 `~/.bashrc` 末尾复制仓库 `bashrc` 内容，并写入标识 `## MARK: HAS SETUP BY MUSCA`（幂等）
	- `tmux` 已实现：将 `~/.tmux.conf` 软链接到仓库配置，必要时自动备份原配置（幂等）
	- `opencode` 已实现：默认执行官方安装命令，支持 `OPENCODE_INSTALL_CMD` 覆写
	- `opencode` 配置已实现：将 `~/.config/opencode/opencode.json` 软链接到仓库模板，并支持通过 `BAILIAN_API_KEY` 提供 provider API Key
	- `fzf` / `mosh` 仍在待实现状态
	- 每完成一个模块，就在上面的 To-Do 中打勾

4. 后续目标

	- 目标是拉库后仅需运行一次 `setup.sh` 即可完成环境初始化

### 4) Cheatsheet

- 快速参考见：[`CHEATSHEET.md`](./CHEATSHEET.md)
- 内容覆盖：`setup.sh` 常用参数、`vim` / `bash` / `tmux` / `opencode` 常用操作
