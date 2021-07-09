function! abbot#initialise() abort  " {{{1
    " General settings, which are not filetype-dependent and can be set
    " immediately upon startup.
    if !exists('g:abbot_use_git_email')
        let g:abbot_use_git_email = v:false
    endif
    if !exists('g:abbot_use_default_map')
        let g:abbot_use_default_map = v:true
    endif
    if !exists('g:abbot_bib_complete')
        let g:abbot_bib_complete = v:false
    endif

    nnoremap <silent> <plug>AbbotExpandDoi :<C-U>call abbot#cite#expand_doi()<CR>
    if g:abbot_use_default_map
        nmap <silent><buffer> <leader>ex <plug>AbbotExpandDoi
    endif
endfunction
" }}}1

function! abbot#initialise_buffer() abort  " {{{1
    " Initialise buffer-specific options. Note that this function relies on
    " &filetype to be set, so cannot be triggered immediately upon plugin
    " loading; instead, it can only fire after the filetype has been detected
    " (autocmd FileType).
    if !exists('b:abbot_cite_style')
        if &filetype == 'bib'
            let b:abbot_cite_style = 'bib'
        else
            let b:abbot_cite_style = 'acs'
        endif
    endif
    if !exists('b:abbot_cite_format')
        if &filetype == 'markdown' || &filetype == 'rst' || &filetype == 'html'
            let b:abbot_cite_format = &filetype
        else
            let b:abbot_cite_format = 'text'
        endif
    endif
    if !exists('b:abbot_replace_text')
        let b:abbot_replace_text = 'word'
    endif
endfunction
" }}}1

" vim: foldmethod=marker
