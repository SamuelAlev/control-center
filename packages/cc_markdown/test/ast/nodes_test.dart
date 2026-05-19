import 'package:cc_markdown/cc_markdown.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ccListEquals', () {
    test('identical list returns true', () {
      const list = <CcInlineNode>[CcText('a')];
      expect(ccListEquals(list, list), isTrue);
    });

    test('equal contents compare true', () {
      expect(
        ccListEquals<CcInlineNode>(
          const [CcText('a'), CcText('b')],
          const [CcText('a'), CcText('b')],
        ),
        isTrue,
      );
    });

    test('differing lengths compare false', () {
      expect(
        ccListEquals<CcInlineNode>(
          const [CcText('a')],
          const [CcText('a'), CcText('b')],
        ),
        isFalse,
      );
    });

    test('differing element compares false', () {
      expect(
        ccListEquals<CcInlineNode>(const [CcText('a')], const [CcText('b')]),
        isFalse,
      );
    });

    test('empty lists compare true', () {
      expect(ccListEquals<CcInlineNode>(const [], const []), isTrue);
    });
  });

  group('CcNode hierarchy', () {
    test('inlines extend CcInlineNode and blocks extend CcBlockNode', () {
      expect(const CcText('x'), isA<CcInlineNode>());
      expect(const CcText('x'), isA<CcNode>());
      expect(const CcParagraph([CcText('x')]), isA<CcBlockNode>());
      expect(const CcParagraph([CcText('x')]), isA<CcNode>());
    });

    test('CcSoftBreak / CcHardBreak are singletons value-wise', () {
      expect(const CcSoftBreak(), equals(const CcSoftBreak()));
      expect(const CcHardBreak(), equals(const CcHardBreak()));
      expect(const CcSoftBreak().hashCode, const CcSoftBreak().hashCode);
      expect(const CcSoftBreak(), isNot(equals(const CcHardBreak())));
    });
  });

  group('CcText', () {
    test('stores text, nodeType, and equals by text', () {
      expect(const CcText('hi').text, 'hi');
      expect(const CcText('hi').nodeType, 'text');
      expect(const CcText('hi'), equals(const CcText('hi')));
      expect(const CcText('hi'), isNot(equals(const CcText('bye'))));
    });

    test('hashCode agrees for equal text', () {
      expect(const CcText('hi').hashCode, const CcText('hi').hashCode);
    });

    test('does not equal an unrelated type', () {
      expect(const CcText('hi'), isNot(equals(Object())));
    });

    test('toString truncates long text with an ellipsis', () {
      final long = 'x' * 100;
      final s = CcText(long).toString();
      expect(s, contains('…'));
      expect(s.length, lessThan(long.length + 20));
      expect(s, startsWith('CcText('));
    });

    test('toString keeps short text verbatim', () {
      expect(const CcText('short').toString(), 'CcText(short)');
    });
  });

  group('CcEmphasis / CcStrong / CcStrikethrough', () {
    test('CcEmphasis equals by deep children', () {
      const a = CcEmphasis([CcText('x')]);
      const b = CcEmphasis([CcText('x')]);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(const CcEmphasis([CcText('x')]).nodeType, 'emphasis');
    });

    test('CcEmphasis differs by children', () {
      expect(
        const CcEmphasis([CcText('x')]),
        isNot(equals(const CcEmphasis([CcText('y')]))),
      );
      expect(
        const CcEmphasis([CcText('x')]),
        isNot(equals(const CcEmphasis([CcText('x'), CcText('y')]))),
      );
    });

    test('CcStrong equals by deep children', () {
      const a = CcStrong([CcText('x')]);
      const b = CcStrong([CcText('x')]);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(const CcStrong([CcText('x')]).nodeType, 'strong');
    });

    test('CcStrong differs by children', () {
      expect(
        const CcStrong([CcText('x')]),
        isNot(equals(const CcStrong([CcText('y')]))),
      );
    });

    test('CcStrikethrough equals by deep children', () {
      const a = CcStrikethrough([CcText('x')]);
      const b = CcStrikethrough([CcText('x')]);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(const CcStrikethrough([CcText('x')]).nodeType, 'strikethrough');
    });

    test('CcStrikethrough differs by children', () {
      expect(
        const CcStrikethrough([CcText('x')]),
        isNot(equals(const CcStrikethrough([CcText('y')]))),
      );
    });

    test('distinct node types with same children are not equal', () {
      expect(
        const CcEmphasis([CcText('x')]),
        isNot(equals(const CcStrong([CcText('x')]))),
      );
    });
  });

  group('CcInlineCode', () {
    test('stores code, nodeType, equals by code', () {
      expect(const CcInlineCode('x = 1').code, 'x = 1');
      expect(const CcInlineCode('x').nodeType, 'inline_code');
      expect(const CcInlineCode('x'), equals(const CcInlineCode('x')));
      expect(const CcInlineCode('x'), isNot(equals(const CcInlineCode('y'))));
      expect(
        const CcInlineCode('x').hashCode,
        const CcInlineCode('x').hashCode,
      );
    });
  });

  group('CcLink', () {
    test('stores all fields with default title/autolink', () {
      const link = CcLink(url: 'https://a.dev', children: [CcText('a')]);
      expect(link.url, 'https://a.dev');
      expect(link.title, isNull);
      expect(link.children.single, const CcText('a'));
      expect(link.autolink, isFalse);
      expect(link.nodeType, 'link');
    });

    test('equals when every field matches', () {
      expect(
        const CcLink(
          url: 'https://a.dev',
          title: 't',
          autolink: true,
          children: [CcText('a')],
        ),
        const CcLink(
          url: 'https://a.dev',
          title: 't',
          autolink: true,
          children: [CcText('a')],
        ),
      );
    });

    test('differs when url/title/autolink/children differ', () {
      const base = CcLink(
        url: 'https://a.dev',
        title: 't',
        autolink: true,
        children: [CcText('a')],
      );
      expect(
        base,
        isNot(
          equals(
            const CcLink(
              url: 'https://b.dev',
              title: 't',
              autolink: true,
              children: [CcText('a')],
            ),
          ),
        ),
      );
      expect(
        base,
        isNot(
          equals(
            const CcLink(
              url: 'https://a.dev',
              title: 'u',
              autolink: true,
              children: [CcText('a')],
            ),
          ),
        ),
      );
      expect(
        base,
        isNot(
          equals(
            const CcLink(
              url: 'https://a.dev',
              title: 't',
              autolink: false,
              children: [CcText('a')],
            ),
          ),
        ),
      );
      expect(
        base,
        isNot(
          equals(
            const CcLink(
              url: 'https://a.dev',
              title: 't',
              autolink: true,
              children: [CcText('b')],
            ),
          ),
        ),
      );
    });

    test('hashCode agrees for equal links', () {
      const a = CcLink(
        url: 'https://a.dev',
        title: 't',
        autolink: true,
        children: [CcText('a')],
      );
      const b = CcLink(
        url: 'https://a.dev',
        title: 't',
        autolink: true,
        children: [CcText('a')],
      );
      expect(a.hashCode, b.hashCode);
    });
  });

  group('CcImage', () {
    test('stores all fields with default title', () {
      const img = CcImage(url: 'https://i.dev/x.png', alt: 'pic');
      expect(img.url, 'https://i.dev/x.png');
      expect(img.alt, 'pic');
      expect(img.title, isNull);
      expect(img.nodeType, 'image');
    });

    test('equals when url/alt/title match', () {
      expect(
        const CcImage(url: 'u', alt: 'a', title: 't'),
        const CcImage(url: 'u', alt: 'a', title: 't'),
      );
    });

    test('differs when url/alt/title differ', () {
      const base = CcImage(url: 'u', alt: 'a', title: 't');
      expect(base, isNot(equals(const CcImage(url: 'u2', alt: 'a'))));
      expect(base, isNot(equals(const CcImage(url: 'u', alt: 'a2'))));
      expect(
        base,
        isNot(equals(const CcImage(url: 'u', alt: 'a', title: 't2'))),
      );
    });

    test('hashCode agrees for equal images', () {
      expect(
        const CcImage(url: 'u', alt: 'a', title: 't').hashCode,
        const CcImage(url: 'u', alt: 'a', title: 't').hashCode,
      );
    });
  });

  group('CcFootnoteRef', () {
    test('stores label/index and equals', () {
      const ref = CcFootnoteRef(label: '1', index: 1);
      expect(ref.label, '1');
      expect(ref.index, 1);
      expect(ref.nodeType, 'footnote_ref');
      expect(
        const CcFootnoteRef(label: '1', index: 1),
        equals(const CcFootnoteRef(label: '1', index: 1)),
      );
      expect(
        const CcFootnoteRef(label: '1', index: 1),
        isNot(equals(const CcFootnoteRef(label: '2', index: 1))),
      );
      expect(
        const CcFootnoteRef(label: '1', index: 1),
        isNot(equals(const CcFootnoteRef(label: '1', index: 2))),
      );
      expect(
        const CcFootnoteRef(label: '1', index: 1).hashCode,
        const CcFootnoteRef(label: '1', index: 1).hashCode,
      );
    });
  });

  group('CcInlineHtml', () {
    test('stores raw and equals', () {
      expect(const CcInlineHtml('<sup>').raw, '<sup>');
      expect(const CcInlineHtml('<sup>').nodeType, 'inline_html');
      expect(const CcInlineHtml('<sup>'), equals(const CcInlineHtml('<sup>')));
      expect(
        const CcInlineHtml('<sup>'),
        isNot(equals(const CcInlineHtml('<sub>'))),
      );
      expect(
        const CcInlineHtml('<sup>').hashCode,
        const CcInlineHtml('<sup>').hashCode,
      );
    });
  });

  group('CcParagraph', () {
    test('equals by deep children', () {
      const a = CcParagraph([CcText('x'), CcText('y')]);
      const b = CcParagraph([CcText('x'), CcText('y')]);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(const CcParagraph([CcText('x')]).nodeType, 'paragraph');
    });

    test('differs by children', () {
      expect(
        const CcParagraph([CcText('x')]),
        isNot(equals(const CcParagraph([CcText('y')]))),
      );
    });
  });

  group('CcHeading', () {
    test('stores level/children and equals', () {
      const h = CcHeading(level: 2, children: [CcText('Hi')]);
      expect(h.level, 2);
      expect(h.children.single, const CcText('Hi'));
      expect(h.nodeType, 'heading');
      expect(
        const CcHeading(level: 2, children: [CcText('Hi')]),
        equals(const CcHeading(level: 2, children: [CcText('Hi')])),
      );
    });

    test('differs by level and children', () {
      expect(
        const CcHeading(level: 1, children: [CcText('Hi')]),
        isNot(equals(const CcHeading(level: 2, children: [CcText('Hi')]))),
      );
      expect(
        const CcHeading(level: 1, children: [CcText('Hi')]),
        isNot(equals(const CcHeading(level: 1, children: [CcText('Yo')]))),
      );
    });

    test('hashCode agrees for equal headings', () {
      expect(
        const CcHeading(level: 3, children: [CcText('Hi')]).hashCode,
        const CcHeading(level: 3, children: [CcText('Hi')]).hashCode,
      );
    });
  });

  group('CcCodeBlock', () {
    test('stores required code and defaults', () {
      const block = CcCodeBlock(code: 'print(1)');
      expect(block.code, 'print(1)');
      expect(block.language, isNull);
      expect(block.fenced, isTrue);
      expect(block.closed, isTrue);
      expect(block.nodeType, 'code_block');
    });

    test('stores all fields', () {
      const block = CcCodeBlock(
        code: 'x',
        language: 'dart',
        fenced: false,
        closed: false,
      );
      expect(block.language, 'dart');
      expect(block.fenced, isFalse);
      expect(block.closed, isFalse);
    });

    test('equals when every field matches', () {
      expect(
        const CcCodeBlock(
          code: 'x',
          language: 'dart',
          fenced: true,
          closed: false,
        ),
        const CcCodeBlock(
          code: 'x',
          language: 'dart',
          fenced: true,
          closed: false,
        ),
      );
    });

    test('differs when any field differs', () {
      const base = CcCodeBlock(
        code: 'x',
        language: 'dart',
        fenced: true,
        closed: true,
      );
      expect(base, isNot(equals(const CcCodeBlock(code: 'y'))));
      expect(base, isNot(equals(const CcCodeBlock(code: 'x', language: 'py'))));
      expect(
        base,
        isNot(
          equals(const CcCodeBlock(code: 'x', language: 'dart', fenced: false)),
        ),
      );
      expect(
        base,
        isNot(
          equals(const CcCodeBlock(code: 'x', language: 'dart', closed: false)),
        ),
      );
    });

    test('hashCode agrees for equal blocks', () {
      expect(
        const CcCodeBlock(
          code: 'x',
          language: 'dart',
          fenced: false,
          closed: false,
        ).hashCode,
        const CcCodeBlock(
          code: 'x',
          language: 'dart',
          fenced: false,
          closed: false,
        ).hashCode,
      );
    });
  });

  group('CcBlockquote', () {
    test('equals by deep children', () {
      const a = CcBlockquote([
        CcParagraph([CcText('q')]),
      ]);
      const b = CcBlockquote([
        CcParagraph([CcText('q')]),
      ]);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(const CcBlockquote([]).nodeType, 'blockquote');
    });

    test('differs by children', () {
      expect(
        const CcBlockquote([
          CcParagraph([CcText('a')]),
        ]),
        isNot(
          equals(
            const CcBlockquote([
              CcParagraph([CcText('b')]),
            ]),
          ),
        ),
      );
    });
  });

  group('CcListItem', () {
    test('stores children and checked state', () {
      const item = CcListItem(
        children: [
          CcParagraph([CcText('done')]),
        ],
        checked: true,
      );
      expect(item.checked, isTrue);
      expect(
        (item.children.single as CcParagraph).children.single,
        const CcText('done'),
      );
    });

    test('equals by checked and deep children', () {
      expect(
        const CcListItem(
          children: [
            CcParagraph([CcText('x')]),
          ],
          checked: true,
        ),
        const CcListItem(
          children: [
            CcParagraph([CcText('x')]),
          ],
          checked: true,
        ),
      );
    });

    test('differs by checked and children', () {
      const base = CcListItem(
        children: [
          CcParagraph([CcText('x')]),
        ],
        checked: true,
      );
      expect(
        base,
        isNot(
          equals(
            const CcListItem(
              children: [
                CcParagraph([CcText('x')]),
              ],
              checked: false,
            ),
          ),
        ),
      );
      expect(
        base,
        isNot(
          equals(
            const CcListItem(
              children: [
                CcParagraph([CcText('y')]),
              ],
              checked: true,
            ),
          ),
        ),
      );
    });

    test('hashCode agrees for equal items', () {
      expect(
        const CcListItem(
          children: [
            CcParagraph([CcText('x')]),
          ],
          checked: null,
        ).hashCode,
        const CcListItem(
          children: [
            CcParagraph([CcText('x')]),
          ],
          checked: null,
        ).hashCode,
      );
    });
  });

  group('CcList', () {
    test('stores ordered/items/start/tight with defaults', () {
      const list = CcList(ordered: false, items: [CcListItem(children: [])]);
      expect(list.ordered, isFalse);
      expect(list.items, hasLength(1));
      expect(list.start, 1);
      expect(list.tight, isTrue);
      expect(list.nodeType, 'list');
    });

    test('equals when all fields match', () {
      expect(
        const CcList(
          ordered: true,
          start: 3,
          tight: false,
          items: [CcListItem(children: [], checked: true)],
        ),
        const CcList(
          ordered: true,
          start: 3,
          tight: false,
          items: [CcListItem(children: [], checked: true)],
        ),
      );
    });

    test('differs when ordered/start/tight/items differ', () {
      const base = CcList(
        ordered: true,
        start: 3,
        tight: false,
        items: [CcListItem(children: [], checked: true)],
      );
      expect(
        base,
        isNot(
          equals(
            const CcList(ordered: false, start: 3, tight: false, items: []),
          ),
        ),
      );
      expect(
        base,
        isNot(
          equals(
            const CcList(ordered: true, start: 4, tight: false, items: []),
          ),
        ),
      );
      expect(
        base,
        isNot(
          equals(const CcList(ordered: true, start: 3, tight: true, items: [])),
        ),
      );
      expect(
        base,
        isNot(
          equals(
            const CcList(
              ordered: true,
              start: 3,
              tight: false,
              items: [CcListItem(children: [], checked: false)],
            ),
          ),
        ),
      );
    });

    test('hashCode agrees for equal lists', () {
      expect(
        const CcList(ordered: true, start: 2, tight: false, items: []).hashCode,
        const CcList(ordered: true, start: 2, tight: false, items: []).hashCode,
      );
    });
  });

  group('CcTableAlign', () {
    test('has the three expected values', () {
      expect(
        CcTableAlign.values,
        containsAll([
          CcTableAlign.left,
          CcTableAlign.center,
          CcTableAlign.right,
        ]),
      );
    });
  });

  group('CcTableCell', () {
    test('equals by deep children', () {
      expect(
        const CcTableCell([CcText('a')]),
        const CcTableCell([CcText('a')]),
      );
      expect(
        const CcTableCell([CcText('a')]).hashCode,
        const CcTableCell([CcText('a')]).hashCode,
      );
      expect(
        const CcTableCell([CcText('a')]),
        isNot(equals(const CcTableCell([CcText('b')]))),
      );
    });
  });

  group('CcTable', () {
    const table = CcTable(
      header: [
        CcTableCell([CcText('A')]),
        CcTableCell([CcText('B')]),
      ],
      alignments: [null, CcTableAlign.right],
      rows: [
        [
          CcTableCell([CcText('1')]),
          CcTableCell([CcText('2')]),
        ],
      ],
    );

    test('exposes header/alignments/rows and nodeType', () {
      expect(table.nodeType, 'table');
      expect(table.header, hasLength(2));
      expect(table.alignments[1], CcTableAlign.right);
      expect(table.rows, hasLength(1));
      expect(table.rows.first, hasLength(2));
    });

    test('equals when header/alignments/rows match', () {
      expect(table, equals(table));
      expect(
        const CcTable(
          header: [
            CcTableCell([CcText('A')]),
            CcTableCell([CcText('B')]),
          ],
          alignments: [null, CcTableAlign.right],
          rows: [
            [
              CcTableCell([CcText('1')]),
              CcTableCell([CcText('2')]),
            ],
          ],
        ),
        equals(table),
      );
    });

    test('differs by header', () {
      expect(
        table,
        isNot(
          equals(
            const CcTable(
              header: [
                CcTableCell([CcText('Z')]),
                CcTableCell([CcText('B')]),
              ],
              alignments: [null, CcTableAlign.right],
              rows: [],
            ),
          ),
        ),
      );
    });

    test('differs by alignments', () {
      expect(
        table,
        isNot(
          equals(
            const CcTable(
              header: [
                CcTableCell([CcText('A')]),
                CcTableCell([CcText('B')]),
              ],
              alignments: [CcTableAlign.left, CcTableAlign.right],
              rows: [],
            ),
          ),
        ),
      );
    });

    test('differs by row count', () {
      expect(
        table,
        isNot(
          equals(
            const CcTable(
              header: [
                CcTableCell([CcText('A')]),
                CcTableCell([CcText('B')]),
              ],
              alignments: [null, CcTableAlign.right],
              rows: [],
            ),
          ),
        ),
      );
    });

    test('differs by a cell in an equal-length rows list', () {
      expect(
        table,
        isNot(
          equals(
            const CcTable(
              header: [
                CcTableCell([CcText('A')]),
                CcTableCell([CcText('B')]),
              ],
              alignments: [null, CcTableAlign.right],
              rows: [
                [
                  CcTableCell([CcText('X')]),
                  CcTableCell([CcText('2')]),
                ],
              ],
            ),
          ),
        ),
      );
    });

    test('hashCode agrees for equal tables', () {
      const copy = CcTable(
        header: [
          CcTableCell([CcText('A')]),
          CcTableCell([CcText('B')]),
        ],
        alignments: [null, CcTableAlign.right],
        rows: [
          [
            CcTableCell([CcText('1')]),
            CcTableCell([CcText('2')]),
          ],
        ],
      );
      expect(copy.hashCode, table.hashCode);
    });
  });

  group('CcThematicBreak', () {
    test('is a value singleton', () {
      expect(const CcThematicBreak().nodeType, 'thematic_break');
      expect(const CcThematicBreak(), equals(const CcThematicBreak()));
      expect(
        const CcThematicBreak().hashCode,
        const CcThematicBreak().hashCode,
      );
    });
  });

  group('CcHtmlBlock', () {
    test('stores raw and equals', () {
      expect(const CcHtmlBlock('<div>').raw, '<div>');
      expect(const CcHtmlBlock('<div>').nodeType, 'html_block');
      expect(const CcHtmlBlock('<div>'), equals(const CcHtmlBlock('<div>')));
      expect(
        const CcHtmlBlock('<div>'),
        isNot(equals(const CcHtmlBlock('<span>'))),
      );
      expect(
        const CcHtmlBlock('<div>').hashCode,
        const CcHtmlBlock('<div>').hashCode,
      );
    });
  });

  group('CcDetails', () {
    test('stores summary/children/open with default open=false', () {
      const details = CcDetails(
        summary: [CcText('s')],
        children: [
          CcParagraph([CcText('b')]),
        ],
      );
      expect(details.summary.single, const CcText('s'));
      expect(details.children.single, isA<CcParagraph>());
      expect(details.open, isFalse);
      expect(details.nodeType, 'details');
    });

    test('stores open=true', () {
      const details = CcDetails(summary: [], children: [], open: true);
      expect(details.open, isTrue);
    });

    test('equals when summary/children/open match', () {
      expect(
        const CcDetails(
          summary: [CcText('s')],
          children: [
            CcParagraph([CcText('b')]),
          ],
          open: true,
        ),
        const CcDetails(
          summary: [CcText('s')],
          children: [
            CcParagraph([CcText('b')]),
          ],
          open: true,
        ),
      );
    });

    test('differs by open/summary/children', () {
      const base = CcDetails(
        summary: [CcText('s')],
        children: [
          CcParagraph([CcText('b')]),
        ],
        open: true,
      );
      expect(
        base,
        isNot(
          equals(
            const CcDetails(
              summary: [CcText('s')],
              children: [
                CcParagraph([CcText('b')]),
              ],
              open: false,
            ),
          ),
        ),
      );
      expect(
        base,
        isNot(
          equals(
            const CcDetails(
              summary: [CcText('z')],
              children: [
                CcParagraph([CcText('b')]),
              ],
              open: true,
            ),
          ),
        ),
      );
      expect(
        base,
        isNot(
          equals(
            const CcDetails(
              summary: [CcText('s')],
              children: [
                CcParagraph([CcText('z')]),
              ],
              open: true,
            ),
          ),
        ),
      );
    });

    test('hashCode agrees for equal details', () {
      expect(
        const CcDetails(
          summary: [CcText('s')],
          children: [
            CcParagraph([CcText('b')]),
          ],
          open: true,
        ).hashCode,
        const CcDetails(
          summary: [CcText('s')],
          children: [
            CcParagraph([CcText('b')]),
          ],
          open: true,
        ).hashCode,
      );
    });
  });

  group('CcFootnoteDef', () {
    test('stores label/index/children and equals', () {
      const def = CcFootnoteDef(
        label: '1',
        index: 1,
        children: [
          CcParagraph([CcText('note')]),
        ],
      );
      expect(def.label, '1');
      expect(def.index, 1);
      expect(def.children.single, isA<CcParagraph>());
      expect(def.nodeType, 'footnote_def');
      expect(
        def,
        equals(
          const CcFootnoteDef(
            label: '1',
            index: 1,
            children: [
              CcParagraph([CcText('note')]),
            ],
          ),
        ),
      );
    });

    test('differs by label/index/children', () {
      const base = CcFootnoteDef(
        label: '1',
        index: 1,
        children: [
          CcParagraph([CcText('note')]),
        ],
      );
      expect(
        base,
        isNot(
          equals(
            const CcFootnoteDef(
              label: '2',
              index: 1,
              children: [
                CcParagraph([CcText('note')]),
              ],
            ),
          ),
        ),
      );
      expect(
        base,
        isNot(
          equals(
            const CcFootnoteDef(
              label: '1',
              index: 2,
              children: [
                CcParagraph([CcText('note')]),
              ],
            ),
          ),
        ),
      );
      expect(
        base,
        isNot(
          equals(
            const CcFootnoteDef(
              label: '1',
              index: 1,
              children: [
                CcParagraph([CcText('other')]),
              ],
            ),
          ),
        ),
      );
    });

    test('hashCode agrees for equal defs', () {
      expect(
        const CcFootnoteDef(
          label: '1',
          index: 1,
          children: [
            CcParagraph([CcText('note')]),
          ],
        ).hashCode,
        const CcFootnoteDef(
          label: '1',
          index: 1,
          children: [
            CcParagraph([CcText('note')]),
          ],
        ).hashCode,
      );
    });
  });

  group('CcLinkReference', () {
    test('== compares url and title', () {
      const a = CcLinkReference(url: 'https://x', title: 't');
      const b = CcLinkReference(url: 'https://x', title: 't');
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('== distinguishes by url and by title', () {
      const base = CcLinkReference(url: 'https://x', title: 't');
      expect(base, isNot(const CcLinkReference(url: 'https://y', title: 't')));
      expect(base, isNot(const CcLinkReference(url: 'https://x', title: 'u')));
      expect(base, isNot(const CcLinkReference(url: 'https://x')));
    });

    test('== is reflexive and rejects unrelated values', () {
      const a = CcLinkReference(url: 'https://x');
      expect(a == a, isTrue);
      expect(a == Object(), isFalse);
    });
  });

  group('CcDocument', () {
    test('constructs with default empty side tables', () {
      const doc = CcDocument(blocks: []);
      expect(doc.blocks, isEmpty);
      expect(doc.linkRefs, isEmpty);
      expect(doc.footnotes, isEmpty);
    });
  });
}
