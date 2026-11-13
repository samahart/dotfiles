" ~/.vimrc — small, sane defaults
set nocompatible
syntax on
filetype plugin indent on

set number relativenumber
set mouse=a
set tabstop=4 shiftwidth=4 expandtab smartindent
set ignorecase smartcase incsearch hlsearch
set scrolloff=5
set wildmenu
set backspace=indent,eol,start
set undofile undodir=~/.vim/undo//
set noswapfile
set clipboard=unnamedplus

" Clear search highlight with Esc
nnoremap <silent> <Esc> :nohlsearch<CR><Esc>
