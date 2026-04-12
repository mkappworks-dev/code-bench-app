// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'branch_picker_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(BranchPickerNotifier)
final branchPickerProvider = BranchPickerNotifierFamily._();

final class BranchPickerNotifierProvider extends $AsyncNotifierProvider<BranchPickerNotifier, BranchPickerState> {
  BranchPickerNotifierProvider._({required BranchPickerNotifierFamily super.from, required String super.argument})
    : super(
        retry: null,
        name: r'branchPickerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$branchPickerNotifierHash();

  @override
  String toString() {
    return r'branchPickerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  BranchPickerNotifier create() => BranchPickerNotifier();

  @override
  bool operator ==(Object other) {
    return other is BranchPickerNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$branchPickerNotifierHash() => r'51305a6a4b9cdb14d7805186508afbdfd55a7b3d';

final class BranchPickerNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          BranchPickerNotifier,
          AsyncValue<BranchPickerState>,
          BranchPickerState,
          FutureOr<BranchPickerState>,
          String
        > {
  BranchPickerNotifierFamily._()
    : super(
        retry: null,
        name: r'branchPickerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  BranchPickerNotifierProvider call(String projectPath) =>
      BranchPickerNotifierProvider._(argument: projectPath, from: this);

  @override
  String toString() => r'branchPickerProvider';
}

abstract class _$BranchPickerNotifier extends $AsyncNotifier<BranchPickerState> {
  late final _$args = ref.$arg as String;
  String get projectPath => _$args;

  FutureOr<BranchPickerState> build(String projectPath);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<BranchPickerState>, BranchPickerState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<BranchPickerState>, BranchPickerState>,
              AsyncValue<BranchPickerState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
