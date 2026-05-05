/// A single installation of the GitHub App on a user account or organisation.
class GitHubAppInstallation {
  const GitHubAppInstallation({required this.id, required this.accountLogin, required this.isOrg});

  final int id;
  final String accountLogin;
  final bool isOrg;

  /// GitHub page where the user can suspend or uninstall this installation.
  String get manageUrl => isOrg
      ? 'https://github.com/organizations/$accountLogin/settings/installations/$id'
      : 'https://github.com/settings/installations/$id';
}
