class AgentAskUserQuestionTool {
  AgentAskUserQuestionTool._();

  static const String name = 'AskUserQuestion';
  static const String description =
      'Ask the user a clarifying question. Use this when you need information '
      'from the user that you cannot infer from context. Returns the user\'s '
      'typed answer as the tool result.';

  static const Map<String, dynamic> inputSchema = {
    'type': 'object',
    'properties': {
      'question': {'type': 'string', 'description': 'The question to ask the user.'},
      'options': {
        'type': 'array',
        'items': {'type': 'string'},
        'description': 'Optional list of suggested answers.',
      },
    },
    'required': ['question'],
  };

  static Map<String, dynamic> get anthropicShape => {
    'name': name,
    'description': description,
    'input_schema': inputSchema,
  };

  static Map<String, dynamic> get openAiShape => {
    'type': 'function',
    'function': {'name': name, 'description': description, 'parameters': inputSchema},
  };

  static Map<String, dynamic> get geminiShape => {'name': name, 'description': description, 'parameters': inputSchema};

  static Map<String, dynamic> get ollamaShape => openAiShape;
}
