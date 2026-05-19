import 'package:control_center/shared/widgets/transcript/util/grep_output_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseGrepOutput', () {
    test('parses harness search lines (path:line: content with space)', () {
      final result = parseGrepOutput(
        'lib/a.dart:12: final x = 1;\nlib/b.dart:3:  return x;',
      );
      expect(result.matches, hasLength(2));
      expect(result.matches[0].path, 'lib/a.dart');
      expect(result.matches[0].line, 12);
      expect(result.matches[0].content, 'final x = 1;');
      expect(result.matches[1].path, 'lib/b.dart');
      expect(result.fileCount, 2);
    });

    test('parses claude grep lines (path:line:content, no space)', () {
      final result = parseGrepOutput(
        'lib/l10n/app_en.arb:3448:"retry": "Retry",',
      );
      expect(result.matches.single.path, 'lib/l10n/app_en.arb');
      expect(result.matches.single.line, 3448);
      expect(result.matches.single.content, '"retry": "Retry",');
    });

    test('keeps windows drive letters in the path', () {
      final result = parseGrepOutput(r'C:\foo\bar.dart:12: hello');
      expect(result.matches.single.path, r'C:\foo\bar.dart');
      expect(result.matches.single.line, 12);
      expect(result.matches.single.content, 'hello');
    });

    test('content containing a colon-number split is not reparsed', () {
      final result = parseGrepOutput('a.dart:5: at 12:30 noon');
      expect(result.matches.single.path, 'a.dart');
      expect(result.matches.single.line, 5);
      expect(result.matches.single.content, 'at 12:30 noon');
    });

    test('files-with-matches mode yields line-less matches', () {
      final result = parseGrepOutput('lib/a.dart\nlib/b.dart');
      expect(result.matches, hasLength(2));
      expect(result.matches[0].line, isNull);
      expect(result.matches[0].content, isEmpty);
      expect(result.fileCount, 2);
    });

    test('trailing parenthesized note is kept separately', () {
      final result = parseGrepOutput(
        'a.dart:1: x\n\n(250 total matches; showing first 200)',
      );
      expect(result.matches, hasLength(1));
      expect(result.note, '(250 total matches; showing first 200)');
    });

    test('empty and no-match outputs yield no matches', () {
      expect(parseGrepOutput('').matches, isEmpty);
      expect(parseGrepOutput('   \n  ').matches, isEmpty);
      expect(parseGrepOutput('No matches for /foo/.').matches, isEmpty);
    });

    test('groups preserve first-seen file order and membership', () {
      final result = parseGrepOutput('b.dart:1: x\na.dart:2: y\nb.dart:3: z');
      final groups = result.groups;
      expect(groups.map((g) => g.path), ['b.dart', 'a.dart']);
      expect(groups[0].matches.map((m) => m.line), [1, 3]);
      expect(groups[1].matches.single.line, 2);
    });
  });
}
