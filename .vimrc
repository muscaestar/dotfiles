"Automatic Installation of plug.vim
if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

"vim-plug
call plug#begin('~/.vim/plugged')
Plug 'https://tpope.io/vim/surround.git'
Plug 'https://tpope.io/vim/repeat.git'
Plug 'Xuyuanp/nerdtree-git-plugin'
Plug 'junegunn/limelight.vim'
Plug 'junegunn/goyo.vim'
call plug#end()

let mapleader =" "

"tab config
set shiftwidth=4
set noexpandtab
set autoindent
set copyindent
set preserveindent
set softtabstop=0
set tabstop=4

"disable arrow keys
"no <down> <Nop>
no <left> <Nop>
no <right> <Nop>
"no <up> <Nop>
"ino <down> <Nop>
ino <left> <Nop>
ino <right> <Nop>
"ino <up> <Nop>
"vno <down> <Nop>
vno <left> <Nop>
vno <right> <Nop>
"vno <up> <Nop>

"visual setting
syntax on
set wildmenu
set ruler
set number relativenumber

"highlight search
set hlsearch
set showmatch

"idk
set autoread
set laststatus=2

"Autocompelte
set wildmode=longest:full,full

"Spell check
map <leader>o :setlocal spell! spelllang=en_us<CR>

"Splits open at below and right
set splitright splitbelow

"Shortcutting split navigation
map <leader>h <C-w>h
map <leader>j <C-w>j
map <leader>k <C-w>k
map <leader>l <C-w>l

"Make the 81th column stand out
highlight ColorColumn ctermbg=Green
call matchadd('ColorColumn', '\%81v', 100) 

"Shady Character
set listchars=tab:‣·
"set listchars+=eol:¬
set list

"Copy and Paste through system clipboard
map <C-c> :w !pbcopy<CR><CR>
map <C-p> :r !pbpaste<CR>

" Smooth Scroll
	"
	" Remamps 
	"  <C-U>
	"  <C-D>
	"  <C-F>
	"  <C-B>
	"
	" to allow smooth scrolling of the window. I find that quick changes of
	" context don't allow my eyes to follow the action properly.
	"
	" The global variable g:scroll_factor changes the scroll speed.
	"
	"
	" Written by Brad Phelan 2006
	" http://xtargets.com
	let g:scroll_factor = 3000
	function! SmoothScroll(dir, windiv, factor)
   	   let wh=winheight(0)
   	   let i=0
   	   while i < wh / a:windiv
      	  let t1=reltime()
      	  let i = i + 1
      	  if a:dir=="d"
         	 normal j
      	  else
         	 normal k
      	  end
      	  redraw
      	  while 1
         	 let t2=reltime(t1,reltime())
         	 if t2[1] > g:scroll_factor * a:factor
            	break
         	 endif
      	  endwhile
   	   endwhile
	endfunction
	map  :call SmoothScroll("d",2, 2)
	map  :call SmoothScroll("u",2, 2)
	map  :call SmoothScroll("d",1, 1)
	map  :call SmoothScroll("u",1, 1)


"highlight the current line
:hi CursorLine   cterm=NONE ctermbg=black "ctermfg=white guibg=darkred guifg=white
set cursorline! 

"use pandoc to transfer the current .md file to .pdf
map <leader>m :!pandoc -f markdown "%" --pdf-engine=xelatex -o "%".pdf<CR><CR>

"complie the java source code
map <leader>v :!clear;javac % <CR>

"run the complied binary java file
"map <leader>r :!clear;java %:r<CR>
map <leader>r :call RunJava() <CR>

function RunJava()
	:!clear;javac %
	if v:shell_error
	else
		:!java %:r
	end
endfunction
