set autoindent expandtab tabstop=4 shiftwidth=4
set hidden
let g:python3_host_prog = '/usr/local/vitol/pyenv/versions/3.11.4/bin/python'


" When editing a file, always jump to the last known cursor position.
autocmd BufReadPost *
  \ if line("'\"") >= 1 && line("'\"") <= line("$") && &ft !~# 'commit'
  \ |   exe "normal! g`\""
  \ | endif

nnoremap <silent> <C-s> :w<cr>
nnoremap <C-l> :bn<cr>
nnoremap <C-h> :bp<cr>
inoremap <silent> <C-S> <esc>:w<cr>i
let mapleader=" "
nnoremap <leader>w :w<cr>:bw<cr>
nnoremap <silent> <leader>W :bw<cr>
nnoremap <leader>v :e ~/.config/nvim/init.lua<cr>
nnoremap <leader>m :e ~/.config/nvim/vimrc.vim<cr>
nnoremap <leader>s :source ~/.config/nvim/init.lua<cr>
nnoremap <leader>q :xa<cr>
nnoremap <leader>f <cmd>Telescope find_files<cr>
nnoremap <leader>g <cmd>Telescope live_grep<cr>
nnoremap <leader>b <cmd>Telescope buffers<cr>
nnoremap <leader>h <cmd>Telescope help_tags<cr>
nnoremap <leader>l <cmd>Lazy<cr>
nmap <silent> <leader>j <Plug>(coc-diagnostic-prev)
nmap <silent> <leader>d <Plug>(coc-diagnostic-next)
function! s:c_cycle(count) abort
    let qf_info = getqflist({ 'idx': 0, 'size': 0 })
    let size = qf_info->get('size')
    if size == 0
        return
    endif

    let idx = qf_info->get('idx')

    let num = (idx + size + a:count) % size

    if num == 0
        let num = size
    endif

    execute num .. 'cc'
endfunction
command! -nargs=1 CCycle call s:c_cycle(<q-args>)

nnoremap <expr> [n '<Cmd>CCycle -' .. v:count1 .. '<CR>'
nnoremap <expr> ]n '<Cmd>CCycle '  .. v:count1 .. '<CR>'

vnoremap <C-k> :m '<-2<CR>gv=gv
vnoremap <C-j> :m '>+1<CR>gv=gv
nnoremap <C-k> :m -2<CR>
nnoremap <C-j> :m +1<CR>
map gf :e<cfile><cr>

augroup tokyonight-night
  autocmd!
  autocmd ColorScheme * highlight Normal guibg=NONE ctermbg=NONE
  autocmd ColorScheme * highlight NonText guibg=NONE ctermbg=NONE
augroup END
colorscheme tokyonight-night
set background=dark

let g:LanguageClient_useVirtualText = 0 " disable inline errors

set undodir=~/.config/nvim/undodir
set undofile
set number relativenumber
