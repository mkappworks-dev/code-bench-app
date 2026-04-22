// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'read_file_tool.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(readFileTool)
final readFileToolProvider = ReadFileToolProvider._();

final class ReadFileToolProvider
    extends $FunctionalProvider<ReadFileTool, ReadFileTool, ReadFileTool>
    with $Provider<ReadFileTool> {
  ReadFileToolProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'readFileToolProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$readFileToolHash();

  @$internal
  @override
  $ProviderElement<ReadFileTool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ReadFileTool create(Ref ref) {
    return readFileTool(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReadFileTool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReadFileTool>(value),
    );
  }
}

String _$readFileToolHash() => r'e591323ff075a2805615d802f23d78eef322e46b';
