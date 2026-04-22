import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:re_editor/re_editor.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/theme_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../data/mcp/models/mcp_server_config.dart';

class McpServerEditorDialog extends StatefulWidget {
  const McpServerEditorDialog({super.key, this.initial, required this.onSave});

  final McpServerConfig? initial;
  final Future<void> Function(McpServerConfig) onSave;

  @override
  State<McpServerEditorDialog> createState() => _McpServerEditorDialogState();
}

enum _EditorView { form, json }

typedef _State = _McpServerEditorDialogState;

class _McpServerEditorDialogState extends State<McpServerEditorDialog> {
  static const _uuid = Uuid();
  // Bidi override code points U+202A..U+202E and U+2066..U+2069.
  static final _bidiRe = RegExp('[\u202a-\u202e\u2066-\u2069]');

  late McpServerConfig _draft;
  _EditorView _view = _EditorView.form;
  String? _jsonError;
  bool _saving = false;

  late final TextEditingController _nameCtrl;
  late final TextEditingController _commandCtrl;
  late final TextEditingController _urlCtrl;
  late final CodeLineEditingController _jsonCtrl;

  // Env vars are kept as a list of mutable key/value pairs for the form view.
  late List<_EnvEntry> _envEntries;

  @override
  void initState() {
    super.initState();
    final init = widget.initial ?? McpServerConfig(id: _uuid.v4(), name: '', transport: McpTransport.stdio);
    _draft = init;

    _nameCtrl = TextEditingController(text: init.name);
    _commandCtrl = TextEditingController(text: init.command ?? '');
    _urlCtrl = TextEditingController(text: init.url ?? '');
    _jsonCtrl = CodeLineEditingController.fromText(_prettyJson(init));
    _envEntries = init.env.entries.map((e) => _EnvEntry(e.key, e.value)).toList();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _commandCtrl.dispose();
    _urlCtrl.dispose();
    _jsonCtrl.dispose();
    for (final e in _envEntries) e.dispose();
    super.dispose();
  }

  String _sanitize(String s) => s.replaceAll(_bidiRe, '').replaceAll('\x00', '');

  McpServerConfig _buildFromForm() {
    final env = <String, String>{
      for (final e in _envEntries)
        if (e.key.trim().isNotEmpty) _sanitize(e.key.trim()): _sanitize(e.value),
    };
    return _draft.copyWith(
      name: _sanitize(_nameCtrl.text.trim()),
      command: _draft.transport == McpTransport.stdio ? _sanitize(_commandCtrl.text.trim()) : null,
      url: _draft.transport == McpTransport.httpSse ? _sanitize(_urlCtrl.text.trim()) : null,
      env: env,
    );
  }

  String _prettyJson(McpServerConfig cfg) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(cfg.toJson());
  }

  /// Switches between form and JSON views, syncing state.
  /// Returns false (and sets [_jsonError]) if JSON is unparseable when
  /// switching json → form.
  bool _switchView(_EditorView target) {
    if (target == _view) return true;

    if (_view == _EditorView.form) {
      // form → json: render current form state into the JSON editor
      final updated = _buildFromForm();
      _draft = updated;
      _jsonCtrl.text = _prettyJson(updated);
      setState(() {
        _view = target;
        _jsonError = null;
      });
      return true;
    } else {
      // json → form: parse JSON back into draft
      final raw = _jsonCtrl.text;
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        final parsed = McpServerConfig.fromJson(map);
        _draft = parsed;
        _nameCtrl.text = parsed.name;
        _commandCtrl.text = parsed.command ?? '';
        _urlCtrl.text = parsed.url ?? '';
        for (final e in _envEntries) e.dispose();
        _envEntries = parsed.env.entries.map((e) => _EnvEntry(e.key, e.value)).toList();
        setState(() {
          _view = target;
          _jsonError = null;
        });
        return true;
      } on FormatException catch (e) {
        setState(() => _jsonError = 'Invalid JSON: ${e.message}');
        return false;
      } on TypeError {
        setState(() => _jsonError = 'JSON does not match server config schema');
        return false;
      }
    }
  }

  String? _validateUrl(String url) {
    if (url.isEmpty) return 'URL is required for HTTP/SSE transport';
    final uri = Uri.tryParse(url);
    if (uri == null) return 'Invalid URL';
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      return 'URL must start with http:// or https://';
    }
    return null;
  }

  Future<void> _save() async {
    McpServerConfig config;

    if (_view == _EditorView.form) {
      if (_draft.transport == McpTransport.httpSse) {
        final urlError = _validateUrl(_urlCtrl.text.trim());
        if (urlError != null) {
          setState(() => _jsonError = urlError);
          return;
        }
      }
      config = _buildFromForm();
    } else {
      // JSON view — parse first; surface error inline rather than dismissing
      final raw = _jsonCtrl.text;
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        config = McpServerConfig.fromJson(map);
      } catch (e) {
        setState(() => _jsonError = 'Invalid JSON: ${e.toString()}');
        return;
      }
      // Validate URL scheme from JSON view too
      if (config.transport == McpTransport.httpSse) {
        final urlError = _validateUrl(config.url ?? '');
        if (urlError != null) {
          setState(() => _jsonError = urlError);
          return;
        }
      }
    }

    setState(() => _saving = true);
    try {
      await widget.onSave(config);
    } catch (_) {
      // onSave threw — stay open so user can retry.
      if (mounted) setState(() => _saving = false);
      return;
    }
    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.of(context).pop();
  }

  /// Public update helper — allows inner StatelessWidget helpers to trigger
  /// a rebuild without violating the [State.setState] protected-member rule.
  void update(VoidCallback fn) => setState(fn);

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final isEdit = widget.initial != null;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 640),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              decoration: BoxDecoration(
                color: c.dialogFill,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: c.dialogBorder),
                boxShadow: [
                  BoxShadow(color: c.shadowDeep, blurRadius: 64, offset: const Offset(0, 24)),
                  BoxShadow(color: c.dialogHighlight, blurRadius: 0, spreadRadius: 0, offset: const Offset(0, 1)),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Header(isEdit: isEdit, view: _view, onViewChanged: _switchView),
                    const SizedBox(height: 16),
                    if (_jsonError != null) ...[_ErrorBanner(message: _jsonError!), const SizedBox(height: 12)],
                    Expanded(
                      child: _view == _EditorView.form ? _FormView(s: this) : _JsonView(s: this),
                    ),
                    const SizedBox(height: 16),
                    _Footer(saving: _saving, onCancel: () => Navigator.of(context).pop(), onSave: _save),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.isEdit, required this.view, required this.onViewChanged});

  final bool isEdit;
  final _EditorView view;
  final bool Function(_EditorView) onViewChanged;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Row(
      children: [
        // Icon badge — matches AppDialog hasInputField:true sizing
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: c.accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: c.accentBorderTeal),
            boxShadow: [BoxShadow(color: c.accentGlowBadge, blurRadius: 14)],
          ),
          child: Icon(Icons.extension_outlined, size: 14, color: c.accent),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            isEdit ? 'Edit MCP Server' : 'Add MCP Server',
            style: TextStyle(color: c.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: 12),
        _TabToggle<_EditorView>(
          options: _EditorView.values,
          labels: const ['Form', 'JSON'],
          selected: view,
          onChanged: (v) {
            onViewChanged(v);
          },
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: c.errorTintBg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: c.destructiveBorder),
      ),
      child: Text(
        message,
        style: TextStyle(color: c.error, fontSize: ThemeConstants.uiFontSizeSmall),
      ),
    );
  }
}

class _Footer extends StatefulWidget {
  const _Footer({required this.saving, required this.onCancel, required this.onSave});

  final bool saving;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  @override
  State<_Footer> createState() => _FooterState();
}

class _FooterState extends State<_Footer> {
  bool _cancelHovered = false;
  bool _saveHovered = false;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        MouseRegion(
          cursor: widget.saving ? SystemMouseCursors.basic : SystemMouseCursors.click,
          onEnter: (_) => setState(() => _cancelHovered = true),
          onExit: (_) => setState(() => _cancelHovered = false),
          child: GestureDetector(
            onTap: widget.saving ? null : widget.onCancel,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: _cancelHovered && !widget.saving ? c.chipStroke : c.chipFill,
                border: Border.all(color: c.chipStroke),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Opacity(
                opacity: widget.saving ? 0.5 : 1.0,
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: c.textPrimary,
                    fontSize: ThemeConstants.uiFontSizeSmall,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        MouseRegion(
          cursor: widget.saving ? SystemMouseCursors.basic : SystemMouseCursors.click,
          onEnter: (_) => setState(() => _saveHovered = true),
          onExit: (_) => setState(() => _saveHovered = false),
          child: GestureDetector(
            onTap: widget.saving ? null : widget.onSave,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 100),
              opacity: _saveHovered && !widget.saving ? 0.82 : 1.0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [c.accent, c.accentHover],
                  ),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [BoxShadow(color: c.sendGlow, blurRadius: 10, offset: const Offset(0, 2))],
                ),
                child: widget.saving
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: c.onAccent),
                      )
                    : Text(
                        'Save',
                        style: TextStyle(
                          color: c.onAccent,
                          fontSize: ThemeConstants.uiFontSizeSmall,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FormView extends StatelessWidget {
  const _FormView({required this.s});
  final _State s;

  @override
  Widget build(BuildContext context) {
    final transport = s._draft.transport;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _FieldLabel(text: 'Name'),
          const SizedBox(height: 6),
          AppTextField(controller: s._nameCtrl, hintText: 'e.g. My MCP Server'),
          const SizedBox(height: 16),

          _FieldLabel(text: 'Transport'),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: _TabToggle<McpTransport>(
              options: McpTransport.values,
              labels: const ['stdio', 'HTTP/SSE'],
              selected: transport,
              onChanged: (t) {
                s.update(() => s._draft = s._draft.copyWith(transport: t));
              },
            ),
          ),
          const SizedBox(height: 16),

          if (transport == McpTransport.stdio) ...[
            _FieldLabel(text: 'Command'),
            const SizedBox(height: 6),
            AppTextField(
              controller: s._commandCtrl,
              hintText: 'e.g. npx -y @modelcontextprotocol/server-filesystem /tmp',
              fontFamily: ThemeConstants.editorFontFamily,
            ),
          ] else ...[
            _FieldLabel(text: 'URL'),
            const SizedBox(height: 6),
            AppTextField(controller: s._urlCtrl, hintText: 'e.g. http://localhost:3000/sse'),
          ],
          const SizedBox(height: 20),

          _EnvVarsEditor(s: s),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Text(
      text,
      style: TextStyle(color: c.textSecondary, fontSize: ThemeConstants.uiFontSizeSmall, fontWeight: FontWeight.w500),
    );
  }
}

class _EnvEntry {
  _EnvEntry(String k, String v) : keyCtrl = TextEditingController(text: k), valCtrl = TextEditingController(text: v);

  final TextEditingController keyCtrl;
  final TextEditingController valCtrl;

  void dispose() {
    keyCtrl.dispose();
    valCtrl.dispose();
  }

  String get key => keyCtrl.text;
  String get value => valCtrl.text;
}

class _AddEnvButton extends StatefulWidget {
  const _AddEnvButton({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_AddEnvButton> createState() => _AddEnvButtonState();
}

class _AddEnvButtonState extends State<_AddEnvButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _hovered ? c.chipStroke : c.chipFill,
            border: Border.all(color: c.chipStroke),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add, size: 12, color: c.textSecondary),
              const SizedBox(width: 4),
              Text(
                'Add',
                style: TextStyle(color: c.textSecondary, fontSize: ThemeConstants.uiFontSizeSmall),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EnvVarsEditor extends StatelessWidget {
  const _EnvVarsEditor({required this.s});
  final _State s;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final entries = s._envEntries;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              'Environment Variables',
              style: TextStyle(
                color: c.textSecondary,
                fontSize: ThemeConstants.uiFontSizeSmall,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            _AddEnvButton(onTap: () => s.update(() => s._envEntries.add(_EnvEntry('', '')))),
          ],
        ),
        if (entries.isNotEmpty) ...[
          const SizedBox(height: 8),
          for (var i = 0; i < entries.length; i++) ...[
            _EnvRow(
              entry: entries[i],
              onRemove: () {
                entries[i].dispose();
                s.update(() => s._envEntries.removeAt(i));
              },
            ),
            if (i < entries.length - 1) const SizedBox(height: 6),
          ],
        ],
      ],
    );
  }
}

class _EnvRow extends StatelessWidget {
  const _EnvRow({required this.entry, required this.onRemove});

  final _EnvEntry entry;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Row(
      children: [
        Expanded(
          child: AppTextField(
            controller: entry.keyCtrl,
            hintText: 'KEY',
            fontFamily: ThemeConstants.editorFontFamily,
            fontSize: ThemeConstants.uiFontSize,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          flex: 2,
          child: AppTextField(controller: entry.valCtrl, hintText: 'value'),
        ),
        const SizedBox(width: 4),
        IconButton(
          icon: Icon(Icons.close, size: 14, color: c.textSecondary),
          onPressed: onRemove,
          tooltip: 'Remove',
          visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
        ),
      ],
    );
  }
}

class _TabToggle<T extends Object> extends StatelessWidget {
  const _TabToggle({required this.options, required this.labels, required this.selected, required this.onChanged});

  final List<T> options;
  final List<String> labels;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: c.chipStroke),
          borderRadius: BorderRadius.circular(6),
        ),
        child: IntrinsicHeight(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 0; i < options.length; i++) ...[
                if (i > 0) VerticalDivider(width: 1, thickness: 1, color: c.chipStroke),
                _TabToggleItem(
                  label: labels[i],
                  isSelected: options[i] == selected,
                  onTap: () {
                    if (options[i] == selected) return;
                    onChanged(options[i]);
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TabToggleItem extends StatefulWidget {
  const _TabToggleItem({required this.label, required this.isSelected, required this.onTap});

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_TabToggleItem> createState() => _TabToggleItemState();
}

class _TabToggleItemState extends State<_TabToggleItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          color: widget.isSelected
              ? c.accentTintMid
              : _hovered
              ? c.chipStroke
              : c.chipFill,
          child: Text(
            widget.label,
            style: TextStyle(
              color: widget.isSelected || _hovered ? c.textPrimary : c.textSecondary,
              fontSize: ThemeConstants.uiFontSizeSmall,
              fontWeight: widget.isSelected ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

class _JsonView extends StatelessWidget {
  const _JsonView({required this.s});
  final _State s;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: CodeEditor(
        controller: s._jsonCtrl,
        style: CodeEditorStyle(
          backgroundColor: c.jsonEditorBg,
          codeTheme: c.jsonHighlightTheme,
          cursorColor: c.accent,
          selectionColor: c.selectionBg,
          fontSize: ThemeConstants.editorFontSize,
          fontFamily: ThemeConstants.editorFontFamily,
        ),
        wordWrap: true,
        indicatorBuilder: (context, editingController, chunkController, notifier) {
          return Row(
            children: [
              DefaultCodeLineNumber(
                controller: editingController,
                notifier: notifier,
                textStyle: TextStyle(fontSize: ThemeConstants.uiFontSize, color: c.editorGutterForeground),
              ),
              DefaultCodeChunkIndicator(width: 20, controller: chunkController, notifier: notifier),
            ],
          );
        },
        border: Border.all(color: c.fieldStroke),
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}
