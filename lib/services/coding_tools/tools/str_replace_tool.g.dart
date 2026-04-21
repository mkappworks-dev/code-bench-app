// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'str_replace_tool.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(strReplaceTool)
final strReplaceToolProvider = StrReplaceToolProvider._();

final class StrReplaceToolProvider extends $FunctionalProvider<StrReplaceTool, StrReplaceTool, StrReplaceTool>
    with $Provider<StrReplaceTool> {
  StrReplaceToolProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'strReplaceToolProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$strReplaceToolHash();

  @$internal
  @override
  $ProviderElement<StrReplaceTool> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  StrReplaceTool create(Ref ref) {
    return strReplaceTool(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StrReplaceTool value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<StrReplaceTool>(value));
  }
}

String _$strReplaceToolHash() => r'2794daf6db11b6f019d021f5bb57555de6d79607';
