import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/ai/models/provider_capabilities.dart';
import '../../data/ai/repository/ai_repository_impl.dart';
import '../../data/shared/ai_model.dart';
import '../ai_provider/ai_provider_service.dart';

part 'provider_capabilities_service.g.dart';

@Riverpod(keepAlive: true)
ProviderCapabilitiesService providerCapabilitiesService(Ref ref) => ProviderCapabilitiesService(ref);

class ProviderCapabilitiesService {
  ProviderCapabilitiesService(this._ref);

  final Ref _ref;

  ProviderCapabilities? capabilitiesFor({required AIModel model, String? cliProviderId}) {
    if (cliProviderId != null) {
      final cliDs = _ref.read(aIProviderServiceProvider.notifier).getProvider(cliProviderId);
      return cliDs?.capabilitiesFor(model);
    }
    return _ref.read(aiRepositoryProvider).value?.capabilitiesFor(model);
  }
}
