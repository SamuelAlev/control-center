import 'package:cc_markdown/src/parser/autolink_extension.dart';
import 'package:flutter_test/flutter_test.dart';

/// Unit tests for the GFM bare-autolink extension: scheme/www. recognition,
/// trailing-punctuation trimming, paren balancing, and `&entity;` tail
/// stripping. This is pure string logic, exercised directly.
void main() {
  group('tryParseBareAutolink', () {
    test('https:// and http:// scheme links are recognized', () {
      final r = tryParseBareAutolink('see https://example.com/x', 4, 0x20);
      expect(r, isNotNull);
      expect(r!.text, 'https://example.com/x');
      expect(r.url, 'https://example.com/x');

      final r2 = tryParseBareAutolink('see http://example.com', 4, 0x20);
      expect(r2!.text, 'http://example.com');
    });

    test('a www. link is recognized and prefixed with http://', () {
      final r = tryParseBareAutolink('see www.example.com', 4, 0x20);
      expect(r, isNotNull);
      expect(r!.text, 'www.example.com');
      expect(r.url, 'http://www.example.com');
    });

    test('a www. link without a dot in the body is not a link', () {
      // www.foo has no dot → not a valid domain.
      final r = tryParseBareAutolink('see www.foo', 4, 0x20);
      expect(r, isNull);
    });

    test('returns null when there is no scheme and not www.', () {
      final r = tryParseBareAutolink('see ftp://example.com', 4, 0x20);
      expect(r, isNull);
    });

    test('returns null when nothing follows the scheme (empty body)', () {
      final r = tryParseBareAutolink('https://<', 0, -1);
      expect(r, isNull);
    });

    test('only recognizes bare links after whitespace or * _ ~ (', () {
      // After 'x' (a letter) → not recognized.
      expect(tryParseBareAutolink('xhttps://e.com', 1, 0x78 /*x*/), isNull);
      // After '*' (0x2A), '_' (0x5F), '~' (0x7E), '(' (0x28) → recognized.
      expect(tryParseBareAutolink('*https://e.com', 1, 0x2A), isNotNull);
      expect(tryParseBareAutolink('_https://e.com', 1, 0x5F), isNotNull);
      expect(tryParseBareAutolink('~https://e.com', 1, 0x7E), isNotNull);
      expect(tryParseBareAutolink('(https://e.com', 1, 0x28), isNotNull);
      // At start of text (before == -1) → recognized.
      expect(tryParseBareAutolink('https://e.com', 0, -1), isNotNull);
    });

    test('trims trailing punctuation', () {
      final r = tryParseBareAutolink('see https://e.com!?,.:', 4, 0x20);
      expect(r!.text, 'https://e.com');
    });

    test('trims trailing * _ ~ quotes', () {
      final r = tryParseBareAutolink('see https://e.com*"\'~_', 4, 0x20);
      expect(r!.text, 'https://e.com');
    });

    test('balances unbalanced trailing close paren', () {
      // One unbalanced close paren is trimmed.
      final r = tryParseBareAutolink('see https://e.com/path)', 4, 0x20);
      expect(r!.text, 'https://e.com/path');
    });

    test('keeps balanced parens in the URL', () {
      final r = tryParseBareAutolink('see https://e.com/a(b)c)', 4, 0x20);
      // The parens balance internally; the trailing ) is trimmed.
      expect(r!.text, 'https://e.com/a(b)c');
    });

    test('strips a trailing &entity; tail', () {
      final r = tryParseBareAutolink('see https://e.com&amp;', 4, 0x20);
      expect(r!.text, 'https://e.com');
    });

    test('strips a trailing &entity; with hash (numeric ref)', () {
      final r = tryParseBareAutolink('see https://e.com&#39;', 4, 0x20);
      expect(r!.text, 'https://e.com');
    });

    test('a lone trailing semicolon (no entity) is trimmed', () {
      final r = tryParseBareAutolink('see https://e.com;', 4, 0x20);
      expect(r!.text, 'https://e.com');
    });

    test('returns null when trimming eats back past the scheme', () {
      // Everything after the scheme is trailing punctuation → linkEnd <=
      // schemeEnd → null.
      final r = tryParseBareAutolink('https://!', 0, -1);
      expect(r, isNull);
    });

    test('stops the URL at the next < ', () {
      final r = tryParseBareAutolink('https://e.com<x', 0, -1);
      expect(r!.text, 'https://e.com');
    });

    test('stops the URL at the next whitespace', () {
      final r = tryParseBareAutolink('https://e.com tab', 0, -1);
      expect(r!.text, 'https://e.com');
    });

    test('CcBareAutolink exposes its fields', () {
      const a = CcBareAutolink(text: 't', url: 'u');
      expect(a.text, 't');
      expect(a.url, 'u');
    });
  });
}
