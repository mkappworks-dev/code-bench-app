import '../models/device_code_response.dart';
import '../models/repository.dart';

abstract interface class GitHubAuthDatasource {
  /// Initiates the GitHub Device Flow. Returns the device code metadata
  /// the caller must display to the user.
  Future<DeviceCodeResponse> requestDeviceCode();

  /// Polls GitHub's token endpoint until the user authorizes the device
  /// (returns [GitHubAccount]) or the flow fails (throws [AuthException]).
  /// Returns `null` if the [cancelSignal] completes before authorization.
  ///
  /// `intervalSeconds` is the initial poll interval; `slow_down` responses
  /// from GitHub increase it. `expiresIn` bounds the total polling window —
  /// the loop throws [AuthException] locally once the device code lifetime
  /// is exhausted, regardless of whether GitHub has returned `expired_token`.
  Future<GitHubAccount?> pollForUserToken(
    String deviceCode,
    int intervalSeconds,
    int expiresIn, {
    Future<void>? cancelSignal,
  });

  Future<GitHubAccount?> getStoredAccount();

  Future<bool> isAuthenticated();

  /// Verifies the stored token against GitHub.
  ///
  /// - Returns `true` on a 2xx response (token still works).
  /// - Returns `false` on a 401 (token rejected — user/owner revoked the
  ///   app, or the token expired).
  /// - Rethrows on transient failures (network down, 5xx, malformed body)
  ///   so callers can leave UI state alone instead of falsely signing out
  ///   a user whose token is fine but whose connection isn't.
  /// - Throws [StateError] when no token is stored (call [getStoredAccount]
  ///   or [isAuthenticated] first).
  Future<bool> validateStoredToken();

  Future<void> signOut();
}
