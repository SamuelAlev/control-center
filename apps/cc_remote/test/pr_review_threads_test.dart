@TestOn('browser')
library;

import 'package:cc_domain/features/pr_review/domain/entities/pr_code_review_comment.dart';
import 'package:cc_remote/widgets/pr_detail/pr_review_threads.dart';
import 'package:flutter_test/flutter_test.dart';

PrCodeReviewComment comment(
  int id, {
  int? replyTo,
  String? threadId,
  int minute = 0,
}) => PrCodeReviewComment(
  id: id,
  body: 'Comment $id',
  user: null,
  path: 'src/example.dart',
  position: null,
  createdAt: DateTime.utc(2026, 1, 1, 0, minute),
  inReplyToId: replyTo,
  threadId: threadId,
);

void main() {
  test(
    'groups replies with their root and orders entire thread chronologically',
    () {
      final threads = groupReviewThreads([
        comment(13, replyTo: 12, minute: 3),
        comment(20, minute: 2),
        comment(11, minute: 0),
        comment(12, replyTo: 11, minute: 1),
      ]);
      expect(threads, hasLength(2));
      expect(threads.first.map((c) => c.id), [11, 12, 13]);
      expect(threads.last.map((c) => c.id), [20]);
    },
  );

  test('joins a root without thread metadata to its enriched reply', () {
    final threads = groupReviewThreads([
      comment(10, minute: 0),
      comment(11, replyTo: 10, threadId: 'thread-1', minute: 1),
    ]);
    expect(threads, hasLength(1));
    expect(threads.single.map((c) => c.id), [10, 11]);
  });

  test('groups orphan replies by the forge thread ID', () {
    final threads = groupReviewThreads([
      comment(3, replyTo: 999, threadId: 'thread-1', minute: 1),
      comment(4, replyTo: 999, threadId: 'thread-1', minute: 2),
    ]);
    expect(threads, hasLength(1));
    expect(threads.single.map((c) => c.id), [3, 4]);
  });
}
