// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Loads API keys on first watch and exposes save/delete actions.
/// Auto-disposes when the settings screen is not in view.

@ProviderFor(ApiKeysNotifier)
final apiKeysProvider = ApiKeysNotifierProvider._();

/// Loads API keys on first watch and exposes save/delete actions.
/// Auto-disposes when the settings screen is not in view.
final class ApiKeysNotifierProvider extends $AsyncNotifierProvider<ApiKeysNotifier, ApiKeysNotifierState> {
  /// Loads API keys on first watch and exposes save/delete actions.
  /// Auto-disposes when the settings screen is not in view.
  ApiKeysNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'apiKeysProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$apiKeysNotifierHash();

  @$internal
  @override
  ApiKeysNotifier create() => ApiKeysNotifier();
}

String _$apiKeysNotifierHash() => r'f386d86f69bc5042362be92f8dd565dc7bd07fa1';

/// Loads API keys on first watch and exposes save/delete actions.
/// Auto-disposes when the settings screen is not in view.

abstract class _$ApiKeysNotifier extends $AsyncNotifier<ApiKeysNotifierState> {
  FutureOr<ApiKeysNotifierState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<ApiKeysNotifierState>, ApiKeysNotifierState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<ApiKeysNotifierState>, ApiKeysNotifierState>,
              AsyncValue<ApiKeysNotifierState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
