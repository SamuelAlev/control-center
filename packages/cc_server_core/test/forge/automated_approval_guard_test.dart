import 'package:cc_connect_core/cc_connect_core.dart' show GitHubTokenScope;
import 'package:cc_server_core/src/forge/github_request_policy.dart';
import 'package:test/test.dart';

/// Automation clients never approve a pull request; a person does, from
/// their own account.
void main() {
  String? guard(String method, String url, Object? body) =>
      refuseAutomatedGitHubApproval(method, url, body);

  group('refuseAutomatedApproval', () {
    test('an APPROVE review is refused, in any case spelling', () {
      expect(
        guard('POST', '/repos/acme/app/pulls/7/reviews', {'event': 'APPROVE'}),
        isNotNull,
      );
      expect(
        guard('post', 'https://api.github.com/repos/acme/app/pulls/7/reviews', {
          'event': 'approve',
          'body': 'LGTM',
        }),
        isNotNull,
      );
    });

    test('a review or GraphQL body the guard cannot read is refused', () {
      for (final url in [
        '/repos/acme/app/pulls/7/reviews',
        '/repos/acme/app/pulls/7/reviews/55/events',
        '/graphql',
      ]) {
        expect(guard('POST', url, null), isNotNull, reason: url);
        expect(guard('POST', url, 'event=APPROVE'), isNotNull, reason: url);
      }
      // Anywhere else an unreadable body is not this guard's business.
      expect(guard('POST', '/repos/acme/app/issues/7/comments', null), isNull);
    });

    test('an APPROVE in the query string is refused', () {
      expect(
        guard('POST', '/repos/acme/app/pulls/7/reviews?event=APPROVE', {
          'event': 'COMMENT',
        }),
        isNotNull,
      );
    });

    test('submitting a pending review as APPROVE is refused', () {
      expect(
        guard('POST', '/repos/acme/app/pulls/7/reviews/55/events', {
          'event': 'APPROVE',
        }),
        isNotNull,
      );
    });

    test('a GraphQL review mutation that approves is refused', () {
      expect(
        guard('POST', '/graphql', {
          'query':
              r'mutation($id: ID!) { addPullRequestReview(input: '
              r'{pullRequestId: $id, event: APPROVE}) { clientMutationId } }',
        }),
        isNotNull,
      );
      expect(
        guard('POST', 'https://api.github.com/graphql', {
          'query':
              r'mutation($e: PullRequestReviewEvent!) { submitPullRequestReview'
              r'(input: {event: $e}) { clientMutationId } }',
          'variables': {'e': 'APPROVE'},
        }),
        isNotNull,
      );
    });

    test('an APPROVE nested inside the mutation input is refused', () {
      expect(
        guard('POST', '/graphql', {
          'query':
              r'mutation($input: AddPullRequestReviewInput!) { '
              r'addPullRequestReview(input: $input) { pullRequestReview { id } } }',
          'variables': {
            'input': {'pullRequestId': 'PR_x', 'event': 'approve'},
          },
        }),
        isNotNull,
      );
      expect(
        guard('POST', '/graphql', {
          'query':
              r'mutation($batch: [Input!]!) { addPullRequestReview(input: '
              r'$batch) { clientMutationId } }',
          'variables': {
            'batch': [
              {'event': 'APPROVE'},
            ],
          },
        }),
        isNotNull,
      );
    });

    test('comments and change requests pass', () {
      expect(
        guard('POST', '/repos/acme/app/pulls/7/reviews', {'event': 'COMMENT'}),
        isNull,
      );
      expect(
        guard('POST', '/repos/acme/app/pulls/7/reviews', {
          'event': 'REQUEST_CHANGES',
        }),
        isNull,
      );
      expect(
        guard('POST', '/repos/acme/app/issues/7/comments', {'body': 'APPROVE'}),
        isNull,
      );
      expect(
        guard('POST', '/graphql', {'query': 'query { viewer { login } }'}),
        isNull,
      );
      expect(guard('GET', '/repos/acme/app/pulls/7/reviews', null), isNull);
    });
  });

  group('refuseUnscopedWrite', () {
    String? unscoped(String method, String url, Object? body) =>
        refuseUnscopedGitHubWrite(method, url, body);

    test('automation reads beyond one repository but never writes there', () {
      expect(unscoped('GET', '/search/issues?q=is:pr', null), isNull);
      expect(
        unscoped('POST', '/graphql', {'query': 'query { viewer { login } }'}),
        isNull,
      );
      expect(
        unscoped('POST', '/graphql', {
          'query':
              r'mutation($id: ID!) { addReaction(input: {subjectId: $id}) '
              '{ clientMutationId } }',
        }),
        isNotNull,
      );
      expect(
        unscoped('POST', '/graphql', {
          'query': '  # setup\n mutation { resolveReviewThread }',
        }),
        isNotNull,
      );
      expect(unscoped('POST', '/graphql', null), isNotNull);
      expect(unscoped('PATCH', '/user', {'bio': 'x'}), isNotNull);
    });

    test('a GraphQL query that only mentions the word in a string reads', () {
      expect(
        unscoped('POST', '/graphql', {
          'query': 'query { search(query: "mutation testing") { issueCount } }',
        }),
        isNull,
      );
    });

    test('a GraphQL mutation is refused whoever acts: no person token ever '
        'rides an owner-wide client', () {
      expect(
        unscoped('POST', '/graphql', {
          'query': 'mutation { resolveReviewThread }',
        }),
        isNotNull,
      );
    });

    test('a repository write no one-repository scope covers is refused', () {
      expect(
        unscoped('POST', '/repos/acme/app/statuses/abc', const {}),
        isNotNull,
      );
      expect(
        unscoped('POST', '/repos/acme/app/issues/1/comments', const {}),
        isNull,
      );
    });
  });

  group('scopeForRequest', () {
    GitHubTokenScope? scope(String method, String path) =>
        githubScopeForRequest(
          method,
          'https://api.github.com$path',
        )?.scope;

    test('each write gets the scope that carries its permission', () {
      final cases = <(String, String), GitHubTokenScope?>{
        ('GET', '/repos/o/r/pulls/1'): GitHubTokenScope.read,
        ('HEAD', '/repos/o/r'): GitHubTokenScope.read,
        // Conversation through the issues API, as the bot.
        ('POST', '/repos/o/r/issues'): GitHubTokenScope.comment,
        // Ticket sync edits the issues it opened; the URL cannot tell an
        // issue from a pull request, and `write` holds no `issues`.
        ('PATCH', '/repos/o/r/issues/1'): GitHubTokenScope.comment,
        ('POST', '/repos/o/r/issues/1/comments'): GitHubTokenScope.comment,
        ('POST', '/repos/o/r/issues/1/labels'): GitHubTokenScope.comment,
        ('DELETE', '/repos/o/r/issues/1/labels/bug'): GitHubTokenScope.comment,
        ('POST', '/repos/o/r/issues/1/assignees'): GitHubTokenScope.comment,
        ('POST', '/repos/o/r/issues/1/reactions'): GitHubTokenScope.comment,
        ('POST', '/repos/o/r/issues/comments/5/reactions'):
            GitHubTokenScope.comment,
        ('DELETE', '/repos/o/r/issues/comments/5/reactions/9'):
            GitHubTokenScope.comment,
        ('POST', '/repos/o/r/pulls/1/reviews'): GitHubTokenScope.bot,
        ('PUT', '/repos/o/r/pulls/1/reviews/3'): GitHubTokenScope.bot,
        ('DELETE', '/repos/o/r/pulls/1/reviews/3'): GitHubTokenScope.bot,
        ('POST', '/repos/o/r/pulls/1/reviews/3/events'): GitHubTokenScope.bot,
        ('POST', '/repos/o/r/pulls/1/comments'): GitHubTokenScope.bot,
        ('POST', '/repos/o/r/pulls/1/comments/4/replies'): GitHubTokenScope.bot,
        ('POST', '/repos/o/r/pulls/1/requested_reviewers'):
            GitHubTokenScope.bot,
        ('DELETE', '/repos/o/r/pulls/1/requested_reviewers'):
            GitHubTokenScope.bot,
        ('POST', '/repos/o/r/pulls/comments/4/reactions'): GitHubTokenScope.bot,
        ('DELETE', '/repos/o/r/pulls/comments/4/reactions/9'):
            GitHubTokenScope.bot,
        // Comments that may be someone else's, dismissals, and a pull
        // request's own title, state, base or branch.
        ('PATCH', '/repos/o/r/issues/comments/5'): GitHubTokenScope.write,
        ('DELETE', '/repos/o/r/issues/comments/5'): GitHubTokenScope.write,
        ('PATCH', '/repos/o/r/pulls/comments/4'): GitHubTokenScope.write,
        ('DELETE', '/repos/o/r/pulls/comments/4'): GitHubTokenScope.write,
        ('PUT', '/repos/o/r/pulls/1/reviews/3/dismissals'):
            GitHubTokenScope.write,
        ('POST', '/repos/o/r/pulls'): GitHubTokenScope.write,
        ('PATCH', '/repos/o/r/pulls/1'): GitHubTokenScope.write,
        ('PUT', '/repos/o/r/pulls/1/merge'): GitHubTokenScope.write,
        ('PUT', '/repos/o/r/pulls/1/update-branch'): GitHubTokenScope.write,
        // Moderation is a person's act.
        ('PUT', '/repos/o/r/issues/1/lock'): null,
        ('DELETE', '/repos/o/r/issues/1/lock'): null,
        ('PUT', '/repos/o/r/contents/a.md'): GitHubTokenScope.write,
        ('POST', '/repos/o/r/git/blobs'): GitHubTokenScope.write,
        ('POST', '/repos/o/r/statuses/abc'): null,
        ('POST', '/repos/o/r/check-runs'): null,
        ('POST', '/repos/o/r/actions/workflows/1/dispatches'): null,
        ('PATCH', '/repos/o/r'): null,
      };
      cases.forEach((request, expected) {
        expect(
          scope(request.$1, request.$2),
          expected,
          reason: '${request.$1} ${request.$2}',
        );
      });
    });

    test('requests that are not about one repository have no target', () {
      expect(
        githubScopeForRequest('POST', 'https://api.github.com/graphql'),
        isNull,
      );
      expect(githubScopeForRequest('GET', '/user'), isNull);
    });

    test('a malformed repository path is a target with no scope', () {
      final target = githubScopeForRequest(
        'GET',
        'https://api.github.com/repos/o/..',
      );
      expect(target, isNotNull);
      expect(target!.scope, isNull);
    });
  });
}
