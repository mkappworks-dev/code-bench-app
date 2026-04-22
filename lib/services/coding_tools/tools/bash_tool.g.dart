// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bash_tool.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(bashTool)
final bashToolProvider = BashToolProvider._();

final class BashToolProvider
    extends $FunctionalProvider<BashTool, BashTool, BashTool>
    with $Provider<BashTool> {
  BashToolProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bashToolProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$bashToolHash();

  @$internal
  @override
  $ProviderElement<BashTool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  BashTool create(Ref ref) {
    return bashTool(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BashTool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BashTool>(value),
    );
  }
}

String _$bashToolHash() => r'fdeb934f125fda210692e67f7d7448076598eb2f';
