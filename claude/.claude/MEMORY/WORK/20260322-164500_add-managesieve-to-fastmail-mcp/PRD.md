---
task: Add ManageSieve filter support to Fastmail MCP
slug: 20260322-164500_add-managesieve-to-fastmail-mcp
effort: extended
phase: verify
progress: 18/18
mode: interactive
started: 2026-03-22T16:45:00-04:00
updated: 2026-03-22T16:46:00-04:00
---

## Context

Zev's fastmail-mcp server currently supports JMAP (mail) and CalDAV (calendars). He wants to add ManageSieve (RFC 5804) as a third protocol backend to manage email filter rules — specifically to create rules like "move Chase emails to Notifications and skip inbox."

The ManageSieve protocol runs over TLS on sieve.fastmail.com:4190, uses SASL PLAIN auth with app passwords (credentials already in config), and supports ~10 commands. No npm ManageSieve client libraries exist — we'll write a thin client using Node.js net/tls modules.

Key architectural constraint: Fastmail uses a **single active script** model. The MCP tools should abstract individual rules while managing the underlying script composition.

**Not requested:** JMAP-based sieve approach, Sieve script parser/builder library, vacation responder support.

### Risks
- TLS upgrade (STARTTLS) may fail if Fastmail requires specific SNI or TLS options
- App password scope may not cover ManageSieve (only JMAP/CalDAV tested)
- Multi-line script content with embedded quotes could break response parsing
- Idle connection timeouts → using connect-per-call pattern to avoid

### Risks
- Fastmail may require STARTTLS before PLAIN auth — must handle TLS upgrade correctly
- Modifying the active sieve script could break existing rules set via Fastmail's web UI
- Single active script model means we need to parse/merge rules carefully
- TLS connection may have different certificate requirements than JMAP/CalDAV

## Criteria

- [x] ISC-1: ManageSieve client connects to sieve.fastmail.com:4190
- [x] ISC-2: ManageSieve client upgrades connection via STARTTLS
- [x] ISC-3: ManageSieve client authenticates via SASL PLAIN
- [x] ISC-4: ManageSieve client parses server OK/NO/BYE responses correctly
- [x] ISC-5: ManageSieve client handles quoted string responses
- [x] ISC-6: ManageSieve client handles literal {size+} responses
- [x] ISC-7: Config exports sieve settings using existing credentials
- [x] ISC-8: sieve_list_scripts tool returns script names with active flag
- [x] ISC-9: sieve_get_script tool returns script content by name
- [x] ISC-10: sieve_put_script tool uploads script content by name
- [x] ISC-11: sieve_set_active tool activates a named script
- [x] ISC-12: sieve_delete_script tool removes a script by name
- [x] ISC-13: sieve_check_script tool validates script syntax without saving
- [x] ISC-14: Tool schemas defined in src/tools/sieve-tools.ts with Zod
- [x] ISC-15: Tool handlers implemented in src/sieve/handlers.ts
- [x] ISC-16: All sieve tools registered in src/index.ts
- [x] ISC-17: ManageSieve client connects in parallel with JMAP and CalDAV at startup
- [x] ISC-18: Project builds successfully with npm run build
- [x] ISC-A-1: Anti: existing JMAP and CalDAV tools unchanged
- [x] ISC-A-2: Anti: no new runtime dependencies added beyond Node.js built-ins
