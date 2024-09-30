au FileType feature :setlocal indentexpr=0
set fo+=t

au BufRead,BufNewFile *.md setlocal textwidth=120

" leader is comma
let mapleader=","

" move to beginning/end of line
nnoremap B ^
nnoremap E $

" highlight current line
set cursorline

" load filetype-specific indent files
filetype indent on

" redraw only when we need to.
set lazyredraw

" turn off search highlight
nnoremap <leader><space> :nohlsearch<CR>

runtime macros/matchit.vim

set wildmode=longest,list,full
set wildmenu

set textwidth=0
set wrapmargin=2
set number
set listchars=tab:>-

filetype plugin indent on
set smartindent
set tabstop=2
set shiftwidth=2
set expandtab

nnoremap <leader>n :NERDTreeFocus<CR>
nnoremap <C-n> :NERDTree<CR>
nnoremap <C-t> :NERDTreeToggle<CR>
" nnoremap <C-f> NERDTreeFind<CR>
nnoremap <C-f> :CtrlP<CR>

autocmd FileType yaml setlocal ts=2 sts=2 sw=2 expandtab
let g:indentLine_char = '⦙'

set rtp+=/usr/local/opt/fzf

set concealcursor-=n
set conceallevel=0
set visualbell
set noerrorbells

syntax on

let g:loaded_perl_provider=0

" PLUGINS ----------------------------------------------------------------

" Install Plug if it's not already
let data_dir = has('nvim') ? stdpath('data') . '/site' : '~/.vim'
if empty(glob(data_dir . '/autoload/plug.vim'))
  silent execute '!curl -fLo '.data_dir.'/autoload/plug.vim --create-dirs  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin('~/.vim/plugged')

" Golang
Plug 'fatih/vim-go', { 'do': ':GoUpdateBinaries' }

Plug 'bash-lsp/bash-language-server' " LSP server for Bash
Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' } " Autocompletion engine

" Kubernetes
Plug 'tpope/vim-fugitive' " Git wrapper for handling Kubernetes files

" TypeScript
Plug 'MaxMEllon/vim-jsx-pretty' " Improved JSX/React syntax highlighting
Plug 'peitalin/vim-jsx-typescript' " TSX (TypeScript + JSX) support
Plug 'styled-components/vim-styled-components', { 'branch': 'main' } " Syntax highlighting for styled-components
Plug 'leafgarland/typescript-vim' " TypeScript syntax and indentation
Plug 'neoclide/coc.nvim', {'branch': 'release'} " LSP and autocompletion
Plug 'yuezk/vim-js' " Better JavaScript syntax highlighting and indentation
Plug 'alvan/vim-closetag'

" Ruby and Rails
Plug 'vim-ruby/vim-ruby' " Ruby support for Vim
Plug 'tpope/vim-rails' " Ruby on Rails power tools

" NERD Comment
Plug 'preservim/nerdcommenter'

" Copilot
Plug 'github/copilot.vim'

" Whitespace
Plug 'bronson/vim-trailing-whitespace'

" Colorschemes
Plug 'morhetz/gruvbox'
Plug 'dracula/vim', { 'as': 'dracula' }
Plug 'folke/tokyonight.nvim'
Plug 'shaunsingh/nord.nvim'
Plug 'navarasu/onedark.nvim'
Plug 'catppuccin/nvim', { 'as': 'catppuccin' }
Plug 'rose-pine/neovim', { 'as': 'rose-pine' }
Plug 'sainnhe/everforest'
Plug 'rebelot/kanagawa.nvim'

call plug#end()

" Automatically install plugins if they are missing
" Comment this out after the first run
autocmd VimEnter * if empty(glob('~/.local/share/nvim/plugged/*')) | PlugInstall | endif

colorscheme dracula
