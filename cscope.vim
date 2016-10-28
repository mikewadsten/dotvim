function! s:CscopeAdd(...)
  let argcount = a:0
  if argcount < 1
    echo ":CscopeAdd <file> [<pre-path> [<flags>]]"
    return ''
  endif

  if !filereadable(a:1)
    echo "File not readable:" a:1
    return ''
  endif

  if cscope_connection(2, a:1)
    echo "You wanted to add:"
    echo repeat(' ', 11) . join(a:000)
    echo "Seems to already be a connection to that cscope database?"
    echo ""
    cscope show
  else
    execute "cscope add " . join(a:000)
    echo "cscope database opened"
  endif
endfunction

set nocscopeverbose

" TODO: Intelligent completion based on which arg you're doing?
" Like this? http://vi.stackexchange.com/a/6696
command! -nargs=* -complete=file CscopeAdd call s:CscopeAdd(<f-args>)

" TODO: Gtags

" TODO: Keybindings (including, possibly, tab-completing the tag? ooooh)
