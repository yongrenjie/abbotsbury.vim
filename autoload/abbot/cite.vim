function abbot#cite#expand_doi() abort  " {{{1
    " Expand a DOI in a file into a full citation.

    " Check minimum version of abbot required for this
    if !abbot#utils#check_version([0, 3, 1, 0])
        call abbot#utils#error('abbot v0.3.1.0 or higher is required for DOI expansion')
    endif

    " Check that style is set
    if !exists('b:abbot_cite_style')
        call abbot#utils#error('no citation style was defined; please set b:abbot_cite_style')
        return
    endif

    " Grab the DOI
    let doi = expand('<cWORD>')
    " Very briefly validate it (we don't want to be too strict here, we just
    " want to catch really obviously wrong DOIs before hammering the Crossref
    " server)
    " https://www.crossref.org/blog/dois-and-matching-regular-expressions/
    if doi !~? '\v^10\.\d{4,9}/\S+$'
        call abbot#utils#error('invalid DOI ' . doi)
        return
    else
        let escaped_doi = shellescape(doi)
    endif

    " Construct the command
    let command_components = ['abbot', 'cite', escaped_doi, '-s', trim(b:abbot_cite_style)]
    if !empty(trim(b:abbot_cite_format))
        call extend(command_components, ['-f', trim(b:abbot_cite_format)])
    endif
    if g:abbot_use_git_email
        call extend(command_components, ['--use-git-email'])
    endif
    let command = join(command_components)
    
    " Get the citation
    echo 'abbotsbury.vim: expanding DOI ' . doi . '...'
    let [exit_code, stdout, stderr] = abbot#utils#system_sync(command)
    if exit_code
        echohl ErrorMsg | echo stderr | echohl None
    else
        " Clear the echoed message.
        redraw!
        let stdout_lines = split(stdout, "\n")
        " Replace text as necessary.
        if b:abbot_replace_text == 'none'
            call append('.', stdout_lines)
        elseif b:abbot_replace_text == 'word'
            let old_line = getline('.')
            let x = match(old_line, '\m' . doi)
            let stdout_lines[0] = s:slice(old_line, 0, x) . stdout_lines[0]
            let stdout_lines[-1] = stdout_lines[-1] . s:slice(old_line, x + len(doi))
            call setline('.', stdout_lines[0])
            call append('.', stdout_lines[1:])
        elseif b:abbot_replace_text == 'line'
            call setline('.', stdout_lines[0])
            call append('.', stdout_lines[1:])
        elseif b:abbot_replace_text == 'linespace'
            if line('.') > 1 && !empty(trim(getline(line('.') - 1)))
                " Add a blank line before
                call insert(stdout_lines, "")
            endif
            if line('.') < line('$') && !empty(trim(getline(line('.') + 1)))
                " Add a blank line after
                call add(stdout_lines, "")
            endif
            call setline('.', stdout_lines[0])
            call append('.', stdout_lines[1:])
        endif
    endif
endfunction
" }}}1

function! s:slice(list, start, ...) abort "{{{1
    " Patched version of slice() as it doesn't exist in nvim.
    " Note: this is only guaranteed to work with lists or strings. I also
    " haven't tested this very much (but for our use case it should be good
    " enough).

    " Construct an empty member of the appropriate type
    function! s:mempty(in)
        if type(a:in) == 3  " list
            return []
        elseif type(a:in) == 1  " string
            return ""
        endif
    endfunction

    if has('nvim')
        if empty(a:0)
            return a:list[(a:start):]
        else
            if (a:1 == 0) || (a:start == a:1)
                " slice(x, 0, 0), slice(x, 1, 1), and slice(x, 1, 0) should all be empty
                return s:mempty(a:list)
            else
                " otherwise just subtract 1 from the end value
                return a:list[(a:start):(a:1 - 1)]
            endif
        endif
    else
        return empty(a:0) ? slice(a:list, a:start) : slice(a:list, a:start, a:1)
    endif
endfunction
" }}}1

" vim: foldmethod=marker
