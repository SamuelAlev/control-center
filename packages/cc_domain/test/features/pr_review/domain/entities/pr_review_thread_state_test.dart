import 'package:cc_domain/features/pr_review/domain/entities/pr_code_review_comment.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_review_thread_state.dart';
import 'package:test/test.dart';

PrCodeReviewComment _comment(int id, {int? startLine, int line = 19}) =>
    PrCodeReviewComment(
      id: id,
      body: 'body $id',
      user: null,
      path: 'lib/a.dart',
      position: line,
      createdAt: DateTime.utc(2026),
      startLine: startLine,
      line: line,
    );

void main() {
  group('withReviewThreadState', () {
    test('stamps every comment of a thread with its state', () {
      final out = withReviewThreadState(
        [_comment(1), _comment(2), _comment(3)],
        const [
          PrReviewThreadState(
            id: 'T1',
            commentIds: [1, 2],
            isResolved: true,
          ),
        ],
      );

      expect(out[0].threadId, 'T1');
      expect(out[0].isResolved, isTrue);
      // A reply inherits the CONVERSATION's state, not its own — resolution is
      // a property of the thread, and a reply that read as unresolved would
      // reopen a settled conversation in the UI.
      expect(out[1].threadId, 'T1');
      expect(out[1].isResolved, isTrue);
    });

    test('a comment no thread claims is left untouched and unresolved', () {
      final out = withReviewThreadState(
        [_comment(1), _comment(9)],
        const [PrReviewThreadState(id: 'T1', commentIds: [1], isResolved: true)],
      );

      expect(out[1].threadId, isNull);
      // Showing a settled conversation costs a click; hiding an open one loses
      // the feedback. The unclaimed case must fail toward showing it.
      expect(out[1].isResolved, isFalse);
    });

    test('no threads known leaves the list identical', () {
      final input = [_comment(1)];
      expect(
        identical(withReviewThreadState(input, const []), input),
        isTrue,
      );
    });

    test('an unresolved thread still carries its id, so it can be resolved', () {
      final out = withReviewThreadState(
        [_comment(1)],
        const [PrReviewThreadState(id: 'T7', commentIds: [1])],
      );

      expect(out.single.threadId, 'T7');
      expect(out.single.isResolved, isFalse);
    });
  });

  group('PrCodeReviewComment anchors', () {
    test('anchorStartLine falls back to the anchor for a single line', () {
      expect(_comment(1, line: 42).anchorStartLine, 42);
    });

    test('anchorStartLine is the range start for a multi-line comment', () {
      final c = _comment(1, startLine: 13);
      expect(c.anchorStartLine, 13);
      // The ANCHOR stays the last line: that is where the forge shows the card
      // and where a reply attaches.
      expect(c.anchorLine, 19);
    });
  });
}
