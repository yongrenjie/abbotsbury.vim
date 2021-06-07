" Generates fold text for folded bib references (the folding itself is handled
" using foldmethod=syntax; this just generates the 'short form' displayed on
" the fold line).
function! AbbotBibFoldText() abort
    let entry_type = ''      " e.g. article, book, thesis, ...
    let identifier = ''      " the bib identifier
    let title = ''           " title of the work
    " Parse the first line of the fold for the entry type and the identifier.
    let entry_type_identifier_match = matchlist(getline(v:foldstart),
                \ '\v\@(\S+)\s*\{\s*%((\S+)\s*,)?')
    if entry_type_identifier_match != []
        let entry_type = entry_type_identifier_match[1]
        let identifier = entry_type_identifier_match[2]
        " Check if the identifier is actually on the next line.
        if empty(identifier)
            let nextline_match = matchlist(getline(v:foldstart + 1),
                        \ '\v^\s*(\S+)\s*,')
            if !empty(nextline_match)
                let identifier = nextline_match[1]
        endif
    endif
    " Search inside the fold for the title of the work (or the entryset, if
    " it's a set)
    let title_regex = entry_type == 'set' ? 
                \ '\v^\s*entryset\s*\=\s*(\{.+\}|\".+\")\s*,?' :
                \ '\v^\s*title\s*\=\s*(\{.+\}|\".+\")\s*,?'
    let lnum = v:foldstart
    while lnum <= v:foldend
        let title_match = matchlist(getline(lnum), title_regex)
        if title_match != []
            " remove surrounding braces or quotes
            let title = title_match[1][1:-2]
            break
        else
            let lnum += 1
        endif
    endwhile
    " Construct the fold text
    if !empty(entry_type) && !empty(identifier) && !empty(title)
        return '+-- ' . entry_type . '{' . identifier . '} -- ' . title . ' '
    elseif !empty(entry_type) && !empty(identifier)
        return '+-- ' . entry_type . '{' . identifier . '} '
    else
        " information wasn't found. Just return the default fold text
        return foldtext()
    endif
endfunction

if g:abbot_bib_folding
    setlocal foldmethod=syntax
    setlocal foldtext=AbbotBibFoldText()
endif
