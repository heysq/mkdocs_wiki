```vimrc
set nu

syntax enable

filetype plugin indent on

set backspace=2
set encoding=utf-8
set nocompatible

set hlsearch “ 高亮搜索
set showmatch “ 括号匹配
“ tab 缩进i
set tabstop=4 “ 设置Tab长度为4空格
set shiftwidth=4 “ 设置自动缩进长度为4空格
set autoindent “ 继承前一行的缩进方式，适用于多行注释

“ 突出显示当前行
set cursorline “突出显示当前行

call plug#begin(‘~/.vim/plugged’)
Plug ‘fatih/vim-go’
Plug ‘bling/vim-airline’
Plug ‘vim-airline/vim-airline-themes’

“ 配色方案
“ colorscheme neodark
Plug ‘KeitaNakamura/neodark.vim’

“ 文件目录树结构
Plug ‘scrooloose/nerdtree’

“ 窗口大小调节
Plug ‘simeji/winresizer’

“ 文件搜索
Plug ‘ctrlpvim/ctrlp.vim’

“ 补全插件
Plug ‘valloric/youcompleteme’

“ 代码结构提取
Plug ‘majutsushi/tagbar’

“ 可以在导航目录中看到 git 版本信息
Plug ‘Xuyuanp/nerdtree-git-plugin’

“ git 插件
Plug ‘tpope/vim-fugitive’

“ 全局搜索插件
Plug ‘dyng/ctrlsf.vim’
call plug#end()

set title
set termguicolors
colorscheme neodark
“let g:airline_theme=’onehalfdark’
set background=dark

let g:airline_powerline_fonts = 1
let g:airline#extensions#tabline#fnamemod = ‘:p:.’

let mapleader = “m”

“mw退出并保存
inoremap w :w

“jj插入模式下jj退出插入模式
inoremap jj <ESC>

“ 分号替换冒号，省的按shift
nnoremap ; :

“窗口切换
noremap h
noremap j
noremap k
noremap l

“ tab切换
set showtabline=2
noremap q :tabNext
noremap t :tabnew
noremap :tabclose

“ nerdtree
nnoremap ff :NERDTreeToggle
let g:NERDTreeWinPos = “left”
“ 显示行号
let NERDTreeShowLineNumbers=1
“ 打开文件时是否显示目录
let NERDTreeAutoCenter=1
let NERDTreeShowBookmarks=2

au FileType go nmap gv (go-def-vertical)
au FileType go nmap gt (go-def-tab)
au FileType go nmap gb (go-build)
let g:go_fmt_command = “goimports” “ 格式化将默认的 gofmt 替换
let g:go_autodetect_gopath = 1
let g:go_list_type = “quickfix”
let g:go_version_warning = 1
let g:go_highlight_types = 1
let g:go_highlight_fields = 1
let g:go_highlight_functions = 1
let g:go_highlight_function_calls = 1
let g:go_highlight_operators = 1
let g:go_highlight_extra_types = 1
let g:go_highlight_methods = 1
let g:go_highlight_generate_tags = 1

“ iterm 光标插入模式竖线，普通模式方块
if $TERM_PROGRAM =~ “iTerm”
let &t_SI = “<Esc>]50;CursorShape=1\x7” “ Vertical bar in insert mode
let &t_EI = “<Esc>]50;CursorShape=0\x7” “ Block in normal mode
endif

“ v 模式下复制内容到系统剪切板
vmap c “+yy
“ n 模式下复制一行到系统剪切板
nmap c “+yy
“ n 模式下粘贴系统剪切板的内容
nmap v “+p

“ majutsushi/tagbar 插件打开关闭快捷键
nmap :TagbarToggle

let g:tagbar_type_go = {
\ ‘ctagstype’ : ‘go’,
\ ‘kinds’ : [
\ ‘p:package’,
\ ‘i:imports:1’,
\ ‘c:constants’,
\ ‘v:variables’,
\ ‘t:types’,
\ ‘n:interfaces’,
\ ‘w:fields’,
\ ‘e:embedded’,
\ ‘m:methods’,
\ ‘r:constructor’,
\ ‘f:functions’
\ ],
\ ‘sro’ : ‘.’,
\ ‘kind2scope’ : {
\ ‘t’ : ‘ctype’,
\ ‘n’ : ‘ntype’
\ },
\ ‘scope2kind’ : {
\ ‘ctype’ : ‘t’,
\ ‘ntype’ : ‘n’
\ },
\ ‘ctagsbin’ : ‘/Users/sunqi/go/bin/gotags’,
\ ‘ctagsargs’ : ‘-sort -silent’
\ }

“ nerdtree git
let g:NERDTreeGitStatusIndicatorMapCustom = {
\ “Modified” : “✹”,
\ “Staged” : “✚”,
\ “Untracked” : “✭”,
\ “Renamed” : “➜”,
\ “Unmerged” : “═”,
\ “Deleted” : “✖”,
\ “Dirty” : “✗”,
\ “Clean” : “✔︎”,
\ ‘Ignored’ : ‘☒’,
\ “Unknown” : “?”
\ }

let g:NERDTreeGitStatusShowIgnored = 1
```