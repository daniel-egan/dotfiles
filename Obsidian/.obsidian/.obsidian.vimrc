" --- General Settings ---
" Set nocompatible to ensure Vim features are used (good practice)
set nocompatible

" Reduce timeout for mapped key sequences to make mappings like 'jk' responsive.
" Default is 1000ms; a shorter timeout (e.g., 100ms) prevents lag.
set timeoutlen=200

" Yank to system clipboard
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


" --- Surround selected text ---
exmap surround_wiki surround [[ ]]
exmap surround_double_quotes surround " "
exmap surround_single_quotes surround ' '
exmap surround_backticks surround ` `
exmap surround_brackets surround ( )
exmap surround_square_brackets surround [ ]
exmap surround_curly_brackets surround { }

map [[ :surround_wiki<CR>
nunmap s
vunmap s
map s" :surround_double_quotes<CR>
map s' :surround_single_quotes<CR>
map s` :surround_backticks<CR>
map sb :surround_brackets<CR>
map s( :surround_brackets<CR>
map s) :surround_brackets<CR>
map s[ :surround_square_brackets<CR>
map s] :surround_square_brackets<CR>
map s{ :surround_curly_brackets<CR>
map s} :surround_curly_brackets<CR>
