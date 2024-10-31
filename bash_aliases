alias vi=nvim
alias ss='source ~/.bashrc'
alias bb='vi ~/.bashrc'
alias ba='vi ~/.bash_aliases'
alias bs='vi ~/.git_secret'
alias r='cd ~/repos && pwd'
alias vv='vi ~/.config/nvim/init.lua'
alias dx='deactivate'
alias ph='poetry shell'
alias ta='tmux a'
alias gb='git branch'
alias gl='git log'
alias pp='vi ~/.profile'
alias pg='git pull origin $(git branch --show-current)'
alias gp='git push origin $(git branch --show-current)'
alias gs='git status'
alias gt='git stash'
alias tt='vi ~/.tmux.conf'
alias gd='git diff --diff-filter=ACMRTUXB'
alias gha='git rev-parse --short HEAD'
alias gf='git fetch'
alias ga='git add --all'
alias l='ls -lrta'
alias i='ipython'
alias python3=/usr/local/vitol/pyenv/versions/3.11.4/bin/python
alias p3=python3
alias t='tree -a -I "*.pyc|*__pycache__|.git|.data|.pytest_cache|.ruff_cache|.mypy_cache|node_modules|env"'
alias pl='poetry shell'
alias act='source env/bin/activate'
alias lsd='ls -d */'
alias tm='tmux'
alias c='cal --three'

n() {
    local latest_file
    latest_file=$(find . -type f \
        -not -path '*/\.*' \
        -not -path '*_cache/*' \
        -not -path '*/__pycache__/*' \
        -not -name '*.pyc' \
        -not -name 'pyproject.toml' \
        -not -name 'poetry.lock' \
        -printf '%T@ %p\n' | sort -n | tail -1 | cut -f2- -d" ")

    if [ -n "$latest_file" ]; then
        nvim "$latest_file"
    else
        echo "No files found."
    fi
}
function gc() {
    git commit -m "$1"
}

v() {
    local file
    file=$(find . -type f \
        -not -path "*/node_modules/*" \
        -not -path "*/__pycache__/*" \
        -not -path "*/venv/*" \
        -not -path "*/.venv/*" \
        -not -path "*/*cache/*" \
        -not -path "*/.git/*" \
        -not -path "*/.reports/*" \
        | fzf)
    if [[ -n $file ]]; then
        vi "$file"
    fi
}

function gh() {
    git checkout -b $1
}

vm() {
    # open the most recently modified file in the current directory
    
    local substring="$1"
    local modified_files
    local selected_files

    modified_files=$(git status --porcelain | grep '^.M' | awk '{print $2}')

    if [ -z "$substring" ]; then
        selected_files=$(echo "$modified_files" | fzf --multi --preview 'git diff --color=always {} | head -500')
    else
        matching_files=$(echo "$modified_files" | grep "$substring")
        count=$(echo "$matching_files" | wc -l)

        if [ "$count" -eq 1 ]; then
            selected_files="$matching_files"
        elif [ "$count" -gt 1 ]; then
            selected_files=$(echo "$matching_files" | fzf --multi --preview 'git diff --color=always {} | head -500')
        fi
    fi

    if [ -n "$selected_files" ]; then
        echo "$selected_files" | while read -r file; do
            diff_output=$(git diff -U0 "$file")
            first_change=$(echo "$diff_output" | grep -m1 '^@@')
            if [ -n "$first_change" ]; then
                line_info=$(echo "$first_change" | awk '{print $3}' | tr -d '+')
                line_number=$(echo "$line_info" | cut -d, -f1)
                change_type=$(echo "$diff_output" | grep -A1 "$first_change" | tail -n1 | cut -c1)
                if [ "$change_type" = "-" ]; then
                    line_number=$((line_number + 1))
                fi
                $EDITOR "+$line_number" "$file"
            else
                $EDITOR "$file"
            fi
        done
    else
        echo "No files selected."
    fi
}

delete_branches_except() {
    if [[ "$#" -eq 0 || "$1" != "--except" ]]; then
        echo "Error: You must supply at least one '--except' argument."
        return 1
    fi

    shift # Remove the '--except' argument

    if [[ "$#" -eq 0 ]]; then
        echo "Error: You must specify at least one branch to keep."
        return 1
    fi

    # Store branches to keep in an array
    local branches_to_keep=("$@")

    # Get all local branches
    local all_branches
    all_branches=$(git branch --format='%(refname:short)')

    # Loop through all branches and delete those not in the branches_to_keep array
    for branch in $all_branches; do
        if [[ ! " ${branches_to_keep[*]} " =~ " ${branch} " ]]; then
            echo "Deleting branch: $branch"
            git branch -D "$branch"
        else
            echo "Keeping branch: $branch"
        fi
    done
}
