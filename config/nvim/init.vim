" =============================================================================
" Plugins
" =============================================================================
" Note: Skip initialization for vim-tiny or vim-small.
if 0 | endif
if &compatible
    set nocompatible                            " Be iMproved
endif

" Required:
set runtimepath^=~/Dotfiles/config/nvim/bundle/neobundle.vim/
" Required:
call neobundle#begin(expand('~/Dotfiles/config/nvim/bundle/'))

NeoBundle 'Shougo/vimproc.vim', {
\ 'build' : {
\     'windows' : 'tools\\update-dll-mingw',
\     'cygwin' : 'make -f make_cygwin.mak',
\     'mac' : 'make -f make_mac.mak',
\     'linux' : 'make',
\     'unix' : 'gmake',
\    },
\ }

" Required:
 NeoBundleFetch 'Shougo/neobundle.vim'

" My Bundles:
 NeoBundle 'https://github.com/scrooloose/nerdtree.git'
 NeoBundle 'https://github.com/vim-airline/vim-airline.git'
 NeoBundle 'https://github.com/vim-airline/vim-airline-themes.git'
 NeoBundle 'https://github.com/scrooloose/nerdcommenter.git'
 NeoBundle 'https://github.com/ctrlpvim/ctrlp.vim.git'
 NeoBundle 'https://github.com/Raimondi/delimitMate.git'
 NeoBundle 'https://github.com/Yggdroot/indentLine.git'
 NeoBundle 'https://github.com/Valloric/YouCompleteMe.git'
 NeoBundle 'https://github.com/sheerun/vim-polyglot.git'
 NeoBundle 'Quramy/tsuquyomi'
 NeoBundle 'https://github.com/tpope/vim-surround.git'
 NeoBundle 'https://github.com/mattn/emmet-vim.git'
 NeoBundle 'https://github.com/skammer/vim-css-color.git'
 NeoBundle 'https://github.com/rakr/vim-one.git'
 NeoBundle 'https://github.com/ryanoasis/vim-devicons.git'
call neobundle#end()

" Required:
filetype plugin indent on

" If there are uninstalled bundles found on startup,
" this will conveniently prompt you to install them.
NeoBundleCheck

" =============================================================================
" Basic Settings
" =============================================================================
let mapleader="\<space>"

" split windows to right
set splitright

" line numbers
set number

" encoding
set encoding=utf8


" ######## SEARCH #############################################################
" instant regex preview
set incsearch
" show all search results
set hlsearch
" turn off wrapping while searching
set nowrapscan
" tolle regex
set magic
" better search
set smartcase
set ignorecase

" ######## FORMAT #############################################################
" 1 tab == 4 spaces
set shiftwidth=4
set tabstop=4
set softtabstop=4

" copy the indention from prev line
set autoindent
" auto indent in some files e.g. C-line
set smartindent

" Tab-stuff
set expandtab
set smarttab

" smart backspace
set backspace=indent,eol,start

" wrap long lines - only for display, no new lines!
set linebreak
set wrap

" no new line after 80 chars
set textwidth=0

" ######## VISUAL #############################################################
" show matching brackets
set showmatch

" graphical menu for command mode autocomplete
set wildmenu

" mouse in all modes
set mouse=a

" cursor-zeile markieren
"set cursorline

" show column number 80
set colorcolumn=80

" ######## FILESYSTEM #########################################################
" fu swapfiles
set noswapfile
set nobackup

" auto read file when a file is changed from outside
set autoread
" normal OS clipboard interaction
set clipboard=unnamedplus
set undofile
" maximum number of changes that can be undone
set undolevels=1000
" maximum number lines to save for undo on a buffer reload
set undoreload=10000
set undodir=~/Dotfiles/config/nvim/undodir//

" ######## COLORSCHEME SETTINGS ###############################################

set background=dark

if (empty($TMUX))
  if (has("nvim"))
    let $NVIM_TUI_ENABLE_TRUE_COLOR=1
  endif
  if (has("termguicolors"))
    set termguicolors
  endif
endif

syntax on
colorscheme one

" cursor sawp
let $NVIM_TUI_ENABLE_CURSOR_SHAPE=1

" =============================================================================
" PLUGINS SETTINGS
" =============================================================================

" ######## AIRLINE ############################################################
set laststatus=2
let g:airline_powerline_fonts=1
let g:airline_theme='base16'
let g:airline#extensions#tabline#enabled=1

" ######## YOU COMPLETE ME ####################################################
set completeopt-=preview
let g:ycm_add_preview_to_completeopt=0
" ######## NERDTREE ###########################################################
map <C-n> :NERDTreeToggle<CR>

" =============================================================================
" KEYBINDINGS
" =============================================================================
" Treat long lines as break lines (useful when moving around in them)
map j gj
map k gk

" save as sudo
cabbrev w!! w !sudo tee % > /dev/null %

" use, y and ,p to copy and paste from system clipboard
noremap <leader>y "+y
noremap <leader>Y "+Y

" when pasting from clipboard toggle the paste feature and use the indent
" adjusted paste ]p and ]P. This prevents breaking of alignment when pasting
" in code from websites and etc..
noremap <leader>p :set paste<cr>"+]p:set nopaste<cr>
noremap <leader>P :set paste<cr>"+]P:set nopaste<cr>

" turn of highlighting on backspace
nnoremap <silent> <bs> :nohl<cr>

" save on double esc
map <Esc><Esc> :w<CR>

"buffer browsing bwith left/right arrows
nnoremap <Left> :bprev<CR>
nnoremap <Right> : bnext<CR>
