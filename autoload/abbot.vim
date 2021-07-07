" Initialise default options. Note that this function relies on &filetype to
" be set, so cannot be triggered immediately upon plugin loading; instead, it
" can only fire after the filetype has been detected (autocmd FileType).
function abbot#initialise()
    if !exists('b:abbot_cite_style')
        if &filetype == 'bib'
            let b:abbot_cite_style = 'bib'
        else
            let b:abbot_cite_style = 'bib'
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
    if !exists('g:abbot_use_git_email')
        let g:abbot_use_git_email = v:false
    endif
    if !exists('g:abbot_use_default_map')
        let g:abbot_use_default_map = v:true
    endif

    if g:abbot_use_default_map
        nmap <silent><buffer> <leader>ex <plug>AbbotExpandDoi
    endif
endfunction
