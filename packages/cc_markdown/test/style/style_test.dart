import 'package:cc_markdown/cc_markdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _body = TextStyle(fontSize: 16, color: Colors.black);
const _h1 = TextStyle(fontSize: 32, fontWeight: FontWeight.bold);
const _h6 = TextStyle(fontSize: 14);

void main() {
  group('CcSoftBreakMode', () {
    test('has newline and space values, newline first', () {
      expect(CcSoftBreakMode.values.first, CcSoftBreakMode.newline);
      expect(CcSoftBreakMode.values, contains(CcSoftBreakMode.space));
    });
  });

  group('CcMarkdownStyle defaults', () {
    test('a const-default style has null text styles and sensible metrics', () {
      const style = CcMarkdownStyle();
      expect(style.paragraph, isNull);
      expect(style.h1, isNull);
      expect(style.h6, isNull);
      expect(style.code, isNull);
      expect(style.inlineCode, isNull);
      expect(style.link, isNull);
      expect(style.blockquote, isNull);
      expect(style.bold, isNull);
      expect(style.italic, isNull);
      expect(style.strikethrough, isNull);
      expect(style.listBullet, isNull);
      expect(style.tableHead, isNull);
      expect(style.tableBody, isNull);
      expect(style.checkbox, isNull);
      expect(style.horizontalRuleColor, isNull);
      expect(style.blockSpacing, 12.0);
      expect(style.listIndent, 24.0);
      expect(style.listItemGap, 4.0);
      expect(style.softBreakMode, CcSoftBreakMode.newline);
    });

    test('construction stores all fields', () {
      const style = CcMarkdownStyle(
        paragraph: _body,
        h1: _h1,
        h2: _h1,
        h3: _h1,
        h4: _h1,
        h5: _h1,
        h6: _h6,
        code: _h6,
        inlineCode: _h6,
        link: _h6,
        blockquote: _h6,
        bold: _h6,
        italic: _h6,
        strikethrough: _h6,
        listBullet: _h6,
        tableHead: _h6,
        tableBody: _h6,
        h1Padding: EdgeInsets.zero,
        h2Padding: EdgeInsets.zero,
        h3Padding: EdgeInsets.zero,
        h4Padding: EdgeInsets.zero,
        h5Padding: EdgeInsets.zero,
        h6Padding: EdgeInsets.zero,
        blockquoteDecoration: BoxDecoration(),
        blockquotePadding: EdgeInsets.zero,
        codeblockDecoration: BoxDecoration(),
        codeblockPadding: EdgeInsets.zero,
        inlineCodePadding: EdgeInsets.zero,
        inlineCodeRadius: 4,
        tableBorder: TableBorder(),
        tableHeadDecoration: BoxDecoration(),
        tableCellPadding: EdgeInsets.zero,
        horizontalRuleColor: Colors.grey,
        blockSpacing: 8,
        listIndent: 16,
        listItemGap: 2,
        checkbox: _checkbox,
        softBreakMode: CcSoftBreakMode.space,
      );
      expect(style.paragraph, _body);
      expect(style.h6, _h6);
      expect(style.inlineCodeRadius, 4);
      expect(style.horizontalRuleColor, Colors.grey);
      expect(style.blockSpacing, 8);
      expect(style.listIndent, 16);
      expect(style.listItemGap, 2);
      expect(style.checkbox, same(_checkbox));
      expect(style.softBreakMode, CcSoftBreakMode.space);
    });
  });

  group('CcMarkdownStyle.headingStyle', () {
    test('maps levels 1..6 and folds out-of-range to h6', () {
      const style = CcMarkdownStyle(h1: _h1, h6: _h6);
      expect(style.headingStyle(1), _h1);
      expect(style.headingStyle(6), _h6);
      // Out-of-range levels (7, 99, 0) all collapse to h6.
      expect(style.headingStyle(7), _h6);
      expect(style.headingStyle(99), _h6);
      expect(style.headingStyle(0), _h6);
    });
  });

  group('CcMarkdownStyle.headingPadding', () {
    test('maps levels 1..6 and folds out-of-range to h6Padding', () {
      const style = CcMarkdownStyle(
        h1Padding: EdgeInsets.all(1),
        h6Padding: EdgeInsets.all(6),
      );
      expect(style.headingPadding(1), const EdgeInsets.all(1));
      expect(style.headingPadding(6), const EdgeInsets.all(6));
      expect(style.headingPadding(7), const EdgeInsets.all(6));
      expect(style.headingPadding(0), const EdgeInsets.all(6));
    });
  });

  group('CcMarkdownStyle.copyWith', () {
    test('returns an equal style when called with no overrides', () {
      const base = CcMarkdownStyle(
        paragraph: _body,
        blockSpacing: 5,
        softBreakMode: CcSoftBreakMode.space,
      );
      final copy = base.copyWith();
      expect(copy, base);
    });

    test('replaces only the overridden field', () {
      const base = CcMarkdownStyle(paragraph: _body, blockSpacing: 5);
      final updated = base.copyWith(blockSpacing: 99);
      expect(updated.blockSpacing, 99);
      // Untouched fields carry over.
      expect(updated.paragraph, _body);
      expect(updated.softBreakMode, base.softBreakMode);
    });

    test('overrides nullable fields back from null', () {
      const base = CcMarkdownStyle();
      final withParagraph = base.copyWith(paragraph: _body);
      expect(withParagraph.paragraph, _body);
    });
  });

  group('CcMarkdownStyle equality', () {
    test('two default const styles are equal with matching hash', () {
      const a = CcMarkdownStyle();
      const b = CcMarkdownStyle();
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('a style equals an identical copyWith rebuild', () {
      const a = CcMarkdownStyle(
        paragraph: _body,
        h1: _h1,
        blockSpacing: 10,
        listIndent: 20,
        listItemGap: 3,
        softBreakMode: CcSoftBreakMode.space,
        checkbox: _checkbox,
      );
      // Build an equal style field-by-field via copyWith on a default.
      final b = const CcMarkdownStyle().copyWith(
        paragraph: _body,
        h1: _h1,
        blockSpacing: 10,
        listIndent: 20,
        listItemGap: 3,
        softBreakMode: CcSoftBreakMode.space,
        checkbox: _checkbox,
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('differs by a single numeric field', () {
      const a = CcMarkdownStyle(blockSpacing: 10);
      const b = CcMarkdownStyle(blockSpacing: 11);
      expect(a, isNot(equals(b)));
    });

    test('differs by softBreakMode', () {
      const a = CcMarkdownStyle(softBreakMode: CcSoftBreakMode.newline);
      const b = CcMarkdownStyle(softBreakMode: CcSoftBreakMode.space);
      expect(a, isNot(equals(b)));
    });

    test('differs by a TextStyle field', () {
      const a = CcMarkdownStyle(h1: _h1);
      const b = CcMarkdownStyle(h1: _h6);
      expect(a, isNot(equals(b)));
    });

    test('differs by checkbox closure identity', () {
      const a = CcMarkdownStyle(checkbox: _checkbox);
      const b = CcMarkdownStyle(checkbox: _otherCheckbox);
      expect(a, isNot(equals(b)));
    });

    test('identical instance is equal', () {
      const a = CcMarkdownStyle();
      expect(a, equals(a));
    });

    test('does not equal an unrelated type', () {
      const a = CcMarkdownStyle();
      expect(a, isNot(equals(Object())));
    });
  });
}

Widget _checkbox(bool checked) => Text('$checked');

Widget _otherCheckbox(bool checked) => Text('other:$checked');
