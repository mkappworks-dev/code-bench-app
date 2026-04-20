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
import '../notifiers/pending_message_action_notifier.dart';
import '../../../data/session/models/session_settings.dart';
import '../notifiers/available_models_failure.dart';
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

/// Hard cap on how many models the picker will render per provider. A
/// misconfigured Custom endpoint returning thousands of entries would
/// otherwise build that many `PopupMenuItem`s in a `Column`.
const int _maxModelsPerProvider = 200;

/// Sealed choice type for the model picker. Replaces the previous
/// `PopupMenuItem<AIModel>` sentinel pattern: refresh-as-model smuggled the
/// control action through the value channel, which was brittle (depends on
/// reference identity of a sentinel value).
sealed class _ModelPickerChoice {
  const _ModelPickerChoice();
}

final class _ModelChoice extends _ModelPickerChoice {
  const _ModelChoice(this.model);
  final AIModel model;
}

final class _RefreshChoice extends _ModelPickerChoice {
  const _RefreshChoice();
}

class _ChatInputBarState extends ConsumerState<ChatInputBar> with SingleTickerProviderStateMixin {
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
  String _lastSentText = '';

  late final AnimationController _pulseController;
  late final Animation<double> _pulseOpacity;

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
    final draft = _sessionDrafts[widget.sessionId];
    if (draft != null && draft.isNotEmpty) {
      _controller.text = draft;
    }
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _pulseOpacity = Tween<double>(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
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

    _lastSentText = text;
    _controller.clear();
    _sessionDrafts.remove(widget.sessionId);
    setState(() => _isSending = true);
    _pulseController.repeat(reverse: true);
    final systemPrompt = ref.read(sessionSystemPromptProvider)[widget.sessionId];
    final sendError = await ref
        .read(chatMessagesProvider(widget.sessionId).notifier)
        .sendMessage(text, systemPrompt: (systemPrompt != null && systemPrompt.isNotEmpty) ? systemPrompt : null);
    if (mounted) {
      if (sendError != null) {
        showErrorSnackBar(context, userMessage(sendError, fallback: 'Failed to get a response.'));
      }
      _pulseController.stop();
      _pulseController.reset();
      setState(() => _isSending = false);
      _focusNode.requestFocus();
    }
  }

  /// Returns a [RelativeRect] whose [bottom] encodes the distance from the
  /// button's bottom edge to the overlay's bottom edge. Combined with
  /// [showInstantMenu]'s [openAbove] flag, this lets [_MenuLayout] anchor the
  /// popup from the screen bottom — which stays stable as the window resizes
  /// vertically because the chat input bar is bottom-docked.
  RelativeRect _menuAbove(BuildContext context, RenderBox box) {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final origin = box.localToGlobal(Offset.zero, ancestor: overlay);
    return RelativeRect.fromLTRB(
      origin.dx,
      origin.dy,
      overlay.size.width - origin.dx - box.size.width,
      overlay.size.height - origin.dy - box.size.height, // distance from button bottom to screen bottom
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
      openAbove: true,
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

    final result = ref.read(availableModelsProvider).value;
    final allModels = result?.models ?? AIModels.defaults;
    final failures = result?.failures ?? const <AIProvider, ModelProviderFailure>{};

    final grouped = <AIProvider, List<AIModel>>{};
    for (final m in allModels) {
      grouped.putIfAbsent(m.provider, () => []).add(m);
    }

    final items = <PopupMenuEntry<_ModelPickerChoice>>[];

    for (final provider in _pickerSectionOrder) {
      final models = grouped[provider];
      final failure = failures[provider];
      if ((models == null || models.isEmpty) && failure == null) continue;

      items.add(
        PopupMenuItem<_ModelPickerChoice>(
          enabled: false,
          height: 24,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            provider.displayName.toUpperCase(),
            style: TextStyle(color: c.mutedFg, fontSize: 9, letterSpacing: 0.06, fontWeight: FontWeight.w600),
          ),
        ),
      );

      if (failure != null) {
        items.add(
          PopupMenuItem<_ModelPickerChoice>(
            enabled: false,
            height: 28,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Icon(AppIcons.warning, size: 11, color: c.warning),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    _failureMessage(failure),
                    style: TextStyle(color: c.warning, fontSize: ThemeConstants.uiFontSizeSmall),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      final visible = (models ?? const <AIModel>[]).take(_maxModelsPerProvider);
      for (final m in visible) {
        items.add(
          PopupMenuItem<_ModelPickerChoice>(
            value: _ModelChoice(m),
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
      final extra = (models?.length ?? 0) - _maxModelsPerProvider;
      if (extra > 0) {
        items.add(
          PopupMenuItem<_ModelPickerChoice>(
            enabled: false,
            height: 24,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              '…and $extra more — refine endpoint to narrow the list',
              style: TextStyle(color: c.mutedFg, fontSize: ThemeConstants.uiFontSizeSmall, fontStyle: FontStyle.italic),
            ),
          ),
        );
      }
    }

    items.add(const PopupMenuDivider());
    items.add(
      PopupMenuItem<_ModelPickerChoice>(
        value: const _RefreshChoice(),
        height: 28,
        child: Text(
          '↺  Refresh models',
          style: TextStyle(color: c.mutedFg, fontSize: ThemeConstants.uiFontSizeSmall),
        ),
      ),
    );

    showInstantMenu<_ModelPickerChoice>(
      context: context,
      position: _menuAbove(context, box),
      openAbove: true,
      color: c.panelBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(7),
        side: BorderSide(color: c.subtleBorder),
      ),
      items: items,
    ).then((value) async {
      if (value == null) return;
      switch (value) {
        case _RefreshChoice():
          // Reopen the picker regardless of refresh outcome — any error is
          // surfaced by the `ref.listen(availableModelsProvider, …)` listener
          // in `build()` as a snackbar, and the prior model list is retained
          // via copyWithPrevious so the reopened picker isn't empty.
          await ref.read(availableModelsProvider.notifier).refresh();
          if (!context.mounted) return;
          _showModelPicker(context);
        case _ModelChoice(:final model):
          ref.read(sessionSettingsActionsProvider.notifier).updateModel(widget.sessionId, model);
      }
    });
  }

  String _failureMessage(ModelProviderFailure failure) => switch (failure) {
    ModelProviderUnreachable(:final provider) => 'Unreachable — check that ${provider.displayName} is running',
    ModelProviderAuth(:final provider) => '${provider.displayName} rejected the API key — check Settings',
    ModelProviderMalformedResponse(:final provider) =>
      '${provider.displayName} returned an unexpected response — check the endpoint',
    ModelProviderUnknown(:final provider) => 'Couldn\'t load ${provider.displayName} models',
  };

  @override
  Widget build(BuildContext context) {
    ref.listen(chatMessagesProvider(widget.sessionId), (_, next) {
      if (!_isSending) return;
      if (next is! AsyncError || !mounted) return;
      showErrorSnackBar(context, 'Failed to send message. Please try again.');
    });

    ref.listen(pendingMessageActionProvider(widget.sessionId), (_, action) {
      if (action == null) return;
      ref.read(pendingMessageActionProvider(widget.sessionId).notifier).clear();
      _controller.text = action.content;
      _controller.selection = TextSelection.collapsed(offset: action.content.length);
      if (action is RetryAction) {
        _send();
      } else {
        _focusNode.requestFocus();
      }
    });

    // Initialise (idempotent after first call) and listen for persist errors.
    ref.listen(sessionSettingsActionsProvider, (_, next) {
      if (next is! AsyncError || !mounted) return;
      if (next.error is! SessionSettingsFailure) return;
      showErrorSnackBar(context, 'Could not save session settings.');
    });

    // Top-level catastrophes in the dynamic-model fetch (storage read failure).
    // Per-provider fetch failures are NOT surfaced here — they ride inside
    // `AvailableModelsResult.failures` and render inline in the picker.
    ref.listen(availableModelsProvider, (_, next) {
      if (next is! AsyncError || !mounted) return;
      final failure = next.error;
      if (failure is! AvailableModelsFailure) return;
      switch (failure) {
        case AvailableModelsStorageError():
          showErrorSnackBar(context, 'Couldn\'t load model list — storage unavailable.');
      }
    });

    final c = AppColors.of(context);
    final model = ref.watch(selectedModelProvider);
    final availableState = ref.watch(availableModelsProvider);
    // `hasValue` stays true across a storage-failed refresh thanks to
    // Riverpod's built-in `copyWithPrevious` — the prior list is retained so
    // this flag reflects real staleness, not transient load/error churn.
    // During the initial load (no prior value) we deliberately don't mark
    // the model stale: `AIModels.fromId` matches and, if it doesn't, the
    // picker itself is the place to warn.
    final isModelStale =
        availableState.hasValue && !availableState.value!.models.any((m) => m.modelId == model.modelId);
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
                      isLoading: availableState.isLoading,
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
                  if (_isSending)
                    AnimatedBuilder(
                      animation: _pulseOpacity,
                      builder: (context, child) => Opacity(opacity: _pulseOpacity.value, child: child),
                      child: GestureDetector(
                        onTap: () {
                          ref.read(chatMessagesProvider(widget.sessionId).notifier).cancelSend();
                          _controller.text = _lastSentText;
                          _controller.selection = TextSelection.collapsed(offset: _lastSentText.length);
                          _pulseController.stop();
                          _pulseController.reset();
                          setState(() => _isSending = false);
                        },
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: c.glassFill,
                            border: Border.all(color: c.glassBorder),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          alignment: Alignment.center,
                          child: Icon(AppIcons.stop, size: 13, color: c.warning),
                        ),
                      ),
                    )
                  else
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
                          if (hasText && !isMissing) {
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
                            onTap: _send,
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                gradient: (hasText && !isMissing)
                                    ? LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [lc.accent, lc.accentHover],
                                      )
                                    : null,
                                color: (!hasText || isMissing) ? bg : null,
                                borderRadius: BorderRadius.circular(7),
                                border: border,
                                boxShadow: shadows,
                              ),
                              child: Center(child: Icon(AppIcons.arrowUp, size: 14, color: iconColor)),
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
  const _ControlChip({
    this.icon,
    required this.label,
    required this.onTap,
    this.isWarning = false,
    this.isLoading = false,
  });
  final IconData? icon;
  final String label;
  final VoidCallback onTap;
  final bool isWarning;
  final bool isLoading;

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
            if (isLoading)
              SizedBox(
                width: 10,
                height: 10,
                child: CircularProgressIndicator(strokeWidth: 1.2, valueColor: AlwaysStoppedAnimation(c.faintFg)),
              )
            else
              Icon(AppIcons.chevronDown, size: 10, color: c.faintFg),
          ],
        ),
      ),
    );
  }
}
