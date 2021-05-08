function abbot#cite#expand_doi() abort
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
    let [exit_code, stdout, stderr] = s:system_sync(command)
    if exit_code
        echohl ErrorMsg | echo stderr | echohl None
    else
        put =stdout
        if g:abbot_replace_line
            norm kdd
        endif
    endif
    call setenv('ABBOT_EMAIL', old_abbot_email)
    return exit_code
endfunction


" Runs a system command synchronously (blocking vim operation) and returns a
" list of three items: the exit code, the sanitised stdout, and the sanitised
" stderr. 'Sanitised' in this case refers to stripping all ANSI escape codes
" as well as unprintable characters.
" Note that, because separating stdout from stderr is extremely painful, this
" function assumes that stdout and stderr are mutually exclusive. That is, if
" the command runs successfully then it only prints to stdout; and if it fails
" then it only prints to stderr.
function s:system_sync(command) abort
    silent let output = system(a:command)
    let sanitised_output = trim(substitute(output, '\e\[[0-9;]*m\|[^[:print:]\n]', '', 'g'))
    if v:shell_error
        return [v:shell_error, "", sanitised_output]
    else
        return [v:shell_error, sanitised_output, ""]
    endif
endfunction


" Pretty-print an error message.
function s:abbot_error(err_msg) abort
    echohl ErrorMsg | echo 'abbotsbury.vim: ' . a:err_msg | echohl None
endfunction
