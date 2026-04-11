import 'package:flutter/material.dart';

import '../../../core/constants/theme_constants.dart';
import '../../../data/models/applied_change.dart';

/// Three-tab diff view shown when the user tries to revert a change on a
/// file that has been externally modified since apply. Each tab shows the
/// content at one point in time:
///
/// - **Original**: what the file looked like *before* the AI wrote to it
///   (null for newly-created files → "(new file)").
/// - **Applied**: what the AI wrote — the content we snapshotted as our
///   revert target.
/// - **Current**: what the file looks like on disk right now, after some
///   external edit (IDE save, formatter, another AI session).
///
/// Buttons let the user either accept the revert (clobber current with
/// original) or keep the current state and cancel the revert.
class ConflictMergeView extends StatefulWidget {
  const ConflictMergeView({
    super.key,
    required this.change,
    required this.currentContent,
    required this.onAcceptRevert,
    required this.onKeepCurrent,
  });

  final AppliedChange change;
  final String currentContent;
  final VoidCallback onAcceptRevert;
  final VoidCallback onKeepCurrent;

  @override
  State<ConflictMergeView> createState() => _ConflictMergeViewState();
}

class _ConflictMergeViewState extends State<ConflictMergeView> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 520,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TabBar(
            controller: _tabController,
            labelStyle: const TextStyle(fontSize: ThemeConstants.uiFontSizeSmall),
            unselectedLabelStyle: const TextStyle(fontSize: ThemeConstants.uiFontSizeSmall),
            labelColor: ThemeConstants.accent,
            unselectedLabelColor: ThemeConstants.textSecondary,
            indicatorColor: ThemeConstants.accent,
            tabs: const [
              Tab(text: 'Original'),
              Tab(text: 'Applied'),
              Tab(text: 'Current'),
            ],
          ),
          SizedBox(
            height: 220,
            child: TabBarView(
              controller: _tabController,
              children: [
                _ContentView(content: widget.change.originalContent ?? '(new file)'),
                _ContentView(content: widget.change.newContent),
                _ContentView(content: widget.currentContent),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: widget.onKeepCurrent,
                child: const Text(
                  'Keep current',
                  style: TextStyle(color: ThemeConstants.textSecondary, fontSize: ThemeConstants.uiFontSizeSmall),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: ThemeConstants.accent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                ),
                onPressed: widget.onAcceptRevert,
                child: const Text('Accept revert', style: TextStyle(fontSize: ThemeConstants.uiFontSizeSmall)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ContentView extends StatelessWidget {
  const _ContentView({required this.content});
  final String content;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ThemeConstants.codeBlockBg,
      padding: const EdgeInsets.all(8),
      child: SingleChildScrollView(
        child: SelectableText(
          content,
          style: const TextStyle(
            color: ThemeConstants.textPrimary,
            fontSize: ThemeConstants.uiFontSizeSmall,
            fontFamily: ThemeConstants.editorFontFamily,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}
