import 'package:cc_markdown/cc_markdown.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    CcMarkdownCache.clearCache();
    CcMarkdownCache.debugParseCount = 0;
    CcMarkdownCache.debugParseOverride = null;
  });

  tearDown(() => CcMarkdownCache.debugParseOverride = null);

  group('CcParseCache LRU', () {
    test('get refreshes recency; eviction drops the least-recently-used', () {
      final cache = CcParseCache(maxSize: 2);
      const p = CcPluginSet.empty;
      cache.put('a', p, const [
        CcParagraph([CcText('a')]),
      ]);
      cache.put('b', p, const [
        CcParagraph([CcText('b')]),
      ]);
      // Touch 'a' so 'b' becomes the LRU victim.
      expect(cache.get('a', p), isNotNull);
      cache.put('c', p, const [
        CcParagraph([CcText('c')]),
      ]);
      expect(cache.get('b', p), isNull);
      expect(cache.get('a', p), isNotNull);
      expect(cache.get('c', p), isNotNull);
      expect(cache.length, 2);
    });

    test('keys on plugin-set identity: distinct sets are distinct entries', () {
      final cache = CcParseCache();
      final setA = CcPluginSet(const [CcThinkingPlugin()]);
      final setB = CcPluginSet(const [CcThinkingPlugin()]);
      cache.put('same', setA, const [
        CcParagraph([CcText('A')]),
      ]);
      // Same string, a DIFFERENT (though equivalent) set instance → miss.
      expect(cache.get('same', setB), isNull);
      // Same instance → hit.
      expect(cache.get('same', setA), isNotNull);
    });
  });

  group('CcMarkdownCache facade', () {
    test('parseCached returns the identical list instance on a hit', () {
      final first = CcMarkdownCache.parseCached('# hi', CcPluginSet.empty);
      final second = CcMarkdownCache.parseCached('# hi', CcPluginSet.empty);
      expect(identical(first, second), isTrue);
      expect(CcMarkdownCache.debugParseCount, 1);
    });

    test('parseEphemeral consults the cache but never inserts', () {
      // Miss: parses, does NOT store.
      CcMarkdownCache.parseEphemeral('ephemeral', CcPluginSet.empty);
      expect(CcMarkdownCache.debugParseCount, 1);
      // Still a miss (nothing was stored) → parses again.
      CcMarkdownCache.parseEphemeral('ephemeral', CcPluginSet.empty);
      expect(CcMarkdownCache.debugParseCount, 2);
      // But it DOES return a cached hit when one exists.
      final cached = CcMarkdownCache.parseCached('stored', CcPluginSet.empty);
      final ephemeral = CcMarkdownCache.parseEphemeral(
        'stored',
        CcPluginSet.empty,
      );
      expect(identical(cached, ephemeral), isTrue);
    });

    test('debugParseOverride is consulted only on a miss', () {
      var overrideCalls = 0;
      CcMarkdownCache.debugParseOverride = (data, plugins) {
        overrideCalls++;
        return const [
          CcParagraph([CcText('overridden')]),
        ];
      };
      CcMarkdownCache.parseCached('x', CcPluginSet.empty);
      CcMarkdownCache.parseCached('x', CcPluginSet.empty); // hit
      expect(overrideCalls, 1);
    });

    test('seed makes the next parseCached a hit', () {
      const nodes = [
        CcParagraph([CcText('seeded')]),
      ];
      CcMarkdownCache.seed('k', CcPluginSet.empty, nodes);
      final got = CcMarkdownCache.parseCached('k', CcPluginSet.empty);
      expect(identical(got, nodes), isTrue);
      expect(CcMarkdownCache.debugParseCount, 0);
    });

    test('footnote definitions ride at the end of the cached list', () {
      final nodes = CcMarkdownCache.parseCached(
        'Ref[^1].\n\n[^1]: note',
        CcPluginSet.empty,
      );
      expect(nodes.whereType<CcFootnoteDef>(), hasLength(1));
      expect(nodes.last, isA<CcFootnoteDef>());
    });
  });

  group('option keying', () {
    test('the same source under different options parses separately', () {
      // Two registers can share a plugin set yet disagree on grammar toggles;
      // without options in the key, whichever parsed first would answer for both.
      const source = '```mermaid\nflowchart TD\n A --> B\n```';
      final drawn = CcMarkdownCache.parseCached(source, CcPluginSet.empty);
      final asCode = CcMarkdownCache.parseCached(
        source,
        CcPluginSet.empty,
        options: const CcParseOptions(mermaid: false),
      );
      expect(drawn.whereType<CcMermaid>(), hasLength(1));
      expect(asCode.whereType<CcMermaid>(), isEmpty);
      expect(asCode.whereType<CcCodeBlock>(), hasLength(1));
    });

    test('a cached entry is only a hit for its own options', () {
      final cache = CcParseCache();
      const nodes = [
        CcParagraph([CcText('a')]),
      ];
      cache.put('a', CcPluginSet.empty, nodes);
      expect(cache.get('a', CcPluginSet.empty), same(nodes));
      expect(
        cache.get(
          'a',
          CcPluginSet.empty,
          options: const CcParseOptions(footnotes: false),
        ),
        isNull,
      );
    });
  });

  group('CcParseCache.remove', () {
    test('removes an existing entry and returns true', () {
      final cache = CcParseCache();
      const p = CcPluginSet.empty;
      cache.put('a', p, const [
        CcParagraph([CcText('a')]),
      ]);
      expect(cache.remove('a', p), isTrue);
      expect(cache.get('a', p), isNull);
    });

    test('returns false for a missing entry', () {
      final cache = CcParseCache();
      expect(cache.remove('absent', CcPluginSet.empty), isFalse);
    });
  });
}
