import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_collaborator.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_link.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_provider.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_status.dart';
import 'package:cc_domain/features/ticketing/domain/repositories/ticket_link_repository.dart';
import 'package:cc_domain/features/ticketing/domain/repositories/ticket_repository.dart';
import 'package:cc_domain/features/ticketing/domain/services/ticket_link_service.dart';
import 'package:flutter_test/flutter_test.dart';
// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

/// Records inserted [TicketLink]s and supports [deleteByEndpoints].
class FakeTicketLinkRepository implements TicketLinkRepository {
  final List<TicketLink> inserted = [];
  final List<({String sourceTicketId, String targetTicketId, TicketLinkType type})>
      deletedByEndpoints = [];

  @override
  Future<void> insert(TicketLink link) async {
    inserted.add(link);
  }

  @override
  Future<int> deleteByEndpoints({
    required String workspaceId,
    required String sourceTicketId,
    required String targetTicketId,
    required TicketLinkType type,
  }) async {
    deletedByEndpoints.add((
      sourceTicketId: sourceTicketId,
      targetTicketId: targetTicketId,
      type: type,
    ));
    return 1;
  }

  // Unused by TicketLinkService — satisfy the interface with no-ops.
  @override
  Future<int> deleteById(String id, {required String workspaceId}) async => 0;

  @override
  Future<List<TicketLink>> getForTicket(
          String workspaceId, String ticketId) async =>
      [];

  @override
  Stream<List<TicketLink>> watchForTicket(
          String workspaceId, String ticketId) =>
      Stream.value([]);
}

/// Returns pre-configured tickets for [getById]; everything else is a no-op.
class FakeTicketRepository implements TicketRepository {

  FakeTicketRepository([List<Ticket>? tickets])
      : _tickets = {for (final t in tickets ?? <Ticket>[]) t.id: t};
  final Map<String, Ticket> _tickets;

  @override
  Future<Ticket?> getById(String id) async => _tickets[id];

  // Unused by TicketLinkService — satisfy the interface with no-ops / defaults.
  @override
  Future<void> insert(Ticket ticket) async {}

  @override
  Future<void> update(Ticket ticket, {int? expectedVersion}) async {}

  @override
  Future<void> upsertMirror(Ticket ticket) async {}

  @override
  Future<void> delete(String ticketId, {required String workspaceId}) async {}

  @override
  Future<Ticket?> getByExternal(
          TicketProvider provider, String externalKey) async =>
      null;

  @override
  @override
  @override
  Future<List<Ticket>> forAgent(String workspaceId, String agentId) async => [];

  @override
  Future<List<Ticket>> childrenOf(
          String workspaceId, String parentTicketId) async =>
      [];

  @override
  Stream<List<Ticket>> watchForWorkspace(String workspaceId) =>
      Stream.value([]);

  @override
  Stream<List<Ticket>> watchByStatus(
          String workspaceId, TicketStatus status) =>
      Stream.value([]);

  @override
  Stream<List<Ticket>> watchByAssignee(
          String workspaceId, String agentId) =>
      Stream.value([]);

  @override
  @override
  Future<void> addCollaborator(TicketCollaborator collaborator) async {}

  @override
  Future<void> removeCollaborator(String ticketId, String agentId) async {}

  @override
  Stream<List<TicketCollaborator>> watchCollaborators(String ticketId) =>
      Stream.value([]);

  @override
  Future<List<TicketCollaborator>> getCollaborators(String ticketId) async =>
      [];
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const _ws = 'ws-1';

Ticket _ticket(String id, {String workspaceId = _ws}) => Ticket(
      id: id,
      workspaceId: workspaceId,
      title: 'Ticket $id',
      status: TicketStatus.backlog,
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('TicketLinkService', () {
    late FakeTicketLinkRepository linkRepo;
    late FakeTicketRepository ticketRepo;
    late TicketLinkService service;

    setUp(() {
      linkRepo = FakeTicketLinkRepository();
      ticketRepo = FakeTicketRepository([
        _ticket('A'),
        _ticket('B'),
        _ticket('C'),
        _ticket('ws2-ticket', workspaceId: 'ws-2'),
      ]);
      service = TicketLinkService(
        linkRepository: linkRepo,
        ticketRepository: ticketRepo,
      );
    });

    // ------- link() -------

    group('link', () {
      test('rejects self-reference (source == target)',
          timeout: const Timeout.factor(2), () async {
        await expectLater(
          () => service.link(
            workspaceId: _ws,
            type: TicketLinkType.blocks,
            sourceTicketId: 'A',
            targetTicketId: 'A',
          ),
          throwsA(isA<ArgumentError>()
              .having((e) => e.message, 'message',
                  'A ticket cannot be linked to itself')),
        );
      });

      test('rejects when source ticket does not exist',
          timeout: const Timeout.factor(2), () async {
        await expectLater(
          () => service.link(
            workspaceId: _ws,
            type: TicketLinkType.blocks,
            sourceTicketId: 'nonexistent',
            targetTicketId: 'B',
          ),
          throwsA(isA<ArgumentError>()
              .having((e) => e.message, 'message',
                  'Ticket nonexistent does not exist')),
        );
      });

      test('rejects when target ticket does not exist',
          timeout: const Timeout.factor(2), () async {
        await expectLater(
          () => service.link(
            workspaceId: _ws,
            type: TicketLinkType.blocks,
            sourceTicketId: 'A',
            targetTicketId: 'nonexistent',
          ),
          throwsA(isA<ArgumentError>()
              .having((e) => e.message, 'message',
                  'Ticket nonexistent does not exist')),
        );
      });

      test('rejects when source workspaceId mismatches',
          timeout: const Timeout.factor(2), () async {
        await expectLater(
          () => service.link(
            workspaceId: _ws,
            type: TicketLinkType.blocks,
            sourceTicketId: 'ws2-ticket',
            targetTicketId: 'B',
          ),
          throwsA(isA<WorkspaceMismatchException>()),
        );
      });

      test('rejects when target workspaceId mismatches',
          timeout: const Timeout.factor(2), () async {
        await expectLater(
          () => service.link(
            workspaceId: _ws,
            type: TicketLinkType.blocks,
            sourceTicketId: 'A',
            targetTicketId: 'ws2-ticket',
          ),
          throwsA(isA<WorkspaceMismatchException>()),
        );
      });

      test('inserts a TicketLink with correct fields on success',
          timeout: const Timeout.factor(2), () async {
        await service.link(
          workspaceId: _ws,
          type: TicketLinkType.blocks,
          sourceTicketId: 'A',
          targetTicketId: 'B',
        );

        expect(linkRepo.inserted, hasLength(1));
        final link = linkRepo.inserted.single;
        expect(link.workspaceId, _ws);
        expect(link.sourceTicketId, 'A');
        expect(link.targetTicketId, 'B');
        expect(link.type, TicketLinkType.blocks);
        expect(link.id, isNotEmpty);
        expect(link.createdAt, isA<DateTime>());
      });

      test('inserts with relatesTo type correctly',
          timeout: const Timeout.factor(2), () async {
        await service.link(
          workspaceId: _ws,
          type: TicketLinkType.relatesTo,
          sourceTicketId: 'A',
          targetTicketId: 'B',
        );

        expect(linkRepo.inserted.single.type, TicketLinkType.relatesTo);
      });

      test('inserts with duplicateOf type correctly',
          timeout: const Timeout.factor(2), () async {
        await service.link(
          workspaceId: _ws,
          type: TicketLinkType.duplicateOf,
          sourceTicketId: 'A',
          targetTicketId: 'B',
        );

        expect(linkRepo.inserted.single.type, TicketLinkType.duplicateOf);
      });

      test('is idempotent (does not throw on duplicate)',
          timeout: const Timeout.factor(2), () async {
        // First call succeeds.
        await service.link(
          workspaceId: _ws,
          type: TicketLinkType.blocks,
          sourceTicketId: 'A',
          targetTicketId: 'B',
        );
        expect(linkRepo.inserted, hasLength(1));

        // Second call with the same parameters also succeeds (the repository
        // insert is the idempotent boundary).
        await service.link(
          workspaceId: _ws,
          type: TicketLinkType.blocks,
          sourceTicketId: 'A',
          targetTicketId: 'B',
        );
        expect(linkRepo.inserted, hasLength(2));
      });

      test('validates both tickets independently (source first)',
          timeout: const Timeout.factor(2), () async {
        // Source missing, target exists — should throw on source.
        await expectLater(
          () => service.link(
            workspaceId: _ws,
            type: TicketLinkType.blocks,
            sourceTicketId: 'nope',
            targetTicketId: 'B',
          ),
          throwsA(isA<ArgumentError>()
              .having((e) => e.message, 'message',
                  'Ticket nope does not exist')),
        );
      });
    });

    // ------- unlink() -------

    group('unlink', () {
      test('delegates to linkRepository.deleteByEndpoints with correct args',
          timeout: const Timeout.factor(2), () async {
        await service.unlink(
          workspaceId: _ws,
          type: TicketLinkType.blocks,
          sourceTicketId: 'A',
          targetTicketId: 'B',
        );

        expect(linkRepo.deletedByEndpoints, hasLength(1));
        final del = linkRepo.deletedByEndpoints.single;
        expect(del.sourceTicketId, 'A');
        expect(del.targetTicketId, 'B');
        expect(del.type, TicketLinkType.blocks);
      });

      test('unlink with relatesTo delegates correctly',
          timeout: const Timeout.factor(2), () async {
        await service.unlink(
          workspaceId: _ws,
          type: TicketLinkType.relatesTo,
          sourceTicketId: 'C',
          targetTicketId: 'A',
        );

        final del = linkRepo.deletedByEndpoints.single;
        expect(del.type, TicketLinkType.relatesTo);
        expect(del.sourceTicketId, 'C');
        expect(del.targetTicketId, 'A');
      });

      test('unlink does not validate tickets (just delegates)',
          timeout: const Timeout.factor(2), () async {
        // Even with a non-existing ticket, unlink should not validate.
        await service.unlink(
          workspaceId: _ws,
          type: TicketLinkType.blocks,
          sourceTicketId: 'nonexistent',
          targetTicketId: 'also-nonexistent',
        );

        expect(linkRepo.deletedByEndpoints, hasLength(1));
      });
    });

    // ------- addRelation() -------

    group('addRelation', () {
      test('blocking maps source=subject, target=other, type=blocks',
          timeout: const Timeout.factor(2), () async {
        await service.addRelation(
          workspaceId: _ws,
          subjectTicketId: 'A',
          otherTicketId: 'B',
          kind: TicketRelationKind.blocking,
        );

        final link = linkRepo.inserted.single;
        expect(link.sourceTicketId, 'A');
        expect(link.targetTicketId, 'B');
        expect(link.type, TicketLinkType.blocks);
      });

      test('blockedBy maps source=other, target=subject, type=blocks',
          timeout: const Timeout.factor(2), () async {
        await service.addRelation(
          workspaceId: _ws,
          subjectTicketId: 'A',
          otherTicketId: 'B',
          kind: TicketRelationKind.blockedBy,
        );

        final link = linkRepo.inserted.single;
        expect(link.sourceTicketId, 'B');
        expect(link.targetTicketId, 'A');
        expect(link.type, TicketLinkType.blocks);
      });

      test('relatedTo maps type=relatesTo, source=subject',
          timeout: const Timeout.factor(2), () async {
        await service.addRelation(
          workspaceId: _ws,
          subjectTicketId: 'A',
          otherTicketId: 'B',
          kind: TicketRelationKind.relatedTo,
        );

        final link = linkRepo.inserted.single;
        expect(link.sourceTicketId, 'A');
        expect(link.targetTicketId, 'B');
        expect(link.type, TicketLinkType.relatesTo);
      });

      test('duplicateOf maps source=subject, target=other, type=duplicateOf',
          timeout: const Timeout.factor(2), () async {
        await service.addRelation(
          workspaceId: _ws,
          subjectTicketId: 'A',
          otherTicketId: 'B',
          kind: TicketRelationKind.duplicateOf,
        );

        final link = linkRepo.inserted.single;
        expect(link.sourceTicketId, 'A');
        expect(link.targetTicketId, 'B');
        expect(link.type, TicketLinkType.duplicateOf);
      });

      test('duplicatedBy maps source=other, target=subject, type=duplicateOf',
          timeout: const Timeout.factor(2), () async {
        await service.addRelation(
          workspaceId: _ws,
          subjectTicketId: 'A',
          otherTicketId: 'B',
          kind: TicketRelationKind.duplicatedBy,
        );

        final link = linkRepo.inserted.single;
        expect(link.sourceTicketId, 'B');
        expect(link.targetTicketId, 'A');
        expect(link.type, TicketLinkType.duplicateOf);
      });

      test('still validates tickets through link()',
          timeout: const Timeout.factor(2), () async {
        await expectLater(
          () => service.addRelation(
            workspaceId: _ws,
            subjectTicketId: 'A',
            otherTicketId: 'A',
            kind: TicketRelationKind.relatedTo,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('rejects parentOf with ArgumentError',
          timeout: const Timeout.factor(2), () async {
        await expectLater(
          () => service.addRelation(
            workspaceId: _ws,
            subjectTicketId: 'A',
            otherTicketId: 'B',
            kind: TicketRelationKind.parentOf,
          ),
          throwsA(isA<ArgumentError>()
              .having(
                (e) => e.message,
                'message',
                'Parent/sub-issue relations are managed by TicketWorkflowService',
              )),
        );
        expect(linkRepo.inserted, isEmpty);
      });

      test('rejects subIssueOf with ArgumentError',
          timeout: const Timeout.factor(2), () async {
        await expectLater(
          () => service.addRelation(
            workspaceId: _ws,
            subjectTicketId: 'A',
            otherTicketId: 'B',
            kind: TicketRelationKind.subIssueOf,
          ),
          throwsA(isA<ArgumentError>()
              .having(
                (e) => e.message,
                'message',
                'Parent/sub-issue relations are managed by TicketWorkflowService',
              )),
        );
        expect(linkRepo.inserted, isEmpty);
      });

      test('self-reference via addRelation still throws',
          timeout: const Timeout.factor(2), () async {
        await expectLater(
          () => service.addRelation(
            workspaceId: _ws,
            subjectTicketId: 'A',
            otherTicketId: 'A',
            kind: TicketRelationKind.blocking,
          ),
          throwsA(isA<ArgumentError>()
              .having((e) => e.message, 'message',
                  'A ticket cannot be linked to itself')),
        );
      });
    });

    // ------- removeRelation() -------

    group('removeRelation', () {
      test('blocking delegates unlink with source=subject, target=other',
          timeout: const Timeout.factor(2), () async {
        await service.removeRelation(
          workspaceId: _ws,
          subjectTicketId: 'A',
          otherTicketId: 'B',
          kind: TicketRelationKind.blocking,
        );

        final del = linkRepo.deletedByEndpoints.single;
        expect(del.sourceTicketId, 'A');
        expect(del.targetTicketId, 'B');
        expect(del.type, TicketLinkType.blocks);
      });

      test('blockedBy delegates unlink with source=other, target=subject',
          timeout: const Timeout.factor(2), () async {
        await service.removeRelation(
          workspaceId: _ws,
          subjectTicketId: 'A',
          otherTicketId: 'B',
          kind: TicketRelationKind.blockedBy,
        );

        final del = linkRepo.deletedByEndpoints.single;
        expect(del.sourceTicketId, 'B');
        expect(del.targetTicketId, 'A');
        expect(del.type, TicketLinkType.blocks);
      });

      test('relatedTo delegates unlink correctly',
          timeout: const Timeout.factor(2), () async {
        await service.removeRelation(
          workspaceId: _ws,
          subjectTicketId: 'A',
          otherTicketId: 'B',
          kind: TicketRelationKind.relatedTo,
        );

        final del = linkRepo.deletedByEndpoints.single;
        expect(del.sourceTicketId, 'A');
        expect(del.targetTicketId, 'B');
        expect(del.type, TicketLinkType.relatesTo);
      });

      test('duplicateOf delegates unlink with source=subject, target=other',
          timeout: const Timeout.factor(2), () async {
        await service.removeRelation(
          workspaceId: _ws,
          subjectTicketId: 'A',
          otherTicketId: 'B',
          kind: TicketRelationKind.duplicateOf,
        );

        final del = linkRepo.deletedByEndpoints.single;
        expect(del.sourceTicketId, 'A');
        expect(del.targetTicketId, 'B');
        expect(del.type, TicketLinkType.duplicateOf);
      });

      test('duplicatedBy delegates unlink with source=other, target=subject',
          timeout: const Timeout.factor(2), () async {
        await service.removeRelation(
          workspaceId: _ws,
          subjectTicketId: 'A',
          otherTicketId: 'B',
          kind: TicketRelationKind.duplicatedBy,
        );

        final del = linkRepo.deletedByEndpoints.single;
        expect(del.sourceTicketId, 'B');
        expect(del.targetTicketId, 'A');
        expect(del.type, TicketLinkType.duplicateOf);
      });

      test('rejects parentOf with ArgumentError',
          timeout: const Timeout.factor(2), () async {
        await expectLater(
          () => service.removeRelation(
            workspaceId: _ws,
            subjectTicketId: 'A',
            otherTicketId: 'B',
            kind: TicketRelationKind.parentOf,
          ),
          throwsA(isA<ArgumentError>()),
        );
        expect(linkRepo.deletedByEndpoints, isEmpty);
      });

      test('rejects subIssueOf with ArgumentError',
          timeout: const Timeout.factor(2), () async {
        await expectLater(
          () => service.removeRelation(
            workspaceId: _ws,
            subjectTicketId: 'A',
            otherTicketId: 'B',
            kind: TicketRelationKind.subIssueOf,
          ),
          throwsA(isA<ArgumentError>()),
        );
        expect(linkRepo.deletedByEndpoints, isEmpty);
      });

      test('does not validate tickets (just delegates to unlink)',
          timeout: const Timeout.factor(2), () async {
        await service.removeRelation(
          workspaceId: _ws,
          subjectTicketId: 'nonexistent',
          otherTicketId: 'also-nonexistent',
          kind: TicketRelationKind.relatedTo,
        );

        expect(linkRepo.deletedByEndpoints, hasLength(1));
      });
    });

    // ------- _assertTicket edge cases -------

    group('_assertTicket via link', () {
      test('rejects when ticket is null (not found)',
          timeout: const Timeout.factor(2), () async {
        final emptyService = TicketLinkService(
          linkRepository: linkRepo,
          ticketRepository: FakeTicketRepository([]),
        );

        await expectLater(
          () => emptyService.link(
            workspaceId: _ws,
            type: TicketLinkType.blocks,
            sourceTicketId: 'A',
            targetTicketId: 'B',
          ),
          throwsA(isA<ArgumentError>()
              .having((e) => e.message, 'message',
                  'Ticket A does not exist')),
        );
      });
    });

    // ------- canonical mapping coverage -------

    group('canonical mapping correctness', () {
      test('relatesTo is symmetric (source == subject always)',
          timeout: const Timeout.factor(2), () async {
        await service.addRelation(
          workspaceId: _ws,
          subjectTicketId: 'C',
          otherTicketId: 'B',
          kind: TicketRelationKind.relatedTo,
        );

        final link = linkRepo.inserted.single;
        expect(link.sourceTicketId, 'C');
        expect(link.targetTicketId, 'B');

        // Reversing subject/other does not change the _canonical output — it
        // still maps source=subject, target=other. The caller is expected to
        // handle symmetry.
      });

      test('blocks canonical source/target respects direction',
          timeout: const Timeout.factor(2), () async {
        // blocking: A blocks B  →  source=A, target=B
        await service.addRelation(
          workspaceId: _ws,
          subjectTicketId: 'A',
          otherTicketId: 'B',
          kind: TicketRelationKind.blocking,
        );

        final blockLink = linkRepo.inserted.last;
        expect(blockLink.sourceTicketId, 'A');
        expect(blockLink.targetTicketId, 'B');
      });

      test('duplicateOf canonical source/target respects direction',
          timeout: const Timeout.factor(2), () async {
        // duplicateOf: A dupe of B  →  source=A, target=B
        await service.addRelation(
          workspaceId: _ws,
          subjectTicketId: 'A',
          otherTicketId: 'B',
          kind: TicketRelationKind.duplicateOf,
        );

        final dupeLink = linkRepo.inserted.last;
        expect(dupeLink.sourceTicketId, 'A');
        expect(dupeLink.targetTicketId, 'B');
      });

      test('addRelation followed by removeRelation for same kind round-trips',
          timeout: const Timeout.factor(2), () async {
        // Add blocking: A blocks B
        await service.addRelation(
          workspaceId: _ws,
          subjectTicketId: 'A',
          otherTicketId: 'B',
          kind: TicketRelationKind.blocking,
        );

        // Remove blocking: A blocks B
        await service.removeRelation(
          workspaceId: _ws,
          subjectTicketId: 'A',
          otherTicketId: 'B',
          kind: TicketRelationKind.blocking,
        );

        final del = linkRepo.deletedByEndpoints.single;
        expect(del.sourceTicketId, 'A');
        expect(del.targetTicketId, 'B');
        expect(del.type, TicketLinkType.blocks);
      });
    });
  });
}
