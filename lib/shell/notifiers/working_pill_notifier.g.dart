// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'working_pill_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Returns `true` when the message with [messageId] in [sessionId] has at
/// least one [ToolStatus.running] tool event.
///
/// Because this is a functional provider returning a [bool], Riverpod will
/// only notify [WorkingPill] when the running status actually flips — not
/// on every message content update — so the widget's elapsed-second timer
/// is not disturbed by unrelated message changes.

@ProviderFor(workingPillRunning)
final workingPillRunningProvider = WorkingPillRunningFamily._();

/// Returns `true` when the message with [messageId] in [sessionId] has at
/// least one [ToolStatus.running] tool event.
///
/// Because this is a functional provider returning a [bool], Riverpod will
/// only notify [WorkingPill] when the running status actually flips — not
/// on every message content update — so the widget's elapsed-second timer
/// is not disturbed by unrelated message changes.

final class WorkingPillRunningProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Returns `true` when the message with [messageId] in [sessionId] has at
  /// least one [ToolStatus.running] tool event.
  ///
  /// Because this is a functional provider returning a [bool], Riverpod will
  /// only notify [WorkingPill] when the running status actually flips — not
  /// on every message content update — so the widget's elapsed-second timer
  /// is not disturbed by unrelated message changes.
  WorkingPillRunningProvider._({
    required WorkingPillRunningFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'workingPillRunningProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$workingPillRunningHash();

  @override
  String toString() {
    return r'workingPillRunningProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    final argument = this.argument as (String, String);
    return workingPillRunning(ref, argument.$1, argument.$2);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is WorkingPillRunningProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$workingPillRunningHash() =>
    r'84b7ec321806532eebf9592cd24fce986397d81f';

/// Returns `true` when the message with [messageId] in [sessionId] has at
/// least one [ToolStatus.running] tool event.
///
/// Because this is a functional provider returning a [bool], Riverpod will
/// only notify [WorkingPill] when the running status actually flips — not
/// on every message content update — so the widget's elapsed-second timer
/// is not disturbed by unrelated message changes.

final class WorkingPillRunningFamily extends $Family
    with $FunctionalFamilyOverride<bool, (String, String)> {
  WorkingPillRunningFamily._()
    : super(
        retry: null,
        name: r'workingPillRunningProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Returns `true` when the message with [messageId] in [sessionId] has at
  /// least one [ToolStatus.running] tool event.
  ///
  /// Because this is a functional provider returning a [bool], Riverpod will
  /// only notify [WorkingPill] when the running status actually flips — not
  /// on every message content update — so the widget's elapsed-second timer
  /// is not disturbed by unrelated message changes.

  WorkingPillRunningProvider call(String sessionId, String messageId) =>
      WorkingPillRunningProvider._(
        argument: (sessionId, messageId),
        from: this,
      );

  @override
  String toString() => r'workingPillRunningProvider';
}
