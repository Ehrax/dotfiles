" =============================================================================
" Plugins {{{
" =============================================================================

" Note: Skip initialization for vim-tiny or vim-small.
if 0 | endif

if &compatible
set nocompatible               " Be iMproved
endif

" Required:
set runtimepath^=~/dotfiles/nvim/bundle/neobundle.vim/

" Required:
call neobundle#begin(expand('~/dotfiles/nvim/bundle/'))

" Required:
NeoBundleFetch 'Shougo/neobundle.vim'

" My Bundles:
 NeoBundle 'https://github.com/tpope/vim-fugitive.git' 
 NeoBundle 'https://github.com/chriskempson/base16-vim.git'
 NeoBundle 'https://github.com/scrooloose/nerdtree.git'
 NeoBundle 'https://github.com/jistr/vim-nerdtree-tabs.git'
 NeoBundle 'https://github.com/jszakmeister/vim-togglecursor.git'
 NeoBundle 'https://github.com/vim-airline/vim-airline.git'
 NeoBundle 'https://github.com/vim-airline/vim-airline-themes.git'
 NeoBundle 'https://github.com/airblade/vim-gitgutter.git'
 NeoBundle 'https://github.com/scrooloose/nerdcommenter.git'
 NeoBundle 'https://github.com/kien/ctrlp.vim.git'
 NeoBundle 'https://github.com/Raimondi/delimitMate.git'
 NeoBundle 'https://github.com/Valloric/MatchTagAlways.git'
 NeoBundle 'https://github.com/justinmk/vim-syntax-extra.git'
 NeoBundle 'https://github.com/Yggdroot/indentLine.git'
 NeoBundle 'https://github.com/vim-ruby/vim-ruby.git'

call neobundle#end()

" Required:
filetype plugin indent on

" If there are uninstalled bundles found on startup,
" this will conveniently prompt you to install them.
NeoBundleCheck
" }}}
" =============================================================================
" Basic Settings {{{ 
" =============================================================================
let mapleader="\<space>"

" split windows to right
set splitright

" line numbers 
set number

" syntax 
syntax enable
set background=dark

" encoding
set encoding=utf8

" lang
set spelllang=de,en

" stfu vim
set noerrorbells visualbell t_vb=
autocmd GUIEnter * set visualbell t_vb=

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
" wrapping words
set formatoptions+=t
" no new line after 80 chars
set textwidth=0
" wrap long lines - only for display, no new lines!
set linebreak
set wrap
" wrap 5 chars before right window border
set wrapmargin=5
" Tab-stuff
set expandtab
set smarttab
" smart backspace
set backspace=indent,eol,start

" ######## VISUAL #############################################################
set nolazyredraw
" show matching brackets
set showmatch
" graphical menu for command mode autocomplete
set wildmenu

set scrolloff=3
" folding
set foldmethod=marker

" use tabs
set switchbuf=usetab

" make Vim run moar smooth
set ttyfast

" mouse in all modes
set mouse=a

" cursor-zeile markieren
set cursorline

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
set undodir=~/dotfiles/nvim/undodir//

" ######## COLORSCHEME SETTINGS ###############################################
let base16colorspace=256
colorscheme base16-ocean
set background=dark
set t_Co=256
" dont syntax highlight extrem long lines...
set synmaxcol=300
set gcr=n:blinkon0

" cursor sawp
if exists('$TMUX')
    let &t_SI = "\<Esc>Ptmux;\<Esc>\e[5 q\<Esc>\\"
    let &t_EI = "\<Esc>Ptmux;\<Esc>\e[2 q\<Esc>\\"
else
    let &t_SI = "\e[5 q"
    let &t_EI = "\e[2 q"
endif

" }}}
" =============================================================================
" PLUGINS SETTINGS {{{ =============================================================================

" ######## AIRLINE ############################################################
set laststatus=2
let g:airline_powerline_fonts=1
let g:airline#extensions#tabline#enabled=1
let g:airline_theme='base16'

" ######## GIT GLITTER ########################################################
 set updatetime=1000

" ######## CTRL SPACE #########################################################
let g:ctrlp_mruf_max = 10000
let g:ctrlp_max_files = 10000
let g:ctrlp_mruf_last_entered = 0
let g:ctrlp_clear_cache_on_exit = 0
let g:ctrlp_extensions = ['mixed']
let g:ctrlp_cmd = 'CtrlPMixed'
set hidden

" ######## DEOPLETE ###########################################################
let g:deoplete#enable_at_startup = 1
if !exists('g:deoplete#omni#input_patterns')
  let g:deoplete#omni#input_patterns = {}
endif

" omnifuncs
augroup omnifuncs
  autocmd!
  autocmd FileType css setlocal omnifunc=csscomplete#CompleteCSS
  autocmd FileType html,markdown setlocal omnifunc=htmlcomplete#CompleteTags
  autocmd FileType javascript setlocal omnifunc=javascriptcomplete#CompleteJS
  autocmd FileType python setlocal omnifunc=pythoncomplete#Complete
  autocmd FileType xml setlocal omnifunc=xmlcomplete#CompleteTags
  autocmd FileType ruby set omnifunc=rubycomplete#Complete
  autocmd FileType ruby let g:rubycomplete_buffer_loading=1
  autocmd FileType ruby let g:rubycomplete_classes_in_global=1
augroup end

" }}}
" =============================================================================
" KEYBINDINGS {{{ 
" =============================================================================
" Treat long lines as break lines (useful when moving around in them)
map j gj
map k gk
" save as sudo
cabbrev w!! w !sudo tee % > /dev/null %

" Paste mode
nnoremap <F2> :set invpaste paste?<CR>
set pastetoggle=<F2>
set showmode

" use, y and ,p to copy and paste from system clipboard
noremap <leader>y "+y
noremap <leader>Y "+Y
" when pasting from clipboard toggle the paste feature and use the indent
" adjusted paste ]p and ]P. This prevents breaking of alignment when pasting
" in code from websites and etc..
noremap <leader>p :set paste<cr>"+]p:set nopaste<cr>
noremap <leader>P :set paste<cr>"+]P:set nopaste<cr>

" NERDTree to F1 
nnoremap <F1> :NERDTreeToggle<cr>

" turn of highlighting on backspace
nnoremap <silent> <bs> :nohl<cr>

" save on double esc
map <Esc><Esc> :w<CR>

"buffer browsing bwith left/right arrows
nnoremap <Left> :bprev<CR>
nnoremap <Right> : bnext<CR>
" }}}