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
  /// from GitHub increase it.
  Future<GitHubAccount?> pollForUserToken(String deviceCode, int intervalSeconds, {Future<void>? cancelSignal});

  Future<GitHubAccount> signInWithPat(String token);

  Future<GitHubAccount?> getStoredAccount();

  Future<bool> isAuthenticated();

  Future<void> signOut();
}
