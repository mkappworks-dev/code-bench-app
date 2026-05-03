import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:code_bench_app/data/_core/secure_storage.dart';
import 'package:code_bench_app/data/github/datasource/github_auth_datasource_web_dio.dart';

class _FakeSecureStorage extends Fake implements SecureStorage {}

void main() {
  late GitHubAuthDatasourceWeb datasource;

  setUp(() {
    datasource = GitHubAuthDatasourceWeb(_FakeSecureStorage());
  });

  group('generatePkce', () {
    test('verifier meets RFC 7636 minimum length of 43 chars', () {
      final pkce = datasource.generatePkce();
      expect(pkce.verifier.length, greaterThanOrEqualTo(43));
    });

    test('verifier contains only base64url characters with no padding', () {
      final pkce = datasource.generatePkce();
      expect(pkce.verifier, matches(RegExp(r'^[A-Za-z0-9\-_]+$')));
    });

    test('challenge contains only base64url characters with no padding', () {
      final pkce = datasource.generatePkce();
      expect(pkce.challenge, matches(RegExp(r'^[A-Za-z0-9\-_]+$')));
    });

    test('challenge is S256 of verifier (RFC 7636 §4.6)', () {
      final pkce = datasource.generatePkce();
      final expected = base64UrlEncode(sha256.convert(utf8.encode(pkce.verifier)).bytes).replaceAll('=', '');
      expect(pkce.challenge, equals(expected));
    });

    test('verifier and challenge are distinct', () {
      final pkce = datasource.generatePkce();
      expect(pkce.verifier, isNot(equals(pkce.challenge)));
    });

    test('successive calls produce different verifiers', () {
      final pkce1 = datasource.generatePkce();
      final pkce2 = datasource.generatePkce();
      expect(pkce1.verifier, isNot(equals(pkce2.verifier)));
    });
  });
}
