import 'package:control_center/shared/widgets/composer/composer_markdown.dart';
import 'package:flutter_test/flutter_test.dart';

typedef F = ComposerMarkdownFlag;

/// The characters of [source] whose flags include [flag], in order.
String withFlag(String source, int flag, {List<ComposerOpaqueRange>? opaque}) {
  final flags = scanComposerMarkdown(source, opaque: opaque ?? const []);
  final out = StringBuffer();
  for (var i = 0; i < source.length; i++) {
    if (flags[i] & flag != 0) {
      out.write(source[i]);
    }
  }
  return out.toString();
}

void main() {
  test('plain text carries no flags', () {
    final flags = scanComposerMarkdown('just a message, nothing marked up');
    expect(flags.every((f) => f == 0), isTrue);
  });

  group('code spans', () {
    test('mark the body and dim the backticks', () {
      const source = 'rename `WorkflowChangedEvent` please';
      expect(withFlag(source, F.code), '`WorkflowChangedEvent`');
      expect(withFlag(source, F.marker), '``');
    });

    test('an unclosed backtick stays literal while it is being typed', () {
      expect(withFlag('rename `Workflow', F.code), isEmpty);
    });

    test('pair runs of equal length only', () {
      const source = 'use ``a ` b`` here';
      expect(withFlag(source, F.code), '``a ` b``');
    });

    test('shield their contents from emphasis', () {
      const source = '`*not italic*` and *italic*';
      expect(withFlag(source, F.italic), 'italic');
    });
  });

  group('emphasis', () {
    test('bold, italic and strikethrough wait for the closing delimiter', () {
      expect(withFlag('**bold', F.bold), isEmpty);
      expect(withFlag('**bold**', F.bold), 'bold');
      expect(withFlag('a *word* here', F.italic), 'word');
      expect(withFlag('~~gone~~', F.strike), 'gone');
    });

    test('dims the delimiters', () {
      expect(withFlag('**bold** and _it_', F.marker), '****__');
    });

    test('bold delimiters are not read as two italics', () {
      expect(withFlag('**bold**', F.italic), isEmpty);
    });

    test('snake_case identifiers are not emphasis', () {
      expect(withFlag('call my_var_name now', F.italic), isEmpty);
      expect(withFlag('__init__method', F.bold), isEmpty);
    });

    test('never spans a line break', () {
      expect(withFlag('*one\ntwo*', F.italic), isEmpty);
    });
  });

  group('blocks', () {
    test('a heading dims its hashes and weights its text', () {
      const source = '## Plan';
      expect(withFlag(source, F.marker), '##');
      expect(withFlag(source, F.heading), ' Plan');
    });

    test('a list bullet is a marker, not emphasis', () {
      const source = '* first item\n- second\n12. third';
      expect(withFlag(source, F.marker), '*-12.');
      expect(withFlag(source, F.italic), isEmpty);
    });

    test('a quote dims its marker and quotes its text', () {
      const source = '> quoted';
      expect(withFlag(source, F.marker), '> ');
      expect(withFlag(source, F.quote), 'quoted');
    });

    test('a thematic break is all marker', () {
      expect(withFlag('---', F.marker), '---');
      expect(withFlag('* * *', F.marker), '* * *');
    });

    test('a fence makes every line code until it closes', () {
      const source = 'before\n```dart\nfinal *a* = 1;\n```\nafter *b*';
      expect(withFlag(source, F.block), '```dartfinal *a* = 1;```');
      expect(withFlag(source, F.italic), 'b');
    });

    test('an unclosed fence runs to the end', () {
      const source = '```\nstill code';
      expect(withFlag(source, F.block), '```still code');
    });
  });

  test('a link dims its brackets and URL', () {
    const source = 'see [the docs](https://x.dev/a_b_c) now';
    expect(withFlag(source, F.link), 'the docs');
    expect(withFlag(source, F.marker), '[](https://x.dev/a_b_c)');
    expect(withFlag(source, F.italic), isEmpty);
  });

  test('opaque ranges stay plain and break no delimiter pair', () {
    const source = 'see @[file:my_notes_v2.md] and *this*';
    const ref = (start: 4, end: 26);
    expect(withFlag(source, F.italic, opaque: [ref]), 'this');
    final flags = scanComposerMarkdown(source, opaque: [ref]);
    expect(flags.sublist(4, 26).every((f) => f == 0), isTrue);
  });
}
