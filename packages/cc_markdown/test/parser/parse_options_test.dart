import 'package:cc_markdown/src/parser/parse_options.dart';
import 'package:flutter_test/flutter_test.dart';

/// Unit tests for [CcParseOptions] — the feature-toggle + safety-cap value
/// object. Equality and hashCode must cover every field so the parse cache's
/// `(data, options)` keying (when options are part of the key) behaves.
void main() {
  group('CcParseOptions', () {
    test('defaults to the full GFM profile', () {
      const o = CcParseOptions();
      expect(o.tables, isTrue);
      expect(o.strikethrough, isTrue);
      expect(o.autolinkExtension, isTrue);
      expect(o.footnotes, isTrue);
      expect(o.details, isTrue);
      expect(o.taskLists, isTrue);
      expect(o.setextHeadings, isTrue);
      expect(o.indentedCode, isTrue);
      expect(o.maxBlockDepth, 32);
      expect(o.maxInlineDepth, 16);
    });

    test('equal options are == and share a hashCode', () {
      const a = CcParseOptions();
      const b = CcParseOptions();
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('every field participates in equality', () {
      const base = CcParseOptions();
      expect(base, isNot(const CcParseOptions(tables: false)));
      expect(base, isNot(const CcParseOptions(strikethrough: false)));
      expect(base, isNot(const CcParseOptions(autolinkExtension: false)));
      expect(base, isNot(const CcParseOptions(footnotes: false)));
      expect(base, isNot(const CcParseOptions(details: false)));
      expect(base, isNot(const CcParseOptions(taskLists: false)));
      expect(base, isNot(const CcParseOptions(setextHeadings: false)));
      expect(base, isNot(const CcParseOptions(indentedCode: false)));
      expect(base, isNot(const CcParseOptions(maxBlockDepth: 8)));
      expect(base, isNot(const CcParseOptions(maxInlineDepth: 4)));
    });

    test('every field participates in hashCode (distinct hashes)', () {
      const base = CcParseOptions();
      // Flipping each field yields a distinct hashCode.
      final hashes = <int>{
        base.hashCode,
        const CcParseOptions(tables: false).hashCode,
        const CcParseOptions(strikethrough: false).hashCode,
        const CcParseOptions(autolinkExtension: false).hashCode,
        const CcParseOptions(footnotes: false).hashCode,
        const CcParseOptions(details: false).hashCode,
        const CcParseOptions(taskLists: false).hashCode,
        const CcParseOptions(setextHeadings: false).hashCode,
        const CcParseOptions(indentedCode: false).hashCode,
        const CcParseOptions(maxBlockDepth: 8).hashCode,
        const CcParseOptions(maxInlineDepth: 4).hashCode,
      };
      // All distinct.
      expect(hashes.length, 11);
    });

    test('== is reflexive and rejects unrelated types', () {
      const o = CcParseOptions();
      expect(o == o, isTrue);
      expect(o == Object(), isFalse);
    });
  });
}
