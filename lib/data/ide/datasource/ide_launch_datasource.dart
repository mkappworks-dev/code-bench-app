abstract interface class IdeLaunchDatasource {
  Future<String?> openVsCode(String path);
  Future<String?> openCursor(String path);
  Future<String?> openInFinder(String path);
  Future<String?> openInTerminal(String path, String terminalApp);
}
