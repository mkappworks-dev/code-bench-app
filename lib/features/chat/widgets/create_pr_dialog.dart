import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/constants/theme_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/app_text_field.dart';
import '../notifiers/create_pr_failure.dart';

class PrFormResult {
  const PrFormResult({required this.title, required this.body, required this.base, required this.draft});
  final String title;
  final String body;
  final String base;
  final bool draft;
}

typedef PrDialogContent = ({String title, String body, List<String> branches});

class CreatePrDialog extends ConsumerStatefulWidget {
  const CreatePrDialog({super.key, required this.contentFuture});

  final Future<PrDialogContent> contentFuture;

  static Future<PrFormResult?> show(BuildContext context, {required Future<PrDialogContent> contentFuture}) {
    return showDialog<PrFormResult>(
      context: context,
      builder: (_) => CreatePrDialog(contentFuture: contentFuture),
    );
  }

  @override
  ConsumerState<CreatePrDialog> createState() => _CreatePrDialogState();
}

class _CreatePrDialogState extends ConsumerState<CreatePrDialog> with SingleTickerProviderStateMixin {
  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;
  late final AnimationController _shimmer;
  List<String> _branches = const ['main'];
  String _base = 'main';
  bool _draft = false;
  bool _loaded = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _bodyController = TextEditingController();
    _shimmer = AnimationController(vsync: this, duration: const Duration(milliseconds: 2800))..repeat();
    widget.contentFuture.then(
      (content) {
        if (!mounted) return;
        setState(() {
          _titleController.text = content.title;
          _bodyController.text = content.body;
          _branches = content.branches;
          _base = content.branches.contains('main')
              ? 'main'
              : (content.branches.isNotEmpty ? content.branches.first : 'main');
          _loaded = true;
        });
      },
      onError: (Object e) {
        if (!mounted) return;
        final msg = switch (e) {
          CreatePrLoadContentFailed(:final message) => message,
          _ => e.toString(),
        };
        setState(() => _loadError = msg);
      },
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _shimmer.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;
    Navigator.of(
      context,
    ).pop(PrFormResult(title: title, body: _bodyController.text.trim(), base: _base, draft: _draft));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _titleController,
      builder: (_, _) => AppDialog(
        icon: AppIcons.gitPullRequest,
        iconType: AppDialogIconType.teal,
        title: 'Create pull request',
        hasInputField: true,
        maxWidth: 480,
        content: Builder(
          builder: (context) {
            final c = AppColors.of(context);
            if (!_loaded) return _buildLoadingState(c);
            return _buildForm(c);
          },
        ),
        actions: [
          AppDialogAction.cancel(onPressed: () => Navigator.of(context).pop()),
          AppDialogAction.primary(
            label: 'Create PR',
            onPressed: (_loaded && _titleController.text.trim().isNotEmpty) ? _submit : null,
          ),
        ],
      ),
    );
  }

  Widget _buildForm(AppColors c) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Title',
          style: TextStyle(color: c.mutedFg, fontSize: ThemeConstants.uiFontSizeLabel),
        ),
        const SizedBox(height: 6),
        AppTextField(controller: _titleController, maxLength: 70),
        const SizedBox(height: 8),
        Text(
          'Description',
          style: TextStyle(color: c.mutedFg, fontSize: ThemeConstants.uiFontSizeLabel),
        ),
        const SizedBox(height: 6),
        AppTextField(controller: _bodyController, maxLines: 6),
        const SizedBox(height: 12),
        Row(
          children: [
            Text(
              'Base',
              style: TextStyle(color: c.mutedFg, fontSize: ThemeConstants.uiFontSizeLabel),
            ),
            const SizedBox(width: 6),
            PopupMenuButton<String>(
              onSelected: (v) => setState(() => _base = v),
              color: c.panelBackground,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: c.deepBorder),
              ),
              itemBuilder: (_) => _branches
                  .map(
                    (b) => PopupMenuItem(
                      value: b,
                      height: 32,
                      child: Text(
                        b,
                        style: TextStyle(color: c.textPrimary, fontSize: ThemeConstants.uiFontSizeSmall),
                      ),
                    ),
                  )
                  .toList(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: c.chipFill,
                  border: Border.all(color: c.chipStroke),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.call_split, size: 12, color: c.accent),
                    const SizedBox(width: 4),
                    Text(
                      _base,
                      style: TextStyle(
                        color: c.textPrimary,
                        fontSize: ThemeConstants.uiFontSizeSmall,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.keyboard_arrow_down, size: 14, color: c.dimFg),
                  ],
                ),
              ),
            ),
            const Spacer(),
            const SizedBox(width: 6),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => setState(() => _draft = !_draft),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _draft ? c.accentTintLight : c.chipFill,
                    border: Border.all(color: _draft ? c.accentBorderTeal : c.chipStroke),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 140),
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(color: _draft ? c.accent : c.mutedFg, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Draft',
                        style: TextStyle(
                          color: _draft ? c.accent : c.chipText,
                          fontSize: ThemeConstants.uiFontSizeSmall,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLoadingState(AppColors c) {
    if (_loadError != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 20, color: c.mutedFg),
          const SizedBox(height: 8),
          Text(
            _loadError!,
            textAlign: TextAlign.center,
            style: TextStyle(color: c.mutedFg, fontSize: ThemeConstants.uiFontSizeSmall),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Text(
              'Close',
              style: TextStyle(color: c.accent, fontSize: ThemeConstants.uiFontSizeSmall, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      );
    }

    // ShaderMask applies the sweep in the Column's own coordinate space,
    // so all bones shimmer at the same absolute x position simultaneously.
    return AnimatedBuilder(
      animation: _shimmer,
      builder: (context, child) {
        final t = _shimmer.value;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) => LinearGradient(
            colors: [Colors.transparent, Colors.white.withValues(alpha: 0.10), Colors.transparent],
            stops: const [0.0, 0.5, 1.0],
            begin: Alignment(-3.0 + t * 4.0, 0),
            end: Alignment(-1.0 + t * 4.0, 0),
          ).createShader(bounds),
          child: child!,
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Title',
            style: TextStyle(color: c.mutedFg, fontSize: ThemeConstants.uiFontSizeLabel),
          ),
          const SizedBox(height: 6),
          _Bone(color: c.inputSurface, height: 36, radius: 6),
          const SizedBox(height: 8),
          Text(
            'Description',
            style: TextStyle(color: c.mutedFg, fontSize: ThemeConstants.uiFontSizeLabel),
          ),
          const SizedBox(height: 6),
          _Bone(color: c.inputSurface, height: 112, radius: 6),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Base',
                style: TextStyle(color: c.mutedFg, fontSize: ThemeConstants.uiFontSizeLabel),
              ),
              const SizedBox(width: 6),
              _Bone(color: c.inputSurface, height: 26, width: 80, radius: 5),
              const Spacer(),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => setState(() => _draft = !_draft),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 140),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _draft ? c.accentTintLight : c.chipFill,
                      border: Border.all(color: _draft ? c.accentBorderTeal : c.chipStroke),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 140),
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(color: _draft ? c.accent : c.mutedFg, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Draft',
                          style: TextStyle(
                            color: _draft ? c.accent : c.chipText,
                            fontSize: ThemeConstants.uiFontSizeSmall,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Generating title and description…',
            textAlign: TextAlign.center,
            style: TextStyle(color: c.mutedFg, fontSize: ThemeConstants.uiFontSizeSmall, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _Bone extends StatelessWidget {
  const _Bone({required this.color, required this.height, required this.radius, this.width});

  final Color color;
  final double height;
  final double radius;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(radius)),
    );
  }
}
