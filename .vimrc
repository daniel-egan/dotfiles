" --- General Settings ---
" Set nocompatible to ensure Vim features are used (good practice)
set nocompatible

" Reduce timeout for mapped key sequences to make mappings like 'jk' responsive.
" Default is 1000ms; a shorter timeout (e.g., 100ms) prevents lag.
set timeoutlen=200

" yank to system clipboard
set clipboard=unnamed

" Keep at least 15 lines above and below the current line
set scrolloff=15

" --- Key Mappings ---

" Quickly exit insert mode with 'jk'
inoremap jk <Esc>

" Quickly exit visual mode with 'jk'
vnoremap jk <Esc>

" Move to the next heading (marked by '#')
nnoremap ]h /^[ \t]*#<CR>

" Move to the previous heading (marked by '#')
nnoremap [h ?^[ \t]*#<CR>