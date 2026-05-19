import 'package:cc_domain/cc_domain.dart';
import 'package:cc_server_core/cc_server_core.dart';
import 'package:test/test.dart';

// `pr_review.commentFindings` posts a reviewer agent's findings to GitHub as
// inline comments. The agent runs in the PR's worktree and can read the whole
// repository, so a finding may legitimately land on a file the PR does not
// change — and GitHub refuses to hang an inline comment there. Telling that
// apart from a real failure is what stops the toast reporting "2 failed" for
// something the operator cannot retry and the reason ending up only in a raw
// Dio error in the server log.
void main() {
  // Verbatim from a real rejection: a finding anchored to
  // a file that is in the branch but not in the PR's diff.
  const pathRejection =
      '{message: Validation Failed, errors: [{resource: '
      'PullRequestReviewComment, code: invalid, field: '
      'pull_request_review_thread.path, message: could not be resolved}], '
      'documentation_url: https://docs.github.com/rest, status: 422}';

  group('isOutOfDiffAnchorRejection', () {
    test('classifies an unresolvable path', () {
      expect(
        isOutOfDiffAnchorRejection(
          const NetworkException(
            'Unprocessable entity',
            statusCode: 422,
            responseBody: pathRejection,
            code: 'unprocessable_entity',
          ),
        ),
        isTrue,
      );
    });

    test('classifies a line outside the diff', () {
      // The file changed but the anchor is not in a hunk. Same consequence for
      // the reviewer, same bucket.
      expect(
        isOutOfDiffAnchorRejection(
          const NetworkException(
            'Unprocessable entity',
            statusCode: 422,
            responseBody:
                '{message: Validation Failed, errors: [{resource: '
                'PullRequestReviewComment, code: custom, field: '
                'pull_request_review_thread.line, message: must be part of '
                'the diff}], status: 422}',
            code: 'unprocessable_entity',
          ),
        ),
        isTrue,
      );
    });

    test('leaves an unrelated 422 as a failure', () {
      // A stale commit_id is a 422 too, and it IS retryable (refresh the head
      // and post again). Folding it into the out-of-diff bucket would hide a
      // bug behind an explanation.
      expect(
        isOutOfDiffAnchorRejection(
          const NetworkException(
            'Unprocessable entity',
            statusCode: 422,
            responseBody:
                '{message: Validation Failed, errors: [{resource: '
                'PullRequestReviewComment, code: invalid, field: commit_id}], '
                'status: 422}',
            code: 'unprocessable_entity',
          ),
        ),
        isFalse,
      );
    });

    test('leaves other statuses and a bodiless error as failures', () {
      expect(
        isOutOfDiffAnchorRejection(
          const NetworkException(
            'Authentication failed',
            statusCode: 403,
            responseBody: 'pull_request_review_thread.path',
            code: 'auth_error',
          ),
        ),
        isFalse,
      );
      expect(
        isOutOfDiffAnchorRejection(
          const NetworkException('Network timeout', code: 'timeout'),
        ),
        isFalse,
      );
      expect(isOutOfDiffAnchorRejection(StateError('nope')), isFalse);
    });
  });
}
