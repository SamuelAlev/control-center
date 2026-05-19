import 'package:cc_markdown/cc_markdown.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    CcMarkdownCache.clearCache();
    CcMarkdownCache.debugParseCount = 0;
    CcMarkdownCache.debugParseOverride = null;
  });

  test('append grows the tail until a block seals', () {
    final c = CcMarkdownStreamController();
    c.append('Hello wor');
    expect(c.sealedBlocks, isEmpty);
    expect(c.tailText, 'Hello wor');
    // A paragraph seals only once the NEXT block's first line is complete
    // (newline-terminated) — conservative, so a construct never splits.
    c.append('ld.\n\nNext para\nmore');
    expect(c.sealedBlocks, hasLength(1));
    expect(c.sealedBlocks.single.nodes.single, isA<CcParagraph>());
    expect(c.tailText.trim(), startsWith('Next para'));
  });

  test('sealed segments parse ephemerally (no global cache traffic)', () {
    final c = CcMarkdownStreamController();
    c.append('First block.\n\nsecond\nmore');
    expect(c.sealedBlocks, hasLength(1));
    // The sealed segment was parsed via parseEphemeral — the global cache is
    // untouched during the stream.
    expect(
      CcMarkdownCache.parseEphemeral('anything', CcPluginSet.empty),
      isNotNull,
    );
    final before = CcMarkdownCache.debugParseCount;
    // A fresh parseCached of the sealed segment's source is still a MISS,
    // proving the stream never inserted it.
    CcMarkdownCache.parseCached('First block.', CcPluginSet.empty);
    expect(CcMarkdownCache.debugParseCount, before + 1);
  });

  test('sealed block instances are identical across later appends', () {
    final c = CcMarkdownStreamController();
    c.append('Alpha.\n\nBeta.\n\nlast\nx');
    expect(c.sealedBlocks, isNotEmpty);
    final firstSealed = c.sealedBlocks.first;
    c.append(' more\n\nnew tail\ny');
    expect(identical(c.sealedBlocks.first, firstSealed), isTrue);
  });

  test('complete collapses to one authoritative block and seeds the cache', () {
    final c = CcMarkdownStreamController();
    c.append('See [d].\n\n');
    c.append('[d]: https://x.dev\n');
    c.complete();
    expect(c.isComplete, isTrue);
    expect(c.sealedBlocks, hasLength(1));
    expect(c.tailText.trim(), isEmpty);
    // The authoritative parse resolved the late link-reference definition.
    final para = c.sealedBlocks.single.nodes.whereType<CcParagraph>().first;
    expect(para.children.whereType<CcLink>().single.url, 'https://x.dev');
    // And it seeded the global cache: re-parsing the final text is a hit.
    CcMarkdownCache.debugParseCount = 0;
    CcMarkdownCache.parseCached(c.text, CcPluginSet.empty);
    expect(CcMarkdownCache.debugParseCount, 0);
  });

  test('setText appends when the text extends, rescans on a rewrite', () {
    final c = CcMarkdownStreamController();
    c.setText('One.\n\nTwo.\n\ntail\nx');
    expect(c.sealedBlocks.length, greaterThanOrEqualTo(1));
    final sealedCount = c.sealedBlocks.length;
    // Append-shaped setText keeps the sealed blocks.
    c.setText('One.\n\nTwo.\n\ntail\nx grows');
    expect(c.sealedBlocks.length, sealedCount);
    // A genuine rewrite (diverges at the start) rescans from scratch.
    c.setText('Rewritten entirely.');
    expect(c.text, 'Rewritten entirely.');
    expect(c.sealedBlocks, isEmpty);
    expect(c.tailText, 'Rewritten entirely.');
  });

  test('revision bumps and listeners fire on every mutation', () {
    final c = CcMarkdownStreamController();
    var notifications = 0;
    c.addListener(() => notifications++);
    final r0 = c.revision;
    c.append('a');
    c.append('b\n\nc');
    c.complete();
    expect(c.revision, greaterThan(r0));
    expect(notifications, greaterThanOrEqualTo(3));
  });

  test('reset clears state', () {
    final c = CcMarkdownStreamController()..append('x\n\ny');
    c.reset();
    expect(c.text, isEmpty);
    expect(c.sealedBlocks, isEmpty);
  });

  // While a fence is open the boundary cannot advance, so the tail is the
  // whole (growing) fence and the generic parse re-scanned all of it on every
  // delta — the shape an LLM answer is dominated by. `openFenceTail` lets the
  // renderer build the code node directly. These pin when it may be used.
  group('openFenceTail', () {
    test('is null before any fence opens', () {
      final c = CcMarkdownStreamController()..append('some prose\n');
      expect(c.openFenceTail, isNull);
    });

    test('describes an open fence that is the whole tail', () {
      final c = CcMarkdownStreamController()
        ..append('```dart\n')
        ..append('void main() {\n')
        ..append('  print(1);\n');
      final tail = c.openFenceTail;
      expect(tail, isNotNull);
      expect(tail!.info, 'dart');
      expect(tail.code, 'void main() {\n  print(1);\n');
    });

    test('carries an empty info string for an unlabelled fence', () {
      final c = CcMarkdownStreamController()..append('```\nplain\n');
      expect(c.openFenceTail?.info, isEmpty);
      expect(c.openFenceTail?.code, 'plain\n');
    });

    test('is null once the fence closes', () {
      final c = CcMarkdownStreamController()
        ..append('```dart\n')
        ..append('x\n')
        ..append('```\n');
      expect(c.openFenceTail, isNull);
    });

    test('is null when unsealed prose precedes the fence', () {
      // Anything before the opener is markdown that has to be parsed, so the
      // fast path must decline rather than silently drop it.
      final c = CcMarkdownStreamController()
        ..append('intro line\n')
        ..append('```dart\n')
        ..append('x\n');
      expect(c.openFenceTail, isNull);
    });

    test('applies again after earlier content sealed away', () {
      final c = CcMarkdownStreamController()
        ..append('a paragraph\n')
        ..append('\n')
        ..append('still here\n')
        ..append('\n')
        ..append('```dart\n')
        ..append('body\n');
      final tail = c.openFenceTail;
      expect(tail, isNotNull);
      expect(tail!.code, 'body\n');
    });

    test('reset clears the open-fence state', () {
      final c = CcMarkdownStreamController()..append('```dart\nx\n');
      expect(c.openFenceTail, isNotNull);
      c.reset();
      expect(c.openFenceTail, isNull);
    });
  });
}
