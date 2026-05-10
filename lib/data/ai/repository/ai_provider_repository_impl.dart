import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/utils/debug_logger.dart';
import '../datasource/ai_provider_datasource.dart';
import '../datasource/claude_cli_datasource_process.dart';
import '../datasource/codex_cli_datasource_process.dart';
import 'ai_provider_repository.dart';

part 'ai_provider_repository_impl.g.dart';

@Riverpod(keepAlive: true)
AIProviderRepository aiProviderRepository(Ref ref) => AIProviderRepositoryImpl(
  datasources: {
    'claude-cli': ref.watch(claudeCliDatasourceProcessProvider),
    'codex': ref.watch(codexCliDatasourceProcessProvider),
  },
);

class AIProviderRepositoryImpl implements AIProviderRepository {
  AIProviderRepositoryImpl({required Map<String, AIProviderDatasource> datasources}) : _datasources = datasources;

  final Map<String, AIProviderDatasource> _datasources;

  @override
  void respondToPermissionRequest(String sessionId, String requestId, {required bool approved}) {
    for (final ds in _datasources.values) {
      ds.respondToPermissionRequest(sessionId, requestId, approved: approved);
    }
  }

  @override
  bool respondToUserInputRequest(String providerId, String sessionId, String requestId, {required String response}) {
    final ds = _datasources[providerId];
    if (ds == null) {
      sLog('[AIProviderRepository] respondToUserInputRequest: unknown providerId $providerId');
      return false;
    }
    return ds.respondToUserInputRequest(sessionId, requestId, response: response);
  }
}
