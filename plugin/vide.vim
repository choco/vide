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

" Hack: don't pop completion pop-up after confirming result {{{
augroup modify_ctrl_y_trigger_ycm
  autocmd!
  au BufEnter * exec "inoremap <expr><silent> <M-NP> vide#DisablePopup()"
  au BufEnter * exec "inoremap <expr><silent> <M-PN> vide#EnablePopup()"
augroup END
" }}}

" Mappings {{{
inoremap <silent><CR> <C-R>=vide#ExpandSnippetOrReturn()<CR>

exec 'inoremap <silent> <expr> ' . vide_move_forwards . ' pumvisible() ? "\' . ycm_key_list_select_completion[0] . '" : "<C-R>=vide#JumpOrKey(1)<CR>"'
exec 'inoremap <silent> <expr> ' . vide_move_backwards . ' pumvisible() ? "\' . ycm_key_list_previous_completion[0] . '" : "<C-R>=vide#JumpOrKey(0)<CR>"'
exec 'snoremap <silent> ' . vide_move_forwards . ' <Esc>:call UltiSnips#JumpForwards()<cr>'
exec 'snoremap <silent> ' . vide_move_backwards . ' <Esc>:call UltiSnips#JumpBackwards()<cr>'
" }}}

autocmd CompleteDone * call vide#GenerateCompleteDoneSnippet()

call vide#finishSetup()
