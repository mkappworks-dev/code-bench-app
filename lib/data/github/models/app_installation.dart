class GitHubAppInstallation {
  const GitHubAppInstallation({required this.id, required this.accountLogin, required this.isOrg});

  final int id;
  final String accountLogin;
  final bool isOrg;

  String get manageUrl => isOrg
      ? 'https://github.com/organizations/$accountLogin/settings/installations/$id'
      : 'https://github.com/settings/installations/$id';
}
