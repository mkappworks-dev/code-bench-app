// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_service_factory.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$aiServiceHash() => r'15bf38451ad95659f4a8b48748e13e899870f558';

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

/// See also [aiService].
@ProviderFor(aiService)
const aiServiceProvider = AiServiceFamily();

/// See also [aiService].
class AiServiceFamily extends Family<AsyncValue<AIService?>> {
  /// See also [aiService].
  const AiServiceFamily();

  /// See also [aiService].
  AiServiceProvider call(
    AIProvider aiProvider,
  ) {
    return AiServiceProvider(
      aiProvider,
    );
  }

  @override
  AiServiceProvider getProviderOverride(
    covariant AiServiceProvider provider,
  ) {
    return call(
      provider.aiProvider,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'aiServiceProvider';
}

/// See also [aiService].
class AiServiceProvider extends AutoDisposeFutureProvider<AIService?> {
  /// See also [aiService].
  AiServiceProvider(
    AIProvider aiProvider,
  ) : this._internal(
          (ref) => aiService(
            ref as AiServiceRef,
            aiProvider,
          ),
          from: aiServiceProvider,
          name: r'aiServiceProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$aiServiceHash,
          dependencies: AiServiceFamily._dependencies,
          allTransitiveDependencies: AiServiceFamily._allTransitiveDependencies,
          aiProvider: aiProvider,
        );

  AiServiceProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.aiProvider,
  }) : super.internal();

  final AIProvider aiProvider;

  @override
  Override overrideWith(
    FutureOr<AIService?> Function(AiServiceRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: AiServiceProvider._internal(
        (ref) => create(ref as AiServiceRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        aiProvider: aiProvider,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<AIService?> createElement() {
    return _AiServiceProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AiServiceProvider && other.aiProvider == aiProvider;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, aiProvider.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin AiServiceRef on AutoDisposeFutureProviderRef<AIService?> {
  /// The parameter `aiProvider` of this provider.
  AIProvider get aiProvider;
}

class _AiServiceProviderElement
    extends AutoDisposeFutureProviderElement<AIService?> with AiServiceRef {
  _AiServiceProviderElement(super.provider);

  @override
  AIProvider get aiProvider => (origin as AiServiceProvider).aiProvider;
}

String _$availableModelsHash() => r'69eb26eebb8ce7a109cc652cc5abe328c8fe995f';

/// See also [availableModels].
@ProviderFor(availableModels)
final availableModelsProvider =
    AutoDisposeFutureProvider<List<AIModel>>.internal(
  availableModels,
  name: r'availableModelsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$availableModelsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AvailableModelsRef = AutoDisposeFutureProviderRef<List<AIModel>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
