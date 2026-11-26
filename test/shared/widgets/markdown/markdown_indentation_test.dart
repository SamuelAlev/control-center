import 'package:control_center/shared/widgets/markdown/markdown_indentation.dart';
import 'package:control_center/shared/widgets/markdown/paste_link_formatter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// A value from [marked] text: `|` is the caret, or a pair of them the
/// selection.
TextEditingValue _v(String marked) {
  final first = marked.indexOf('|');
  final last = marked.lastIndexOf('|');
  final text = marked.replaceAll('|', '');
  return TextEditingValue(
    text: text,
    selection: TextSelection(
      baseOffset: first,
      extentOffset: last == first ? first : last - 1,
    ),
  );
}

String _marked(TextEditingValue value) {
  final s = value.selection;
  final withEnd = value.text.replaceRange(s.end, s.end, '|');
  return s.isCollapsed ? withEnd : withEnd.replaceRange(s.start, s.start, '|');
}

String? _tab(String marked, {bool outdent = false}) {
  final next = indentMarkdownLines(_v(marked), outdent: outdent);
  return next == null ? null : _marked(next);
}

void main() {
  group('indentMarkdownLines', () {
    test('leaves Tab alone in prose', () {
      expect(_tab('hello |world'), isNull);
      expect(_tab('hello |wor|ld'), isNull);
      expect(_tab('  hello |world', outdent: true), isNull);
    });

    test('inserts a step at the caret inside a fence', () {
      expect(_tab('```ts\nfoo|\n```'), '```ts\nfoo |\n```');
      expect(_tab('```ts\n|\n```'), '```ts\n  |\n```');
      expect(_tab('```\nopen fence|'), '```\nopen fence  |');
    });

    test('keeps the fence\'s own step and its tabs', () {
      expect(
        _tab('```\nif a:\n    b\n|c\n```'),
        '```\nif a:\n    b\n    |c\n```',
      );
      expect(_tab('```\na\n\tb\n|c\n```'), '```\na\n\tb\n\t|c\n```');
      expect(_tab('```\na\n\tb\n|c\nd|\n```'), '```\na\n\tb\n|\tc\n\td|\n```');
    });

    test('indents and outdents the selected lines of a fence', () {
      expect(
        _tab('```\n|<A>\n\n  {b}|\n</A>\n```'),
        '```\n|  <A>\n\n    {b}|\n</A>\n```',
      );
      expect(
        _tab('```\n      {b|}\n    </A|>\n```', outdent: true),
        '```\n    {b|}\n  </A|>\n```',
      );
      expect(_tab('```\n\t\ta|\n```', outdent: true), '```\n\ta|\n```');
      expect(_tab('```\n a|\n   b\n```', outdent: true), '```\na|\n   b\n```');
      expect(_tab('```\na|\n```', outdent: true), isNull);
    });

    test('a selection ending at a line start leaves that line alone', () {
      expect(_tab('|a\nb\n|c'), '|  a\n  b\n|c');
    });

    test('nests a list item under the one above', () {
      expect(_tab('- a\n- b|'), '- a\n  - b|');
      expect(_tab('1. a\n2. b|'), '1. a\n   2. b|');
      expect(_tab('10. a\n- |b'), '10. a\n    - |b');
      expect(_tab('- a|'), '  - a|');
    });

    test('outdents a list item to the level above', () {
      expect(_tab('1. a\n   - b|', outdent: true), '1. a\n- b|');
      expect(_tab('- a\n  - b\n    - c|', outdent: true), '- a\n  - b\n  - c|');
      expect(_tab('- a|', outdent: true), isNull);
    });
  });

  group('PasteLinkFormatter', () {
    TextEditingValue paste(String marked, String pasted) {
      final old = _v(marked);
      final s = old.selection;
      return const PasteLinkFormatter().formatEditUpdate(
        old,
        TextEditingValue(
          text: old.text.replaceRange(s.start, s.end, pasted),
          selection: TextSelection.collapsed(offset: s.start + pasted.length),
        ),
      );
    }

    test('links the selection to a pasted URL', () {
      expect(
        _marked(paste('see |the docs| now', 'https://a.dev/x')),
        'see [the docs](https://a.dev/x)| now',
      );
      expect(
        paste('|wiki|', 'https://w.org/A_(b)').text,
        '[wiki](<https://w.org/A_(b)>)',
      );
    });

    test('pastes plainly otherwise', () {
      expect(paste('|docs|', 'not a url').text, 'not a url');
      expect(paste('|https://old.dev|', 'https://a.dev').text, 'https://a.dev');
      expect(paste('|a\nb|', 'https://a.dev').text, 'https://a.dev');
      expect(
        paste('```\n|code|\n```', 'https://a.dev').text,
        '```\nhttps://a.dev\n```',
      );
      expect(paste('a|b', 'https://a.dev').text, 'ahttps://a.devb');
    });
  });
}
