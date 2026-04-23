// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ApiKeysNotifier)
final apiKeysProvider = ApiKeysNotifierProvider._();

final class ApiKeysNotifierProvider extends $AsyncNotifierProvider<ApiKeysNotifier, ApiKeysNotifierState> {
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

String _$apiKeysNotifierHash() => r'2fe9936fe6ec6ef6866a767db40600342cbe93b5';

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
