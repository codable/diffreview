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
  if index(g:ReviewChangeList, l:filename) == -1
    return
  end

  if l:filename == g:ReviewFilename
    return
  end

  let g:ReviewFilename = l:filename

  for i in range(1, winnr('$'))
    " close window except the quickfix and current file
    if winbufnr(i) != l:bufnr && bufname(winbufnr(i)) != ''
      :execute i . 'q'
    endif
  endfor
  let l:ReviewGdiff = function('s:ReviewGdiff')
  call timer_start(100, l:ReviewGdiff)
endfunction

function! s:ReviewStart(ref)
  let l:qflist = []
  let g:ReviewChangeList = []
  let g:ReviewFilename = ''
  let l:output = system('git diff --name-status ' . a:ref)
  for item in split(l:output, '\n')
    " Match {status} {filename}
    let l:parts = matchlist(item, '\([ACDMRTUXB]\)\s\+\(.*\)')
    let l:filename = l:parts[2]
    call add(l:qflist, {'filename': l:filename, 'pattern': '', 'text': l:parts[1]})
    call add(g:ReviewChangeList, l:filename)
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

command -nargs=? Greview :call s:ReviewStart("<args>")