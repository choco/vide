let g:ycm_key_list_select_completion = ['<C-n>']
let g:ycm_key_list_previous_completion = ['<C-p>']
let g:UltiSnipsJumpForwardTrigger  = '\<Nop>'
let g:UltiSnipsJumpBackwardTrigger = '\<Nop>'
let g:UltiSnipsExpandTrigger       = '\<Nop>'
let g:UltiSnipsUsePythonVersion = 2

if !exists('g:vide_move_forwards')
  let g:vide_move_forwards  = "<tab>"
endif
if !exists('g:vide_move_backwards')
  let g:vide_move_backwards  = "<s-tab>"
endif
if !exists('g:vide_jump_chars')
  let g:vide_jump_chars = [')', ']', '"', "'"]
endif

let s:available_on_the_fly_snippet = 0
let s:temporary_on_the_fly_snippet = ""
let s:completedone_available_snippet = 0
let s:completedone_snippet = ""

" Escaped keys {{{
exec 'let s:escaped_vide_move_forwards = "\'.g:vide_move_forwards.'"'
exec 'let s:escaped_vide_move_backwards = "\'.g:vide_move_backwards.'"'
" }}}

" Hack: don't pop completion pop-up after confirming result {{{
augroup modify_ctrl_y_trigger_ycm
  autocmd!
  au BufEnter * exec "inoremap <expr><silent> <M-NP> vide#DisablePopup()"
  au BufEnter * exec "inoremap <expr><silent> <M-PN> vide#EnablePopup()"
augroup END
" }}}

" create a snippet with Ultisnips for completed function names
" NOTE: only works with function declaration like some_fun(arg1, args2, ...)
"       and objc functions
function s:GenerateClikeFuncSnippet(base, with_starting_bracket, with_ending_bracket) " {{{
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

function s:GenerateObjCSnippet() " {{{
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

function s:GenerateSnippet(from_completeDone) "{{{
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
    return s:GenerateObjCSnippet()
  elseif &filetype == 'cs'
    return s:GenerateClikeFuncSnippet(v:completed_item.menu, 0, 1)
  elseif &filetype == 'python'
    return s:GenerateClikeFuncSnippet(v:completed_item.info, 1, 1)
  elseif &filetype == 'go'
    return s:GenerateClikeFuncSnippet(v:completed_item.menu, 1, 1)
  else
    return a:from_completeDone ? s:GenerateClikeFuncSnippet(v:completed_item.abbr, 0, 0) : s:GenerateClikeFuncSnippet(v:completed_item.abbr, 1, 1)
  endif

endfunction
" }}}

" func ExpandSnippetOrJumpOrReturn() {{{
let g:ulti_expand_or_jump_res      = 0
function s:ExpandSnippetOrReturn()
  if pumvisible()
    let snippet = UltiSnips#ExpandSnippetOrJump()
    if g:ulti_expand_or_jump_res > 0
      return snippet
    else
      let s:available_on_the_fly_snippet = 0
      let s:temporary_on_the_fly_snippet = s:GenerateSnippet(0)
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

" func JumpOrKey(direction) {{{
let g:ulti_jump_forwards_res  = 0
let g:ulti_jump_backwards_res = 0
function s:JumpOrKey(direction)
  if a:direction > 0
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
      return s:escaped_ultisnips_ycm_move_forwards
    endif
  else
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
      return s:escaped_ultisnips_ycm_move_backwards
    endif
  endif
endfunction
" }}}

" helper functions to invalidate compledone snippet {{{
let s:invalidate_snippet_counter = 0
function s:InvalidateSnippet()
  let s:completedone_available_snippet = 0
  let s:invalidate_snippet_counter = 0
  try
    exec "augroup! invalidate_completedone_snippet"
  catch /^Vim\%((\a\+)\)\=:E367/
  endtry
endfunction
function s:CheckInvalidateSnippet()
  if s:invalidate_snippet_counter > 0
    call s:InvalidateSnippet()
  else
    let s:invalidate_snippet_counter = s:invalidate_snippet_counter + 1
  endif
endfunction
" }}}

" Mappings {{{
imap <silent><CR> <C-R>=<SID>ExpandSnippetOrReturn()<CR>

exec 'inoremap <silent> <expr> ' . vide_move_forwards . ' pumvisible() ? "\' . ycm_key_list_select_completion[0] . '" : "<C-R>=<SID>JumpOrKey(1)<CR>"'
exec 'inoremap <silent> <expr> ' . vide_move_backwards . ' pumvisible() ? "\' . ycm_key_list_previous_completion[0] . '" : "<C-R>=<SID>JumpOrKey(0)<CR>"'
exec 'snoremap <silent> ' . vide_move_forwards . ' <Esc>:call UltiSnips#JumpForwards()<cr>'
exec 'snoremap <silent> ' . vide_move_backwards . ' <Esc>:call UltiSnips#JumpBackwards()<cr>'
" }}}

function s:GenerateCompleteDoneSnippet() " {{{
  let s:completedone_available_snippet = 0
  let s:completedone_snippet = s:GenerateSnippet(1)
  if len(s:completedone_snippet) > 1
    let s:completedone_available_snippet = 1
    augroup invalidate_completedone_snippet
      autocmd!
      autocmd CursorMovedI * call s:CheckInvalidateSnippet()
      autocmd InsertLeave * call s:InvalidateSnippet()
    augroup END
  endif
endfunction
autocmd CompleteDone * call s:GenerateCompleteDoneSnippet()
" }}}

" }}}
