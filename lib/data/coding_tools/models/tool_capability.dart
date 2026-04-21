// lib/data/coding_tools/models/tool_capability.dart

/// Declarative tag describing the side-effect surface of a [Tool].
/// Drives [ToolRegistry]'s permission-aware filtering.
///
/// - [readOnly]: reads filesystem or in-memory state only. Always allowed.
/// - [mutatingFiles]: creates, overwrites, or edits files in the project.
/// - [shell]: spawns a subprocess. (Reserved for Phase 5 — not used yet.)
/// - [network]: makes HTTP or socket I/O. (Reserved for Phase 9 — not used yet.)
enum ToolCapability { readOnly, mutatingFiles, shell, network }
