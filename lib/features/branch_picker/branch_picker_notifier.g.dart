// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'branch_picker_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Returns the [BranchPickerNotifier] scoped to [projectPath].
/// Auto-disposes when no widget is watching (i.e. when the popover closes).

@ProviderFor(branchPicker)
final branchPickerProvider = BranchPickerFamily._();

/// Returns the [BranchPickerNotifier] scoped to [projectPath].
/// Auto-disposes when no widget is watching (i.e. when the popover closes).

final class BranchPickerProvider
    extends $FunctionalProvider<BranchPickerNotifier, BranchPickerNotifier, BranchPickerNotifier>
    with $Provider<BranchPickerNotifier> {
  /// Returns the [BranchPickerNotifier] scoped to [projectPath].
  /// Auto-disposes when no widget is watching (i.e. when the popover closes).
  BranchPickerProvider._({required BranchPickerFamily super.from, required String super.argument})
    : super(
        retry: null,
        name: r'branchPickerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$branchPickerHash();

  @override
  String toString() {
    return r'branchPickerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<BranchPickerNotifier> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  BranchPickerNotifier create(Ref ref) {
    final argument = this.argument as String;
    return branchPicker(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BranchPickerNotifier value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<BranchPickerNotifier>(value));
  }

  @override
  bool operator ==(Object other) {
    return other is BranchPickerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$branchPickerHash() => r'a0100f30d218ada639f4cd68d14c0667d091fc2b';

/// Returns the [BranchPickerNotifier] scoped to [projectPath].
/// Auto-disposes when no widget is watching (i.e. when the popover closes).

final class BranchPickerFamily extends $Family with $FunctionalFamilyOverride<BranchPickerNotifier, String> {
  BranchPickerFamily._()
    : super(
        retry: null,
        name: r'branchPickerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Returns the [BranchPickerNotifier] scoped to [projectPath].
  /// Auto-disposes when no widget is watching (i.e. when the popover closes).

  BranchPickerProvider call(String projectPath) => BranchPickerProvider._(argument: projectPath, from: this);

  @override
  String toString() => r'branchPickerProvider';
}
