---
capture_type: LEARNING
timestamp: 2026-03-22 09:05:51 PST
rating: 1
source: explicit
auto_captured: true
tags: [low-rating, improvement-opportunity]
---

# Low Rating Captured: 1/10

**Date:** 2026-03-22
**Rating:** 1/10
**Detection Method:** Explicit Rating


---

## Context

It's your own repo at `/Users/zev/repos/fastmail-mcp` (zevaverbach/fastmail-mcp). Well-structured TypeScript MCP server — 12 mail tools + 8 calendar tools.

**The pattern for adding tools is clean:**
1. Schema in `src/tools/mail-tools.ts`
2. Handler in `src/jmap/mail.ts`
3. Registration in `src/index.ts`
4. `npm run build`

**The catch with Sieve:** Fastmail's JMAP API doesn't expose the standard `urn:ietf:params:jmap:sieve` extension. However, Fastmail *does* support Sieve — they have a **ManageSieve** protocol endpoint at `sieve.fastmail.com:4190`. We could use that, or there may be an undocumented JMAP capability for it.

Before I start planning the implementation — a question for you, Zev:

**What approach do you think makes sense here?** Two options:

1. **ManageSieve protocol** — standard, well-documented RFC 5804. We'd add a new client alongside JMAP and CalDAV. More work but robust.
2. **JMAP-based approach** — Fastmail may expose sieve management through their JMAP API (they have custom extensions like `https://www.fastmail.com/dev/...`). Less code if it exists, but possibly undocumented.

Either way we'd expose tools like `mail_list_rules`, `mail_create_rule`, `mail_delete_rule`. Which direction appeals to you, or should I research what Fastmail actually supports first?

🗣️ Vennari: Your own MCP repo — clean pattern, sieve support is feasible to add

---

## Improvement Notes

This response was rated 1/10 by Zev. Use this as an improvement opportunity.

---
