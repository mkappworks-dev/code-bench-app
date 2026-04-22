// test/data/mcp/datasource/mcp_stdio_datasource_process_test.dart
//
// Tests for McpStdioDatasourceProcess — focuses on the stderr drain that
// prevents child-process pipe-full deadlocks.

import 'dart:io';

import 'package:code_bench_app/data/mcp/datasource/mcp_stdio_datasource_process.dart';
import 'package:code_bench_app/data/mcp/models/mcp_server_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('McpStdioDatasourceProcess', () {
    test(
      'connect does not deadlock when subprocess writes a large amount to stderr',
      () async {
        // A process that:
        //   1. Writes ~160 KB to stderr (well beyond the ~64 KB pipe buffer).
        //   2. Exits cleanly.
        // Without stderr draining the child blocks on the stderr write and
        // connect() would hang until the timeout expires.
        final ds = McpStdioDatasourceProcess();
        const config = McpServerConfig(
          id: 'test-stderr',
          name: 'stderr-test',
          transport: McpTransport.stdio,
          command: 'python3',
          args: [
            '-c',
            // Write 200_000 bytes (~200 KB) to stderr then exit.
            "import sys; sys.stderr.write('x' * 200000); sys.stderr.flush()",
          ],
        );

        // If stderr is not drained this will hang and the timeout will fire,
        // causing the test to fail with a TimeoutException.
        await expectLater(ds.connect(config).timeout(const Duration(seconds: 10)), completes);

        await ds.close();
      },
      skip: Platform.isMacOS || Platform.isLinux ? null : 'Unix only (python3)',
    );
  });
}
