import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/ai/repository/ai_provider_repository.dart';
import '../../data/ai/repository/ai_provider_repository_impl.dart';
import 'ai_provider_service.dart';

part 'ai_provider_repository_provider.g.dart';

@Riverpod(keepAlive: true)
AIProviderRepository aiProviderRepository(Ref ref) =>
    AIProviderRepositoryImpl(datasources: ref.watch(aIProviderServiceProvider));
