# 「 Vide - IDE-like configuration for VIM 」
#### NOTE: REALLY HACKY, PROBABLY WRONG, BUT WORKS FOR ME

##### Requirements:

- YouCompleteMe
- Ultisnips
- delimitMate
- vim-endwise

##### Current Setup:

- move between completion menu results using `g:vide_move_forwards`
  and `g:vide_move_backwards`
- confirm result by either continuing to type or `<CR>`
- if confirmed with `<CR>` and auto completion is a snippet it's expanded
  (note: functions defined as `some_func(arg1, arg2, ...)` are converted to
  snippets and therefore expanded as well)
- when inside snippet move with the same keys between placeholders or by
  completing a result with `<CR>`
- inside a snippet movement inside the completion menu is prioritized
  over the movement between the placeholders

##### Limitations:

- if semantic completion is triggered inside a snippets, placeholders are
  removed, apply [this patch](https://gist.github.com/cHoco/27549c8bc5119eda7d3b)
  to fix this (it may cause other issues to arise
  <https://github.com/SirVer/ultisnips/issues/586#issuecomment-148914335>)

##### Roadmap:

- make it more adaptable to different user configurations and mappings
- make it more configurable
- clean up and refactor code (learning vimscript might be a good start...)
