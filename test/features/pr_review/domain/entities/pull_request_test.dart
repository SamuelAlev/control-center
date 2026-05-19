import 'package:cc_domain/features/pr_review/domain/entities/pr_user.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime.now();
  const author = PrUser(login: 'dev', avatarUrl: 'https://avat.ar/dev');

  PullRequest createPr({
    int id = 1,
    int number = 42,
    String title = 'Add feature X',
    String body = 'This PR adds feature X',
    PrState state = PrState.open,
    bool isDraft = false,
    PrUser? authorParam,
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
      author: authorParam ?? author,
      createdAt: createdAt,
      updatedAt: updatedAt,
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

  group('PullRequest constructor', () {
    test('creates instance with all fields', () {
      const reviewers = [PrUser(login: 'r1', avatarUrl: '')];
      const assignees = [PrUser(login: 'a1', avatarUrl: '')];
      final mergedAt = DateTime(2025, 1, 1);

      final pr = PullRequest(
        id: 10,
        number: 5,
        title: 'Fix bug',
        body: 'Fixes issue',
        state: PrState.open,
        isDraft: true,
        author: author,
        createdAt: now,
        updatedAt: now,
        repoFullName: 'org/repo',
        htmlUrl: 'https://github.com/org/repo/pull/5',
        nodeId: 'node-1',
        headSha: 'sha123',
        baseRef: 'main',
        headRef: 'fix/bug',
        requestedReviewers: reviewers,
        assignees: assignees,
        mergedAt: mergedAt,
      );

      expect(pr.id, 10);
      expect(pr.number, 5);
      expect(pr.title, 'Fix bug');
      expect(pr.body, 'Fixes issue');
      expect(pr.state, PrState.open);
      expect(pr.isDraft, isTrue);
      expect(pr.author, author);
      expect(pr.createdAt, now);
      expect(pr.updatedAt, now);
      expect(pr.repoFullName, 'org/repo');
      expect(pr.htmlUrl, 'https://github.com/org/repo/pull/5');
      expect(pr.nodeId, 'node-1');
      expect(pr.headSha, 'sha123');
      expect(pr.baseRef, 'main');
      expect(pr.headRef, 'fix/bug');
      expect(pr.requestedReviewers, reviewers);
      expect(pr.assignees, assignees);
      expect(pr.mergedAt, mergedAt);
    });

    test('defaults for optional fields', () {
      final pr = PullRequest(
        id: 1,
        number: 1,
        title: 'T',
        body: '',
        state: PrState.open,
        isDraft: false,
        author: null,
        createdAt: null,
        updatedAt: null,
        repoFullName: 'o/r',
        htmlUrl: '',
      );

      expect(pr.nodeId, '');
      expect(pr.headSha, '');
      expect(pr.baseRef, '');
      expect(pr.headRef, '');
      expect(pr.requestedReviewers, isEmpty);
      expect(pr.assignees, isEmpty);
      expect(pr.mergedAt, isNull);
      expect(pr.author, isNull);
    });

    test('throws assertion error for number <= 0', () {
      expect(
        () => PullRequest(
          id: 1,
          number: 0,
          title: 'Title',
          body: '',
          state: PrState.open,
          isDraft: false,
          author: null,
          createdAt: null,
          updatedAt: null,
          repoFullName: 'o/r',
          htmlUrl: '',
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('throws assertion error for empty title', () {
      expect(
        () => PullRequest(
          id: 1,
          number: 1,
          title: '',
          body: '',
          state: PrState.open,
          isDraft: false,
          author: null,
          createdAt: null,
          updatedAt: null,
          repoFullName: 'o/r',
          htmlUrl: '',
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('PullRequest == and hashCode', () {
    test('identical instances are equal', () {
      final a = createPr();
      final b = createPr();
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('different id makes unequal', () {
      final a = createPr(id: 1);
      final b = createPr(id: 2);
      expect(a, isNot(equals(b)));
    });

    test('same id but different other fields are equal (identity by id)', () {
      final a = createPr(id: 1, title: 'A');
      final b = createPr(id: 1, title: 'B');
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('self equality', () {
      final a = createPr();
      expect(a, equals(a));
    });
  });

  group('PullRequest computed properties', () {
    test('isOpen returns true for open state', () {
      expect(createPr(state: PrState.open).isOpen, isTrue);
      expect(createPr(state: PrState.closed).isOpen, isFalse);
      expect(createPr(state: PrState.merged).isOpen, isFalse);
    });

    test('isClosed returns true for closed state', () {
      expect(createPr(state: PrState.closed).isClosed, isTrue);
      expect(createPr(state: PrState.open).isClosed, isFalse);
      expect(createPr(state: PrState.merged).isClosed, isFalse);
    });

    test('isMerged returns true for merged state', () {
      expect(createPr(state: PrState.merged).isMerged, isTrue);
      expect(createPr(state: PrState.open).isMerged, isFalse);
      expect(createPr(state: PrState.closed).isMerged, isFalse);
    });

    test('canMerge is true when open and not draft', () {
      expect(createPr(state: PrState.open, isDraft: false).canMerge, isTrue);
    });

    test('canMerge is false when closed', () {
      expect(createPr(state: PrState.closed, isDraft: false).canMerge, isFalse);
    });

    test('canMerge is false when draft', () {
      expect(createPr(state: PrState.open, isDraft: true).canMerge, isFalse);
    });

    test('canMerge is false when merged', () {
      expect(createPr(state: PrState.merged).canMerge, isFalse);
    });

    test('isStale returns false for recently updated PR', () {
      final recentPr = createPr(
        createdAt: now,
        updatedAt: now.subtract(const Duration(hours: 1)),
      );
      expect(recentPr.isStale(const Duration(hours: 24)), isFalse);
    });

    test('isStale returns true for old PR', () {
      final oldPr = createPr(
        createdAt: now,
        updatedAt: now.subtract(const Duration(days: 30)),
      );
      expect(oldPr.isStale(const Duration(hours: 24)), isTrue);
    });

    test('isStale uses createdAt when updatedAt is null', () {
      final pr = createPr(
        updatedAt: null,
        createdAt: now.subtract(const Duration(days: 10)),
      );
      expect(pr.isStale(const Duration(hours: 24)), isTrue);
    });

    test('isStale returns false when both timestamps are null', () {
      final pr = createPr(createdAt: null, updatedAt: null);
      expect(pr.isStale(const Duration(hours: 24)), isFalse);
    });

    test('isStale returns false when duration equals threshold', () {
      final recent = DateTime.now().subtract(const Duration(hours: 23, minutes: 59));
      final pr = createPr(createdAt: recent, updatedAt: recent);
      expect(pr.isStale(const Duration(hours: 24)), isFalse);
    });

    test('isStale returns true just past threshold boundary', () {
      final old = DateTime.now().subtract(const Duration(hours: 25));
      final pr = createPr(createdAt: old, updatedAt: old);
      expect(pr.isStale(const Duration(hours: 24)), isTrue);
    });

    test('isPriority returns true when reviewers requested', () {
      final pr = createPr(
        requestedReviewers: const [PrUser(login: 'reviewer1', avatarUrl: '')],
      );
      expect(pr.isPriority, isTrue);
    });

    test('isPriority returns false when no reviewers', () {
      final pr = createPr(requestedReviewers: const []);
      expect(pr.isPriority, isFalse);
    });
  });

  group('PrState', () {
    group('name', () {
      test('open returns open', () {
        expect(PrState.open.name, 'open');
      });
      test('closed returns closed', () {
        expect(PrState.closed.name, 'closed');
      });
      test('merged returns merged', () {
        expect(PrState.merged.name, 'merged');
      });
    });

    group('fromString', () {
      test('parses open', () {
        expect(PrStateExtension.fromString('open').name, PrState.open.name);
      });
      test('parses closed', () {
        expect(PrStateExtension.fromString('closed').name, PrState.closed.name);
      });
      test('parses merged', () {
        expect(PrStateExtension.fromString('merged').name, PrState.merged.name);
      });
      test('unknown defaults to open', () {
        expect(PrStateExtension.fromString('bogus').name, PrState.open.name);
      });
      test('empty string defaults to open', () {
        expect(PrStateExtension.fromString('').name, PrState.open.name);
      });
    });
  });


  group('PullRequest copyWith', () {
    test('copyWith overrides additions', () {
      final pr = createPr();
      final copy = pr.copyWith(additions: 500);

      expect(copy.additions, 500);
      expect(copy.deletions, pr.deletions);
      expect(copy.commentsCount, pr.commentsCount);
      expect(copy.changedFiles, pr.changedFiles);
      expect(copy.checksStatus, pr.checksStatus);
      expect(copy.mergeableState, pr.mergeableState);
      expect(copy.reviewedByMe, pr.reviewedByMe);
    });

    test('copyWith overrides deletions', () {
      final pr = createPr();
      final copy = pr.copyWith(deletions: 300);

      expect(copy.deletions, 300);
    });

    test('copyWith overrides commentsCount', () {
      final pr = createPr();
      final copy = pr.copyWith(commentsCount: 5);

      expect(copy.commentsCount, 5);
    });

    test('copyWith overrides changedFiles', () {
      final pr = createPr();
      final copy = pr.copyWith(changedFiles: 20);

      expect(copy.changedFiles, 20);
    });

    test('copyWith overrides checksStatus', () {
      final pr = createPr();
      final copy = pr.copyWith(checksStatus: PrChecksStatus.passing);

      expect(copy.checksStatus, PrChecksStatus.passing);
    });

    test('copyWith overrides mergeableState', () {
      final pr = createPr();
      final copy = pr.copyWith(mergeableState: PrMergeableState.clean);

      expect(copy.mergeableState, PrMergeableState.clean);
    });

    test('copyWith overrides reviewedByMe', () {
      final pr = createPr();
      final copy = pr.copyWith(reviewedByMe: true);

      expect(copy.reviewedByMe, isTrue);
    });

    test('copyWith preserves other fields when overriding', () {
      final pr = createPr(id: 42, state: PrState.closed);
      final copy = pr.copyWith(additions: 999);

      expect(copy.id, 42);
      expect(copy.state, PrState.closed);
      expect(copy.author, author);
    });

    test('copyWith returns instance with same fields when no args', () {
      final pr = createPr(id: 7, title: 'No args copy');
      final copy = pr.copyWith();

      expect(copy, equals(pr));
      expect(identical(copy, pr), isFalse);
    });
  });
}
