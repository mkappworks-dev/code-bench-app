# WebFetch Tool — Design Spec

**Date:** 2026-04-23
**Phase:** 6 of the Agentic Executor Roadmap
**Status:** Approved — ready for implementation

---

## Goal

Add a `web_fetch` tool that lets the AI model fetch and read public web page content during an agentic session. The tool strips HTML to readable text, blocks private-network addresses, and requires explicit user approval for every request.

---

## Decisions Log

| Question | Decision | Rationale |
|---|---|---|
| Content size cap | 100,000 chars | Matches Claude Code's model-facing cap; generous enough for real doc pages |
| Authenticated requests | Not supported (YAGNI) | No concrete use case; Claude Code also has no custom-header support |
| Non-HTML text (JSON, XML, plain text) | Return as-is, capped | Consistent with Claude Code behaviour |
| Binary content | Error with MIME type | No useful representation; clear error guides the model |
| Redirect handling | Follow all, up to 5 hops | Simpler than Claude Code's cross-host redirect signal; per-request approval mitigates SSRF-via-redirect risk |
| SSRF protection | Local RFC-1918 string check | No remote `domain_info` API available; per-request user approval is the primary safety gate |
| HTML conversion approach | Inline in datasource | Follows `BashDatasource`/`GrepDatasource` pattern; no second caller justifies extraction |

---

## Architecture

Follows the datasource-injection pattern established by `BashTool` and `GrepTool`. The interface boundary is a single method: `fetch(url:) → String`.

### Files

| Action | Path | Purpose |
|---|---|---|
| Create | `lib/data/web_fetch/datasource/web_fetch_datasource.dart` | Abstract interface |
| Create | `lib/data/web_fetch/datasource/web_fetch_datasource_dio.dart` | Dio impl: SSRF, HTTP, HTML→text, cap |
| Create | `lib/services/coding_tools/tools/web_fetch_tool.dart` | `WebFetchTool extends Tool` + `@riverpod` provider |
| Modify | `lib/services/coding_tools/tool_registry.dart` | `requiresPrompt` gates `network`; adds tool to built-ins |
| Modify | `lib/services/agent/agent_service.dart` | `_summaryFor` web_fetch case |
| Modify | `lib/features/chat/widgets/permission_request_card.dart` | Always-visible URL code block |
| Modify | `pubspec.yaml` | Add `html: ^0.15.4` |

---

## Data Flow

```
Model emits: web_fetch { url: "https://..." }
        ↓
AgentService._summaryFor
  → truncates URL at 100 chars for display
        ↓
ToolRegistry.requiresPrompt
  → ToolCapability.network → always true
        ↓
Permission card shown (always-visible URL code block, Deny / Allow)
        ↓  (user approves)
WebFetchTool.execute
  1. Validate url arg — non-empty string
  2. Call datasource.fetch(url:)
        ↓
WebFetchDatasourceDio.fetch
  1. Uri.parse — reject non-http/https scheme
  2. isPrivateHost(uri.host) — reject RFC-1918 / loopback
  3. Dio GET
       connectTimeout: 15 s
       receiveTimeout: 30 s
       followRedirects: true, maxRedirects: 5
       Accept: text/html, text/plain, application/json, */*
       User-Agent: CodeBench/1.0 (web fetch)
  4. Content-type branch:
       text/html              → htmlToText(body) → 100k char cap
       text/*, app/json,
       app/*+json, app/xml,
       app/*+xml              → raw string       → 100k char cap
       anything else          → ArgumentError("web_fetch only supports text
                                content. The URL returned <mime-type>.")
  5. Return capped string
        ↓
CodingToolResult.success(content)
  → stored in ToolEvent, sent on wire via existing AgentService pipeline
```

---

## SSRF Protection

String-only matching against the parsed `uri.host` — no DNS resolution.

| Pattern | Blocked |
|---|---|
| `localhost` | yes |
| `[::1]`, `::1` | yes |
| `127.x.x.x` | yes (127.0.0.0/8) |
| `10.x.x.x` | yes (10.0.0.0/8) |
| `192.168.x.x` | yes (192.168.0.0/16) |
| `172.16.x.x` – `172.31.x.x` | yes (172.16.0.0/12) |
| All other dotted-decimal | no |
| Public hostnames (e.g. `example.com`) | no |

**Known gap:** hostname aliases for internal hosts (e.g. `db.internal`) are not blocked. Acceptable for v1 — per-request user approval is the primary safety gate.

---

## HTML-to-Text Conversion

The `html` Dart package parses the DOM. Noise elements are removed before traversal: `script`, `style`, `nav`, `footer`, `header`, `noscript`, `iframe`.

**Conversion rules:**

| Element | Output |
|---|---|
| `h1` | `\n\n# text\n\n` |
| `h2` | `\n\n## text\n\n` |
| `h3` | `\n\n### text\n\n` |
| `h4`–`h6` | `\n\n#### text\n\n` |
| `p`, `div`, `section`, `article`, `main` | `\ntext\n` |
| `br` | `\n` |
| `li` | `\n- text` |
| `a` (href + text both non-empty) | `[text](href)` |
| `pre` | `\n```\ntext\n```\n` |
| `code` | `` `text` `` |
| `strong`, `b` | `**text**` |
| `em`, `i` | `_text_` |
| `hr` | `\n---\n` |
| all others | recurse into children |

Intentionally omits: tables, image alt-text, footnotes. Goal is readable prose for the model, not a lossless HTML→Markdown roundtrip.

**Cap:** after conversion, truncate to 100,000 chars and append `\n[Content truncated at 100k characters]`.

---

## Error Handling

No new `*Actions` notifier or `*Failure` type. Errors surface as `CodingToolResult.error` strings through the existing `AgentService` → `ToolEvent.error` → chat UI pipeline.

| Condition | Tool result message |
|---|---|
| `url` arg missing / empty / non-string | `web_fetch requires a non-empty "url" argument.` |
| Non-http/https scheme | `Only http and https URLs are supported. Got: <scheme>` |
| Private / loopback host | `Fetching private or internal network addresses is not allowed.` |
| Binary content type | `web_fetch only supports text content. The URL returned <mime-type>.` |
| HTTP 4xx / 5xx | `Failed to fetch "<url>": DioException [bad response, statusCode: N]` |
| Network timeout / DNS failure | `Failed to fetch "<url>": <exception message>` |
| User denies permission | `ToolEvent` marked `cancelled` — existing pipeline, no change |

---

## Permission Card

The card gains a `web_fetch` block in `permission_request_card.dart`, parallel to the existing `bash` block:

- Always-visible `Container` with `codeBlockBg` background, showing `request.summary` (the URL) in monospace 11pt via `SelectableText`
- Note below: `"External network requests are always gated."` in `textMuted` 10pt
- No diff / expand section (previewLines is null for web_fetch)
- Deny / Allow buttons unchanged

`_summaryFor` in `AgentService` returns the URL string, truncated at 100 chars with `…` if longer.

---

## Permission Gating

`ToolRegistry.requiresPrompt` is extended with one line:

```dart
if (t.capability == ToolCapability.network) return true;
```

This gates all current and future `network`-capability tools unconditionally, regardless of the session's `ChatPermission` level — matching how `shell` tools are handled.

`visibleTools` is unchanged: `network` tools are hidden in `readOnly` sessions (same as `shell` and `mutatingFiles` tools).

---

## Testing

### `test/data/web_fetch/datasource/web_fetch_datasource_dio_test.dart`

Pure unit tests on the two static methods — no Dio mock, no network:

**`isPrivateHost`**
- Blocks: `localhost`, `[::1]`, `::1`, `127.0.0.1`, `10.0.0.1`, `192.168.1.100`, `172.16.0.1`, `172.31.255.255`
- Allows: `172.32.0.1`, `8.8.8.8`, `example.com`

**`htmlToText`**
- Strips `<script>` and `<style>` content
- Emits `# H1`, `## H2`, `### H3` heading markers
- Emits `[text](url)` for anchors
- Wraps `<pre>` in triple backticks
- Applies 100k char cap with truncation notice

### `test/services/coding_tools/tools/web_fetch_tool_test.dart`

Uses `@GenerateMocks([WebFetchDatasource])` (mockito already in dev_dependencies):

- `name == 'web_fetch'`, `capability == ToolCapability.network`
- Missing / empty / non-string `url` → `CodingToolResultError`
- Valid URL → delegates to datasource, returns `CodingToolResultSuccess`
- Trims whitespace from URL before delegating
- `ArgumentError` from datasource → `CodingToolResultError` with the message
- Any other exception → `CodingToolResultError`

---

## Out of Scope (v1)

- Custom HTTP headers / authentication
- WebSearch (separate roadmap item, deferred)
- PDF parsing
- Image alt-text extraction
- Response caching across turns
- Table preservation in HTML→text conversion
