" Initialise default options. Note that this function relies on &filetype to
" be set, so cannot be triggered immediately upon plugin loading; instead, it
" can only fire after the filetype has been detected (autocmd FileType).
function! abbot#initialise() abort
    if !exists('b:abbot_cite_style')
        if &filetype == 'bib'
            let b:abbot_cite_style = 'bib'
        else
            let b:abbot_cite_style = 'acs'
        endif
    endif
    if !exists('b:abbot_cite_format')
        if &filetype == 'markdown' || &filetype == 'rst' || &filetype == 'html'
            let b:abbot_cite_format = &filetype
        else
            let b:abbot_cite_format = 'text'
        endif
    endif
    if !exists('b:abbot_replace_text')
        let b:abbot_replace_text = 'word'
    endif
    if !exists('g:abbot_use_git_email')
        let g:abbot_use_git_email = v:false
    endif
    if !exists('g:abbot_use_default_map')
        let g:abbot_use_default_map = v:true
    endif

    if g:abbot_use_default_map
        nmap <silent><buffer> <leader>ex <plug>AbbotExpandDoi
    endif
endfunction


function! abbot#complete(findstart, base) abort
    if a:findstart
        if empty(trim(getline('.')))
            return col('.')
        else
            return -3
        endif
    else
        let l:location = abbot#parse#parse_modeline()
        if empty(l:location) | return [] | endif

        let l:entries = abbot#parse#parse_entries(l:location)
        call filter(l:entries, 's:base_is_in_entry(a:base, v:val)')
        echomsg l:entries
        return map(l:entries, function('s:abbreviate_entries'))
    endif
endfunction


function! abbot#post_complete(completed_item)
    " Deletes the line and replaces it with abbot's citation.
    if empty(v:completed_item) || !has_key(v:completed_item, 'word')
        return
    endif
    let l:match = matchlist(v:completed_item['word'], '\v^\[(\d+)\|')
    if empty(l:match) | return | endif

    let l:idx = l:match[1]
    let l:abbot_dir = fnamemodify(abbot#parse#parse_modeline(), ':h')
    let l:cmd = "echo 'cite " . l:idx . "' | abbot -q -d " . l:abbot_dir
    let l:output = abbot#utils#system_sync(l:cmd)[1]
    call append(line('.') - 1, split(l:output, '\n'))

    " Adjust cursor position to be after the closing brace, so that whatever
    " keystroke follows is what would 'naturally' happen as if the complete
    " citation was typed in.
    normal! dd
    if line('.') != line('$')
        normal! k
    endif
    startinsert!
endfunction!


function! s:base_is_in_entry(base, entry) abort
    return 1
endfunction


function! s:abbreviate_entries(idx, entry) abort
    let l:abbrev_work_type = a:entry['work_type'] == 'article' ? 'a'
                \ : a:entry['work_type'] == 'book' ? 'b'
                \ : ''

    return { 'word': printf('[%d|%s] %s%d%s', a:idx + 1, l:abbrev_work_type, a:entry['authors'][0], a:entry['year'], a:entry['journal']),
                \ 'menu': a:entry['title']
                \ }
endfunction
