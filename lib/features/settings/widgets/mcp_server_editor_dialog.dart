import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:re_editor/re_editor.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/mcp/models/mcp_server_config.dart';

// ---------------------------------------------------------------------------
// Public widget
// ---------------------------------------------------------------------------

class McpServerEditorDialog extends StatefulWidget {
  const McpServerEditorDialog({super.key, this.initial, required this.onSave});

  final McpServerConfig? initial;
  final Future<void> Function(McpServerConfig) onSave;

  @override
  State<McpServerEditorDialog> createState() => _McpServerEditorDialogState();
}

// ---------------------------------------------------------------------------
// Enum
// ---------------------------------------------------------------------------

enum _EditorView { form, json }

// ---------------------------------------------------------------------------
// Typedef alias so inner StatelessWidgets can reference the State type concisely
// ---------------------------------------------------------------------------

typedef _State = _McpServerEditorDialogState;

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

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

  // ── Helpers ──────────────────────────────────────────────────────────────

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

  Future<void> _save() async {
    McpServerConfig config;

    if (_view == _EditorView.form) {
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
    }

    setState(() => _saving = true);
    await widget.onSave(config);
    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.of(context).pop();
  }

  /// Public update helper — allows inner StatelessWidget helpers to trigger
  /// a rebuild without violating the [State.setState] protected-member rule.
  void update(VoidCallback fn) => setState(fn);

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final isEdit = widget.initial != null;

    return Dialog(
      backgroundColor: c.dialogFill,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: c.dialogBorder),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 640),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              _Header(isEdit: isEdit, view: _view, onViewChanged: _switchView),
              const SizedBox(height: 16),

              // JSON error banner
              if (_jsonError != null) ...[_ErrorBanner(message: _jsonError!), const SizedBox(height: 12)],

              // Body
              Expanded(
                child: _view == _EditorView.form ? _FormView(s: this) : _JsonView(s: this),
              ),
              const SizedBox(height: 20),

              // Footer
              _Footer(saving: _saving, onCancel: () => Navigator.of(context).pop(), onSave: _save),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  const _Header({required this.isEdit, required this.view, required this.onViewChanged});

  final bool isEdit;
  final _EditorView view;
  final bool Function(_EditorView) onViewChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(isEdit ? 'Edit MCP Server' : 'Add MCP Server', style: Theme.of(context).textTheme.titleLarge),
        ),
        const SizedBox(width: 16),
        SegmentedButton<_EditorView>(
          segments: const [
            ButtonSegment(value: _EditorView.form, label: Text('Form')),
            ButtonSegment(value: _EditorView.json, label: Text('JSON')),
          ],
          selected: {view},
          onSelectionChanged: (sel) => onViewChanged(sel.first),
          style: const ButtonStyle(visualDensity: VisualDensity(horizontal: -2, vertical: -2)),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Error banner
// ---------------------------------------------------------------------------

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
      child: Text(message, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: c.error)),
    );
  }
}

// ---------------------------------------------------------------------------
// Footer
// ---------------------------------------------------------------------------

class _Footer extends StatelessWidget {
  const _Footer({required this.saving, required this.onCancel, required this.onSave});

  final bool saving;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(onPressed: saving ? null : onCancel, child: const Text('Cancel')),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: saving ? null : onSave,
          child: saving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Save'),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Form view
// ---------------------------------------------------------------------------

class _FormView extends StatelessWidget {
  const _FormView({required this.s});
  final _State s;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final transport = s._draft.transport;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Name
          _FieldLabel(text: 'Name'),
          const SizedBox(height: 6),
          TextField(
            controller: s._nameCtrl,
            decoration: _inputDec(c, hint: 'e.g. My MCP Server'),
          ),
          const SizedBox(height: 16),

          // Transport selector
          _FieldLabel(text: 'Transport'),
          const SizedBox(height: 6),
          SegmentedButton<McpTransport>(
            segments: const [
              ButtonSegment(value: McpTransport.stdio, label: Text('stdio')),
              ButtonSegment(value: McpTransport.httpSse, label: Text('HTTP/SSE')),
            ],
            selected: {transport},
            onSelectionChanged: (sel) {
              s.update(() => s._draft = s._draft.copyWith(transport: sel.first));
            },
          ),
          const SizedBox(height: 16),

          // Conditional transport fields
          if (transport == McpTransport.stdio) ...[
            _FieldLabel(text: 'Command'),
            const SizedBox(height: 6),
            TextField(
              controller: s._commandCtrl,
              decoration: _inputDec(c, hint: 'e.g. npx -y @modelcontextprotocol/server-filesystem /tmp'),
            ),
          ] else ...[
            _FieldLabel(text: 'URL'),
            const SizedBox(height: 6),
            TextField(
              controller: s._urlCtrl,
              decoration: _inputDec(c, hint: 'e.g. http://localhost:3000/sse'),
            ),
          ],
          const SizedBox(height: 20),

          // Env vars
          _EnvVarsEditor(s: s),
        ],
      ),
    );
  }

  InputDecoration _inputDec(AppColors c, {String? hint}) => InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: c.fieldFill,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: BorderSide(color: c.fieldStroke),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: BorderSide(color: c.fieldStroke),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: BorderSide(color: c.accent, width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    isDense: true,
  );
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Text(text, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: c.textSecondary));
  }
}

// ---------------------------------------------------------------------------
// Env vars editor
// ---------------------------------------------------------------------------

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
              style: Theme.of(context).textTheme.labelMedium?.copyWith(color: c.textSecondary),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () {
                s.update(() => s._envEntries.add(_EnvEntry('', '')));
              },
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add'),
              style: TextButton.styleFrom(visualDensity: const VisualDensity(horizontal: -2, vertical: -2)),
            ),
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
              c: c,
            ),
            if (i < entries.length - 1) const SizedBox(height: 6),
          ],
        ],
      ],
    );
  }
}

class _EnvRow extends StatelessWidget {
  const _EnvRow({required this.entry, required this.onRemove, required this.c});

  final _EnvEntry entry;
  final VoidCallback onRemove;
  final AppColors c;

  @override
  Widget build(BuildContext context) {
    final inputDec = InputDecoration(
      filled: true,
      fillColor: c.fieldFill,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: c.fieldStroke),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: c.fieldStroke),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: c.accent, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      isDense: true,
    );

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: entry.keyCtrl,
            decoration: inputDec.copyWith(hintText: 'KEY'),
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          flex: 2,
          child: TextField(
            controller: entry.valCtrl,
            decoration: inputDec.copyWith(hintText: 'value'),
            style: const TextStyle(fontSize: 13),
          ),
        ),
        const SizedBox(width: 4),
        IconButton(
          icon: Icon(Icons.close, size: 16, color: c.textSecondary),
          onPressed: onRemove,
          tooltip: 'Remove',
          visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// JSON view
// ---------------------------------------------------------------------------

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
          backgroundColor: c.codeBlockBg,
          textColor: c.textPrimary,
          cursorColor: c.accent,
          selectionColor: c.selectionBg,
          fontSize: 13,
          fontFamily: 'monospace',
        ),
        wordWrap: true,
        indicatorBuilder: (context, editingController, chunkController, notifier) {
          return Row(
            children: [
              DefaultCodeLineNumber(
                controller: editingController,
                notifier: notifier,
                textStyle: TextStyle(fontSize: 12, color: c.editorGutterForeground),
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
