" Check if user wants to use abbot.
if !get(g:, 'abbot_enabled', 1)
    finish
endif

" Check vim version.
if !(v:version > 800 || (v:version == 800 && has('patch1630')))
    echohl ErrorMsg | echo 'abbotsbury.vim: vim v8.0.1630 or newer is required. Aborting...' | echohl None
    finish
endif

augroup abbotsbury_ft
    autocmd FileType <buffer> call abbot#initialise()
augroup END
nnoremap <silent><buffer> <plug>AbbotExpandDoi :<C-U>call abbot#cite#expand_doi()<CR>
