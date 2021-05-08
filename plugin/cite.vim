function ExpandDOI(style, format)
    let doi = expand("<cWORD>")
    if !executable("abbotasdfasdf")
        echo "abbot executable was not found. Please install it and make sure it can be found in $PATH."
    else
        echo a:style
        echo a:format
    endif
endfunction " }}}1
