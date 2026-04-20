import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../data/shared/ai_model.dart';

part 'available_models_failure.freezed.dart';

/// Top-level failure emitted as `AsyncError` on `availableModelsProvider`.
/// Per-provider fetch failures do NOT surface here — they are kept inside
/// `AvailableModelsResult.failures` so a partial fetch still produces
/// `AsyncData`.
@freezed
sealed class AvailableModelsFailure with _$AvailableModelsFailure {
  /// Thrown when secure storage / providers-service reads fail before any
  /// endpoint fetch can run. Fires on both cold-boot and refresh paths;
  /// Riverpod's built-in `copyWithPrevious` preserves the last-known models
  /// on the refresh path.
  const factory AvailableModelsFailure.storageError(Object error) = AvailableModelsStorageError;
}

/// Per-provider classification stored in `AvailableModelsResult.failures`.
/// Rendered inline in the model picker (not as a snackbar) because it's a
/// partial-success shape — the rest of the list is still usable.
@freezed
sealed class ModelProviderFailure with _$ModelProviderFailure {
  /// Network-level failure (DNS, timeout, 5xx, connection refused).
  const factory ModelProviderFailure.unreachable(AIProvider provider) = ModelProviderUnreachable;

  /// Endpoint rejected the credential (401/403).
  const factory ModelProviderFailure.auth(AIProvider provider) = ModelProviderAuth;

  /// Endpoint responded but the payload did not match the expected shape.
  const factory ModelProviderFailure.malformedResponse(AIProvider provider, String detail) =
      ModelProviderMalformedResponse;

  /// Catch-all for anything that isn't one of the above (also used when the
  /// repository-layer error type isn't one we classify).
  const factory ModelProviderFailure.unknown(AIProvider provider, Object error) = ModelProviderUnknown;
}
