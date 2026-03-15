# MSH Insurance Status Summary

Quick summary of all insurance claims and reimbursement status from the claims tracker.

## Instructions

**CRITICAL REQUIREMENTS:**

1. **READ-ONLY OPERATION:** This command only reads and summarizes data, no browser automation needed
2. **DETERMINISTIC OUTPUT:** Parse claims-tracker.json and output a formatted summary
3. **NO USER INTERACTION:** Run to completion with no prompts or questions

**Input:** No arguments needed - reads from `~/.claude/msh-insurance/claims-tracker.json`

**Workflow:**

1. **Read claims tracker:**
   - Load `~/.claude/msh-insurance/claims-tracker.json`
   - Extract metadata and all claims

2. **Generate summary output:**

```
=== MSH INSURANCE STATUS SUMMARY ===
Last updated: [metadata.last_updated in readable format]

OVERVIEW:
Total claims: [total_claims]
Outstanding amount: [sum of pending claim amounts] CHF

REIMBURSEMENT STATUS:
✓ Paid: [reimbursed_claims] claims - [sum of amount_reimbursed] CHF
⏳ Pending: [pending_claims] claims - [sum of pending amounts] CHF
✗ Rejected: [rejected_claims] claims - [sum of rejected amounts] CHF
⊘ Cancelled: [cancelled_claims] claims - [sum of cancelled amounts] CHF

BREAKDOWN BY BENEFICIARY:
[For each unique beneficiary, show:]
  [Beneficiary Name]:
    Paid: [count] claims ([total CHF] CHF)
    Pending: [count] claims ([total CHF] CHF)
    Rejected: [count] claims ([total CHF] CHF)

ATTENTION REQUIRED:
[List claims with warnings/notes, such as:]
✗ [claim_number] - [beneficiary] - REJECTED: [rejection reason from notes]
⚠ [claim_number] - [beneficiary] - [warning from notes, e.g., partial reimbursement]

PENDING CLAIMS (awaiting reimbursement):
[For each pending claim:]
⏳ [claim_number] - [beneficiary] - [amount] CHF
   [description] - [provider]
   Service date: [service_date]
   Submitted: [submission_date] ([days ago] days ago)

RECENT REIMBURSEMENTS (last 5):
[For each of the 5 most recent reimbursed claims, sorted by reimbursement_date:]
✓ [claim_number] - [beneficiary] - [amount_reimbursed] CHF
   [description] - [provider]
   Reimbursed on: [reimbursement_date] ([days ago] days ago)
```

3. **Formatting requirements:**
   - Use clear visual indicators: ✓ (paid), ⏳ (pending), ✗ (rejected), ⊘ (cancelled), ⚠ (warning)
   - Show dates in readable format (YYYY-MM-DD)
   - Calculate "days ago" for pending claims and recent reimbursements
   - Sort beneficiaries alphabetically
   - Sort pending claims by submission date (oldest first)
   - Sort recent reimbursements by reimbursement date (newest first)
   - Align numbers nicely for readability
   - Include currency symbol (CHF) for all amounts
   - Round amounts to 2 decimal places

4. **Special cases to highlight:**
   - Claims with partial reimbursements (notes contain "⚠")
   - Rejected claims (status = "rejected")
   - Cancelled claims (status = "cancelled")
   - Pending claims submitted more than 14 days ago (flag with "⏰ DELAYED")
   - Resubmitted claims (has "previous_claim" field)

5. **Exit:**
   - Exit with code 0 when complete
   - No need to modify files or commit anything

**Example output:**

```
=== MSH INSURANCE STATUS SUMMARY ===
Last updated: 2026-01-25 14:42:00 UTC

OVERVIEW:
Total claims: 26
Outstanding amount: 3399.34 CHF

REIMBURSEMENT STATUS:
✓ Paid: 16 claims - 3608.81 CHF
⏳ Pending: 7 claims - 3366.44 CHF (expected ~3198.12 CHF at 95%)
✗ Rejected: 2 claims - 224.40 CHF
⊘ Cancelled: 1 claim - 139.90 CHF

BREAKDOWN BY BENEFICIARY:
  Abigail AVERBACH:
    Paid: 3 claims (586.54 CHF)
    Pending: 1 claim (193.50 CHF)
    Rejected: 1 claim (193.50 CHF)

  August Winston Chester AVERBACH:
    Paid: 1 claim (504.36 CHF)
    Pending: 2 claims (141.79 CHF)
    Rejected: 1 claim (30.90 CHF)
    Cancelled: 1 claim (139.90 CHF)

  Simon Alexander AVERBACH:
    Paid: 5 claims (1024.77 CHF)
    Pending: 1 claim (17.85 CHF)

  Sylvia Hannah AVERBACH:
    Paid: 3 claims (362.15 CHF)
    Pending: 1 claim (1846.20 CHF)

  Zev AVERBACH:
    Paid: 1 claim (436.24 CHF)
    Pending: 2 claims (1200.00 CHF)

ATTENTION REQUIRED:
✗ CFW7961722 - August Winston Chester AVERBACH - REJECTED: 'Please provide us with the itemized invoices'
  → Resubmitted as CFW8030371 (pending)

✗ CFW7961735 - Abigail AVERBACH - REJECTED: 'Please send us a copy of the invoice that you forgot to attach'
  → Resubmitted as CFW8030381 (pending)

⊘ CFW7961778 - August Winston Chester AVERBACH - CANCELLED on 2026-01-07

⚠ CFW7954479 - Simon Alexander AVERBACH - Emergency claim: expected 189.00 CHF (100%), received 179.55 CHF

⚠ CFW7955164 - Sylvia Hannah AVERBACH - Partial reimbursement: expected 305.62 CHF (95%), received 132.91 CHF

PENDING CLAIMS (awaiting reimbursement):
⏳ CFW8030257 - Zev AVERBACH - 600.00 CHF
   Psychotherapist (Therapists) - Dr. Marc Descombes (Psychotherapy)
   Service date: 11/12/2025
   Submitted: 2026-01-25 (0 days ago)

⏳ CFW8030265 - Simon Alexander AVERBACH - 17.85 CHF
   Paediatrician (Outpatient consultations) - Dre Christina Maneff
   Service date: 02/12/2025
   Submitted: 2026-01-25 (0 days ago)

⏳ CFW8030284 - August Winston Chester AVERBACH - 110.90 CHF
   Paediatrician (Outpatient consultations) - Dre Christina Maneff
   Service date: 11/12/2025
   Submitted: 2026-01-25 (0 days ago)

⏳ CFW8030294 - Sylvia Hannah AVERBACH - 1846.20 CHF
   Dental Check-up (Dental care) - Centre Dentaire Chêne-Bourg
   Service date: 30/12/2025
   Submitted: 2026-01-25 (0 days ago)

⏳ CFW8030347 - Zev AVERBACH - 600.00 CHF
   Psychotherapist (Therapists) - Dr. Marc Descombes (Psychotherapy)
   Service date: 28/10/2025
   Submitted: 2026-01-25 (0 days ago)

⏳ CFW8030371 - August Winston Chester AVERBACH - 30.89 CHF
   G.P office visit (Outpatient consultations) - Dr. FAUNDEZ Tamara
   Service date: 28/12/2025
   Submitted: 2026-01-25 (0 days ago)
   Note: Resubmission of CFW7961722 with itemized invoice

⏳ CFW8030381 - Abigail AVERBACH - 193.50 CHF
   Psychologist (Therapists) - Centre Médical Bachet de Pesay
   Service date: 03/11/2025
   Submitted: 2026-01-25 (0 days ago)
   Note: Resubmission of CFW7961735 with proper invoice attachment

RECENT REIMBURSEMENTS (last 5):
✓ CFW7961795 - August Winston Chester AVERBACH - 504.36 CHF
   Dental Check-up (Dental care) - Dr A. Bérard & Dr T-M. Nguyen & Dr S. Torres
   Reimbursed on: 2026-01-12 (13 days ago)

✓ CFW7961782 - Simon Alexander AVERBACH - 226.25 CHF
   Paediatrician (Outpatient consultations) - Dre Christina Maneff
   Reimbursed on: 2026-01-10 (15 days ago)

✓ CFW7961716 - Simon Alexander AVERBACH - 171.47 CHF
   G.P office visit (Outpatient consultations) - Dr. FAUNDEZ Tamara
   Reimbursed on: 2026-01-10 (15 days ago)

✓ CFW7961835 - Sylvia Hannah AVERBACH - 211.95 CHF
   Dental Check-up (Dental care) - Centre Dentaire Chêne-Bourg
   Reimbursed on: 2026-01-10 (15 days ago)

✓ CFW7961866 - Simon Alexander AVERBACH - 311.32 CHF
   Orthodontic treatment (Dental care) - Centre Dentaire Chêne-Bourg
   Reimbursed on: 2026-01-10 (15 days ago)
```

**IMPORTANT:**
- This is a read-only summary command - no modifications to files
- No browser automation required - just parse JSON and format output
- Output should be immediate and deterministic
- Use clear visual indicators for easy scanning
- Highlight items requiring attention

## Run

cd ~/.claude/msh-insurance && git pull
