// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'glob_tool.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(globTool)
final globToolProvider = GlobToolProvider._();

final class GlobToolProvider
    extends $FunctionalProvider<GlobTool, GlobTool, GlobTool>
    with $Provider<GlobTool> {
  GlobToolProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'globToolProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$globToolHash();

  @$internal
  @override
  $ProviderElement<GlobTool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GlobTool create(Ref ref) {
    return globTool(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GlobTool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GlobTool>(value),
    );
  }
}

String _$globToolHash() => r'b40d946f64eb2aaf85999e5dae0709a8ad705ef5';
