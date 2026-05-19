import 'package:cc_markdown/cc_markdown.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const parser = CcParser();

  test('kitchen sink parses to the expected shapes', () {
    final doc = parser.parseDocument('''
# Title

Some **bold** and *italic* and `code` and ~~gone~~ text.

- one
- two [x] not a task
- [x] done task

1. first
2. second

> quoted **deep**

```dart
void main() {}
```

| a | b |
|---|--:|
| 1 | 2 |

[link](https://example.com "t") and <https://auto.dev> and https://bare.dev/x.

---

<details open>
<summary>More **info**</summary>

Hidden paragraph.

</details>

Footnote here[^1].

[^1]: The note.
''');

    final blocks = doc.blocks;
    expect(blocks[0], isA<CcHeading>());
    expect((blocks[0] as CcHeading).level, 1);

    final p1 = blocks[1] as CcParagraph;
    expect(p1.children.whereType<CcStrong>(), hasLength(1));
    expect(p1.children.whereType<CcEmphasis>(), hasLength(1));
    expect(p1.children.whereType<CcInlineCode>(), hasLength(1));
    expect(p1.children.whereType<CcStrikethrough>(), hasLength(1));

    final ul = blocks[2] as CcList;
    expect(ul.ordered, isFalse);
    expect(ul.items, hasLength(3));
    expect(ul.items[0].checked, isNull);
    expect(ul.items[2].checked, isTrue);

    final ol = blocks[3] as CcList;
    expect(ol.ordered, isTrue);
    expect(ol.start, 1);

    final quote = blocks[4] as CcBlockquote;
    expect(quote.children.single, isA<CcParagraph>());

    final code = blocks[5] as CcCodeBlock;
    expect(code.language, 'dart');
    expect(code.code, 'void main() {}');
    expect(code.closed, isTrue);

    final table = blocks[6] as CcTable;
    expect(table.header, hasLength(2));
    expect(table.alignments[1], CcTableAlign.right);
    expect(table.rows, hasLength(1));

    final links = blocks[7] as CcParagraph;
    final linkNodes = links.children.whereType<CcLink>().toList();
    expect(linkNodes, hasLength(3));
    expect(linkNodes[0].url, 'https://example.com');
    expect(linkNodes[0].title, 't');
    expect(linkNodes[0].autolink, isFalse);
    expect(linkNodes[1].autolink, isTrue);
    expect(linkNodes[2].url, 'https://bare.dev/x');

    expect(blocks[8], isA<CcThematicBreak>());

    final details = blocks[9] as CcDetails;
    expect(details.open, isTrue);
    expect(details.summary.whereType<CcStrong>(), hasLength(1));
    expect(details.children.single, isA<CcParagraph>());

    final fn = blocks[10] as CcParagraph;
    expect(fn.children.whereType<CcFootnoteRef>().single.index, 1);
    expect(doc.footnotes.single.label, '1');
  });

  test('emphasis pairing follows CommonMark', () {
    List<CcInlineNode> inline(String text) =>
        (parser.parse(text).single as CcParagraph).children;

    // ***a*** = <em><strong>a</strong></em> per CommonMark.
    final triple = inline('***a***');
    final em = triple.whereType<CcEmphasis>().single;
    expect(em.children.whereType<CcStrong>(), hasLength(1));

    // Intraword underscore does not emphasize.
    final intraword = inline('snake_case_name');
    expect(intraword.whereType<CcEmphasis>(), isEmpty);
    // Intraword asterisk does.
    final star = inline('a*b*c');
    expect(star.whereType<CcEmphasis>(), hasLength(1));

    // Unmatched delimiters stay literal.
    final unmatched = inline('a ** b');
    expect(unmatched.whereType<CcStrong>(), isEmpty);
    expect((unmatched.first as CcText).text, contains('**'));

    // foo**bar**baz → strong pairs intraword for *.
    final mid = inline('foo**bar**baz');
    expect(mid.whereType<CcStrong>(), hasLength(1));
  });

  test('setext headings and lazy continuation', () {
    final doc = parser.parse('Title\n===\n\n> quote\nlazy line\n');
    expect((doc[0] as CcHeading).level, 1);
    final quote = doc[1] as CcBlockquote;
    final text = (quote.children.single as CcParagraph).children
        .whereType<CcText>()
        .map((t) => t.text)
        .join();
    expect(text, contains('quote'));
    expect(text, contains('lazy line'));
  });

  test('link reference definitions resolve regardless of position', () {
    final doc = parser.parse('See [docs][d].\n\n[d]: https://docs.dev\n');
    final p = doc.single as CcParagraph;
    final link = p.children.whereType<CcLink>().single;
    expect(link.url, 'https://docs.dev');
  });

  test('unclosed streaming fence stays open', () {
    final doc = parser.parse('```py\nprint(1)\n');
    final code = doc.single as CcCodeBlock;
    expect(code.closed, isFalse);
    expect(code.language, 'py');
  });

  test('never throws on hostile input', () {
    const hostile = '[[[[**~~`\n>>>\n- [ \n|||\n<details>\n\$\\\x00';
    expect(() => parser.parse(hostile), returnsNormally);
    expect(() => parser.parse(''), returnsNormally);
    expect(() => parser.parse('*' * 5000), returnsNormally);
  });
}
