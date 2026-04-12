// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pr_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Manages live state for a single GitHub pull request card.
///
/// Widgets call [refresh] from their poll timer, [approve] and [merge] from
/// button taps — they never touch [GitHubApiService] directly.
///
/// ### Security
/// Only `e.runtimeType` is ever logged. A full `$e` could invoke
/// `DioException.toString()`, which serialises request headers and would
/// leak the `Authorization: Bearer <PAT>` token. See `macos/Runner/README.md`.

@ProviderFor(PrCard)
final prCardProvider = PrCardFamily._();

/// Manages live state for a single GitHub pull request card.
///
/// Widgets call [refresh] from their poll timer, [approve] and [merge] from
/// button taps — they never touch [GitHubApiService] directly.
///
/// ### Security
/// Only `e.runtimeType` is ever logged. A full `$e` could invoke
/// `DioException.toString()`, which serialises request headers and would
/// leak the `Authorization: Bearer <PAT>` token. See `macos/Runner/README.md`.
final class PrCardProvider extends $AsyncNotifierProvider<PrCard, PrCardState> {
  /// Manages live state for a single GitHub pull request card.
  ///
  /// Widgets call [refresh] from their poll timer, [approve] and [merge] from
  /// button taps — they never touch [GitHubApiService] directly.
  ///
  /// ### Security
  /// Only `e.runtimeType` is ever logged. A full `$e` could invoke
  /// `DioException.toString()`, which serialises request headers and would
  /// leak the `Authorization: Bearer <PAT>` token. See `macos/Runner/README.md`.
  PrCardProvider._({required PrCardFamily super.from, required (String, String, int) super.argument})
    : super(
        retry: null,
        name: r'prCardProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$prCardHash();

  @override
  String toString() {
    return r'prCardProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  PrCard create() => PrCard();

  @override
  bool operator ==(Object other) {
    return other is PrCardProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$prCardHash() => r'ccf1714ef1890527fc9d0c168abaaac40d06a62d';

/// Manages live state for a single GitHub pull request card.
///
/// Widgets call [refresh] from their poll timer, [approve] and [merge] from
/// button taps — they never touch [GitHubApiService] directly.
///
/// ### Security
/// Only `e.runtimeType` is ever logged. A full `$e` could invoke
/// `DioException.toString()`, which serialises request headers and would
/// leak the `Authorization: Bearer <PAT>` token. See `macos/Runner/README.md`.

final class PrCardFamily extends $Family
    with
        $ClassFamilyOverride<
          PrCard,
          AsyncValue<PrCardState>,
          PrCardState,
          FutureOr<PrCardState>,
          (String, String, int)
        > {
  PrCardFamily._()
    : super(
        retry: null,
        name: r'prCardProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Manages live state for a single GitHub pull request card.
  ///
  /// Widgets call [refresh] from their poll timer, [approve] and [merge] from
  /// button taps — they never touch [GitHubApiService] directly.
  ///
  /// ### Security
  /// Only `e.runtimeType` is ever logged. A full `$e` could invoke
  /// `DioException.toString()`, which serialises request headers and would
  /// leak the `Authorization: Bearer <PAT>` token. See `macos/Runner/README.md`.

  PrCardProvider call(String owner, String repo, int prNumber) =>
      PrCardProvider._(argument: (owner, repo, prNumber), from: this);

  @override
  String toString() => r'prCardProvider';
}

/// Manages live state for a single GitHub pull request card.
///
/// Widgets call [refresh] from their poll timer, [approve] and [merge] from
/// button taps — they never touch [GitHubApiService] directly.
///
/// ### Security
/// Only `e.runtimeType` is ever logged. A full `$e` could invoke
/// `DioException.toString()`, which serialises request headers and would
/// leak the `Authorization: Bearer <PAT>` token. See `macos/Runner/README.md`.

abstract class _$PrCard extends $AsyncNotifier<PrCardState> {
  late final _$args = ref.$arg as (String, String, int);
  String get owner => _$args.$1;
  String get repo => _$args.$2;
  int get prNumber => _$args.$3;

  FutureOr<PrCardState> build(String owner, String repo, int prNumber);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<PrCardState>, PrCardState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<PrCardState>, PrCardState>,
              AsyncValue<PrCardState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args.$1, _$args.$2, _$args.$3));
  }
}
