" Author: w0rp <devw0rp@gmail.com>
" Description: Functions for working with paths in the filesystem.

" Given a buffer and a filename, find the nearest file by searching upwards
" through the paths relative to the given buffer.
function! ale#path#FindNearestFile(buffer, filename) abort
    let l:buffer_filename = fnamemodify(bufname(a:buffer), ':p')

    let l:relative_path = findfile(a:filename, l:buffer_filename . ';')

    if !empty(l:relative_path)
        return fnamemodify(l:relative_path, ':p')
    endif

    return ''
endfunction

" Given a buffer and a directory name, find the nearest directory by searching upwards
" through the paths relative to the given buffer.
function! ale#path#FindNearestDirectory(buffer, directory_name) abort
    let l:buffer_filename = fnamemodify(bufname(a:buffer), ':p')

    let l:relative_path = finddir(a:directory_name, l:buffer_filename . ';')

    if !empty(l:relative_path)
        return fnamemodify(l:relative_path, ':p')
    endif

    return ''
endfunction

" Given a buffer, a string to search for, an a global fallback for when
" the search fails, look for a file in parent paths, and if that fails,
" use the global fallback path instead.
function! ale#path#ResolveLocalPath(buffer, search_string, global_fallback) abort
    " Search for a locally installed file first.
    let l:path = ale#path#FindNearestFile(a:buffer, a:search_string)

    " If the serach fails, try the global executable instead.
    if empty(l:path)
        let l:path = a:global_fallback
    endif

    return l:path
endfunction

" Output 'cd <directory> && '
" This function can be used changing the directory for a linter command.
function! ale#path#CdString(directory) abort
    return 'cd ' . fnameescape(a:directory) . ' && '
endfunction

" Output 'cd <buffer_filename_directory> && '
" This function can be used changing the directory for a linter command.
function! ale#path#BufferCdString(buffer) abort
    return ale#path#CdString(fnamemodify(bufname(a:buffer), ':p:h'))
endfunction

" Return 1 if a path is an absolute path.
function! ale#path#IsAbsolute(filename) abort
    " Check for /foo and C:\foo, etc.
    return a:filename[:0] ==# '/' || a:filename[1:2] ==# ':\'
endfunction

" Given a directory and a filename, resolve the path, which may be relative
" or absolute, and get an absolute path to the file, following symlinks.
function! ale#path#GetAbsPath(directory, filename) abort
    " If the path is already absolute, then just resolve it.
    if ale#path#IsAbsolute(a:filename)
        return resolve(a:filename)
    endif

    " Get an absolute path to our containing directory.
    " If our directory is relative, then we'll use the CWD.
    let l:absolute_directory = ale#path#IsAbsolute(a:directory)
    \   ? a:directory
    \   : getcwd() . '/' . a:directory

    " Resolve the relative path to the file with the absolute path to our
    " directory.
    return resolve(l:absolute_directory . '/' . a:filename)
endfunction

" Given a buffer number and a relative or absolute path, return 1 if the
" two paths represent the same file on disk.
function! ale#path#IsBufferPath(buffer, filename) abort
    let l:buffer_filename = expand('#' . a:buffer)
    let l:buffer_absolute_filename = expand('#' . a:buffer . ':p')

    let l:buffer_directory = substitute(l:buffer_absolute_filename, l:buffer_filename . '$', '', '')
    let l:resolved_filename = ale#path#GetAbsPath(
    \   l:buffer_directory,
    \   a:filename
    \)

    return resolve(l:buffer_absolute_filename) ==# l:resolved_filename
endfunction
