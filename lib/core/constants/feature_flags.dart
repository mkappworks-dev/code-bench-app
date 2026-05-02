/// Compile-time feature flags used to gate UI entry points without deleting
/// the underlying code. Toggling a flag here flips the corresponding code
/// path on or off across the whole app; release builds tree-shake the
/// disabled branch.
class FeatureFlags {
  FeatureFlags._();

  /// Shows the "Continue with GitHub" OAuth button on the onboarding GitHub
  /// step and the Settings → Integrations screen. When `false`, users only
  /// see the personal access token (PAT) flow. The OAuth notifier and
  /// datasource remain wired up — only the UI entry points are hidden.
  static const bool githubOAuthEnabled = false;
}
