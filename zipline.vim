" Filename: zipline.vim
" Author:   mikewadsten
" License:  MIT License

" zipline: My own statusline implementation
" Inspiration drawn from itchyny/lightline.vim

" Most colors ripped from lightline solarized_dark scheme.
hi Zipline_Blue     ctermfg=230 ctermbg=33
hi Zipline_Red      ctermfg=230 ctermbg=124
hi Zipline_Green    ctermfg=230 ctermbg=64
hi Zipline_Magenta  ctermfg=230 ctermbg=125
hi Zipline_Git      ctermfg=7   ctermbg=8

" Give mode highlight groups unique names
hi link Zipline_Mode_Normal   Zipline_Blue
hi link Zipline_Mode_Insert   Zipline_Green
hi link Zipline_Mode_Visual   Zipline_Magenta
hi link Zipline_Mode_Replace  Zipline_Red

hi clear StatusLine
hi StatusLine   term=NONE cterm=NONE ctermfg=230 ctermbg=240
hi StatusLineNC term=NONE cterm=NONE ctermfg=10  ctermbg=236
hi ZiplineNC_Filename term=NONE cterm=NONE ctermfg=4 ctermbg=236

function! zipline#mode() abort
  let modemap = {
        \ 'n': 'normal', 'i': 'insert', 'R': 'replace', 'v': 'visual',
        \ 'V': 'V-line', "\<C-v>": 'V-block', 'c': 'command',
        \ 's': 'select', 'S': 's-line', "\<C-s>": 's-block',
        \ 't': 'terminal' }
  let l:mode = mode()
  return '  ' . toupper(get(modemap, l:mode, printf("MODE? %s", l:mode))) . ' '
endfunction

function! zipline#buffers() abort
  call bufferline#refresh_status()
  " bufferline#get_status_string() gets the content that we'd put in
  " &statusline. We're computing that here now, though, so...
  let b = g:bufferline_status_info.before
  let c = g:bufferline_status_info.current
  let a = g:bufferline_status_info.after
  return b.c.a
endfunction

function! zipline#fileinfo() abort
  let _ = &filetype
  if &fileformat != 'unix'
    let _ .= printf(' (%s)', toupper(&fileformat))
  endif
  return _
endfunction

function! zipline#git() abort
  let _ = fugitive#head()
  if _ == ''
    " Just return empty if there's no head
    return ''
  endif
  if strlen(_) > 18
    " Avoid too-long heads
    let _ = printf('%.18s...', _)
  endif
  " Vim strips one leading space from value, because %{} is treated
  " as a 'flag' (src/buffer.c:4141). Work around that by having 2 spaces.
  return printf('  %s ', _)
endfunction

let s:zipline = {
      \ 'active': {
      \   'left':  ['mode', 'git', 'buffers'],
      \   'right': ['fileinfo', 'percent', 'lineinfo']
      \ },
      \ 'inactive': {
      \   'left': ['dimfile'], 'right': []
      \ },
      \ 'exprs': {
      \   'mode': 'zipline#mode()',
      \   'git': 'zipline#git()',
      \   'buffers': 'zipline#buffers()',
      \   'fileinfo': 'zipline#fileinfo()',
      \ },
      \ 'formats': {
      \   'percent': '%3p%%',
      \   'lineinfo': '%3l:%-2v',
      \   'dimfile': '###### %{expand("%:p:~:.:h")}/%0*%#ZiplineNC_Filename#%t'
      \ },
      \ 'mode_colors': {
      \   'n': 'Zipline_Mode_Normal',
      \   'i': 'Zipline_Mode_Insert',
      \   'v': 'Zipline_Mode_Visual',
      \   'V': 'Zipline_Mode_Visual',
      \   "\<C-v>": 'Zipline_Mode_Visual',
      \   's': 'Zipline_Mode_Visual',
      \   'S': 'Zipline_Mode_Visual',
      \   "\<C-s>": 'Zipline_Mode_Visual',
      \   'R': 'Zipline_Mode_Replace',
      \   't': 'Zipline_Mode_Insert'
      \ },
      \ 'highlight': {
      \   'git': 'Zipline_Git',
      \   'dimfile': 'StatusLineNC'
      \ },
      \ }

let s:save_mode = ''
let s:hgroup_activemode = 'Zipline_activemode'

function! zipline#highlight() abort
  " Relink s:hgroup_activemode according to new mode
  if s:save_mode != mode()
    let s:save_mode = mode()

    let hgroup = get(s:zipline.mode_colors, mode(), 'Zipline_Mode_Normal')
    execute printf('hi link %s %s', s:hgroup_activemode, hgroup)
  endif
  return ''
endfunction

function! s:make_pieces(pieces, sep) abort
  let l:bits = []
  for piece in a:pieces
    if piece == 'mode'
      let hgroup = s:hgroup_activemode
    else
      let hgroup = get(s:zipline.highlight, piece, 'StatusLine')
    endif

    if has_key(s:zipline.exprs, piece)
      let expr = '%{' . s:zipline.exprs[piece] . '}'
    elseif has_key(s:zipline.formats, piece)
      let expr = s:zipline.formats[piece]
    else
      echoerr "No exprs or formats for " . piece
      return ''
    endif

    call add(l:bits, '%#' . hgroup . '#' . expr . '%0*')
  endfor
  return join(l:bits, a:sep)
endfunction

function! s:build_line(active)
  let l:_ = '%{zipline#highlight()}'
  let l:side = a:active ? s:zipline.active : s:zipline.inactive
  let l:_ .= s:make_pieces(l:side.left, '') . '%=' . s:make_pieces(l:side.right, ' | ')
  return l:_
endfunction

function! zipline#update()
  let curwin = winnr()
  let lines = winnr('$') == 1 ? [s:build_line(1)] : [s:build_line(1), s:build_line(0)]
  for w in range(1, winnr('$'))
    call setwinvar(w, '&statusline', lines[w != curwin])
  endfor
endfunction

augroup zipline
  autocmd!
  autocmd WinEnter,BufWinEnter,FileType,ColorScheme,SessionLoadPost * call zipline#update()
augroup END