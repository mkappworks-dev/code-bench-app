abstract interface class IdeLaunchRepository {
  Future<String?> openVsCode(String path);
  Future<String?> openCursor(String path);
  Future<String?> openInFinder(String path);
  // Reads the terminal app preference internally.
  Future<String?> openInTerminal(String path);
}
