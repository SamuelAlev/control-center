import 'package:cc_domain/features/ticketing/domain/entities/ticket_link.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final ts = DateTime(2025, 1, 1);

  TicketLink make({
    String id = 'l1',
    String workspaceId = 'ws1',
    String sourceTicketId = 'A',
    String targetTicketId = 'B',
    TicketLinkType type = TicketLinkType.blocks,
  }) {
    return TicketLink(
      id: id,
      workspaceId: workspaceId,
      sourceTicketId: sourceTicketId,
      targetTicketId: targetTicketId,
      type: type,
      createdAt: ts,
    );
  }

  group('TicketLinkType', () {
    group('fromStorage', () {
      test('maps known storage strings', timeout: const Timeout.factor(2), () {
        expect(TicketLinkType.fromStorage('blocks'), TicketLinkType.blocks);
        expect(TicketLinkType.fromStorage('relates_to'), TicketLinkType.relatesTo);
        expect(TicketLinkType.fromStorage('duplicate_of'), TicketLinkType.duplicateOf);
      });

      test('returns null for unknown', timeout: const Timeout.factor(2), () {
        expect(TicketLinkType.fromStorage('unknown'), isNull);
        expect(TicketLinkType.fromStorage(null), isNull);
        expect(TicketLinkType.fromStorage(''), isNull);
      });
    });

    group('toStorageString', () {
      test('returns snake_case storage form', timeout: const Timeout.factor(2), () {
        expect(TicketLinkType.blocks.toStorageString(), 'blocks');
        expect(TicketLinkType.relatesTo.toStorageString(), 'relates_to');
        expect(TicketLinkType.duplicateOf.toStorageString(), 'duplicate_of');
      });

      test('round-trips through fromStorage', timeout: const Timeout.factor(2), () {
        for (final t in TicketLinkType.values) {
          expect(TicketLinkType.fromStorage(t.toStorageString()), t);
        }
      });
    });
  });

  group('TicketRelationKind', () {
    test('has all expected values', timeout: const Timeout.factor(2), () {
      expect(TicketRelationKind.values, hasLength(7));
      expect(TicketRelationKind.values, containsAll([
        TicketRelationKind.blockedBy,
        TicketRelationKind.blocking,
        TicketRelationKind.relatedTo,
        TicketRelationKind.duplicateOf,
        TicketRelationKind.duplicatedBy,
        TicketRelationKind.subIssueOf,
        TicketRelationKind.parentOf,
      ]));
    });
  });

  group('TicketLink', () {
    test('creates with required fields', timeout: const Timeout.factor(2), () {
      final link = make();
      expect(link.id, 'l1');
      expect(link.workspaceId, 'ws1');
      expect(link.sourceTicketId, 'A');
      expect(link.targetTicketId, 'B');
      expect(link.type, TicketLinkType.blocks);
      expect(link.createdAt, ts);
    });

    group('relationFor', () {
      test('blocks: source sees blocking, target sees blockedBy', timeout: const Timeout.factor(2), () {
        final link = make(type: TicketLinkType.blocks);
        final src = link.relationFor('A')!;
        expect(src.kind, TicketRelationKind.blocking);
        expect(src.otherTicketId, 'B');

        final tgt = link.relationFor('B')!;
        expect(tgt.kind, TicketRelationKind.blockedBy);
        expect(tgt.otherTicketId, 'A');
      });

      test('relatesTo: symmetric from both ends', timeout: const Timeout.factor(2), () {
        final link = make(type: TicketLinkType.relatesTo);
        final src = link.relationFor('A')!;
        expect(src.kind, TicketRelationKind.relatedTo);
        expect(src.otherTicketId, 'B');

        final tgt = link.relationFor('B')!;
        expect(tgt.kind, TicketRelationKind.relatedTo);
        expect(tgt.otherTicketId, 'A');
      });

      test('duplicateOf: source sees duplicateOf, target sees duplicatedBy', timeout: const Timeout.factor(2), () {
        final link = make(type: TicketLinkType.duplicateOf);
        final src = link.relationFor('A')!;
        expect(src.kind, TicketRelationKind.duplicateOf);
        expect(src.otherTicketId, 'B');

        final tgt = link.relationFor('B')!;
        expect(tgt.kind, TicketRelationKind.duplicatedBy);
        expect(tgt.otherTicketId, 'A');
      });

      test('returns null when subject is not an endpoint', timeout: const Timeout.factor(2), () {
        final link = make();
        expect(link.relationFor('X'), isNull);
      });
    });

    group('equality', () {
      test('equal when id, sourceTicketId, targetTicketId, type match', timeout: const Timeout.factor(2), () {
        final a = make(id: 'l', sourceTicketId: 'A', targetTicketId: 'B', type: TicketLinkType.blocks);
        final b = make(id: 'l', sourceTicketId: 'A', targetTicketId: 'B', type: TicketLinkType.blocks);
        expect(a, equals(b));
      });

      test('not equal when id differs', timeout: const Timeout.factor(2), () {
        final a = make(id: 'l1');
        final b = make(id: 'l2');
        expect(a, isNot(equals(b)));
      });

      test('not equal when type differs', timeout: const Timeout.factor(2), () {
        final a = make(type: TicketLinkType.blocks);
        final b = make(type: TicketLinkType.relatesTo);
        expect(a, isNot(equals(b)));
      });

      test('hashCode consistent with equality', timeout: const Timeout.factor(2), () {
        final a = make(id: 'l', sourceTicketId: 'A', targetTicketId: 'B');
        final b = make(id: 'l', sourceTicketId: 'A', targetTicketId: 'B');
        expect(a.hashCode, b.hashCode);
      });

      test('createdAt difference does not affect equality', timeout: const Timeout.factor(2), () {
        final a = TicketLink(
          id: 'l', workspaceId: 'ws', sourceTicketId: 'A', targetTicketId: 'B',
          type: TicketLinkType.blocks, createdAt: DateTime(2025, 1, 1),
        );
        final b = TicketLink(
          id: 'l', workspaceId: 'ws', sourceTicketId: 'A', targetTicketId: 'B',
          type: TicketLinkType.blocks, createdAt: DateTime(2025, 12, 31),
        );
        expect(a, equals(b));
      });
    });
  });
}
