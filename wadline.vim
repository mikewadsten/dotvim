" Filename: wadline.vim
" Author: mikewadsten
" License: MIT License

" wadline: My own statusline implementation
" Inspiration drawn from itchyny/lightline.vim

" Most colors ripped from lightline solarized_dark scheme.
hi Wadline_Blue   ctermfg=230 ctermbg=33
hi Wadline_Green  ctermfg=230 ctermbg=DarkGreen
" TODO: more colors, more mode_colors values...

hi clear StatusLine
hi StatusLine   term=NONE cterm=NONE ctermbg=235
hi StatusLineNC term=NONE cterm=NONE ctermfg=0 ctermbg=233

function! wadline#mode() abort
  let modemap = {
        \ 'n': 'normal', 'i': 'insert', 'R': 'replace', 'v': 'visual',
        \ 'V': 'V-line', "\<C-v>": 'V-block', 'c': 'command',
        \ 's': 'select', 'S': 's-line', "\<C-s>": 's-block',
        \ 't': 'terminal' }
  let l:mode = mode()
  return '  ' . toupper(get(modemap, l:mode, printf("MODE? %s", l:mode))) . ' '
endfunction

function! wadline#buffers() abort
  call bufferline#refresh_status()
  " bufferline#get_status_string() gets the content that we'd put in
  " &statusline. We're computing that here now, though, so...
  let b = g:bufferline_status_info.before
  let c = g:bufferline_status_info.current
  let a = g:bufferline_status_info.after
  return b.c.a
endfunction

function! wadline#fileinfo() abort
  let _ = &filetype
  if &fileformat != 'unix'
    let _ .= printf(' (%s)', toupper(&fileformat))
  endif
  return _
endfunction

let s:wadline = {
      \ 'active': {
      \   'left':  ['mode', 'buffers'],
      \   'right': ['fileinfo', 'percent', 'lineinfo']
      \ },
      \ 'exprs': {
      \   'mode': 'wadline#mode()',
      \   'buffers': 'wadline#buffers()',
      \   'fileinfo': 'wadline#fileinfo()',
      \ },
      \ 'formats': {
      \   'percent': '%3p%%',
      \   'lineinfo': '%3l:%-2v',
      \ },
      \ 'mode_colors': {
      \   'n': 'Wadline_Blue',
      \   'i': 'Wadline_Green'
      \ },
      \ 'highlight': {
      \ },
      \ }

let s:save_mode = ''

function! wadline#highlight() abort
  " Relink Wadline_modeactive according to new mode
  if s:save_mode != mode()
    let s:save_mode = mode()

    let hgroup = get(s:wadline.mode_colors, mode(), 'User7')
    execute printf('hi link Wadline_modeactive %s', hgroup)
  endif
  return ''
endfunction

function! s:make_pieces(pieces, sep) abort
  let l:bits = []
  for piece in a:pieces
    if piece == 'mode'
      let hgroup = 'Wadline_modeactive'
    else
      let hgroup = get(s:wadline.highlight, piece, 'StatusLine')
    endif

    if has_key(s:wadline.exprs, piece)
      let expr = '%{' . s:wadline.exprs[piece] . '}'
    elseif has_key(s:wadline.formats, piece)
      let expr = s:wadline.formats[piece]
    else
      echoerr "No exprs or formats for " . piece
      return ''
    endif

    call add(l:bits, '%#' . hgroup . '#' . expr . '%0*')
  endfor
  return join(l:bits, a:sep)
endfunction

function! s:build_line()
  let l:_ = '%{wadline#highlight()}'
  let l:_ .= s:make_pieces(s:wadline.active.left, '') . '%=' . s:make_pieces(s:wadline.active.right, ' | ')
  return l:_
endfunction

function! wadline#update()
  let &statusline = s:build_line()
endfunction

" TODO: Inactive windows should have their statuslines dimmed.
augroup wadline
  autocmd!
  autocmd WinEnter,BufWinEnter,FileType,ColorScheme,SessionLoadPost * call wadline#update()
augroup END
