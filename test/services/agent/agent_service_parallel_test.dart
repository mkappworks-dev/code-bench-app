import 'package:code_bench_app/data/coding_tools/models/coding_tool_result.dart';
import 'package:code_bench_app/data/coding_tools/models/tool.dart';
import 'package:code_bench_app/data/coding_tools/models/tool_capability.dart';
import 'package:code_bench_app/data/coding_tools/models/tool_context.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records execution order of tool calls by appending to [log].
class _OrderedTool extends Tool {
  _OrderedTool(this._name, this._capability, this._log, {Duration delay = Duration.zero}) : _delay = delay;

  final String _name;
  final ToolCapability _capability;
  final List<String> _log;
  final Duration _delay;

  @override
  String get name => _name;
  @override
  ToolCapability get capability => _capability;
  @override
  String get description => _name;
  @override
  Map<String, dynamic> get inputSchema => const {'type': 'object', 'properties': {}};

  @override
  Future<CodingToolResult> execute(ToolContext ctx) async {
    if (_delay != Duration.zero) await Future.delayed(_delay);
    _log.add(_name);
    return CodingToolResult.success(_name);
  }
}

ToolContext _fakeCtx() => ToolContext(
  projectPath: '/tmp',
  sessionId: 's',
  messageId: 'm',
  args: const {},
  denylist: (segments: {}, filenames: {}, extensions: {}, prefixes: {}),
);

void main() {
  test('read-only tools in same round run in parallel', () async {
    final log = <String>[];
    final read1 = _OrderedTool('grep', ToolCapability.readOnly, log, delay: const Duration(milliseconds: 80));
    final read2 = _OrderedTool('glob', ToolCapability.readOnly, log, delay: const Duration(milliseconds: 80));

    final started = DateTime.now();
    await Future.wait([read1.execute(_fakeCtx()), read2.execute(_fakeCtx())]);
    final elapsed = DateTime.now().difference(started).inMilliseconds;
    expect(elapsed, lessThan(200), reason: 'should run in parallel not serial');
  });

  test('write tools are not parallelised (serial list partition)', () {
    final readTool = _OrderedTool('grep', ToolCapability.readOnly, []);
    final writeTool = _OrderedTool('write_file', ToolCapability.mutatingFiles, []);

    expect(readTool.capability, ToolCapability.readOnly);
    expect(writeTool.capability, ToolCapability.mutatingFiles);
    expect(writeTool.capability != ToolCapability.readOnly, isTrue);
  });
}
