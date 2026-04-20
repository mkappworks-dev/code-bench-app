// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ask_question_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AskQuestionNotifier)
final askQuestionProvider = AskQuestionNotifierProvider._();

final class AskQuestionNotifierProvider
    extends $NotifierProvider<AskQuestionNotifier, AskQuestionState> {
  AskQuestionNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'askQuestionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$askQuestionNotifierHash();

  @$internal
  @override
  AskQuestionNotifier create() => AskQuestionNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AskQuestionState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AskQuestionState>(value),
    );
  }
}

String _$askQuestionNotifierHash() =>
    r'f4ec54ade058c965aaa1590b1ffc557a6f3b46ee';

abstract class _$AskQuestionNotifier extends $Notifier<AskQuestionState> {
  AskQuestionState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AskQuestionState, AskQuestionState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AskQuestionState, AskQuestionState>,
              AskQuestionState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
