import 'package:control_center/core/database/app_database.dart';
import 'package:control_center/core/domain/entities/review_channel_association.dart';
import 'package:control_center/features/pr_review/data/mappers/review_channel_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

ReviewChannelsTableData _makeRow({
  String id = 'rc-1',
  String channelId = 'ch-1',
  String workspaceId = 'ws-1',
  String prNodeId = 'PR_node-1',
  int prNumber = 42,
  String repoFullName = 'owner/repo',
  String status = 'requested',
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  final now = DateTime(2025, 1, 15, 10, 30);
  return ReviewChannelsTableData(
    id: id,
    channelId: channelId,
    workspaceId: workspaceId,
    prNodeId: prNodeId,
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
        channelId: 'ch-1',
        workspaceId: 'ws-1',
        prNodeId: 'PR_abc',
        prNumber: 99,
        repoFullName: 'org/repo',
        status: 'in_progress',
        createdAt: now,
        updatedAt: now,
      );
      final domain = toDomain(row);
      expect(domain.id, 'rc-1');
      expect(domain.channelId, 'ch-1');
      expect(domain.workspaceId, 'ws-1');
      expect(domain.prNodeId, 'PR_abc');
      expect(domain.prNumber, 99);
      expect(domain.repoFullName, 'org/repo');
      expect(domain.status, ReviewChannelStatus.inProgress);
      expect(domain.createdAt, now);
      expect(domain.updatedAt, now);
    });

    test('defaults unknown status to requested', timeout: const Timeout.factor(2), () {
      final row = _makeRow(status: 'unknown_status');
      final domain = toDomain(row);
      expect(domain.status, ReviewChannelStatus.requested);
    });
  });

  group('toDomainList', () {
    test('maps empty list', timeout: const Timeout.factor(2), () {
      final result = toDomainList([]);
      expect(result, isEmpty);
      expect(result, isA<List<ReviewChannelAssociation>>());
    });

    test('maps multiple rows', timeout: const Timeout.factor(2), () {
      final rows = [
        _makeRow(id: 'rc-1', status: 'requested'),
        _makeRow(id: 'rc-2', status: 'completed'),
      ];
      final result = toDomainList(rows);
      expect(result, hasLength(2));
      expect(result[0].id, 'rc-1');
      expect(result[0].status, ReviewChannelStatus.requested);
      expect(result[1].id, 'rc-2');
      expect(result[1].status, ReviewChannelStatus.completed);
    });

    test('returns non-growable list', timeout: const Timeout.factor(2), () {
      final result = toDomainList([_makeRow()]);
      expect(() => (result as List).add(toDomain(_makeRow(id: 'x'))), throwsA(anything));
    });
  });

  group('parseStatus', () {
    test('parses requested', timeout: const Timeout.factor(2), () {
      expect(parseStatus('requested'), ReviewChannelStatus.requested);
    });

    test('parses in_progress', timeout: const Timeout.factor(2), () {
      expect(parseStatus('in_progress'), ReviewChannelStatus.inProgress);
    });

    test('parses awaiting_approval', timeout: const Timeout.factor(2), () {
      expect(parseStatus('awaiting_approval'), ReviewChannelStatus.awaitingApproval);
    });

    test('parses completed', timeout: const Timeout.factor(2), () {
      expect(parseStatus('completed'), ReviewChannelStatus.completed);
    });

    test('defaults unknown to requested', timeout: const Timeout.factor(2), () {
      expect(parseStatus(''), ReviewChannelStatus.requested);
      expect(parseStatus('unknown'), ReviewChannelStatus.requested);
    });
  });

  group('statusToString', () {
    test('converts all statuses', timeout: const Timeout.factor(2), () {
      expect(statusToString(ReviewChannelStatus.requested), 'requested');
      expect(statusToString(ReviewChannelStatus.inProgress), 'in_progress');
      expect(statusToString(ReviewChannelStatus.awaitingApproval), 'awaiting_approval');
      expect(statusToString(ReviewChannelStatus.completed), 'completed');
    });
  });

  group('round-trip parseStatus → statusToString', () {
    test('round-trips all statuses', timeout: const Timeout.factor(2), () {
      for (final status in ReviewChannelStatus.values) {
        expect(parseStatus(statusToString(status)), status);
      }
    });
  });
}
