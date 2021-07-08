" Runs a system command synchronously (blocking vim operation) and returns a
" list of three items: the exit code, the sanitised stdout, and the sanitised
" stderr. 'Sanitised' in this case refers to stripping all ANSI escape codes
" as well as unprintable characters.
" Note that, because separating stdout from stderr is extremely painful, this
" function assumes that stdout and stderr are mutually exclusive. That is, if
" the command runs successfully then it only prints to stdout; and if it fails
" then it only prints to stderr.
function abbot#utils#system_sync(command) abort
    silent let output = system(a:command)
    let sanitised_output = trim(substitute(output, '\e\[[0-9;]*m\|[^[:print:]\n]', '', 'g'))
    if v:shell_error
        return [v:shell_error, "", sanitised_output]
    else
        return [v:shell_error, sanitised_output, ""]
    endif
endfunction


" Pretty-print an error message.
function abbot#utils#error(err_msg) abort
    echohl ErrorMsg | echo 'abbotsbury.vim: ' . a:err_msg | echohl None
endfunction

