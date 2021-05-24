" Sentinel value to use whenever the executable isn't found.
let s:abbot_not_found = [0, 0, 0, 0]

" Cache the executable version so that we don't check it literally every time.
let s:abbot_version_is_cached = v:false
let s:abbot_version_cache_value = s:abbot_not_found

" The main function.
function abbot#cite#expand_doi() abort
    " Check whether abbot exists, and whether it is sufficiently up-to-date.
    let abbot_version = s:get_abbot_version()
    if abbot_version == s:abbot_not_found
        call s:abbot_error('`abbot` executable was not found')
        return 1
    elseif s:compare_version(abbot_version, [0, 3, 1, 0]) < 0
        call s:abbot_error('requires `abbot` version 0.3.1.0 or newer, please update `abbot`')
        return 1
    endif

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
        let escaped_doi = shellescape(doi)
    endif

    " Construct the command
    let command_components = ['abbot', 'cite', escaped_doi, '-s', trim(g:abbot_cite_style)]
    if !empty(trim(g:abbot_cite_format))
        call extend(command_components, ['-f', trim(g:abbot_cite_format)])
    endif
    if g:abbot_use_git_email
        call extend(command_components, ['--use-git-email'])
    endif
    let command = join(command_components)
    
    " Get the citation
    echo 'abbotsbury.vim: expanding DOI ' . doi . '...'
    let [exit_code, stdout, stderr] = s:system_sync(command)
    if exit_code
        echohl ErrorMsg | echo stderr | echohl None
    else
        " Clear the echoed message.
        redraw!
        let stdout_lines = split(stdout, "\n")
        " Replace text as necessary.
        if g:abbot_replace_text == 'none'
            call append('.', stdout_lines)
        elseif g:abbot_replace_text == 'word'
            let old_line = getline('.')
            let x = match(old_line, '\m' . doi)
            let stdout_lines[0] = slice(old_line, 0, x) . stdout_lines[0]
            let stdout_lines[-1] = stdout_lines[-1] . slice(old_line, x + len(doi))
            call setline('.', stdout_lines[0])
            call append('.', stdout_lines[1:])
        elseif g:abbot_replace_text == 'line'
            call setline('.', stdout_lines[0])
            call append('.', stdout_lines[1:])
        elseif g:abbot_replace_text == 'linespace'
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


" Check whether the `abbot` executable exists, and get its version. If the
" executable doesn't exist this returns [0, 0, 0, 0].
function s:get_abbot_version() abort
    if s:abbot_version_is_cached
        return s:abbot_version_cache_value
    else
        if !executable("abbot")
            let s:abbot_version_is_cached = v:true
            let s:abbot_version_cache_value = s:abbot_not_found
            return s:abbot_not_found
        endif
        silent let output = system('abbot --version')
        let abbot_version = split(split(trim(output))[2], '\.')
        call map(abbot_version, 'str2nr(v:val)')
        let s:abbot_version_is_cached = v:true
        let s:abbot_version_cache_value = abbot_version
        return abbot_version
    endif
endfunction


" Check two version numbers. Returns +1 if v1 > v2, etc. (similar to strcmp).
" This assumes that both versions passed (a:v1 and a:v2) are lists of four
" numbers.
function s:compare_version(v1, v2) abort
    if a:v1[0] > a:v2[0]
        return 1
    elseif a:v1[0] < a:v2[0]
        return -1
    else
        if a:v1[1] > a:v2[1]
            return 1
        elseif a:v1[1] < a:v2[1]
            return -1
        else
            if a:v1[2] > a:v2[2]
                return 1
            elseif a:v1[2] < a:v2[2]
                return -1
            else
                if a:v1[3] > a:v2[3]
                    return 1
                elseif a:v1[3] < a:v2[3]
                    return -1
                endif
            endif
        endif
    endif
    return 0
endfunction
