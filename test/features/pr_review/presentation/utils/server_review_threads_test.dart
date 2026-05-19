import 'package:cc_domain/features/pr_review/domain/entities/pr_code_review_comment.dart';
import 'package:control_center/features/pr_review/presentation/utils/server_review_threads.dart';
import 'package:flutter_test/flutter_test.dart';

PrCodeReviewComment _c(
  int id, {
  int? inReplyTo,
  int? line,
  int? startLine,
  int? reviewId,
  String path = 'lib/a.dart',
  int hour = 0,
  bool resolved = false,
  String? threadId,
}) => PrCodeReviewComment(
  id: id,
  body: 'body $id',
  user: null,
  path: path,
  position: line,
  createdAt: DateTime.utc(2026, 1, 1, hour),
  inReplyToId: inReplyTo,
  startLine: startLine,
  line: line,
  reviewId: reviewId,
  threadId: threadId,
  isResolved: resolved,
);

void main() {
  group('groupServerReviewThreads', () {
    test('a reply joins the conversation it answers', () {
      final threads = groupServerReviewThreads([
        _c(1, line: 10, hour: 1),
        _c(2, inReplyTo: 1, line: 10, hour: 2),
        _c(3, inReplyTo: 1, line: 10, hour: 3),
      ]);

      expect(threads, hasLength(1));
      expect(threads.single.comments.map((c) => c.id), [1, 2, 3]);
      expect(threads.single.root.id, 1);
    });

    test('separate roots are separate conversations', () {
      final threads = groupServerReviewThreads([
        _c(1, line: 10, hour: 1),
        _c(5, line: 20, hour: 2),
        _c(2, inReplyTo: 1, line: 10, hour: 3),
      ]);

      expect(threads.map((t) => t.root.id), [1, 5]);
      expect(threads.first.comments, hasLength(2));
      expect(threads.last.comments, hasLength(1));
    });

    test('comments are ordered oldest first regardless of input order', () {
      final threads = groupServerReviewThreads([
        _c(3, inReplyTo: 1, line: 10, hour: 5),
        _c(1, line: 10, hour: 1),
        _c(2, inReplyTo: 1, line: 10, hour: 3),
      ]);

      expect(threads.single.comments.map((c) => c.id), [1, 2, 3]);
    });

    test('a reply whose parent is not in the page is kept, not dropped', () {
      // The parent lives outside the fetched page. Showing the reply detached
      // beats losing someone's words entirely.
      final threads = groupServerReviewThreads([
        _c(9, inReplyTo: 404, line: 1),
      ]);

      expect(threads, hasLength(1));
      expect(threads.single.root.id, 9);
    });

    test('the conversation reports the ROOT review, not a reply\'s', () {
      // A reply is submitted with its own later review; keying off it would
      // scatter one discussion across several timeline entries.
      final threads = groupServerReviewThreads([
        _c(1, line: 10, hour: 1, reviewId: 100),
        _c(2, inReplyTo: 1, line: 10, hour: 2, reviewId: 200),
      ]);

      expect(threads.single.reviewId, 100);
    });

    test('range, resolution and thread id come off the root', () {
      final threads = groupServerReviewThreads([
        _c(1, line: 19, startLine: 13, hour: 1, resolved: true, threadId: 'T1'),
        // A reply carries the anchor without the range and is never resolved
        // itself — reading either off it would lose the range and reopen a
        // settled conversation.
        _c(2, inReplyTo: 1, line: 19, hour: 2),
      ]);

      final t = threads.single;
      expect(t.startLine, 13);
      expect(t.endLine, 19);
      expect(t.isMultiLine, isTrue);
      expect(t.isResolved, isTrue);
      expect(t.threadId, 'T1');
      expect(t.isOutdated, isFalse);
    });

    test('a comment with no anchor line is outdated', () {
      final threads = groupServerReviewThreads([_c(1)]);

      expect(threads.single.isOutdated, isTrue);
      expect(threads.single.endLine, isNull);
    });

    test('the id matches the diff\'s synthesised thread id', () {
      // Both surfaces key per-thread UI state (collapsed, focused) by this.
      expect(
        groupServerReviewThreads([_c(4242, line: 1)]).single.id,
        'server-4242',
      );
    });

    test('an empty list yields no conversations', () {
      expect(groupServerReviewThreads(const []), isEmpty);
    });
  });

  group('serverReviewRepliesByReview', () {
    test('a reply is attributed to the review it was SUBMITTED with', () {
      // Its conversation belongs to review 100, so review 200's timeline entry
      // would otherwise be a bare "reviewed" row with the words nowhere.
      final threads = groupServerReviewThreads([
        _c(1, line: 10, hour: 1, reviewId: 100),
        _c(2, inReplyTo: 1, line: 10, hour: 2, reviewId: 200),
      ]);

      final byReview = serverReviewRepliesByReview(threads);

      expect(byReview.keys, [200]);
      expect(byReview[200]!.single.comment.id, 2);
      expect(byReview[200]!.single.thread.id, 'server-1');
    });

    test('a reply from the conversation\'s OWN review is not duplicated', () {
      // That entry already renders the whole thread underneath it.
      final threads = groupServerReviewThreads([
        _c(1, line: 10, hour: 1, reviewId: 100),
        _c(2, inReplyTo: 1, line: 10, hour: 2, reviewId: 100),
      ]);

      expect(serverReviewRepliesByReview(threads), isEmpty);
    });

    test('roots are never reply references', () {
      final threads = groupServerReviewThreads([
        _c(1, line: 10, hour: 1, reviewId: 100),
      ]);

      expect(serverReviewRepliesByReview(threads), isEmpty);
    });

    test('a reply with no review id is skipped', () {
      final threads = groupServerReviewThreads([
        _c(1, line: 10, hour: 1, reviewId: 100),
        _c(2, inReplyTo: 1, line: 10, hour: 2),
      ]);

      expect(serverReviewRepliesByReview(threads), isEmpty);
    });
  });

  group('inlineThreadFromServerThread', () {
    test('carries the range, state and every comment as an entry', () {
      final thread = groupServerReviewThreads([
        _c(1, line: 19, startLine: 13, hour: 1, threadId: 'T1'),
        _c(2, inReplyTo: 1, line: 19, hour: 2),
      ]).single;

      final inline = inlineThreadFromServerThread(
        thread,
        unknownAuthorLabel: 'unknown',
        resolved: true,
      );

      expect(inline.id, 'server-1');
      expect(inline.line, 13);
      expect(inline.lineEnd, 19);
      expect(inline.isMultiLine, isTrue);
      expect(inline.resolved, isTrue);
      expect(inline.threadId, 'T1');
      expect(inline.serverId, 1);
      expect(inline.entries.map((e) => e.body), ['body 1', 'body 2']);
      expect(inline.entries.first.author, 'unknown');
    });

    test('the original code comes from the forge hunk when not supplied', () {
      // This is what makes a ```suggestion render outside the diff: the hunk
      // is the snapshot the comment was written against, so it still holds the
      // code even after the line changed. Without it the mini-diff had nothing
      // to diff against and drew a header over an empty box.
      final thread = groupServerReviewThreads([
        PrCodeReviewComment(
          id: 1,
          body: '```suggestion\n```',
          user: null,
          path: 'lib/a.dart',
          position: 39,
          line: 39,
          startLine: 38,
          createdAt: DateTime.utc(2026),
          diffHunk:
              '@@ -35,3 +37,3 @@\n'
              ' unchanged context\n'
              '+first commented line\n'
              '+second commented line',
        ),
      ]).single;

      final inline = inlineThreadFromServerThread(
        thread,
        unknownAuthorLabel: 'unknown',
        resolved: false,
      );

      expect(
        inline.originalCode,
        'first commented line\nsecond commented line',
      );
    });

    test('an explicit original code wins over the hunk', () {
      final thread = groupServerReviewThreads([
        PrCodeReviewComment(
          id: 1,
          body: 'x',
          user: null,
          path: 'lib/a.dart',
          position: 39,
          line: 39,
          createdAt: DateTime.utc(2026),
          diffHunk: '@@ -35,1 +39,1 @@\n+from the hunk',
        ),
      ]).single;

      // The diff reads the LIVE rows, which carry any context the reader
      // expanded — richer than the frozen hunk.
      expect(
        inlineThreadFromServerThread(
          thread,
          unknownAuthorLabel: 'unknown',
          resolved: false,
          originalCode: 'from the rendered rows',
        ).originalCode,
        'from the rendered rows',
      );
    });

    test('an outdated conversation still builds a renderable thread', () {
      final thread = groupServerReviewThreads([_c(1)]).single;

      final inline = inlineThreadFromServerThread(
        thread,
        unknownAuthorLabel: 'unknown',
        resolved: false,
      );

      // No anchor to speak of, but the conversation must still render — the
      // timeline is the only place it can be read.
      expect(inline.entries, hasLength(1));
      expect(inline.line, 0);
      expect(inline.lineEnd, 0);
    });
  });
}
