import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_dialog.dart';
import '../../core/widgets/app_snack_bar.dart';
import '../../data/coding_tools/models/denylist_category.dart';
import '../../data/coding_tools/models/denylist_defaults.dart';
import '../settings/widgets/section_label.dart';
import 'notifiers/coding_tools_denylist_actions.dart';
import 'notifiers/coding_tools_denylist_notifier.dart';
import 'widgets/denylist_category_group.dart';
import 'widgets/ripgrep_availability_banner.dart';

class CodingToolsScreen extends ConsumerStatefulWidget {
  const CodingToolsScreen({super.key});

  @override
  ConsumerState<CodingToolsScreen> createState() => _CodingToolsScreenState();
}

class _CodingToolsScreenState extends ConsumerState<CodingToolsScreen> {
  static const _categories = [
    (
      category: DenylistCategory.segment,
      title: 'Blocked directories',
      subtitle: 'Blocks the entire tree of any matching segment at any depth.',
      hint: 'e.g. node_modules',
    ),
    (
      category: DenylistCategory.filename,
      title: 'Blocked filenames',
      subtitle: 'Exact filename match at any depth.',
      hint: 'e.g. .env.local',
    ),
    (
      category: DenylistCategory.extension,
      title: 'Blocked extensions',
      subtitle: 'Trailing file extension match.',
      hint: 'e.g. .p8',
    ),
    (
      category: DenylistCategory.prefix,
      title: 'Blocked filename prefixes',
      subtitle: 'Filename starts-with match.',
      hint: 'e.g. .env.',
    ),
  ];

  Future<void> _confirmSuppressBaseline(DenylistCategory category, String value) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AppDialog(
        icon: AppIcons.warning,
        iconType: AppDialogIconType.destructive,
        title: 'Allow the agent to access "$value"?',
        content: Text(
          'The coding tools will no longer refuse reads, lists, or writes of '
          'any file or directory matching "$value" inside your project. '
          'You can restore this block at any time.',
        ),
        actions: [
          AppDialogAction.cancel(onPressed: () => Navigator.pop(ctx, false)),
          AppDialogAction.destructive(label: 'Allow access', onPressed: () => Navigator.pop(ctx, true)),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!mounted) return;
    await ref.read(codingToolsDenylistActionsProvider.notifier).suppressBaseline(category, value);
  }

  Future<void> _confirmRestoreCategory(DenylistCategory category, Set<String> suppressed) async {
    if (suppressed.isNotEmpty) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AppDialog(
          icon: AppIcons.revert,
          iconType: AppDialogIconType.teal,
          title: 'Restore defaults for this category?',
          content: Text('Your additions and any defaults you\'ve opted out of will be cleared.'),
          actions: [
            AppDialogAction.cancel(onPressed: () => Navigator.pop(ctx, false)),
            AppDialogAction.primary(label: 'Restore', onPressed: () => Navigator.pop(ctx, true)),
          ],
        ),
      );
      if (confirmed != true) return;
      if (!mounted) return;
    }
    await ref.read(codingToolsDenylistActionsProvider.notifier).restoreCategory(category);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(codingToolsDenylistActionsProvider, (prev, next) {
      if (next is! AsyncError) return;
      final failure = next.error;
      if (failure is! CodingToolsDenylistFailure) return;
      final msg = switch (failure) {
        CodingToolsDenylistInvalidEntry() => 'Enter a non-empty value.',
        CodingToolsDenylistDuplicate() => 'That entry is already in the list.',
        CodingToolsDenylistSaveFailed() => 'Could not save — please try again.',
        CodingToolsDenylistUnknown() => 'Unexpected error.',
      };
      AppSnackBar.show(context, msg, type: AppSnackBarType.error);
    });

    final stateAsync = ref.watch(codingToolsDenylistProvider);
    final isLoading = ref.watch(codingToolsDenylistActionsProvider).isLoading;

    final c = AppColors.of(context);

    return stateAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text('Failed to load denylist settings.', style: TextStyle(color: c.textSecondary, fontSize: 12)),
      ),
      data: (state) => SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionLabel('Coding Tools'),
              const SizedBox(height: 4),
              Text(
                'Files and folders the agent may not read, list, or modify.',
                style: TextStyle(color: c.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 16),
              const RipgrepAvailabilityBanner(),
              for (final cat in _categories) ...[
                DenylistCategoryGroup(
                  title: cat.title,
                  subtitle: cat.subtitle,
                  baseline: DenylistDefaults.forCategory(cat.category),
                  userAdded: state.userAdded[cat.category] ?? const <String>{},
                  suppressed: state.suppressedDefaults[cat.category] ?? const <String>{},
                  inputHint: cat.hint,
                  isSubmitting: isLoading,
                  onAdd: (value) =>
                      ref.read(codingToolsDenylistActionsProvider.notifier).addUserEntry(cat.category, value),
                  onRemoveUser: (value) =>
                      ref.read(codingToolsDenylistActionsProvider.notifier).removeUserEntry(cat.category, value),
                  onSuppressBaseline: (value) => _confirmSuppressBaseline(cat.category, value),
                  onRestoreBaseline: (value) =>
                      ref.read(codingToolsDenylistActionsProvider.notifier).restoreBaseline(cat.category, value),
                  onRestoreCategory: () =>
                      _confirmRestoreCategory(cat.category, state.suppressedDefaults[cat.category] ?? const <String>{}),
                ),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 8),
              Divider(height: 1, thickness: 1, color: c.borderColor),
              const SizedBox(height: 8),
              const SectionLabel('About'),
              const SizedBox(height: 4),
              Text(
                'Entries with strikethrough are baseline defaults you have opted out of. '
                'They can be restored at any time.',
                style: TextStyle(color: c.textSecondary, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
