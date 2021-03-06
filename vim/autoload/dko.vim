" autoload/dko.vim
"
" vimrc and debugging helper funtions
"

" ============================================================================
" Guards
" ============================================================================

if exists('g:loaded_dko') | finish | endif
let g:loaded_dko = 1

" ============================================================================
" Setup vars
" ============================================================================

let g:dko#vim_dir = fnamemodify(resolve(expand('$MYVIMRC')), ':p:h')
let g:dko#plug_dir = '/vendor/'
let g:dko#plug_absdir = g:dko#vim_dir . g:dko#plug_dir

" ============================================================================
" General VimL utility functions
" ============================================================================

" Output &runtimepath, one per line, to current buffer
function! dko#Runtimepath() abort
  put! =split(&runtimepath, ',', 0)
endfunction

" Declare and define var as new dict if the variable has not been used before
"
" @param  {String} var
" @return {String} the declared var name
function! dko#InitDict(var) abort
  let {a:var} = exists(a:var) ? {a:var} : {}
  return {a:var}
endfunction

" Declare and define var as new list if the variable has not been used before
"
" @param  {String} var
" @return {String} the declared var name
function! dko#InitList(var) abort
  let {a:var} = exists(a:var) ? {a:var} : []
  return {a:var}
endfunction

" Return shortened path
"
" @param {String} path
" @param {Int} max
" @return {String}
function! dko#ShortenPath(path, max) abort
  let l:full = fnamemodify(a:path, ':~:.')
  return len(l:full) > a:max
        \ ? ''
        \ : ' ' . (len(l:full) == 0 ? '~' : l:full) . ' '
endfunction

" Generate a string command to map keys in nvo&ic modes to a command
"
" @param  {Dict}    settings
" @param  {String}  settings.key
" @param  {String}  [settings.command]
" @param  {Int}     [settings.special]
" @param  {Int}     [settings.remap]
" @return {String}  to execute (this way :verb map traces back to correct file)
function! dko#MapAll(settings) abort
  " Auto determine if special key was mapped
  " Just in case I forgot to include cpoptions guards somewhere
  let l:special = get(a:settings, 'special', 0) || a:settings.key[0] ==# '<'
        \ ? '<special>'
        \ : ''

  let l:remap = get(a:settings, 'remap', 1)
        \ ? 'nore'
        \ : ''

  " Key to map
  let l:lhs = '<silent>'
        \ . l:special
        \ . ' ' . a:settings.key . ' '

  " Command to map to
  if !empty(get(a:settings, 'command', ''))
    let l:rhs_nvo = ':<C-U>' . a:settings.command . '<CR>'
    let l:rhs_ic  = '<Esc>' . l:rhs_nvo
  else
    " No command
    " @TODO support non command mappings
    return ''
  endif

  " Compose result
  let l:mapping_nvo = l:remap . 'map '  . l:lhs . ' ' . l:rhs_nvo
  let l:mapping_ic  = l:remap . 'map! ' . l:lhs . ' ' . l:rhs_ic
  return l:mapping_nvo . '| ' . l:mapping_ic
endfunction

" @param {List} list
" @return {List} deduplicated list
function! dko#Unique(list) abort
  " stackoverflow style -- immutable, but unnecessary since we're operating on
  " a copy of the list in a:list anyway
  "return filter( copy(l:list), 'index(l:list, v:val, v:key + 1) == -1' )

  " xolox style -- mutable list
  return reverse(filter(reverse(a:list), 'count(a:list, v:val) == 1'))
endfunction

" @param {List} a:000 args
" @return {Mixed} first arg that is non-empty or empty string
function! dko#First(...) abort
  for l:item in a:000
    if !empty(l:item) | return l:item | endif
  endfor
  return ''
endfunction

" ============================================================================
" Buffer info
" ============================================================================

" @param {Int|String} bufnr or {expr} as in bufname()
" @return {Boolean}
function! dko#IsNonFile(bufnr) abort
  return getbufvar(a:bufnr, '&buftype') =~# '\v(nofile|quickfix|terminal)'
        \ || getbufvar(a:bufnr, '&filetype') =~# '\v(netrw)'
endfunction

" @param {Int} bufnr
" @return {Boolean}
function! dko#IsHelp(bufnr) abort
  return getbufvar(a:bufnr, '&buftype') =~# '\v(help)'
endfunction

" ============================================================================
" Whitespace settings
" ============================================================================

function! dko#TwoSpace() abort
  setlocal expandtab
  setlocal shiftwidth=2
  setlocal softtabstop=2
endfunction

function! dko#TwoTabs() abort
  setlocal noexpandtab
  setlocal shiftwidth=2
  setlocal softtabstop=2
endfunction

function! dko#FourTabs() abort
  setlocal noexpandtab
  setlocal shiftwidth=4
  setlocal softtabstop=4
endfunction

" ============================================================================
" grepprg
" ============================================================================

function! dko#GetGrepper() abort
  if exists('s:grepper') | return s:grepper | endif

  let s:greppers = {}
  let s:greppers.rg = {
        \   'command': 'rg',
        \   'options': [
        \     '--hidden',
        \     '--smart-case',
        \     '--no-heading',
        \     '--vimgrep',
        \   ],
        \   'format': '%f:%l:%c:%m,%f:%l:%m,%f:%l%m,%f %l%m',
        \ }
  let s:greppers.ag = {
        \   'command': 'ag',
        \   'options': [
        \     '--hidden',
        \     '--smart-case',
        \     '--vimgrep',
        \   ],
        \   'format': '%f:%l:%c:%m,%f:%l:%m,%f:%l%m,%f %l%m',
        \ }
  let s:greppers.ack = {
        \   'command': 'ack',
        \   'options': [
        \     '--nogroup',
        \     '--nocolor',
        \     '--smart-case',
        \     '--column',
        \   ],
        \   'format': '%f:%l:%c:%m,%f:%l:%m,%f:%l%m,%f %l%m',
        \ }

  let s:grepper_name =
        \   executable('rg') ? 'rg'
        \ : executable('ag') ? 'ag'
        \ : executable('ack') ? 'ack'
        \ : ''

  let s:grepper = empty(s:grepper_name) ? {} : s:greppers[s:grepper_name]

  return s:grepper
endfunction

" ============================================================================
" vim-plug helpers
" ============================================================================

" Memory cache
" List of loaded plug names
let s:loaded = []

" @param  {String} name
" @return {Boolean} true if the plugin is installed
function! dko#IsPlugged(name) abort
  return index(g:plugs_order, a:name) > -1
endfunction

" @param  {String} name
" @return {String} path where plugin installed
function! dko#PlugDir(name) abort
  return dko#IsPlugged(a:name) ? g:plugs[a:name].dir : ''
endfunction

" @param  {String} name
" @return {Boolean} true if the plugin is actually loaded
function! dko#IsLoaded(name) abort
  if index(s:loaded, a:name) > -1
    return 1
  endif

  let l:plug_dir = dko#PlugDir(a:name)
  if empty(l:plug_dir)  || !isdirectory(l:plug_dir)
    return 0
  endif

  let l:is_loaded = empty(l:plug_dir)
        \ ? 0
        \ : stridx(&runtimepath, l:plug_dir) > -1

  if l:is_loaded
    call add(s:loaded, a:name)
  endif

  return l:is_loaded
endfunction

" ============================================================================
" Filepath helpers
" ============================================================================

" @param {String[]} pathlist to shorten and validate
" @param {String} base to prepend to paths
" @return {String[]} filtered pathlist
function! dko#ShortPaths(pathlist, ...) abort
  let l:pathlist = a:pathlist

  " Prepend base path
  if isdirectory(get(a:, 1, ''))
    call map(l:pathlist, "a:1 . '/' . v:val")
  endif

  " Filter out non-existing files (e.g. when given deleted filenames from
  " `git diff -name-only`)
  call filter(l:pathlist, 'filereadable(expand(v:val))')

  " Shorten
  return map(l:pathlist, "fnamemodify(v:val, ':~:.')" )
endfunction

" ============================================================================
" Vim introspection
" ============================================================================

let s:mru_blacklist = "v:val !~ '" . join([
      \   'fugitive:',
      \   'NERD_tree',
      \   '^/tmp/',
      \   '.git/',
      \   '\[.*\]',
      \   'vim/runtime/doc',
      \ ], '\|') . "'"

" @return {List} recently used and still-existing files
function! dko#GetMru() abort
  " Shortened(Readable(Whitelist)
  return dko#ShortPaths(filter(copy(v:oldfiles), s:mru_blacklist))
endfunction

" @return {List} listed buffers
function! dko#GetBuffers() abort
  return map(
        \   filter(range(1, bufnr('$')), 'buflisted(v:val)'),
        \   'bufname(v:val)'
        \ )
endfunction
