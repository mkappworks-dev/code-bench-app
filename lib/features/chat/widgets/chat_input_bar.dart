import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/theme_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../core/utils/instant_menu.dart';
import '../../../data/shared/ai_model.dart';
import '../../../data/project/models/project.dart';
import '../../../features/project_sidebar/notifiers/project_sidebar_actions.dart';
import '../../../features/project_sidebar/notifiers/project_sidebar_notifier.dart';
import '../notifiers/chat_notifier.dart';
import '../../../data/session/models/session_settings.dart';
import '../notifiers/available_models_notifier.dart';
import '../notifiers/session_settings_actions.dart';
import '../notifiers/session_settings_failure.dart';

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

class ChatInputBar extends ConsumerStatefulWidget {
  const ChatInputBar({super.key, required this.sessionId});
  final String sessionId;

  @override
  ConsumerState<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends ConsumerState<ChatInputBar> with SingleTickerProviderStateMixin {
  // Sentinel returned when the user taps "Refresh models".
  // Identity-checked (identical()) so null (dismissed) stays distinct.
  static final _refreshSentinel = AIModel(id: '_refresh_sentinel', provider: AIProvider.custom, name: '', modelId: '');

  static const _pickerSectionOrder = [
    AIProvider.anthropic,
    AIProvider.openai,
    AIProvider.gemini,
    AIProvider.ollama,
    AIProvider.custom,
  ];

  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _keyboardFocusNode = FocusNode();
  bool _isSending = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseOpacity;

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
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
    _pulseOpacity = Tween<double>(
      begin: 0.35,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    // Stash the current draft so a later ChatInputBar rebuild can
    // restore it for this session.
    _stashDraft(widget.sessionId, _controller.text);
    _pulseController.dispose();
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
    // are isolated per session. Effort/mode/permission are now per-session
    // and loaded by SessionSettingsActions; no local state to preserve here.
    if (oldWidget.sessionId != widget.sessionId) {
      _stashDraft(oldWidget.sessionId, _controller.text);
      _controller.text = _sessionDrafts[widget.sessionId] ?? '';
    }
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
    final project = ref.read(activeProjectProvider);
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
    final systemPrompt = ref.read(sessionSystemPromptProvider)[widget.sessionId];
    final sendError = await ref
        .read(chatMessagesProvider(widget.sessionId).notifier)
        .sendMessage(text, systemPrompt: (systemPrompt != null && systemPrompt.isNotEmpty) ? systemPrompt : null);
    if (mounted) {
      if (sendError != null) {
        showErrorSnackBar(context, userMessage(sendError, fallback: 'Failed to get a response.'));
      }
      setState(() => _isSending = false);
      _focusNode.requestFocus();
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
    final c = AppColors.of(context);
    showInstantMenu<T>(
      context: context,
      position: _menuAbove(context, box),
      color: c.panelBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(7),
        side: BorderSide(color: c.subtleBorder),
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
                        color: item == selected ? c.textPrimary : c.textSecondary,
                        fontSize: ThemeConstants.uiFontSizeSmall,
                      ),
                    ),
                  ),
                  if (item == selected) Icon(AppIcons.check, size: 11, color: c.accent),
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
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;
    final c = AppColors.of(context);
    final selected = ref.read(selectedModelProvider);

    final allModels = ref.read(availableModelsProvider).value ?? AIModels.defaults;
    final isRefreshing = ref.read(availableModelsProvider).isLoading;

    final grouped = <AIProvider, List<AIModel>>{};
    for (final m in allModels) {
      grouped.putIfAbsent(m.provider, () => []).add(m);
    }

    final items = <PopupMenuEntry<AIModel>>[];

    for (final provider in _pickerSectionOrder) {
      final models = grouped[provider];
      if (models == null || models.isEmpty) continue;

      items.add(
        PopupMenuItem<AIModel>(
          enabled: false,
          height: 24,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            provider.displayName.toUpperCase(),
            style: TextStyle(color: c.mutedFg, fontSize: 9, letterSpacing: 0.06, fontWeight: FontWeight.w600),
          ),
        ),
      );

      for (final m in models) {
        items.add(
          PopupMenuItem<AIModel>(
            value: m,
            height: 32,
            child: Text(
              m.name,
              style: TextStyle(
                color: m == selected ? c.textPrimary : c.textSecondary,
                fontSize: ThemeConstants.uiFontSizeSmall,
              ),
            ),
          ),
        );
      }
    }

    if (isRefreshing) {
      items.add(
        PopupMenuItem<AIModel>(
          enabled: false,
          height: 28,
          child: Text(
            'Refreshing…',
            style: TextStyle(color: c.mutedFg, fontSize: ThemeConstants.uiFontSizeSmall, fontStyle: FontStyle.italic),
          ),
        ),
      );
    }

    items.add(const PopupMenuDivider());
    items.add(
      PopupMenuItem<AIModel>(
        value: _refreshSentinel,
        height: 28,
        child: Text(
          '↺  Refresh models',
          style: TextStyle(color: c.mutedFg, fontSize: ThemeConstants.uiFontSizeSmall),
        ),
      ),
    );

    showInstantMenu<AIModel>(
      context: context,
      position: _menuAbove(context, box),
      color: c.panelBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(7),
        side: BorderSide(color: c.subtleBorder),
      ),
      items: items,
    ).then((value) {
      if (identical(value, _refreshSentinel)) {
        ref.read(availableModelsProvider.notifier).refresh();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showModelPicker(context);
        });
        return;
      }
      if (value != null) {
        ref.read(sessionSettingsActionsProvider.notifier).updateModel(widget.sessionId, value);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(chatMessagesProvider(widget.sessionId), (_, next) {
      if (!_isSending) return;
      if (next is! AsyncError || !mounted) return;
      showErrorSnackBar(context, 'Failed to send message. Please try again.');
    });

    // Initialise (idempotent after first call) and listen for persist errors.
    ref.listen(sessionSettingsActionsProvider, (_, next) {
      if (next is! AsyncError || !mounted) return;
      if (next.error is! SessionSettingsFailure) return;
      showErrorSnackBar(context, 'Could not save session settings.');
    });

    final c = AppColors.of(context);
    final model = ref.watch(selectedModelProvider);
    final availableState = ref.watch(availableModelsProvider);
    final isModelStale = availableState.hasValue && !availableState.value!.any((m) => m.modelId == model.modelId);
    final mode = ref.watch(sessionModeProvider);
    final effort = ref.watch(sessionEffortProvider);
    final permission = ref.watch(sessionPermissionProvider);
    // Re-render whenever the active project or its status changes so the
    // send button + Enter key disable the moment the folder goes missing
    // (e.g. app-resume refresh, write-button guard, or ApplyService catch).
    final project = ref.watch(activeProjectProvider);
    final isMissing = project?.status == ProjectStatus.missing;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      decoration: BoxDecoration(color: c.background),
      child: Container(
        decoration: BoxDecoration(
          color: c.glassFill,
          border: Border.all(color: c.glassBorder),
          borderRadius: BorderRadius.circular(11),
          boxShadow: [
            BoxShadow(color: c.chatBoxShadowOuter, blurRadius: 24, offset: const Offset(0, -6)),
            BoxShadow(color: c.chatBoxShadowDrop, blurRadius: 8, offset: const Offset(0, 2)),
            BoxShadow(color: c.chatBoxRimGlow, blurRadius: 0, spreadRadius: 0.5),
          ],
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
                style: TextStyle(color: c.textPrimary, fontSize: ThemeConstants.uiFontSize),
                decoration: InputDecoration(
                  hintText: isMissing
                      ? 'Project folder is missing — Relocate or Remove to continue'
                      : 'Ask anything, @tag files/folders, or use /command',
                  hintStyle: TextStyle(color: c.faintFg, fontSize: ThemeConstants.uiFontSize),
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
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: c.faintBorder)),
              ),
              child: Row(
                children: [
                  Builder(
                    builder: (ctx) => _ControlChip(
                      icon: AppIcons.aiMode,
                      label: model.name,
                      isWarning: isModelStale,
                      onTap: () => _showModelPicker(ctx),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Builder(
                    builder: (ctx) => _ControlChip(
                      label: effort.label,
                      onTap: () => _showDropdown(
                        ctx,
                        ChatEffort.values,
                        effort,
                        (e) => e.label,
                        (e) => ref.read(sessionSettingsActionsProvider.notifier).updateEffort(widget.sessionId, e),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Builder(
                    builder: (ctx) => _ControlChip(
                      icon: AppIcons.chat,
                      label: mode.label,
                      onTap: () => _showDropdown(
                        ctx,
                        ChatMode.values,
                        mode,
                        (m) => m.label,
                        (m) => ref.read(sessionSettingsActionsProvider.notifier).updateMode(widget.sessionId, m),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Builder(
                    builder: (ctx) => _ControlChip(
                      icon: AppIcons.lock,
                      label: permission.label,
                      onTap: () => _showDropdown(
                        ctx,
                        ChatPermission.values,
                        permission,
                        (p) => p.label,
                        (p) => ref.read(sessionSettingsActionsProvider.notifier).updatePermission(widget.sessionId, p),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Tooltip(
                    message: isMissing ? 'Project folder is missing. Relocate or Remove it from the sidebar.' : '',
                    child: ListenableBuilder(
                      listenable: _controller,
                      builder: (context, _) {
                        final lc = AppColors.of(context);
                        final hasText = _controller.text.trim().isNotEmpty;
                        final Color bg;
                        final Border? border;
                        final Color iconColor;
                        final List<BoxShadow> shadows;
                        if (_isSending) {
                          bg = lc.accentHover;
                          border = null;
                          iconColor = lc.onAccent;
                          shadows = [];
                        } else if (hasText && !isMissing) {
                          bg = lc.accent;
                          border = null;
                          iconColor = lc.onAccent;
                          shadows = [BoxShadow(color: lc.sendGlow, blurRadius: 8, offset: const Offset(0, 2))];
                        } else {
                          bg = lc.sendDisabledFill;
                          border = Border.all(color: lc.sendDisabledStroke);
                          iconColor = lc.sendDisabledIconColor;
                          shadows = [];
                        }
                        return GestureDetector(
                          onTap: _isSending ? null : _send,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              gradient: (!_isSending && hasText && !isMissing)
                                  ? LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [lc.accent, lc.accentHover],
                                    )
                                  : null,
                              color: (_isSending || !hasText || isMissing) ? bg : null,
                              borderRadius: BorderRadius.circular(7),
                              border: border,
                              boxShadow: shadows,
                            ),
                            child: Center(
                              child: _isSending
                                  ? AnimatedBuilder(
                                      animation: _pulseOpacity,
                                      builder: (context, _) => Opacity(
                                        opacity: _pulseOpacity.value,
                                        child: Container(
                                          width: 9,
                                          height: 9,
                                          decoration: BoxDecoration(
                                            color: lc.onAccent,
                                            borderRadius: BorderRadius.circular(2),
                                          ),
                                        ),
                                      ),
                                    )
                                  : Icon(AppIcons.arrowUp, size: 14, color: iconColor),
                            ),
                          ),
                        );
                      },
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
  const _ControlChip({this.icon, required this.label, required this.onTap, this.isWarning = false});
  final IconData? icon;
  final String label;
  final VoidCallback onTap;
  final bool isWarning;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(5),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: isWarning ? c.warningTintBg : c.chipFill,
          border: Border.all(color: isWarning ? c.warning.withValues(alpha: 0.4) : c.chipStroke),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Icon(icon, size: 11, color: c.chipText), const SizedBox(width: 4)],
            if (isWarning) ...[Icon(AppIcons.warning, size: 10, color: c.warning), const SizedBox(width: 3)],
            Text(
              label,
              style: TextStyle(color: c.chipText, fontSize: ThemeConstants.uiFontSizeSmall),
            ),
            const SizedBox(width: 3),
            Icon(AppIcons.chevronDown, size: 10, color: c.faintFg),
          ],
        ),
      ),
    );
  }
}
