// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_pr_actions.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Command notifier mediating every GitHub-API call the "Create PR"
/// dialog flow makes. Widgets never touch [GitHubRepository] or
/// [SecureStorage] directly — they go through here so the
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
/// dialog flow makes. Widgets never touch [GitHubRepository] or
/// [SecureStorage] directly — they go through here so the
/// GitHub PAT never crosses the widget layer.
///
/// ### Security
///
/// Only `e.runtimeType` is ever logged. A full `$e` could invoke
/// `DioException.toString()`, which serialises request headers and would
/// leak the `Authorization: Bearer <PAT>` token. Same discipline as
/// [PrCardNotifier]; see `macos/Runner/README.md`.
final class CreatePrActionsProvider extends $AsyncNotifierProvider<CreatePrActions, void> {
  /// Command notifier mediating every GitHub-API call the "Create PR"
  /// dialog flow makes. Widgets never touch [GitHubRepository] or
  /// [SecureStorage] directly — they go through here so the
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
}

String _$createPrActionsHash() => r'a15370145b53f3be2533a732a8bbc2051a9d626b';

/// Command notifier mediating every GitHub-API call the "Create PR"
/// dialog flow makes. Widgets never touch [GitHubRepository] or
/// [SecureStorage] directly — they go through here so the
/// GitHub PAT never crosses the widget layer.
///
/// ### Security
///
/// Only `e.runtimeType` is ever logged. A full `$e` could invoke
/// `DioException.toString()`, which serialises request headers and would
/// leak the `Authorization: Bearer <PAT>` token. Same discipline as
/// [PrCardNotifier]; see `macos/Runner/README.md`.

abstract class _$CreatePrActions extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element as $ClassProviderElement<AnyNotifier<AsyncValue<void>, void>, AsyncValue<void>, Object?, Object?>;
    element.handleCreate(ref, build);
  }
}
