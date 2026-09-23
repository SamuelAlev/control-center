import 'package:control_center/features/messaging/presentation/ide/search_line_preview.dart';
import 'package:control_center/features/messaging/providers/repo_content_search_provider.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('leftCutAtWordBoundary', () {
    // VS Code's strings.test.ts cases for `lcut`.
    test('keeps a short string and snaps a long one to a word', () {
      expect(leftCutAtWordBoundary('foo bar', 5), 'foo bar');
      expect(leftCutAtWordBoundary('test string 0.1.2.3', 3), '2.3');
      expect(leftCutAtWordBoundary('foo bar', 0, prefix: '…'), '…');
      expect(leftCutAtWordBoundary('foo bar', 1, prefix: '…'), '…bar');
      expect(leftCutAtWordBoundary('foo bar', 3, prefix: '…'), '…bar');
      expect(leftCutAtWordBoundary('foo bar', 4, prefix: '…'), '…bar');
      expect(leftCutAtWordBoundary('foo bar', 5, prefix: '…'), 'foo bar');
      expect(
        leftCutAtWordBoundary('test string 0.1.2.3', 3, prefix: '…'),
        '…2.3',
      );
      expect(leftCutAtWordBoundary('', 10), '');
      expect(leftCutAtWordBoundary('a', 10), 'a');
      expect(leftCutAtWordBoundary(' a', 10), 'a');
      expect(leftCutAtWordBoundary(' bbbb a', 10), 'bbbb a');
      expect(leftCutAtWordBoundary('............a', 10), '............a');
      expect(leftCutAtWordBoundary('', 10, prefix: '…'), '');
      expect(leftCutAtWordBoundary('a', 10, prefix: '…'), 'a');
      expect(
        leftCutAtWordBoundary('............a', 10, prefix: '…'),
        '............a',
      );
    });
  });

  group('previewSearchLine', () {
    test('shows a short line from the start and highlights the match', () {
      final preview = previewSearchLine('  needle here', 'needle');
      expect(preview.text, 'needle here');
      expect(preview.highlights, [(start: 0, end: 6)]);
    });

    test('prefixes an ellipsis when the match sits past the lead', () {
      final preview = previewSearchLine(
        'UNIQUEPREFIX underline plus stronger text colour.',
        'colour',
      );
      expect(preview.text, '…underline plus stronger text colour.');
      final range = preview.highlights.first;
      expect(preview.text.substring(range.start, range.end), 'colour');
    });

    test('caps a boundary-less prefix so the match is not pushed off', () {
      final preview = previewSearchLine('${'x' * 80}needle', 'needle');
      expect(preview.text, startsWith('…'));
      expect(preview.text, contains('needle'));
      expect(preview.text.indexOf('needle'), lessThan(30));
    });

    test('highlights a regex group rather than the pattern text', () {
      final preview = previewSearchLine(
        'export const getUserPopupConfig = (deps) {}',
        '(deps)',
        options: const ContentSearchOptions(regex: true),
      );
      final range = preview.highlights.single;
      expect(preview.text.substring(range.start, range.end), 'deps');
    });

    test('a case-sensitive query ignores the other case', () {
      final preview = previewSearchLine(
        'foo FOO',
        'FOO',
        options: const ContentSearchOptions(caseSensitive: true),
      );
      expect(preview.highlights, [(start: 4, end: 7)]);
    });

    test('highlights every match that stays inside the window', () {
      final preview = previewSearchLine('one two one', 'one');
      expect(preview.highlights, [(start: 0, end: 3), (start: 8, end: 11)]);
    });
  });

  testWidgets('a narrow row keeps the match and drops the leading text', (
    tester,
  ) async {
    const line =
        'UNIQUEPREFIX export const getUserPopupConfig = (deps) and then '
        'a long tail that would otherwise hide the match';
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: 160,
            child: SearchMatchPreview(
              line: line,
              query: '(deps)',
              style: TextStyle(fontSize: 12),
              highlight: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );

    final rich = tester.widget<RichText>(find.byType(RichText));
    final plain = rich.text.toPlainText();
    expect(plain, startsWith('…'));
    expect(plain, contains('(deps)'));
    expect(plain, isNot(contains('UNIQUEPREFIX')));

    final end = plain.indexOf('(deps)') + '(deps)'.length;
    final painter = TextPainter(
      text: TextSpan(
        text: plain.substring(0, end),
        style: const TextStyle(fontSize: 12),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    // Room left for the overflow ellipsis the row paints after the match.
    expect(painter.width, lessThan(160));
    painter.dispose();
  });
}
