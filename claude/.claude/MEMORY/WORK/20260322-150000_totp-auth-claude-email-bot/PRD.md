---
task: Add TOTP authentication to Claude email bot
slug: 20260322-150000_totp-auth-claude-email-bot
effort: extended
phase: complete
progress: 17/17
mode: interactive
started: 2026-03-22T15:00:00-04:00
updated: 2026-03-22T15:01:00-04:00
---

## Context

Adding TOTP-based 2FA to the email-claude.py pipeline. The TOTP secret gets added to any standard authenticator app (1Password, Google Authenticator, Apple Passwords) which already has biometric protection. The sending workflow uses iOS Shortcuts / Alfred / Tasker to compose the email with a TOTP code. The server verifies the code with a widened window for email delivery latency.

Approach: Generate TOTP secret → store on beelink → add to authenticator via QR/otpauth URI → update email-claude.py to require TOKEN: line → build iOS Shortcut + Alfred workflow.

### Risks
- Email delivery delay could exceed TOTP window — use ±5 steps (±2.5 min)
- iOS Shortcuts can't compute TOTP natively — use authenticator app + paste/input
- Alfred can compute TOTP via oathtool if installed

## Criteria

- [x] ISC-1: TOTP shared secret generated and stored at /srv/media-ext/claude-totp-secret
- [x] ISC-2: Secret file permissions are 600 (owner-only read)
- [x] ISC-3: otpauth URI printed for adding to authenticator apps
- [x] ISC-4: email-claude.py reads TOTP secret from file on startup
- [x] ISC-5: email-claude.py extracts TOKEN: line from email body
- [x] ISC-6: email-claude.py verifies TOTP with ±5 step window
- [x] ISC-7: email-claude.py rejects emails without valid TOKEN line
- [x] ISC-8: email-claude.py sends rejection reply on bad/missing token
- [x] ISC-9: email-claude.py strips TOKEN line before passing to Claude
- [x] ISC-10: email-claude.py logs auth success/failure events
- [x] ISC-11: Dashboard CRON_DESCRIPTIONS updated to mention 2FA
- [x] ISC-12: iOS Shortcut instructions created with prompt + token input + email compose
- [x] ISC-13: Alfred workflow created with TOTP generation + email compose
- [x] ISC-14: Tasker approach documented for Android
- [x] ISC-15: email-claude.py still runs without error after changes
- [x] ISC-16: Existing non-claude email scripts unaffected
- [x] ISC-A-1: Anti: email without valid TOTP cannot trigger Claude execution
