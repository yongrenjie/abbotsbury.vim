function! abbot#complete#func(findstart, base) abort  " {{{1
    " Function which generates entries for autocomplete. Note that this will
    " only work on lines that are blank.
    " See `:h complete-function` for details of how it works.
    if a:findstart
        if empty(trim(getline('.')))
            return col('.')
        else
            return -3
        endif
    else
        let l:location = abbot#parse#modeline()
        if empty(l:location) | return [] | endif

        let l:entries = abbot#parse#entries(l:location)
        call map(l:entries, function('s:convert_entry'))

        let l:lines = getline(1, line('$'))
        return filter(l:entries, 's:accept_complete(a:base, l:lines, v:val)')
    endif
endfunction
" }}}1
function! s:accept_complete(base, lines, entry) abort  " {{{1
    " This function returns 0 if the reference is already present in the bib
    " file (by performing fuzzy matching against every line in the file).
    return empty(matchfuzzy(a:lines, a:entry['menu']))
endfunction
" }}}1
function! s:convert_entry(idx, entry) abort  " {{{1
    " Converts the entries returned by abbot#parse#entries, into
    " something which the complete-function can accept (i.e. vim's
    " autocomplete interface).
    let l:abbrev_work_type = a:entry['work_type'] == 'article' ? 'a'
                \ : a:entry['work_type'] == 'book' ? 'b'
                \ : ''
    let l:word = printf('[%d|%s] %s%d%s',
                \ a:idx + 1,
                \ l:abbrev_work_type,
                \ a:entry['authors'][0],
                \ a:entry['year'],
                \ a:entry['journal'])
    return {'word': l:word, 'menu': a:entry['title']}
endfunction
" }}}1


function! abbot#complete#expand(completed_item)  " {{{1
    " Takes the autocompleted word and replaces it with abbot's citation.
    if empty(v:completed_item) || !has_key(v:completed_item, 'word')
        return
    endif
    let l:match = matchlist(v:completed_item['word'], '\v^\[(\d+)\|')
    if empty(l:match) | return | endif

    let l:idx = l:match[1]
    let l:abbot_dir = fnamemodify(abbot#parse#modeline(), ':h')
    let l:cmd = "echo 'cite " . l:idx . "' | abbot -q -d " . l:abbot_dir
    let l:output = abbot#utils#system_sync(l:cmd)[1]
    call append(line('.') - 1, split(l:output, '\n'))

    " Adjust cursor position to be after the closing brace, so that whatever
    " keystroke follows is what would 'naturally' happen as if the complete
    " citation was typed in.
    normal! dd
    if line('.') != line('$')
        normal! k
    endif
    startinsert!
endfunction
" }}}1


" vim: foldmethod=marker
