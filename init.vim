" dotvim
" A fresh take on my Vim/Neovim setup.

set nocompatible
set mouse=a
set virtualedit=onemore

" Stuff copied from vim-sensible {{

if has('autocmd')
  filetype plugin indent on
endif
if has('syntax') && !exists('g:syntax_on')
  syntax enable
endif

" Use :help 'option' to see the documentation for the given option.
" (Single quotes ensures :help finds the option.)
set autoindent
set backspace=indent,eol,start
set complete=.,w,b,u,t,i
set smarttab

set nrformats-=octal

set ttimeout
set ttimeoutlen=100

set incsearch
" Use <C-L> to toggle the highlighting of :set hlsearch.
if maparg('<C-L', 'n') ==# ''
  nnoremap <silent> <C-L> :set invhlsearch<C-R>=has('diff')?'<Bar>diffupdate':''<CR><CR><C-L>
endif

set laststatus=2
set ruler
set viewoptions=folds,options,cursor
" Better Unix compatibility on Windows
set viewoptions+=unix

set scrolloff=1 scrolljump=1
set sidescrolloff=5
set display=lastline

set splitright splitbelow

if v:version > 703 || v:version == 703 && has("patch541")
  set formatoptions+=j  " Delete comment character when joining commented lines
endif

set autoread

set history=1000
if !empty(&viminfo)
  set viminfo^=!
endif
set noswapfile

set sessionoptions-=options

" Allow color schemes to do bright colors without forcing bold.
if &t_Co == 8 && $TERM !~# '^linux\|^Eterm'
  set t_Co=16
endif

" Load matchit.vim, but only if the user hasn't installed a newer version.
if !exists('g:loaded_matchit') && findfile('plugin/matchit.vim', &rtp) ==# ''
  runtime! macros/matchit.vim
endif

" }}

" Abbreviate messages, and hide the intro
set shortmess+=aoOtTI

if has('persistent_undo')
  set undofile
  set undolevels=1000
  set undoreload=10000
  let &undodir=$HOME . '/.vimundo'
endif

" set spell
set hidden
set switchbuf=useopen

set list
" TODO
set listchars=tab:\ \ 

set number
set noshowmatch                         " This just slows down typing if it's on.
set ignorecase
set smartcase
set wildmode=list:longest,full
set whichwrap=b,s,h,l,<,>,[,]

" Default indentation settings. Wow, so PEP-8.
if 0  " TODO: Do this based on filetype...
  set tabstop=4
  set shiftwidth=4
  set softtabstop=4
else
  set tabstop=2 shiftwidth=2 softtabstop=2
endif
set expandtab
set shiftround

set colorcolumn=80
set noshowmode " This is what wadline is for

" Key mappings {
  " Escape is annoying to hit.
  inoremap jk <Esc>
  " And I've become rather addicted to just hitting q to cancel everything...
  " ... plus, nobody starts a macro while in visual mode... right?
  vnoremap q <Esc>

  " Stupid shift-key fixes
  if has("user_commands")
    command! -bang -nargs=* -complete=file E e<bang> <args>
    command! -bang -nargs=* -complete=file W w<bang> <args>
    command! -bang -nargs=* -complete=file Wq wq<bang> <args>
    command! -bang -nargs=* -complete=file WQ wq<bang> <args>
    command! -bang Wa wa<bang>
    command! -bang WA wa<bang>
    command! -bang Q q<bang>
    command! -bang Qa qa<bang>
    command! -bang QA qa<bang>

    command! Bn bn
    command! BN bn
    command! Bp bp
    command! BP bp
  endif

  let mapleader = ','

  nmap <silent> <Leader>/ :set invhlsearch<CR>
  " I seem to have a habit of hitting q and then leader...
  nmap <silent> q, ,
  " and q:. Who even uses Ex mode, I mean come on.
  nnoremap <silent> q: :

  " Jump to merge conflict markers.
  map <leader>fc /\v^[<\|=>]{7}( .*\|$)<CR>

  " Go back to visual mode after indent change.
  vnoremap < <gv
  vnoremap > >gv

  " Allow repeat operator to work on visual selection.
  " http://stackoverflow.com/a/8064607/127816
  vnoremap . :normal .<CR>

  " Delete to black hole register with <leader>d
  nnoremap <leader>d "_dd
  vnoremap <leader>d "_d

  " Save some effort on having to push Shift for commands...
  nnoremap ; :

  " I have literally never used Ex mode. Make Q a bit more useful.
  nnoremap Q @@

  " vim-dirvish takes over -, but now that I know about what + does, I would
  " sort of like the functionality of - (minus)! But I don't need what _
  " provides, so let's override that.
  noremap _ -

  " switch.vim
  nnoremap <silent> <BS> :Switch<CR>

" }

" Switch to current file directory automatically
autocmd BufEnter * if bufname("") !~ "^\[A-Za-z0-9\]*://" |
      \ execute 'lcd ' . fnamemodify(resolve(expand('%:p')), ':h') |
      \ endif

" TODO: cscope {
" }

" Omnicompletion {
  if has("autocmd") && exists("+omnifunc")
    autocmd Filetype *
          \if &omnifunc == "" |
          \setlocal omnifunc=syntaxcomplete#Complete |
          \endif
  endif

  hi Pmenu ctermfg=black ctermbg=lightgray
  "hi PmenuSbar ctermfg=darkcyan ctermbg=lightgray
  "hi PmenuThumb ctermfg=lightgray ctermbg=darkgray

  " Automatically open/close the popup menu.
  augroup omnicomplete
    autocmd!
    autocmd CursorMovedI,InsertLeave * if pumvisible() == 0 | silent! pclose | endif
  augroup END

  set completeopt=menu,preview,longest

  function! s:CompleteMap(key,mapping)
    execute printf('inoremap <expr> %s pumvisible() ? "%s" : "%s"', a:key, a:mapping, a:key)
  endfunction

  if 0
    " Doesn't work...
    call s:CompleteMap('<Esc>',   '<C-e>')
    call s:CompleteMap('<CR>',    '<C-y>')
    call s:CompleteMap('<Down>',  '<C-n>')
    call s:CompleteMap('<Up>',    '<C-p>')
  endif
" }

" TODO: neocomplete

" TODO: neovim-specific stuff

" Plugins! {{

  set background=dark

  let s:dotvim_path = fnamemodify(resolve(expand('<sfile>:p')), ':h')
  function! DotvimPath()
    return s:dotvim_path
  endfunction
  function! LoadDotvimFile(name)
    let l:fpath =  s:dotvim_path . '/' . a:name
    if filereadable(l:fpath)
      execute "source " . l:fpath
    " else
    "   echo "not readable: " . l:fpath
    endif
  endfunction

  " If there's a preplug.work.vim file, load it first. Lets us make settings for
  " plugins, etc.
  call LoadDotvimFile('preplug.work.vim')
  call LoadDotvimFile('preplug.local.vim')

  " Find the plugins.vim alongside this init.vim file!
  call LoadDotvimFile('plugins.vim')

" }}

" Colorscheme {

  let g:solarized_termcolors=256
  let g:solarized_termtrans = 0
  let g:solarized_contrast="high"
  try
    set background=dark
    colorscheme solarized
  catch /E185:/
    echo "solarized colorscheme not found, let's do a PlugInstall"
    PlugInstall
    colorscheme solarized
  endtry

  " hi LineNR ctermbg=NONE ctermfg=237
  hi VertSplit ctermbg=236 ctermfg=236

  " The following content provided by:
  " howivim airblade

  hi clear StatusLine
  hi clear StatusLineNC
  " hi StatusLine   term=bold cterm=bold ctermfg=White ctermbg=235
  hi User1                      ctermfg=4          guifg=#40ffff            " Identifier
  hi User2                      ctermfg=2 gui=bold guifg=#ffff60            " Statement
  hi User3 term=bold cterm=bold ctermfg=1          guifg=White   guibg=Red  " Error
  hi User4                      ctermfg=1          guifg=Orange             " Special
  hi User5                      ctermfg=10         guifg=#80a0ff            " Comment
  hi User6 term=bold cterm=bold ctermfg=1          guifg=Red                " WarningMsg
  set laststatus=2

  " My own personal statusline 'plugin'
  call LoadDotvimFile('wadline.vim')

" }

" Filetypes {

  " 99% of my C++ use (at work) is in unit tests, and scanning the includes
  " there can take a second or two each time. Don't do this.
  autocmd! Filetype cpp setlocal complete-=i

  autocmd! Filetype cpp,html,xml let b:AutoPairs = extend({'<': '>'}, g:AutoPairs, 'keep')

" }

" TODO total hack
augroup mikeInitReload
  autocmd!
  " After each write to this init.vim file, source it.
  execute printf('autocmd! BufWritePost %s source %%', resolve(expand('<sfile>:p')))
augroup END

augroup restoreCursor
  autocmd!
  autocmd! BufWinEnter *
        \ if &filetype != "netrw" && line("'\"") > 1 && line("'\"") <= line("$") |
        \ execute 'normal! g`"' | 
        \ endif
augroup END

" scriptease-lite {

" TODO: figure out what to do with this
function! s:get_visual_selection()
  let sel_save = &selection
  let cb_save = &clipboard
  let reg_save = @@
  try
    set selection=inclusive clipboard-=unnamed clipboard-=unnamedplus
    silent exe "normal! gvy"
    redraw
    let foo = substitute(@@, '\v\C\n%(\s*\\)=', '', 'g')
    let b:vis = foo
    return foo
  finally
    let @@ = reg_save
    let &selection = sel_save
    let &clipboard = cb_save
  endtry
endfunction

" Scan current line and up for any continuation lines,
" then down, joining continuations. Returns full string.
function! s:grab_code_here()
  let l:curline = line('.')
  let l:continuation = '\v\C^%(\s*\\)'
  while l:curline > -1 && (match(getline(l:curline), l:continuation) != -1)
    let l:curline -= 1
  endwhile

  if l:curline <= 1
    echoerr "grab_code_here(): got to top of file!"
    return ""
  endif

  let l:content = getline(l:curline)
  let l:curline += 1
  while l:curline <= line('$')
    let l:line = getline(l:curline)
    if -1 == match(l:line, l:continuation)
      break
    else
      let l:content .= substitute(getline(l:curline), l:continuation, '', 'g')
      let l:curline += 1
    endif
  endwhile
  " let b:code = l:content
  echom l:content
  return l:content
endfunction

let a = 1 + 2
      \ + 3 *
      \ 4

" xnoremap <silent> gz :<C-U>call <SID>get_visual_selection()<CR>

" Execute the line of vimscript under the cursor (as found by scanning for
" continuations) -- intended for use when hacking on statusline format.
autocmd Filetype vim nnoremap <buffer> <silent> gz :execute <SID>grab_code_here()<CR>

" }

" vim: set ft=vim et sw=2 ts=2 sts=2:
