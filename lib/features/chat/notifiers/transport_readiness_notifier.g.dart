// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transport_readiness_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Derived chat-input readiness for the active model + transport.
///
/// CLI transport: composes installed-binary status with auth status. Auth
/// `unknown` maps to [TransportReadiness.ready] (honest bias — never block on
/// probe failure; the pre-send fresh probe in [ChatMessagesNotifier] catches
/// real signed-out cases).
///
/// HTTP transport: readiness is fully determined by whether the matching API
/// key/URL is configured.

@ProviderFor(transportReadiness)
final transportReadinessProvider = TransportReadinessProvider._();

/// Derived chat-input readiness for the active model + transport.
///
/// CLI transport: composes installed-binary status with auth status. Auth
/// `unknown` maps to [TransportReadiness.ready] (honest bias — never block on
/// probe failure; the pre-send fresh probe in [ChatMessagesNotifier] catches
/// real signed-out cases).
///
/// HTTP transport: readiness is fully determined by whether the matching API
/// key/URL is configured.

final class TransportReadinessProvider
    extends $FunctionalProvider<TransportReadiness, TransportReadiness, TransportReadiness>
    with $Provider<TransportReadiness> {
  /// Derived chat-input readiness for the active model + transport.
  ///
  /// CLI transport: composes installed-binary status with auth status. Auth
  /// `unknown` maps to [TransportReadiness.ready] (honest bias — never block on
  /// probe failure; the pre-send fresh probe in [ChatMessagesNotifier] catches
  /// real signed-out cases).
  ///
  /// HTTP transport: readiness is fully determined by whether the matching API
  /// key/URL is configured.
  TransportReadinessProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'transportReadinessProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$transportReadinessHash();

  @$internal
  @override
  $ProviderElement<TransportReadiness> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  TransportReadiness create(Ref ref) {
    return transportReadiness(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TransportReadiness value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<TransportReadiness>(value));
  }
}

String _$transportReadinessHash() => r'518452ad63ea27e57ff878c4205d03bbb9a6f23b';
