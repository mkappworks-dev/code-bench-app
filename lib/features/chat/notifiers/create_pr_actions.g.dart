// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_pr_actions.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Command notifier mediating every GitHub-API call the "Create PR"
/// dialog flow makes. Widgets never touch [GitHubApiService] or
/// [SecureStorageSource] directly — they go through here so the
/// GitHub PAT never crosses the widget layer.
///
/// ### Security
///
/// Only `e.runtimeType` is ever logged. A full `$e` could invoke
/// `DioException.toString()`, which serialises request headers and would
/// leak the `Authorization: Bearer <PAT>` token. Same discipline as
/// [PrCardNotifier]; see `macos/Runner/README.md`.

@ProviderFor(CreatePrActions)
final createPrActionsProvider = CreatePrActionsProvider._();

/// Command notifier mediating every GitHub-API call the "Create PR"
/// dialog flow makes. Widgets never touch [GitHubApiService] or
/// [SecureStorageSource] directly — they go through here so the
/// GitHub PAT never crosses the widget layer.
///
/// ### Security
///
/// Only `e.runtimeType` is ever logged. A full `$e` could invoke
/// `DioException.toString()`, which serialises request headers and would
/// leak the `Authorization: Bearer <PAT>` token. Same discipline as
/// [PrCardNotifier]; see `macos/Runner/README.md`.
final class CreatePrActionsProvider extends $NotifierProvider<CreatePrActions, void> {
  /// Command notifier mediating every GitHub-API call the "Create PR"
  /// dialog flow makes. Widgets never touch [GitHubApiService] or
  /// [SecureStorageSource] directly — they go through here so the
  /// GitHub PAT never crosses the widget layer.
  ///
  /// ### Security
  ///
  /// Only `e.runtimeType` is ever logged. A full `$e` could invoke
  /// `DioException.toString()`, which serialises request headers and would
  /// leak the `Authorization: Bearer <PAT>` token. Same discipline as
  /// [PrCardNotifier]; see `macos/Runner/README.md`.
  CreatePrActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'createPrActionsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$createPrActionsHash();

  @$internal
  @override
  CreatePrActions create() => CreatePrActions();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<void>(value));
  }
}

String _$createPrActionsHash() => r'cfeac02f291e07579a51ef0dec63396df84593f6';

/// Command notifier mediating every GitHub-API call the "Create PR"
/// dialog flow makes. Widgets never touch [GitHubApiService] or
/// [SecureStorageSource] directly — they go through here so the
/// GitHub PAT never crosses the widget layer.
///
/// ### Security
///
/// Only `e.runtimeType` is ever logged. A full `$e` could invoke
/// `DioException.toString()`, which serialises request headers and would
/// leak the `Authorization: Bearer <PAT>` token. Same discipline as
/// [PrCardNotifier]; see `macos/Runner/README.md`.

abstract class _$CreatePrActions extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element = ref.element as $ClassProviderElement<AnyNotifier<void, void>, void, Object?, Object?>;
    element.handleCreate(ref, build);
  }
}
