// lib/data/update/datasource/update_install_datasource.dart

/// Performs the side-effectful steps of installing a downloaded update bundle:
/// extraction, signature inspection, and the bundle swap + relaunch.
///
/// All filesystem layout, Process invocation, and exit() lives here. Higher
/// layers (service, notifier) only orchestrate and apply policy.
abstract interface class UpdateInstallDatasource {
  /// Returns the path of the running app's `.app` bundle (resolved from the
  /// running executable). Synchronous because it's pure path arithmetic.
  String currentAppPath();

  /// Creates a unique randomised tempdir for extracting an update zip into.
  /// Returns the absolute path.
  Future<String> createExtractDir();

  /// Extracts [zipPath] into [destDir] using ditto (preserves macOS xattrs
  /// and codesign metadata). Throws [UpdateInstallException] on non-zero exit.
  Future<void> extractZip({required String zipPath, required String destDir});

  /// Validates the contents of [extractDir] and returns the path of the
  /// single extracted `.app`. Throws [UpdateInstallException] if any
  /// top-level entry is a symlink, or if there isn't exactly one `.app`.
  Future<String> resolveExtractedAppPath(String extractDir);

  /// Reads the `TeamIdentifier` of the codesign at [appPath]. Returns null
  /// for unsigned or ad-hoc-signed bundles.
  Future<String?> readTeamId(String appPath);

  /// Runs `codesign --verify --deep --strict <appPath>`. Throws
  /// [UpdateInstallException] if the bundle's signature is missing or invalid.
  Future<void> verifyCodesign(String appPath);

  /// Runs `spctl --assess --type execute <appPath>`. Throws
  /// [UpdateInstallException] if Gatekeeper would refuse to launch the bundle.
  Future<void> assessGatekeeper(String appPath);

  /// Writes the relaunch script and spawns it detached, then exits the
  /// running process with code 0. Never returns normally on success.
  ///
  /// The spawned script: backs up the current bundle, ditto-copies the new
  /// one in, optionally re-verifies codesign, writes a status sentinel to
  /// [statusSentinelPath], cleans up tempdirs/zip, and `open`s the new app.
  Future<Never> swapAndRelaunch({
    required String currentAppPath,
    required String newAppPath,
    required String extractDir,
    required String zipPath,
    required String statusSentinelPath,
    required bool enforceSignature,
  });

  /// Best-effort delete of [extractDir]. Used by callers when install aborts
  /// before reaching [swapAndRelaunch]. Never throws.
  void cleanupExtractDir(String extractDir);
}
