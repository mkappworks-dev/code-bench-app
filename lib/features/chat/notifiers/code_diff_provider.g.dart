// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'code_diff_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Computes a diff between the on-disk file and [newContent].
/// Returns `null` on any error (outside-project, unreadable file, etc.).

@ProviderFor(codeDiff)
final codeDiffProvider = CodeDiffFamily._();

/// Computes a diff between the on-disk file and [newContent].
/// Returns `null` on any error (outside-project, unreadable file, etc.).

final class CodeDiffProvider extends $FunctionalProvider<AsyncValue<DiffResult?>, DiffResult?, FutureOr<DiffResult?>>
    with $FutureModifier<DiffResult?>, $FutureProvider<DiffResult?> {
  /// Computes a diff between the on-disk file and [newContent].
  /// Returns `null` on any error (outside-project, unreadable file, etc.).
  CodeDiffProvider._({
    required CodeDiffFamily super.from,
    required ({String absolutePath, String projectPath, String newContent}) super.argument,
  }) : super(
         retry: null,
         name: r'codeDiffProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$codeDiffHash();

  @override
  String toString() {
    return r'codeDiffProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<DiffResult?> $createElement($ProviderPointer pointer) => $FutureProviderElement(pointer);

  @override
  FutureOr<DiffResult?> create(Ref ref) {
    final argument = this.argument as ({String absolutePath, String projectPath, String newContent});
    return codeDiff(
      ref,
      absolutePath: argument.absolutePath,
      projectPath: argument.projectPath,
      newContent: argument.newContent,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CodeDiffProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$codeDiffHash() => r'596aa98afd0cf33da5da01682799815666f59302';

/// Computes a diff between the on-disk file and [newContent].
/// Returns `null` on any error (outside-project, unreadable file, etc.).

final class CodeDiffFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<DiffResult?>,
          ({String absolutePath, String projectPath, String newContent})
        > {
  CodeDiffFamily._()
    : super(
        retry: null,
        name: r'codeDiffProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Computes a diff between the on-disk file and [newContent].
  /// Returns `null` on any error (outside-project, unreadable file, etc.).

  CodeDiffProvider call({required String absolutePath, required String projectPath, required String newContent}) =>
      CodeDiffProvider._(
        argument: (absolutePath: absolutePath, projectPath: projectPath, newContent: newContent),
        from: this,
      );

  @override
  String toString() => r'codeDiffProvider';
}
