function! abbot#complete#func(findstart, base) abort  " {{{1
    " Function which generates entries for autocomplete. Note that this will
    " only work on lines that are blank.
    " See `:h complete-function` for details of how it works.
    if a:findstart
        return 0  " always start completion from the start of line
    else
        let l:location = abbot#parse#modeline()
        if empty(l:location) | return [] | endif

        let l:entries = abbot#parse#entries(l:location)
        call map(l:entries, function('s:convert_entry'))

        let l:lines = getline(1, line('$'))
        call filter(l:entries, 's:accept_complete(a:base, l:lines, v:val)')

        let l:keywords = split(a:base)
        return filter(l:entries, 's:keyword_matches(l:keywords, v:val)')
    endif
endfunction
" }}}1
function! s:accept_complete(base, lines, entry) abort  " {{{1
    " This function returns 0 if the reference is already present in the bib
    " file (by performing fuzzy matching against every line in the file).
    let l:match_score_threshold = 0
    
    " Remove non-alphabetical characters from the title (to avoid confusion
    " over LaTeX escaping preventing the match from happening)
    let l:title_only_alpha = a:entry['menu']
                \ ->split('\A')
                \ ->filter({idx, val -> !empty(val)})
                \ ->join(' ')
    let l:matches = matchfuzzypos(a:lines, l:title_only_alpha)
    return empty(l:matches) || max(l:matches[2]) <= l:match_score_threshold
endfunction
" }}}1
function! s:keyword_matches(keywords, entry) abort  " {{{1
    " Performs a case-insensitive search for a list of keywords in the
    " citation key of an entry. If all are found, returns true.
    if empty(a:keywords)
        return v:true
    endif

    " a:entry['word'] is of the form FirstAuthorYYYYJournalAbbrev.
    for l:keyword in a:keywords
        echomsg a:entry['word']
        if match(a:entry['word'], ('\c' . l:keyword)) == -1 
            return v:false
        endif
    endfor
    return v:true
endfunction
" }}}1
function! s:convert_entry(idx, entry) abort  " {{{1
    " Converts the entries returned by abbot#parse#entries, into
    " something which the complete-function can accept (i.e. vim's
    " autocomplete interface).
    let l:abbrev_work_type = a:entry['work_type'] == 'article' ? 'a'
                \ : a:entry['work_type'] == 'book' ? 'b'
                \ : ''
    let l:abbot_index = a:idx + 1
    let l:word = printf('[%d|%s] %s%d%s',
                \ l:abbot_index,
                \ l:abbrev_work_type,
                \ substitute(a:entry['authors'][0], '\s*', '', 'g'),
                \ a:entry['year'],
                \ a:entry['journal'])
    return {'word': l:word, 'menu': a:entry['title'], 'user_data': l:abbot_index}
endfunction
" }}}1


function! abbot#complete#expand(completed_item)  " {{{1
    " Takes the autocompleted word and replaces it with abbot's citation.
    if empty(v:completed_item) || !has_key(v:completed_item, 'word')
        return
    endif
    let l:abbot_index = v:completed_item['user_data']
    let l:abbot_dir = fnamemodify(abbot#parse#modeline(), ':h')
    let l:cmd = "echo 'cite " . l:abbot_index . "' | abbot -q -d " . l:abbot_dir
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
