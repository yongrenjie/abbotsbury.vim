function! AbbotBibFoldText() abort
    let l:lnum = v:foldstart
    let l:type = ''
    let l:title = ''
    while l:lnum <= v:foldend
        let l:type_match = matchlist(
                    \ getline(l:lnum),
                    \ '\v\@(\S+)\s*\{\s*(\S+),'
                    \ )
        if l:type_match != []
            let l:type = l:type_match[1] . '{' . l:type_match[2] . '}'
            break
        else
            let l:lnum += 1
        endif
    endwhile
    let l:lnum = v:foldstart
    while l:lnum <= v:foldend
        let l:title_match = matchlist(
                    \ getline(l:lnum),
                    \ '\v^\s*title\s*\=\s*(\{(.+)\}|\"(.+)\")\s*,'
                    \ )
        if l:title_match != []
            let l:title = l:title_match[2]
            break
        else
            let l:lnum += 1
        endif
    endwhile
    if strlen(l:type) > 0
        if strlen(l:title) > 0
            return '+-- ' . l:type . ' -- ' . l:title . ' '
        else
            return '+-- ' . l:type . ' '
        endif
    else
        " wasn't found. Just return the default fold text
        return foldtext()
    endif
endfunction

if g:abbot_bib_folding
    setlocal foldmethod=syntax
    setlocal foldtext=AbbotBibFoldText()
endif
