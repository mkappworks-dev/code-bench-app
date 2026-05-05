// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_pr_actions.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Command notifier owning the entire "Create PR" workflow: AI title/body
/// generation, GitHub preflight (token, branch, remote, branch list), and
/// the final create-PR API call. Widgets never touch [GitHubRepository] or
/// [SecureStorage] directly — they go through here so the GitHub PAT never
/// crosses the widget layer.
///
/// ### Security
///
/// Only `e.runtimeType` is ever logged. A full `$e` could invoke
/// `DioException.toString()`, which serialises request headers and would
/// leak the `Authorization: Bearer <PAT>` token. Same discipline as
/// [PrCardNotifier]; see `macos/Runner/README.md`.

@ProviderFor(CreatePrActions)
final createPrActionsProvider = CreatePrActionsProvider._();

/// Command notifier owning the entire "Create PR" workflow: AI title/body
/// generation, GitHub preflight (token, branch, remote, branch list), and
/// the final create-PR API call. Widgets never touch [GitHubRepository] or
/// [SecureStorage] directly — they go through here so the GitHub PAT never
/// crosses the widget layer.
///
/// ### Security
///
/// Only `e.runtimeType` is ever logged. A full `$e` could invoke
/// `DioException.toString()`, which serialises request headers and would
/// leak the `Authorization: Bearer <PAT>` token. Same discipline as
/// [PrCardNotifier]; see `macos/Runner/README.md`.
final class CreatePrActionsProvider extends $AsyncNotifierProvider<CreatePrActions, void> {
  /// Command notifier owning the entire "Create PR" workflow: AI title/body
  /// generation, GitHub preflight (token, branch, remote, branch list), and
  /// the final create-PR API call. Widgets never touch [GitHubRepository] or
  /// [SecureStorage] directly — they go through here so the GitHub PAT never
  /// crosses the widget layer.
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

String _$createPrActionsHash() => r'bde6ebe808b0522d59d5301e98d955768bcd5967';

/// Command notifier owning the entire "Create PR" workflow: AI title/body
/// generation, GitHub preflight (token, branch, remote, branch list), and
/// the final create-PR API call. Widgets never touch [GitHubRepository] or
/// [SecureStorage] directly — they go through here so the GitHub PAT never
/// crosses the widget layer.
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
