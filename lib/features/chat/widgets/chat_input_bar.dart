import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/theme_constants.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../core/utils/instant_menu.dart';
import '../../../data/models/ai_model.dart';
import '../../../data/models/project.dart';
import '../../../features/project_sidebar/project_sidebar_actions.dart';
import '../../../features/project_sidebar/project_sidebar_notifier.dart';
import '../chat_notifier.dart';

/// Private in-memory store of per-session chat-input drafts.
///
/// Not a Riverpod provider because nothing in the tree needs to observe it —
/// the drafts are only read/written by ChatInputBar itself in response to
/// session switches. Using a plain module-level map sidesteps Riverpod's
/// "can't modify provider during build" guard (which fires in
/// `didUpdateWidget`) and the "ref unsafe after unmount" check (in
/// `dispose`), both of which are triggered by this widget's lifecycle.
///
/// Survives switching between chats within a single app run but is not
/// persisted across restarts. Empty entries are evicted so the map doesn't
/// grow with stale keys.
final Map<String, String> _sessionDrafts = <String, String>{};

/// Resets `_sessionDrafts` so one widget test can't leak its draft into the
/// next. Intended only for `setUp` in widget tests — production code should
/// never call this.
@visibleForTesting
void clearSessionDraftsForTesting() => _sessionDrafts.clear();

enum _Effort { low, medium, high, max }

enum _Mode { chat, plan, act }

enum _Permission { readOnly, askBefore, fullAccess }

extension _EffortLabel on _Effort {
  String get label => switch (this) {
    _Effort.low => 'Low',
    _Effort.medium => 'Medium',
    _Effort.high => 'High',
    _Effort.max => 'Max',
  };
}

extension _ModeLabel on _Mode {
  String get label => switch (this) {
    _Mode.chat => 'Chat',
    _Mode.plan => 'Plan',
    _Mode.act => 'Act',
  };
}

extension _PermissionLabel on _Permission {
  String get label => switch (this) {
    _Permission.readOnly => 'Read only',
    _Permission.askBefore => 'Ask before changes',
    _Permission.fullAccess => 'Full access',
  };
}

class ChatInputBar extends ConsumerStatefulWidget {
  const ChatInputBar({super.key, required this.sessionId});
  final String sessionId;

  @override
  ConsumerState<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends ConsumerState<ChatInputBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _keyboardFocusNode = FocusNode();
  bool _isSending = false;
  _Effort _effort = _Effort.high;
  _Mode _mode = _Mode.chat;
  _Permission _permission = _Permission.fullAccess;

  void _stashDraft(String sessionId, String text) {
    if (text.isEmpty) {
      _sessionDrafts.remove(sessionId);
    } else {
      _sessionDrafts[sessionId] = text;
    }
  }

  @override
  void initState() {
    super.initState();
    // Restore any draft that was stashed for this session last time
    // the user switched away. In-memory only, so a fresh app launch
    // starts with an empty controller.
    final draft = _sessionDrafts[widget.sessionId];
    if (draft != null && draft.isNotEmpty) {
      _controller.text = draft;
    }
  }

  @override
  void dispose() {
    // Stash the current draft so a later ChatInputBar rebuild can
    // restore it for this session.
    _stashDraft(widget.sessionId, _controller.text);
    _controller.dispose();
    _focusNode.dispose();
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ChatInputBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Flutter reuses this Element across sessionId changes (same widget
    // type in the same tree slot), so the text controller keeps whatever
    // the user typed in the previous chat. Save the outgoing draft
    // against oldWidget.sessionId and load the incoming one so drafts
    // are isolated per session. Effort/mode/permission stay untouched —
    // those are intentional global sender preferences.
    if (oldWidget.sessionId != widget.sessionId) {
      _stashDraft(oldWidget.sessionId, _controller.text);
      _controller.text = _sessionDrafts[widget.sessionId] ?? '';
    }
  }

  /// Resolves the active project for this session. Returns null if no project
  /// is selected or the project row has not loaded yet.
  Project? _resolveActiveProject() {
    final projectId = ref.read(activeProjectIdProvider);
    final projects = ref.read(projectsProvider).value ?? <Project>[];
    return projects.firstWhereOrNull((p) => p.id == projectId);
  }

  /// Defense-in-depth check run at send time: the freezed `status` field only
  /// reflects state at the last Drift stream re-emission, so we hit the
  /// filesystem directly here as the source of truth. On any drift between
  /// the cached status and the filesystem — either direction — kicks off a
  /// targeted refresh so the sidebar tile + send button catch up:
  ///
  ///  - cached `available` but folder just vanished → block + heal to missing
  ///  - cached `missing` but folder was restored by the user out-of-band →
  ///    allow send + heal back to available
  bool _isProjectAvailable(Project project) {
    final existsOnDisk = ref.read(projectSidebarActionsProvider.notifier).projectExistsOnDisk(project.path);
    final cachedAsAvailable = project.status == ProjectStatus.available;
    if (existsOnDisk != cachedAsAvailable) {
      // The notifier logs its own failures; swallow here so this background
      // refresh never surfaces as an uncaught exception.
      unawaited(
        ref.read(projectSidebarActionsProvider.notifier).refreshProjectStatus(project.id).catchError((Object _) {}),
      );
    }
    return existsOnDisk;
  }

  Future<void> _send() async {
    if (_isSending) return;

    // Check project availability BEFORE the empty-text bailout so that a
    // tap on the disabled send button (which routes through this method)
    // still surfaces the "folder missing" snackbar — otherwise the user
    // gets a silent no-op and no explanation of why sending is blocked.
    //
    // The gate defers entirely to the filesystem via `_isProjectAvailable`;
    // `project.status` is only read for rendering (button dim, hint text),
    // never for blocking, because it can be stale in either direction.
    final project = _resolveActiveProject();
    if (project == null) {
      showErrorSnackBar(context, 'No active project.');
      return;
    }
    if (!_isProjectAvailable(project)) {
      showErrorSnackBar(
        context,
        'Project folder is missing. Right-click the project in the sidebar to Relocate or Remove it.',
      );
      return;
    }

    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();
    // Drop the stashed draft for this session too — once the message
    // is on the wire, there's nothing to restore on a later switch.
    _sessionDrafts.remove(widget.sessionId);
    setState(() => _isSending = true);
    try {
      final systemPrompt = ref.read(sessionSystemPromptProvider)[widget.sessionId];
      await ref
          .read(chatMessagesProvider(widget.sessionId).notifier)
          .sendMessage(text, systemPrompt: (systemPrompt != null && systemPrompt.isNotEmpty) ? systemPrompt : null);
    } catch (e) {
      if (mounted) showErrorSnackBar(context, 'Failed to send message. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
        _focusNode.requestFocus();
      }
    }
  }

  /// Positions a showMenu popup above the tapped widget.
  /// Setting bottom:0 tells Flutter the avoid-rect extends to the screen bottom,
  /// leaving no space below and forcing the menu to open upward.
  RelativeRect _menuAbove(BuildContext context, RenderBox box) {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final origin = box.localToGlobal(Offset.zero, ancestor: overlay);
    return RelativeRect.fromLTRB(
      origin.dx,
      origin.dy, // button top → _MenuLayout places menu bottom here (non-covering)
      overlay.size.width - origin.dx - box.size.width,
      0,
    );
  }

  void _showDropdown<T>(
    BuildContext context,
    List<T> items,
    T selected,
    String Function(T) label,
    void Function(T) onSelect,
  ) {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;
    showInstantMenu<T>(
      context: context,
      position: _menuAbove(context, box),
      color: ThemeConstants.panelBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(7),
        side: const BorderSide(color: Color(0xFF333333)),
      ),
      items: items
          .map(
            (item) => PopupMenuItem<T>(
              value: item,
              height: 32,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label(item),
                      style: TextStyle(
                        color: item == selected ? ThemeConstants.textPrimary : ThemeConstants.textSecondary,
                        fontSize: ThemeConstants.uiFontSizeSmall,
                      ),
                    ),
                  ),
                  if (item == selected) const Icon(AppIcons.check, size: 11, color: ThemeConstants.accent),
                ],
              ),
            ),
          )
          .toList(),
    ).then((value) {
      if (value != null) onSelect(value);
    });
  }

  void _showModelPicker(BuildContext context) {
    final models = AIModels.defaults;
    final selected = ref.read(selectedModelProvider);
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;
    showInstantMenu<AIModel>(
      context: context,
      position: _menuAbove(context, box),
      color: ThemeConstants.panelBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(7),
        side: const BorderSide(color: Color(0xFF333333)),
      ),
      items: models
          .map(
            (m) => PopupMenuItem<AIModel>(
              value: m,
              height: 32,
              child: Text(
                '${m.provider.displayName} / ${m.name}',
                style: TextStyle(
                  color: m == selected ? ThemeConstants.textPrimary : ThemeConstants.textSecondary,
                  fontSize: ThemeConstants.uiFontSizeSmall,
                ),
              ),
            ),
          )
          .toList(),
    ).then((value) {
      if (value != null) ref.read(selectedModelProvider.notifier).select(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final model = ref.watch(selectedModelProvider);
    // Re-render whenever the active project or its status changes so the
    // send button + Enter key disable the moment the folder goes missing
    // (e.g. app-resume refresh, write-button guard, or ApplyService catch).
    final projectId = ref.watch(activeProjectIdProvider);
    final projectsAsync = ref.watch(projectsProvider);
    final project = projectsAsync.value?.firstWhereOrNull((p) => p.id == projectId);
    final isMissing = project?.status == ProjectStatus.missing;
    final canSend = !_isSending && !isMissing;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: ThemeConstants.deepBorder)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: ThemeConstants.inputSurface,
          border: Border.all(color: ThemeConstants.deepBorder),
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            KeyboardListener(
              focusNode: _keyboardFocusNode,
              onKeyEvent: (event) {
                if (event is KeyDownEvent &&
                    event.logicalKey == LogicalKeyboardKey.enter &&
                    !HardwareKeyboard.instance.isShiftPressed &&
                    !_isSending) {
                  // Let _send() own the missing-project branch so Enter
                  // surfaces the same snackbar as the tap on the button.
                  _send();
                }
              },
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                maxLines: null,
                minLines: 1,
                style: const TextStyle(color: ThemeConstants.textPrimary, fontSize: ThemeConstants.uiFontSize),
                decoration: InputDecoration(
                  hintText: isMissing
                      ? 'Project folder is missing — Relocate or Remove to continue'
                      : 'Ask anything, @tag files/folders, or use /command',
                  hintStyle: const TextStyle(color: ThemeConstants.faintFg, fontSize: ThemeConstants.uiFontSize),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.only(top: 7),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: ThemeConstants.deepBorder)),
              ),
              child: Row(
                children: [
                  Builder(
                    builder: (ctx) =>
                        _ControlChip(icon: AppIcons.aiMode, label: model.name, onTap: () => _showModelPicker(ctx)),
                  ),
                  const _Separator(),
                  Builder(
                    builder: (ctx) => _ControlChip(
                      label: _effort.label,
                      onTap: () => _showDropdown(
                        ctx,
                        _Effort.values,
                        _effort,
                        (e) => e.label,
                        (e) => setState(() => _effort = e),
                      ),
                    ),
                  ),
                  const _Separator(),
                  Builder(
                    builder: (ctx) => _ControlChip(
                      icon: AppIcons.chat,
                      label: _mode.label,
                      onTap: () =>
                          _showDropdown(ctx, _Mode.values, _mode, (m) => m.label, (m) => setState(() => _mode = m)),
                    ),
                  ),
                  const _Separator(),
                  Builder(
                    builder: (ctx) => _ControlChip(
                      icon: AppIcons.lock,
                      label: _permission.label,
                      onTap: () => _showDropdown(
                        ctx,
                        _Permission.values,
                        _permission,
                        (p) => p.label,
                        (p) => setState(() => _permission = p),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Tooltip(
                    message: isMissing ? 'Project folder is missing. Relocate or Remove it from the sidebar.' : '',
                    child: GestureDetector(
                      // Route all taps through _send() — even when visually
                      // disabled for a missing folder — so the guard inside
                      // _send() can show the explanatory snackbar.
                      onTap: _isSending ? null : _send,
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: canSend ? ThemeConstants.accent : ThemeConstants.accent.withValues(alpha: 0.35),
                          shape: BoxShape.circle,
                        ),
                        child: _isSending
                            ? const Padding(
                                padding: EdgeInsets.all(6),
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(AppIcons.arrowUp, size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ControlChip extends StatelessWidget {
  const _ControlChip({this.icon, required this.label, required this.onTap});
  final IconData? icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Icon(icon, size: 11, color: ThemeConstants.textSecondary), const SizedBox(width: 4)],
            Text(
              label,
              style: const TextStyle(color: ThemeConstants.textSecondary, fontSize: ThemeConstants.uiFontSizeSmall),
            ),
            const SizedBox(width: 3),
            const Icon(AppIcons.chevronDown, size: 10, color: ThemeConstants.faintFg),
          ],
        ),
      ),
    );
  }
}

class _Separator extends StatelessWidget {
  const _Separator();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 1),
      child: Text(
        '|',
        style: TextStyle(color: ThemeConstants.deepBorder, fontSize: ThemeConstants.uiFontSizeSmall),
      ),
    );
  }
}
