import 'package:cc_domain/features/dispatch/domain/edit/content_hash.dart';
import 'package:test/test.dart';

void main() {
  group('normalizeContent', () {
    test('strips a leading UTF-8 BOM', () {
      expect(normalizeContent('﻿hello'), 'hello');
    });

    test('only strips the BOM when it is leading', () {
      expect(normalizeContent('a﻿b'), 'a﻿b');
    });

    test('converts CRLF to LF', () {
      expect(normalizeContent('a\r\nb\r\nc'), 'a\nb\nc');
    });

    test('converts lone CR to LF', () {
      expect(normalizeContent('a\rb\rc'), 'a\nb\nc');
    });

    test('leaves already-normalized LF text untouched', () {
      expect(normalizeContent('a\nb\nc'), 'a\nb\nc');
    });

    test('handles empty input', () {
      expect(normalizeContent(''), '');
    });
  });

  group('computeContentHash', () {
    test('is exactly 4 lowercase hex characters', () {
      for (final s in ['', 'hello', 'a\nb\nc\n', 'longer\ncontent\nhere']) {
        final hash = computeContentHash(s);
        expect(hash, hasLength(contentHashLength));
        expect(hash, matches(RegExp(r'^[0-9a-f]{4}$')));
      }
    });

    test('is deterministic across calls', () {
      expect(computeContentHash('hello\nworld'),
          computeContentHash('hello\nworld'));
    });

    test('matches the known fingerprint for a fixed input', () {
      // Pinned so a change to the hash algorithm is caught.
      expect(computeContentHash('hello'), '6334');
      expect(computeContentHash(''), '1cd9');
    });

    test('differs for different content', () {
      expect(computeContentHash('hello'), isNot(computeContentHash('world')));
    });

    test('BOM + CRLF content hashes identically to plain LF content', () {
      expect(
        computeContentHash('﻿hello\r\nworld'),
        computeContentHash('hello\nworld'),
      );
    });

    test('lone CR content hashes identically to plain LF content', () {
      expect(computeContentHash('a\rb'), computeContentHash('a\nb'));
    });
  });
}
