# new feature: check on reimbursements

## background

  - first read the guide: ./claims-submission-guide.md
  - [ ] log in
  - [ ] navigate to https://www.msh-services.com/index.php?module=decomptes&controller=index&action=index
  - each row has
    - a claim number
    - a "magnifying glass"
    - a PDF link
  - clicking on the magnifying glass will take you to a page with info about whether and how much was reimbursed, the status and any other additional info
  - clicking the PDF link will download/open a PDF with more or less the same info

## procedure for 'check on reimbursements'

  - [ ] look inside the claims-tracker.json
  - [ ] for any unreimbursed items, check for updated status in this part of the site
  - [ ] if it's been reimbursed, update the tracker
  - [ ] if there's an issue where more info is needed, flag this to the user and update the status to something regarding that (pending/need more info, etc.)
  - [ ] if it's just not covered, and no more info is needed, update the status to reflect that, and also flag it to the user
  - typically we're reimbursed 95% for medical expenses, and 100% for emergency-related medical expenses


# make a new Claude command

  - [ ] create /Users/zev/.claude/commands/msh-check-claims.md which performs the above

# rename the existing Claude command

  - [ ] rename /Users/zev/.claude/commands/msh-insurance.md -> msh-make-claims.md
