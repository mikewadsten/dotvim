let s:suite = themis#suite('cscope')
let s:assert = themis#helper('assert')

let s:cwd = expand('<sfile>:p:h')
let s:dotpath = fnamemodify(s:cwd, ':h')

function! s:suite.before()
  cscope kill -1
  " Change to test directory
  execute "chdir " . s:cwd
  call system('cscope -Rbq -P' . s:cwd)
  chdir -
  source cscope.vim
endfunction

function! s:suite.after()
  call system(printf("rm -f %s/cscope.*out", s:cwd))
endfunction

function! s:suite.before_each()
  cscope kill -1
  chdir /tmp
  call s:assert.equals(cscope_connection(), 0, "Saw cscope connection after chdir to /tmp")
endfunction

function! s:suite.detect_with_dir()
  let b:git_dir = '/tmp'
  call cscope#detect(s:cwd)
  call s:assert.equals(cscope_connection(), 1,
        \              "Did not see cscope connection after detect")
  call s:assert.equals(cscope_connection(2, s:cwd . '/cscope.out'), 1,
        \              "Didn't find cscope.out in given dir!")
endfunction

function! s:suite.detect_git_dir()
  " Default is to use b:git_dir for detection. This must then end in .git
  let b:git_dir = s:cwd . '/.git'
  call cscope#detect()
  call s:assert.equals(cscope_connection(), 1,
        \              "Did not see cscope connection after detect")
  call s:assert.equals(cscope_connection(2, s:cwd . '/cscope.out'), 1,
        \              "Didn't find cscope.out in given dir!")
endfunction

function! s:suite.CscopeAdd_no_prepath()
  execute "CscopeAdd " . s:cwd . "/cscope.out"

  call s:assert.equals(cscope_connection(), 1)
  call s:assert.equals(cscope_connection(4, s:cwd . '/cscope.out', s:cwd), 1)
endfunction

function! s:suite.CscopeAdd_prepath()
  execute "CscopeAdd " . s:cwd . "/cscope.out /tmp"

  call s:assert.equals(cscope_connection(), 1)
  call s:assert.equals(cscope_connection(4, s:cwd . '/cscope.out', '/tmp'), 1)
endfunction

function! s:suite.CscopeAdd_flags()
  " Can't assert on flags being there, but we can assert on the connection
  execute "CscopeAdd " . s:cwd . "/cscope.out /var -C"

  call s:assert.equals(cscope_connection(), 1)
  call s:assert.equals(cscope_connection(4, s:cwd . '/cscope.out', '/var'), 1)
endfunction
