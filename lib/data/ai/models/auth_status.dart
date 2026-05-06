import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_status.freezed.dart';

@freezed
sealed class AuthStatus with _$AuthStatus {
  const factory AuthStatus.authenticated() = AuthAuthenticated;
  const factory AuthStatus.unauthenticated({required String signInCommand, String? hint}) = AuthUnauthenticated;
  const factory AuthStatus.unknown() = AuthUnknown;
}
