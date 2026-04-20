import 'package:flutter_test/flutter_test.dart';
import 'package:code_bench_app/data/coding_tools/models/coding_tool_definition.dart';

void main() {
  group('CodingTools.catalog', () {
    test('exposes the four MVP tools with the expected names', () {
      final names = CodingTools.all.map((t) => t.name).toList();
      expect(names, ['read_file', 'list_dir', 'write_file', 'str_replace']);
    });

    test('read-only subset excludes write_file and str_replace', () {
      final names = CodingTools.readOnly.map((t) => t.name).toList();
      expect(names, ['read_file', 'list_dir']);
    });

    test('toOpenAiToolJson wraps schema in {type: function, function: {...}}', () {
      final json = CodingTools.readFile.toOpenAiToolJson();
      expect(json['type'], 'function');
      expect(json['function']['name'], 'read_file');
      expect((json['function']['parameters'] as Map)['required'], ['path']);
    });
  });
}
