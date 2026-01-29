alias vi=nvim
function tok() {
    if [[ -z "$1" ]]; then
        echo "Usage: tok <filename>"
        return 1
    fi
    local filename="${1}"
    uv run --with tiktoken python -c "import tiktoken; print(len(tiktoken.get_encoding('cl100k_base').encode(open('${filename}', encoding='utf-8', errors='ignore').read())))"
}
alias py="DYLD_LIBRARY_PATH=/Users/zev/repos/python-for-hacking/Python-3.13.5 /Users/zev/repos/python-for-hacking/Python-3.13.5/python.exe"

alias weave="codeweaver -ignore '.wrangler,summaries,screenshots,iam,__pycache__,.venv,.git,node_modules,.*cache,uv.lock,package-lock.json,venv,.*\.md,.*\.png,.*\.ico,.*\.txt,.*\.css',.*\.log"
alias soc="vi ~/socratic-prompt.txt"
alias cc="claude --dangerously-skip-permissions"
alias co="vi ~/CLAUDE.md"
alias d='cd ~/Downloads'
alias docs='cd ~/Documents'
alias bp='vi ~/.bash_profile'
alias bc='vi ~/.bash_claude'
alias bf='vi ~/.bash_funcs'
alias bff='vi ~/.bash_functions'
alias ss='source ~/.bash_profile'
alias bb='vi ~/.bashrc'
alias ba='vi ~/.bash_aliases'
alias bs='vi ~/.git_secret'
alias r='cd ~/repos && pwd'
alias vv='vi ~/.config/nvim/init.lua'
alias dx='deactivate'
alias ph='poetry shell'
alias ta='tmux a'
# alias vg='nvim -c "lua require(\"telescope.builtin\").live_grep()"'
# alias o='nvim -c ":Oil"'
alias claude-plan='ANTHROPIC_MODEL=claude-opus-4-20250514 claude'
alias gb='git branch'
alias gl='git log'
alias pp='vi ~/.profile'
alias pg='git pull origin $(git branch --show-current)'
alias gp='git push origin $(git branch --show-current)'
alias gs='git status'
alias gt='git stash'
alias tt='vi ~/.tmux.conf'
alias gd='git diff --diff-filter=ACMRTUXB'
alias gf='git fetch'
alias ga='git add --all'
alias l='ls -lrta'
alias i='ipython'
alias python3=python3.12
alias p3=python3
alias t='tree -a -I "*.pyc|*__pycache__|.git|.data|.venv|.pytest_cache|.ruff_cache|.mypy_cache|node_modules|env"'
alias pl='poetry shell'
alias act='source .venv/bin/activate'
alias lsd='ls -d */'
alias tm='tmux'
alias c='cal --three'

function y() {
    local audio_only=false
    local url=""
    local limit=""
    local output_template="~/Documents/video/%(channel)s/%(title)s.%(ext)s"
    local browser="chrome"  # Change this to your preferred browser
    
    # First, handle the flag if it's present at the beginning
    if [[ "$1" == "-a" || "$1" == "--audio-only" ]]; then
        audio_only=true
        shift
    fi
    
    # Now get the URL (should be the first remaining argument)
    url="$1"
    shift
    
    # Check if there's a limit argument (should be the next argument if present)
    if [[ "$1" =~ ^[0-9]+$ ]]; then
        limit="$1"
    fi
    
    # Check if URL was provided
    if [[ -z "$url" ]]; then
        echo "Error: No URL or file provided"
        echo "Usage: y [-a|--audio-only] URL|file.txt [number_of_videos]"
        return 1
    fi
    
    # Set audio options if audio_only is true
    local audio_opts=""
    if [[ "$audio_only" == true ]]; then
        audio_opts="-x --audio-format mp3"
        echo "Audio-only mode enabled (mp3 format)"
    fi
    
    # Set limit option if provided
    local limit_opt=""
    if [[ -n "$limit" ]]; then
        limit_opt="--playlist-end $limit"
        echo "Limiting to $limit videos"
    fi
    
    # Check if the input is a text file
    if [[ "$url" == *.txt && -f "$url" ]]; then
        echo "Processing URLs from file: $url"
        
        # Process each URL in the file
        while IFS= read -r line || [[ -n "$line" ]]; do
            # Skip empty lines and comments
            if [[ -z "$line" || "$line" == \#* ]]; then
                continue
            fi
            
            echo "Processing: $line"
            yt-dlp -o "$output_template" --no-overwrites --cookies-from-browser "$browser" $limit_opt $audio_opts "$line" --sleep-requests 3 --min-sleep-interval 2 --max-sleep-interval 210
        done < "$url"
    else
        # Regular URL processing
        yt-dlp -o "$output_template" --no-overwrites --cookies-from-browser "$browser" $limit_opt $audio_opts "$url" --sleep-requests 3 --min-sleep-interval 2 --max-sleep-interval 210
    fi
}

function a() {
    local url="$1"
    local output_template="~/Downloads/YouTube/%(channel)s/%(title)s.%(ext)s"
    local browser="firefox"  # Change this to your preferred browser: firefox, chrome, edge, etc.
    
    # Check if a second argument (number of videos) was provided
    if [[ $2 =~ ^[0-9]+$ ]]; then
        # Second argument is a number, download that many videos
        yt-dlp -x --audio-format m4a -o "$output_template" --no-overwrites --cookies-from-browser "$browser" --playlist-end "$2" "$url"
    else
        # No second argument or not a number, download all videos
        yt-dlp -x --audio-format m4a -o "$output_template" --no-overwrites --cookies-from-browser "$browser" "$url"
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

function poetry_activate() { source $(poetry env info --path)/bin/activate; }

function clip() {
    # Check if we have enough arguments
    if [ "$#" -lt 3 ]; then
        echo "Usage: clip <input_file> <start_time> <end_time> [output_file]"
        echo "Example: clip video.mp4 00:20:40 00:23:59 [output.mp4]"
        return 1
    fi

    input_file="$1"
    start_time="$2"
    end_time="$3"
    
    # Get file extension
    extension="${input_file##*.}"
    
    # Get base filename without extension
    base_filename="${input_file%.*}"
    
    # Set output filename or use default
    if [ "$#" -eq 4 ]; then
        output_file="$4"
    else
        output_file="${base_filename}_clip_${start_time//:/}_to_${end_time//:/}.${extension}"
    fi
    
    echo "Creating clip from $start_time to $end_time..."
    
    # Run ffmpeg command
    ffmpeg -i "$input_file" -ss "$start_time" -to "$end_time" -c copy "$output_file"
    
    # Check if the command was successful
    if [ $? -eq 0 ]; then
        echo "Clip created successfully: $output_file"
    else
        echo "Error creating clip"
    fi
}

hash_repo() {
    local ignore_patterns="${1:-codebase.md,__pycache__,.venv,.git,node_modules,.*cache,uv.lock,package-lock.json,venv}"
    find . -type f \
      -not -path './.git/*' \
      -not -path './__pycache__/*' \
      -not -path './.venv/*' \
      -not -path './venv/*' \
      -not -path './node_modules/*' \
      -not -name 'codebase.md' \
      -not -name '*.pyc' \
      -not -name 'uv.lock' \
      -not -name 'package-lock.json' \
      -print0 | sort -z | xargs -0 sha256sum | sha256sum | cut -d' ' -f1
}

hash_files() {
    # Create/update individual file hashes for change tracking
    # Usage: hash_files [check|update]
    local action="${1:-update}"
    local hash_dir=".file_hashes"
    local current_hashes="$hash_dir/current.txt"
    local previous_hashes="$hash_dir/previous.txt"
    
    mkdir -p "$hash_dir"
    
    if [[ "$action" == "check" ]]; then
        # Check which files have changed
        if [[ ! -f "$previous_hashes" ]]; then
            echo "No previous hashes found. All files will be processed."
            return 1
        fi
        
        # Generate current hashes
        find . -type f \
            -not -path './.git/*' \
            -not -path './__pycache__/*' \
            -not -path './.venv/*' \
            -not -path './venv/*' \
            -not -path './node_modules/*' \
            -not -path './.file_hashes/*' \
            -not -path './summaries/*' \
            -not -name 'codebase.md' \
            -not -name '*.pyc' \
            -not -name 'uv.lock' \
            -not -name 'package-lock.json' \
            -not -name '.DS_Store' \
            -print0 | sort -z | xargs -0 -I {} sh -c 'echo "$(sha256sum "{}" | cut -d" " -f1) {}"' > "$current_hashes"
        
        # Compare and output changed files
        comm -13 <(sort "$previous_hashes") <(sort "$current_hashes") | cut -d' ' -f2-
        
    elif [[ "$action" == "update" ]]; then
        # Update stored hashes
        [[ -f "$current_hashes" ]] && cp "$current_hashes" "$previous_hashes"
        
        find . -type f \
            -not -path './.git/*' \
            -not -path './__pycache__/*' \
            -not -path './.venv/*' \
            -not -path './venv/*' \
            -not -path './node_modules/*' \
            -not -path './.file_hashes/*' \
            -not -path './summaries/*' \
            -not -name 'codebase.md' \
            -not -name '*.pyc' \
            -not -name 'uv.lock' \
            -not -name 'package-lock.json' \
            -not -name '.DS_Store' \
            -print0 | sort -z | xargs -0 -I {} sh -c 'echo "$(sha256sum "{}" | cut -d" " -f1) {}"' > "$current_hashes"
        
        echo "File hashes updated in $hash_dir/"
    fi
}


# Simple redirect function for KV storage - works from anywhere
redir() {
    local src="$1"
    local target="$2"
    local worker_dir="/Users/zev/repos/redirector/redirect-worker"
    
    # Validate arguments
    if [[ $# -ne 2 ]]; then
        echo "Usage: redir <path> <target_url>"
        echo ""
        echo "Creates redirects for averba.ch using KV storage:"
        echo "  redir /sauna https://claude.ai/artifacts/..."
        echo "  redir /app https://myapp.com"
        echo "  redir /docs https://docs.example.com"
        echo ""
        echo "Results in:"
        echo "  averba.ch/sauna → https://claude.ai/artifacts/..."
        echo "  averba.ch/app → https://myapp.com"
        echo "  averba.ch/docs → https://docs.example.com"
        return 1
    fi
    
    # Ensure path starts with /
    if [[ ! "$src" =~ ^/ ]]; then
        src="/$src"
    fi
    
    # Check if worker directory exists
    if [[ ! -d "$worker_dir" ]]; then
        echo "Error: Worker directory not found at $worker_dir"
        return 1
    fi
    
    echo "🔄 Adding redirect: $src → $target"
    echo "📂 Using worker at: $worker_dir"
    
    # Change to worker directory and run wrangler
    (
        cd "$worker_dir" || exit 1
        
        # Try different KV command formats (syntax varies by wrangler version)
        if wrangler kv key put --binding=REDIRECTS_V2 --remote "$src" "$target" 2>/dev/null; then
            echo "✅ Redirect added successfully!"
        elif wrangler kv:key put --binding=REDIRECTS_V2 --remote "$src" "$target" 2>/dev/null; then
            echo "✅ Redirect added successfully!"
        else
            echo "❌ Failed to add redirect. Trying alternative syntax..."
            echo "Please try manually:"
            echo "  cd $worker_dir"
            echo "  wrangler kv key put --binding=REDIRECTS_V2 --remote \"$src\" \"$target\""
            exit 1
        fi
    )
    
    if [[ $? -eq 0 ]]; then
        echo "🔗 averba.ch$src → $target"
        echo ""
        echo "💡 To remove this redirect later:"
        echo "  redir_rm \"$src\""
    fi
}

# Function to list all redirects
redir_list() {
    local worker_dir="/Users/zev/repos/redirector/redirect-worker"
    
    if [[ ! -d "$worker_dir" ]]; then
        echo "Error: Worker directory not found at $worker_dir"
        return 1
    fi
    
    echo "📋 Current redirects:"
    
    (
        cd "$worker_dir" || exit 1
        
        if wrangler kv key list --binding=REDIRECTS 2>/dev/null; then
            echo "✅ Listed successfully"
        elif wrangler kv:key list --binding=REDIRECTS 2>/dev/null; then
            echo "✅ Listed successfully"
        else
            echo "❌ Failed to list redirects. Try manually:"
            echo "  cd $worker_dir && wrangler kv key list --binding=REDIRECTS"
        fi
    )
}

# Function to delete a redirect
redir_rm() {
    local src="$1"
    local worker_dir="/Users/zev/repos/redirector/redirect-worker"
    
    if [[ $# -ne 1 ]]; then
        echo "Usage: redir_rm <path>"
        echo "Example: redir_rm /sauna"
        return 1
    fi
    
    # Ensure path starts with /
    if [[ ! "$src" =~ ^/ ]]; then
        src="/$src"
    fi
    
    if [[ ! -d "$worker_dir" ]]; then
        echo "Error: Worker directory not found at $worker_dir"
        return 1
    fi
    
    echo "🗑️  Removing redirect: $src"
    
    (
        cd "$worker_dir" || exit 1
        
        if wrangler kv key put --binding=REDIRECTS --remote "$src" "$target" 2>/dev/null; then
            echo "✅ Redirect removed successfully!"
        elif wrangler kv:key delete --binding=REDIRECTS --remote "$src" 2>/dev/null; then
            echo "✅ Redirect removed successfully!"
        else
            echo "❌ Failed to remove redirect. Try manually:"
            echo "  cd $worker_dir && wrangler kv key delete --remote --binding=REDIRECTS \"$src\""
        fi
    )
}


function redir_ls() {
    cd /Users/zev/repos/redirector/redirect-worker || return 1
    
    echo "📋 Current redirects:"
    echo ""
    
    # Simple approach - just show the keys
    /usr/local/Cellar/node/24.4.1/bin/wrangler kv key list --binding=REDIRECTS_V2 --remote | jq -r '.[] | "   averba.ch" + .name + " → (use redir_show to see target)"'
    
    echo ""
    echo "💡 Use 'redir_show /path' to see where a specific redirect goes"
}

fix_mp4_keyframes() {
    if [ -z "$1" ]; then
        echo "Usage: fix_mp4_keyframes <input.mp4>"
        return 1
    fi
    
    local input="$1"
    
    if [ ! -f "$input" ]; then
        echo "Error: File '$input' not found"
        return 1
    fi
    
    local temp="${input}.temp.mp4"
    
    echo "Processing: $input"
    
    ffmpeg -i "$input" -c:v libx264 -crf 23 -g 30 -keyint_min 30 -c:a copy "$temp"
    
    if [ $? -eq 0 ]; then
        mv "$temp" "$input"
        echo "Success! Original file replaced with fixed version"
    else
        echo "Error: ffmpeg command failed"
        rm -f "$temp"
        return 1
    fi
}
