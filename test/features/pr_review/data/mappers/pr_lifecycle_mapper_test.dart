import 'package:cc_domain/features/pr_review/domain/entities/pr_generation.dart';
import 'package:cc_persistence/database/app_database.dart';
import 'package:cc_persistence/mappers/pr_lifecycle_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PrLifecycleMapper', () {
    late PrLifecycleMapper mapper;

    setUp(() {
      mapper = const PrLifecycleMapper();
    });

    test('maps PullRequestsTableData to PrGeneration with draft status', () {
      final now = DateTime(2026, 5, 18);
      final row = PullRequestsTableData(
        id: 'pr-1',
        workspaceId: 'ws-1',
        title: 'My PR',
        body: 'PR body',
        status: 'draft',
        githubPrUrl: null,
        githubPrNumber: null,
        diffSummary: null,
        createdAt: now,
      );

      final pr = mapper.toDomain(row);

      expect(pr.id, 'pr-1');
      expect(pr.workspaceId, 'ws-1');
      expect(pr.title, 'My PR');
      expect(pr.body, 'PR body');
      expect(pr.status, isA<Draft>());
      expect(pr.isDraft, isTrue);
      expect(pr.createdAt, now);
      expect(pr.updatedAt, now);
      expect(pr.branch, isNull);
    });

    test('maps created status correctly', () {
      final now = DateTime(2026, 5, 18);
      final row = PullRequestsTableData(
        id: 'pr-2',
        workspaceId: 'ws-1',
        title: 'Created PR',
        body: '',
        status: 'created',
        createdAt: now,
      );

      final pr = mapper.toDomain(row);

      expect(pr.status, isA<Created>());
      expect(pr.isCreated, isTrue);
      expect(pr.isDraft, isFalse);
    });

    test('maps published status correctly', () {
      final now = DateTime(2026, 5, 18);
      final row = PullRequestsTableData(
        id: 'pr-3',
        workspaceId: 'ws-1',
        title: 'Published PR',
        body: '',
        status: 'published',
        createdAt: now,
      );

      final pr = mapper.toDomain(row);

      expect(pr.status, isA<Published>());
      expect(pr.isPublished, isTrue);
    });

    test('maps unknown status to Draft by default', () {
      final now = DateTime(2026, 5, 18);
      final row = PullRequestsTableData(
        id: 'pr-4',
        workspaceId: 'ws-1',
        title: 'Unknown Status',
        body: '',
        status: 'unknown',
        createdAt: now,
      );

      final pr = mapper.toDomain(row);

      expect(pr.status, isA<Draft>());
      expect(pr.isDraft, isTrue);
    });

    test('toDomainList maps multiple rows', () {
      final now = DateTime(2026, 5, 18);
      final rows = [
        PullRequestsTableData(
          id: 'pr-1',
          workspaceId: 'ws-1',
          title: 'First',
          body: '',
          status: 'draft',
          createdAt: now,
        ),
        PullRequestsTableData(
          id: 'pr-2',
          workspaceId: 'ws-1',
          title: 'Second',
          body: '',
          status: 'created',
          createdAt: now,
        ),
      ];

      final prs = mapper.toDomainList(rows);

      expect(prs.length, 2);
      expect(prs[0].id, 'pr-1');
      expect(prs[1].id, 'pr-2');
      expect(prs[0].status, isA<Draft>());
      expect(prs[1].status, isA<Created>());
    });

    test('toDomainList returns empty list for empty input', () {
      final prs = mapper.toDomainList([]);

      expect(prs, isEmpty);
    });

    test('maps nullable title and body correctly', () {
      final now = DateTime(2026, 5, 18);
      final row = PullRequestsTableData(
        id: 'pr-5',
        workspaceId: 'ws-1',
        title: '',
        body: '',
        status: 'draft',
        createdAt: now,
      );

      final pr = mapper.toDomain(row);

      expect(pr.title, isEmpty);
      expect(pr.body, isEmpty);
    });
  });
}
