import 'package:freezed_annotation/freezed_annotation.dart';

part 'tool_event.freezed.dart';
part 'tool_event.g.dart';

/// Lifecycle of a single tool-use invocation.
///
/// Terminal states: [success], [error], [cancelled]. Only [running] shows
/// a spinner in the UI.
enum ToolStatus { running, success, error, cancelled }

/// Origin of a tool event. [agentLoop] is the default (events emitted by
/// Code Bench's own agent loop for custom providers). [cliTransport] is
/// set when the event comes from a CLI-transport datasource (e.g. Claude
/// Code CLI), where Code Bench is rendering receipts of another agent's
/// tool-use rather than driving tools directly.
enum ToolEventSource { agentLoop, cliTransport }

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
    @Default(ToolEventSource.agentLoop) ToolEventSource source,
  }) = _ToolEvent;

  factory ToolEvent.fromJson(Map<String, dynamic> json) => _$ToolEventFromJson(json);
}
