let s:runtime_dir = DotvimPath() . '/.runtime'
let s:autoload_dir = s:runtime_dir . '/autoload'
if !isdirectory(s:autoload_dir)
  call mkdir(s:autoload_dir, 'p')
endif
execute 'set runtimepath+=' . s:runtime_dir

let s:plug_path = s:autoload_dir . '/plug.vim'
if empty(glob(s:plug_path))
  echo "Looks like the first time setup for vim-plug..."
  silent exe '!curl -fLo ' . s:plug_path ' --create-dirs ' .
        \ 'https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  autocmd VimEnter * PlugInstall | execute "source " . DotvimPath() . '/init.vim'
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

  let g:commentary_map_backslash = 0

  " let g:ale_linters = {'python': ['pylint']}

  let g:indentLine_setColors = 1
  let g:indentLine_color_term = 0

" }}

" Use DotvimPath() for full standalone installation. :)
call plug#begin(DotvimPath() . '/.plugged')

Plug 'altercation/vim-colors-solarized'

" So much Tim Pope...
Plug 'tpope/vim-surround'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-repeat'
Plug 'tpope/vim-dispatch'
Plug 'tpope/vim-unimpaired'
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-scriptease'

" Plug 'nathanaelkane/vim-indent-guides'
Plug 'Yggdroot/indentLine'
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

" Lint
Plug 'ynkdir/vim-vimlparser'
Plug 'syngan/vim-vimlint'

Plug 'thinca/vim-themis'
Plug 'rust-lang/rust.vim'

Plug 'tpope/vim-abolish'

Plug 'w0rp/ale'

" TODO: vim-over?
call plug#end()

call LoadDotvimFile('cscope.vim')

" Total hack
augroup mikeInitReloadPlugins
  autocmd!
  " After each write to this init.vim file, source it.
  let s:plugins_file_path = resolve(expand('<sfile>:p'))
  execute 'autocmd! BufWritePost ' . s:plugins_file_path . " source " . s:plugins_file_path
augroup END
