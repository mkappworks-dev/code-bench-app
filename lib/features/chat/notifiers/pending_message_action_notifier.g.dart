// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_message_action_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PendingMessageActionNotifier)
final pendingMessageActionProvider = PendingMessageActionNotifierFamily._();

final class PendingMessageActionNotifierProvider
    extends $NotifierProvider<PendingMessageActionNotifier, MessageAction?> {
  PendingMessageActionNotifierProvider._({
    required PendingMessageActionNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'pendingMessageActionProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$pendingMessageActionNotifierHash();

  @override
  String toString() {
    return r'pendingMessageActionProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  PendingMessageActionNotifier create() => PendingMessageActionNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MessageAction? value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<MessageAction?>(value));
  }

  @override
  bool operator ==(Object other) {
    return other is PendingMessageActionNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$pendingMessageActionNotifierHash() => r'8dbd64cf780a13456222cd9cb3cb8e37571c82a9';

final class PendingMessageActionNotifierFamily extends $Family
    with $ClassFamilyOverride<PendingMessageActionNotifier, MessageAction?, MessageAction?, MessageAction?, String> {
  PendingMessageActionNotifierFamily._()
    : super(
        retry: null,
        name: r'pendingMessageActionProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  PendingMessageActionNotifierProvider call(String sessionId) =>
      PendingMessageActionNotifierProvider._(argument: sessionId, from: this);

  @override
  String toString() => r'pendingMessageActionProvider';
}

abstract class _$PendingMessageActionNotifier extends $Notifier<MessageAction?> {
  late final _$args = ref.$arg as String;
  String get sessionId => _$args;

  MessageAction? build(String sessionId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<MessageAction?, MessageAction?>;
    final element =
        ref.element
            as $ClassProviderElement<AnyNotifier<MessageAction?, MessageAction?>, MessageAction?, Object?, Object?>;
    element.handleCreate(ref, () => build(_$args));
  }
}
