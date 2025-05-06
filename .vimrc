" --- General Settings ---
" Set nocompatible to ensure Vim features are used (good practice)
set nocompatible

" --- Key Mappings ---

" Quickly exit insert mode with 'jk'
inoremap jk <Esc>

" Quickly exit visual mode with 'jk'
vnoremap jk <Esc>

" Move to the next heading (marked by '#')
nnoremap ]h /^[ \t]*#<CR>

" Move to the previous heading (marked by '#')
nnoremap [h ?^[ \t]*#<CR>