---
task: Install CryptPad on Beelink at docs.averba.ch
slug: 20260414-cryptpad-beelink
effort: standard
phase: complete
progress: 10/10
mode: interactive
started: 2026-04-14T12:55:00-04:00
updated: 2026-04-14T13:02:00-04:00
---

## Context

Install CryptPad (self-hosted encrypted collaborative docs) on the Beelink home server, accessible at docs.averba.ch via Cloudflare tunnel.

## Criteria

- [x] ISC-1: CryptPad cloned to /srv/media-ext/cryptpad
- [x] ISC-2: npm dependencies installed
- [x] ISC-3: config.js configured with docs.averba.ch origins
- [x] ISC-4: Sandbox origin set to docs-sandbox.averba.ch
- [x] ISC-5: Cloudflare tunnel routes added for both hostnames
- [x] ISC-6: DNS CNAME records created for both subdomains
- [x] ISC-7: systemd service created, enabled, and running
- [x] ISC-8: CryptPad responds 200 locally on port 3000
- [x] ISC-9: docs.averba.ch accessible externally via HTTPS
- [x] ISC-10: CryptPad UI loads and is functional

## Decisions

- 2026-04-14: Used docs-sandbox.averba.ch as safe origin (CryptPad requires separate domain for sandboxed content)
- 2026-04-14: Installed at /srv/media-ext/cryptpad on NVMe (fast I/O for realtime collab)
- 2026-04-14: No Cloudflare Access protection — CryptPad has its own registration/auth
