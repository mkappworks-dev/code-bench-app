import 'package:freezed_annotation/freezed_annotation.dart';

part 'tool_event.freezed.dart';
part 'tool_event.g.dart';

/// Lifecycle of a single tool-use invocation.
///
/// Explicit states replace the Phase-6 "infer from field presence" pattern
/// (`durationMs == null && output == null`) that caused the eternal-spinner
/// bug when a tool raised before either field was written.
///
/// Terminal states: [success], [error], [cancelled]. Only [running] shows
/// a spinner in the UI.
enum ToolStatus { running, success, error, cancelled }

@freezed
abstract class ToolEvent with _$ToolEvent {
  const factory ToolEvent({
    /// Stable identity for the emission. Prefer the provider's tool-use
    /// block id when available (Anthropic `tool_use.id`, OpenAI
    /// `tool_call.id`); fall back to a UUID v4. Lets the emitter update a
    /// [running] event into a terminal state without ambiguity when the
    /// model calls the same tool twice in a single turn.
    required String id,
    required String type,
    required String toolName,
    @Default(ToolStatus.running) ToolStatus status,
    @Default({}) Map<String, dynamic> input,
    String? output,
    String? filePath,
    int? durationMs,
    int? tokensIn,
    int? tokensOut,

    /// Short human-readable error summary. Set **only** when [status] is
    /// [ToolStatus.error]. Must not contain secrets — emitters should log
    /// `runtimeType` via `dLog` and pass a scrubbed message here (see the
    /// "no PAT header logging" rule in `macos/Runner/README.md`).
    String? error,
  }) = _ToolEvent;

  factory ToolEvent.fromJson(Map<String, dynamic> json) => _$ToolEventFromJson(_normalizeLegacyToolEventJson(json));
}

/// Pre-processes legacy JSON before delegating to the freezed-generated
/// `_$ToolEventFromJson`. Kept outside the class body so it doesn't
/// appear in the generated freezed surface.
///
/// Legacy tolerance: pre-Phase-10 chat DB rows have no `id` or `status`.
/// The app is not yet released, but local dev databases from Phase 6
/// exist. Infer a plausible status from the old "field presence" rule
/// and mint a unique id so the widget tree stays stable on rebuild.
///
/// NOTE: intentionally forgiving — one-release bridge.
/// Remove after the next app release if deemed safe.
Map<String, dynamic> _normalizeLegacyToolEventJson(Map<String, dynamic> json) {
  final out = Map<String, dynamic>.of(json);
  out['id'] ??= _legacyId();
  if (out['status'] == null) {
    final hasOutput = out['output'] != null;
    final hasDuration = out['durationMs'] != null;
    // Anything terminal (output set OR duration recorded) is assumed
    // success — the charitable default for legitimate empty-output tools
    // like `write_file` or a silent `run_command`. Mis-flagging these as
    // errors (an earlier draft) was misleading on reload and gave the
    // eternal-spinner bug a second guise in the review.
    out['status'] = (hasOutput || hasDuration) ? 'success' : 'running';
  }
  return out;
}

// Process-lifetime counter appended to the micros-epoch timestamp so that
// a batch of legacy rows decoded inside one micro-tick still get unique
// ids. Widget keying (see `ValueKey(event.id)` in `message_bubble.dart`)
// depends on that uniqueness; a time-only id collided under `loadHistory`
// bulk decode. No need for `package:uuid` — legacy ids never round-trip
// to a provider, so only intra-process uniqueness matters.
int _legacyCounter = 0;

String _legacyId() {
  final now = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
  final seq = (_legacyCounter++).toRadixString(36);
  return 'legacy-$now-$seq';
}
