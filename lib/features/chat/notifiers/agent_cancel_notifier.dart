import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'agent_cancel_notifier.g.dart';

/// Cooperative cancel flag read by [AgentService] at each tool boundary.
/// Separate from the plain-text stream cancel so both can be flipped by a
/// single stop-button press without coupling their wiring.
@Riverpod(keepAlive: true)
class AgentCancelNotifier extends _$AgentCancelNotifier {
  @override
  bool build() => false;

  void request() => state = true;
  void clear() => state = false;

  /// Stable accessor for closures captured by `ChatStreamService` — `ref.read` would throw after the originating notifier disposes.
  bool get cancelled => state;
}
