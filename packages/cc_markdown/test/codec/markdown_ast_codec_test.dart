import 'package:cc_markdown/cc_markdown.dart';
import 'package:flutter_test/flutter_test.dart';

/// Round-trip + edge-case tests for the typed-AST ↔ primitive-map codec.
///
/// The codec exists so a parsed document can cross an isolate / Web Worker
/// boundary and be rebuilt bit-for-bit. Every encode branch is exercised by
/// parsing a document that contains each node kind; the decode half is then
/// proven by asserting the rebuilt document equals the original.
void main() {
  group('encodeCcDocument / decodeCcDocument round-trip', () {
    test('preserves every inline kind across the boundary', () {
      final source = [
        'A **bold** and *italic* and ~~strike~~ and `code` line.',
        '',
        'A [link][l] and an ![image](https://i.dev/x.png "t") and a soft',
        'wrap plus a hard  ',
        'break.',
        '',
        '[l]: https://link.dev "L"',
      ].join('\n');
      final doc = const CcParser().parseDocument(source);

      final rebuilt = decodeCcDocument(encodeCcDocument(doc));

      expect(rebuilt.blocks, equals(doc.blocks));
      expect(rebuilt.linkRefs, equals(doc.linkRefs));
      expect(rebuilt.footnotes, equals(doc.footnotes));
    });

    test('preserves a table cell colspan across the boundary', () {
      final doc = const CcParser().parseDocument(
        '<table><tr><th>a</th><th>b</th></tr>'
        '<tr><td colspan="2">wide</td></tr></table>',
      );
      final table = doc.blocks.whereType<CcTable>().single;
      expect(table.rows.single.first.span, 2);

      final rebuilt = decodeCcDocument(encodeCcDocument(doc));

      expect(rebuilt.blocks, equals(doc.blocks));
      final rebuiltTable = rebuilt.blocks.whereType<CcTable>().single;
      expect(rebuiltTable.rows.single.first.span, 2);
    });

    test('preserves every block kind across the boundary', () {
      // Exercises paragraph, heading, code block, blockquote, ordered + task
      // list, table, thematic break, html block, details, and footnote def.
      final source = [
        '# Heading',
        '',
        '> quoted text',
        '',
        '```dart',
        'void main() {}',
        '```',
        '',
        '- [x] done',
        '- [ ] todo',
        '',
        '1. first',
        '2. second',
        '',
        '| A | B |',
        '|---|---:|',
        '| 1 | 2 |',
        '',
        '---',
        '',
        '<div>raw html block</div>',
        '',
        '<details>',
        '<summary>S</summary>',
        '',
        'hidden body',
        '',
        '</details>',
        '',
        'Body with a note[^1].',
        '',
        '[^1]: The footnote text.',
      ].join('\n');
      final doc = const CcParser().parseDocument(source);

      final rebuilt = decodeCcDocument(encodeCcDocument(doc));

      expect(rebuilt.blocks, equals(doc.blocks), reason: 'blocks differ');
      expect(
        rebuilt.footnotes,
        equals(doc.footnotes),
        reason: 'footnotes differ',
      );
    });

    test('preserves link references verbatim (url + title)', () {
      const source = '[ref][L]\n\n[L]: https://example.org "the title"';
      final doc = const CcParser().parseDocument(source);

      expect(doc.linkRefs, isNotEmpty);
      final rebuilt = decodeCcDocument(encodeCcDocument(doc));
      expect(rebuilt.linkRefs, equals(doc.linkRefs));
      expect(rebuilt.linkRefs.values.single.url, 'https://example.org');
      expect(rebuilt.linkRefs.values.single.title, 'the title');
    });

    test('link reference with no title round-trips title=null', () {
      const source = '[ref][L]\n\n[L]: https://example.org';
      final doc = const CcParser().parseDocument(source);

      final rebuilt = decodeCcDocument(encodeCcDocument(doc));
      expect(rebuilt.linkRefs.values.single.title, isNull);
      expect(rebuilt.linkRefs, equals(doc.linkRefs));
    });

    test('the encoded form is JSON-shaped (only primitives)', () {
      const source = '# H\n\nbody `code`';
      final doc = const CcParser().parseDocument(source);
      final map = encodeCcDocument(doc);

      // Top-level keys are present and the blocks list is non-empty.
      expect(
        map.keys,
        containsAll(<String>['blocks', 'linkRefs', 'footnotes']),
      );
      expect(map['blocks'], isA<List>());
      // No CcNode instances leak into the primitive form.
      void assertPrimitive(Object? v) {
        switch (v) {
          case null:
          case String():
          case int():
          case bool():
            return;
          case List(:final length):
            for (var i = 0; i < length; i++) {
              assertPrimitive(v[i]);
            }
          case Map(:final values):
            for (final entry in values) {
              assertPrimitive(entry);
            }
        }
      }

      assertPrimitive(map);
    });
  });

  group('encode error paths', () {
    test(
      'a CcCustomBlock node throws UnsupportedError (never silently dropped)',
      () {
        const doc = CcDocument(blocks: [_WidgetlessBlock()]);
        expect(() => encodeCcDocument(doc), throwsA(isA<UnsupportedError>()));
      },
    );

    test('a CcCustomInline node throws UnsupportedError', () {
      const doc = CcDocument(
        blocks: [
          CcParagraph([_WidgetlessInline()]),
        ],
      );
      expect(() => encodeCcDocument(doc), throwsA(isA<UnsupportedError>()));
    });
  });

  group('decode error paths', () {
    test('an unknown inline nodeType throws UnsupportedError', () {
      const map = {
        'blocks': [
          {
            't': 'paragraph',
            'children': [
              {'t': 'never_seen_inline', 'text': 'x'},
            ],
          },
        ],
        'linkRefs': <String, dynamic>{},
        'footnotes': <dynamic>[],
      };
      expect(() => decodeCcDocument(map), throwsA(isA<UnsupportedError>()));
    });

    test('an unknown block nodeType throws UnsupportedError', () {
      const map = {
        'blocks': [
          {'t': 'never_seen_block'},
        ],
        'linkRefs': <String, dynamic>{},
        'footnotes': <dynamic>[],
      };
      expect(() => decodeCcDocument(map), throwsA(isA<UnsupportedError>()));
    });

    test('decodes a table with a null alignment (default column)', () {
      // A column with no alignment marker encodes as null index; decode must
      // reconstruct it as null without indexing the enum.
      const map = {
        'blocks': [
          {
            't': 'table',
            'header': [
              [
                {'t': 'text', 'text': 'A'},
              ],
            ],
            'alignments': <dynamic>[null],
            'rows': <dynamic>[
              [
                [
                  {'t': 'text', 'text': '1'},
                ],
              ],
            ],
          },
        ],
        'linkRefs': <String, dynamic>{},
        'footnotes': <dynamic>[],
      };
      final doc = decodeCcDocument(map);
      final table = doc.blocks.single as CcTable;
      expect(table.alignments.single, isNull);
      expect((table.rows.single.single.children.single as CcText).text, '1');
    });

    test('decodes a list item with checked=null (plain bullet)', () {
      const map = {
        'blocks': [
          {
            't': 'list',
            'ordered': false,
            'start': 1,
            'tight': true,
            'items': [
              {
                'checked': null,
                'children': [
                  {
                    't': 'paragraph',
                    'children': [
                      {'t': 'text', 'text': 'item'},
                    ],
                  },
                ],
              },
            ],
          },
        ],
        'linkRefs': <String, dynamic>{},
        'footnotes': <dynamic>[],
      };
      final doc = decodeCcDocument(map);
      final list = doc.blocks.single as CcList;
      expect(list.items.single.checked, isNull);
    });
  });

  group('mermaid nodes', () {
    test('a mermaid block round-trips through the codec', () {
      const source = 'flowchart TD\n  A[Start] -->|go| B((End))';
      const doc = CcDocument(
        blocks: [
          CcParagraph([CcText('before')]),
          CcMermaid(source),
        ],
        linkRefs: {},
        footnotes: [],
      );
      final decoded = decodeCcDocument(encodeCcDocument(doc));
      expect(decoded.blocks.whereType<CcMermaid>().single.source, source);
      expect(decoded.blocks, doc.blocks);
    });

    test('the encoded form is JSON-primitive only', () {
      final map = encodeCcDocument(
        const CcDocument(
          blocks: [CcMermaid('graph TD\n A --> B')],
          linkRefs: {},
          footnotes: [],
        ),
      );
      final block = (map['blocks'] as List).single as Map<String, dynamic>;
      expect(block['t'], 'mermaid');
      expect(block['source'], isA<String>());
    });
  });
}

/// A custom block node with no registered builder, to exercise the
/// UnsupportedError encode path.
class _WidgetlessBlock extends CcCustomBlock {
  const _WidgetlessBlock();
  @override
  String get nodeType => 'widgetless_block';
  @override
  bool operator ==(Object other) => other is _WidgetlessBlock;
  @override
  int get hashCode => nodeType.hashCode;
}

class _WidgetlessInline extends CcCustomInline {
  const _WidgetlessInline();
  @override
  String get nodeType => 'widgetless_inline';
  @override
  bool operator ==(Object other) => other is _WidgetlessInline;
  @override
  int get hashCode => nodeType.hashCode;
}
