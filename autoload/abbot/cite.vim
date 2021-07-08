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
            let stdout_lines[0] = slice(old_line, 0, x) . stdout_lines[0]
            let stdout_lines[-1] = stdout_lines[-1] . slice(old_line, x + len(doi))
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

" vim: foldmethod=marker
