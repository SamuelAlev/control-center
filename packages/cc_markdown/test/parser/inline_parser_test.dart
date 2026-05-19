import 'package:cc_markdown/cc_markdown.dart';
import 'package:flutter_test/flutter_test.dart';

/// Inline-pass coverage: drives the [CcParser] with markdown constructs whose
/// AST shape exercises the inline parser's branches — entities, autolinks,
/// images, hard breaks (backslash + trailing-space), nested emphasis, link
/// titles, strikethrough and inline HTML.
void main() {
  const parser = CcParser();

  /// Parses a single paragraph's inline children from [source].
  List<CcInlineNode> inline(String source) =>
      (parser.parse(source).single as CcParagraph).children;

  /// Concatenates the literal text of all CcText nodes in [nodes].
  String textOf(Iterable<CcInlineNode> nodes) =>
      nodes.whereType<CcText>().map((t) => t.text).join();

  group('entity decoding', () {
    test('named entities decode to their characters', () {
      final nodes = inline('a &amp; b &lt;c&gt; &quot;q&quot; &copy;');
      final text = textOf(nodes);
      expect(text, contains('&'));
      expect(text, contains('<c>'));
      expect(text, contains('"q"'));
      expect(text, contains('©'));
    });

    test('numeric and hex numeric entities decode', () {
      final nodes = inline('&#65; &#x42;');
      final text = textOf(nodes);
      expect(text, contains('A'));
      expect(text, contains('B'));
    });

    test('an unknown entity name is left literal', () {
      final nodes = inline('&nope;');
      expect(textOf(nodes), contains('&'));
    });
  });

  group('inline code spans', () {
    test('a code span captures its content verbatim', () {
      final nodes = inline('`a &amp; b`');
      final code = nodes.whereType<CcInlineCode>().single;
      expect(code.code, 'a &amp; b');
    });

    test('matching backtick counts find the span end', () {
      final nodes = inline('``a ` code``');
      expect(nodes.whereType<CcInlineCode>().single.code, 'a ` code');
    });

    test('an unterminated code span falls back to literal text', () {
      final nodes = inline('`no close');
      // No CcInlineCode produced — degrades to text.
      expect(nodes.whereType<CcInlineCode>(), isEmpty);
    });
  });

  group('emphasis and strong', () {
    test('**bold** produces a CcStrong', () {
      final nodes = inline('**bold**');
      final strong = nodes.whereType<CcStrong>().single;
      expect(textOf(strong.children), 'bold');
    });

    test('*italic* produces a CcEmphasis', () {
      final nodes = inline('*italic*');
      expect(nodes.whereType<CcEmphasis>(), hasLength(1));
    });

    test('nested **bold *and italic*** nest correctly', () {
      final nodes = inline('**outer *inner* outer**');
      final strong = nodes.whereType<CcStrong>().single;
      expect(strong.children.whereType<CcEmphasis>(), hasLength(1));
    });

    test('~~strikethrough~~ produces a CcStrikethrough', () {
      final nodes = inline('~~gone~~');
      expect(nodes.whereType<CcStrikethrough>(), hasLength(1));
    });

    test('intra-word underscores are not emphasis', () {
      final nodes = inline('foo_bar_baz');
      // No emphasis — underscores inside a word stay literal.
      expect(nodes.whereType<CcEmphasis>(), isEmpty);
    });
  });

  group('links and images', () {
    test('[t](u "title") produces a titled CcLink', () {
      final nodes = inline('[label](https://x.com "the title")');
      final link = nodes.whereType<CcLink>().single;
      expect(link.url, 'https://x.com');
      expect(link.title, 'the title');
      expect(textOf(link.children), 'label');
    });

    test('a reference link resolves against link-ref definitions', () {
      final doc = parser.parseDocument(
        '[label][ref]\n\n[ref]: https://ref.example',
      );
      final p = doc.blocks.whereType<CcParagraph>().single;
      final link = p.children.whereType<CcLink>().single;
      expect(link.url, 'https://ref.example');
    });

    test('a shortcut reference link resolves', () {
      final doc = parser.parseDocument(
        '[ref]\n\n[ref]: https://shortcut.example',
      );
      final p = doc.blocks.whereType<CcParagraph>().single;
      expect(
        p.children.whereType<CcLink>().single.url,
        'https://shortcut.example',
      );
    });

    test('![alt](url) produces a CcImage', () {
      final nodes = inline('![alt text](https://e.com/i.png)');
      final img = nodes.whereType<CcImage>().single;
      expect(img.url, 'https://e.com/i.png');
      expect(img.alt, 'alt text');
    });

    test('a bare https:// URL autolinks', () {
      final nodes = inline('see https://example.com end');
      final link = nodes.whereType<CcLink>().single;
      expect(link.url, 'https://example.com');
      expect(link.autolink, isTrue);
    });

    test('an <https://url> autolink is recognized', () {
      final nodes = inline('<https://auto.example>');
      final link = nodes.whereType<CcLink>().single;
      expect(link.url, 'https://auto.example');
    });

    test('an <email@x> autolink becomes a mailto link', () {
      final nodes = inline('<a@b.com>');
      final link = nodes.whereType<CcLink>().single;
      expect(link.url, contains('a@b.com'));
    });

    test('an inline link with an <angled> destination parses', () {
      final nodes = inline('[t](<https://e.com/a b>)');
      final link = nodes.whereType<CcLink>().single;
      expect(link.url, 'https://e.com/a b');
    });

    test('an inline link with balanced parens in the url parses', () {
      final nodes = inline('[t](https://e.com/a(b)c)');
      final link = nodes.whereType<CcLink>().single;
      expect(link.url, 'https://e.com/a(b)c');
    });

    test('an inline link with a backslash escape in the url parses', () {
      final nodes = inline(r'[t](https://e.com/a\?b)');
      final link = nodes.whereType<CcLink>().single;
      expect(link.url, 'https://e.com/a?b');
    });

    test('a malformed inline link (no destination) is not a link', () {
      final nodes = inline('[t]()');
      expect(nodes.whereType<CcLink>(), isEmpty);
    });

    test('a shortcut reference uses the label as its text', () {
      final doc = parser.parseDocument('[Word]\n\n[Word]: https://e.com');
      final p = doc.blocks.whereType<CcParagraph>().single;
      final link = p.children.whereType<CcLink>().single;
      expect(textOf(link.children), 'Word');
    });
  });

  group('line breaks', () {
    test('two trailing spaces produce a hard break', () {
      final nodes = inline('a  \nb');
      expect(nodes, contains(isA<CcHardBreak>()));
    });

    test('a backslash before a newline produces a hard break', () {
      final nodes = inline('a\\\nb');
      expect(nodes, contains(isA<CcHardBreak>()));
    });

    test('a bare newline produces a soft break', () {
      final nodes = inline('a\nb');
      expect(nodes, contains(isA<CcSoftBreak>()));
    });

    test('a backslash escapes a punctuation char literally', () {
      final nodes = inline(r'\*not bold\*');
      // Escaped asterisks do not form emphasis.
      expect(nodes.whereType<CcStrong>(), isEmpty);
      expect(nodes.whereType<CcEmphasis>(), isEmpty);
    });
  });

  group('inline HTML + raw', () {
    test('an inline HTML tag is captured as CcInlineHtml', () {
      final nodes = inline('a <b>b</b> c');
      expect(nodes.whereType<CcInlineHtml>(), isNotEmpty);
    });

    test('an HTML anchor with href parses into a CcLink', () {
      final nodes = inline(
        'see <a href="https://linear.app/x/issue/MD-309">MD-309 Handle '
        'deletion</a> end',
      );
      final link = nodes.whereType<CcLink>().single;
      expect(link.url, 'https://linear.app/x/issue/MD-309');
      expect(textOf(link.children), 'MD-309 Handle deletion');
      expect(textOf(nodes), contains('see'));
      expect(textOf(nodes), contains('end'));
    });

    test('an HTML anchor tolerates single-quoted and bare hrefs', () {
      expect(
        inline("<a href='https://a.b/c'>t</a>").whereType<CcLink>().single.url,
        'https://a.b/c',
      );
      expect(
        inline('<a href=https://a.b/d>t</a>').whereType<CcLink>().single.url,
        'https://a.b/d',
      );
    });

    test('an unclosed or href-less anchor falls back to tag tolerance', () {
      expect(inline('<a href="https://a.b">open').whereType<CcLink>(), isEmpty);
      expect(inline('<a name="x">t</a>').whereType<CcLink>(), isEmpty);
    });

    test('anchor inner markdown still parses', () {
      final link = inline(
        '<a href="https://a.b">has `code`</a>',
      ).whereType<CcLink>().single;
      expect(link.children.whereType<CcInlineCode>(), isNotEmpty);
    });
  });

  group('autolink extension toggle', () {
    test('bare www. links are off when autolinkExtension is disabled', () {
      const p = CcParser(options: CcParseOptions(autolinkExtension: false));
      final nodes =
          (p.parse('see www.example.com end').single as CcParagraph).children;
      expect(nodes.whereType<CcLink>(), isEmpty);
    });
  });
}
