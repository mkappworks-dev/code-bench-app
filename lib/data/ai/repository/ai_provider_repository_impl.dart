import '../datasource/ai_provider_datasource.dart';
import 'ai_provider_repository.dart';

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
  void respondToUserInputRequest(String sessionId, String requestId, {required String response}) {
    for (final ds in _datasources.values) {
      ds.respondToUserInputRequest(sessionId, requestId, response: response);
    }
  }
}
