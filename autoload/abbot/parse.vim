function! abbot#parse#modeline() abort  " {{{1
    " Checks the first and last lines of the buffer for a commented line
    " specifying where the abbot refs are. Returns the full path to the
    " abbot.yaml file.
    " The modeline is resolved WRT the directory that contains the bib file.
    let l:pattern = '^\s*%\s*abbotsbury.vim:'
    if getline(1) =~? l:pattern
        let l:location = trim(s:split_at_first_colon(getline(1)))
    elseif getline('$') =~? l:pattern
        let l:location = trim(s:split_at_first_colon(getline('$')))
    else
        let l:location = 'refs/abbot.yaml'
    endif

    " note that relative paths only work on Unix
    let l:is_absolute = l:location[0] == '~' || l:location[0] == '/'
    if !l:is_absolute && has('unix')
        " bib_dir might not be the same as cwd, so we can't use fnamemodify
        " directly on it
        let l:bib_dir = expand('%:p:h')
        let l:location = l:bib_dir . '/' . l:location
    endif
    let l:location = fnamemodify(l:location, ':p')

    if isdirectory(l:location)
        let l:location = l:location . '/abbot.yaml'
    endif

    return filereadable(l:location) ? simplify(l:location) : ''
endfunction
" }}}1


function! abbot#parse#entries(fname) abort  " {{{1
    return map(s:get_entries(a:fname), function('s:parse_one_entry'))
endfunction
" }}}1
function! s:get_entries(fname) abort  " {{{1
    try
        let l:contents = readfile(a:fname)
    catch /E484/
        call abbot#utils#error('cannot find file ' . a:fname . ' (E484)')
        return 1
    endtry

    let l:entries = []
    " Split contents up into sub-lists, one per entry
    while 1
        " Must search from second line, otherwise this will always be 0.
        let l:next_entry_start = match(l:contents, '^-', 1)
        if l:next_entry_start == -1
            " No more entries; add the last one then break
            call add(l:entries, l:contents)
            break
        endif

        let l:entry = remove(l:contents, 0, l:next_entry_start - 1)
        call add(l:entries, l:entry)
    endwhile

    return l:entries
endfunction
" }}}1
function! s:parse_one_entry(idx, entry) abort  " {{{1
    " Returns a dictionary with the following keys: work_type, title, journal,
    " authors (which is a list of non-null family names), and year.

    " First figure out workType, since that influences the rest of our choices
    let l:work_type = match(a:entry, 'tag: BookWork') != -1 ? 'book'
                \ : match(a:entry, 'tag: ArticleWork') != -1 ? 'article' : ''

    if empty(l:work_type)
        echohl ErrorMsg
        echo 'abbotsbury.vim: could not parse file ' . a:fname
        echohl None
        return
    endif
    
    let l:prefix = '_' . l:work_type

    let l:title_lnum = match(a:entry, l:prefix . 'Title:')
    let l:title = l:title_lnum == -1 ? ''
                \ : trim(s:split_at_first_colon(a:entry[l:title_lnum]))
    if !empty(l:title) && l:title[0] == "'" && l:title[-1:] != "'"
        while l:title[-1:] != "'"
            let l:nextline = trim(a:entry[l:title_lnum + 1])
            let l:title = trim(l:title . ' ' . l:nextline)
            let l:title_lnum += 1
        endwhile
        let l:title = l:title[1:-2]  " remove quotes
    endif

    if l:work_type == 'article'
        let l:journal_lnum = match(a:entry, l:prefix . 'JournalShort')
        let l:journal = l:journal_lnum == -1 ? ''
                    \ : trim(s:split_at_first_colon(a:entry[l:journal_lnum]))
        " Filter to retain only capital letters.
        let l:journal = list2str(filter(str2list(l:journal), 'v:val >= 65 && v:val <= 90'))
    else
        let l:journal = ''
    endif

    let l:year_lnum = match(a:entry, l:prefix . 'Year:')
    let l:year = l:year_lnum == -1 ? ''
                \ : trim(s:split_at_first_colon(a:entry[l:year_lnum]))

    let l:family_names = filter(a:entry, "v:val =~ '_family'")
    let l:family_names = map(l:family_names,
                \ {idx, val -> trim(s:split_at_first_colon(val))})
    let l:family_names = filter(l:family_names, "v:val !=# 'null'")
    " Note that filter() modifies in place so do not do anything after this to
    " the entry!

    return {'work_type': l:work_type,
                \ 'title': l:title,
                \ 'authors': l:family_names,
                \ 'journal': l:journal,
                \ 'year': l:year,
                \ }
endfunction
" }}}1


function! s:split_at_first_colon(text) abort " {{{1
    " Splits at colons, but only the first one.
    let l:colon = match(a:text, ':')
    return l:colon == -1 ? a:text : a:text[l:colon + 1:]
    endif
endfunction
" }}}1

" vim: foldmethod=marker
