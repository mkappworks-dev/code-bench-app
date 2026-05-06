import 'package:freezed_annotation/freezed_annotation.dart';

part 'transport_readiness.freezed.dart';

@freezed
sealed class TransportReadiness with _$TransportReadiness {
  const factory TransportReadiness.ready() = TransportReady;
  const factory TransportReadiness.notInstalled({required String provider}) = TransportNotInstalled;
  const factory TransportReadiness.signedOut({required String provider, required String signInCommand}) =
      TransportSignedOut;
  const factory TransportReadiness.httpKeyMissing({required String provider}) = TransportHttpKeyMissing;
  const factory TransportReadiness.unknown() = TransportUnknown;
}
