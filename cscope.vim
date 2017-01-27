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
    let prepath = expand(get(a:000, 1, fnamemodify(file, ':h')))
    let flags = get(a:000, 2, '-ia')

    " Validate arguments.
    if !filereadable(file)
      echo "File not readable:" file
      return ''
    elseif prepath[0] == '-'
      " Second argument is flags.
      let flags = prepath
      let prepath = fnamemodify(file, ':p:h')
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
    let prepath = expand(get(a:000, 1, fnamemodify(file, ':h')))
    let flags = get(a:000, 2, '-ia')

    " Validate arguments.
    if !filereadable(file)
      echo "File not readable:" file
      return ''
    elseif prepath[0] == '-'
      " Second argument is flags.
      let flags = prepath
      let prepath = fnamemodify(file, ':p:h')
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

  function! s:resolve_git_root(git_dir)
    let answer = a:git_dir

    " Since the git repository may be a submodule, use rev-parse to get the
    " working directory.
    let cmd = printf('git --git-dir=%s rev-parse --show-toplevel', a:git_dir)
    let rsp = system(cmd)
    if v:shell_error
      echo printf("git rev-parse errored with %d\n%s", v:shell_error, rsp)
      " Hack for tests - instead of erroring, strip what we assume is .git at
      " the end of the b:git_dir variable.
      return fnamemodify(b:git_dir, ':h')
    endif

    return substitute(rsp, '\n', '', '')
  endfunction

  function! cscope#detect(...)
    " One optional argument, to override b:git_dir check
    if a:0 > 0
      if !isdirectory(a:1)
        echo printf("cscope#detect(%s): Not a directory", shellescape(a:1))
        return 0
      else
        let root = a:1
      endif
    else
      " No arguments passed
      if !exists('b:git_dir')
        return 0
      else
        let root = s:resolve_git_root(b:git_dir)
      endif
    endif

    let silent = get(g:, 'cscope_detect_silent', 1) ? 'silent! ' : ''

    if executable('cscope')
      if filereadable(root . '/cscope.out')
        execute printf("%sCscopeAdd %s/cscope.out", silent, root)
      elseif filereadable(root . '/.git/cscope')  " git hooks based
        execute printf("%sCscopeAdd %s/.git/cscope %s", silent, root, root)
      endif
    endif

    if executable('gtags-cscope') && filereadable(root . '/GTAGS')
      execute printf("%sGtagsAdd %s/GTAGS", silent, root)
    endif

    return 1
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

  function! s:generate(directory, tagkind, cmd) abort
    let directory = a:directory
    if directory == ''
      if !exists("b:git_dir")
        return 0
      endif
      let directory = s:resolve_git_root(b:git_dir)
    endif

    if !isdirectory(directory)
      echoerr "Not a directory"
      return 0
    endif

    echo "Working on it..."

    let savecwd = getcwd()
    execute printf("chdir %s", escape(directory, ' '))
    echo system(printf("%s 2>&1 >/dev/null", a:cmd))
    execute printf("chdir %s", escape(savecwd, ' '))
  
    redraw
    echo printf("%s generation complete!", a:tagkind)

    return 1
  endfunction

" }}

" TODO: Intelligent completion based on which arg you're doing?
" Like this? http://vi.stackexchange.com/a/6696
if executable('cscope')
  function! cscope#gen_cscope(...) abort
    return s:generate(get(a:000, 0, ''), 'cscope', 'cscope -Rbq -f cscope.out')
  endfunction

  command! -nargs=* -complete=file CscopeAdd call s:add_cscope(<f-args>)
  command! -nargs=? -complete=dir CscopeGen call cscope#gen_cscope(<f-args>) | call cscope#detect(<f-args>)
endif
if executable('gtags-cscope')
  function! cscope#gen_gtags(...) abort
    return s:generate(get(a:000, 0, ''), 'gtags', 'gtags --gtagslabel ctags')
  endfunction

  command! -nargs=* -complete=file GtagsAdd  call s:add_gtags(<f-args>)
  command! -nargs=? -complete=dir GtagsGen call cscope#gen_gtags(<f-args>) | call cscope#detect(<f-args>)
endif

" FIXME hack to work around plugin load order
if get(g:, 'cscope_has_fugitive', 1)
  function! s:fugitive_boot()
    augroup cscopeDetect
      autocmd!
      autocmd User Fugitive silent call cscope#detect()
    augroup END
  endfunction

  autocmd! User FugitiveBoot call s:fugitive_boot()
endif

" Key bindings {{

  nnoremap <silent>   <Plug>cscopePrompt :call <SID>prompt()<CR>
  " Launch prompt
  let s:trigger = has("nvim") ? "<C-Space>" : "<C-@>"
  exe printf("nmap %s<Space>   <Plug>cscopePrompt", s:trigger)
  exe printf("nmap %s%s        <Plug>cscopePrompt", s:trigger, s:trigger)
  exe printf("nmap %s?         <Plug>cscopePrompt", s:trigger)
  exe printf("nmap %s<C-?>     <Plug>cscopePrompt", s:trigger)

  " Go right to a query operation
  for s:c in ['s', 'g', 't', 'c', 'd', 'e', 'f', 'i']
    let s:nr = char2nr(s:c)
    execute printf("nnoremap <silent> %s%c :call <SID>do_cs_find('%c')<CR>", s:trigger, s:nr, s:nr)
    unlet s:c
    unlet s:nr
  endfor

  set nocscopeverbose
  " Use both cscope and ctags for 'ctrl-]', ':ta', and 'vim -t'
  set cscopetag

" }}
