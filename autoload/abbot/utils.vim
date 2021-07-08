function abbot#utils#system_sync(command) abort " {{{1
    " Runs a system command synchronously (blocking vim operation) and returns
    " a list of three items: the exit code, the sanitised stdout, and the
    " sanitised stderr. 'Sanitised' in this case refers to stripping all ANSI
    " escape codes as well as unprintable characters. Note that, because
    " separating stdout from stderr is extremely painful, this function
    " assumes that stdout and stderr are mutually exclusive. That is, if the
    " command runs successfully then it only prints to stdout; and if it fails
    " then it only prints to stderr.
    silent let output = system(a:command)
    let sanitised_output = trim(substitute(output, '\e\[[0-9;]*m\|[^[:print:]\n]', '', 'g'))
    if v:shell_error
        return [v:shell_error, "", sanitised_output]
    else
        return [v:shell_error, sanitised_output, ""]
    endif
endfunction
" }}}1


function abbot#utils#error(err_msg) abort " {{{1
    " Pretty-print an error message. 
    echohl ErrorMsg | echo 'abbotsbury.vim: ' . a:err_msg | echohl None
endfunction
" }}}1


" Sentinel value to use whenever the executable isn't found.
let s:abbot_not_found = [0, 0, 0, 0]
" Cache the executable version so that we don't check it literally every time.
let s:abbot_version_is_cached = v:false
let s:abbot_version_cache_value = s:abbot_not_found
function abbot#utils#check_version(min_version) abort  " {{{1
    " Check whether abbot exists, and whether it has a version greater than or
    " equal to the minimum requested version. Returns 1 if it's sufficiently
    " up to date, 0 if not.
    let l:abbot_version = s:get_version()
    if l:abbot_version == [0, 0, 0, 0]
        call abbot#utils#error('`abbot` executable was not found')
        return 0
    elseif s:compare_version(l:abbot_version, a:min_version) < 0
        let l:version_string = join(a:min_version, '.')
        call abbot#utils#error('requires `abbot` version ' . l:version_string . ' or newer, please update')
        return 0
    endif
    return 1
endfunction
" }}}1
function s:get_version() abort " {{{1
    " Check whether the `abbot` executable exists, and get its version. If the
    " executable doesn't exist this returns [0, 0, 0, 0].
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
" }}}1
function s:compare_version(v1, v2) abort " {{{1
    " Check two version numbers. Returns +1 if v1 > v2, etc. (similar to
    " strcmp). This assumes that both versions passed (a:v1 and a:v2) are
    " lists of four numbers.
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
" }}}1

" vim: foldmethod=marker
