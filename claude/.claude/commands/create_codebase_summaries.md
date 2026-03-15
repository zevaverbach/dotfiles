# Documentation Generation Workflow
Execute ALL commands in exact order. Do NOT skip any steps:

## Command 1: Check Which Files Changed
```bash
# Handle case where previous run didn't complete
if [[ -f ".file_hashes/current.txt" && ! -f ".file_hashes/previous.txt" ]]; then
    echo "Previous run incomplete. Creating baseline from current.txt"
    cp .file_hashes/current.txt .file_hashes/previous.txt
fi

changed_files=$(hash_files check 2>/dev/null)
```

**CRITICAL LOGIC:**
- If `$changed_files` is empty: STOP immediately and return: "Documentation is up to date. No changes detected."
- If `$changed_files` contains files: Continue to Command 2 to process ONLY the changed files
- NEVER regenerate all documentation when no files have changed

## Command 2: Generate Documentation
```bash
codeweaver -ignore 'codebase.md,__pycache__,.venv,.git,node_modules,.*cache,uv.lock,package-lock.json,venv,.DS_Store,.*\.md'
```

## Command 3: Verify Output
```bash
ls -la codebase.md
```

## Command 4: Token Validation
```bash
tok codebase.md
```

If result exceeds 170,000:
- STOP and return this message to user: "codebase.md has {token_count} tokens, exceeding the 170,000 limit. Please specify which additional extensions or paths should be ignored in the codeweaver command, then re-run this command."
- Do NOT continue processing until user provides guidance

## Command 5: Process Documentation
If codebase.md exceeds 25,000 tokens, process it in chunks:

1. **Read Structure First:**
   ```bash
   head -100 codebase.md > structure_preview.md
   ```
   Read structure_preview.md to get directory/file listing

2. **Process Code in Sections:**
   Use offset/limit parameters to read codebase.md in chunks of ~20,000 tokens each.
   For each chunk, document all complete function/class definitions found.
   If a definition appears to be cut off at the end of a chunk, note it and pick it up in the next chunk.
   
   Process sequence:
   - Read(codebase.md, offset=0, limit=20000) → Document complete definitions
   - Read(codebase.md, offset=18000, limit=20000) → Use overlap to catch split definitions
   - Continue with overlapping chunks until end of file

3. **Create Documentation Files:**

**A) Create/update codebase_overview.md containing:**
- High-level project description
- Directory structure overview
- Main modules and their purposes
- Key architectural patterns
- Entry points and main workflows
(Keep this concise and high-level - aim for 1-2 pages max)

**B) Selectively update individual module summary files:**

**Focus on Changed Files Only:**
- Use the `$changed_files` variable from Command 1 to identify which files need summary updates
- For each changed file, create/update corresponding `summaries/[path]/[filename]_summary.md`
- Skip files that haven't changed (major token savings!)

Create `summaries/` directory structure mirroring the project, with individual `[filename]_summary.md` files:
```
summaries/
  kindchess/
    api_summary.md
    api_ws_summary.md
    db_summary.md
    ztypes_summary.md
    static/
      game_js_summary.md
      store_js_summary.md
      boardOps_js_summary.md
  tests/
    test_auth_summary.md
    test_utils_summary.md
```

**IMPORTANT CONSTRAINTS:**
- Each summary file must be under 5,000 tokens (check with `tok` command after creation)
- If a single module would exceed 5,000 tokens, split it into multiple files by logical sections
- Include ALL file types (Python, JavaScript, CSS, HTML, etc.) - not just Python files
- Create summaries for static assets like JS/CSS files showing their main functions and purposes
- **Only process files listed in `$changed_files` variable**

Each `[filename]_summary.md` file should contain:

**Code Documentation:**
For each function/class in the module, document with:
- Complete signature including all types
- Complete docstring verbatim
- All decorators and inheritance

**Format Example:**
```python
def login_user(user: User, pw: str, testing: bool) -> None: # raises InvalidUser
    """
    This is the main function for logging in a user. 
    TODO: write some unit tests
    Args:
      user:    this is a User object
      pw:      password in plaintext
      testing: are we in test mode?
    Returns: 
      None
    Raises: 
      InvalidUser
    """
```

**Restriction:** Use only codebase.md as source. Do not access repository directly. If file is too large, process in chunks using offset/limit parameters.

## Command 6: MANDATORY - Update File Hashes
```bash
hash_files update
```

**CRITICAL**: This step is REQUIRED and must ALWAYS be executed at the end. It saves the current file state so the next run will only process newly changed files. Failure to execute this step will cause the entire workflow to reprocess all files unnecessarily on the next run.
