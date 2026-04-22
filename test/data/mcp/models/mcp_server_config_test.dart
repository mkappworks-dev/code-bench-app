import 'package:code_bench_app/data/mcp/models/mcp_server_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('McpServerConfig', () {
    test('serializes and deserializes round-trip', () {
      const config = McpServerConfig(
        id: 'abc',
        name: 'my-server',
        transport: McpTransport.stdio,
        command: 'npx -y @my/server',
        args: ['--verbose'],
        env: {'API_KEY': 'secret'},
        enabled: true,
      );
      final json = config.toJson();
      final restored = McpServerConfig.fromJson(json);
      expect(restored.id, 'abc');
      expect(restored.transport, McpTransport.stdio);
      expect(restored.args, ['--verbose']);
      expect(restored.env, {'API_KEY': 'secret'});
    });

    test('defaults enabled to true and collections to empty', () {
      const config = McpServerConfig(id: 'x', name: 'n', transport: McpTransport.httpSse, url: 'http://localhost:3000');
      expect(config.enabled, true);
      expect(config.args, <String>[]);
      expect(config.env, <String, String>{});
    });
  });
}
