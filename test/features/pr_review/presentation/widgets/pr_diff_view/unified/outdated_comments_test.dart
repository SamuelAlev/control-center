import 'package:cc_domain/features/pr_review/domain/entities/pr_code_review_comment.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_user.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view/unified/outdated_comments.dart';
import 'package:flutter_test/flutter_test.dart';

PrCodeReviewComment _comment({
  required int id,
  required String path,
  int? line,
  int? originalLine,
  String side = 'RIGHT',
  String body = 'body',
  String diffHunk = '',
}) => PrCodeReviewComment(
  id: id,
  body: body,
  user: const PrUser(login: 'octocat', avatarUrl: ''),
  path: path,
  position: null,
  createdAt: DateTime(2024, 1, 1),
  side: side,
  line: line,
  originalLine: originalLine,
  diffHunk: diffHunk,
);

void main() {
  group('partitionServerCommentsForFile', () {
    test(
      'a comment with a null anchorLine is surfaced as outdated, not dropped',
      () {
        // No line and no originalLine => anchorLine == null.
        final outdated = _comment(
          id: 1,
          path: 'lib/main.dart',
          diffHunk: '@@ -1 +1 @@\n-old\n+new',
        );
        expect(outdated.anchorLine, isNull, reason: 'precondition');

        final result = partitionServerCommentsForFile([
          outdated,
        ], 'lib/main.dart');

        expect(
          result.anchored,
          isEmpty,
          reason: 'an unanchorable comment must not be placed on a live row',
        );
        expect(
          result.outdated,
          hasLength(1),
          reason: 'it must be collected into the outdated bucket, not dropped',
        );
        expect(result.outdated.single.id, 1);
        expect(result.outdated.single.diffHunk, isNotEmpty);
      },
    );

    test('a comment with a live line is anchored by "<side>-<line>"', () {
      final anchored = _comment(id: 2, path: 'lib/main.dart', line: 42);

      final result = partitionServerCommentsForFile([
        anchored,
      ], 'lib/main.dart');

      expect(result.outdated, isEmpty);
      expect(result.anchored.keys, contains('RIGHT-42'));
      expect(result.anchored['RIGHT-42'], hasLength(1));
    });

    test('falls back to originalLine for the anchor when line is null', () {
      final anchored = _comment(
        id: 3,
        path: 'lib/main.dart',
        originalLine: 7,
        side: 'LEFT',
      );

      final result = partitionServerCommentsForFile([
        anchored,
      ], 'lib/main.dart');

      expect(result.outdated, isEmpty);
      expect(result.anchored.keys, contains('LEFT-7'));
    });

    test('splits a mixed list and ignores other files', () {
      final comments = [
        _comment(id: 1, path: 'a.dart', line: 10),
        _comment(id: 2, path: 'a.dart'), // outdated (null anchor)
        _comment(id: 3, path: 'a.dart', line: 10), // same anchor as id 1
        _comment(id: 4, path: 'b.dart', line: 5), // other file, excluded
        _comment(id: 5, path: 'b.dart'), // other file, excluded
      ];

      final result = partitionServerCommentsForFile(comments, 'a.dart');

      expect(result.outdated.map((c) => c.id), [2]);
      expect(result.anchored['RIGHT-10']!.map((c) => c.id), [1, 3]);
      expect(
        result.anchored.values.expand((e) => e).any((c) => c.path == 'b.dart'),
        isFalse,
      );
    });
  });
}
