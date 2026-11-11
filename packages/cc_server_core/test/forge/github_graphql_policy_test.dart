import 'package:cc_connect_core/cc_connect_core.dart' show GitHubTokenScope;
import 'package:cc_infra/cc_infra.dart' show ForgeCredentialUnavailable;
import 'package:cc_server_core/src/forge/github_graphql_policy.dart';
import 'package:cc_server_core/src/forge/github_request_policy.dart';
import 'package:test/test.dart';

void main() {
  GitHubTokenScope? scopeOf(String query, [Map<String, Object?>? variables]) =>
      githubGraphQlScope({'query': query, 'variables': ?variables}).scope;
  String? refusalOf(String query) =>
      githubGraphQlScope({'query': query}).refusal;

  group('githubGraphQlScope', () {
    test('every mutation the codebase sends has a listed scope', () {
      // The documents GitHubGraphQlClient sends, in its own spelling.
      final cases = <String, GitHubTokenScope>{
        r'mutation MarkFileAsViewed($pullRequestId: ID!, $path: String!) { '
                r'markFileAsViewed(input: {pullRequestId: $pullRequestId, '
                r'path: $path}) { pullRequest { id } } }':
            GitHubTokenScope.bot,
        r'mutation UnmarkFileAsViewed($pullRequestId: ID!, $path: String!) {'
                r' unmarkFileAsViewed(input: {pullRequestId: $pullRequestId, '
                r'path: $path}) { pullRequest { id } } }':
            GitHubTokenScope.bot,
        r'mutation ResolveThread($threadId: ID!) { resolveReviewThread('
                r'input: {threadId: $threadId}) { thread { id isResolved } } }':
            GitHubTokenScope.bot,
        r'mutation UnresolveThread($threadId: ID!) { unresolveReviewThread('
                r'input: {threadId: $threadId}) { thread { id isResolved } } }':
            GitHubTokenScope.bot,
        r'mutation($subject: ID!, $content: ReactionContent!) { addReaction('
                r'input: {subject: $subject, content: $content}) { reaction '
                '{ id content } } }':
            GitHubTokenScope.comment,
        r'mutation($reactionId: ID!) { removeReaction(input: {reactionId: '
                r'$reactionId}) { reaction { id content } } }':
            GitHubTokenScope.comment,
        r'mutation ConvertToDraft($id: ID!) { convertPullRequestToDraft('
                r'input: {pullRequestId: $id}) { pullRequest { isDraft } } }':
            GitHubTokenScope.write,
        r'mutation MarkReady($id: ID!) { markPullRequestReadyForReview('
                r'input: {pullRequestId: $id}) { pullRequest { isDraft } } }':
            GitHubTokenScope.write,
      };
      cases.forEach((query, expected) {
        expect(scopeOf(query), expected, reason: query);
      });
    });

    test('conversation is comment, reviews bot; state, dismissals and '
        'comment edits are write', () {
      final cases = <String, GitHubTokenScope>{
        'addComment': GitHubTokenScope.comment,
        'addPullRequestReview': GitHubTokenScope.bot,
        'submitPullRequestReview': GitHubTokenScope.bot,
        'addPullRequestReviewThread': GitHubTokenScope.bot,
        'requestReviews': GitHubTokenScope.bot,
        'addLabelsToLabelable': GitHubTokenScope.comment,
        'addAssigneesToAssignable': GitHubTokenScope.comment,
        'updateIssueComment': GitHubTokenScope.write,
        'deleteIssueComment': GitHubTokenScope.write,
        'updatePullRequestReviewComment': GitHubTokenScope.write,
        'dismissPullRequestReview': GitHubTokenScope.write,
        'createPullRequest': GitHubTokenScope.write,
        'updatePullRequest': GitHubTokenScope.write,
        'closePullRequest': GitHubTokenScope.write,
        'mergePullRequest': GitHubTokenScope.write,
      };
      cases.forEach((field, expected) {
        expect(
          scopeOf('mutation { $field(input: {}) { clientMutationId } }'),
          expected,
          reason: field,
        );
      });
    });

    test('queries read, whatever they mention', () {
      expect(scopeOf('query { viewer { login } }'), GitHubTokenScope.read);
      expect(scopeOf('{ viewer { login } }'), GitHubTokenScope.read);
      expect(
        scopeOf(
          'query { search(query: "mutation { mergePullRequest }") '
          '{ issueCount } }',
        ),
        GitHubTokenScope.read,
      );
      // A field aliased `mutation` is still a query.
      expect(
        scopeOf('query { mutation: viewer { login } }'),
        GitHubTokenScope.read,
      );
    });

    test('several root fields need the highest of their scopes', () {
      expect(
        scopeOf(
          'mutation { a: addComment(input: {}) { clientMutationId } '
          'b: closePullRequest(input: {}) { clientMutationId } }',
        ),
        GitHubTokenScope.write,
      );
      expect(
        scopeOf(
          'query Q { viewer { login } } '
          'mutation M { addReaction(input: {}) { clientMutationId } }',
        ),
        GitHubTokenScope.comment,
      );
      // A comment and a review in one document need the review's scope.
      expect(
        scopeOf(
          'mutation { a: addComment(input: {}) { clientMutationId } '
          'b: addPullRequestReview(input: {}) { clientMutationId } }',
        ),
        GitHubTokenScope.bot,
      );
    });

    test('an unlisted mutation is refused, by name', () {
      final why = refusalOf(
        'mutation { deleteRef(input: {refId: "x"}) { clientMutationId } }',
      );
      expect(why, contains('deleteRef'));
      expect(
        githubGraphQlScope({
          'query': 'mutation { deleteRef(input: {}) { clientMutationId } }',
        }).scope,
        isNull,
      );
    });

    test('an alias cannot pass an unlisted mutation off as a listed one', () {
      expect(
        refusalOf(
          'mutation { addComment: deleteRef(input: {}) { clientMutationId } }',
        ),
        contains('deleteRef'),
      );
      expect(
        scopeOf(
          'mutation { addComment: closePullRequest(input: {}) '
          '{ clientMutationId } }',
        ),
        GitHubTokenScope.write,
      );
    });

    test('comments and strings hide nothing', () {
      // The real root field sits after a comment that looks like a field.
      expect(
        refusalOf(
          'mutation {\n # addComment(input: {})\n'
          ' deleteRef(input: {}) { clientMutationId } }',
        ),
        contains('deleteRef'),
      );
      // A string carrying braces does not end the argument list early.
      expect(
        refusalOf(
          'mutation { addComment(input: {body: "} } mutation { x"}) '
          '{ clientMutationId } deleteRef(input: {}) { clientMutationId } }',
        ),
        contains('deleteRef'),
      );
      expect(
        refusalOf(
          'mutation { addComment(input: {body: """ } \\""" } """}) '
          '{ clientMutationId } deleteRef(input: {}) { clientMutationId } }',
        ),
        contains('deleteRef'),
      );
    });

    test('fragments at the root count: inline and named', () {
      expect(
        refusalOf(
          'mutation { ... on Mutation { deleteRef(input: {}) '
          '{ clientMutationId } } }',
        ),
        contains('deleteRef'),
      );
      expect(
        refusalOf(
          'mutation { ...F } '
          'fragment F on Mutation { deleteRef(input: {}) { clientMutationId } }',
        ),
        contains('deleteRef'),
      );
      expect(
        scopeOf(
          'mutation { ...F @include(if: true) } '
          'fragment F on Mutation { addComment(input: {}) '
          '{ clientMutationId } }',
        ),
        GitHubTokenScope.comment,
      );
      // A fragment that spreads itself does not loop.
      expect(
        scopeOf(
          'mutation { ...F } fragment F on Mutation { ...F '
          'addReaction(input: {}) { clientMutationId } }',
        ),
        GitHubTokenScope.comment,
      );
      expect(refusalOf('mutation { ...Missing }'), isNotNull);
    });

    test('subscriptions, unreadable documents and missing queries are '
        'refused', () {
      expect(refusalOf('subscription { x }'), isNotNull);
      expect(refusalOf('mutation { addComment(input: {}) '), isNotNull);
      expect(refusalOf('mutation { addComment(input: "x) }'), isNotNull);
      expect(refusalOf(''), isNotNull);
      expect(refusalOf('type Mutation { x: Int }'), isNotNull);
      expect(githubGraphQlScope(null).refusal, isNotNull);
      expect(githubGraphQlScope(const {'query': 7}).refusal, isNotNull);
    });

    test('a refusal throws as an unsent 403 from a credential lookup', () {
      expect(
        () => requireGitHubGraphQlScope(const {
          'query': 'mutation { deleteRef(input: {}) { clientMutationId } }',
        }),
        throwsA(
          isA<ForgeCredentialUnavailable>().having(
            (e) => e.statusCode,
            'statusCode',
            403,
          ),
        ),
      );
    });
  });

  group('isGraphQlWrite', () {
    test('only a query reads; an unreadable body is a write', () {
      expect(isGraphQlWrite(const {'query': '{ viewer { login } }'}), isFalse);
      expect(
        isGraphQlWrite(const {'query': 'query { mutation: viewer { id } }'}),
        isFalse,
      );
      expect(
        isGraphQlWrite(const {'query': 'mutation { addComment(input: {}) }'}),
        isTrue,
      );
      expect(isGraphQlWrite(const {'query': 'subscription { x }'}), isTrue);
      expect(isGraphQlWrite(const {'query': 'query {'}), isTrue);
      expect(isGraphQlWrite(null), isTrue);
    });
  });

  group('refuseGitHubRepoClientRequest', () {
    String? guard(String method, String url, [Object? body]) =>
        refuseGitHubRepoClientRequest('acme', 'api', method, url, body);

    test('a listed mutation and a query pass', () {
      expect(
        guard('POST', '/graphql', const {
          'query': 'mutation { addComment(input: {}) { clientMutationId } }',
        }),
        isNull,
      );
      expect(
        guard('POST', '/graphql', const {'query': '{ viewer { login } }'}),
        isNull,
      );
      expect(guard('GET', '/repos/acme/api/pulls'), isNull);
    });

    test('an unlisted mutation is refused before any token is minted', () {
      expect(
        guard('POST', '/graphql', const {
          'query': 'mutation { deleteRef(input: {}) { clientMutationId } }',
        }),
        contains('deleteRef'),
      );
    });

    test('approving stays refused, however the event is spelled', () {
      expect(
        guard('POST', '/graphql', const {
          'query':
              r'mutation($id: ID!) { submitPullRequestReview(input: '
              r'{pullRequestReviewId: $id, event: APPROVE}) '
              '{ clientMutationId } }',
        }),
        contains('never approves'),
      );
      expect(
        guard('POST', '/graphql', const {
          'query':
              r'mutation($e: PullRequestReviewEvent!) { addPullRequestReview('
              r'input: {pullRequestId: "x", event: $e}) { clientMutationId } }',
          'variables': {'e': 'APPROVE'},
        }),
        contains('never approves'),
      );
      expect(
        guard('POST', '/repos/acme/api/pulls/1/reviews', const {
          'event': 'APPROVE',
        }),
        contains('never approves'),
      );
    });

    test('another repository is refused', () {
      expect(guard('GET', '/repos/acme/other/pulls'), isNotNull);
    });
  });
}
