if 0  " has('nvim')
  let s:plug_path = '~/.nvim/autoload/plug.vim'
else
  let s:plug_path = '~/.vim/autoload/plug.vim'
endif

if empty(glob(s:plug_path))
  echo "Looks like the first time setup for vim-plug..."
  silent exe '!curl -fLo ' . s:plug_path ' --create-dirs ' .
        \ 'https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  autocmd VimEnter * PlugInstall | source $MYVIMRC
endif

" Settings {{

" let g:SuperTabDefaultCompletionType = "<c-n>"

  let g:switch_custom_definitions =
        \ [
        \   {'\<==\>': '\<!=\>', '\<!=\>': '\<==\>'}
        \ ]

  " CppUTest test macros
  let s:switch_cpputest = {
        \ '\<TEST\>': 'IGNORE_TEST',
        \ '\<IGNORE_TEST\>': 'TEST' }
  autocmd Filetype cpp let b:switch_custom_definitions =
        \ [
        \   s:switch_cpputest
        \ ]

  autocmd Filetype python let b:switch_custom_definitions =
        \ [
        \   ['\<or\>', '\<and\>'],
        \ ]

  " I will be integrating bufferline into my own statusline.
  let g:bufferline_echo = 0

" }}

" Use DotvimPath() for full standalone installation. :)
call plug#begin(DotvimPath() . '/plugged')

Plug 'altercation/vim-colors-solarized'

" So much Tim Pope...
Plug 'tpope/vim-surround'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-repeat'
Plug 'tpope/vim-dispatch'
Plug 'tpope/vim-unimpaired'
let g:commentary_map_backslash = 0
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-scriptease'

Plug 'nathanaelkane/vim-indent-guides'
Plug 'airblade/vim-gitgutter'

Plug 'tmhedberg/matchit'
Plug 'python_match.vim'

Plug 'python.vim'

Plug 'justinmk/vim-dirvish'

Plug 'MarcWeber/vim-addon-mw-utils'
Plug 'tomtom/tlib_vim'
Plug 'garbas/vim-snipmate'
Plug 'ervandew/supertab'

Plug 'embear/vim-localvimrc'

Plug 'jiangmiao/auto-pairs'

Plug 'AndrewRadev/switch.vim'

Plug 'bling/vim-bufferline'

" TODO: vim-over?
call plug#end()

" Total hack
augroup mikeInitReloadPlugins
  autocmd!
  " After each write to this init.vim file, source it.
  let s:plugins_file_path = resolve(expand('<sfile>:p'))
  execute 'autocmd! BufWritePost ' . s:plugins_file_path . " source " . s:plugins_file_path
augroup END
