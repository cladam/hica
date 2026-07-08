" Vim indent file for hica (.hc)
" Language:    hica
" Maintainer:  cladam

if exists("b:did_indent")
  finish
endif
let b:did_indent = 1

setlocal indentexpr=hicaIndent(v:lnum)
setlocal indentkeys=0{,0},0),0],!^F,o,O,e

function! hicaIndent(lnum) abort
  let prev_lnum = prevnonblank(a:lnum - 1)
  if prev_lnum == 0
    return 0
  endif

  let prev_line = getline(prev_lnum)
  let curr_line = getline(a:lnum)

  let indent = indent(prev_lnum)

  " Increase indent after opening braces/brackets
  if prev_line =~# '[{(\[]\s*$'
    let indent += &shiftwidth
  endif

  " Decrease indent for closing braces/brackets
  if curr_line =~# '^\s*[})\]]'
    let indent -= &shiftwidth
  endif

  " Don't go below zero
  return max([0, indent])
endfunction
