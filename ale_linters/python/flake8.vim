" Author: w0rp <devw0rp@gmail.com>
" Description: flake8 for python files

let g:ale_python_flake8_executable =
\   get(g:, 'ale_python_flake8_executable', 'flake8')

" Support an old setting as a fallback.
let s:default_options = get(g:, 'ale_python_flake8_args', '')
let g:ale_python_flake8_options =
\   get(g:, 'ale_python_flake8_options', s:default_options)
let g:ale_python_flake8_use_global = get(g:, 'ale_python_flake8_use_global', 0)

function! s:UsingModule(buffer) abort
    return ale#Var(a:buffer, 'python_flake8_options') =~# ' *-m flake8'
endfunction

function! ale_linters#python#flake8#GetExecutable(buffer) abort
    if !s:UsingModule(a:buffer)
        return ale#python#FindExecutable(a:buffer, 'python_flake8', ['flake8'])
    endif

    return ale#Var(a:buffer, 'python_flake8_executable')
endfunction

function! ale_linters#python#flake8#VersionCheck(buffer) abort
    let l:executable = ale_linters#python#flake8#GetExecutable(a:buffer)

    " If we have previously stored the version number in a cache, then
    " don't look it up again.
    if ale#semver#HasVersion(l:executable)
        " Returning an empty string skips this command.
        return ''
    endif

    let l:executable = ale#Escape(l:executable)
    let l:module_string = s:UsingModule(a:buffer) ? ' -m flake8' : ''

    return l:executable . l:module_string . ' --version'
endfunction

function! ale_linters#python#flake8#GetCommand(buffer, version_output) abort
    let l:executable = ale_linters#python#flake8#GetExecutable(a:buffer)
    let l:version = ale#semver#GetVersion(l:executable, a:version_output)

    " Only include the --stdin-display-name argument if we can parse the
    " flake8 version, and it is recent enough to support it.
    let l:display_name_args = ale#semver#GTE(l:version, [3, 0, 0])
    \   ? ' --stdin-display-name %s'
    \   : ''

    let l:options = ale#Var(a:buffer, 'python_flake8_options')

    return ale#Escape(l:executable)
    \   . (!empty(l:options) ? ' ' . l:options : '')
    \   . ' --format=default'
    \   . l:display_name_args . ' -'
endfunction

let s:end_col_pattern_map = {
\   'F405': '\(.\+\) may be undefined',
\   'F821': 'undefined name ''\([^'']\+\)''',
\   'F999': '^''\([^'']\+\)''',
\   'F841': 'local variable ''\([^'']\+\)''',
\}

function! ale_linters#python#flake8#Handle(buffer, lines) abort
    for l:line in a:lines[:10]
        if match(l:line, '^Traceback') >= 0
            return [{
            \   'lnum': 1,
            \   'text': 'An exception was thrown. See :ALEDetail',
            \   'detail': join(a:lines, "\n"),
            \}]
        endif
    endfor

    " Matches patterns line the following:
    "
    " Matches patterns line the following:
    "
    " stdin:6:6: E111 indentation is not a multiple of four
    let l:pattern = '\v^[a-zA-Z]?:?[^:]+:(\d+):?(\d+)?: ([[:alnum:]]+) (.*)$'
    let l:output = []

    for l:match in ale#util#GetMatches(a:lines, l:pattern)
        let l:code = l:match[3]

        if (l:code is# 'W291' || l:code is# 'W293')
        \ && !ale#Var(a:buffer, 'warn_about_trailing_whitespace')
            " Skip warnings for trailing whitespace if the option is off.
            continue
        endif

        let l:item = {
        \   'lnum': l:match[1] + 0,
        \   'col': l:match[2] + 0,
        \   'text': l:code . ': ' . l:match[4],
        \   'type': 'W',
        \}

        if l:code[:0] is# 'F' || l:code is# 'E999'
            let l:item.type = 'E'
        elseif l:code[:0] is# 'E'
            let l:item.type = 'E'
            let l:item.sub_type = 'style'
        elseif l:code[:0] is# 'W'
            let l:item.sub_type = 'style'
        endif

        let l:end_col_pattern = get(s:end_col_pattern_map, l:code, '')

        if !empty(l:end_col_pattern)
            let l:end_col_match = matchlist(l:match[4], l:end_col_pattern)

            if !empty(l:end_col_match)
                let l:item.end_col = l:item.col + len(l:end_col_match[1]) - 1
            endif
        endif

        call add(l:output, l:item)
    endfor

    return l:output
endfunction

call ale#linter#Define('python', {
\   'name': 'flake8',
\   'executable_callback': 'ale_linters#python#flake8#GetExecutable',
\   'command_chain': [
\       {'callback': 'ale_linters#python#flake8#VersionCheck'},
\       {'callback': 'ale_linters#python#flake8#GetCommand', 'output_stream': 'both'},
\   ],
\   'callback': 'ale_linters#python#flake8#Handle',
\})
