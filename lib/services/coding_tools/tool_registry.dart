// lib/services/coding_tools/tool_registry.dart

import 'package:collection/collection.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/utils/debug_logger.dart';
import '../../data/coding_tools/models/coding_tool_result.dart';
import '../../data/coding_tools/models/denylist_category.dart';
import '../../data/coding_tools/models/effective_denylist.dart';
import '../../data/coding_tools/models/tool.dart';
import '../../data/coding_tools/models/tool_capability.dart';
import '../../data/coding_tools/models/tool_context.dart';
import '../../data/coding_tools/repository/coding_tools_denylist_repository.dart';
import '../../data/coding_tools/repository/coding_tools_denylist_repository_impl.dart';
import '../../data/session/models/session_settings.dart';
import 'tools/list_dir_tool.dart';
import 'tools/read_file_tool.dart';
import 'tools/str_replace_tool.dart';
import 'tools/write_file_tool.dart';

part 'tool_registry.g.dart';

@Riverpod(keepAlive: true)
ToolRegistry toolRegistry(Ref ref) => ToolRegistry(
  builtIns: [
    ref.watch(readFileToolProvider),
    ref.watch(listDirToolProvider),
    ref.watch(writeFileToolProvider),
    ref.watch(strReplaceToolProvider),
  ],
  denylistRepo: ref.watch(codingToolsDenylistRepositoryProvider),
);

/// Central registry of all tools the agent loop may call. Holds built-in
/// tools and — via [register] — runtime-added tools (the seam MCP will
/// plug into in Phase 7).
///
/// Replaces the static `CodingTools.all` catalog and the `switch(toolName)`
/// dispatch in the deleted `CodingToolsService`.
class ToolRegistry {
  ToolRegistry({required List<Tool> builtIns, required CodingToolsDenylistRepository denylistRepo})
    : _tools = [...builtIns],
      _denylistRepo = denylistRepo;

  final List<Tool> _tools;
  final CodingToolsDenylistRepository _denylistRepo;

  List<Tool> get tools => List.unmodifiable(_tools);

  Tool? byName(String name) => _tools.firstWhereOrNull((t) => t.name == name);

  List<Tool> byCapability(ToolCapability c) => _tools.where((t) => t.capability == c).toList();

  /// Tools the agent is allowed to see under [p]. In readOnly mode the
  /// model receives only tools tagged [ToolCapability.readOnly]; in all
  /// other modes it receives every registered tool.
  List<Tool> visibleTools(ChatPermission p) => p == ChatPermission.readOnly
      ? _tools.where((t) => t.capability == ToolCapability.readOnly).toList()
      : List.unmodifiable(_tools);

  /// Whether invoking [t] should raise a PermissionRequest in [p].
  bool requiresPrompt(Tool t, ChatPermission p) =>
      p == ChatPermission.askBefore && t.capability != ToolCapability.readOnly;

  /// Dispatcher. Loads the effective denylist, builds a [ToolContext],
  /// delegates to the tool, wraps crash-catch + timing log.
  Future<CodingToolResult> execute({
    required String name,
    required String projectPath,
    required String sessionId,
    required String messageId,
    required Map<String, dynamic> args,
  }) async {
    final tool = byName(name);
    if (tool == null) return CodingToolResult.error('Unknown tool "$name"');

    final started = DateTime.now();
    dLog('[ToolRegistry] $name start');
    try {
      final effective = await _loadEffectiveDenylist();
      final ctx = ToolContext(
        projectPath: projectPath,
        sessionId: sessionId,
        messageId: messageId,
        args: args,
        denylist: effective,
      );
      return await tool.execute(ctx);
    } catch (e, st) {
      dLog('[ToolRegistry] $name crashed: ${e.runtimeType} $e\n$st');
      return CodingToolResult.error('Tool "$name" encountered an internal error.');
    } finally {
      final ms = DateTime.now().difference(started).inMilliseconds;
      dLog('[ToolRegistry] $name done in ${ms}ms');
    }
  }

  Future<EffectiveDenylist> _loadEffectiveDenylist() async => (
    segments: await _denylistRepo.effective(DenylistCategory.segment),
    filenames: await _denylistRepo.effective(DenylistCategory.filename),
    extensions: await _denylistRepo.effective(DenylistCategory.extension),
    prefixes: await _denylistRepo.effective(DenylistCategory.prefix),
  );

  /// Adds a tool at runtime. Phase-1 seam for Phase 7 MCP integration.
  /// Throws [StateError] if a tool with that name already exists.
  ///
  /// NOTE: mutation is not reactive. Watchers of toolRegistryProvider do
  /// not rebuild on register/unregister. AgentService reads the registry
  /// at the start of each turn so this is safe today. If Phase 7 needs
  /// reactive propagation, convert this class to a Notifier shape then.
  void register(Tool t) {
    if (_tools.any((x) => x.name == t.name)) {
      throw StateError('Tool "${t.name}" already registered');
    }
    _tools.add(t);
  }

  void unregister(String name) {
    _tools.removeWhere((t) => t.name == name);
  }
}
