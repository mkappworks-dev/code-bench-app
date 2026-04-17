// lib/features/providers/notifiers/providers_actions_failure.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'providers_actions_failure.freezed.dart';

@freezed
sealed class ProvidersActionsFailure with _$ProvidersActionsFailure {
  const factory ProvidersActionsFailure.storageFailed(String providerName) =
      ProvidersStorageFailed;
  const factory ProvidersActionsFailure.unknown(Object error) =
      ProvidersUnknownError;
}
