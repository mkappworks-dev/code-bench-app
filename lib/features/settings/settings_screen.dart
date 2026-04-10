import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/constants/api_constants.dart';
import '../../core/constants/theme_constants.dart';
import '../../core/utils/instant_menu.dart';
import '../../data/datasources/local/general_preferences.dart';
import '../../data/datasources/local/secure_storage_source.dart';
import '../../data/models/ai_model.dart';
import '../../services/ai/ai_service_factory.dart';
import '../../services/session/session_service.dart';
import 'archive_screen.dart';

enum _SettingsNav { general, providers, archive }

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  _SettingsNav _activeNav = _SettingsNav.general;

  // Provider API key controllers
  final _controllers = <AIProvider, TextEditingController>{
    AIProvider.openai: TextEditingController(),
    AIProvider.anthropic: TextEditingController(),
    AIProvider.gemini: TextEditingController(),
  };
  final _ollamaController = TextEditingController();
  final _customEndpointController = TextEditingController();
  final _customApiKeyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadKeys();
  }

  Future<void> _loadKeys() async {
    final storage = ref.read(secureStorageSourceProvider);
    for (final provider in _controllers.keys) {
      final key = await storage.readApiKey(provider.name);
      if (key != null) _controllers[provider]!.text = key;
    }
    final ollamaUrl = await storage.readOllamaUrl();
    _ollamaController.text = ollamaUrl ?? ApiConstants.ollamaDefaultBaseUrl;
    final customEndpoint = await storage.readCustomEndpoint();
    if (customEndpoint != null) _customEndpointController.text = customEndpoint;
    final customApiKey = await storage.readCustomApiKey();
    if (customApiKey != null) _customApiKeyController.text = customApiKey;
    setState(() {});
  }

  Future<void> _saveKeys() async {
    final storage = ref.read(secureStorageSourceProvider);
    for (final entry in _controllers.entries) {
      final key = entry.value.text.trim();
      if (key.isNotEmpty) {
        await storage.writeApiKey(entry.key.name, key);
      } else {
        await storage.deleteApiKey(entry.key.name);
      }
    }
    final ollamaUrl = _ollamaController.text.trim();
    if (ollamaUrl.isNotEmpty) await storage.writeOllamaUrl(ollamaUrl);
    await storage.writeCustomEndpoint(_customEndpointController.text.trim());
    await storage.writeCustomApiKey(_customApiKeyController.text.trim());
    ref.invalidate(aiServiceProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved'),
          backgroundColor: ThemeConstants.success,
        ),
      );
    }
  }

  Future<void> _deleteKey(AIProvider provider) async {
    final storage = ref.read(secureStorageSourceProvider);
    await storage.deleteApiKey(provider.name);
    _controllers[provider]!.clear();
    ref.invalidate(aiServiceProvider);
  }

  Future<void> _testOllama() async {
    final url = _ollamaController.text.trim();
    try {
      final testDio = Dio(
        BaseOptions(baseUrl: url, connectTimeout: const Duration(seconds: 5)),
      );
      await testDio.get('/api/tags');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ollama is running!'),
            backgroundColor: ThemeConstants.success,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot connect to Ollama.'),
            backgroundColor: ThemeConstants.error,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    _ollamaController.dispose();
    _customEndpointController.dispose();
    _customApiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeConstants.background,
      body: Column(
        children: [
          // Header bar
          _SettingsHeaderBar(
            onRestoreDefaults: _restoreDefaults,
          ),
          Expanded(
            child: Row(
              children: [
                // Left nav (200px)
                _SettingsLeftNav(
                  activeNav: _activeNav,
                  onSelect: (nav) => setState(() => _activeNav = nav),
                  onBack: () => context.go('/chat'),
                ),
                // Content area
                Expanded(
                  child: Container(
                    color: ThemeConstants.sidebarBackground,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    child: _buildContent(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_activeNav) {
      case _SettingsNav.general:
        return _GeneralSection(
          generalPrefs: ref.read(generalPreferencesProvider),
        );
      case _SettingsNav.providers:
        return _ProvidersSection(
          controllers: _controllers,
          ollamaController: _ollamaController,
          customEndpointController: _customEndpointController,
          customApiKeyController: _customApiKeyController,
          onSave: _saveKeys,
          onDeleteKey: _deleteKey,
          onTestOllama: _testOllama,
        );
      case _SettingsNav.archive:
        return ArchiveScreen(
          onUnarchive: (id) => ref.read(sessionServiceProvider).unarchiveSession(id),
        );
    }
  }

  Future<void> _restoreDefaults() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ThemeConstants.panelBackground,
        title: const Text(
          'Restore defaults?',
          style: TextStyle(color: ThemeConstants.textPrimary, fontSize: 14),
        ),
        content: const Text(
          'All settings will be reset to their default values.',
          style: TextStyle(color: ThemeConstants.textSecondary, fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final prefs = ref.read(generalPreferencesProvider);
    await prefs.setAutoCommit(false);
    await prefs.setTerminalApp('Terminal');
    await prefs.setDeleteConfirmation(true);
    if (mounted) setState(() {});
  }
}

// ── Header bar ────────────────────────────────────────────────────────────────

class _SettingsHeaderBar extends StatelessWidget {
  const _SettingsHeaderBar({required this.onRestoreDefaults});

  final VoidCallback onRestoreDefaults;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      decoration: const BoxDecoration(
        color: ThemeConstants.inputBackground,
        border: Border(bottom: BorderSide(color: ThemeConstants.borderColor)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Spacer(),
          TextButton(
            onPressed: onRestoreDefaults,
            child: const Text(
              '↺ Restore defaults',
              style: TextStyle(
                color: ThemeConstants.textSecondary,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Left nav ──────────────────────────────────────────────────────────────────

class _SettingsLeftNav extends StatelessWidget {
  const _SettingsLeftNav({
    required this.activeNav,
    required this.onSelect,
    required this.onBack,
  });

  final _SettingsNav activeNav;
  final ValueChanged<_SettingsNav> onSelect;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      decoration: const BoxDecoration(
        color: ThemeConstants.activityBar,
        border: Border(right: BorderSide(color: ThemeConstants.borderColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Text(
              'Settings',
              style: TextStyle(
                color: ThemeConstants.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          _NavItem(
            icon: LucideIcons.settings,
            label: 'General',
            isActive: activeNav == _SettingsNav.general,
            onTap: () => onSelect(_SettingsNav.general),
          ),
          _NavItem(
            icon: LucideIcons.messageSquare,
            label: 'Providers',
            isActive: activeNav == _SettingsNav.providers,
            onTap: () => onSelect(_SettingsNav.providers),
          ),
          _NavItem(
            icon: LucideIcons.archive,
            label: 'Archive',
            isActive: activeNav == _SettingsNav.archive,
            onTap: () => onSelect(_SettingsNav.archive),
          ),
          const Spacer(),
          _NavItem(
            icon: LucideIcons.arrowLeft,
            label: 'Back',
            isActive: false,
            onTap: onBack,
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? ThemeConstants.inputSurface : null,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: isActive ? ThemeConstants.textPrimary : ThemeConstants.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isActive ? ThemeConstants.textPrimary : ThemeConstants.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── General section ───────────────────────────────────────────────────────────

class _GeneralSection extends StatefulWidget {
  const _GeneralSection({required this.generalPrefs});

  final GeneralPreferences generalPrefs;

  @override
  State<_GeneralSection> createState() => _GeneralSectionState();
}

class _GeneralSectionState extends State<_GeneralSection> {
  bool _autoCommit = false;
  bool _deleteConfirmation = true;
  final _terminalAppController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final autoCommit = await widget.generalPrefs.getAutoCommit();
    final deleteConfirm = await widget.generalPrefs.getDeleteConfirmation();
    final terminalApp = await widget.generalPrefs.getTerminalApp();
    setState(() {
      _autoCommit = autoCommit;
      _deleteConfirmation = deleteConfirm;
      _terminalAppController.text = terminalApp;
    });
  }

  @override
  void dispose() {
    _terminalAppController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel('General'),
          const SizedBox(height: 8),
          _SettingsGroup(rows: [
            _SettingsRow(
              label: 'Theme',
              description: 'How Code Bench looks',
              trailing: Builder(
                builder: (ctx) => _AppDropdown<String>(
                  value: 'Dark',
                  items: const ['Dark', 'Light', 'System'],
                  label: (s) => s,
                  onChanged: (_) {},
                  context: ctx,
                ),
              ),
            ),
            _SettingsRow(
              label: 'Delete confirmation',
              description: 'Ask before deleting a session',
              trailing: Builder(
                builder: (ctx) => _AppDropdown<bool>(
                  value: _deleteConfirmation,
                  items: const [true, false],
                  label: (v) => v ? 'Enabled' : 'Disabled',
                  onChanged: (v) async {
                    await widget.generalPrefs.setDeleteConfirmation(v);
                    setState(() => _deleteConfirmation = v);
                  },
                  context: ctx,
                ),
              ),
            ),
            _SettingsRow(
              label: 'Auto-commit',
              description: 'Skip commit dialog; commit immediately with AI-generated message',
              trailing: Builder(
                builder: (ctx) => _AppDropdown<bool>(
                  value: _autoCommit,
                  items: const [true, false],
                  label: (v) => v ? 'Enabled' : 'Disabled',
                  onChanged: (v) async {
                    await widget.generalPrefs.setAutoCommit(v);
                    setState(() => _autoCommit = v);
                  },
                  context: ctx,
                ),
              ),
            ),
            _SettingsRow(
              label: 'Terminal app',
              description: 'App to open when "Open Terminal" is tapped',
              trailing: SizedBox(
                width: 140,
                child: _InlineTextField(controller: _terminalAppController),
              ),
              isLast: true,
            ),
          ]),
          const SizedBox(height: 24),
          _SectionLabel('About'),
          const SizedBox(height: 8),
          _SettingsGroup(rows: [
            _SettingsRow(
              label: 'Version',
              description: 'Current app version',
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: ThemeConstants.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Up to Date',
                  style: TextStyle(
                    color: ThemeConstants.success,
                    fontSize: 10,
                  ),
                ),
              ),
              isLast: true,
            ),
          ]),
        ],
      ),
    );
  }
}

// ── Providers section ─────────────────────────────────────────────────────────

class _ProvidersSection extends StatelessWidget {
  const _ProvidersSection({
    required this.controllers,
    required this.ollamaController,
    required this.customEndpointController,
    required this.customApiKeyController,
    required this.onSave,
    required this.onDeleteKey,
    required this.onTestOllama,
  });

  final Map<AIProvider, TextEditingController> controllers;
  final TextEditingController ollamaController;
  final TextEditingController customEndpointController;
  final TextEditingController customApiKeyController;
  final VoidCallback onSave;
  final void Function(AIProvider) onDeleteKey;
  final VoidCallback onTestOllama;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel('API Keys'),
          const SizedBox(height: 8),
          ...AIProvider.values.where((p) => p != AIProvider.ollama && p != AIProvider.custom).map(
                (provider) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ProviderKeyCard(
                    provider: provider,
                    controller: controllers[provider]!,
                    onDelete: () => onDeleteKey(provider),
                  ),
                ),
              ),
          const SizedBox(height: 16),
          _SectionLabel('Ollama (Local)'),
          const SizedBox(height: 8),
          _SettingsGroup(rows: [
            _SettingsRow(
              label: 'Base URL',
              description: ApiConstants.ollamaDefaultBaseUrl,
              trailing: SizedBox(
                width: 200,
                child: _InlineTextField(controller: ollamaController),
              ),
              isLast: true,
            ),
          ]),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onTestOllama,
            icon: const Icon(LucideIcons.play, size: 12),
            label: const Text('Test Connection', style: TextStyle(fontSize: 11)),
          ),
          const SizedBox(height: 16),
          _SectionLabel('Custom Endpoint (OpenAI-compatible)'),
          const SizedBox(height: 8),
          _SettingsGroup(rows: [
            _SettingsRow(
              label: 'Base URL',
              description: 'http://localhost:1234/v1',
              trailing: SizedBox(
                width: 200,
                child: _InlineTextField(controller: customEndpointController),
              ),
            ),
            _SettingsRow(
              label: 'API Key',
              description: 'sk-... or leave blank',
              trailing: SizedBox(
                width: 200,
                child: _InlineTextField(
                  controller: customApiKeyController,
                  obscureText: true,
                ),
              ),
              isLast: true,
            ),
          ]),
          const SizedBox(height: 24),
          SizedBox(
            width: 160,
            child: ElevatedButton(
              onPressed: onSave,
              child: const Text('Save', style: TextStyle(fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProviderKeyCard extends StatefulWidget {
  const _ProviderKeyCard({
    required this.provider,
    required this.controller,
    required this.onDelete,
  });

  final AIProvider provider;
  final TextEditingController controller;
  final VoidCallback onDelete;

  @override
  State<_ProviderKeyCard> createState() => _ProviderKeyCardState();
}

class _ProviderKeyCardState extends State<_ProviderKeyCard> {
  bool _obscure = true;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final hasKey = widget.controller.text.isNotEmpty;
    return Container(
      decoration: BoxDecoration(
        color: ThemeConstants.inputSurface,
        border: Border.all(color: ThemeConstants.deepBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: hasKey ? ThemeConstants.success : ThemeConstants.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    widget.provider.displayName,
                    style: const TextStyle(
                      color: ThemeConstants.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    hasKey ? 'Configured' : 'Not configured',
                    style: const TextStyle(
                      color: ThemeConstants.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _expanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                    size: 14,
                    color: ThemeConstants.mutedFg,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: widget.controller,
                      obscureText: _obscure,
                      style: const TextStyle(
                        color: ThemeConstants.textPrimary,
                        fontSize: 12,
                        fontFamily: ThemeConstants.editorFontFamily,
                      ),
                      decoration: InputDecoration(
                        hintText: 'API key',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure ? LucideIcons.eyeOff : LucideIcons.eye,
                            size: 14,
                          ),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(LucideIcons.x, size: 14, color: ThemeConstants.error),
                    tooltip: 'Remove key',
                    onPressed: widget.onDelete,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── Shared row/group components ───────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        color: ThemeConstants.mutedFg,
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.rows});

  final List<_SettingsRow> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: ThemeConstants.deepBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            if (i > 0)
              const Divider(
                height: 1,
                color: ThemeConstants.deepBorder,
              ),
            rows[i],
          ],
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.label,
    required this.description,
    required this.trailing,
    this.isLast = false,
  });

  final String label;
  final String description;
  final Widget trailing;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: ThemeConstants.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    color: ThemeConstants.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          trailing,
        ],
      ),
    );
  }
}

class _InlineTextField extends StatelessWidget {
  const _InlineTextField({
    required this.controller,
    this.obscureText = false,
  });

  final TextEditingController controller;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(
        color: ThemeConstants.textPrimary,
        fontSize: 12,
        fontFamily: ThemeConstants.editorFontFamily,
      ),
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      ),
    );
  }
}

class _AppDropdown<T> extends StatelessWidget {
  const _AppDropdown({
    required this.value,
    required this.items,
    required this.label,
    required this.onChanged,
    required this.context,
  });

  final T value;
  final List<T> items;
  final String Function(T) label;
  final void Function(T) onChanged;
  final BuildContext context;

  void _open() {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final origin = box.localToGlobal(Offset.zero, ancestor: overlay);
    showInstantMenu<T>(
      context: context,
      position: RelativeRect.fromLTRB(
        origin.dx,
        origin.dy + box.size.height + 4,
        overlay.size.width - origin.dx - box.size.width,
        0,
      ),
      color: ThemeConstants.panelBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: const BorderSide(color: Color(0xFF333333)),
      ),
      items: items
          .map((item) => PopupMenuItem<T>(
                value: item,
                height: 30,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        label(item),
                        style: TextStyle(
                          color: item == value ? ThemeConstants.textPrimary : ThemeConstants.textSecondary,
                          fontSize: ThemeConstants.uiFontSizeSmall,
                        ),
                      ),
                    ),
                    if (item == value) const Icon(LucideIcons.check, size: 11, color: ThemeConstants.accent),
                  ],
                ),
              ))
          .toList(),
    ).then((picked) {
      if (picked != null) onChanged(picked);
    });
  }

  @override
  Widget build(BuildContext _) {
    return InkWell(
      onTap: _open,
      borderRadius: BorderRadius.circular(5),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          border: Border.all(color: ThemeConstants.deepBorder),
          borderRadius: BorderRadius.circular(5),
          color: ThemeConstants.inputSurface,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label(value),
              style: const TextStyle(
                color: ThemeConstants.textPrimary,
                fontSize: ThemeConstants.uiFontSizeSmall,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(LucideIcons.chevronDown, size: 10, color: ThemeConstants.mutedFg),
          ],
        ),
      ),
    );
  }
}
