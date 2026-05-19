import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/features/pr_review/domain/entities/enriched_pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_user.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2025, 5, 18, 9, 0);

  Repo createRepo({
    String id = 'repo-1',
    String name = 'my-repo',
    String path = '/path/to/repo',
    String githubOwner = 'org',
    String githubRepoName = 'my-repo',
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Repo(
      id: id,
      name: name,
      path: path,
      githubOwner: githubOwner,
      githubRepoName: githubRepoName,
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
    );
  }

  PullRequest createPr({
    int id = 1,
    int number = 42,
    String title = 'Add feature X',
    String body = 'This PR adds feature X',
    PrState state = PrState.open,
    bool isDraft = false,
    PrUser? author,
    DateTime? createdAt,
    DateTime? updatedAt,
    String repoFullName = 'org/repo',
    String htmlUrl = 'https://github.com/org/repo/pull/42',
    String nodeId = '',
    String headSha = 'abc123',
    String baseRef = 'main',
    String headRef = 'feature/x',
    List<PrUser> requestedReviewers = const [],
    List<PrUser> assignees = const [],
    DateTime? mergedAt,
  }) {
    return PullRequest(
      id: id,
      number: number,
      title: title,
      body: body,
      state: state,
      isDraft: isDraft,
      author: author,
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
      repoFullName: repoFullName,
      htmlUrl: htmlUrl,
      nodeId: nodeId,
      headSha: headSha,
      baseRef: baseRef,
      headRef: headRef,
      requestedReviewers: requestedReviewers,
      assignees: assignees,
      mergedAt: mergedAt,
    );
  }

  group('EnrichedPullRequest', () {
    test('repoFullName delegates to repo.fullName', () {
      final pr = createPr();
      final repo = createRepo(githubOwner: 'acme', githubRepoName: 'widgets');
      final enriched = NormalPr(pr: pr, repo: repo);
      expect(enriched.repoFullName, 'acme/widgets');
    });

    test('repoOwner delegates to repo.githubOwner', () {
      final pr = createPr();
      final repo = createRepo(githubOwner: 'acme');
      final enriched = NormalPr(pr: pr, repo: repo);
      expect(enriched.repoOwner, 'acme');
    });

    test('repoName delegates to repo.githubRepoName', () {
      final pr = createPr();
      final repo = createRepo(githubRepoName: 'widgets');
      final enriched = NormalPr(pr: pr, repo: repo);
      expect(enriched.repoName, 'widgets');
    });
  });

  group('PriorityReview', () {
    test('constructor stores pr and repo', () {
      final pr = createPr();
      final repo = createRepo();
      final review = PriorityReview(pr: pr, repo: repo);
      expect(review.pr, pr);
      expect(review.repo, repo);
    });

    test('age returns duration since updatedAt', () {
      final updated = now.subtract(const Duration(hours: 2));
      final pr = createPr(updatedAt: updated);
      final repo = createRepo();
      final review = PriorityReview(pr: pr, repo: repo);
      expect(review.age.inHours, greaterThanOrEqualTo(2));
    });

    test('age uses createdAt when updatedAt is null', () {
      final created = now.subtract(const Duration(hours: 3));
      final pr = createPr(updatedAt: null, createdAt: created);
      final repo = createRepo();
      final review = PriorityReview(pr: pr, repo: repo);
      expect(review.age.inHours, greaterThanOrEqualTo(3));
    });

    test('age handles both null gracefully', () {
      final pr = createPr(updatedAt: null, createdAt: null);
      final repo = createRepo();
      final review = PriorityReview(pr: pr, repo: repo);
      expect(review.age, isA<Duration>());
    });

    test('== returns true for same pr id', () {
      final a = PriorityReview(pr: createPr(id: 1), repo: createRepo());
      final b = PriorityReview(pr: createPr(id: 1), repo: createRepo());
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('== returns false for different pr id', () {
      final a = PriorityReview(pr: createPr(id: 1), repo: createRepo());
      final b = PriorityReview(pr: createPr(id: 2), repo: createRepo());
      expect(a, isNot(equals(b)));
    });

    test('== returns false for different runtimeType', () {
      final a = PriorityReview(pr: createPr(id: 1), repo: createRepo());
      final b = StalePr(pr: createPr(id: 1), repo: createRepo());
      expect(a, isNot(equals(b)));
    });

    test('self equality', () {
      final a = PriorityReview(pr: createPr(), repo: createRepo());
      expect(a, equals(a));
    });

    test('constructed instances are equal for same pr id', () {
      final review1 = PriorityReview(pr: createPr(id: 1), repo: createRepo());
      final review2 = PriorityReview(pr: createPr(id: 1), repo: createRepo());
      expect(review1, equals(review2));
    });
  });

  group('StalePr', () {
    test('constructor stores pr and repo', () {
      final pr = createPr();
      final repo = createRepo();
      final stale = StalePr(pr: pr, repo: repo);
      expect(stale.pr, pr);
      expect(stale.repo, repo);
    });

    test('stalenessAge returns duration since updatedAt', () {
      final updated = now.subtract(const Duration(days: 5));
      final pr = createPr(updatedAt: updated);
      final repo = createRepo();
      final stale = StalePr(pr: pr, repo: repo);
      expect(stale.stalenessAge.inDays, greaterThanOrEqualTo(5));
    });

    test('== returns true for same pr id', () {
      final a = StalePr(pr: createPr(id: 5), repo: createRepo());
      final b = StalePr(pr: createPr(id: 5), repo: createRepo());
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('== returns false for different pr id', () {
      final a = StalePr(pr: createPr(id: 5), repo: createRepo());
      final b = StalePr(pr: createPr(id: 6), repo: createRepo());
      expect(a, isNot(equals(b)));
    });

    test('self equality', () {
      final a = StalePr(pr: createPr(), repo: createRepo());
      expect(a, equals(a));
    });
  });

  group('NormalPr', () {
    test('constructor stores pr and repo', () {
      final pr = createPr();
      final repo = createRepo();
      final normal = NormalPr(pr: pr, repo: repo);
      expect(normal.pr, pr);
      expect(normal.repo, repo);
    });

    test('== returns true for same pr id', () {
      final a = NormalPr(pr: createPr(id: 10), repo: createRepo());
      final b = NormalPr(pr: createPr(id: 10), repo: createRepo());
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('== returns false for different pr id', () {
      final a = NormalPr(pr: createPr(id: 10), repo: createRepo());
      final b = NormalPr(pr: createPr(id: 11), repo: createRepo());
      expect(a, isNot(equals(b)));
    });

    test('self equality', () {
      final a = NormalPr(pr: createPr(), repo: createRepo());
      expect(a, equals(a));
    });
  });

  group('RepoPullRequests', () {
    test('constructor stores repo and prs', () {
      final repo = createRepo();
      final prs = [createPr(id: 1), createPr(id: 2)];
      final rpr = RepoPullRequests(repo: repo, prs: prs);
      expect(rpr.repo, repo);
      expect(rpr.prs, prs);
    });

    test('== returns true for same repo', () {
      final repo = createRepo(id: 'r1');
      final a = RepoPullRequests(repo: repo, prs: [createPr(id: 1)]);
      final b = RepoPullRequests(repo: repo, prs: [createPr(id: 2)]);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('== returns false for different repo', () {
      final a = RepoPullRequests(repo: createRepo(id: 'r1'), prs: []);
      final b = RepoPullRequests(repo: createRepo(id: 'r2'), prs: []);
      expect(a, isNot(equals(b)));
    });

    test('constructed instances are equal for same repo', () {
      final repo = createRepo(id: 'r1');
      final rpr1 = RepoPullRequests(repo: repo, prs: []);
      final rpr2 = RepoPullRequests(repo: repo, prs: []);
      expect(rpr1, equals(rpr2));
    });
  });
}
