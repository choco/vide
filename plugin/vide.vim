if exists('g:loaded_vide_plugin')
  finish
endif
let g:loaded_vide_plugin = 1
call vide#initialSetup()

if !exists('g:vide_confirm_selection')
  let g:vide_confirm_selection  = "<cr>"
endif
if !exists('g:vide_move_forwards')
  let g:vide_move_forwards  = "<tab>"
endif
if !exists('g:vide_move_backwards')
  let g:vide_move_backwards  = "<s-tab>"
endif
exec 'inoremap <Plug>VideMoveForwardsKey ' . g:vide_move_forwards
exec 'inoremap <Plug>VideMoveBackwardsKey ' . g:vide_move_backwards
if !exists('g:vide_jump_chars')
  let g:vide_jump_chars = [')', ']', '"', "'"]
endif

" Hack: don't pop completion pop-up after confirming result {{{
exec "inoremap <expr><silent> <Plug>VideDisablePopup vide#DisablePopup()"
exec "inoremap <expr><silent> <Plug>VideEnablePopup vide#EnablePopup()"
" }}}

" Mappings {{{

exec 'imap <silent> <expr> ' . vide_move_forwards . ' pumvisible() ? "\' . ycm_key_list_select_completion[0] . '" : "<C-R>=vide#JumpOrKey(1)<CR>"'
exec 'imap <silent> <expr> ' . vide_move_backwards . ' pumvisible() ? "\' . ycm_key_list_previous_completion[0] . '" : "<C-R>=vide#JumpOrKey(0)<CR>"'
exec 'snoremap <silent> ' . vide_move_forwards . ' <Esc>:call UltiSnips#JumpForwards()<cr>'
exec 'snoremap <silent> ' . vide_move_backwards . ' <Esc>:call UltiSnips#JumpBackwards()<cr>'
" }}}

autocmd CompleteDone * call vide#GenerateCompleteDoneSnippet()

call vide#finishSetup()
