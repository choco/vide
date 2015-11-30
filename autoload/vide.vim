function vide#finishSetup()
  let s:available_on_the_fly_snippet = 0
  let s:temporary_on_the_fly_snippet = ""
  let s:completedone_available_snippet = 0
  let s:completedone_snippet = ""
  let s:invalidate_snippet_counter = 0

  exec 'let s:escaped_vide_move_forwards = "\'.g:vide_move_forwards.'"'
  exec 'let s:escaped_vide_move_backwards = "\'.g:vide_move_backwards.'"'
endfunction

function vide#DisablePopup()
  let g:ycm_auto_trigger = 0
  return ""
endfun

function vide#EnablePopup()
  let g:ycm_auto_trigger = 1
  return ""
endfun

" func JumpOrKey(direction) {{{
function vide#JumpOrKey(direction)
  if a:direction > 0
    let g:ulti_jump_forwards_res  = 0
    call UltiSnips#JumpForwards()
    if g:ulti_jump_forwards_res > 0
      return ''
    else
      let c_col = col('.')
      let n_char = getline('.')[c_col-1]
      for jump_c in g:vide_jump_chars
        if n_char == jump_c
          call cursor(0, c_col+1)
          return ""
        endif
      endfor
      return s:escaped_vide_move_forwards
    endif
  else
    let g:ulti_jump_backwards_res = 0
    call UltiSnips#JumpBackwards()
    if g:ulti_jump_backwards_res > 0
      return ''
    else
      let c_col = col('.')
      let n_char = getline('.')[c_col-2]
      for jump_c in g:vide_jump_chars
        if n_char == jump_c
          call cursor(0, c_col-1)
          return ""
        endif
      endfor
      return s:escaped_vide_move_backwards
    endif
  endif
endfunction
" }}}

function vide#ExpandSnippetOrReturn() " {{{
  if pumvisible()
    let g:ulti_expand_or_jump_res = 0
    let snippet = UltiSnips#ExpandSnippetOrJump()
    if g:ulti_expand_or_jump_res > 0
      return snippet
    else
      let s:available_on_the_fly_snippet = 0
      let s:temporary_on_the_fly_snippet = vide#GenerateSnippet(0)
      if len(s:temporary_on_the_fly_snippet)>1
        let s:available_on_the_fly_snippet = 1
      endif
      call feedkeys("\<M-NP>")
      call feedkeys("\<C-Y>")
      call feedkeys("\<M-PN>")
      if s:available_on_the_fly_snippet > 0
        call UltiSnips#Anon(s:temporary_on_the_fly_snippet)
        let s:available_on_the_fly_snippet = 0
        let s:completedone_available_snippet = 0
      endif
      return ""
    endif
  else
    if s:completedone_available_snippet > 0
      call UltiSnips#Anon(s:completedone_snippet)
      let s:completedone_available_snippet = 0
      let s:available_on_the_fly_snippet = 0
      return ""
    else
      call feedkeys("\<Plug>delimitMateCR"."\<Plug>DiscretionaryEnd")
      return ""
    endif
  endif
endfunction
" }}}

" create a snippet with Ultisnips for completed function names
" NOTE: only works with function declaration like some_fun(arg1, args2, ...)
"       and objc functions
function vide#GenerateClikeFuncSnippet(base, with_starting_bracket, with_ending_bracket) " {{{
  let base = a:base
  let startIdx = match(base, "(")
  let endIdx = match(base, ")")
  let ind_difference = endIdx - startIdx
  if ind_difference > 0
    let argsStr = strpart(base, startIdx+1, endIdx - startIdx - 1)
    let argsList = split(argsStr, ",")
    let snippet = ""
    if a:with_starting_bracket > 0
      let snippet = "("
    endif
    let c = 1
    for i in argsList
      if c > 1
        let snippet = snippet. ", "
      endif
      " strip space
      let arg = substitute(i, '^\s*\(.\{-}\)\s*$', '\1', '')
      let snippet = snippet . '${'.c.":".arg.'}'
      let c += 1
    endfor
    if a:with_ending_bracket > 0 && !(ind_difference == 1 && a:with_starting_bracket == 0)
      let snippet = snippet . ")$0"
    else
      let snippet = snippet . "$0" " TODO: find a way to jump over existing character
    endif
    return snippet
  else
    return ""
  endif
endfunction
" }}}

function vide#GenerateObjCSnippet() " {{{
  let abbr = v:completed_item.abbr
  let hasArguments = match(abbr, ":")
  if hasArguments > 0
    let argsList = split(abbr, ') \|)$')
    let snippet = ""
    let c = 1
    for i in argsList
      if c > 1
        let snippet = snippet . " "
      endif
      let arg = split(i, ':')
      let firstPart = arg[0] . ":"
      if c == 1
        let firstPart = ""
      endif
      let secondPart = arg[1] . ")"
      let snippet = snippet . firstPart . '${'.c.":".secondPart.'}'
      let c += 1
    endfor
    let snippet = snippet . "$0" " TODO: find a way to jump over existing character
    return snippet
  else
    return ""
  endif
endfunction
" }}}

function vide#GenerateSnippet(from_completeDone) "{{{
  if !exists('v:completed_item') || empty(v:completed_item)
    return ""
  endif

  let completed_type = v:completed_item.kind
  if completed_type != 'f' && &filetype != 'cs' && &filetype != 'python'
    return ""
  endif

  let complete_str = v:completed_item.word
  if complete_str == '' && &filetype != 'python'
    return ""
  endif

  if &filetype == 'objc'
    return vide#GenerateObjCSnippet()
  elseif &filetype == 'cs'
    return vide#GenerateClikeFuncSnippet(v:completed_item.menu, 0, 1)
  elseif &filetype == 'python'
    return vide#GenerateClikeFuncSnippet(v:completed_item.info, 1, 1)
  elseif &filetype == 'go'
    return vide#GenerateClikeFuncSnippet(v:completed_item.menu, 1, 1)
  else
    return a:from_completeDone ? vide#GenerateClikeFuncSnippet(v:completed_item.abbr, 0, 0) : vide#GenerateClikeFuncSnippet(v:completed_item.abbr, 1, 1)
  endif

endfunction
" }}}

" helper functions to invalidate compledone snippet {{{
function vide#InvalidateSnippet()
  let s:completedone_available_snippet = 0
  let s:invalidate_snippet_counter = 0
  try
    exec "augroup! invalidate_completedone_snippet"
  catch /^Vim\%((\a\+)\)\=:E367/
  endtry
endfunction
function vide#CheckInvalidateSnippet()
  if s:invalidate_snippet_counter > 0
    call vide#InvalidateSnippet()
  else
    let s:invalidate_snippet_counter = s:invalidate_snippet_counter + 1
  endif
endfunction
" }}}

function vide#GenerateCompleteDoneSnippet() " {{{
  let s:completedone_available_snippet = 0
  let s:completedone_snippet = vide#GenerateSnippet(1)
  if len(s:completedone_snippet) > 1
    let s:completedone_available_snippet = 1
    augroup invalidate_completedone_snippet
      autocmd!
      autocmd CursorMovedI * call vide#CheckInvalidateSnippet()
      autocmd InsertLeave * call vide#InvalidateSnippet()
    augroup END
  endif
endfunction
" }}}
