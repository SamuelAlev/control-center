import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_infra/src/network/pr_review_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

/// A representative GraphQL `PullRequest` node, shaped like the batched
/// `fetchOpenPullRequestsBatch` query's `PrListFields` fragment.
Map<String, dynamic> _node({
  int number = 42,
  String title = 'Add widget',
  bool isDraft = false,
  String? mergeStateStatus = 'CLEAN',
  String? rollupState = 'SUCCESS',
  List<Map<String, dynamic>> reviewRequests = const [],
  List<Map<String, dynamic>> latestReviews = const [],
}) {
  return <String, dynamic>{
    'number': number,
    'title': title,
    'isDraft': isDraft,
    'createdAt': '2026-01-01T10:00:00Z',
    'updatedAt': '2026-01-02T12:00:00Z',
    'url': 'https://github.com/o/r/pull/$number',
    'id': 'PR_node_$number',
    'headRefOid': 'deadbeef',
    'baseRefName': 'main',
    'headRefName': 'feature/x',
    'mergedAt': null,
    'author': {'login': 'octocat', 'avatarUrl': 'https://a/o.png'},
    'additions': 120,
    'deletions': 7,
    'changedFiles': 4,
    'comments': {'totalCount': 3},
    'commitsTotal': {'totalCount': 5},
    'mergeStateStatus': mergeStateStatus,
    'lastCommit': {
      'nodes': [
        {
          'commit': {
            'statusCheckRollup': rollupState == null
                ? null
                : {'state': rollupState},
          },
        },
      ],
    },
    'reviewRequests': {'nodes': reviewRequests},
    'latestReviews': {'nodes': latestReviews},
  };
}

void main() {
  group('pullRequestFromGraphQlNode', () {
    test('maps the core list fields and metrics', () {
      final pr = pullRequestFromGraphQlNode(_node(), repoFullName: 'o/r');

      expect(pr.number, 42);
      expect(pr.id, 42);
      expect(pr.title, 'Add widget');
      expect(pr.state, PrState.open);
      expect(pr.isDraft, isFalse);
      expect(pr.repoFullName, 'o/r');
      expect(pr.htmlUrl, 'https://github.com/o/r/pull/42');
      expect(pr.nodeId, 'PR_node_42');
      expect(pr.headSha, 'deadbeef');
      expect(pr.baseRef, 'main');
      expect(pr.headRef, 'feature/x');
      expect(pr.author?.login, 'octocat');
      expect(pr.createdAt, DateTime.utc(2026, 1, 1, 10));
      expect(pr.updatedAt, DateTime.utc(2026, 1, 2, 12));
      expect(pr.additions, 120);
      expect(pr.deletions, 7);
      expect(pr.changedFiles, 4);
      expect(pr.commentsCount, 3);
      expect(pr.commitsCount, 5);
      // Body/reactions are intentionally not fetched for the list.
      expect(pr.body, isEmpty);
      expect(pr.reactions, isEmpty);
    });

    test('maps the status-check rollup to checksStatus', () {
      expect(
        pullRequestFromGraphQlNode(
          _node(rollupState: 'SUCCESS'),
          repoFullName: 'o/r',
        ).checksStatus,
        PrChecksStatus.passing,
      );
      expect(
        pullRequestFromGraphQlNode(
          _node(rollupState: 'FAILURE'),
          repoFullName: 'o/r',
        ).checksStatus,
        PrChecksStatus.failing,
      );
      expect(
        pullRequestFromGraphQlNode(
          _node(rollupState: 'PENDING'),
          repoFullName: 'o/r',
        ).checksStatus,
        PrChecksStatus.pending,
      );
      expect(
        pullRequestFromGraphQlNode(
          _node(rollupState: null),
          repoFullName: 'o/r',
        ).checksStatus,
        PrChecksStatus.none,
      );
    });

    test('lowercases mergeStateStatus into mergeableState', () {
      expect(
        pullRequestFromGraphQlNode(
          _node(mergeStateStatus: 'CLEAN'),
          repoFullName: 'o/r',
        ).mergeableState,
        PrMergeableState.clean,
      );
      expect(
        pullRequestFromGraphQlNode(
          _node(mergeStateStatus: 'BLOCKED'),
          repoFullName: 'o/r',
        ).mergeableState,
        PrMergeableState.blocked,
      );
      expect(
        pullRequestFromGraphQlNode(
          _node(mergeStateStatus: 'HAS_HOOKS'),
          repoFullName: 'o/r',
        ).mergeableState,
        PrMergeableState.hasHooks,
      );
    });

    test('maps user and team requested reviewers; ignores empty reviewers', () {
      final pr = pullRequestFromGraphQlNode(
        _node(
          reviewRequests: [
            {
              'requestedReviewer': {
                '__typename': 'User',
                'login': 'reviewer1',
                'avatarUrl': 'https://a/r1.png',
              },
            },
            {
              'requestedReviewer': {'__typename': 'Team', 'name': 'platform'},
            },
            {'requestedReviewer': null},
          ],
        ),
        repoFullName: 'o/r',
      );

      expect(pr.requestedReviewers.map((u) => u.login), ['reviewer1', 'platform']);
      expect(pr.isPriority, isTrue);
    });

    test('derives reviewedByMe from latestReviews against the viewer (case-insensitive)', () {
      Map<String, dynamic> nodeWithReviewers(List<String> logins) => _node(
        latestReviews: [
          for (final l in logins)
            {
              'author': {'login': l},
            },
        ],
      );

      expect(
        pullRequestFromGraphQlNode(
          nodeWithReviewers(['someone', 'OctoCat']),
          repoFullName: 'o/r',
          viewerLogin: 'octocat',
        ).reviewedByMe,
        isTrue,
      );
      expect(
        pullRequestFromGraphQlNode(
          nodeWithReviewers(['someone', 'else']),
          repoFullName: 'o/r',
          viewerLogin: 'octocat',
        ).reviewedByMe,
        isFalse,
      );
      // No viewer login known → cannot be reviewed-by-me.
      expect(
        pullRequestFromGraphQlNode(
          nodeWithReviewers(['octocat']),
          repoFullName: 'o/r',
        ).reviewedByMe,
        isFalse,
      );
    });
  });
}
