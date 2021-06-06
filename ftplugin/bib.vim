" Generates fold text for folded bib references (the folding itself is handled
" using foldmethod=syntax; this just generates the 'short form' displayed on
" the fold line).
function! AbbotBibFoldText() abort
    let lnum = v:foldstart   " start of fold
    let identifier = ''      " e.g. article{Claridge2019MRC}
    let title = ''           " title of the work
    " Search inside the fold for the type of the work and the bib identifier
    while lnum <= v:foldend
        let identifier_match = matchlist(
                    \ getline(lnum),
                    \ '\v\@(\S+)\s*\{\s*(\S+),'
                    \ )
        if identifier_match != []
            let identifier = identifier_match[1] . '{' . identifier_match[2] . '}'
            break
        else
            let lnum += 1
        endif
    endwhile
    " Search inside the fold for the title of the work
    let lnum = v:foldstart
    while lnum <= v:foldend
        let title_match = matchlist(
                    \ getline(lnum),
                    \ '\v^\s*title\s*\=\s*(\{(.+)\}|\"(.+)\")\s*,'
                    \ )
        if title_match != []
            let title = title_match[2]
            break
        else
            let lnum += 1
        endif
    endwhile
    " Construct the fold text
    if strlen(identifier) > 0
        if strlen(title) > 0
            return '+-- ' . identifier . ' -- ' . title . ' '
        else
            return '+-- ' . identifier . ' '
        endif
    else
        " Wasn't found. Just return the default fold text
        return foldtext()
    endif
endfunction

if g:abbot_bib_folding
    setlocal foldmethod=syntax
    setlocal foldtext=AbbotBibFoldText()
endif
