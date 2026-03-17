# MSH Insurance Claims Submission Guide

## Quick Start - Automatic Processing

### Simple Command to Process All Invoices

To automatically process ALL invoices in the received folders without any further prompting:

```bash
# In Claude Code CLI, simply say:
/msh-insurance
# Then respond with: "please continue"
```

**What happens:**
1. Claude will automatically find all invoices in `~/Downloads/bills/received, paid/`
2. It will process each invoice sequentially:
   - Read the invoice to extract details (beneficiary, date, amount, provider, description)
   - Log into MSH Services portal
   - Fill out the claim form with the extracted information
   - Upload the invoice attachments
   - Submit the claim
   - Extract the claim number
   - Update the claims tracker JSON
   - Move the invoice to `~/Downloads/bills/submitted/`
3. After completing all invoices, it will commit and push the tracker changes to git

**Important Notes:**
- **No user prompts:** Claude will process all invoices without stopping or asking for confirmation
- **Sequential processing:** Invoices are processed one at a time (MSH portal requirement)
- **Automatic image compression:** Images over 3MB are automatically compressed before upload
- **Session continuity:** If Claude runs out of context, just say "please continue" and it will resume
- **Error handling:** If a claim fails, Claude will skip it and move to the next one

### Alternative: User-Directed Processing

If you prefer to control which invoice to process:

```bash
# In Claude Code CLI:
/msh-insurance [specific-invoice-path]

# Example:
/msh-insurance ~/Downloads/bills/received, paid/12345678
```

## Overview
This guide documents the process for submitting medical insurance claims through the MSH Services Members' Area.

## Login Information
- **URL:** https://www.msh-services.com/index_assure_previnter.php?lang=en
- **Credentials:** Environment variables `MSH_INTL_LOGIN` and `MSH_INTL_PASS` (source from `~/.bash_secret`)

## Workflow Overview

### Sequential Processing:
When invoked, this process handles **one claim at a time** in sequence, processing all non-submitted invoices until complete.

1. **Scan for invoices** in:
   - `~/Downloads/bills/received, paid/` - Invoices already paid
   - `~/Downloads/bills/received, unpaid/` - Outstanding invoices
2. **For each invoice:**
   - **⚠️ CRITICAL: Verify it's a medical bill** (see Medical Bill Verification section)
   - If NOT a medical bill, skip it and flag for user review - DO NOT SUBMIT
   - Compress images in that invoice folder if needed (see Image Compression section)
   - Submit the claim following the steps below
   - After successful submission:
     - Extract claim number from success screen
     - Rename the file (image/PDF) to `[claim-number].[extension]`
     - Add invoice ID to file metadata (extended attribute + Finder comment)
     - Move to `~/Downloads/bills/submitted/` (flat structure, no subfolders)
3. **Repeat** until all invoices are processed

### Critical: Sequential Processing Only
⚠️ **IMPORTANT:** The MSH portal uses session-based state that is shared across all browser tabs. Claims MUST be processed sequentially, one at a time.

**Correct workflow:**
- Complete ONE full claim submission at a time: fill form → upload → submit → confirm → move files
- Only start the next claim AFTER the previous one is fully complete

**Why sequential processing:**
- Session state is cleared when you submit one claim
- Multiple tabs or parallel processing will fail
- Each claim must complete before starting the next

## Medical Bill Verification

**⚠️ CRITICAL CHECK BEFORE SUBMITTING ANY CLAIM:**

Before processing an invoice, verify it is a **medical/health-related expense**. DO NOT submit claims for:

**Non-Medical Bills (SKIP THESE):**
- ❌ **School tuition** (e.g., "Ecolage", "Institut Florimont", "School fees")
- ❌ **General education fees** (not health-related)
- ❌ **Non-medical services**

**Valid Medical Bills (SUBMIT THESE):**
- ✅ Doctor visits (GP, specialist, pediatrician)
- ✅ Lab tests and diagnostics
- ✅ Dental care and orthodontics
- ✅ Emergency visits (Urgences)
- ✅ Psychologist/therapist visits
- ✅ Prescriptions and medications
- ✅ Medical imaging (X-rays, ultrasounds, etc.)

**How to Check:**
1. Read the invoice provider name
2. Look for medical terminology in the description
3. Check for medical procedure codes or diagnoses
4. If in doubt, ask the user before submitting

**If Non-Medical Bill Found:**
- **DO NOT SUBMIT A CLAIM**
- Move to a separate `~/Downloads/bills/non-medical/` folder
- Flag for user review
- Report which invoice was skipped and why

## Claims Submission Process

### Step 1: Navigate to Claims Form

1. Navigate to the Members' Area: `https://www.msh-services.com/index_assure_previnter.php?lang=en`
2. Log in using credentials from `~/.bash_secret` (MSH_INTL_LOGIN, MSH_INTL_PASS)
3. Navigate to claims form directly:
   - **Direct URL:** `https://www.msh-services.com/index.php?module=demandes&controller=claimform&action=etape2`

**Technical Details:**
- Login page: `https://www.msh-services.com/index_assure_previnter.php?lang=en`
- Main page URL: `https://www.msh-services.com/index.php?module=common&controller=index&action=index`
- "Your claims" link text: "Your claims Submit your claims in just a few clicks"

### Step 2: Select Dependents (Family Members)
1. Select the family member(s) who received medical services by clicking their checkbox
2. Answer the Social Security eligibility question (typically "No")
3. Click "Next step"

**Technical Details:**
- Each family member has a checkbox in a table row
- Social Security question appears after selecting a member
- Radio buttons: `name="accident"` with values for Yes/No
- Next step button: `javascript:submitFormSelectionBeneficiaires('next')`

### Step 3: Enter Medical Expense Details
**IMPORTANT:** Fill in the Date of Service FIRST to load the description categories

1. **Date of service:** Enter in format DD/MM/YYYY (e.g., 02/12/2025)
   - Press Tab after entering to trigger category loading
2. **Description:** Select from categorized options:
   - Diagnostic tests > Lab tests (for laboratory analyses)
   - Outpatient consultations (for doctor visits)
   - Other categories as appropriate
3. **Country:** SWITZERLAND (default)
4. **Amount paid:** Enter amount (e.g., 189.00)
5. **Currency:** CHF (default)
6. **Accident/Emergency question:** "Is this treatment a result of an accident, an accident caused by a third party or a medical emergency?"
   - **⚠️ CRITICAL:** Always check the invoice carefully for emergency visits!
   - Look for **"Demandé par"** (Requested by) or **"Ordered by"** field on the invoice
   - If it shows **"Urgences"** (Emergency), **"Urgences Pédiatriques"** (Pediatric Emergency), or any emergency department, select **"Yes"**
   - For regular appointments, select "No"
7. Click "Add this medical expense"
8. Click "Next step"

**Technical Details:**
- URL: `https://www.msh-services.com/index.php?module=demandes&controller=claimform&action=etape3`
- Date field: `input#date_soins` (name="date_soins")
  - **IMPORTANT:** Use the datepicker UI - clicking the field opens a calendar widget
  - Select month/year from dropdowns, then click the day
  - Final format stored is MM-DD-YYYY (e.g., "11-13-2025" for Nov 13, 2025)
  - Typing directly may cause validation errors - always use the datepicker
- Description: Tree structure in `ul#codesActes` (loads after date is entered)
  - Click expand icons to open categories
  - Click the text link to select (e.g., "Lab tests")
- Country dropdown: `select#pays` (name="pays")
- Amount field: `input[name="montant"]`
- Currency dropdown: `select#devise` (name="devise")
- Emergency question: Radio buttons with `name="accident"` (id="accident-1" for Yes, "accident-0" for No)
- Submit button: `button#ajoutersoin` with text "Add this medical expense"

### Step 3b: Additional Information for Emergency/Accident (Only if marked as emergency in Step 3)

**This step appears ONLY if you selected "Yes" for the accident/emergency question in Step 3.**

Fill in the following required fields:

1. **Nature** (select one):
   - Transport accident
   - Work-related accident
   - Medical emergency (for "Urgences" visits)
   - Other type of accident

2. **Date** - Date of the emergency/accident (format: DD/MM/YYYY)

3. **Place** - Location where the emergency occurred
   - For hospital visits, include: Department name, address
   - Example: "Urgences Pédiatriques Cité Général, Route de Chancy 98-100, 1213 Onex"

4. **Circumstances** - Brief description of what happened
   - Example: "Multiple persistent coughing fits, trouble breathing without coughing."

**Technical Details:**
- URL: `https://www.msh-services.com/index.php?module=demandes&controller=claimform&action=etape4`
- Nature: Radio buttons with name likely similar to accident type
  - Medical emergency: `id` or value for medical emergency option
- Date field: `input#date` (name="date")
- Place field: `input#lieu` (name="lieu")
- Circumstances field: `input#circonstances` or `textarea#circonstances` (name="circonstances")
- Next step: `javascript:submitFormAccident('next')`

**Note:** After emergency claims, the step numbering shifts - Attachments becomes Step 4, General Summary becomes Step 5.

### Step 4: Upload Attachments

#### File Requirements:
- **Maximum file size:** 3 MB per file
- **Maximum files:** 20 documents
- **Accepted formats:** jpeg, jpg, gif, pdf, png, JPEG, JPG, PNG, msg, heif, heic

#### Upload Process:
1. Select "Yes" when asked about electronic documents (Radio button id="modeUpload")
   - **Automation note:** The radio button may be obscured by other elements
   - Use JavaScript if needed: `document.getElementById('modeUpload').checked = true; document.getElementById('modeUpload').dispatchEvent(new Event('change', { bubbles: true }));`
2. Click the "Add files" link (not the hidden file input button)
   - **IMPORTANT:** Click the visible "Add files" link, which triggers the file chooser
   - Do NOT try to click the "Choose File" button directly - it's overlaid by the plupload interface
3. Select file(s) from the file chooser dialog
4. Wait for 100% upload completion (shown in progress indicator)
5. Click "Confirm" to proceed to summary

**Technical Details:**
- URL: `https://www.msh-services.com/index.php?module=demandes&controller=claimform&action=etape5`
- Yes/No radio buttons: name="choix" (id="modeUpload" for Yes, "modeNormal" for No)
- Upload interface: Uses plupload library with link id="uploader_demande_de_remboursement_browse"
- File upload endpoint: `POST /index.php?module=default&controller=upload&action=uploadfile&designation=demande_de_remboursement`
- File list endpoint: `POST /index.php?module=default&controller=upload&action=list`
- Progress shown in percentage and file size

### Step 5: Review and Submit
1. Review the General Summary:
   - Verify family member name
   - Check date, description, amount, country
   - Confirm attachments are listed
   - Verify bank details (Wire transfer, CHF)
2. Select reimbursement currency from dropdown (typically CHF)
3. **Payment status** is determined by which folder the invoice was in:
   - `received, paid/` → `paid: true`
   - `received, unpaid/` → `paid: false`
   - This will be recorded in the `paid` field of claims-tracker.json
4. Check the certification box: "I certify that the information recorded in this form and attached supporting documents are true and accurate."
5. **Automatically click the "Submit" button** (appears after checking the box) - NO USER CONFIRMATION NEEDED
6. **After successful submission:**
   - Extract claim number from success screen (e.g., "CFW7954479")
   - Rename the submitted file to `[claim-number].[extension]` (e.g., `CFW7954479.pdf`)
   - Add invoice ID to file metadata:
     ```bash
     xattr -w com.user.invoice_id "[invoice-id]" "[claim-file]"
     osascript -e "tell application \"Finder\" to set comment of (POSIX file \"[full-path]\" as alias) to \"Invoice: [invoice-id]\""
     ```
   - Move renamed file to `~/Downloads/bills/submitted/` (flat structure)
   - Update claims-tracker.json with claim details
7. **Continue to next invoice:** Repeat the process for the next non-submitted invoice

**Technical Details:**
- URL: `https://www.msh-services.com/index.php?module=demandes&controller=claimform&action=etape6`
- Currency dropdown: `select` with name likely similar to payment currency
- Certification checkbox: Look for checkbox with text about certifying accuracy
- Submit button appears after checkbox is checked

## Claims Tracking

A JSON data store tracks all submitted claims for reimbursement tracking:

**Location:** `~/.claude/msh-insurance/claims-tracker.json`

**Structure:**
```json
{
  "claims": [
    {
      "claim_number": "CFW7954479",
      "invoice_id": "12039295",
      "submission_date": "2026-01-05",
      "beneficiary": "Simon Alexander AVERBACH",
      "service_date": "02/12/2025",
      "provider": "Unilabs Coppet - Urgences Pédiatriques",
      "amount": 189.00,
      "currency": "CHF",
      "emergency": true,
      "paid": true,
      "status": "submitted",
      "reimbursement": {
        "status": "pending",
        "amount_reimbursed": null,
        "reimbursement_date": null
      }
    }
  ]
}
```

**Field Descriptions:**
- `paid`: Boolean indicating whether the invoice has been paid (separate from reimbursement status)
  - `true`: Invoice has been paid
  - `false`: Invoice is still outstanding
  - Default: `true` (most invoices are paid before submission)

**After each successful submission:**
1. Add new claim entry with claim number from success screen
2. Update metadata counters
3. Link claim number to invoice ID for tracking
4. **Git commit:** Commit and push changes to the tracker (and guide if modified):
   ```bash
   cd ~/.claude/msh-insurance
   git add claims-tracker.json claims-submission-guide.md
   git commit -m "Update claims tracker: add claim [CLAIM_NUMBER]"
   git push
   ```

## File Organization

### Invoice Organization System

**Initial State:**
Invoices arrive as individual files (images or PDFs) in the received folders. Part of the processing task is to:
1. **Group files that belong to the same invoice** by:
   - Reading invoice content (same invoice number/ID)
   - Checking file metadata (consecutive timestamps indicate same invoice)
2. **Organize into folders** by invoice ID
3. **Determine payment status** from which received folder they're in

**Organization by payment status:**

```
~/Downloads/bills/
├── received, paid/    # Individual files arrive here (already paid)
│   ├── IMG_0995.jpeg  # File 1 for invoice F_3181100200
│   ├── IMG_0996.jpeg  # File 2 for invoice F_3181100200 (consecutive timestamp)
│   ├── IMG_0986.jpeg  # File 1 for invoice 12008744
│   ├── IMG_0987.jpeg  # File 2 for invoice 12008744
│   ├── Facture - August AVERBACH A4489 - 14391.pdf  # Single-file invoice
│   └── [other files]/
├── received, unpaid/  # Individual files arrive here (not yet paid)
│   └── [invoice files]/
├── submitted/         # Successfully submitted claims (flat structure)
│   ├── CFW7954479.jpeg  # Named by claim number, not invoice ID
│   ├── CFW7954704.pdf
│   ├── CFW7954873.pdf
│   ├── originals/          # All original images
│   │   ├── 12039295_IMG_0985.jpeg
│   │   ├── 12008744_IMG_0986.jpeg
│   │   └── [other originals named: invoice-id_filename]
│   └── [other claims]/
├── non-medical/       # Non-medical bills (DO NOT SUBMIT)
│   └── [tuition, school fees, etc.]/
└── archive/          # Optional: for older invoices
```

**Determining Which Files Belong to Same Invoice:**
Files can be grouped by:
1. **Reading invoice content:**
   - Same invoice number/ID visible in images
   - Same provider, beneficiary, date, and amount
2. **File metadata (timestamps):**
   - Files with consecutive timestamps (within seconds/minutes) likely belong together
   - Check: `ls -lt` to see files sorted by modification time
   - Example: IMG_0995.jpeg and IMG_0996.jpeg both modified at 09:39:15 = same invoice

**Processing Workflow:**
1. **Scan received folders** for individual files
2. **Group files by invoice:**
   - Read content or check timestamps to identify which files belong together
   - Create folder named by invoice ID
   - Move related files into that folder
3. **For each grouped invoice:**
   - Compress images (if needed) and combine into single PDF
   - Submit claim and get claim number
   - **Rename file to claim number** (e.g., `CFW7954479.pdf`)
   - **Add invoice ID to file metadata** (extended attribute + Finder comment)
   - Move renamed file to `submitted/` (flat structure, no subfolders)
4. Payment status is tracked in claims-tracker.json
5. Process continues sequentially until all invoices are complete

**File Metadata:**
Each submitted file has:
- Extended attribute: `com.user.invoice_id` = original invoice ID
- Finder comment: "Invoice: [invoice-id]"
- Accessible via: `xattr -p com.user.invoice_id [filename]` or Finder Get Info

### Image Compression

Images must be under 3MB to upload to the MSH portal.

**Naming Convention:**
- Original: `IMG_0985.jpeg` → Moved to `originals/` subfolder after compression
- Single image: `IMG_0985_compressed.jpeg` → Remains in invoice folder
- Multiple images: `[invoice-id].pdf` → Combined into single PDF

**Behavior:**
1. Compress all images >3MB to 70% quality JPEG
2. Move originals to `originals/` subfolder
3. **If multiple images exist:** Combine all images into a single PDF named after the invoice ID
   - Tries progressively lower quality (85%, 75%, 65%, 55%, 45%, 35%, 25%) until PDF < 3MB
   - Removes individual compressed images once PDF is successfully created
   - If even 25% quality produces a PDF > 3MB, keeps individual compressed images instead
4. Scripts automatically skip images that already have a compressed version

**Why combine into PDF?**
- Simplifies upload (one file instead of multiple)
- MSH portal accepts both JPEGs and PDFs
- PDF compression is efficient - often similar size to single image

**Usage:**
```bash
~/.claude/msh-insurance/compress-invoice-images.sh <invoice-directory>

# Example - single image:
~/.claude/msh-insurance/compress-invoice-images.sh "~/Downloads/bills/received, paid/12039295"
# Result: IMG_0985_compressed.jpeg

# Example - multiple images:
~/.claude/msh-insurance/compress-invoice-images.sh "~/Downloads/bills/received, paid/12008744"
# Result: 12008744.pdf (containing IMG_0986 and IMG_0987)
```

## Family Members

### Portal Display Names
The MSH portal displays family member names in a specific format that may differ from invoice names:

| Portal Display Name | Invoice Name | Notes |
|---------------------|--------------|-------|
| AVERBACH ABIGAIL | Abigail AVERBACH | Principal insured - last name first in portal |
| AVERBACH Zev | Zev AVERBACH | Spouse |
| AVERBACH Sylvia Hannah | Sylvia Hannah AVERBACH | Child |
| AVERBACH Simon Alexander | Simon Alexander AVERBACH | Child |
| AVERBACH August Winston Chester | August Winston Chester AVERBACH | Child |

**Important:** When matching invoices to family members, be flexible with name order and formatting. The portal shows "LASTNAME Firstname" but invoices may show "Firstname LASTNAME".

## Common Invoice Types

**Valid Medical Providers:**
- **Unilabs:** Laboratory tests (Diagnostic tests > Lab tests)
- **Dianalabs:** Laboratory tests (Diagnostic tests > Lab tests)
- **Dr. Faundez:** Doctor consultations (Outpatient consultations)
- **Dr. Maneff:** Doctor consultations (Outpatient consultations)
- **Centre Dentaire Chene-Bourg:** Dental care (Dental care category)
- **Urgences Pédiatriques:** Emergency visits (mark as emergency)
- **Psychologist visits:** Therapy (Therapists category)

**⚠️ NON-MEDICAL - DO NOT SUBMIT:**
- **Institut Florimont:** School tuition/education fees - NOT MEDICAL
- Any invoice with "Ecolage" (tuition) in description
- Any education-related fees

## Tips

### Critical Reminders
- **Keep originals:** Retain original documents for 24 months (required by insurance)

### Workflow Efficiency
- **Compress images:** Compress images in the invoice folder before submission if they exceed 3MB
- **Move after submit:** Always move completed invoice folders to `submitted/` folder after successful submission
- **Sequential processing:** Process each claim completely before moving to the next
- **Use technical details:** Reference the element IDs and field names in this guide for faster automation

### During Submission
- **Description matters:** Use the description categories carefully - they determine coverage eligibility
- **Save drafts:** Use the "Draft" button at any step to save progress
- **Edit anytime:** Click step numbers in the progress bar to go back and edit

### Common Mappings
- Lab tests → "Diagnostic tests > Lab tests"
- Doctor visits → "Outpatient consultations"
- Dental → "Dental care"

## Quick Commands

### Rename and Move File After Submission
```bash
# After successful submission:
# 1. Rename file to claim number
# 2. Add invoice ID to metadata
# 3. Move to submitted folder

# Example:
cd ~/Downloads/bills/received,\ paid/12039295
mv 12039295.pdf ~/Downloads/bills/submitted/CFW7954479.pdf
xattr -w com.user.invoice_id "12039295" ~/Downloads/bills/submitted/CFW7954479.pdf
osascript -e 'tell application "Finder" to set comment of (POSIX file "/Users/zev/Downloads/bills/submitted/CFW7954479.pdf" as alias) to "Invoice: 12039295"'
```

### Check File Sizes
```bash
# List all files with sizes in received folders
find ~/Downloads/bills/received,\ paid ~/Downloads/bills/received,\ unpaid -type f -exec ls -lh {} \; | grep -E '\.(jpg|jpeg|png|pdf)$'

# Count invoices ready to submit (both paid and unpaid)
ls -1 ~/Downloads/bills/received,\ paid ~/Downloads/bills/received,\ unpaid 2>/dev/null | wc -l

# Count submitted invoices
ls -1 ~/Downloads/bills/submitted | wc -l
```

## Troubleshooting

### Date Field Not Loading Categories
- Make sure to fill in the date field FIRST (input#date_soins)
- Press Tab to trigger the category loading
- Wait 2-3 seconds for categories to appear in ul#codesActes
- If still not loading, refresh the page and try again

### Date Picker JavaScript Workaround
The jQuery datepicker may not respond to normal Playwright `selectOption()` calls. Use JavaScript evaluation instead:

```javascript
// Set year
await page.evaluate(() => {
  const yearSelect = document.querySelector('.ui-datepicker-year');
  yearSelect.value = '2025';
  yearSelect.dispatchEvent(new Event('change'));
});

// Set month (0-indexed: 0=Jan, 9=Oct, 10=Nov, etc.)
await page.evaluate(() => {
  const monthSelect = document.querySelector('.ui-datepicker-month');
  monthSelect.value = '10'; // November
  monthSelect.dispatchEvent(new Event('change'));
});

// Then click the day
await page.getByRole('link', { name: '11' }).click();
```

### File Upload Automation Notes
- The "Yes" radio button for electronic documents may be obscured by the plupload interface
- Use JavaScript to check it directly: `document.getElementById('modeUpload').checked = true; document.getElementById('modeUpload').dispatchEvent(new Event('change', { bubbles: true }));`
- Click the visible "Add files" link to trigger the file chooser, not the hidden "Choose File" button
- Wait 2-3 seconds after clicking "Yes" for the upload interface to fully initialize

## Created
January 5, 2026
