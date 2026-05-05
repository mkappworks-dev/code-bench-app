// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'claude_cli_prompt_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(claudeCliPromptService)
final claudeCliPromptServiceProvider = ClaudeCliPromptServiceProvider._();

final class ClaudeCliPromptServiceProvider
    extends $FunctionalProvider<ClaudeCliPromptService, ClaudeCliPromptService, ClaudeCliPromptService>
    with $Provider<ClaudeCliPromptService> {
  ClaudeCliPromptServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'claudeCliPromptServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$claudeCliPromptServiceHash();

  @$internal
  @override
  $ProviderElement<ClaudeCliPromptService> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  ClaudeCliPromptService create(Ref ref) {
    return claudeCliPromptService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ClaudeCliPromptService value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<ClaudeCliPromptService>(value));
  }
}

String _$claudeCliPromptServiceHash() => r'70e2b8aaf72361395a149021b476b22419608a2c';
