let s:var_patterns = {
      \   'javascript': {
      \     'template': 'var %s = %s;',
      \     'regex': '\v^\s*var\s*(%s)\s*\=\s*(.*);$'
      \   },
      \   'ruby': {
      \     'template': '%s = %s',
      \     'regex': '\v^\s*(%s)\s*\=\s*(.*)$'
      \   },
      \   'vim': {
      \     'template': 'let %s = %s',
      \     'regex': '\v^\s*let\s([gswtblav]*:*%s)\s*\=\s*(.*)$'
      \   },
      \ }

function! s:PrintError(msg)
  let prefix = '[vim-exctract-line]'
  echohl ErrorMsg | echon prefix.' '.a:msg | echohl None
endfunction

function! s:ExecuteKeepingCursorPosition(command)
  let l:saved_search_pattern = @/
  let l:saved_line = line('.')
  let l:saved_column = col('.')

  execute a:command

  let @/ = l:saved_search_pattern
  call cursor(l:saved_line, l:saved_column)
endfunction

function! s:GetVarTemplate(var_name, var_value)
  let l:var_pattern = get(s:var_patterns, &ft)
  let l:var_template = l:var_pattern['template']
  return printf(l:var_template, a:var_name, a:var_value)
endfunction

function! s:GetVarPattern(var_name)
  let l:var_pattern = get(s:var_patterns, &ft)
  let l:var_template = l:var_pattern['regex']
  return printf(l:var_template, a:var_name)
endfunction

function! ExtractLocalVariable()
  let l:temp = @s
  silent normal! gv"sy

  let @s = substitute(@s, '\n$', '', 'g')
  if @s =~ '\n'
    call s:PrintError('Line breaks not supported')
    return
  endif

  let l:var_value = substitute(@s, '\([][/]\)', '\\\1', 'g')
  let @s = l:temp

  let l:var_name = input('Variable name: ')

  if len(l:var_name)
    execute 'normal! O' . s:GetVarTemplate(l:var_name, l:var_value)
    call <SID>ExecuteKeepingCursorPosition('.+1,$s/' . l:var_value . '/' . l:var_name . '/gc')
  endif
endfunction

function! InlineLocalVariable()
  let l:var_name = expand('<cword>')
  let l:regexd_pattern = s:GetVarPattern(l:var_name)

  if search(regexd_pattern) > 0
    let l:result = matchlist(getline('.'), l:regexd_pattern)
    let l:var_name = l:result[1]
    let l:var_value = substitute(l:result[2], '\(&:\)', '\\\1', 'g')

    call <SID>ExecuteKeepingCursorPosition('.+1,$s/\C\<' . l:var_name . '\>/' . l:var_value . '/gc')
    execute 'normal! dd'
  else
    echohl ErrorMsg | echo 'Unable to find where variable "'.l:var_name.'" was declared.' | echohl None
  endif
endfunction

vnoremap <Plug>(extract-local-variable)   :call ExtractLocalVariable()<CR>
nnoremap <Plug>(inline-local-variable)    :call InlineLocalVariable()<CR>

if get(g:, 'extract_inline#disable_default_mappings')
  finish
endif

vmap <Leader>e   <Plug>(extract-local-variable)
nmap <Leader>i   <Plug>(inline-local-variable)
