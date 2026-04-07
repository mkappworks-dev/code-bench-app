// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'editor_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$saveFileHash() => r'fc8ab969566ecc695c60293bb9e08270ff8e9210';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [saveFile].
@ProviderFor(saveFile)
const saveFileProvider = SaveFileFamily();

/// See also [saveFile].
class SaveFileFamily extends Family<AsyncValue<void>> {
  /// See also [saveFile].
  const SaveFileFamily();

  /// See also [saveFile].
  SaveFileProvider call(String path) {
    return SaveFileProvider(path);
  }

  @override
  SaveFileProvider getProviderOverride(covariant SaveFileProvider provider) {
    return call(provider.path);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'saveFileProvider';
}

/// See also [saveFile].
class SaveFileProvider extends AutoDisposeFutureProvider<void> {
  /// See also [saveFile].
  SaveFileProvider(String path)
      : this._internal(
          (ref) => saveFile(ref as SaveFileRef, path),
          from: saveFileProvider,
          name: r'saveFileProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$saveFileHash,
          dependencies: SaveFileFamily._dependencies,
          allTransitiveDependencies: SaveFileFamily._allTransitiveDependencies,
          path: path,
        );

  SaveFileProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.path,
  }) : super.internal();

  final String path;

  @override
  Override overrideWith(FutureOr<void> Function(SaveFileRef provider) create) {
    return ProviderOverride(
      origin: this,
      override: SaveFileProvider._internal(
        (ref) => create(ref as SaveFileRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        path: path,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<void> createElement() {
    return _SaveFileProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SaveFileProvider && other.path == path;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, path.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin SaveFileRef on AutoDisposeFutureProviderRef<void> {
  /// The parameter `path` of this provider.
  String get path;
}

class _SaveFileProviderElement extends AutoDisposeFutureProviderElement<void>
    with SaveFileRef {
  _SaveFileProviderElement(super.provider);

  @override
  String get path => (origin as SaveFileProvider).path;
}

String _$editorTabsHash() => r'd68161a0e346e4fc310ef1e5f64415b907594588';

/// See also [EditorTabs].
@ProviderFor(EditorTabs)
final editorTabsProvider =
    NotifierProvider<EditorTabs, List<OpenFile>>.internal(
  EditorTabs.new,
  name: r'editorTabsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$editorTabsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$EditorTabs = Notifier<List<OpenFile>>;
String _$activeFilePathHash() => r'34e1a32aaddebc924cea25abddb9124525151006';

/// See also [ActiveFilePath].
@ProviderFor(ActiveFilePath)
final activeFilePathProvider =
    NotifierProvider<ActiveFilePath, String?>.internal(
  ActiveFilePath.new,
  name: r'activeFilePathProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$activeFilePathHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ActiveFilePath = Notifier<String?>;
String _$workingDirectoryHash() => r'8e1c0b1ca6cf8a662132ce5d9fb8a007b033cfcf';

/// See also [WorkingDirectory].
@ProviderFor(WorkingDirectory)
final workingDirectoryProvider =
    NotifierProvider<WorkingDirectory, String?>.internal(
  WorkingDirectory.new,
  name: r'workingDirectoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$workingDirectoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$WorkingDirectory = Notifier<String?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
