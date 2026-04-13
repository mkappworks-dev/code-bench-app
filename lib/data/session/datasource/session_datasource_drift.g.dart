// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_datasource_drift.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(sessionDatasource)
final sessionDatasourceProvider = SessionDatasourceProvider._();

final class SessionDatasourceProvider
    extends $FunctionalProvider<SessionDatasource, SessionDatasource, SessionDatasource>
    with $Provider<SessionDatasource> {
  SessionDatasourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sessionDatasourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sessionDatasourceHash();

  @$internal
  @override
  $ProviderElement<SessionDatasource> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  SessionDatasource create(Ref ref) {
    return sessionDatasource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SessionDatasource value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<SessionDatasource>(value));
  }
}

String _$sessionDatasourceHash() => r'deccf2c9b135f077d4ec46c6833f8fc8051cc542';
