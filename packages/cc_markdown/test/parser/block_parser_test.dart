import 'package:cc_markdown/cc_markdown.dart';
import 'package:flutter_test/flutter_test.dart';

/// Block-pass coverage: drives the [CcParser] with block constructs whose AST
/// shape exercises block-parser branches — setext headings, indented code,
/// fenced code with language/info strings, nested blockquotes/lists, thematic
/// breaks, HTML blocks, details and feature toggles.
void main() {
  const parser = CcParser();

  group('setext headings', () {
    test('an === underline makes a level-1 setext heading', () {
      final blocks = parser.parse('Title\n===');
      final h = blocks.whereType<CcHeading>().single;
      expect(h.level, 1);
      expect(h.children.whereType<CcText>(), isNotEmpty);
    });

    test('a --- underline makes a level-2 setext heading', () {
      final blocks = parser.parse('Sub\n---');
      expect(blocks.whereType<CcHeading>().single.level, 2);
    });

    test('setext headings are off when the toggle is disabled', () {
      const p = CcParser(options: CcParseOptions(setextHeadings: false));
      final blocks = p.parse('Title\n===');
      // Without setext, this is a paragraph (not a heading).
      expect(blocks.whereType<CcHeading>(), isEmpty);
    });
  });

  group('indented code blocks', () {
    test('a 4-space indent makes a code block', () {
      final blocks = parser.parse('    code here');
      final cb = blocks.whereType<CcCodeBlock>().single;
      expect(cb.fenced, isFalse);
      expect(cb.code, 'code here');
    });

    test('indented code is off when the toggle is disabled', () {
      const p = CcParser(options: CcParseOptions(indentedCode: false));
      final blocks = p.parse('    code here');
      expect(blocks.whereType<CcCodeBlock>(), isEmpty);
    });
  });

  group('fenced code blocks', () {
    test('a fenced block captures language and code', () {
      final blocks = parser.parse('```dart\nhello\n```');
      final cb = blocks.whereType<CcCodeBlock>().single;
      expect(cb.fenced, isTrue);
      expect(cb.language, 'dart');
      expect(cb.code, contains('hello'));
      expect(cb.closed, isTrue);
    });

    test('a tilde-fenced block is recognized', () {
      final blocks = parser.parse('~~~\nbody\n~~~');
      final cb = blocks.whereType<CcCodeBlock>().single;
      expect(cb.fenced, isTrue);
      expect(cb.code, contains('body'));
    });
  });

  group('mermaid fences', () {
    test('a closed mermaid fence becomes a diagram node', () {
      final blocks = parser.parse('```mermaid\nflowchart TD\n  A --> B\n```');
      final diagram = blocks.whereType<CcMermaid>().single;
      expect(diagram.source, 'flowchart TD\n  A --> B');
      expect(blocks.whereType<CcCodeBlock>(), isEmpty);
    });

    test('the info string is matched case-insensitively', () {
      final blocks = parser.parse('```Mermaid\ngraph TD\n  A --> B\n```');
      expect(blocks.whereType<CcMermaid>(), hasLength(1));
    });

    test('an UNCLOSED fence stays a code block while it streams', () {
      final blocks = parser.parse('```mermaid\nflowchart TD\n  A --> B');
      expect(blocks.whereType<CcMermaid>(), isEmpty);
      final cb = blocks.whereType<CcCodeBlock>().single;
      expect(cb.closed, isFalse);
      expect(cb.language, 'mermaid');
    });

    test('an empty mermaid fence stays a code block', () {
      final blocks = parser.parse('```mermaid\n\n```');
      expect(blocks.whereType<CcMermaid>(), isEmpty);
      expect(blocks.whereType<CcCodeBlock>(), hasLength(1));
    });

    test('the mermaid toggle keeps the fence as code when off', () {
      const p = CcParser(options: CcParseOptions(mermaid: false));
      final blocks = p.parse('```mermaid\nflowchart TD\n  A --> B\n```');
      expect(blocks.whereType<CcMermaid>(), isEmpty);
      expect(blocks.whereType<CcCodeBlock>().single.language, 'mermaid');
    });

    test('a diagram inside a list item survives container parsing', () {
      final blocks = parser.parse(
        '- item\n\n  ```mermaid\n  graph TD\n  A-->B\n  ```',
      );
      final list = blocks.whereType<CcList>().single;
      expect(list.items.first.children.whereType<CcMermaid>(), hasLength(1));
    });

    test('mermaid nodes are value-equal (the memoization lever)', () {
      const a = CcMermaid('flowchart TD\n A --> B');
      const b = CcMermaid('flowchart TD\n A --> B');
      const c = CcMermaid('flowchart LR\n A --> B');
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
      expect(a.nodeType, 'mermaid');
    });
  });

  group('lists', () {
    test('a nested list renders nested CcList items', () {
      final blocks = parser.parse('- one\n  - nested');
      final list = blocks.whereType<CcList>().single;
      expect(list.items, hasLength(1));
      expect(list.items.first.children.whereType<CcList>(), hasLength(1));
    });

    test('an ordered list starts at a custom start number', () {
      final blocks = parser.parse('3. three\n4. four');
      final list = blocks.whereType<CcList>().single;
      expect(list.ordered, isTrue);
      expect(list.start, 3);
    });

    test('a loose list (blank line between items) is not tight', () {
      final blocks = parser.parse('- one\n\n- two');
      final list = blocks.whereType<CcList>().single;
      expect(list.tight, isFalse);
    });

    test('a tight list has tight=true', () {
      final blocks = parser.parse('- one\n- two');
      expect(blocks.whereType<CcList>().single.tight, isTrue);
    });
  });

  group('blockquotes', () {
    test('a nested blockquote carries its children', () {
      final blocks = parser.parse('> outer\n> > inner');
      final bq = blocks.whereType<CcBlockquote>().single;
      expect(bq.children, isNotEmpty);
    });
  });

  group('misc constructs', () {
    test('a thematic break produces CcThematicBreak', () {
      final blocks = parser.parse('---');
      expect(blocks.whereType<CcThematicBreak>(), hasLength(1));
    });

    test('an ATX heading with closing hashes is parsed', () {
      final blocks = parser.parse('## Title ##');
      expect(blocks.whereType<CcHeading>().single.level, 2);
    });

    test('a details block carries summary and body children', () {
      final blocks = parser.parse(
        '<details>\n<summary>S</summary>\n\nBody.\n\n</details>',
      );
      final details = blocks.whereType<CcDetails>().single;
      expect(details.children, isNotEmpty);
    });

    test('a details block is open when the open attribute is present', () {
      final blocks = parser.parse(
        '<details open>\n<summary>S</summary>\n\nBody.\n\n</details>',
      );
      expect(blocks.whereType<CcDetails>().single.open, isTrue);
    });

    test('an HTML block is interpreted into first-class nodes', () {
      final blocks = parser.parse('<div>\nraw html\n</div>');
      final para = blocks.whereType<CcParagraph>().single;
      expect(para.children.whereType<CcText>().single.text, 'raw html');
    });

    test('an HTML block stays a raw CcHtmlBlock when the toggle is off', () {
      const p = CcParser(options: CcParseOptions(htmlBlocks: false));
      final blocks = p.parse('<div>\nraw html\n</div>');
      expect(blocks.whereType<CcHtmlBlock>(), isNotEmpty);
    });

    test('a footnote definition is parsed into the document side table', () {
      final doc = parser.parseDocument('Text[^1].\n\n[^1]: The note.');
      expect(doc.footnotes, hasLength(1));
      expect(doc.footnotes.single.label, '1');
      expect(doc.footnotes.single.index, 1);
    });
  });

  group('feature toggles', () {
    test('tables off yields no CcTable', () {
      const p = CcParser(options: CcParseOptions(tables: false));
      final blocks = p.parse('| a | b |\n|---|---|\n| 1 | 2 |');
      expect(blocks.whereType<CcTable>(), isEmpty);
    });

    test('footnotes off treats [^1] as plain text', () {
      const p = CcParser(options: CcParseOptions(footnotes: false));
      final doc = p.parseDocument('[^1]: note');
      expect(doc.footnotes, isEmpty);
    });

    test('strikethrough off treats ~~x~~ as plain text', () {
      const p = CcParser(options: CcParseOptions(strikethrough: false));
      final para = p.parse('~~gone~~').whereType<CcParagraph>().single;
      expect(para.children.whereType<CcStrikethrough>(), isEmpty);
    });
  });

  group('nesting cap', () {
    test('deeply nested blockquotes degrade past maxBlockDepth', () {
      // 40 levels of nesting — past the 32 cap; the parser must not throw.
      final src = '${List.filled(40, '> ').join()}deep';
      final blocks = parser.parse(src);
      expect(blocks, isNotEmpty);
    });
  });
}
