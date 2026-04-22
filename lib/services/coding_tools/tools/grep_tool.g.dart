// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'grep_tool.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(grepTool)
final grepToolProvider = GrepToolProvider._();

final class GrepToolProvider
    extends $FunctionalProvider<GrepTool, GrepTool, GrepTool>
    with $Provider<GrepTool> {
  GrepToolProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'grepToolProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$grepToolHash();

  @$internal
  @override
  $ProviderElement<GrepTool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GrepTool create(Ref ref) {
    return grepTool(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GrepTool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GrepTool>(value),
    );
  }
}

String _$grepToolHash() => r'3ce8dda4f85f3f0a5272cf04a741ff6c7f3b3c09';
