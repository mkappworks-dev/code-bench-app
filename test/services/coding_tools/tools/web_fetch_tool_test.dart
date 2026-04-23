import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:code_bench_app/core/errors/app_exception.dart';
import 'package:code_bench_app/data/coding_tools/models/coding_tool_result.dart';
import 'package:code_bench_app/data/coding_tools/models/tool_capability.dart';
import 'package:code_bench_app/data/coding_tools/models/tool_context.dart';
import 'package:code_bench_app/data/web_fetch/datasource/web_fetch_datasource.dart';
import 'package:code_bench_app/services/coding_tools/tools/web_fetch_tool.dart';

import 'web_fetch_tool_test.mocks.dart';

// Note: The generated MockWebFetchDatasource has `fetch({required String? url})`
// even though the interface declares `{required String url}`. This is a known
// Mockito quirk where mock parameters become nullable. The test still works
// because we pass non-null values and Mockito coerces the types at runtime.
@GenerateMocks([WebFetchDatasource])
void main() {
  late MockWebFetchDatasource mockDatasource;
  late WebFetchTool tool;

  setUp(() {
    mockDatasource = MockWebFetchDatasource();
    tool = WebFetchTool(datasource: mockDatasource);
  });

  ToolContext ctx(Map<String, dynamic> args) => ToolContext(
    projectPath: '/project',
    sessionId: 'sess',
    messageId: 'msg',
    args: args,
    denylist: (segments: {}, filenames: {}, extensions: {}, prefixes: {}),
  );

  test('name is web_fetch', () {
    expect(tool.name, 'web_fetch');
  });

  test('capability is network', () {
    expect(tool.capability, ToolCapability.network);
  });

  test('returns error when url arg is absent', () async {
    final result = await tool.execute(ctx({}));
    expect(result, isA<CodingToolResultError>());
  });

  test('returns error when url arg is empty string', () async {
    final result = await tool.execute(ctx({'url': ''}));
    expect(result, isA<CodingToolResultError>());
  });

  test('returns error when url arg is not a string', () async {
    final result = await tool.execute(ctx({'url': 42}));
    expect(result, isA<CodingToolResultError>());
  });

  test('delegates to datasource with the url and returns content', () async {
    when(mockDatasource.fetch(url: 'https://example.com')).thenAnswer((_) async => 'Page content');

    final result = await tool.execute(ctx({'url': 'https://example.com'}));

    verify(mockDatasource.fetch(url: 'https://example.com')).called(1);
    expect(result, isA<CodingToolResultSuccess>());
    expect((result as CodingToolResultSuccess).output, 'Page content');
  });

  test('trims whitespace from url before delegating', () async {
    when(mockDatasource.fetch(url: 'https://example.com')).thenAnswer((_) async => 'ok');

    await tool.execute(ctx({'url': '  https://example.com  '}));

    verify(mockDatasource.fetch(url: 'https://example.com')).called(1);
  });

  test('returns error message from ArgumentError', () async {
    when(mockDatasource.fetch(url: anyNamed('url'))).thenThrow(ArgumentError('private address not allowed'));

    final result = await tool.execute(ctx({'url': 'http://192.168.1.1'}));

    expect(result, isA<CodingToolResultError>());
    expect((result as CodingToolResultError).message, contains('not allowed'));
  });

  test('returns generic error for unexpected exceptions', () async {
    when(mockDatasource.fetch(url: anyNamed('url'))).thenThrow(Exception('connection refused'));

    final result = await tool.execute(ctx({'url': 'https://unreachable.test'}));

    expect(result, isA<CodingToolResultError>());
  });

  test('includes HTTP status code when NetworkException carries one', () async {
    when(mockDatasource.fetch(url: anyNamed('url'))).thenThrow(const NetworkException('Not found', statusCode: 404));

    final result = await tool.execute(ctx({'url': 'https://example.com/missing'}));

    expect(result, isA<CodingToolResultError>());
    final message = (result as CodingToolResultError).message;
    expect(message, contains('HTTP 404'));
    expect(message, contains('Not found'));
  });

  test('NetworkException without status code is still surfaced cleanly', () async {
    when(mockDatasource.fetch(url: anyNamed('url'))).thenThrow(const NetworkException('DNS lookup failed'));

    final result = await tool.execute(ctx({'url': 'https://unresolvable.test'}));

    expect(result, isA<CodingToolResultError>());
    final message = (result as CodingToolResultError).message;
    expect(message, contains('DNS lookup failed'));
    expect(message, isNot(contains('HTTP')));
  });
}
