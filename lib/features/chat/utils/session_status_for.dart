import '../widgets/session_status_dot.dart';

SessionStatus sessionStatusFor({
  required bool isStreaming,
  required bool hasPendingPermission,
  required bool hasPendingQuestion,
  required bool lastTurnFailed,
}) {
  if (isStreaming) return SessionStatus.streaming;
  if (hasPendingPermission || hasPendingQuestion) return SessionStatus.awaiting;
  if (lastTurnFailed) return SessionStatus.errored;
  return SessionStatus.idle;
}
