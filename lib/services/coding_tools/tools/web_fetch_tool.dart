import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/coding_tools/models/coding_tool_result.dart';
import '../../../data/coding_tools/models/tool.dart';
import '../../../data/coding_tools/models/tool_capability.dart';
import '../../../data/coding_tools/models/tool_context.dart';
import '../../../data/web_fetch/datasource/web_fetch_datasource.dart';
import '../../../data/web_fetch/datasource/web_fetch_datasource_dio.dart';

part 'web_fetch_tool.g.dart';

@riverpod
WebFetchTool webFetchTool(Ref ref) => WebFetchTool(datasource: WebFetchDatasourceDio());

class WebFetchTool extends Tool {
  WebFetchTool({required this.datasource});

  final WebFetchDatasource datasource;

  @override
  String get name => 'web_fetch';

  @override
  ToolCapability get capability => ToolCapability.network;

  @override
  String get description =>
      'Fetch and read content from a public web URL. HTML is converted to '
      'readable text. Only http and https are supported. Private network '
      'addresses are blocked. Use this to read docs, GitHub issues, or '
      'API references when given a URL.';

  @override
  Map<String, dynamic> get inputSchema => const {
    'type': 'object',
    'properties': {
      'url': {'type': 'string', 'description': 'The full URL to fetch (must start with http:// or https://).'},
    },
    'required': ['url'],
  };

  @override
  Future<CodingToolResult> execute(ToolContext ctx) async {
    final url = ctx.args['url'];
    if (url is! String || url.trim().isEmpty) {
      return const CodingToolResult.error('web_fetch requires a non-empty "url" argument.');
    }
    try {
      final content = await datasource.fetch(url: url.trim());
      return CodingToolResult.success(content);
    } on ArgumentError catch (e) {
      return CodingToolResult.error(e.message.toString());
    } catch (e) {
      return CodingToolResult.error('Failed to fetch "$url": $e');
    }
  }
}
