import 'package:flutter_test/flutter_test.dart';
import 'package:code_bench_app/data/web_fetch/datasource/web_fetch_datasource_dio.dart';

void main() {
  group('WebFetchDatasourceDio.isPrivateHost', () {
    test('blocks localhost', () {
      expect(WebFetchDatasourceDio.isPrivateHost('localhost'), isTrue);
    });

    test('blocks 127.0.0.1', () {
      expect(WebFetchDatasourceDio.isPrivateHost('127.0.0.1'), isTrue);
    });

    test('blocks 10.x address', () {
      expect(WebFetchDatasourceDio.isPrivateHost('10.0.0.1'), isTrue);
    });

    test('blocks 192.168.x address', () {
      expect(WebFetchDatasourceDio.isPrivateHost('192.168.1.100'), isTrue);
    });

    test('blocks 172.16.x address', () {
      expect(WebFetchDatasourceDio.isPrivateHost('172.16.0.1'), isTrue);
    });

    test('blocks 172.31.x address', () {
      expect(WebFetchDatasourceDio.isPrivateHost('172.31.255.255'), isTrue);
    });

    test('allows 172.32.x address (outside private range)', () {
      expect(WebFetchDatasourceDio.isPrivateHost('172.32.0.1'), isFalse);
    });

    test('allows public IP', () {
      expect(WebFetchDatasourceDio.isPrivateHost('8.8.8.8'), isFalse);
    });

    test('allows public hostname', () {
      expect(WebFetchDatasourceDio.isPrivateHost('example.com'), isFalse);
    });

    test('blocks IPv6 loopback [::1]', () {
      expect(WebFetchDatasourceDio.isPrivateHost('[::1]'), isTrue);
    });

    test('blocks bare ::1', () {
      expect(WebFetchDatasourceDio.isPrivateHost('::1'), isTrue);
    });
  });

  group('WebFetchDatasourceDio.htmlToText', () {
    test('strips HTML tags', () {
      const input = '<html><body><h1>Title</h1><p>Hello world.</p></body></html>';
      final result = WebFetchDatasourceDio.htmlToText(input);
      expect(result, contains('Title'));
      expect(result, contains('Hello world'));
      expect(result, isNot(contains('<h1>')));
    });

    test('strips script content', () {
      const input =
          '<html><head><script>alert("xss")</script></head>'
          '<body><p>Safe</p></body></html>';
      final result = WebFetchDatasourceDio.htmlToText(input);
      expect(result, isNot(contains('alert')));
      expect(result, contains('Safe'));
    });

    test('strips style content', () {
      const input =
          '<html><head><style>body{color:red}</style></head>'
          '<body><p>Text</p></body></html>';
      final result = WebFetchDatasourceDio.htmlToText(input);
      expect(result, isNot(contains('color')));
      expect(result, contains('Text'));
    });

    test('adds # prefix for h1', () {
      const input = '<html><body><h1>Heading</h1></body></html>';
      final result = WebFetchDatasourceDio.htmlToText(input);
      expect(result, contains('# Heading'));
    });

    test('adds ## prefix for h2', () {
      const input = '<html><body><h2>Sub</h2></body></html>';
      final result = WebFetchDatasourceDio.htmlToText(input);
      expect(result, contains('## Sub'));
    });

    test('adds ### prefix for h3', () {
      const input = '<html><body><h3>Section</h3></body></html>';
      final result = WebFetchDatasourceDio.htmlToText(input);
      expect(result, contains('### Section'));
    });

    test('preserves links in markdown format', () {
      const input = '<html><body><a href="https://example.com">Example</a></body></html>';
      final result = WebFetchDatasourceDio.htmlToText(input);
      expect(result, contains('[Example](https://example.com)'));
    });

    test('wraps pre blocks in triple backticks', () {
      const input = '<html><body><pre>print("hi")</pre></body></html>';
      final result = WebFetchDatasourceDio.htmlToText(input);
      expect(result, contains('```'));
      expect(result, contains('print("hi")'));
    });

    test('caps output at 100k chars and adds truncation notice', () {
      final bigHtml = '<html><body>${List.filled(200, '<p>${'x' * 1000}</p>').join()}</body></html>';
      final result = WebFetchDatasourceDio.htmlToText(bigHtml);
      expect(result, contains('[Content truncated at 100k characters]'));
    });
  });
}
