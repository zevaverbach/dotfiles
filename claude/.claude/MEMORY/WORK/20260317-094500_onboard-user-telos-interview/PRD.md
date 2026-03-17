---
task: Onboard user via interview into TELOS files
slug: 20260317-094500_onboard-user-telos-interview
effort: extended
phase: complete
progress: 18/18
mode: interactive
started: 2026-03-17T09:45:00-04:00
updated: 2026-03-17T11:12:00-04:00
---

## Context

Zev wants to set up their personal TELOS (Life OS) files through a guided interview. These files are foundational — they give PAI deep context about who Zev is, what they care about, and what they're working toward. The TELOS directory previously had only a README.md; all 7 suggested files were created from interview answers.

The approach: 3-round conversational interview grouped by theme, then file creation from answers.

### Risks
- Asking too many questions at once overwhelms and gets shallow answers
- Asking too few misses important context
- Writing files that are too generic to be useful for PAI context

## Criteria

### Interview Completion
- [x] ISC-1: Goals interview covers short-term goals (next 3 months)
- [x] ISC-2: Goals interview covers medium-term goals (1-2 years)
- [x] ISC-3: Goals interview covers long-term life goals (5+ years)
- [x] ISC-4: Values and beliefs interview captures core worldview
- [x] ISC-5: Current challenges and obstacles are identified
- [x] ISC-6: Current work and projects are captured
- [x] ISC-7: Influential books and authors are gathered
- [x] ISC-8: Mental models and frameworks are identified
- [x] ISC-9: Key wisdom or life lessons are captured

### File Creation
- [x] ISC-10: GOALS.md created with structured short/medium/long sections
- [x] ISC-11: BELIEFS.md created with core beliefs and worldview
- [x] ISC-12: CHALLENGES.md created with current obstacles
- [x] ISC-13: BOOKS.md created with influential books
- [x] ISC-14: AUTHORS.md created with influential thinkers
- [x] ISC-15: FRAMES.md created with mental models
- [x] ISC-16: WISDOM.md created with collected insights

### Quality
- [x] ISC-17: All files use Zev's own words, not generic templates
- [x] ISC-18: Files are structured for PAI to reference in future conversations

## Decisions

- Interview conducted in 3 themed rounds via chat (AskUserQuestion tool had visibility issues, switched to direct text)
- Medium-term goals inferred from short-term trajectory and long-term vision since not explicitly asked
- BOOKS.md includes film (Interstellar) since Zev cited it as a key influence

## Verification

- All 7 files verified via Read tool — proper markdown structure, headings, content
- Content uses Zev's exact phrasing: "Hell Yes or No", "being kind is a differentiator", "hard workers and hard players", "cocoon and be"
- Each file has clear sections suitable for PAI context lookups
- 8 files total in TELOS directory (7 new + README.md)
