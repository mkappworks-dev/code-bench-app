// test/services/update/update_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:code_bench_app/services/update/update_service.dart';

void main() {
  group('UpdateService.isNewer', () {
    test('true when minor is higher', () {
      expect(UpdateService.isNewer('1.2.0', '1.1.0'), isTrue);
    });
    test('true when major is higher', () {
      expect(UpdateService.isNewer('2.0.0', '1.9.9'), isTrue);
    });
    test('true when patch is higher', () {
      expect(UpdateService.isNewer('1.1.1', '1.1.0'), isTrue);
    });
    test('false when equal', () {
      expect(UpdateService.isNewer('1.1.0', '1.1.0'), isFalse);
    });
    test('false when current is higher', () {
      expect(UpdateService.isNewer('1.1.0', '1.2.0'), isFalse);
    });
    test('false when version string has fewer than 3 segments', () {
      expect(UpdateService.isNewer('1.1', '1.0.0'), isFalse);
    });
  });
}
