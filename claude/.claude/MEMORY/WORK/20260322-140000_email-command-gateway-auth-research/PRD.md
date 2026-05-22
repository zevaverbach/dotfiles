---
task: Research email command gateway authentication and 2FA methods
slug: 20260322-140000_email-command-gateway-auth-research
effort: extended
phase: complete
progress: 18/18
mode: interactive
started: 2026-03-22T14:00:00-07:00
updated: 2026-03-22T14:08:00-07:00
---

## Context

User needs comprehensive research on securing email-based command gateways -- systems where sending an email triggers automated actions. Eight specific sub-topics requested covering TOTP, HMAC, platform-specific auth patterns, open-source projects, mobile/desktop token generation with biometric gates, and anti-spoofing best practices. Explicit requirement for implementation-level detail: repos, packages, code patterns -- not just concepts.

## Criteria

- [x] ISC-1: TOTP-in-email-body pattern documented with implementation details
- [x] ISC-2: TOTP libraries identified for TypeScript and other languages
- [x] ISC-3: HMAC email body signing mechanism explained with code pattern
- [x] ISC-4: HMAC shared secret management approach documented
- [x] ISC-5: IFTTT email trigger authentication mechanism documented
- [x] ISC-6: Zapier email trigger authentication mechanism documented
- [x] ISC-7: CI/CD email trigger auth patterns documented (GitHub/GitLab)
- [x] ISC-8: Mailgun inbound webhook authentication documented
- [x] ISC-9: Open-source email-to-command projects identified with repos
- [x] ISC-10: iOS Shortcuts TOTP generation capability documented
- [x] ISC-11: iOS Shortcuts biometric gate implementation documented
- [x] ISC-12: Alfred workflow auth token generation documented
- [x] ISC-13: Android Tasker TOTP or crypto signature generation documented
- [x] ISC-14: Android biometric gate for auth token generation documented
- [x] ISC-15: SPF/DKIM/DMARC anti-spoofing role explained
- [x] ISC-16: Replay attack prevention for email commands documented
- [x] ISC-17: Specific GitHub repos or npm packages cited for each approach
- [x] ISC-18: Strategic synthesis of best approach provided
- [x] ISC-A-1: Anti: No high-level-only findings without implementation detail

## Verification

- ISC-1: Section 1 includes otplib code example, window management strategy, and canonical email format
- ISC-2: Table listing otplib (TS), otpauth (JS), JS-OTP (JS), pyotp (Python), totp-kt (Kotlin)
- ISC-3: Section 2 includes full TypeScript and Python HMAC-SHA256 code with canonical string construction
- ISC-4: Section 2 covers timing-safe comparison, rotation with dual-secret window, never-transmit rule
- ISC-5: IFTTT trigger@applet.ifttt.com mechanism with sender-match-only auth noted
- ISC-6: Zapier random @zapiermail.com address as obscurity-based auth documented
- ISC-7: GitHub Actions no-email-trigger noted; GitLab pipeline trigger tokens documented
- ISC-8: Mailgun HMAC-SHA256 webhook verification with signing key distinction and code example
- ISC-9: PopExe, Laravel Mailbox, Chainmail, Cloudflare Email Workers documented with repo links
- ISC-10: Three options documented: SwiftOTP+Shortcuts, Scriptable JS runtime, built-in iOS authenticator
- ISC-11: iOS 18 Authenticate action, iOS 16.4 Lock Screen action, RoutineHub shortcut documented
- ISC-12: Four Alfred workflows documented with repos: alfred-totp, gauth, mfa-workflow, ente-auth
- ISC-13: Tasker JavaScriptlet with pure-JS HMAC, AndOTP broadcast integration documented
- ISC-14: Tasker biometric plugin, Android Keystore+TEE biometric binding documented
- ISC-15: SPF/DKIM/DMARC explained with best practices and limitation (no protection against compromised accounts)
- ISC-16: Nonce tracking, timestamp enforcement, sequence numbers, Redis implementation with code
- ISC-17: 25+ specific repos, npm packages, and libraries cited throughout report
- ISC-18: Three-scenario strategic framework (simple/moderate/high security) with second-order effects
- ISC-A-1: Every section includes code examples, specific package names, or repo links
