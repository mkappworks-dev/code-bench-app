/// A single tool that the model may call. Pure data — no runtime behavior.
/// The matching handler lives on [CodingToolsService].
class CodingToolDefinition {
  const CodingToolDefinition({required this.name, required this.description, required this.inputSchema});

  final String name;
  final String description;
  final Map<String, dynamic> inputSchema;

  /// Serializes to the OpenAI chat-completions `tools[]` shape:
  /// `{"type": "function", "function": {name, description, parameters}}`.
  Map<String, dynamic> toOpenAiToolJson() => {
    'type': 'function',
    'function': {'name': name, 'description': description, 'parameters': inputSchema},
  };
}

/// Catalog of tools shipped in the MVP. Order matters — it's preserved in
/// the request body and in UI lists.
class CodingTools {
  static const readFile = CodingToolDefinition(
    name: 'read_file',
    description: 'Read the contents of a text file inside the active project.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'path': {'type': 'string', 'description': 'Project-relative or absolute path to a file inside the project.'},
      },
      'required': ['path'],
    },
  );

  static const listDir = CodingToolDefinition(
    name: 'list_dir',
    description: 'List entries in a directory inside the active project.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'path': {'type': 'string'},
        'recursive': {'type': 'boolean', 'default': false},
      },
      'required': ['path'],
    },
  );

  static const writeFile = CodingToolDefinition(
    name: 'write_file',
    description:
        'Create or overwrite a file inside the active project. Prefer str_replace for targeted edits to existing files.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'path': {'type': 'string'},
        'content': {'type': 'string'},
      },
      'required': ['path', 'content'],
    },
  );

  static const strReplace = CodingToolDefinition(
    name: 'str_replace',
    description:
        'Replace the first exact occurrence of old_str with new_str in a file. The match must be unique — if zero or multiple matches exist, this tool returns an error and the file is unchanged.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'path': {'type': 'string'},
        'old_str': {'type': 'string'},
        'new_str': {'type': 'string'},
      },
      'required': ['path', 'old_str', 'new_str'],
    },
  );

  static const all = <CodingToolDefinition>[readFile, listDir, writeFile, strReplace];
  static const readOnly = <CodingToolDefinition>[readFile, listDir];
}
