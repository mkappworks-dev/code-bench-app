import 'package:freezed_annotation/freezed_annotation.dart';

part 'providers_failure.freezed.dart';

@freezed
sealed class ProvidersFailure with _$ProvidersFailure {
  const factory ProvidersFailure.storageFailed(String providerName) = ProvidersStorageFailed;
  const factory ProvidersFailure.unknown(Object error) = ProvidersUnknownError;
}
