# MSH Insurance Reimbursement Check

Automate checking reimbursement status for submitted MSH insurance claims using Playwright browser automation.

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

**YOU ARE RUNNING IN AUTOMATED MODE - CHECK ALL PENDING CLAIMS**

**Input:** No arguments needed - the command will automatically read claims from `~/.claude/msh-insurance/claims-tracker.json`

**Workflow - AUTOMATE ALL STEPS:**

**FIRST: Load pending claims**
1. Read `~/.claude/msh-insurance/claims-tracker.json`
2. Filter for claims where `reimbursement.status` is "pending"
3. Output: "Found X pending claims to check"

**Automate browser navigation using Playwright MCP tools:**

1. **Navigate to MSH portal:**
   - Use `browser_navigate` to https://www.msh-services.com/index_assure_previnter.php?lang=en
   - Output: "Browser opened"

2. **Dismiss cookie/GDPR overlay (if present):**
   - Use `browser_snapshot` to check for cookie banner
   - If present, use `browser_click` to accept cookies (look for "Accept", "Accepter", "OK" buttons)
   - Output: "Cookie banner dismissed" or "No cookie banner found"

3. **Login:**
   - Load credentials from ~/.bash_secret (MSH_INTL_LOGIN, MSH_INTL_PASS)
   - Use `browser_type` to fill username field
   - Use `browser_type` to fill password field
   - Use `browser_click` to click login button
   - Output: "Logged in successfully"

4. **Navigate to "Your claims" page:**
   - Click "Your reimbursements" menu to expand it
   - Click "Your claims" link
   - Or navigate directly to: https://www.msh-services.com/index.php?module=demandes&controller=index&action=index
   - Output: "On claims page"

5. **For each pending claim:**

   a. Use `browser_snapshot` to see the claims table

   b. Find the claim number (from claims-tracker.json) in the table
      - Table has columns: "Date of claim", "Claim No.", "Claim status"
      - Look for the claim number in the "Claim No." column

   c. Check the "Claim status" column for this claim:

      **CASE 1: Status shows "In progress"**
      - This means claim is still being processed, not yet reimbursed
      - Keep tracker: `reimbursement.status = "pending"`
      - Output: "⏳ Claim [CLAIM_NUMBER]: Still in progress"
      - Continue to next claim

      **CASE 2: Status shows "Processed on [date] ([reimbursement_number])"**
      - This means claim has been processed and reimbursed!
      - The reimbursement_number is a clickable link (e.g., "CH260000429")
      - Click the reimbursement number link
      - Output: "Checking claim [CLAIM_NUMBER]..."

   d. **If claim was processed (CASE 2), read the reimbursement details page:**
      - Use `browser_snapshot` to capture the page content
      - The page shows:
        - Processing date (in first table)
        - Claim number
        - Total reimbursement amount (e.g., "45.32 CHF")
        - Payment method ("Wire transfer")
        - Payment recipient
      - Below that, a "Details of the reimbursement notice" section shows:
        - Beneficiary name as heading
        - Table with: Date of service, Service, Expenses incurred, Accepted amount, Other insurance, **Our payment**
        - **"Our payment"** column contains the actual reimbursed amount
      - **IMPORTANT:** Look for any explanation text or deductible information on the page:
        - Check for "Deductible", "Franchise", "Co-payment" mentions
        - Check for any notes explaining why reimbursement differs from expected
        - This info often appears near the "Accepted amount" or in footnotes

   e. **Extract information from details page:**
      - Processing date (from "Processing date" cell)
      - Total reimbursement amount (from "Total reimbursement" cell)
      - Reimbursed amount per service (from "Our payment" column in details table)
      - **Deductible/explanation info** (if present) - capture any text explaining discrepancies

   f. **Calculate expected reimbursement and flag discrepancies:**
      - Get original amount from tracker (e.g., 47.70 CHF)
      - If claim.emergency = true: expected = 100% of amount
      - If claim.emergency = false: expected = 95% of amount
      - Calculate: expected_amount = amount * (1.00 if emergency else 0.95)
      - If abs(reimbursed_amount - expected_amount) > 0.50 CHF:
        - Flag to user: "⚠ Claim [CLAIM_NUMBER]: Reimbursed [amount] CHF but expected [expected] CHF (original: [original] CHF)"

   g. **Update tracker for processed claim:**
      - Update: `reimbursement.status = "paid"`
      - Update: `reimbursement.amount_reimbursed = [total reimbursement amount]`
      - Update: `reimbursement.reimbursement_date = [processing date in YYYY-MM-DD format]`
      - Update: `reimbursement.reimbursement_number = [reimbursement number, e.g., "CH260000429"]`
      - **If partial reimbursement (discrepancy detected):**
        - Update: `reimbursement.accepted_amount = [accepted amount from details table]`
        - Update: `reimbursement.deductible_applied = [deductible amount if mentioned]`
        - Update: `reimbursement.explanation = [any explanation text found]`
        - Update: `reimbursement.notes = "⚠ [explanation of discrepancy]"`
      - Output: "✓ Claim [CLAIM_NUMBER]: REIMBURSED - [amount] CHF on [date]"

   h. **Navigate back to claims list:**
      - Use `browser_click` on "Go back to the list" link if available
      - Or use `browser_navigate` to https://www.msh-services.com/index.php?module=demandes&controller=index&action=index
      - Output: "Back to claims list"

   i. **Handle pagination if needed:**
      - The claims table shows 20 claims per page
      - If there are more pages (check for "Page suivante" / "Next page" link), navigate to next page
      - Continue checking pending claims on subsequent pages

   j. Repeat for next pending claim

6. **After checking all claims:**
   - Update `~/.claude/msh-insurance/claims-tracker.json` with all changes
   - Update metadata:
     - `last_updated` = current timestamp in ISO format
     - `pending_claims` = count of claims where reimbursement.status is "pending"
     - `reimbursed_claims` = count of claims where reimbursement.status is "paid"
     - `rejected_claims` = count of claims where reimbursement.status is "rejected"
     - `outstanding_amount` = sum of amounts for all pending claims
     - `total_reimbursed` = sum of amount_reimbursed for all paid claims
   - Output summary of findings

7. **Commit changes to git:**
   ```bash
   cd ~/.claude/msh-insurance
   git add claims-tracker.json
   git commit -m "Update claims tracker: reimbursement check on [date]"
   git push
   ```

8. **Final summary output:**
   ```
   === REIMBURSEMENT CHECK SUMMARY ===
   Total claims checked: X
   Newly reimbursed: Y (total: CHF Z.ZZ)
   Still pending: N

   [List newly reimbursed claims with amounts and dates]
   [List any claims with unexpected reimbursement amounts]
   ```

9. **Critical requirements:**
   - **AUTOMATION ONLY:** Use Playwright MCP browser automation tools. Never output manual instructions or ask user to do anything
   - **FULL AUTOMATION:** Complete the entire workflow from browser open to updating tracker without any user interaction
   - **PROGRESS OUTPUT:** Print progress messages as you go (e.g., "Browser opened", "Logged in", "Checking claim...")
   - **EXPECTED REIMBURSEMENT RATES:**
     - Medical expenses: 95% of amount
     - Emergency expenses: 100% of amount
     - Flag any discrepancies > 0.50 CHF to user
   - **PAGE NAVIGATION:** Use "Your claims" page (`/index.php?module=demandes&controller=index&action=index`), NOT "Your reimbursement notices"
   - **STATUS DETECTION:** Look for "Processed on [date] ([reimbursement_number])" in the status column
   - MUST dismiss cookie/GDPR banner before logging in (if present)
   - MUST navigate back to claims list after checking each processed claim
   - MUST update claims-tracker.json with all status changes
   - Exit with code 0 if completed successfully, code 1 if failed

**WRONG APPROACH - DO NOT DO THIS:**
```
Ready to proceed? Once you've logged in...
Please follow these steps...
Let me know when you're done...
```

**CORRECT APPROACH - DO THIS:**
```
=== Starting MSH reimbursement check ===
Reading claims tracker...
Found 19 pending claims to check

Opening browser...
Browser opened
Logging in...
Logged in successfully
On claims page

Checking claim CFW7954479...
⏳ Claim CFW7954479: Still in progress

Checking claim CFW7954704...
⏳ Claim CFW7954704: Still in progress

Checking claim CFW7955311...
✓ Claim CFW7955311: REIMBURSED - 45.32 CHF on 2026-01-05
Back to claims list

Checking claim CFW7961812...
✓ Claim CFW7961812: REIMBURSED - 104.88 CHF on 2026-01-06
Back to claims list

... (checking remaining claims)

=== REIMBURSEMENT CHECK SUMMARY ===
Total claims checked: 19
Newly reimbursed: 2 (total: CHF 150.20)
Still pending: 17

NEWLY REIMBURSED:
✓ CFW7955311 - 45.32 CHF on 2026-01-05 (Sylvia Hannah AVERBACH - Lab tests)
✓ CFW7961812 - 104.88 CHF on 2026-01-06 (Sylvia Hannah AVERBACH - Dental Check-up)

Updated claims tracker and committed changes to git.
Done
```

**IMPORTANT:** Output these progress messages immediately as each step completes to provide real-time feedback.

## Run

cd ~/.claude/msh-insurance && git pull
