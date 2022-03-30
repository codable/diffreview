" Map quickfix movement
nmap [q :cprev<CR>
nmap ]q :cnext<CR>

let g:ReviewStarted = 0
let g:ReviewChangeList = []
let g:ReviewBaseFilename = ''

augroup AutoReview
  autocmd!
  autocmd BufEnter * call s:ReviewDiff()
augroup END

function! s:ReviewGdiff(timer)
  if !g:ReviewStarted
    return
  endif
  if g:ReviewBaseFilename == ''
    :execute 'Gvdiffsplit ' . g:ReviewRef
  else
    :execute 'Gvdiffsplit ' . g:ReviewRef . ':' . g:ReviewBaseFilename
  endif
endfunction

function! s:ReviewDiff()
  if !g:ReviewStarted
    return
  endif

  let l:filename = bufname('%')
  let l:bufnr = bufnr('%')
  let l:qflist = getqflist()
  let l:fullpath = getcwd() . '/' . l:filename
  let l:status = ''
  let l:oldname = ''

  let l:index = index(g:ReviewChangeList, getcwd() . '/' . l:filename)

  if l:index == -1
    return
  endif

  " Already reviewed
  if l:filename == g:ReviewFilename
    return
  end

  let g:ReviewFilename = l:filename

  if l:qflist[l:index].text =~ 'R\d\+'
    let l:parts = split(l:qflist[l:index].text, '|')
    let g:ReviewBaseFilename = l:parts[1]
  else
    let g:ReviewBaseFilename = ''
  endif

  " close window except the quickfix and current file
  for i in range(1, winnr('$'))
    if winbufnr(i) == l:bufnr
      continue
    endif

    let l:ibufname =  bufname(winbufnr(i))

    " skip quickfix window
    if l:ibufname == ''
      continue
    endif

    " skip minibuf window
    if l:ibufname == '-MiniBufExplorer-'
      continue
    endif

    " close this window
    :execute i . 'q'
  endfor
  let l:ReviewGdiff = function('s:ReviewGdiff')
  call timer_start(100, l:ReviewGdiff)
endfunction

function! s:CollectFiles(qflist, dir, ref)
  let l:output = system('git -C ' . a:dir . ' diff --name-status ' . a:ref)
  let l:root = system('git -C ' . a:dir . ' rev-parse --show-toplevel | tr -d \\r\\n')
  for item in split(l:output, '\n')
    " Match {status} {filename}
    let l:parts = matchlist(item, '\([ADMTUXB]\|C\d\+\|R\d\+\)\s\+\(.*\)')
    let l:status = l:parts[1]
    if l:status =~ 'R\d\+'
      let l:names = split(l:parts[2], '\t')
      let l:oldname = l:names[0]
      let l:newname = l:names[1]
      let l:fullpath = l:root . '/' . l:newname
      call add(a:qflist, {'filename': l:fullpath, 'pattern': '', 'text': l:parts[1] . '|' . l:oldname})
    else
      let l:filename = l:parts[2]
      let l:fullpath = l:root . '/' . l:filename
      call add(a:qflist, {'filename': l:fullpath, 'pattern': '', 'text': l:parts[1]})
    endif
    call add(g:ReviewChangeList, l:fullpath)
  endfor
endfunction

function! s:ReviewStart(ref)
  let g:ReviewChangeList = []
  let g:ReviewFilename = ''
  let l:qflist = []
  let l:dir = FugitiveWorkTree()
  call s:CollectFiles(l:qflist, l:dir, a:ref)

  call setqflist(l:qflist)
  :cw

  let g:ReviewRef = a:ref
  let g:ReviewStarted = 1
endfunction

function! s:ReviewStop()
  call setqflist([])
  let g:ReviewStarted = 0
  :ccl
endfunction

function! s:ReviewRepo(ref)
  let g:ReviewChangeList = []
  let g:ReviewFilename = ''
  let l:qflist = []

  let l:output = system('repo list -p')
  for project in split(l:output, '\n')
    call s:CollectFiles(l:qflist, project, a:ref)
  endfor

  call setqflist(l:qflist)
  :cw

  let g:ReviewRef = a:ref
  let g:ReviewStarted = 1
endfunction

command -nargs=? -complete=customlist,fugitive#EditComplete Greview :call s:ReviewStart("<args>")
command GreviewStop :call s:ReviewStop()
command -nargs=? GreviewRepo :call s:ReviewRepo("<args>")
