import 'package:cc_domain/features/governance/domain/entities/approval.dart';
import 'package:cc_domain/features/governance/domain/value_objects/approval_kind.dart';
import 'package:cc_domain/features/governance/domain/value_objects/approval_status.dart';
import 'package:test/test.dart';

/// Exercises [Approval]: construction invariants, the `remove*` copyWith flags
/// (a field silently kept vs nulled is a real bug class), and equality.
void main() {
  Approval approval({
    String id = 'ap-1',
    String workspaceId = 'ws-1',
    String title = 'Deploy to prod',
    String? description = 'the deploy',
    ApprovalKind kind = ApprovalKind.merge,
    ApprovalStatus status = ApprovalStatus.pending,
    String requestedByActorType = 'agent',
    String? requestedById = 'a-1',
    List<String> linkedTicketIds = const ['t-1'],
    String? linkedEntityType = 'ticket',
    String? linkedEntityId = 't-1',
    String? decidedByActorType = 'user',
    String? decidedById = 'u-1',
    String? decisionReason = 'looks good',
    DateTime? createdAt,
    DateTime? decidedAt,
    DateTime? updatedAt,
  }) => Approval(
    id: id,
    workspaceId: workspaceId,
    title: title,
    description: description,
    kind: kind,
    status: status,
    requestedByActorType: requestedByActorType,
    requestedById: requestedById,
    linkedTicketIds: linkedTicketIds,
    linkedEntityType: linkedEntityType,
    linkedEntityId: linkedEntityId,
    decidedByActorType: decidedByActorType,
    decidedById: decidedById,
    decisionReason: decisionReason,
    createdAt: createdAt ?? DateTime(2026, 1, 1),
    decidedAt: decidedAt,
    updatedAt: updatedAt ?? DateTime(2026, 1, 2),
  );

  group('Approval construction', () {
    test('rejects an empty title', () {
      expect(() => approval(title: ''), throwsA(isA<AssertionError>()));
    });

    test('stores every field', () {
      final a = approval();
      expect(a.id, 'ap-1');
      expect(a.title, 'Deploy to prod');
      expect(a.kind, ApprovalKind.merge);
      expect(a.status, ApprovalStatus.pending);
      expect(a.linkedTicketIds, ['t-1']);
    });
  });

  group('Approval.copyWith preservation', () {
    test('a single-field copyWith preserves every other field', () {
      final a = approval();
      final next = a.copyWith(status: ApprovalStatus.approved);
      expect(next.status, ApprovalStatus.approved);
      // Untouched fields survive.
      expect(next.title, a.title);
      expect(next.kind, a.kind);
      expect(next.linkedTicketIds, a.linkedTicketIds);
      expect(next.decisionReason, a.decisionReason);
    });

    test('removeDescription nulls the field', () {
      final a = approval();
      final next = a.copyWith(removeDescription: true);
      expect(next.description, isNull);
    });

    test('removeRequestedById nulls the field', () {
      final a = approval();
      final next = a.copyWith(removeRequestedById: true);
      expect(next.requestedById, isNull);
    });

    test('removeDecidedAt nulls the field', () {
      final a = approval(decidedAt: DateTime(2026, 1, 3));
      final next = a.copyWith(removeDecidedAt: true);
      expect(next.decidedAt, isNull);
    });

    test('removeDecidedByActorType nulls the field', () {
      final a = approval();
      final next = a.copyWith(removeDecidedByActorType: true);
      expect(next.decidedByActorType, isNull);
    });

    test('removeLinkedEntityType + removeLinkedEntityId null both', () {
      final a = approval();
      final next = a.copyWith(
        removeLinkedEntityType: true,
        removeLinkedEntityId: true,
      );
      expect(next.linkedEntityType, isNull);
      expect(next.linkedEntityId, isNull);
    });

    test('omitting every field yields an equal copy', () {
      expect(approval().copyWith(), approval());
    });
  });

  group('Approval equality', () {
    test('equal when every field matches', () {
      expect(approval(), approval());
    });

    test('unequal when status differs', () {
      expect(
        approval(status: ApprovalStatus.pending),
        isNot(approval(status: ApprovalStatus.approved)),
      );
    });

    test('unequal when linkedTicketIds differ', () {
      expect(
        approval(linkedTicketIds: ['t-1']),
        isNot(approval(linkedTicketIds: ['t-2'])),
      );
    });

    test('hashCode matches for equal approvals', () {
      expect(approval().hashCode, approval().hashCode);
    });
  });
}
