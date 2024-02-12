set autoindent expandtab tabstop=4 shiftwidth=4
set hidden

" When editing a file, always jump to the last known cursor position.
autocmd BufReadPost *
  \ if line("'\"") >= 1 && line("'\"") <= line("$") && &ft !~# 'commit'
  \ |   exe "normal! g`\""
  \ | endif

nnoremap <silent> <C-s> :w<cr>
nnoremap <silent> <C-n> :noh<cr>
nnoremap <C-l> :bn<cr>
nnoremap <C-h> :bp<cr>
inoremap <silent> <C-S> <esc>:w<cr>i
let mapleader=" "
nnoremap <leader>w :w<cr>:bw<cr>
nnoremap <silent> <leader>W :bw<cr>
nnoremap <leader>v :e ~/.config/nvim/init.lua<cr>
nnoremap <leader>r :e ~/.config/nvim/vimrc.vim<cr>
nnoremap <leader>t :e ~/.tmux.conf<cr>
nnoremap <silent> <leader>x :Sex<cr>
nnoremap <leader>s :source ~/.config/nvim/init.lua<cr>
nnoremap <leader>q :xa<cr>
nnoremap <leader>f <cmd>Telescope find_files<cr>
nnoremap <leader>g <cmd>Telescope live_grep<cr>
nnoremap <leader>b <cmd>Telescope buffers<cr>
nnoremap <leader>h <cmd>Telescope help_tags<cr>
nmap <silent> <leader>j <Plug>(coc-diagnostic-prev)
nmap <silent> <leader>d <Plug>(coc-diagnostic-next)
inoremap <expr><Tab> CheckBackspace() ? "\<Tab>" : "\<C-n>"

vnoremap <C-k> :m '<-2<CR>gv=gv
vnoremap <C-j> :m '>+1<CR>gv=gv
nnoremap <C-k> :m -2<CR>
nnoremap <C-j> :m +1<CR>

function! CheckBackspace() abort
    let col = col('.') - 1
    return !col || getline('.')[col - 1]  =~# '\s'
endfunction

colorscheme tokyonight-night

let g:LanguageClient_useVirtualText = 0 " disable inline errors

set undodir=~/.config/nvim/undodir
set undofile
set number relativenumber
