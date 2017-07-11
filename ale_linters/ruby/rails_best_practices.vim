" Author: Eddie Lebow https://github.com/elebow
" Description: rails_best_practices, a code metric tool for rails projects

let g:ale_ruby_rails_best_practices_options =
\   get(g:, 'ale_ruby_rails_best_practices_options', '')

function! ale_linters#ruby#rails_best_practices#Handle(buffer, lines) abort
    if len(a:lines) == 0
        return []
    endif

    let l:result = json_decode(join(a:lines, ''))

    let l:output = []

    for l:warning in l:result
        if !ale#path#IsBufferPath(a:buffer, l:warning.filename)
          continue
        endif

        call add(l:output, {
        \    'lnum': l:warning.line_number + 0,
        \    'type': 'W',
        \    'text': l:warning.message,
        \})
    endfor

    return l:output
endfunction

function! ale_linters#ruby#rails_best_practices#GetCommand(buffer) abort
    let l:rails_root = ale#ruby#FindRailsRoot(a:buffer)

    if l:rails_root ==? ''
        return ''
    endif

    return 'rails_best_practices --silent -f json --output-file /dev/stdout ' "TODO Windows?
    \    . ale#Var(a:buffer, 'ruby_rails_best_practices_options')
    \    . ale#Escape(l:rails_root)
endfunction

call ale#linter#Define('ruby', {
\    'name': 'rails_best_practices',
\    'executable': 'rails_best_practices',
\    'command_callback': 'ale_linters#ruby#rails_best_practices#GetCommand',
\    'callback': 'ale_linters#ruby#rails_best_practices#Handle',
\    'lint_file': 1,
\})
