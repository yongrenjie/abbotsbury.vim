function abbot#cite#expand_doi()
    " Check whether the abbot executable exists
    if !executable("abbot")
        call s:abbot_error('`abbot` executable was not found')
        return 1
    endif

    " Check for email.
    let email = ""
    " Get it from ABBOT_EMAIL environment variable first.
    if has_key(environ(), 'ABBOT_EMAIL')
        let email = getenv('ABBOT_EMAIL')
    else
        " Check for email via `git config`.
        if g:abbot_use_git_email
            silent let git_email = trim(system('git config --get user.email'))
            if v:shell_error || empty(git_email)
                call s:abbot_error("`couldn't get email via `git config`")
                return 1
            else
                let email = git_email
            endif
        " User didn't want to use git email, but also didn't set ABBOT_EMAIL.
        else
            call s:abbot_error('ABBOT_EMAIL environment variable was not defined')
            return 1
        endif
    endif
    " Temporarily set ABBOT_EMAIL to that.
    let old_abbot_email = getenv('ABBOT_EMAIL')
    call setenv('ABBOT_EMAIL', email)

    " Check that style is set
    if !exists('g:abbot_cite_style')
        call s:abbot_error('no citation style was defined')
        return 1
    endif

    " Grab the DOI
    let doi = expand('<cWORD>')
    " Very briefly validate it (we don't want to be too strict here, we just
    " want to catch really obviously wrong DOIs before hammering the Crossref
    " server)
    " https://www.crossref.org/blog/dois-and-matching-regular-expressions/
    if doi !~? '\v^10\.\d{4,9}/\S+$'
        call s:abbot_error('invalid DOI ' . doi)
        return 1
    else
        let doi = shellescape(doi)
    endif

    " Construct the command
    let command_components = ['abbot', 'cite', doi, '-s', trim(g:abbot_cite_style)]
    if !empty(trim(g:abbot_cite_format))
        call extend(command_components, ['-f', trim(g:abbot_cite_format)])
    endif
    let command = join(command_components)
    
    " Get the citation
    echo 'abbotsbury.vim: expanding DOI ' . doi . '...'
    silent let output = system(command)
    if v:shell_error
        " Strip ANSI escape sequences. The first part of the regex catches
        " escape sequences. The second part catches everything that isn't a
        " printable character or a newline.
        let sanitised_stderr = trim(substitute(output, '\e\[[0-9;]*m\|[^[:print:]\n]', '', 'g'))
        echohl ErrorMsg | echo sanitised_stderr | echohl None
        call setenv('ABBOT_EMAIL', old_abbot_email)
        return 1
    else
        put =output
        if g:abbot_replace_line
            norm kdd
        endif
        call setenv('ABBOT_EMAIL', old_abbot_email)
    endif
endfunction


" Pretty-print an error message.
function s:abbot_error(err_msg)
    echohl ErrorMsg | echo 'abbotsbury.vim: ' . a:err_msg | echohl None
endfunction
