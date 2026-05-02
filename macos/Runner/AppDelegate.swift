import Cocoa
import Darwin
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationWillFinishLaunching(_ notification: Notification) {
    // Ignore SIGPIPE for the whole process. Without this, writing to a closed
    // pipe (orphaned Dart VM Service, plugin XPC channels, sockets) terminates
    // the process with exit code 141 — silent, no crash log, no Dart
    // exception. Flutter's `flutter run` tool sets the same disposition on
    // its launcher; this matches that behavior for direct-launched binaries
    // (the dmg-installed app and any `open` invocation).
    signal(SIGPIPE, SIG_IGN)
    super.applicationWillFinishLaunching(notification)
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}
