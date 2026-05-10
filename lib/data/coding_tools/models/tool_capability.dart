/// Declarative tag describing the side-effect surface of a [Tool].
/// Drives [ToolRegistryService]'s permission-aware filtering.
///
/// - [readOnly]: reads filesystem or in-memory state only. Always allowed.
/// - [mutatingFiles]: creates, overwrites, or edits files in the project.
/// - [shell]: spawns a subprocess. (Reserved for Phase 5 — not used yet.)
/// - [network]: makes HTTP or socket I/O. Used by WebFetchTool (Phase 6).
enum ToolCapability { readOnly, mutatingFiles, shell, network }
