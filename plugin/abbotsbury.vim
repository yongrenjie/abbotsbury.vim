if !get(g:, 'abbot_enabled', 1)
    finish
endif

if !executable('abbot')
    call abbot#utils#error('`abbot` executable was not found on PATH')
    finish
endif

if !(v:version > 800 || (v:version == 800 && has('patch1630')))
    call abbot#utils#error('vim v8.0.1630 or newer is required')
    finish
endif

call abbot#initialise()
augroup abbotsbury_ft
    autocmd FileType * call abbot#initialise_ft()
augroup END
