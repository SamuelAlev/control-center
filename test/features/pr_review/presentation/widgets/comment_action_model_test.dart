import 'package:control_center/features/pr_review/presentation/widgets/comment_action_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('canDeleteComment', () {
    test('the author can delete a published comment', () {
      expect(
        canDeleteComment(isAuthor: true, published: true, permission: 'read'),
        isTrue,
      );
    });

    test('write and admin can delete someone else\'s comment', () {
      expect(
        canDeleteComment(isAuthor: false, published: true, permission: 'write'),
        isTrue,
      );
      expect(
        canDeleteComment(isAuthor: false, published: true, permission: 'admin'),
        isTrue,
      );
    });

    test('read, none, and a permission still loading cannot', () {
      expect(
        canDeleteComment(isAuthor: false, published: true, permission: 'read'),
        isFalse,
      );
      expect(
        canDeleteComment(isAuthor: false, published: true, permission: 'none'),
        isFalse,
      );
      expect(
        canDeleteComment(isAuthor: false, published: true, permission: null),
        isFalse,
      );
    });

    test('an unpublished draft can be discarded locally', () {
      expect(
        canDeleteComment(isAuthor: false, published: false, permission: null),
        isTrue,
      );
    });
  });

  group('canEditComment', () {
    test('only the author of a published comment can edit it', () {
      expect(canEditComment(isAuthor: true, published: true), isTrue);
      expect(canEditComment(isAuthor: true, published: false), isFalse);
      expect(canEditComment(isAuthor: false, published: true), isFalse);
    });
  });

  test('logins compare case-insensitively', () {
    expect(commentIsAuthor('Ada', 'ada'), isTrue);
    expect(commentIsAuthor('ada', 'grace'), isFalse);
    expect(commentIsAuthor('', 'ada'), isFalse);
  });

  test('permalinks follow the forge that hosts the pull request', () {
    expect(
      commentPermalink(
        htmlUrl: 'https://github.com/acme/app/pull/7',
        commentId: 12,
        reviewComment: false,
      ),
      'https://github.com/acme/app/pull/7#issuecomment-12',
    );
    expect(
      commentPermalink(
        htmlUrl: 'https://github.com/acme/app/pull/7',
        commentId: 12,
        reviewComment: true,
      ),
      'https://github.com/acme/app/pull/7#discussion_r12',
    );
    expect(
      commentPermalink(
        htmlUrl: 'https://gitlab.com/acme/app/-/merge_requests/7',
        commentId: 4,
        reviewComment: true,
      ),
      'https://gitlab.com/acme/app/-/merge_requests/7#note_4',
    );
  });

  test('the agent prompt quotes the comment and names its anchor', () {
    final prompt = commentAgentPrompt(
      body: 'Why this endpoint?',
      author: 'ada',
      path: 'lib/api.dart',
      startLine: 10,
      endLine: 12,
    );
    expect(prompt, contains('Address this comment.'));
    expect(prompt, contains('lib/api.dart:10-12'));
    expect(prompt, contains('ada'));
    expect(prompt, contains('> Why this endpoint?'));
  });

  test('a thread prompt keeps every reply', () {
    final prompt = commentAgentPrompt(
      body: 'ignored when the thread is passed',
      thread: [
        (author: 'ada', body: 'first'),
        (author: 'grace', body: 'second'),
      ],
    );
    expect(prompt, contains('> first'));
    expect(prompt, contains('> second'));
    expect(prompt, isNot(contains('ignored')));
  });
}
