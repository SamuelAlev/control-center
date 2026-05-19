import 'package:cc_markdown/cc_markdown.dart';
import 'package:flutter_test/flutter_test.dart';

/// Coverage for the HTML block interpreter: the raw-HTML subset GitHub bot
/// comments emit (single-line `<table>`/`<details>` chunks, unquoted
/// attribute values, colspan, entities) must land as first-class AST nodes,
/// with the raw [CcHtmlBlock] kept as the fallback for uninterpretable
/// content.
void main() {
  const parser = CcParser();

  // The vitest coverage-report shape: everything on one line, no blank lines
  // inside — heading, summary table, a <details> wrapping a file table, and
  // an <em> footer with an unquoted href.
  const coverageReport =
      '<h2>Coverage Report</h2>\n'
      '<table> <thead> <tr> <th align="center">Status</th> '
      '<th align="left">Category</th> <th align="right">Percentage</th> '
      '</tr> </thead> <tbody> <tr> <td align="center">🔵</td> '
      '<td align="left">Lines</td> '
      '<td align="right">28.97%<br/>⬆️ <em>+2.20%</em></td> </tr> '
      '</tbody> </table>'
      '<details><summary>File Coverage</summary>'
      '<table> <thead> <tr> <th align="left">File</th> '
      '<th align="right">Stmts</th> </tr> </thead> <tbody> '
      '<tr> <td align="left" colspan="2"><b>Changed Files</b></td> </tr> '
      '<tr> <td align="left"><a href="https://github.com/x/y/blob/c0ffee/app/server.ts">app/server.ts</a></td> '
      '<td align="right">0%</td> </tr> '
      '</tbody> </table></details>\n'
      '<em>Generated in workflow <a href=https://github.com/x/y/actions/runs/1>#5</a></em>';

  group('coverage-report bot comment', () {
    test('parses into heading, table, details, and footer paragraph', () {
      final blocks = parser.parse(coverageReport);
      expect(blocks.whereType<CcHtmlBlock>(), isEmpty);
      final heading = blocks.whereType<CcHeading>().single;
      expect(heading.level, 2);
      expect(
        heading.children.whereType<CcText>().single.text,
        'Coverage Report',
      );
      expect(blocks.whereType<CcTable>(), hasLength(1));
      expect(blocks.whereType<CcDetails>(), hasLength(1));
      expect(blocks.whereType<CcParagraph>(), hasLength(1));
    });

    test('the summary table keeps columns, alignment, and cell content', () {
      final table = parser.parse(coverageReport).whereType<CcTable>().single;
      expect(table.header, hasLength(3));
      expect(table.header.map((c) => (c.children.single as CcText).text), [
        'Status',
        'Category',
        'Percentage',
      ]);
      expect(table.alignments, [
        CcTableAlign.center,
        CcTableAlign.left,
        CcTableAlign.right,
      ]);
      final percentage = table.rows.single[2].children;
      expect(percentage.whereType<CcHardBreak>(), hasLength(1));
      final em = percentage.whereType<CcEmphasis>().single;
      expect((em.children.single as CcText).text, '+2.20%');
    });

    test('the details block carries its summary and the file table', () {
      final details = parser
          .parse(coverageReport)
          .whereType<CcDetails>()
          .single;
      expect(details.summary.whereType<CcText>().single.text, 'File Coverage');
      final table = details.children.whereType<CcTable>().single;
      // The colspan="2" row pads to full width, keeping its bold cell, and
      // carries the span so the renderer can merge the cells visually.
      final spanned = table.rows.first;
      expect(spanned, hasLength(2));
      expect(spanned.first.span, 2);
      final bold = spanned.first.children.whereType<CcStrong>().single;
      expect((bold.children.single as CcText).text, 'Changed Files');
      expect(spanned.last.children, isEmpty);
      expect(spanned.last.span, 1);
      // The file row's anchor survives as a tappable link.
      final link = table.rows[1].first.children.whereType<CcLink>().single;
      expect(link.url, 'https://github.com/x/y/blob/c0ffee/app/server.ts');
    });

    test('the footer emphasis keeps its unquoted-href anchor', () {
      final footer = parser
          .parse(coverageReport)
          .whereType<CcParagraph>()
          .single;
      final em = footer.children.whereType<CcEmphasis>().single;
      final link = em.children.whereType<CcLink>().single;
      expect(link.url, 'https://github.com/x/y/actions/runs/1');
      expect((link.children.single as CcText).text, '#5');
    });
  });

  group('structure tolerance', () {
    test('implicit </td>/</tr> closes parse sloppy table markup', () {
      final blocks = parser.parse(
        '<table><tr><th>a<th>b<tr><td>1<td>2</table>',
      );
      final table = blocks.whereType<CcTable>().single;
      expect(table.header, hasLength(2));
      expect((table.rows.single[1].children.single as CcText).text, '2');
    });

    test('a headerless table promotes its first row to the header', () {
      final table = parser
          .parse(
            '<table><tr><td>x</td><td>y</td></tr><tr><td>1</td><td>2</td></tr></table>',
          )
          .whereType<CcTable>()
          .single;
      expect((table.header.first.children.single as CcText).text, 'x');
      expect(table.rows, hasLength(1));
    });

    test('nested details interpret recursively', () {
      final blocks = parser.parse(
        '<details open><summary>Outer</summary>'
        '<details><summary>Inner</summary><p>Body</p></details>'
        '</details>',
      );
      final outer = blocks.whereType<CcDetails>().single;
      expect(outer.open, isTrue);
      final inner = outer.children.whereType<CcDetails>().single;
      expect(inner.open, isFalse);
      expect(inner.summary.whereType<CcText>().single.text, 'Inner');
    });

    test('lists, blockquotes, and hr interpret into their nodes', () {
      final blocks = parser.parse(
        '<blockquote><p>quoted</p></blockquote>'
        '<ol start="3"><li>one</li><li>two</li></ol>'
        '<hr/>'
        '<ul><li>bullet</li></ul>',
      );
      final quote = blocks.whereType<CcBlockquote>().single;
      expect(quote.children, hasLength(1));
      final lists = blocks.whereType<CcList>().toList();
      expect(lists.first.ordered, isTrue);
      expect(lists.first.start, 3);
      expect(lists.first.items, hasLength(2));
      expect(lists.last.ordered, isFalse);
      expect(blocks.whereType<CcThematicBreak>(), hasLength(1));
    });

    test('<pre><code class="language-x"> keeps language and whitespace', () {
      final blocks = parser.parse(
        '<pre><code class="language-dart">void main() {\n'
        '  print(1 &lt; 2);\n'
        '}</code></pre>',
      );
      final code = blocks.whereType<CcCodeBlock>().single;
      expect(code.language, 'dart');
      expect(code.code, 'void main() {\n  print(1 < 2);\n}');
    });

    test('entities decode in text, script content is dropped', () {
      final blocks = parser.parse(
        '<div><script>evil()</script><p>a &amp; b &#x2191;</p></div>',
      );
      final para = blocks.whereType<CcParagraph>().single;
      expect((para.children.single as CcText).text, 'a & b ↑');
    });

    test('multi-line hand-written HTML tables interpret too', () {
      final blocks = parser.parse(
        '<table>\n<tr>\n<th>k</th>\n<th>v</th>\n</tr>\n<tr>\n<td>a</td>\n<td>1</td>\n</tr>\n</table>',
      );
      expect(blocks.whereType<CcTable>().single.rows, hasLength(1));
    });
  });

  group('fallback', () {
    test('an uninterpretable chunk stays a raw CcHtmlBlock', () {
      final blocks = parser.parse('<div></div>');
      expect(blocks.whereType<CcHtmlBlock>(), hasLength(1));
    });

    test('the htmlBlocks toggle disables interpretation', () {
      const p = CcParser(options: CcParseOptions(htmlBlocks: false));
      final blocks = p.parse(coverageReport);
      expect(blocks.whereType<CcTable>(), isEmpty);
      expect(blocks.whereType<CcHtmlBlock>(), isNotEmpty);
    });

    test('markdown around an HTML block is unaffected', () {
      final blocks = parser.parse(
        'Before **bold**.\n\n<table><tr><th>h</th></tr><tr><td>1</td></tr></table>\n\nAfter.',
      );
      expect(blocks.whereType<CcParagraph>(), hasLength(2));
      expect(blocks.whereType<CcTable>(), hasLength(1));
    });
  });
}
