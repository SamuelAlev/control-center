import 'package:cc_domain/core/domain/entities/review_space_association.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:cc_persistence/mappers/review_space_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

ReviewSpacesTableData _makeRow({
  String id = 'rc-1',
  String spaceId = 'ch-1',
  String workspaceId = 'ws-1',
  String prExternalId = 'PR_node-1',
  int prNumber = 42,
  String repoFullName = 'owner/repo',
  String status = 'requested',
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  final now = DateTime(2025, 1, 15, 10, 30);
  return ReviewSpacesTableData(
    id: id,
    spaceId: spaceId,
    workspaceId: workspaceId,
    prExternalId: prExternalId,
    prNumber: prNumber,
    repoFullName: repoFullName,
    status: status,
    createdAt: createdAt ?? now,
    updatedAt: updatedAt ?? now,
  );
}

void main() {
  group('toDomain', () {
    test('maps all fields correctly', timeout: const Timeout.factor(2), () {
      final now = DateTime(2025, 3, 1);
      final row = _makeRow(
        id: 'rc-1',
        spaceId: 'ch-1',
        workspaceId: 'ws-1',
        prExternalId: 'PR_abc',
        prNumber: 99,
        repoFullName: 'org/repo',
        status: 'in_progress',
        createdAt: now,
        updatedAt: now,
      );
      final domain = toDomain(row);
      expect(domain.id, 'rc-1');
      expect(domain.spaceId, 'ch-1');
      expect(domain.workspaceId, 'ws-1');
      expect(domain.prExternalId, 'PR_abc');
      expect(domain.prNumber, 99);
      expect(domain.repoFullName, 'org/repo');
      expect(domain.status, ReviewSpaceStatus.inProgress);
      expect(domain.createdAt, now);
      expect(domain.updatedAt, now);
    });

    test(
      'defaults unknown status to requested',
      timeout: const Timeout.factor(2),
      () {
        final row = _makeRow(status: 'unknown_status');
        final domain = toDomain(row);
        expect(domain.status, ReviewSpaceStatus.requested);
      },
    );
  });

  group('toDomainList', () {
    test('maps empty list', timeout: const Timeout.factor(2), () {
      final result = toDomainList([]);
      expect(result, isEmpty);
      expect(result, isA<List<ReviewSpaceAssociation>>());
    });

    test('maps multiple rows', timeout: const Timeout.factor(2), () {
      final rows = [
        _makeRow(id: 'rc-1', status: 'requested'),
        _makeRow(id: 'rc-2', status: 'completed'),
      ];
      final result = toDomainList(rows);
      expect(result, hasLength(2));
      expect(result[0].id, 'rc-1');
      expect(result[0].status, ReviewSpaceStatus.requested);
      expect(result[1].id, 'rc-2');
      expect(result[1].status, ReviewSpaceStatus.completed);
    });

    test('returns non-growable list', timeout: const Timeout.factor(2), () {
      final result = toDomainList([_makeRow()]);
      expect(
        () => (result as List).add(toDomain(_makeRow(id: 'x'))),
        throwsA(anything),
      );
    });
  });

  group('parseStatus', () {
    test('parses requested', timeout: const Timeout.factor(2), () {
      expect(parseStatus('requested'), ReviewSpaceStatus.requested);
    });

    test('parses in_progress', timeout: const Timeout.factor(2), () {
      expect(parseStatus('in_progress'), ReviewSpaceStatus.inProgress);
    });

    test('parses awaiting_approval', timeout: const Timeout.factor(2), () {
      expect(
        parseStatus('awaiting_approval'),
        ReviewSpaceStatus.awaitingApproval,
      );
    });

    test('parses completed', timeout: const Timeout.factor(2), () {
      expect(parseStatus('completed'), ReviewSpaceStatus.completed);
    });

    test('defaults unknown to requested', timeout: const Timeout.factor(2), () {
      expect(parseStatus(''), ReviewSpaceStatus.requested);
      expect(parseStatus('unknown'), ReviewSpaceStatus.requested);
    });
  });

  group('statusToString', () {
    test('converts all statuses', timeout: const Timeout.factor(2), () {
      expect(statusToString(ReviewSpaceStatus.requested), 'requested');
      expect(statusToString(ReviewSpaceStatus.inProgress), 'in_progress');
      expect(
        statusToString(ReviewSpaceStatus.awaitingApproval),
        'awaiting_approval',
      );
      expect(statusToString(ReviewSpaceStatus.completed), 'completed');
    });
  });

  group('round-trip parseStatus → statusToString', () {
    test('round-trips all statuses', timeout: const Timeout.factor(2), () {
      for (final status in ReviewSpaceStatus.values) {
        expect(parseStatus(statusToString(status)), status);
      }
    });
  });
}
