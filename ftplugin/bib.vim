set omnifunc=abbot#complete
set completeopt+=menuone
augroup abbotsbury_complete
    autocmd CompleteDonePre <buffer> call abbot#post_complete(v:completed_item)
augroup END
