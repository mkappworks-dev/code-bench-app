import '../../../data/coding_tools/models/tool_capability.dart';

enum PhaseClass { think, tool, io }

PhaseClass classifyTool(String toolName, ToolCapability? capability) {
  if (capability != null) {
    return switch (capability) {
      ToolCapability.readOnly || ToolCapability.mutatingFiles => PhaseClass.io,
      ToolCapability.shell || ToolCapability.network => PhaseClass.tool,
    };
  }
  return switch (toolName) {
    'Read' ||
    'Edit' ||
    'Write' ||
    'Glob' ||
    'Grep' ||
    'NotebookEdit' ||
    'read_file' ||
    'write_file' ||
    'list_dir' ||
    'glob' ||
    'grep' ||
    'str_replace' => PhaseClass.io,
    'Bash' || 'WebFetch' || 'WebSearch' || 'bash' || 'web_fetch' => PhaseClass.tool,
    _ => PhaseClass.tool,
  };
}
