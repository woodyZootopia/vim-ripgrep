if exists('g:loaded_rg') || &cp
  finish
endif

let g:loaded_rg = 1

if !exists('g:rg_binary')
  let g:rg_binary = 'rg'
endif

if !exists('g:rg_format')
  let g:rg_format = "%f:%l:%c:%m"
endif

if !exists('g:rg_option')
  let g:rg_option = '--vimgrep'
endif

if !exists('g:rg_root')
  let g:rg_root = 'cwd'
endif

if !exists('g:rg_root_types')
  let g:rg_root_types = ['.git']
endif

if !exists('g:rg_window_location')
  let g:rg_window_location = 'botright'
endif

if !exists('g:rg_use_location_list')
  let g:rg_use_location_list = 0
endif

fun! g:RgVisual() range
  call s:RgGrepContext(function('s:RgSearch'), '"' . s:RgGetVisualSelection() . '"')
endfun

fun! s:Rg(txt)
  let l:selected_texts = s:RgGetVisualSelection()
  if l:selected_texts == []
    call s:RgGrepContext(function('s:RgSearch'), s:RgSearchTerm(a:txt))
  elseif len(l:selected_texts) > 1
    echo "Multiple line search is not supported yet."
  else
    call s:RgGrepContext(function('s:RgSearch'), s:RgSearchTerm(l:selected_texts[0]))
  endif
endfun

fun! s:LRg(txt)
  let l:rg_use_location_list_bak = g:rg_use_location_list
  let g:rg_use_location_list = 1
  call s:Rg(a:txt)
  let g:rg_use_location_list = l:rg_use_location_list_bak
endfun

fun! s:RgGetVisualSelection()
    " Why is this not a built-in Vim script function?!
    let [line_start, column_start] = getpos("'<")[1:2]
    let [line_end, column_end] = getpos("'>")[1:2]
    let lines = getline(line_start, line_end)
    if len(lines) == 0
        return []
    endif
    let lines[-1] = lines[-1][: column_end - (&selection == 'inclusive' ? 1 : 2)]
    let lines[0] = lines[0][column_start - 1:]
    return lines
endfun

fun! s:RgSearchTerm(txt)
  if empty(a:txt)
    return expand("<cword>")
  else
    return a:txt
  endif
endfun

fun! s:RgSearch(txt)
  let l:rgopts = ' '
  if &ignorecase == 1
    let l:rgopts = l:rgopts . '-i '
  endif
  if &smartcase == 1
    let l:rgopts = l:rgopts . '-S '
  endif
  if (g:rg_use_location_list==1)
    let l:rg_grep_cmd = 'lgrep! '
    let l:rg_window_cmd = 'lopen'
    let l:rg_window_close_cmd = 'lclose'
  else
    let l:rg_grep_cmd = 'grep! '
    let l:rg_window_cmd = 'copen'
    let l:rg_window_close_cmd = 'cclose'
  endif
  silent! exe l:rg_grep_cmd  . l:rgopts . a:txt
  if (g:rg_use_location_list ? len(getloclist(0)) : len(getqflist()))
    exe g:rg_window_location . ' ' . l:rg_window_cmd
    redraw!
    if exists('g:rg_highlight')
      call s:RgHighlight(a:txt)
    endif
  else
    exe l:rg_window_close_cmd
    redraw!
    echo "No match found for " . a:txt
  endif
endfun

fun! s:RgGrepContext(search, txt)
  let l:grepprg_bak = &grepprg
  let l:grepformat_bak = &grepformat
  let &grepprg = g:rg_binary . ' ' . g:rg_option
  let &grepformat = g:rg_format
  let l:te = &t_te
  let l:ti = &t_ti
  let l:shellpipe_bak=&shellpipe
  set t_te=
  set t_ti=
  if !has("win32")
      let &shellpipe="2>&1 | cat >"
  endif

  if exists('g:rg_derive_root')
    call s:RgPathContext(a:search, a:txt)
  else
  let l:cwd_bak = getcwd()
  exe 'lcd '.s:RgGetCwd()
  call a:search(a:txt)
  exe 'lcd '.l:cwd_bak
  endif

  let &shellpipe=l:shellpipe_bak
  let &t_te=l:te
  let &t_ti=l:ti
  let &grepprg = l:grepprg_bak
  let &grepformat = l:grepformat_bak
endfun

fun! s:RgPathContext(search, txt)
  let l:cwd_bak = getcwd()
  exe 'lcd '.s:RgRootDir()
  call a:search(a:txt)
  exe 'lcd '.l:cwd_bak
endfun

fun! s:RgHighlight(txt)
  let @/=escape(substitute(a:txt, '"', '', 'g'), '|')
  call feedkeys(":let &hlsearch=1\<CR>", 'n')
endfun

fun! s:RgRootDir()
  let l:cwd = s:RgGetCwd()
  let l:dirs = split(s:RgGetCwd(), '/')

  for l:dir in reverse(copy(l:dirs))
    for l:type in g:rg_root_types
      let l:path = s:RgMakePath(l:dirs, l:dir)
      if s:RgHasFile(l:path.'/'.l:type)
        return l:path
      endif
    endfor
  endfor
  return l:cwd
endfun

fun! s:RgMakePath(dirs, dir)
  return '/'.join(a:dirs[0:index(a:dirs, a:dir)], '/')
endfun

fun! s:RgHasFile(path)
  return filereadable(a:path) || isdirectory(a:path)
endfun

fun! s:RgShowRoot()
  if exists('g:rg_derive_root')
    echo s:RgRootDir()
  else
    echo getcwd()
  endif
endfun

fun! s:RgGetCwd() abort
  if g:rg_root == 'cwd'
    return getcwd()
  elseif g:rg_root == 'file'
    return expand("%:p:h")
  endif
endfun

command! -range -nargs=* -complete=file Rg :call s:Rg(<q-args>)
command! -range -nargs=* -complete=file LRg :call s:LRg(<q-args>)
command! -complete=file RgRoot :call s:RgShowRoot()
