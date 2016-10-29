" Script functions {{

  function! s:add_cscope(...) abort
    if !executable('cscope')
      echo "cscope not found"
      return ''
    elseif a:0 < 1
      echo ":CscopeAdd <file> [<pre-path>=file:p:h] [<flags>=-ia]"
      return ''
    endif

    " Pull arguments out into variables.
    let file = fnamemodify(expand(a:1), ':p')
    let prepath = expand(get(a:000, 2, fnamemodify(file, ':h')))
    let flags = get(a:000, 3, '-ia')

    " Validate arguments.
    if !filereadable(file)
      echo "File not readable:" file
      return ''
    elseif prepath[0] == '-'
      " Second argument is flags.
      let prepath = fnamemodify(file ':p:h')
      let flags = ''
    elseif !isdirectory(prepath)
      echo "Not a directory:" prepath
      return ''
    endif

    if cscope_connection(2, file)
      echo "You wanted to add:"
      echo repeat(' ', 11) . join(a:000)
      echo "Seems to already be a connection to that cscope database?"
      echo ""
      cscope show
    else
      let save_csverb=&cscopeverbose
      let save_csprg = &cscopeprg
      set nocscopeverbose cscopeprg=cscope
      try
        execute printf("cscope add %s %s %s", file, prepath, flags)
        echo "cscope database opened:" file
      finally
        let &csverb=save_csverb
        let &cscopeprg = save_csprg
      endtry
    endif
  endfunction

  function! s:add_gtags(...) abort
    if !executable('gtags-cscope')
      echo "gtags-cscope not found"
      return ''
    elseif a:0 < 1
      echo ":GtagsAdd <file> [<pre-path>=file:p:h [<flags>=-ia]]"
      return ''
    endif

    " Pull arguments out into variables.
    let file = fnamemodify(expand(a:1), ':p')
    let prepath = expand(get(a:000, 2, fnamemodify(file, ':h')))
    let flags = get(a:000, 3, '-ia')

    " Validate arguments.
    if !filereadable(file)
      echo "File not readable:" file
      return ''
    elseif prepath[0] == '-'
      " Second argument is flags.
      let prepath = fnamemodify(file ':p:h')
      let flags = ''
    elseif !isdirectory(prepath)
      echo "Not a directory:" prepath
      return ''
    endif

    if cscope_connection(2, file)
      echo "You wanted to add:"
      echo repeat(' ', 11) . join(a:000)
      echo "Seems to already be a connection to that database?"
      echo ""
      cscope show
    else
      let save_csprg = &cscopeprg
      let save_gtr = $GTAGSROOT
      let save_gdp = $GTAGSDBPATH
      let save_csverb = &cscopeverbose
      set nocscopeverbose cscopeprg=gtags-cscope
      let $GTAGSROOT = prepath
      let $GTAGSDBPATH = prepath
      try
        execute printf("cscope add %s %s %s", file, prepath, flags)
        echo "gtags-cscope database opened:" file
      finally
        let $GTAGSROOT = save_gtr
        let $GTAGSDBPATH = save_gdp
        let &csverb = save_csverb
        let &cscopeprg = save_csprg
      endtry
    endif
  endfunction

  function! s:do_cs_find(key)
    let cw = expand('<cword>')
    let cf = expand('<cfile>')
    if cw == '' && cf == ''
      echo "Nothing under cursor"
      return
    endif

    let csfindargs = {
          \'s': cw,
          \'g': cw,
          \'t': cw,
          \'c': cw,
          \'d': cw,
          \'e': cw,
          \'f': cf,
          \'i': cf
          \}

    if !has_key(csfindargs, a:key)
      echo "cscope.vim: do_cs_find missing key:" a:key
      return ''
    endif
    let arg = csfindargs[a:key]
    try
      execute printf("cscope find %s %s", a:key, arg)
    catch
      echo v:exception
    endtry
  endfunction

  function! s:prompt()
    if expand('<cword>') == '' && expand('<cfile>') == ''
      echo "Nothing under cursor"
      return
    endif

    let handlekeys = "sgtcdefi"
    let prompt = "&symbol\n&definition\n&text\n&calls\ncalle&d by this\n&egrep\ngo to &file\n&includes\n& cancel"
    let which = confirm("cscope search type?", prompt, 0)
    if which && which <= strlen(handlekeys)
      call s:do_cs_find(handlekeys[which - 1])
    endif
  endfunction

" }}

" TODO: Intelligent completion based on which arg you're doing?
" Like this? http://vi.stackexchange.com/a/6696
if executable('cscope')
  command! -nargs=* -complete=file CscopeAdd call s:add_cscope(<f-args>)
endif
if executable('gtags-cscope')
  command! -nargs=* -complete=file GtagsAdd  call s:add_gtags(<f-args>)
endif

" Key bindings {{

  nnoremap <silent>   <Plug>cscopePrompt :call <SID>prompt()<CR>
  " Launch prompt
  nmap <C-@><Space>   <Plug>cscopePrompt
  nmap <C-@><C-@>     <Plug>cscopePrompt
  nmap <C-@>?         <Plug>cscopePrompt
  nmap <C-@><C-?>     <Plug>cscopePrompt

  " Go right to a query operation
  for c in ['s', 'g', 't', 'c', 'd', 'e', 'f', 'i']
    execute printf("nnoremap <silent> <C-@>%s :call <SID>do_cs_find('%s')<CR>", c, c)
  endfor

  set nocscopeverbose
  " Use both cscope and ctags for 'ctrl-]', ':ta', and 'vim -t'
  set cscopetag

" }}
