import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/theme_constants.dart';
import '../editor_notifier.dart';

class FileTabBar extends ConsumerWidget {
  const FileTabBar({
    super.key,
    required this.tabs,
    required this.activeFilePath,
  });

  final List<OpenFile> tabs;
  final String? activeFilePath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 35,
      color: ThemeConstants.sidebarBackground,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: tabs
              .map((tab) => _FileTab(
                    file: tab,
                    isActive: tab.path == activeFilePath,
                    onTap: () => ref.read(activeFilePathProvider.notifier).set(tab.path),
                    onClose: () => ref.read(editorTabsProvider.notifier).closeFile(tab.path),
                  ))
              .toList(),
        ),
      ),
    );
  }
}

class _FileTab extends StatefulWidget {
  const _FileTab({
    required this.file,
    required this.isActive,
    required this.onTap,
    required this.onClose,
  });

  final OpenFile file;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onClose;

  @override
  State<_FileTab> createState() => _FileTabState();
}

class _FileTabState extends State<_FileTab> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: widget.isActive ? ThemeConstants.tabActive : ThemeConstants.tabInactive,
            border: Border(
              top: BorderSide(
                color: widget.isActive ? ThemeConstants.tabBorder : Colors.transparent,
                width: 1,
              ),
              right: const BorderSide(color: ThemeConstants.borderColor, width: 0.5),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.file.displayName,
                style: TextStyle(
                  color: widget.isActive
                      ? ThemeConstants.textPrimary
                      : ThemeConstants.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(
                width: 16,
                height: 16,
                child: widget.file.isDirty
                    ? const Text(
                        '●',
                        style: TextStyle(
                          color: ThemeConstants.textSecondary,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      )
                    : _hovered
                        ? GestureDetector(
                            onTap: widget.onClose,
                            child: const Icon(
                              Icons.close,
                              size: 13,
                              color: ThemeConstants.textSecondary,
                            ),
                          )
                        : const SizedBox(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
