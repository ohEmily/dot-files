" GENERAL EDITOR SETTINGS
set number              " line numbers
colors koehler          " good default color scheme
syntax on               " syntax highlighting

set showcmd             " show partial command in bottom line of editor (adds helpful info to what you're typing)
set showmatch           " show matching brackets
set ignorecase          " case insensitive matching
set smartcase           " smart case matching
set incsearch           " incremental search
set mouse=a             " enable mouse usage

" have Vim jump to the last position when reopening a file
if has("autocmd")
  au BufReadPost * if line("'\"") > 0 && line("'\"") <= line("$")
    \| exe "normal! g'\"" | endif
endif

" FILES
" When coding, auto-indent by 4 spaces, just like in K&R
" Note that this does NOT change tab into 4 spaces
" You can do that with "set tabstop=4", which is a BAD idea
set shiftwidth=4

" replace tab with 8 spaces
set expandtab

" MAKEFILES
autocmd FileType make setlocal noexpandtab

" PYTHON FILES
autocmd FileType python set tabstop=4|set shiftwidth=4|set expandtab

" TEXT FILES
" Jae's settings when editing *.txt files
"   - automatically indent lines according to previous lines
"   - replace tab with 8 spaces
"   - when I hit tab key, move 2 spaces instead of 8
"   - wrap text if I go longer than 76 columns
"   - check spelling
autocmd FileType text setlocal autoindent expandtab softtabstop=2 textwidth=76 spell spelllang=en_us
