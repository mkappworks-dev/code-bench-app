// test/services/coding_tools/_helpers/tool_test_helpers.dart

import 'package:code_bench_app/data/coding_tools/models/effective_denylist.dart';
import 'package:code_bench_app/data/coding_tools/models/tool_context.dart';

/// Empty denylist snapshot for tests that don't exercise the denylist.
EffectiveDenylist emptyDenylist() =>
    (segments: const <String>{}, filenames: const <String>{}, extensions: const <String>{}, prefixes: const <String>{});

/// Builds a [ToolContext] with sane test defaults. Override any field as
/// needed. The default [denylist] is [emptyDenylist].
ToolContext fakeCtx({
  required String projectPath,
  String sessionId = 's',
  String messageId = 'm',
  Map<String, dynamic> args = const {},
  EffectiveDenylist? denylist,
}) => ToolContext(
  projectPath: projectPath,
  sessionId: sessionId,
  messageId: messageId,
  args: args,
  denylist: denylist ?? emptyDenylist(),
);
