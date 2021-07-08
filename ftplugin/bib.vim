if g:abbot_bib_complete
    " Autocompletion requires v0.4.0.0 or later because of 'quiet' flag
    if !abbot#utils#check_version([0, 4, 0, 0])
        call abbot#utils#error('abbot v0.4.0.0 or later is required for bib autocompletion')
    else
        set omnifunc=abbot#complete#func
        set completeopt+=menuone
        augroup abbotsbury_complete
            autocmd CompleteDonePre <buffer> call abbot#complete#expand(v:completed_item)
        augroup END
    endif
endif
