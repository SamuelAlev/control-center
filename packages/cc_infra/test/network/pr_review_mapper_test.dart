import 'package:cc_domain/core/domain/entities/github_user.dart';
import 'package:cc_domain/features/pr_review/domain/entities/check_run.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_review_submission.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_reviewer.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_timeline_event.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_user.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/ports/forge_pr_client.dart';
import 'package:cc_infra/src/network/models/github_check_run.dart';
import 'package:cc_infra/src/network/models/github_commit.dart';
import 'package:cc_infra/src/network/models/github_issue_comment.dart';
import 'package:cc_infra/src/network/models/github_job_run.dart';
import 'package:cc_infra/src/network/models/github_pr_review_state.dart';
import 'package:cc_infra/src/network/models/github_pull_request.dart';
import 'package:cc_infra/src/network/models/github_pull_request_file.dart';
import 'package:cc_infra/src/network/models/github_reaction.dart';
import 'package:cc_infra/src/network/models/github_review.dart';
import 'package:cc_infra/src/network/models/github_review_comment.dart';
import 'package:cc_infra/src/network/models/github_timeline_event.dart';
import 'package:cc_infra/src/network/pr_review_mapper.dart';
import 'package:test/test.dart';

void main() {
  group('GitHubPullRequest.fromJson — the forge id', () {
    test("reads GitHub's node_id", () {
      // The API calls it `node_id`; `external_id` is OUR name for it and only
      // our own [toJson] writes that key. Reading only ours left every PR
      // fetched from the API with an EMPTY forge id, so a review space keyed
      // on it was keyed on '' — and the PR page, looking its review up by '',
      // found either nothing or a different PR's row and reported "no review
      // yet" for a pull request that had a finished one.
      final pr = GitHubPullRequest.fromJson(const {
        'number': 42,
        'node_id': 'PR_kwDOABCD',
      });
      expect(pr.externalId, 'PR_kwDOABCD');
    });

    test('round-trips our own toJson shape unchanged', () {
      final pr = GitHubPullRequest.fromJson(const {
        'number': 42,
        'external_id': 'PR_ours',
        'node_id': 'PR_theirs',
      });
      expect(
        pr.externalId,
        'PR_ours',
        reason: 'a re-decoded toJson payload must not be rewritten by node_id',
      );
    });

    test('is empty when neither key is present', () {
      expect(GitHubPullRequest.fromJson(const {'number': 1}).externalId, '');
    });
  });

  group('reactionGroupsFromSummary', () {
    test('returns empty when summary is null', () {
      expect(reactionGroupsFromSummary(null), isEmpty);
    });

    test('returns empty when total count is zero', () {
      const summary = GitHubReactionSummary(totalCount: 0);
      expect(reactionGroupsFromSummary(summary), isEmpty);
    });

    test('maps only non-zero reaction kinds with correct counts and emoji', () {
      const summary = GitHubReactionSummary(
        totalCount: 4,
        plusOne: 2,
        heart: 1,
        rocket: 1,
      );
      final groups = reactionGroupsFromSummary(summary);

      expect(groups, hasLength(3));
      expect(groups[0].content, '+1');
      expect(groups[0].emoji, '👍');
      expect(groups[0].count, 2);
      expect(groups[0].userReacted, isFalse);

      expect(groups[1].content, 'heart');
      expect(groups[1].emoji, '❤️');
      expect(groups[1].count, 1);

      expect(groups[2].content, 'rocket');
      expect(groups[2].emoji, '🚀');
      expect(groups[2].count, 1);
    });

    test('maps every supported reaction kind when all are non-zero', () {
      const summary = GitHubReactionSummary(
        totalCount: 8,
        plusOne: 1,
        minusOne: 1,
        laugh: 1,
        hooray: 1,
        confused: 1,
        heart: 1,
        rocket: 1,
        eyes: 1,
      );
      final groups = reactionGroupsFromSummary(summary);
      expect(groups.map((g) => g.content).toList(), [
        '+1',
        '-1',
        'laugh',
        'hooray',
        'confused',
        'heart',
        'rocket',
        'eyes',
      ]);
      // Spot-check the minusOne count mapping (the only non-emoji-name branch).
      final minusOne = groups.firstWhere((g) => g.content == '-1');
      expect(minusOne.count, 1);
      expect(minusOne.emoji, '👎');
    });
  });

  group('reactionGroupsFromPerUser', () {
    test('returns empty when no reaction carries a login', () {
      expect(
        reactionGroupsFromPerUser(
          const [ForgeReaction(content: '+1', login: '')],
        ),
        isEmpty,
      );
    });

    test('groups by content, counts, carries usernames, orders by support', () {
      final groups = reactionGroupsFromPerUser(const [
        ForgeReaction(content: 'rocket', login: 'ada'),
        ForgeReaction(content: '+1', login: 'sam'),
        ForgeReaction(content: '+1', login: 'ada'),
      ]);

      expect(groups, hasLength(2));
      // Supported-reaction order, not first-seen order.
      expect(groups[0].content, '+1');
      expect(groups[0].count, 2);
      expect(groups[0].usernames, ['sam', 'ada']);
      expect(groups[0].userReacted, isFalse);
      expect(groups[1].content, 'rocket');
      expect(groups[1].count, 1);
      expect(groups[1].usernames, ['ada']);
    });
  });

  group('pullRequestFromGitHub', () {
    test('maps every field from a fully-populated GitHubPullRequest', () {
      final gh = GitHubPullRequest(
        number: 42,
        title: 'Add feature',
        body: 'The body',
        // A merged PR is exactly this on the wire: REST reports `closed` and
        // sets `merged_at`. There is no `state: 'open'` + `mergedAt` shape.
        state: 'closed',
        isDraft: true,
        userLogin: 'alice',
        htmlUrl: 'https://gh/p/42',
        externalId: 'NODE_42',
        author: const GitHubUser(login: 'alice', avatarUrl: 'https://a'),
        createdAt: DateTime.utc(2024, 1, 2),
        updatedAt: DateTime.utc(2024, 1, 3),
        mergedAt: DateTime.utc(2024, 1, 4),
        headSha: 'sha-head',
        baseRef: 'main',
        baseSha: 'sha-base',
        headRef: 'feature/x',
        requestedReviewers: const [
          GitHubUser(login: 'rev1', avatarUrl: 'https://r1'),
        ],
        assignees: const [GitHubUser(login: 'asg1', avatarUrl: 'https://as1')],
        reactions: const GitHubReactionSummary(totalCount: 1, heart: 1),
        bodyHtml: '<p>html</p>',
        changedFiles: 7,
        commitsCount: 3,
        mergeableState: 'clean',
      );

      final pr = pullRequestFromGitHub(gh, repoFullName: 'o/repo');

      expect(pr.number, 42);
      expect(pr.id, 42);
      expect(pr.title, 'Add feature');
      expect(pr.body, 'The body');
      // `merged_at` promotes the REST `closed` to `merged`.
      expect(pr.state, PrState.merged);
      expect(pr.isDraft, isTrue);
      expect(pr.author, const PrUser(login: 'alice', avatarUrl: 'https://a'));
      expect(pr.createdAt, DateTime.utc(2024, 1, 2));
      expect(pr.updatedAt, DateTime.utc(2024, 1, 3));
      expect(pr.mergedAt, DateTime.utc(2024, 1, 4));
      expect(pr.repoFullName, 'o/repo');
      expect(pr.htmlUrl, 'https://gh/p/42');
      expect(pr.externalId, 'NODE_42');
      expect(pr.headSha, 'sha-head');
      expect(pr.baseRef, 'main');
      expect(pr.baseSha, 'sha-base');
      expect(pr.headRef, 'feature/x');
      expect(pr.requestedReviewers, [
        const PrUser(login: 'rev1', avatarUrl: 'https://r1'),
      ]);
      expect(pr.assignees, [
        const PrUser(login: 'asg1', avatarUrl: 'https://as1'),
      ]);
      expect(pr.bodyHtml, '<p>html</p>');
      expect(pr.changedFiles, 7);
      expect(pr.commitsCount, 3);
      expect(pr.mergeableState, PrMergeableState.clean);
      expect(pr.reviewedByMe, isFalse);
      expect(pr.reactions, hasLength(1));
      expect(pr.reactions.first.content, 'heart');

      // reviewedByMe override is honoured.
      expect(
        pullRequestFromGitHub(
          gh,
          repoFullName: 'o/repo',
          reviewedByMe: true,
        ).reviewedByMe,
        isTrue,
      );
    });

    test('maps a PR with a null author to an empty PrUser', () {
      const gh = GitHubPullRequest(
        number: 1,
        title: 't',
        body: '',
        state: 'closed',
        isDraft: false,
        userLogin: '',
        htmlUrl: '',
        externalId: '',
      );
      final pr = pullRequestFromGitHub(gh, repoFullName: 'o/r');
      expect(pr.author, const PrUser(login: '', avatarUrl: ''));
      expect(pr.state, PrState.closed);
    });

    test('maps an open PR with no reactions summary to empty reactions', () {
      const gh = GitHubPullRequest(
        number: 9,
        title: 'open',
        body: '',
        state: 'open',
        isDraft: false,
        userLogin: 'b',
        htmlUrl: '',
        externalId: '',
        mergeableState: 'dirty',
      );
      final pr = pullRequestFromGitHub(gh, repoFullName: 'o/r');
      expect(pr.reactions, isEmpty);
      expect(pr.mergeableState, PrMergeableState.dirty);
      // No `merged_at`, so nothing promotes the state.
      expect(pr.state, PrState.open);
    });
  });

  group('prChecksStatusFromRollup', () {
    test('SUCCESS -> passing', () {
      expect(prChecksStatusFromRollup('SUCCESS'), PrChecksStatus.passing);
    });

    test('FAILURE and ERROR -> failing', () {
      expect(prChecksStatusFromRollup('FAILURE'), PrChecksStatus.failing);
      expect(prChecksStatusFromRollup('ERROR'), PrChecksStatus.failing);
    });

    test('PENDING and EXPECTED -> pending', () {
      expect(prChecksStatusFromRollup('PENDING'), PrChecksStatus.pending);
      expect(prChecksStatusFromRollup('EXPECTED'), PrChecksStatus.pending);
    });

    test('null and unknown values -> none', () {
      expect(prChecksStatusFromRollup(null), PrChecksStatus.none);
      expect(prChecksStatusFromRollup('WHATEVER'), PrChecksStatus.none);
    });
  });

  group('pullRequestFromGraphQlNode', () {
    Map<String, dynamic> fullNode() => <String, dynamic>{
      'number': 17,
      'title': 'GraphQL PR',
      'isDraft': true,
      'author': {'login': 'Carol', 'avatarUrl': 'https://c'},
      'createdAt': '2024-02-01T00:00:00Z',
      'updatedAt': '2024-02-02T00:00:00Z',
      'url': 'https://gh/p/17',
      'id': 'NODE_17',
      'headRefOid': 'deadbeef',
      'baseRefName': 'main',
      'headRefName': 'feat',
      'mergedAt': '2024-02-03T00:00:00Z',
      'mergeStateStatus': 'BLOCKED',
      'changedFiles': 4,
      'additions': 50,
      'deletions': 12,
      'comments': {'totalCount': 9},
      'commitsTotal': {'totalCount': 3},
      'reviewRequests': {
        'nodes': [
          {
            'requestedReviewer': {
              'login': 'reviewer-a',
              'avatarUrl': 'https://ra',
            },
          },
          {
            // Team reviewer — exposes `name` + `slug`, not `login`.
            'requestedReviewer': {
              'name': 'Frontend Platform',
              'slug': 'frontend-platform',
              'avatarUrl': 'https://team',
            },
          },
          {
            // Null reviewer slot — skipped.
            'requestedReviewer': null,
          },
          {
            // Empty login + empty name — skipped.
            'requestedReviewer': {'login': '', 'name': ''},
          },
        ],
      },
      'lastCommit': {
        'nodes': [
          {
            'commit': {
              'statusCheckRollup': {'state': 'FAILURE'},
            },
          },
        ],
      },
      'latestReviews': {
        'nodes': [
          {
            'author': {'login': 'Carol'},
          },
          {
            'author': {'login': 'other'},
          },
        ],
      },
    };

    test('maps every field on a fully-populated node', () {
      final pr = pullRequestFromGraphQlNode(
        fullNode(),
        repoFullName: 'o/r',
        viewerLogin: 'carol',
      );

      expect(pr.number, 17);
      expect(pr.id, 17);
      expect(pr.title, 'GraphQL PR');
      expect(pr.body, '');
      expect(pr.state, PrState.open);
      expect(pr.isDraft, isTrue);
      expect(pr.author, const PrUser(login: 'Carol', avatarUrl: 'https://c'));
      expect(pr.createdAt, DateTime.utc(2024, 2, 1));
      expect(pr.updatedAt, DateTime.utc(2024, 2, 2));
      expect(pr.mergedAt, DateTime.utc(2024, 2, 3));
      expect(pr.repoFullName, 'o/r');
      expect(pr.htmlUrl, 'https://gh/p/17');
      expect(pr.externalId, 'NODE_17');
      expect(pr.headSha, 'deadbeef');
      expect(pr.baseRef, 'main');
      expect(pr.headRef, 'feat');
      expect(pr.changedFiles, 4);
      expect(pr.commitsCount, 3);
      expect(pr.additions, 50);
      expect(pr.deletions, 12);
      expect(pr.commentsCount, 9);
      expect(pr.checksStatus, PrChecksStatus.failing);
      expect(pr.mergeableState, PrMergeableState.blocked);
      // viewer authored a latest review → reviewedByMe true.
      expect(pr.reviewedByMe, isTrue);
      // Users stay in requestedReviewers; teams go to requestedTeamSlugs.
      expect(pr.requestedReviewers, [
        const PrUser(login: 'reviewer-a', avatarUrl: 'https://ra'),
      ]);
      expect(pr.requestedTeamSlugs, ['frontend-platform']);
    });

    test('reviewedByMe is false when viewer login is null or empty', () {
      for (final viewer in const <String?>[null, '']) {
        final pr = pullRequestFromGraphQlNode(
          fullNode(),
          repoFullName: 'o/r',
          viewerLogin: viewer,
        );
        expect(pr.reviewedByMe, isFalse, reason: 'viewer=$viewer');
      }
    });

    test('reviewedByMe is false when latestReviews has no matching author', () {
      final pr = pullRequestFromGraphQlNode(
        fullNode(),
        repoFullName: 'o/r',
        viewerLogin: 'nobody',
      );
      expect(pr.reviewedByMe, isFalse);
    });

    test('falls back to defaults on a node missing optional fields', () {
      // PullRequest asserts number > 0 and title non-empty, so supply those;
      // every other optional field stays absent to exercise the fallbacks.
      final pr = pullRequestFromGraphQlNode(<String, dynamic>{
        'number': 1,
        'title': 't',
      }, repoFullName: 'o/r');
      expect(pr.number, 1);
      expect(pr.title, 't');
      expect(pr.isDraft, isFalse);
      expect(pr.author, const PrUser(login: '', avatarUrl: ''));
      expect(pr.createdAt, isNull);
      expect(pr.headSha, '');
      expect(pr.commitsCount, 0);
      expect(pr.checksStatus, PrChecksStatus.none);
      // Absent mergeStateStatus → null → lowercased null → unrecognized.
      expect(pr.mergeableState, PrMergeableState.unrecognized);
      expect(pr.requestedReviewers, isEmpty);
    });

    test('ignores review request entries that are not maps', () {
      final node = <String, dynamic>{
        'number': 1,
        'title': 't',
        'repository': {'nameWithOwner': 'o/r'},
        'reviewRequests': {
          'nodes': [
            'not-a-map',
            {
              'requestedReviewer': {'login': 'real'},
            },
          ],
        },
      };
      final pr = pullRequestFromGraphQlNode(node, repoFullName: 'o/r');
      expect(pr.requestedReviewers.map((u) => u.login).toList(), ['real']);
    });
  });

  group('priorityReviewFromSearchNode', () {
    test('maps a usable search node into a PR plus repo full name', () {
      final node = <String, dynamic>{
        'number': 55,
        'title': 'Search hit',
        'isDraft': false,
        'createdAt': '2024-03-01T00:00:00Z',
        'updatedAt': '2024-03-02T00:00:00Z',
        'url': 'https://gh/p/55',
        'headRefName': 'branch',
        'additions': 10,
        'deletions': 4,
        'comments': {'totalCount': 2},
        'repository': {'nameWithOwner': 'o/search-repo'},
      };
      final result = priorityReviewFromSearchNode(node);
      expect(result, isNotNull);
      final pr = result!.pr;
      expect(pr.number, 55);
      expect(pr.title, 'Search hit');
      expect(pr.repoFullName, 'o/search-repo');
      expect(result.repoFullName, 'o/search-repo');
      expect(pr.headRef, 'branch');
      expect(pr.additions, 10);
      expect(pr.deletions, 4);
      expect(pr.commentsCount, 2);
      expect(pr.author, isNull);
      expect(pr.state, PrState.open);
    });

    test('returns null when number is non-positive', () {
      expect(
        priorityReviewFromSearchNode({
          'number': 0,
          'title': 't',
          'repository': {'nameWithOwner': 'o/r'},
        }),
        isNull,
      );
    });

    test('returns null when title is empty', () {
      expect(
        priorityReviewFromSearchNode({
          'number': 1,
          'title': '',
          'repository': {'nameWithOwner': 'o/r'},
        }),
        isNull,
      );
    });

    test('returns null when repo full name is empty', () {
      expect(
        priorityReviewFromSearchNode({
          'number': 1,
          'title': 't',
          'repository': {'nameWithOwner': ''},
        }),
        isNull,
      );
      // And when repository / nameWithOwner are absent entirely.
      expect(
        priorityReviewFromSearchNode(<String, dynamic>{
          'number': 1,
          'title': 't',
        }),
        isNull,
      );
    });
  });

  group('prReviewerStateFromGraphQl', () {
    test('maps APPROVED / CHANGES_REQUESTED / COMMENTED', () {
      expect(
        prReviewerStateFromGraphQl('APPROVED'),
        PrReviewSubmissionState.approved,
      );
      expect(
        prReviewerStateFromGraphQl('CHANGES_REQUESTED'),
        PrReviewSubmissionState.changesRequested,
      );
      expect(
        prReviewerStateFromGraphQl('COMMENTED'),
        PrReviewSubmissionState.commented,
      );
    });

    test('maps DISMISSED / PENDING / unknown to pending', () {
      expect(
        prReviewerStateFromGraphQl('DISMISSED'),
        PrReviewSubmissionState.pending,
      );
      expect(
        prReviewerStateFromGraphQl('PENDING'),
        PrReviewSubmissionState.pending,
      );
      expect(
        prReviewerStateFromGraphQl('???'),
        PrReviewSubmissionState.pending,
      );
    });
  });

  group('codeOwnerIdentitiesFromReviewState', () {
    test(
      'collects code-owner users and teams, lowercased, skipping empties',
      () {
        const raw = GitHubPrReviewState(
          pendingUsers: [
            GitHubPendingUserRequest(
              login: 'Alice',
              avatarUrl: '',
              asCodeOwner: true,
            ),
            GitHubPendingUserRequest(
              login: 'Bob',
              avatarUrl: '',
              asCodeOwner: false,
            ),
            GitHubPendingUserRequest(
              login: '',
              avatarUrl: '',
              asCodeOwner: true,
            ),
          ],
          pendingTeams: [
            GitHubPendingTeamRequest(
              name: 'Frontend',
              slug: 'Frontend-Platform',
              asCodeOwner: true,
            ),
            GitHubPendingTeamRequest(
              name: 'Backend',
              slug: '',
              asCodeOwner: true,
            ),
          ],
        );
        expect(codeOwnerIdentitiesFromReviewState(raw), {
          'user:alice',
          'team:frontend-platform',
        });
      },
    );

    test('returns empty when nothing is flagged as code owner', () {
      const raw = GitHubPrReviewState(
        pendingUsers: [
          GitHubPendingUserRequest(
            login: 'Alice',
            avatarUrl: '',
            asCodeOwner: false,
          ),
        ],
      );
      expect(codeOwnerIdentitiesFromReviewState(raw), isEmpty);
    });
  });

  group('prReviewersFromReviewState', () {
    test('pending users and teams become pending rows', () {
      const raw = GitHubPrReviewState(
        pendingUsers: [
          GitHubPendingUserRequest(
            login: 'Alice',
            avatarUrl: 'https://a',
            asCodeOwner: true,
          ),
        ],
        pendingTeams: [
          GitHubPendingTeamRequest(
            name: 'Frontend',
            slug: 'fe',
            asCodeOwner: false,
            avatarUrl: 'https://t/fe',
          ),
        ],
      );
      final reviewers = prReviewersFromReviewState(raw);
      expect(reviewers, hasLength(2));
      final user = reviewers.whereType<PrUserReviewer>().single;
      expect(user.user.login, 'Alice');
      expect(user.isCodeOwner, isTrue);
      expect(user.state, PrReviewSubmissionState.pending);
      final team = reviewers.whereType<PrTeamReviewer>().single;
      expect(team.slug, 'fe');
      expect(team.avatarUrl, 'https://t/fe');
      expect(team.isCodeOwner, isFalse);
      expect(team.state, PrReviewSubmissionState.pending);
    });

    test('skips pending users/teams with empty login/slug', () {
      const raw = GitHubPrReviewState(
        pendingUsers: [
          GitHubPendingUserRequest(login: '', avatarUrl: '', asCodeOwner: true),
        ],
        pendingTeams: [
          GitHubPendingTeamRequest(name: 'x', slug: '', asCodeOwner: true),
        ],
      );
      expect(prReviewersFromReviewState(raw), isEmpty);
    });

    test('a completed individual review overrides a pending row', () {
      const raw = GitHubPrReviewState(
        pendingUsers: [
          GitHubPendingUserRequest(
            login: 'Alice',
            avatarUrl: 'https://a',
            asCodeOwner: false,
          ),
        ],
        completedReviews: [
          GitHubCompletedReview(
            authorLogin: 'alice',
            authorAvatarUrl: 'https://a',
            state: 'APPROVED',
          ),
        ],
      );
      final reviewers = prReviewersFromReviewState(raw);
      final user = reviewers.whereType<PrUserReviewer>().single;
      expect(user.user.login, 'alice');
      expect(user.state, PrReviewSubmissionState.approved);
    });

    test('knownCodeOwnerIds marks a completed reviewer as code owner', () {
      const raw = GitHubPrReviewState(
        completedReviews: [
          GitHubCompletedReview(
            authorLogin: 'Bob',
            authorAvatarUrl: '',
            state: 'COMMENTED',
          ),
        ],
      );
      final reviewers = prReviewersFromReviewState(
        raw,
        knownCodeOwnerIds: const {'user:bob'},
      );
      expect(reviewers.whereType<PrUserReviewer>().single.isCodeOwner, isTrue);
    });

    test('a completed review on behalf of a team merges into the team row', () {
      const raw = GitHubPrReviewState(
        pendingTeams: [
          GitHubPendingTeamRequest(
            name: 'Frontend',
            slug: 'fe',
            asCodeOwner: true,
          ),
        ],
        completedReviews: [
          GitHubCompletedReview(
            authorLogin: 'dave',
            authorAvatarUrl: 'https://d',
            state: 'CHANGES_REQUESTED',
            onBehalfOf: [GitHubReviewTeamRef(name: 'Frontend', slug: 'fe')],
          ),
        ],
      );
      final reviewers = prReviewersFromReviewState(raw);
      final team = reviewers.whereType<PrTeamReviewer>().single;
      expect(team.slug, 'fe');
      expect(team.name, 'Frontend');
      expect(team.isCodeOwner, isTrue);
      expect(team.state, PrReviewSubmissionState.changesRequested);
      expect(team.reviewedBy?.login, 'dave');
    });

    test(
      'a completed team review creates the team row when none was pending',
      () {
        const raw = GitHubPrReviewState(
          completedReviews: [
            GitHubCompletedReview(
              authorLogin: 'eve',
              authorAvatarUrl: '',
              state: 'APPROVED',
              onBehalfOf: [GitHubReviewTeamRef(name: 'New Team', slug: 'new')],
            ),
          ],
        );
        final team = prReviewersFromReviewState(
          raw,
        ).whereType<PrTeamReviewer>().single;
        expect(team.slug, 'new');
        expect(team.name, 'New Team');
        expect(team.state, PrReviewSubmissionState.approved);
      },
    );

    test('users render before teams', () {
      const raw = GitHubPrReviewState(
        pendingUsers: [
          GitHubPendingUserRequest(
            login: 'zoe',
            avatarUrl: '',
            asCodeOwner: false,
          ),
        ],
        pendingTeams: [
          GitHubPendingTeamRequest(
            name: 'AAA',
            slug: 'aaa',
            asCodeOwner: false,
          ),
        ],
      );
      final reviewers = prReviewersFromReviewState(raw);
      expect(reviewers.first, isA<PrUserReviewer>());
      expect(reviewers.last, isA<PrTeamReviewer>());
    });
  });

  group('prFileFromGitHub', () {
    test('maps fields including renamed status and previous filename', () {
      const f = GitHubPullRequestFile(
        filename: 'a/b.dart',
        status: 'renamed',
        additions: 3,
        deletions: 1,
        changes: 4,
        patch: '@@ diff @@',
        previousFilename: 'a/c.dart',
      );
      final prFile = prFileFromGitHub(f);
      expect(prFile.filename, 'a/b.dart');
      expect(prFile.status, PrFileStatus.renamed);
      expect(prFile.additions, 3);
      expect(prFile.deletions, 1);
      expect(prFile.patch, '@@ diff @@');
      expect(prFile.previousFilename, 'a/c.dart');
    });

    test('unknown status falls back to modified', () {
      const f = GitHubPullRequestFile(
        filename: 'x',
        status: 'wat',
        additions: 0,
        deletions: 0,
        changes: 0,
        patch: '',
      );
      expect(prFileFromGitHub(f).status, PrFileStatus.modified);
    });
  });

  group('prCommitFromGitHub', () {
    test('maps sha, message, author, date', () {
      final c = GitHubCommit(
        sha: 'abc123',
        message: 'Fix bug\n\nBody',
        authorName: 'A',
        authorEmail: 'a@x',
        author: const GitHubUser(login: 'alice', avatarUrl: 'https://a'),
        committedAt: DateTime.utc(2024, 5, 1),
      );
      final commit = prCommitFromGitHub(c);
      expect(commit.sha, 'abc123');
      expect(commit.message, 'Fix bug\n\nBody');
      expect(
        commit.author,
        const PrUser(login: 'alice', avatarUrl: 'https://a'),
      );
      expect(commit.date, DateTime.utc(2024, 5, 1));
    });

    test('null author maps to an empty PrUser', () {
      const c = GitHubCommit(
        sha: 's',
        message: 'm',
        authorName: '',
        authorEmail: '',
      );
      expect(
        prCommitFromGitHub(c).author,
        const PrUser(login: '', avatarUrl: ''),
      );
    });
  });

  group('prCodeReviewCommentFromGitHub', () {
    test('maps all fields and prefers line over originalLine', () {
      final c = GitHubReviewComment(
        id: 99,
        body: 'nit',
        path: 'lib/a.dart',
        diffHunk: '@@ hunk @@',
        line: 30,
        originalLine: 28,
        startLine: 20,
        side: 'RIGHT',
        inReplyToId: 5,
        user: const GitHubUser(login: 'rev', avatarUrl: 'https://r'),
        createdAt: DateTime.utc(2024, 6, 1),
        reactions: const GitHubReactionSummary(totalCount: 1, plusOne: 1),
      );
      final comment = prCodeReviewCommentFromGitHub(c);
      expect(comment.id, 99);
      expect(comment.body, 'nit');
      expect(comment.path, 'lib/a.dart');
      expect(comment.position, 30);
      expect(comment.createdAt, DateTime.utc(2024, 6, 1));
      expect(comment.side, 'RIGHT');
      expect(comment.inReplyToId, 5);
      expect(comment.startLine, 20);
      expect(comment.diffHunk, '@@ hunk @@');
      expect(comment.line, 30);
      expect(comment.originalLine, 28);
      expect(comment.user, const PrUser(login: 'rev', avatarUrl: 'https://r'));
      expect(comment.reactions.single.content, '+1');
    });

    test('falls back to originalLine when line is null', () {
      const c = GitHubReviewComment(
        id: 1,
        body: '',
        path: '',
        diffHunk: '',
        originalLine: 12,
      );
      expect(prCodeReviewCommentFromGitHub(c).position, 12);
    });
  });

  group('checkRunFromGitHub', () {
    test('maps status, conclusion, output and checkSuiteId', () {
      final c = GitHubCheckRun(
        id: 7,
        name: 'ci',
        status: GitHubCheckStatus.completed,
        conclusion: GitHubCheckConclusion.success,
        appName: 'GitHub Actions',
        htmlUrl: 'https://gh/ci/7',
        completedAt: DateTime.utc(2024, 7, 1),
        output: 'all good',
        checkSuiteId: 9001,
      );
      final run = checkRunFromGitHub(c);
      expect(run.name, 'ci');
      expect(run.status, CheckRunStatus.completed);
      expect(run.conclusion, CheckRunConclusion.success);
      expect(run.htmlUrl, 'https://gh/ci/7');
      expect(run.completedAt, DateTime.utc(2024, 7, 1));
      expect(run.output, 'all good');
      expect(run.checkSuiteId, 9001);
    });

    test('maps every status enum value', () {
      final mapping = <GitHubCheckStatus, CheckRunStatus>{
        GitHubCheckStatus.queued: CheckRunStatus.queued,
        GitHubCheckStatus.inProgress: CheckRunStatus.inProgress,
        GitHubCheckStatus.completed: CheckRunStatus.completed,
        GitHubCheckStatus.unknown: CheckRunStatus.queued,
      };
      mapping.forEach((ghStatus, expected) {
        final c = GitHubCheckRun(
          id: 1,
          name: 'c',
          status: ghStatus,
          conclusion: GitHubCheckConclusion.none,
          appName: '',
          htmlUrl: '',
        );
        expect(checkRunFromGitHub(c).status, expected, reason: '$ghStatus');
      });
    });

    test('maps every conclusion enum value', () {
      final mapping = <GitHubCheckConclusion, CheckRunConclusion?>{
        GitHubCheckConclusion.success: CheckRunConclusion.success,
        GitHubCheckConclusion.failure: CheckRunConclusion.failure,
        GitHubCheckConclusion.neutral: CheckRunConclusion.neutral,
        GitHubCheckConclusion.cancelled: CheckRunConclusion.cancelled,
        GitHubCheckConclusion.skipped: CheckRunConclusion.skipped,
        GitHubCheckConclusion.timedOut: CheckRunConclusion.timedOut,
        GitHubCheckConclusion.actionRequired: CheckRunConclusion.actionRequired,
        GitHubCheckConclusion.stale: CheckRunConclusion.stale,
        GitHubCheckConclusion.none: null,
      };
      mapping.forEach((ghConclusion, expected) {
        final c = GitHubCheckRun(
          id: 1,
          name: 'c',
          status: GitHubCheckStatus.completed,
          conclusion: ghConclusion,
          appName: '',
          htmlUrl: '',
        );
        expect(
          checkRunFromGitHub(c).conclusion,
          expected,
          reason: '$ghConclusion',
        );
      });
    });
  });

  group('prReviewSubmissionFromGitHub', () {
    test('maps approved state and author', () {
      final r = GitHubReview(
        id: 1,
        state: GitHubReviewState.approved,
        body: 'lgtm',
        submittedAt: DateTime.utc(2024, 8, 1),
        user: const GitHubUser(login: 'rev', avatarUrl: 'https://r'),
      );
      final sub = prReviewSubmissionFromGitHub(r);
      expect(sub.id, 1);
      expect(sub.state, PrReviewSubmissionState.approved);
      expect(sub.body, 'lgtm');
      expect(sub.author, const PrUser(login: 'rev', avatarUrl: 'https://r'));
      expect(sub.submittedAt, DateTime.utc(2024, 8, 1));
    });

    test('maps every review state (REST shape)', () {
      final cases = <GitHubReviewState, PrReviewSubmissionState>{
        GitHubReviewState.approved: PrReviewSubmissionState.approved,
        GitHubReviewState.changesRequested:
            PrReviewSubmissionState.changesRequested,
        GitHubReviewState.commented: PrReviewSubmissionState.commented,
        GitHubReviewState.dismissed: PrReviewSubmissionState.commented,
        GitHubReviewState.pending: PrReviewSubmissionState.commented,
        GitHubReviewState.unknown: PrReviewSubmissionState.commented,
      };
      cases.forEach((ghState, expected) {
        final r = GitHubReview(
          id: 1,
          state: ghState,
          body: '',
          submittedAt: null,
        );
        expect(
          prReviewSubmissionFromGitHub(r).state,
          expected,
          reason: '$ghState',
        );
      });
    });

    test('null user maps to an empty PrUser', () {
      const r = GitHubReview(
        id: 2,
        state: GitHubReviewState.commented,
        body: '',
        submittedAt: null,
      );
      expect(
        prReviewSubmissionFromGitHub(r).author,
        const PrUser(login: '', avatarUrl: ''),
      );
    });
  });

  group('prTimelineEventFromGitHub', () {
    test('maps a user review request', () {
      final e = GitHubTimelineEvent(
        event: 'review_requested',
        actor: const GitHubUser(login: 'alice', avatarUrl: 'https://a'),
        requestedReviewer: const GitHubUser(
          login: 'bob',
          avatarUrl: 'https://b',
        ),
        createdAt: DateTime.utc(2026, 7, 1),
      );
      final mapped = prTimelineEventFromGitHub(e);
      expect(mapped, isNotNull);
      expect(mapped!.kind, PrTimelineEventKind.reviewRequested);
      expect(mapped.actor?.login, 'alice');
      expect(mapped.reviewerName, 'bob');
      expect(mapped.reviewerIsTeam, isFalse);
      expect(mapped.reviewerAvatarUrl, 'https://b');
      expect(mapped.createdAt, DateTime.utc(2026, 7, 1));
    });

    test('maps a team request removal', () {
      const e = GitHubTimelineEvent(
        event: 'review_request_removed',
        actor: GitHubUser(login: 'alice', avatarUrl: ''),
        requestedTeamName: 'Platform',
        requestedTeamAvatarUrl: 'https://t/platform',
      );
      final mapped = prTimelineEventFromGitHub(e);
      expect(mapped!.kind, PrTimelineEventKind.reviewRequestRemoved);
      expect(mapped.reviewerName, 'Platform');
      expect(mapped.reviewerIsTeam, isTrue);
      expect(mapped.reviewerAvatarUrl, 'https://t/platform');
    });

    test('returns null for event kinds the feed does not consume', () {
      const e = GitHubTimelineEvent(event: 'labeled');
      expect(prTimelineEventFromGitHub(e), isNull);
    });
  });

  group('issueCommentFromGitHub', () {
    test('maps id, body, user, createdAt and reactions', () {
      final c = GitHubIssueComment(
        id: 77,
        body: 'comment',
        user: const GitHubUser(login: 'u', avatarUrl: 'https://u'),
        createdAt: DateTime.utc(2024, 9, 1),
        reactions: const GitHubReactionSummary(totalCount: 2, laugh: 2),
      );
      final comment = issueCommentFromGitHub(c);
      expect(comment.id, 77);
      expect(comment.body, 'comment');
      expect(comment.user, const PrUser(login: 'u', avatarUrl: 'https://u'));
      expect(comment.createdAt, DateTime.utc(2024, 9, 1));
      expect(comment.reactions.single.content, 'laugh');
    });

    test('null user maps to an empty PrUser and no reactions', () {
      const c = GitHubIssueComment(id: 1, body: '');
      final comment = issueCommentFromGitHub(c);
      expect(comment.user, const PrUser(login: '', avatarUrl: ''));
      expect(comment.reactions, isEmpty);
    });
  });
  group('jobRunDetailFromGitHub', () {
    test('maps status, conclusion, steps and log passthrough', () {
      final job = GitHubJobRun(
        id: 101,
        runId: 7,
        name: 'build',
        status: 'completed',
        conclusion: 'failure',
        htmlUrl: 'https://github.com/o/c/actions/runs/7/job/101',
        steps: [
          GitHubJobStep(
            number: 1,
            name: 'Set up job',
            status: 'completed',
            conclusion: 'success',
            startedAt: DateTime.utc(2025, 1, 1, 10),
            completedAt: DateTime.utc(2025, 1, 1, 10, 0, 10),
          ),
          const GitHubJobStep(
            number: 2,
            name: 'Run tests',
            status: 'completed',
            conclusion: 'failure',
          ),
        ],
      );
      final detail = jobRunDetailFromGitHub(
        job,
        logs: 'some log text',
        logsTruncated: true,
      );
      expect(detail.jobId, 101);
      expect(detail.status, CheckRunStatus.completed);
      expect(detail.conclusion, CheckRunConclusion.failure);
      expect(detail.htmlUrl, endsWith('/job/101'));
      expect(detail.steps, hasLength(2));
      expect(detail.steps.first.status, CheckRunStatus.completed);
      expect(detail.steps.first.conclusion, CheckRunConclusion.success);
      expect(detail.steps.first.startedAt, DateTime.utc(2025, 1, 1, 10));
      expect(detail.steps.last.conclusion, CheckRunConclusion.failure);
      expect(detail.logs, 'some log text');
      expect(detail.logsTruncated, isTrue);
      expect(detail.isComplete, isTrue);
    });

    test('running job has null conclusion and null logs', () {
      const job = GitHubJobRun(
        id: 102,
        runId: 7,
        name: 'build',
        status: 'in_progress',
      );
      final detail = jobRunDetailFromGitHub(job);
      expect(detail.status, CheckRunStatus.inProgress);
      expect(detail.conclusion, isNull);
      expect(detail.logs, isNull);
      expect(detail.logsTruncated, isFalse);
      expect(detail.isComplete, isFalse);
    });
  });
}
