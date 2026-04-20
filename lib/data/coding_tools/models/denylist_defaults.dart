import 'denylist_category.dart';

/// Baseline denylist shipped with the app. UI surfaces these with a
/// "default" visual style; users can suppress individual entries
/// but the set itself is immutable and the single source of truth
/// for both runtime evaluation and the Settings UI.
class DenylistDefaults {
  DenylistDefaults._();

  static const Set<String> segments = {'.git', '.ssh', '.aws', '.gnupg', '.config'};

  static const Set<String> filenames = {
    '.env',
    '.netrc',
    '.npmrc',
    '.pypirc',
    '.htpasswd',
    'credentials',
    'secrets',
    'id_rsa',
    'id_dsa',
    'id_ecdsa',
    'id_ed25519',
  };

  static const Set<String> extensions = {'.pem', '.key', '.p12', '.pfx', '.jks'};

  static const Set<String> prefixes = {'.env.'};

  static const Map<DenylistCategory, Set<String>> _all = {
    DenylistCategory.segment: segments,
    DenylistCategory.filename: filenames,
    DenylistCategory.extension: extensions,
    DenylistCategory.prefix: prefixes,
  };

  static Set<String> forCategory(DenylistCategory category) => _all[category]!;
}
