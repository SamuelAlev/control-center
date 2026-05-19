import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/features/pr_review/domain/entities/enriched_pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_user.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/usecases/classify_pull_requests_use_case.dart';
import 'package:flutter_test/flutter_test.dart';

Repo _repo(String name) {
  return Repo(
    id: 'repo-$name',
    name: name,
    path: '/repos/$name',
    githubOwner: 'owner',
    githubRepoName: name,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

PullRequest _pr({
  required int number,
  required String title,
  required DateTime createdAt,
  DateTime? updatedAt,
  bool isPriority = false,
  bool isDraft = false,
  List<PrUser>? requestedReviewers,
}) {
  return PullRequest(
    id: number,
    number: number,
    title: title,
    body: 'Body for $title',
    state: PrState.open,
    isDraft: isDraft,
    author: const PrUser(login: 'dev', avatarUrl: ''),
    createdAt: createdAt,
    updatedAt: updatedAt,
    repoFullName: 'owner/repo',
    htmlUrl: 'https://github.com/owner/repo/pull/$number',
    requestedReviewers: requestedReviewers ??
        (isPriority
            ? [const PrUser(login: 'reviewer', avatarUrl: '')]
            : const []),
  );
}

void main() {
  group('ClassifyPullRequestsUseCase', () {
    const useCase = ClassifyPullRequestsUseCase();
    late DateTime now;

    setUp(() {
      now = DateTime(2026, 5, 18);
    });

    test('returns empty PrListData for empty input', () {
      final result = useCase.execute(byRepo: [], now: now);

      expect(result.isEmpty, isTrue);
      expect(result.priorityReviews, isEmpty);
      expect(result.byRepo, isEmpty);
    });

    test('classifies PR as priority when overdue with requested reviewers', () {
      final repo = _repo('test-repo');
      final pr = _pr(
        number: 1,
        title: 'Priority PR',
        createdAt: DateTime(2026, 5, 1),
        updatedAt: DateTime(2026, 5, 1),
        isPriority: true,
      );

      final result = useCase.execute(
        byRepo: [RepoPullRequests(repo: repo, prs: [pr])],
        now: now,
      );

      expect(result.priorityReviews.length, 1);
      expect(result.priorityReviews.first.pr.number, 1);
    });

    test('does not classify recent PR as priority', () {
      final repo = _repo('test-repo');
      final pr = _pr(
        number: 2,
        title: 'Recent PR',
        createdAt: DateTime(2026, 5, 18, 0),
        updatedAt: DateTime(2026, 5, 18, 1),
        isPriority: true,
      );

      final result = useCase.execute(
        byRepo: [RepoPullRequests(repo: repo, prs: [pr])],
        now: now,
      );

      expect(result.priorityReviews, isEmpty);
    });

    test('does not classify non-priority PR as priority even if old', () {
      final repo = _repo('test-repo');
      final pr = _pr(
        number: 3,
        title: 'Old non-priority',
        createdAt: DateTime(2026, 1, 1),
        isPriority: false,
      );

      final result = useCase.execute(
        byRepo: [RepoPullRequests(repo: repo, prs: [pr])],
        now: now,
      );

      expect(result.priorityReviews, isEmpty);
    });

    test('skips draft PRs even with requested reviewers', () {
      final repo = _repo('test-repo');
      final pr = _pr(
        number: 4,
        title: 'Draft PR',
        createdAt: DateTime(2026, 1, 1),
        isPriority: true,
        isDraft: true,
      );

      final result = useCase.execute(
        byRepo: [RepoPullRequests(repo: repo, prs: [pr])],
        now: now,
      );

      expect(result.priorityReviews, isEmpty);
    });

    test('filters priority reviews by currentUserLogin', () {
      final repo = _repo('test-repo');
      final mine = _pr(
        number: 10,
        title: 'Mine',
        createdAt: DateTime(2026, 1, 1),
        requestedReviewers: const [
          PrUser(login: 'me', avatarUrl: ''),
          PrUser(login: 'other', avatarUrl: ''),
        ],
      );
      final notMine = _pr(
        number: 11,
        title: 'Not mine',
        createdAt: DateTime(2026, 1, 1),
        requestedReviewers: const [PrUser(login: 'other', avatarUrl: '')],
      );

      final result = useCase.execute(
        byRepo: [RepoPullRequests(repo: repo, prs: [mine, notMine])],
        currentUserLogin: 'me',
        now: now,
      );

      expect(result.priorityReviews.length, 1);
      expect(result.priorityReviews.first.pr.number, 10);
    });

    test('matches currentUserLogin case-insensitively', () {
      final repo = _repo('test-repo');
      final pr = _pr(
        number: 12,
        title: 'Mixed case',
        createdAt: DateTime(2026, 1, 1),
        requestedReviewers: const [PrUser(login: 'SamuelAlev', avatarUrl: '')],
      );

      final result = useCase.execute(
        byRepo: [RepoPullRequests(repo: repo, prs: [pr])],
        currentUserLogin: 'samuelalev',
        now: now,
      );

      expect(result.priorityReviews.length, 1);
    });

    test('returns byRepo as-is in result', () {
      final repo = _repo('test-repo');
      final prs = [
        _pr(number: 100, title: 'PR 100', createdAt: DateTime(2026, 5, 17)),
      ];
      final byRepo = [RepoPullRequests(repo: repo, prs: prs)];

      final result = useCase.execute(byRepo: byRepo, now: now);

      expect(result.byRepo, equals(byRepo));
    });

    test('handles multiple repos', () {
      final repo1 = _repo('repo1');
      final repo2 = _repo('repo2');
      final pr1 = _pr(
        number: 1,
        title: 'Priority 1',
        createdAt: DateTime(2026, 1, 1),
        isPriority: true,
      );
      final pr2 = _pr(
        number: 2,
        title: 'Normal 2',
        createdAt: DateTime(2026, 5, 17),
      );
      final pr3 = _pr(
        number: 3,
        title: 'Normal 3',
        createdAt: DateTime(2026, 5, 17),
      );

      final result = useCase.execute(
        byRepo: [
          RepoPullRequests(repo: repo1, prs: [pr1]),
          RepoPullRequests(repo: repo2, prs: [pr2, pr3]),
        ],
        now: now,
      );

      expect(result.priorityReviews.length, 1);
      expect(result.byRepo.length, 2);
    });
  });

  group('PrListData', () {
    test('isEmpty returns true when all lists are empty', () {
      const data = PrListData(priorityReviews: [], byRepo: []);
      expect(data.isEmpty, isTrue);
    });

    test('isEmpty returns false when priorityReviews non-empty', () {
      final repo = _repo('test');
      final pr = _pr(number: 1, title: 'PR', createdAt: DateTime(2026, 5, 18));
      final data = PrListData(
        priorityReviews: [PriorityReview(pr: pr, repo: repo)],
        byRepo: const [],
      );
      expect(data.isEmpty, isFalse);
    });

    test('isEmpty returns false when byRepo non-empty', () {
      final repo = _repo('test');
      final data = PrListData(
        priorityReviews: const [],
        byRepo: [RepoPullRequests(repo: repo, prs: const [])],
      );
      expect(data.isEmpty, isFalse);
    });
  });
}
