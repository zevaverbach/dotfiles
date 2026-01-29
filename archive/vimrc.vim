let g:python3_host_prog = '/usr/local/vitol/pyenv/versions/3.11.4/bin/python'
let g:gitblame_enabled = 0


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
nnoremap <leader>w :call CloseBuffer()<CR>

function! CloseBuffer()
    let file_path = expand('%:p')
    let resolved_path = resolve(file_path)
    let project_dir = getcwd()
    let ignored_dirs = [
        \ 'node_modules',
        \ '.git',
        \ 'venv',
        \ 'vendor',
        \ 'dist',
        \ 'build',
        \ 'target',
        \ 'coverage'
    \ ]
    let positive_exceptions = [
        \ '.vimrc',
        \ 'init.vim',
        \ 'vimrc.vim',
        \ 'init.lua',
        \ '.tmux.conf',
        \ '.bashrc',
        \ '.bash_profile',
        \ '.gitconfig'
    \ ]

    let should_save = 1
    for dir in ignored_dirs
        if file_path =~# dir && index(positive_exceptions, expand('%:t')) == -1
            let should_save = 0
            break
        endif
    endfor

    if stridx(file_path, project_dir) != 0 && index(positive_exceptions, expand('%:t')) == -1
        let should_save = 0
    endif

    if resolved_path =~ '/dotfiles/' . expand('%:t') . '\$'
        let should_save = 1
    endif

    if should_save
        execute 'w'
        execute 'bw'
    else
        execute 'bw!'
    endif
endfunction
nnoremap <silent> <leader>W :bw<cr>
nnoremap <leader>v :e ~/.config/nvim/init.lua<cr>
nnoremap <leader>m :e ~/.config/nvim/vimrc.vim<cr>
nnoremap <leader>t :e ~/.tmux.conf<cr>
nnoremap <leader>s :source ~/.config/nvim/init.lua<cr>
nnoremap <leader>q :xa<cr>
nnoremap <leader>f <cmd>Telescope find_files<cr>
nnoremap <leader>g <cmd>Telescope live_grep<cr>
nnoremap <leader>h <cmd>Telescope lsp_definitions<cr>
nnoremap <leader>l <cmd>Lazy<cr>
nnoremap <leader>b <cmd>GitBlameToggle<cr>
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
autocmd FileType help nnoremap <buffer> <C-c> :q<CR>


augroup tokyonight-night
  autocmd!
  autocmd ColorScheme * highlight Normal guibg=NONE ctermbg=NONE
  autocmd ColorScheme * highlight NonText guibg=NONE ctermbg=NONE
augroup END
colorscheme tokyonight-night
set background=dark

set undodir=~/.config/nvim/undodir
set undofile
set number relativenumber
