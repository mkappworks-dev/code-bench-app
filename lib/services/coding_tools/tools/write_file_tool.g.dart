// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'write_file_tool.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(writeFileTool)
final writeFileToolProvider = WriteFileToolProvider._();

final class WriteFileToolProvider extends $FunctionalProvider<WriteFileTool, WriteFileTool, WriteFileTool>
    with $Provider<WriteFileTool> {
  WriteFileToolProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'writeFileToolProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$writeFileToolHash();

  @$internal
  @override
  $ProviderElement<WriteFileTool> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  WriteFileTool create(Ref ref) {
    return writeFileTool(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WriteFileTool value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<WriteFileTool>(value));
  }
}

String _$writeFileToolHash() => r'08bf5511ff8fd905a5ee809b28bcfd51e24ce962';
