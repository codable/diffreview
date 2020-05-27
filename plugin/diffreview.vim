" Map quickfix movement
nmap [q :cprev<CR>
nmap ]q :cnext<CR>

let g:ReviewStarted = 0
let g:ReviewChangeList = []

augroup AutoReview
  autocmd!
  autocmd BufEnter * call s:ReviewDiff()
augroup END

function! s:ReviewGdiff(timer)
  :execute 'Gdiff ' . g:ReviewRef
endfunction

function! s:ReviewDiff()
  let l:filename = bufname('%')
  let l:bufnr = bufnr('%')
  if index(g:ReviewChangeList, getcwd() . '/' . l:filename) == -1
    return
  end

  if l:filename == g:ReviewFilename
    return
  end

  let g:ReviewFilename = l:filename

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

function! s:ReviewStart(ref)
  let l:qflist = []
  let g:ReviewChangeList = []
  let g:ReviewFilename = ''
  let l:output = system('git diff --name-status ' . a:ref)
  let l:root = system('git rev-parse --show-toplevel | tr -d \\r\\n')
  for item in split(l:output, '\n')
    " Match {status} {filename}
    let l:parts = matchlist(item, '\([ADMTUXB]\|C\d\+\|R\d\+\)\s\+\(.*\)')
    let l:filename = l:parts[2]
    call add(l:qflist, {'filename': l:root . '/' . l:filename, 'pattern': '', 'text': l:parts[1]})
    call add(g:ReviewChangeList, l:root . '/' . l:filename)
  endfor
  call setqflist(l:qflist)
  :cw
  let g:ReviewRef = a:ref
  let g:ReviewStarted = 1
endfunction

function! s:ReviewStop(ref)
  call setqflist([])
  let g:ReviewStarted = false
endfunction

command -nargs=? -complete=customlist,fugitive#EditComplete Greview :call s:ReviewStart("<args>")
