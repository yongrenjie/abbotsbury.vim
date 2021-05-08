" Check if user wants to use abbot.
if !get(g:, 'abbot_enabled', 1)
    finish
endif

" Initialise default options.
function s:abbot_initialise_options()
    if !exists('g:abbot_cite_style')
        let g:abbot_cite_style = 'acs'
    endif
    if !exists('g:abbot_cite_format')
        let g:abbot_cite_format = 'text'
    endif
    if !exists('g:abbot_replace_line')
        let g:abbot_replace_line = v:true
    endif
    if !exists('g:abbot_use_git_email')
        let g:abbot_use_git_email = v:false
    endif
    if !exists('g:abbot_use_default_map')
        let g:abbot_use_default_map = v:true
    endif
endfunction

call s:abbot_initialise_options()
nnoremap <silent><buffer> <plug>AbbotExpandDoi :<C-U>call abbot#cite#expand_doi()<CR>
if g:abbot_use_default_map
    nmap <silent><buffer> <leader>ex <plug>AbbotExpandDoi
endif
