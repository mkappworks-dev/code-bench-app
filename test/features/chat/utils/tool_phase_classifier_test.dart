import 'package:code_bench_app/data/coding_tools/models/tool_capability.dart';
import 'package:code_bench_app/features/chat/utils/tool_phase_classifier.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('classifyTool', () {
    test('readOnly capability → io', () {
      expect(classifyTool('read_file', ToolCapability.readOnly), PhaseClass.io);
      expect(classifyTool('grep', ToolCapability.readOnly), PhaseClass.io);
    });
    test('mutatingFiles capability → io', () {
      expect(classifyTool('write_file', ToolCapability.mutatingFiles), PhaseClass.io);
      expect(classifyTool('str_replace', ToolCapability.mutatingFiles), PhaseClass.io);
    });
    test('shell capability → tool', () {
      expect(classifyTool('bash', ToolCapability.shell), PhaseClass.tool);
    });
    test('network capability → tool', () {
      expect(classifyTool('web_fetch', ToolCapability.network), PhaseClass.tool);
    });
    test('unknown name without capability → tool (opaque exec)', () {
      expect(classifyTool('mystery_tool', null), PhaseClass.tool);
    });
    test('CLI-transport built-in names map by name when capability is unknown', () {
      expect(classifyTool('Read', null), PhaseClass.io);
      expect(classifyTool('Edit', null), PhaseClass.io);
      expect(classifyTool('Bash', null), PhaseClass.tool);
      expect(classifyTool('WebFetch', null), PhaseClass.tool);
    });
  });
}
