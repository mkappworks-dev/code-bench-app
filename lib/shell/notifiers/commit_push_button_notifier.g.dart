// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'commit_push_button_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Returns the `html_url` of the first open PR for [path]'s current branch,
/// or `null` when none exists, the check is still loading, or any error occurs.
/// Used by [commitPushButtonStateProvider] to disable "Create PR" when a PR is
/// already open.

@ProviderFor(existingOpenPrUrl)
final existingOpenPrUrlProvider = ExistingOpenPrUrlFamily._();

/// Returns the `html_url` of the first open PR for [path]'s current branch,
/// or `null` when none exists, the check is still loading, or any error occurs.
/// Used by [commitPushButtonStateProvider] to disable "Create PR" when a PR is
/// already open.

final class ExistingOpenPrUrlProvider extends $FunctionalProvider<AsyncValue<String?>, String?, FutureOr<String?>>
    with $FutureModifier<String?>, $FutureProvider<String?> {
  /// Returns the `html_url` of the first open PR for [path]'s current branch,
  /// or `null` when none exists, the check is still loading, or any error occurs.
  /// Used by [commitPushButtonStateProvider] to disable "Create PR" when a PR is
  /// already open.
  ExistingOpenPrUrlProvider._({required ExistingOpenPrUrlFamily super.from, required String super.argument})
    : super(
        retry: null,
        name: r'existingOpenPrUrlProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$existingOpenPrUrlHash();

  @override
  String toString() {
    return r'existingOpenPrUrlProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<String?> $createElement($ProviderPointer pointer) => $FutureProviderElement(pointer);

  @override
  FutureOr<String?> create(Ref ref) {
    final argument = this.argument as String;
    return existingOpenPrUrl(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ExistingOpenPrUrlProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$existingOpenPrUrlHash() => r'6825f9e15bc5ae7410b965111161e395c2fc4b97';

/// Returns the `html_url` of the first open PR for [path]'s current branch,
/// or `null` when none exists, the check is still loading, or any error occurs.
/// Used by [commitPushButtonStateProvider] to disable "Create PR" when a PR is
/// already open.

final class ExistingOpenPrUrlFamily extends $Family with $FunctionalFamilyOverride<FutureOr<String?>, String> {
  ExistingOpenPrUrlFamily._()
    : super(
        retry: null,
        name: r'existingOpenPrUrlProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Returns the `html_url` of the first open PR for [path]'s current branch,
  /// or `null` when none exists, the check is still loading, or any error occurs.
  /// Used by [commitPushButtonStateProvider] to disable "Create PR" when a PR is
  /// already open.

  ExistingOpenPrUrlProvider call(String path) => ExistingOpenPrUrlProvider._(argument: path, from: this);

  @override
  String toString() => r'existingOpenPrUrlProvider';
}

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

String _$commitPushButtonStateHash() => r'282cc7be8e4b9563ebc43cc7df401bbd222dac22';

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
