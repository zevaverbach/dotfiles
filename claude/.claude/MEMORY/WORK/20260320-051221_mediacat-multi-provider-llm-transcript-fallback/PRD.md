---
task: Add multi-provider LLM and transcript fallback to mediacat
slug: 20260320-051221_mediacat-multi-provider-llm-transcript-fallback
effort: advanced
phase: complete
progress: 28/28
mode: interactive
started: 2026-03-20T05:12:21Z
updated: 2026-03-20T05:12:48Z
---

## Context

Mediacat (`mcat`) is a Go CLI that summarizes YouTube videos, podcasts, and audio files using AI. Currently hardcoded to Claude (Anthropic) as LLM provider. Two features requested:

1. **Multi-provider LLM support** — Add OpenAI and Gemini as alternative providers, selectable via `LLM_PROVIDER` env var. Uses raw `net/http` (no SDK deps). Must preserve backward compat with existing `CLAUDE_*` env vars.

2. **YouTube transcript fallback** — When yt-dlp subtitle extraction fails, fall back to `youtube_transcript_api` Python CLI. Cascade: yt-dlp → youtube_transcript_api with lang → without lang → error.

### Key constraints
- 5 places instantiate `ClaudeClient` directly: `cmd/sum.go`, `cmd/ask.go`, `cmd/cat.go` (2x), `cmd/retitle.go`
- `pipeline.Runner.Summarizer` is typed as `*api.ClaudeClient` (concrete), not `api.Summarizer` (interface)
- `ask.Session.client` is typed as `*api.ClaudeClient` (concrete) — uses `Query()` method not on `Summarizer` interface
- `titlefix.SuggestTitle` takes `*api.ClaudeClient` directly
- Existing `Summarizer` interface in `api/anthropic.go` has 3 methods but no `Query()` — need to extend or create new interface

### Risks
- `Query()` method is only on ClaudeClient, not on Summarizer interface — need a broader interface
- `ask.Session` references `client.QAModel` field directly for spinner display
- `IsBadSummary` is a package-level function, not method — safe

## Criteria

### Feature 1: Multi-Provider LLM

- [x] ISC-1: Config struct has LLMProvider field loaded from LLM_PROVIDER env var
- [x] ISC-2: Config struct has LLMModel field loaded from LLM_MODEL env var
- [x] ISC-3: Config struct has GeminiAPIKey field loaded from GEMINI_API_KEY env var
- [x] ISC-4: LLM interface defined with Summarize, SuggestTags, SuggestTitle, Query methods
- [x] ISC-5: ClaudeClient implements LLM interface (existing code, no changes needed)
- [x] ISC-6: OpenAI LLM client implements LLM interface using chat completions API
- [x] ISC-7: OpenAI client uses Authorization Bearer header auth pattern
- [x] ISC-8: OpenAI client defaults to gpt-4o-mini model
- [x] ISC-9: Gemini LLM client implements LLM interface using generateContent API
- [x] ISC-10: Gemini client uses URL query param auth pattern
- [x] ISC-11: Gemini client defaults to gemini-2.0-flash model
- [x] ISC-12: Factory function creates correct client based on LLMProvider config value
- [x] ISC-13: Factory returns ClaudeClient when LLM_PROVIDER is empty or "claude"
- [x] ISC-14: Existing CLAUDE_SUMMARY_MODEL env vars still work when provider is claude
- [x] ISC-15: Pipeline Runner.Summarizer field type changed to LLM interface
- [x] ISC-16: ask.Session.client field type changed to LLM interface
- [x] ISC-17: titlefix.SuggestTitle accepts LLM interface instead of concrete ClaudeClient
- [x] ISC-18: All 5 ClaudeClient instantiation sites use factory function instead
- [x] ISC-19: Doctor command shows LLM provider and model configuration

### Feature 2: YouTube Transcript Fallback

- [x] ISC-20: Config has YTTranscriptFallback bool field (default true via YT_TRANSCRIPT_FALLBACK)
- [x] ISC-21: Config has YTTranscriptLang string field (default "en" via YT_TRANSCRIPT_LANG)
- [x] ISC-22: Fallback function shells out to youtube_transcript_api CLI
- [x] ISC-23: Fallback extracts video ID from YouTube URL
- [x] ISC-24: Fallback parses double-nested JSON array output to plain text
- [x] ISC-25: DownloadSubtitles tries youtube_transcript_api when yt-dlp fails
- [x] ISC-26: Second fallback attempt omits --languages flag
- [x] ISC-27: Doctor command shows youtube_transcript_api install status
- [x] ISC-28: Doctor command shows fallback configuration

### Anti-criteria

- [x] ISC-A1: No bash/python scripts in repo root modified
- [x] ISC-A2: No external SDK dependencies added to go.mod
- [x] ISC-A3: No changes to storage format or catalog/TUI behavior

## Decisions

## Verification
