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
/// and mint a time-based id so the widget tree stays stable on rebuild.
///
/// NOTE: intentionally forgiving — one-release bridge.
/// Remove after the next app release if deemed safe.
Map<String, dynamic> _normalizeLegacyToolEventJson(Map<String, dynamic> json) {
  final out = Map<String, dynamic>.of(json);
  out['id'] ??= _legacyId();
  if (out['status'] == null) {
    final hasOutput = out['output'] != null;
    final hasDuration = out['durationMs'] != null;
    out['status'] = switch ((hasOutput, hasDuration)) {
      (true, _) => 'success',
      (false, true) => 'error', // finished but no output — treat as error
      (false, false) => 'running', // truly unknown — leave spinner
    };
  }
  return out;
}

// Uses a time-based id rather than pulling in the `uuid` package —
// legacy ids never round-trip to a provider, so collision resistance
// is overkill.
String _legacyId() {
  final now = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
  return 'legacy-$now';
}
