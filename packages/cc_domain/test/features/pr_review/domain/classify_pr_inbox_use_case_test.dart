import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/features/pr_review/domain/entities/enriched_pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_user.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/usecases/classify_pr_inbox_use_case.dart';
import 'package:test/test.dart';

Repo _repo(String id) => Repo(
  id: id,
  name: id,
  path: '/tmp/$id',
  remoteOwner: 'o',
  remoteName: id,
  createdAt: DateTime(2025),
  updatedAt: DateTime(2025),
);

PullRequest _pr(
  int number, {
  String author = 'me',
  PrState state = PrState.open,
  bool draft = false,
  List<String> requested = const [],
  List<String> requestedTeams = const [],
  PrReviewDecision decision = PrReviewDecision.none,
  PrChecksStatus checks = PrChecksStatus.none,
  bool reviewedByMe = false,
  DateTime? updatedAt,
  DateTime? mergedAt,
}) => PullRequest(
  id: number,
  number: number,
  title: 'PR $number',
  body: '',
  state: state,
  isDraft: draft,
  author: PrUser(login: author, avatarUrl: ''),
  createdAt: DateTime(2026, 1, 1),
  updatedAt: updatedAt ?? DateTime(2026, 1, 2),
  repoFullName: 'o/r1',
  htmlUrl: '',
  requestedReviewers: [
    for (final r in requested) PrUser(login: r, avatarUrl: ''),
  ],
  requestedTeamSlugs: requestedTeams,
  reviewDecision: decision,
  checksStatus: checks,
  reviewedByMe: reviewedByMe,
  mergedAt: mergedAt,
);

void main() {
  const useCase = ClassifyPrInboxUseCase();
  final repo = _repo('r1');
  final now = DateTime(2026, 7, 21, 12);

  PrInboxData classify(
    List<PullRequest> open, {
    List<PullRequest> merged = const [],
    Set<String> reviewedKeys = const {},
    Map<String, Set<String>> viewerTeams = const {},
  }) => useCase.execute(
    openByRepo: [RepoPullRequests(repo: repo, prs: open)],
    mergedByRepo: [RepoPullRequests(repo: repo, prs: merged)],
    viewerLoginByForge: const {ForgeHost.github: 'Me'},
    reviewedByMeKeys: reviewedKeys,
    viewerTeamsByOrg: viewerTeams,
    now: now,
  );

  List<int> numbers(PrInboxData data, PrInboxSection s) =>
      data.of(s).map((i) => i.pr.number).toList();

  group('ClassifyPrInboxUseCase', () {
    test('a pending team I belong to lands in needs-your-review', () {
      final data = classify(
        [
          _pr(1, author: 'alice', requestedTeams: ['frontend-platform']),
        ],
        viewerTeams: {
          'o': {'frontend-platform'},
        },
      );
      expect(numbers(data, PrInboxSection.needsYourReview), [1]);
    });

    test('a team request is ignored when I am not on that team', () {
      final data = classify(
        [
          _pr(1, author: 'alice', requestedTeams: ['frontend-platform']),
        ],
        viewerTeams: {
          'o': {'other-team'},
        },
      );
      expect(data.of(PrInboxSection.needsYourReview), isEmpty);
      expect(data.total, 0);
    });

    test('a satisfied team request (no remaining slug) stays out', () {
      final data = classify(
        [_pr(1, author: 'alice')],
        viewerTeams: {
          'o': {'frontend-platform'},
        },
      );
      expect(data.of(PrInboxSection.needsYourReview), isEmpty);
    });

    test('my own PR that requests my team stays author-centric', () {
      final data = classify(
        [
          _pr(1, requestedTeams: ['frontend-platform']),
        ],
        viewerTeams: {
          'o': {'frontend-platform'},
        },
      );
      expect(data.of(PrInboxSection.needsYourReview), isEmpty);
      expect(numbers(data, PrInboxSection.waitingForReviewers), [1]);
    });

    test('a draft requesting my team stays out of needs-your-review', () {
      final data = classify(
        [
          _pr(
            1,
            author: 'alice',
            requestedTeams: ['frontend-platform'],
            draft: true,
          ),
        ],
        viewerTeams: {
          'o': {'frontend-platform'},
        },
      );
      expect(data.of(PrInboxSection.needsYourReview), isEmpty);
      expect(data.total, 0);
    });

    test('a review request of me lands in needs-your-review', () {
      final data = classify([
        _pr(1, author: 'alice', requested: ['ME']),
      ]);
      expect(numbers(data, PrInboxSection.needsYourReview), [1]);
      expect(data.total, 1);
    });

    test('a draft requesting me stays out of needs-your-review', () {
      final data = classify([
        _pr(1, author: 'alice', requested: ['me'], draft: true),
      ]);
      expect(data.of(PrInboxSection.needsYourReview), isEmpty);
      expect(data.total, 0);
    });

    test('my PR with changes requested is returned to me', () {
      final data = classify([
        _pr(1, decision: PrReviewDecision.changesRequested),
      ]);
      expect(numbers(data, PrInboxSection.returnedToYou), [1]);
    });

    test('my PR with failing checks is returned to me', () {
      final data = classify([_pr(1, checks: PrChecksStatus.failing)]);
      expect(numbers(data, PrInboxSection.returnedToYou), [1]);
    });

    test('my approved PR lands in approved', () {
      final data = classify([_pr(1, decision: PrReviewDecision.approved)]);
      expect(numbers(data, PrInboxSection.approved), [1]);
    });

    test('changes-requested outranks a stale approval signal', () {
      final data = classify([
        _pr(
          1,
          decision: PrReviewDecision.changesRequested,
          checks: PrChecksStatus.passing,
        ),
      ]);
      expect(numbers(data, PrInboxSection.returnedToYou), [1]);
      expect(data.of(PrInboxSection.approved), isEmpty);
    });

    test('my draft lands in drafts, my undecided PR waits for reviewers', () {
      final data = classify([
        _pr(1, draft: true),
        _pr(2),
        _pr(3, decision: PrReviewDecision.reviewRequired),
      ]);
      expect(numbers(data, PrInboxSection.drafts), [1]);
      expect(
        numbers(data, PrInboxSection.waitingForReviewers),
        containsAll([2, 3]),
      );
    });

    test('a PR I reviewed (via key overlay) waits for its author', () {
      final data = classify(
        [_pr(1, author: 'alice')],
        reviewedKeys: {'o/r1#1'},
      );
      expect(numbers(data, PrInboxSection.waitingForAuthor), [1]);
    });

    test('a re-request pulls a reviewed PR back to needs-your-review', () {
      final data = classify(
        [
          _pr(1, author: 'alice', requested: ['me'], reviewedByMe: true),
        ],
        reviewedKeys: {'o/r1#1'},
      );
      expect(numbers(data, PrInboxSection.needsYourReview), [1]);
      expect(data.of(PrInboxSection.waitingForAuthor), isEmpty);
    });

    test("someone else's uninvolved PR is excluded", () {
      final data = classify([
        _pr(1, author: 'alice'),
        _pr(2, author: 'alice', requested: ['bob']),
      ]);
      expect(data.total, 0);
    });

    test('my recent merge lands in merging-and-merged, old ones drop', () {
      final data = classify(
        const [],
        merged: [
          _pr(
            1,
            state: PrState.merged,
            mergedAt: now.subtract(const Duration(days: 2)),
          ),
          _pr(
            2,
            state: PrState.merged,
            mergedAt: now.subtract(const Duration(days: 30)),
          ),
          _pr(
            3,
            author: 'alice',
            state: PrState.merged,
            mergedAt: now.subtract(const Duration(hours: 1)),
          ),
        ],
      );
      expect(numbers(data, PrInboxSection.mergingAndMerged), [1]);
    });

    test('a PR in both feeds is not double-listed', () {
      final data = classify(
        [_pr(1)],
        merged: [
          _pr(
            1,
            state: PrState.merged,
            mergedAt: now.subtract(const Duration(hours: 1)),
          ),
        ],
      );
      expect(numbers(data, PrInboxSection.waitingForReviewers), [1]);
      expect(data.of(PrInboxSection.mergingAndMerged), isEmpty);
    });

    test('sections sort by recency', () {
      final data = classify([
        _pr(1, updatedAt: DateTime(2026, 7, 1)),
        _pr(2, updatedAt: DateTime(2026, 7, 20)),
        _pr(3, updatedAt: DateTime(2026, 7, 10)),
      ]);
      expect(numbers(data, PrInboxSection.waitingForReviewers), [2, 3, 1]);
    });

    test('an unknown login classifies nothing', () {
      final data = useCase.execute(
        openByRepo: [
          RepoPullRequests(repo: repo, prs: [_pr(1)]),
        ],
        viewerLoginByForge: const {ForgeHost.github: ''},
        now: now,
      );
      expect(data.isEmpty, isTrue);
    });
  });
}
