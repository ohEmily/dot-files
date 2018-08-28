" VUNDLE (https://github.com/VundleVim/Vundle.vim)
set nocompatible              " be iMproved, required
filetype off                  " required

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

" let Vundle manage Vundle, required
Plugin 'VundleVim/Vundle.vim'

call vundle#end()            " required
filetype plugin indent on    " required


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
set cursorline          " underlines current line

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

" HEXFILES (from http://vim.wikia.com/wiki/Improved_hex_editing)
" ex command for toggling hex mode - define mapping if desired
command -bar Hex call ToggleHex()

" HEXMODE helper function to toggle hex mode
function ToggleHex()
  " hex mode should be considered a read-only operation
  " save values for modified and read-only for restoration later,
  " and clear the read-only flag for now
  let l:modified=&mod
  let l:oldreadonly=&readonly
  let &readonly=0
  let l:oldmodifiable=&modifiable
  let &modifiable=1
  if !exists("b:editHex") || !b:editHex
    " save old options
    let b:oldft=&ft
    let b:oldbin=&bin
    " set new options
    setlocal binary " make sure it overrides any textwidth, etc.
    silent :e " this will reload the file without trickeries 
              "(DOS line endings will be shown entirely )
    let &ft="xxd"
    " set status
    let b:editHex=1
    " switch to hex editor
    %!xxd
  else
    " restore old options
    let &ft=b:oldft
    if !b:oldbin
      setlocal nobinary
    endif
    " set status
    let b:editHex=0
    " return to normal editing
    %!xxd -r
  endif
  " restore values for modified and read only state
  let &mod=l:modified
  let &readonly=l:oldreadonly
  let &modifiable=l:oldmodifiable
endfunction

" JSON PRETTY PRINT https://pascalprecht.github.io/2014/07/10/pretty-print-json-in-vim/
:command Json :%!python -m json.tool

" highlight Vagrantfile as ruby
"
" Install: $HOME/.vim/plugin/vagrant.vim
" Author: Brandon Philips <brandon@ifup.org>

augroup vagrant
  au!
  au BufRead,BufNewFile Vagrantfile set filetype=ruby
augroup END
