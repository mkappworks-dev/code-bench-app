import '../models/update_install_status.dart';

/// Reads and clears the install-status sentinel that the relaunch script
/// writes to a stable path on every install attempt. Used at startup so the
/// notifier can surface install failures the parent process couldn't see.
abstract interface class UpdateInstallStatusDatasource {
  /// Absolute path the sentinel will be written to / read from.
  Future<String> sentinelPath();

  /// Reads and parses the sentinel; returns null if no sentinel exists or
  /// the file is unreadable.
  Future<UpdateInstallStatus?> readStatus();

  /// Removes the sentinel after the notifier has surfaced its content.
  Future<void> clearStatus();
}
