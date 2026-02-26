# Dotfiles Cheatsheet

## setup.sh

```bash
# 预览模式（默认，不改系统）
bash ./setup.sh

# 应用模式（执行安装/配置）
bash ./setup.sh --apply

# 应用模式 + apt update
bash ./setup.sh --apply --apt-update

# 安装 opencode（示例）
OPENCODE_INSTALL_CMD="<your install command>" bash ./setup.sh --apply

# 默认 opencode 安装命令（apply 模式会执行）
curl -fsSL https://opencode.ai/install | bash
```

## Bash

```bash
# 重新加载当前 shell 配置
source ~/.bashrc

# 查看最近命令历史
history | tail -n 50

# 常用目录跳转
cd ~
cd -
```

## Vim

```vim
" 当前配置要点（来自 vim/vimrc）
" 4 空格缩进
:set expandtab tabstop=4 softtabstop=4 shiftwidth=4

" 行号 + 相对行号 + 当前行高亮
:set number relativenumber cursorline

" 搜索：忽略大小写 + 智能大小写 + 增量搜索 + 高亮
:set ignorecase smartcase incsearch hlsearch

" 分屏新窗口默认方向
:set splitright splitbelow

" 持久 undo（依赖 ~/.vim/undo）
:set undofile
:set undodir?

" 清除搜索高亮（自定义映射）
<C-l>

" 常用保存/退出
:w
:q
:wq
:q!
```

```vim
" 搜索示例（smartcase 生效）
/foo        " 匹配 foo/Foo/FOO
/Foo        " 只匹配 Foo（区分大小写）
```

```vim
" 分屏常用
:vsplit     " 垂直分屏（新窗口在右）
:split      " 水平分屏（新窗口在下）
<C-w>h/j/k/l
```

## tmux

```tmux
# 当前配置要点（来自 tmux/tmux.conf）
prefix: C-a
reload: prefix + r
horizontal split: prefix + |
vertical split: prefix + _
```

```bash
# 启动 / 连接
tmux
tmux new -s work
tmux attach -t work

# 会话管理
tmux ls
tmux kill-session -t work
```

```tmux
# 窗口与面板
prefix + c        # 新建窗口
prefix + n / p    # 下一个 / 上一个窗口
prefix + 1..9     # 跳转窗口
prefix + |        # 左右分屏
prefix + _        # 上下分屏
prefix + x        # 关闭当前面板
prefix + z        # 当前面板最大化/还原
```

```bash
# 排查：为什么配置没生效
# 1) 检查 ~/.tmux.conf 是否已链接到仓库配置
ls -la ~/.tmux.conf
readlink -f ~/.tmux.conf

# 2) 检查当前 tmux server 实际前缀
tmux show -g prefix

# 3) attach 旧 server 不会自动重读配置，手动重载
tmux source-file ~/.tmux.conf
tmux show -g prefix

# 4) 仍异常时重启 server
tmux kill-server
tmux
```

- 结论：`tmux attach` 连接的是已运行的 server，默认不会自动加载新的 `~/.tmux.conf`。
- 日常建议：改完配置后用 `prefix + r`（即 `C-a` 然后 `r`）立即重载。

## opencode

```bash
# 配置文件路径（由 setup.sh 维护链接）
~/.config/opencode/opencode.json

# 设置 provider API Key（bash）
export BAILIAN_API_KEY="<your_api_key>"

# 检查是否已安装
command -v opencode

# 查看版本（若支持）
opencode --version

# 使用 setup.sh 安装（默认官方安装命令）
bash ./setup.sh --apply

# 自定义安装命令
OPENCODE_INSTALL_CMD="<your install command>" bash ./setup.sh --apply

# 检查配置链接是否正确
ls -la ~/.config/opencode/opencode.json
readlink -f ~/.config/opencode/opencode.json
```

## Git（在本仓库中）

```bash
# 查看改动
git status

# 查看差异
git diff

# 查看提交历史（简版）
git log --oneline --graph --decorate -n 20
```
