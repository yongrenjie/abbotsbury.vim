if !get(g:, 'abbot_enabled', 1)
    finish
endif

if !executable('abbot')
    call abbot#utils#error('`abbot` executable was not found on PATH')
    finish
endif

if !(v:version > 802 || (v:version == 802 && has('patch2344')))
    call abbot#utils#error('vim v8.2.2344 or newer is required')
    finish
endif

call abbot#initialise()
augroup abbotsbury_ft
    autocmd FileType * call abbot#initialise_buffer()
augroup END
