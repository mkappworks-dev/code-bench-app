// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'git_actions.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Command notifier that delegates all git write operations to [GitService].
///
/// Widgets never instantiate [GitService] directly — they call methods here
/// instead. Each method is a thin passthrough; error handling and UI feedback
/// (snackbars, spinners) remain the widget's responsibility.

@ProviderFor(GitActions)
final gitActionsProvider = GitActionsProvider._();

/// Command notifier that delegates all git write operations to [GitService].
///
/// Widgets never instantiate [GitService] directly — they call methods here
/// instead. Each method is a thin passthrough; error handling and UI feedback
/// (snackbars, spinners) remain the widget's responsibility.
final class GitActionsProvider extends $NotifierProvider<GitActions, void> {
  /// Command notifier that delegates all git write operations to [GitService].
  ///
  /// Widgets never instantiate [GitService] directly — they call methods here
  /// instead. Each method is a thin passthrough; error handling and UI feedback
  /// (snackbars, spinners) remain the widget's responsibility.
  GitActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'gitActionsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$gitActionsHash();

  @$internal
  @override
  GitActions create() => GitActions();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<void>(value));
  }
}

String _$gitActionsHash() => r'608c70d3b711150c80af22b4113a98afd9e6ec2a';

/// Command notifier that delegates all git write operations to [GitService].
///
/// Widgets never instantiate [GitService] directly — they call methods here
/// instead. Each method is a thin passthrough; error handling and UI feedback
/// (snackbars, spinners) remain the widget's responsibility.

abstract class _$GitActions extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element = ref.element as $ClassProviderElement<AnyNotifier<void, void>, void, Object?, Object?>;
    element.handleCreate(ref, build);
  }
}
