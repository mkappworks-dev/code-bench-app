// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_repository_impl.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(sessionRepository)
final sessionRepositoryProvider = SessionRepositoryProvider._();

final class SessionRepositoryProvider
    extends $FunctionalProvider<AsyncValue<SessionRepository>, SessionRepository, FutureOr<SessionRepository>>
    with $FutureModifier<SessionRepository>, $FutureProvider<SessionRepository> {
  SessionRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sessionRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sessionRepositoryHash();

  @$internal
  @override
  $FutureProviderElement<SessionRepository> $createElement($ProviderPointer pointer) => $FutureProviderElement(pointer);

  @override
  FutureOr<SessionRepository> create(Ref ref) {
    return sessionRepository(ref);
  }
}

String _$sessionRepositoryHash() => r'7d335deb453cc749ceeba72d5b5d3ec28f48e3b6';
