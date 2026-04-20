// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'commit_push_button_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Derives all [CommitPushButton] display flags from live git state,
/// behind-count, and the loaded remote list for [path].

@ProviderFor(commitPushButtonState)
final commitPushButtonStateProvider = CommitPushButtonStateFamily._();

/// Derives all [CommitPushButton] display flags from live git state,
/// behind-count, and the loaded remote list for [path].

final class CommitPushButtonStateProvider
    extends $FunctionalProvider<CommitPushButtonState, CommitPushButtonState, CommitPushButtonState>
    with $Provider<CommitPushButtonState> {
  /// Derives all [CommitPushButton] display flags from live git state,
  /// behind-count, and the loaded remote list for [path].
  CommitPushButtonStateProvider._({required CommitPushButtonStateFamily super.from, required String super.argument})
    : super(
        retry: null,
        name: r'commitPushButtonStateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$commitPushButtonStateHash();

  @override
  String toString() {
    return r'commitPushButtonStateProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<CommitPushButtonState> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  CommitPushButtonState create(Ref ref) {
    final argument = this.argument as String;
    return commitPushButtonState(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CommitPushButtonState value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<CommitPushButtonState>(value));
  }

  @override
  bool operator ==(Object other) {
    return other is CommitPushButtonStateProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$commitPushButtonStateHash() => r'a676ab7b21566e09a203891e0fc7225e59f50da0';

/// Derives all [CommitPushButton] display flags from live git state,
/// behind-count, and the loaded remote list for [path].

final class CommitPushButtonStateFamily extends $Family with $FunctionalFamilyOverride<CommitPushButtonState, String> {
  CommitPushButtonStateFamily._()
    : super(
        retry: null,
        name: r'commitPushButtonStateProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Derives all [CommitPushButton] display flags from live git state,
  /// behind-count, and the loaded remote list for [path].

  CommitPushButtonStateProvider call(String path) => CommitPushButtonStateProvider._(argument: path, from: this);

  @override
  String toString() => r'commitPushButtonStateProvider';
}
