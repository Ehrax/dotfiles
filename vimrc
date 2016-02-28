" =============================================================================
" {{{ BASIC SETTINGS
" =============================================================================
set nocompatible
hi CursorLineNr   term=bold ctermfg=Yellow gui=bold guifg=Yellow

filetype off 
filetype plugin off 
filetype indent off

let mapleader="\<space>"

"split windows to right
set splitright

" ######## SYNTAX #############################################################
syntax enable
set background=dark

" ######## ENCODING ###########################################################
set encoding=utf8
set termencoding=utf-8
set fileencoding=utf-8

" ######## LINE NUMBERS #######################################################
" Line numbers
" set relativenumber
set number

" ######## FORMAT #############################################################
" 1 tab == 4 spaces
set shiftwidth=4
set tabstop=4
set softtabstop=4 
" copy the indention from prev line
set autoindent
" auto indent in some files e.g. C-like
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

" ######## VISUAL #############################################################
" Don't redraw while executing macros (good performance config)
set lazyredraw
" show matching brackets
set showmatch
" graphical menu for command mode autocomplete
set wildmenu
" min 5 zeilen unten und oben platz
set scrolloff=5
" folding
set foldmethod=marker
" set antialias
set antialias
" use tabs
set switchbuf=usetab
" make Vim run moar smooth
set ttyfast
" mouse in all modes
set mouse=a
" cursor-zeile markieren
set cursorline

" fixing delay on leaving insert-mode
set notimeout
set ttimeout
set ttimeoutlen=10

" show column number 80
set colorcolumn=80

" ######## LANG ###############################################################
set spelllang=de,en

" ######## FILESYSTEM #########################################################
" fu swapfiles
set noswapfile
set nobackup
" auto read file when a file is changed from outside
set autoread
" normal OS clipboard interaction
set clipboard=unnamedplus

" ######## UI Options #########################################################

" remove unecssary toolbars
if has('gui_running') 
    set guioptions-=T       "disable tool bar
    set guioptions-=m       "disable menu bar
    set guioptions-=r       "disable right scrollbar
    set guioptions-=L       "disable left scrollbar
endif

" }}}
" =============================================================================
" {{{ PLUGINS 
" =============================================================================
filetype off                  " required
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

  Plugin 'VundleVim/Vundle.vim'
  " git plugin 
  Plugin 'tpope/vim-fugitive'
  " colorsheme 
  Plugin 'chriskempson/base16-vim'
  " nerdtree file manager
  Plugin 'scrooloose/nerdtree'
  " Nerdtree in all tabs
  Plugin 'jistr/vim-nerdtree-tabs'
  " complete me, auto completion
  Plugin 'Valloric/YouCompleteMe'
  " toogle cursor
  Plugin 'jszakmeister/vim-togglecursor'
  " Vim airline status bar
  Plugin 'bling/vim-airline'
  Plugin 'vim-airline/vim-airline-themes'
  " shows git diffrence when editing files
  Plugin 'airblade/vim-gitgutter'
  " auto comment
  Plugin 'scrooloose/nerdcommenter'
  " fuzzy finder
  Plugin 'kien/ctrlp.vim'
  " auto close brackets
  Plugin 'raimondi/delimitmate'
  " Matching Tags
  Plugin 'Valloric/MatchTagAlways'
  " shows color
  Plugin 'lilydjwg/colorizer' 
  " more syntax highlighting
  Plugin 'justinmk/vim-syntax-extra'
  " show indentions
  Plugin 'Yggdroot/indentLine'
  " rainbow brackets
  Plugin 'vim-ruby/vim-ruby'

  filetype on 
  filetype plugin on
  filetype indent on

  call vundle#end()

" }}}
" =============================================================================
" {{{ EXTENDED SETTINGS
" =============================================================================
" ######## MUTE VIM ###########################################################
set noerrorbells visualbell t_vb=
autocmd GUIEnter * set visualbell t_vb=

" ######## FILESYSTEM #########################################################
set undofile
" maximum number of changes that can be undone
set undolevels=1000 
" maximum number lines to save for undo on a buffer reload
set undoreload=10000 
set undodir=~/.vim/undodir//
set viminfo+=n~/.vim/viminfo

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
" {{{ PLUGINS SETTINGS
" =============================================================================

" ######## AIRLINE ############################################################
set laststatus=2
let g:airline_powerline_fonts=1
let g:airline#extensions#tabline#enabled=1
let g:airline_theme='tomorrow'

" ######## GIT GLITTER ########################################################
 set updatetime=250

" ######## CTRL SPACE #########################################################
let g:ctrlp_mruf_max = 10000
let g:ctrlp_max_files = 10000
let g:ctrlp_mruf_last_entered = 0
let g:ctrlp_clear_cache_on_exit = 0
let g:ctrlp_extensions = ['mixed']
let g:ctrlp_cmd = 'CtrlPMixed'
set hidden

" }}}
" =============================================================================
" {{{ KEYBINDINGS 
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
