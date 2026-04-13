import '../../models/repository.dart';

abstract interface class GitHubAuthDatasource {
  Future<GitHubAccount> authenticate();

  Future<GitHubAccount> signInWithPat(String token);

  Future<GitHubAccount?> getStoredAccount();

  Future<bool> isAuthenticated();

  Future<void> signOut();
}
