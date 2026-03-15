# MSH Insurance Claims Submission

Automate medical insurance claims submission to MSH Services using Playwright browser automation.

## Read

~/.claude/msh-insurance/claims-submission-guide.md

## Instructions

**CRITICAL REQUIREMENTS - READ CAREFULLY:**

⚠️ **AUTOMATION MODE - NO USER INTERACTION ALLOWED** ⚠️

1. **NEVER PROMPT THE USER:** Do not ask questions, do not wait for input, do not output "Ready to proceed?" or similar
2. **NEVER PROVIDE MANUAL INSTRUCTIONS:** Do not say "Please follow these steps" or "Let me know when..."
3. **AUTOMATE EVERYTHING:** Use Playwright MCP browser tools to perform ALL actions automatically
4. **OUTPUT PROGRESS IMMEDIATELY:** Print status messages as you go (use print() or echo to force output)
5. **RUN TO COMPLETION:** Execute all steps from start to finish without stopping

**YOU ARE RUNNING IN BATCH MODE - PROCESS ALL INVOICES SEQUENTIALLY**

**Input:** No arguments needed - the command will automatically find and process ALL invoices in:
- `~/Downloads/bills/received, paid/` (both directories and PDF files)
- `~/Downloads/bills/received, unpaid/` (both directories and PDF files)

**Workflow - AUTOMATE ALL STEPS:**

**FIRST: Collect all invoices**
1. List all directories and PDF files in both received folders
2. Output: "Found X invoices to process"
3. For each invoice, process sequentially (one at a time)

**FOR EACH INVOICE:**

**FIRST ACTION:**
1. Check if Playwright MCP tools are available (browser_navigate, browser_click, etc.)
2. If NOT available: Output "ERROR: Playwright MCP tools not available" and EXIT WITH CODE 1
3. If available: Output "=== Starting MSH automation for: [invoice_path] ===" and continue

**CRITICAL:** If you don't have access to browser_navigate, browser_click, browser_type, browser_snapshot, and browser_file_upload tools, you MUST exit with error code 1. Do NOT exit with code 0. Do NOT offer alternatives.

1. **Parse invoice information** from the provided path:
   - If directory: Read invoice images, identify beneficiary, date, provider, amount
   - If PDF file: Read PDF content to extract invoice details
   - Determine payment status from parent folder name (paid/unpaid)
   - Output: "Parsed invoice: [beneficiary] - [amount] CHF - [date]"

2. **Prepare files:**
   - For directories: Use compressed images if available (*_compressed.jpeg), otherwise compress images >3MB
   - For PDFs: Use the PDF file directly (already under 20MB limit)
   - Output: "Files ready: [list of files]"

3. **Automate browser submission using Playwright MCP tools:**

   a. Navigate to MSH portal:
      - Use `browser_navigate` to https://www.msh-services.com/index_assure_previnter.php?lang=en
      - Output: "Browser opened"

   b. Dismiss cookie/GDPR overlay (IMPORTANT):
      - Use `browser_snapshot` to check for cookie banner
      - If present, use `browser_click` to accept cookies (look for "Accept", "Accepter", "OK" buttons)
      - Output: "Cookie banner dismissed" or "No cookie banner found"

   c. Login:
      - Load credentials from ~/.bash_secret (MSH_INTL_LOGIN, MSH_INTL_PASS)
      - Use `browser_type` to fill username field
      - Use `browser_type` to fill password field
      - Use `browser_click` to click login button
      - Output: "Logged in successfully"

   d. Navigate to claims form:
      - Use `browser_navigate` to https://www.msh-services.com/index.php?module=demandes&controller=claimform&action=etape2
      - Output: "On claims form"

   e. Select beneficiary:
      - Use `browser_snapshot` to see checkboxes
      - Use `browser_click` to select correct family member
      - Use `browser_click` to select "No" for Social Security
      - Use `browser_click` on "Next step" button
      - Output: "Selected beneficiary: [name]"

   f. Fill medical expense details:
      - Use `browser_type` to fill date field FIRST
      - Use `browser_click` to select description category
      - Use `browser_type` for country, amount, currency
      - Use `browser_click` for emergency/accident question
      - Use `browser_click` on "Add this medical expense"
      - Use `browser_click` on "Next step"
      - Output: "Medical details filled"

   g. Handle emergency details if needed (if emergency was selected):
      - Use `browser_click` to select nature
      - Use `browser_type` for date, place, circumstances
      - Use `browser_click` on "Next step"
      - Output: "Emergency details filled"

   h. Upload attachments:
      - Use `browser_click` to select "Yes" for electronic documents
      - Use `browser_file_upload` to upload files
      - Wait for upload completion
      - Use `browser_click` on "Confirm"
      - Output: "Files uploaded"

   i. Review and submit:
      - Use `browser_snapshot` to verify summary
      - Use `browser_click` to check certification checkbox
      - Use `browser_click` on "Submit" button
      - Output: "Claim submitted"

   j. Extract claim number:
      - Use `browser_snapshot` to read success page
      - Extract claim number from page
      - Output: "Claim number: [NUMBER]"

4. **After successful submission:**
   - Update ~/.claude/msh-insurance/claims-tracker.json with new claim entry
   - Move invoice (directory or file) to ~/Downloads/bills/submitted/
   - Output: "Invoice [invoice_id] completed successfully"
   - Continue to next invoice

5. **After ALL invoices are processed:**
   - Update claims-tracker.json metadata:
     - `total_claims` = count of all claims
     - `pending_claims` = count of claims where reimbursement.status is "pending"
     - `outstanding_amount` = sum of amounts for all pending claims
     - `last_updated` = current timestamp in ISO format
   - Commit and push all changes to git repository
   - Output summary: "Processed X invoices: Y successful, Z failed"
   - Exit with code 0 if all succeeded, code 1 if any failed

6. **Critical requirements:**
   - **AUTOMATION ONLY:** Use Playwright MCP browser automation tools. Never output manual instructions or ask user to do anything
   - **FULL AUTOMATION:** Complete the entire workflow from browser open to claim submission without any user interaction
   - **BATCH PROCESSING:** Process ALL invoices sequentially, continue even if individual invoices fail
   - **ERROR HANDLING:** If an invoice fails, log the error and continue to the next invoice
   - **PROGRESS OUTPUT:** Print progress messages as you go (e.g., "Browser opened", "Logged in", "Claim submitted")
   - MUST dismiss cookie/GDPR banner before logging in (only needed once per batch)
   - MUST check "Demandé par" field in images/PDF for "Urgences" (emergency)
   - MUST fill date field FIRST to load description categories
   - MUST extract and return claim number
   - MUST handle both directory-based and PDF file invoices
   - Exit with code 0 only if ALL invoices succeeded, code 1 if ANY failed

**WRONG APPROACH - DO NOT DO THIS:**
```
Ready to proceed? Once you've logged in...
Please follow these steps...
Let me know when you're done...
```

**CORRECT APPROACH - DO THIS:**
```
Found 13 invoices to process

=== Starting MSH automation for: /Users/zev/Downloads/bills/received, paid/14392 ===
Parsing invoice...
Parsed invoice: Zev AVERBACH - 459.20 CHF - 08/12/2025
Files ready: IMG_0983_compressed.jpeg
Opening browser...
Browser opened
Dismissing cookie banner...
Cookie banner dismissed
Logging in...
Logged in successfully
On claims form
Selected beneficiary: Zev AVERBACH
Medical details filled
Files uploaded
Claim submitted
Claim number: CFW1234567
Invoice 14392 completed successfully

=== Starting MSH automation for: /Users/zev/Downloads/bills/received, paid/12345 ===
Parsing invoice...
Parsed invoice: Simon Alexander AVERBACH - 125.00 CHF - 15/12/2025
Files ready: invoice.pdf
On claims form (already logged in)
Selected beneficiary: Simon Alexander AVERBACH
Medical details filled
Files uploaded
Claim submitted
Claim number: CFW1234568
Invoice 12345 completed successfully

... (processing remaining invoices)

Processed 13 invoices: 13 successful, 0 failed
Done
```

**IMPORTANT:** Output these progress messages immediately as each step completes to provide real-time feedback on batch progress.

## Run

cd ~/.claude/msh-insurance && git pull
