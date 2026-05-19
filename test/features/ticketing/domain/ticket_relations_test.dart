import 'package:control_center/core/domain/events/domain_event_bus.dart';
import 'package:control_center/core/errors/app_exceptions.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket_collaborator.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket_link.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket_provider.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket_status.dart';
import 'package:control_center/features/ticketing/domain/repositories/ticket_link_repository.dart';
import 'package:control_center/features/ticketing/domain/repositories/ticket_repository.dart';
import 'package:control_center/features/ticketing/domain/services/ticket_link_service.dart';
import 'package:control_center/features/ticketing/domain/services/ticket_workflow_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeTicketRepo implements TicketRepository {
  final Map<String, Ticket> store = {};

  Ticket seed(String id, String ws, {String? parentId}) {
    final now = DateTime(2026);
    final t = Ticket(
      id: id,
      workspaceId: ws,
      title: id,
      status: TicketStatus.open,
      parentTicketId: parentId,
      createdAt: now,
      updatedAt: now,
    );
    store[id] = t;
    return t;
  }

  @override
  Future<void> insert(Ticket ticket) async => store[ticket.id] = ticket;

  @override
  Future<void> update(Ticket ticket, {int? expectedVersion}) async {
    final current = store[ticket.id];
    if (expectedVersion != null &&
        current != null &&
        current.version != expectedVersion) {
      throw const ConcurrencyConflictException('conflict');
    }
    store[ticket.id] = ticket;
  }

  @override
  Future<void> upsertMirror(Ticket ticket) async =>
      store[ticket.id] = ticket;

  @override
  Future<void> delete(String ticketId, {required String workspaceId}) async {
    final t = store[ticketId];
    if (t != null && t.workspaceId == workspaceId) {
      store.remove(ticketId);
    }
  }

  @override
  Future<Ticket?> getById(String id) async => store[id];

  @override
  Future<Ticket?> getByExternal(TicketProvider p, String key) async => null;

  @override
  Future<List<Ticket>> forPipelineRun(String w, String r) async => [];

  @override
  Future<List<Ticket>> forPipelineStep(String w, String r, String s) async =>
      [];

  @override
  Future<List<Ticket>> forAgent(String w, String a) async => [];

  @override
  Future<List<Ticket>> childrenOf(String w, String parentId) async => store
      .values
      .where((t) => t.workspaceId == w && t.parentTicketId == parentId)
      .toList();

  @override
  Stream<List<Ticket>> watchForWorkspace(String w) =>
      Stream.value(store.values.where((t) => t.workspaceId == w).toList());

  @override
  Stream<List<Ticket>> watchByStatus(String w, TicketStatus s) =>
      const Stream.empty();

  @override
  Stream<List<Ticket>> watchByAssignee(String w, String a) =>
      const Stream.empty();

  @override
  Stream<List<Ticket>> watchForPipelineRun(String w, String r) =>
      const Stream.empty();

  @override
  Future<void> addCollaborator(TicketCollaborator c) async {}

  @override
  Future<void> removeCollaborator(String t, String a) async {}

  @override
  Stream<List<TicketCollaborator>> watchCollaborators(String t) =>
      const Stream.empty();

  @override
  Future<List<TicketCollaborator>> getCollaborators(String t) async => [];
}

class _FakeLinkRepo implements TicketLinkRepository {
  final List<TicketLink> store = [];

  @override
  Future<void> insert(TicketLink link) async {
    final dup = store.any((l) =>
        l.workspaceId == link.workspaceId &&
        l.sourceTicketId == link.sourceTicketId &&
        l.targetTicketId == link.targetTicketId &&
        l.type == link.type);
    if (!dup) {
      store.add(link);
    }
  }

  @override
  Future<int> deleteById(String id, {required String workspaceId}) async {
    final before = store.length;
    store.removeWhere((l) => l.id == id && l.workspaceId == workspaceId);
    return before - store.length;
  }

  @override
  Future<int> deleteByEndpoints({
    required String workspaceId,
    required String sourceTicketId,
    required String targetTicketId,
    required TicketLinkType type,
  }) async {
    final before = store.length;
    store.removeWhere((l) =>
        l.workspaceId == workspaceId &&
        l.sourceTicketId == sourceTicketId &&
        l.targetTicketId == targetTicketId &&
        l.type == type);
    return before - store.length;
  }

  @override
  Future<List<TicketLink>> getForTicket(String w, String ticketId) async =>
      store
          .where((l) =>
              l.workspaceId == w &&
              (l.sourceTicketId == ticketId || l.targetTicketId == ticketId))
          .toList();

  @override
  Stream<List<TicketLink>> watchForTicket(String w, String ticketId) =>
      Stream.value(store);
}

void main() {
  late _FakeTicketRepo tickets;
  late _FakeLinkRepo links;
  late TicketLinkService linkService;
  late TicketWorkflowService workflow;

  setUp(() {
    tickets = _FakeTicketRepo();
    links = _FakeLinkRepo();
    linkService = TicketLinkService(
      linkRepository: links,
      ticketRepository: tickets,
    );
    workflow = TicketWorkflowService(
      repository: tickets,
      eventBus: DomainEventBus(),
    );
  });

  group('TicketLinkService.link', () {
    test('creates a direct link between two tickets', () async {
      tickets.seed('a', 'w');
      tickets.seed('b', 'w');
      await linkService.link(
        workspaceId: 'w',
        type: TicketLinkType.relatesTo,
        sourceTicketId: 'a',
        targetTicketId: 'b',
      );
      expect(links.store.length, 1);
      expect(links.store.single.type, TicketLinkType.relatesTo);
      expect(links.store.single.sourceTicketId, 'a');
      expect(links.store.single.targetTicketId, 'b');
    });

    test('rejects self-link', () async {
      tickets.seed('a', 'w');
      await expectLater(
        () => linkService.link(
          workspaceId: 'w',
          type: TicketLinkType.relatesTo,
          sourceTicketId: 'a',
          targetTicketId: 'a',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects non-existent source ticket', () async {
      tickets.seed('b', 'w');
      await expectLater(
        () => linkService.link(
          workspaceId: 'w',
          type: TicketLinkType.blocks,
          sourceTicketId: 'missing',
          targetTicketId: 'b',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects non-existent target ticket', () async {
      tickets.seed('a', 'w');
      await expectLater(
        () => linkService.link(
          workspaceId: 'w',
          type: TicketLinkType.blocks,
          sourceTicketId: 'a',
          targetTicketId: 'missing',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects cross-workspace source ticket', () async {
      tickets.seed('a', 'ws-other');
      tickets.seed('b', 'w');
      await expectLater(
        () => linkService.link(
          workspaceId: 'w',
          type: TicketLinkType.relatesTo,
          sourceTicketId: 'a',
          targetTicketId: 'b',
        ),
        throwsA(isA<WorkspaceMismatchException>()),
      );
    });

    test('rejects cross-workspace target ticket', () async {
      tickets.seed('a', 'w');
      tickets.seed('b', 'ws-other');
      await expectLater(
        () => linkService.link(
          workspaceId: 'w',
          type: TicketLinkType.relatesTo,
          sourceTicketId: 'a',
          targetTicketId: 'b',
        ),
        throwsA(isA<WorkspaceMismatchException>()),
      );
    });

    test('creates blocks link type', () async {
      tickets.seed('a', 'w');
      tickets.seed('b', 'w');
      await linkService.link(
        workspaceId: 'w',
        type: TicketLinkType.blocks,
        sourceTicketId: 'a',
        targetTicketId: 'b',
      );
      expect(links.store.single.type, TicketLinkType.blocks);
    });

    test('creates duplicateOf link type', () async {
      tickets.seed('a', 'w');
      tickets.seed('b', 'w');
      await linkService.link(
        workspaceId: 'w',
        type: TicketLinkType.duplicateOf,
        sourceTicketId: 'a',
        targetTicketId: 'b',
      );
      expect(links.store.single.type, TicketLinkType.duplicateOf);
    });
  });

  group('TicketLinkService.unlink', () {
    test('removes an existing link', () async {
      tickets.seed('a', 'w');
      tickets.seed('b', 'w');
      await linkService.link(
        workspaceId: 'w',
        type: TicketLinkType.relatesTo,
        sourceTicketId: 'a',
        targetTicketId: 'b',
      );
      expect(links.store.length, 1);
      await linkService.unlink(
        workspaceId: 'w',
        type: TicketLinkType.relatesTo,
        sourceTicketId: 'a',
        targetTicketId: 'b',
      );
      expect(links.store, isEmpty);
    });

    test('unlinking a non-existent link is a no-op', () async {
      tickets.seed('a', 'w');
      tickets.seed('b', 'w');
      await linkService.unlink(
        workspaceId: 'w',
        type: TicketLinkType.relatesTo,
        sourceTicketId: 'a',
        targetTicketId: 'b',
      );
      expect(links.store, isEmpty);
    });
  });

  group('TicketLinkService.addRelation', () {
    test('"blocked by" stores a canonical blocks edge from the other ticket',
        () async {
      tickets.seed('a', 'w');
      tickets.seed('b', 'w');
      await linkService.addRelation(
        workspaceId: 'w',
        subjectTicketId: 'a',
        otherTicketId: 'b',
        kind: TicketRelationKind.blockedBy,
      );
      // a blocked by b  ==  b blocks a
      final link = links.store.single;
      expect(link.type, TicketLinkType.blocks);
      expect(link.sourceTicketId, 'b');
      expect(link.targetTicketId, 'a');
      // From a's perspective it reads back as blockedBy.
      expect(link.relationFor('a')!.kind, TicketRelationKind.blockedBy);
    });

    test('"blocking" stores a canonical blocks edge from the subject',
        () async {
      tickets.seed('a', 'w');
      tickets.seed('b', 'w');
      await linkService.addRelation(
        workspaceId: 'w',
        subjectTicketId: 'a',
        otherTicketId: 'b',
        kind: TicketRelationKind.blocking,
      );
      final link = links.store.single;
      expect(link.type, TicketLinkType.blocks);
      expect(link.sourceTicketId, 'a');
      expect(link.targetTicketId, 'b');
      expect(link.relationFor('a')!.kind, TicketRelationKind.blocking);
      expect(link.relationFor('b')!.kind, TicketRelationKind.blockedBy);
    });

    test('"related to" stores a symmetric relatesTo edge', () async {
      tickets.seed('a', 'w');
      tickets.seed('b', 'w');
      await linkService.addRelation(
        workspaceId: 'w',
        subjectTicketId: 'a',
        otherTicketId: 'b',
        kind: TicketRelationKind.relatedTo,
      );
      final link = links.store.single;
      expect(link.type, TicketLinkType.relatesTo);
      expect(link.sourceTicketId, 'a');
      expect(link.targetTicketId, 'b');
      expect(link.relationFor('a')!.kind, TicketRelationKind.relatedTo);
      expect(link.relationFor('b')!.kind, TicketRelationKind.relatedTo);
    });

    test('"duplicate of" stores canonical duplicateOf edge from subject',
        () async {
      tickets.seed('a', 'w');
      tickets.seed('b', 'w');
      await linkService.addRelation(
        workspaceId: 'w',
        subjectTicketId: 'a',
        otherTicketId: 'b',
        kind: TicketRelationKind.duplicateOf,
      );
      final link = links.store.single;
      expect(link.type, TicketLinkType.duplicateOf);
      expect(link.sourceTicketId, 'a');
      expect(link.targetTicketId, 'b');
      expect(link.relationFor('a')!.kind, TicketRelationKind.duplicateOf);
      expect(link.relationFor('b')!.kind, TicketRelationKind.duplicatedBy);
    });

    test('"duplicated by" stores canonical duplicateOf edge from other',
        () async {
      tickets.seed('a', 'w');
      tickets.seed('b', 'w');
      await linkService.addRelation(
        workspaceId: 'w',
        subjectTicketId: 'a',
        otherTicketId: 'b',
        kind: TicketRelationKind.duplicatedBy,
      );
      final link = links.store.single;
      expect(link.type, TicketLinkType.duplicateOf);
      expect(link.sourceTicketId, 'b');
      expect(link.targetTicketId, 'a');
      expect(link.relationFor('a')!.kind, TicketRelationKind.duplicatedBy);
      expect(link.relationFor('b')!.kind, TicketRelationKind.duplicateOf);
    });

    test('a ticket cannot be linked to itself', () async {
      tickets.seed('a', 'w');
      await expectLater(
        () => linkService.link(
          workspaceId: 'w',
          type: TicketLinkType.relatesTo,
          sourceTicketId: 'a',
          targetTicketId: 'a',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('linking across workspaces is rejected', () async {
      tickets.seed('a', 'w');
      tickets.seed('x', 'other');
      await expectLater(
        () => linkService.link(
          workspaceId: 'w',
          type: TicketLinkType.relatesTo,
          sourceTicketId: 'a',
          targetTicketId: 'x',
        ),
        throwsA(isA<WorkspaceMismatchException>()),
      );
      expect(links.store, isEmpty);
    });

    test('removeRelation deletes the canonical edge', () async {
      tickets.seed('a', 'w');
      tickets.seed('b', 'w');
      await linkService.addRelation(
        workspaceId: 'w',
        subjectTicketId: 'a',
        otherTicketId: 'b',
        kind: TicketRelationKind.relatedTo,
      );
      expect(links.store.length, 1);
      await linkService.removeRelation(
        workspaceId: 'w',
        subjectTicketId: 'a',
        otherTicketId: 'b',
        kind: TicketRelationKind.relatedTo,
      );
      expect(links.store, isEmpty);
    });

    test('removeRelation for blocking/bockedBy removes the shared edge',
        () async {
      tickets.seed('a', 'w');
      tickets.seed('b', 'w');
      await linkService.addRelation(
        workspaceId: 'w',
        subjectTicketId: 'a',
        otherTicketId: 'b',
        kind: TicketRelationKind.blocking,
      );
      expect(links.store.length, 1);
      await linkService.removeRelation(
        workspaceId: 'w',
        subjectTicketId: 'a',
        otherTicketId: 'b',
        kind: TicketRelationKind.blocking,
      );
      expect(links.store, isEmpty);
    });

    test('removeRelation for blockedBy (inverse direction) removes the edge',
        () async {
      tickets.seed('a', 'w');
      tickets.seed('b', 'w');
      await linkService.addRelation(
        workspaceId: 'w',
        subjectTicketId: 'a',
        otherTicketId: 'b',
        kind: TicketRelationKind.blockedBy,
      );
      expect(links.store.length, 1);
      // Remove from the perspective that sees it as blocking
      await linkService.removeRelation(
        workspaceId: 'w',
        subjectTicketId: 'b',
        otherTicketId: 'a',
        kind: TicketRelationKind.blocking,
      );
      expect(links.store, isEmpty);
    });

    test('rejects parent/sub-issue relation kinds', () async {
      tickets.seed('a', 'w');
      tickets.seed('b', 'w');
      await expectLater(
        () => linkService.addRelation(
          workspaceId: 'w',
          subjectTicketId: 'a',
          otherTicketId: 'b',
          kind: TicketRelationKind.subIssueOf,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects parentOf relation kind', () async {
      tickets.seed('a', 'w');
      tickets.seed('b', 'w');
      await expectLater(
        () => linkService.addRelation(
          workspaceId: 'w',
          subjectTicketId: 'a',
          otherTicketId: 'b',
          kind: TicketRelationKind.parentOf,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('TicketLinkService: idempotent link', () {
    test('inserting same link twice does not duplicate', () async {
      tickets.seed('a', 'w');
      tickets.seed('b', 'w');
      await linkService.link(
        workspaceId: 'w',
        type: TicketLinkType.relatesTo,
        sourceTicketId: 'a',
        targetTicketId: 'b',
      );
      await linkService.link(
        workspaceId: 'w',
        type: TicketLinkType.relatesTo,
        sourceTicketId: 'a',
        targetTicketId: 'b',
      );
      expect(links.store.length, 1);
    });
  });

  group('TicketWorkflowService.setParent', () {
    test('sets the parent', () async {
      tickets.seed('child', 'w');
      tickets.seed('parent', 'w');
      await workflow.setParent('child', 'parent', workspaceId: 'w');
      expect(tickets.store['child']!.parentTicketId, 'parent');
    });

    test('rejects self-parenting', () async {
      tickets.seed('a', 'w');
      await expectLater(
        () => workflow.setParent('a', 'a', workspaceId: 'w'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects a cycle', () async {
      // a -> b (b is a's parent). Now trying to make b a sub-issue of a cycles.
      tickets.seed('a', 'w', parentId: 'b');
      tickets.seed('b', 'w');
      await expectLater(
        () => workflow.setParent('b', 'a', workspaceId: 'w'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects a parent from a different workspace', () async {
      tickets.seed('a', 'w');
      tickets.seed('x', 'other');
      await expectLater(
        () => workflow.setParent('a', 'x', workspaceId: 'w'),
        throwsA(isA<WorkspaceMismatchException>()),
      );
    });

    test('clearParent removes the parent', () async {
      tickets.seed('child', 'w', parentId: 'parent');
      tickets.seed('parent', 'w');
      await workflow.clearParent('child', workspaceId: 'w');
      expect(tickets.store['child']!.parentTicketId, isNull);
    });
  });

  group('TicketWorkflowService.setProject', () {
    test('assigns and clears the project', () async {
      tickets.seed('a', 'w');
      await workflow.setProject('a', 'p-1', workspaceId: 'w');
      expect(tickets.store['a']!.projectId, 'p-1');
      await workflow.setProject('a', null, workspaceId: 'w');
      expect(tickets.store['a']!.projectId, isNull);
    });

    test('rejects a ticket from a different workspace', () async {
      tickets.seed('a', 'w');
      await expectLater(
        () => workflow.setProject('a', 'p-1', workspaceId: 'other-ws'),
        throwsA(isA<WorkspaceMismatchException>()),
      );
    });
  });
}
