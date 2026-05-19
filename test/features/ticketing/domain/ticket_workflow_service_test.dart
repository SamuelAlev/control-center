import 'package:control_center/core/domain/events/domain_event_bus.dart';
import 'package:control_center/core/domain/events/ticketing_events.dart';
import 'package:control_center/core/errors/app_exceptions.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket_collaborator.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket_provider.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket_status.dart';
import 'package:control_center/features/ticketing/domain/repositories/ticket_repository.dart';
import 'package:control_center/features/ticketing/domain/services/ticket_workflow_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRepo implements TicketRepository {
  final Map<String, Ticket> store = {};
  final Map<String, List<TicketCollaborator>> collabs = {};

  @override
  Future<void> insert(Ticket ticket) async => store[ticket.id] = ticket;
  @override
  Future<void> update(Ticket ticket, {int? expectedVersion}) async {
    // Simulate optimistic locking so version-safe writes are exercised: the
    // write only lands when the stored version matches [expectedVersion].
    final current = store[ticket.id];
    if (expectedVersion != null &&
        current != null &&
        current.version != expectedVersion) {
      throw ConcurrencyConflictException(
        'Ticket ${ticket.id} was modified (expected $expectedVersion, '
        'found ${current.version})',
      );
    }
    store[ticket.id] = ticket;
  }
  @override
  Future<void> upsertMirror(Ticket ticket) async => store[ticket.id] = ticket;
  @override
  Future<void> delete(String ticketId, {required String workspaceId}) async {
    // Mirror the DAO's workspace-scoped delete: a foreign row is never matched.
    final t = store[ticketId];
    if (t != null && t.workspaceId == workspaceId) {
      store.remove(ticketId);
      collabs.remove(ticketId);
    }
  }
  @override
  Future<Ticket?> getById(String id) async => store[id];
  @override
  Future<Ticket?> getByExternal(TicketProvider p, String key) async =>
      store.values.where((t) => t.provider == p && t.externalKey == key).firstOrNull;
  @override
  Future<List<Ticket>> forPipelineRun(String w, String runId) async =>
      store.values
          .where((t) => t.workspaceId == w && t.pipelineRunId == runId)
          .toList();
  @override
  Future<List<Ticket>> forPipelineStep(
    String w,
    String runId,
    String stepId,
  ) async =>
      store.values
          .where((t) =>
              t.workspaceId == w &&
              t.pipelineRunId == runId &&
              t.pipelineStepId == stepId)
          .toList();
  @override
  Future<List<Ticket>> forAgent(String w, String agentId) async =>
      store.values
          .where((t) => t.workspaceId == w && t.assignedAgentId == agentId)
          .toList();
  @override
  Future<List<Ticket>> childrenOf(String w, String parentId) async =>
      store.values
          .where((t) => t.workspaceId == w && t.parentTicketId == parentId)
          .toList();
  @override
  Stream<List<Ticket>> watchForWorkspace(String w) =>
      Stream.value(store.values.where((t) => t.workspaceId == w).toList());
  @override
  Stream<List<Ticket>> watchByStatus(String w, TicketStatus s) =>
      Stream.value(store.values
          .where((t) => t.workspaceId == w && t.status == s)
          .toList());
  @override
  Stream<List<Ticket>> watchByAssignee(String w, String a) =>
      Stream.value(store.values
          .where((t) => t.workspaceId == w && t.assignedAgentId == a)
          .toList());
  @override
  Stream<List<Ticket>> watchForPipelineRun(String w, String r) =>
      Stream.value(store.values
          .where((t) => t.workspaceId == w && t.pipelineRunId == r)
          .toList());
  @override
  Future<void> addCollaborator(TicketCollaborator c) async =>
      (collabs[c.ticketId] ??= []).add(c);
  @override
  Future<void> removeCollaborator(String t, String a) async =>
      collabs[t]?.removeWhere((c) => c.agentId == a);
  @override
  Stream<List<TicketCollaborator>> watchCollaborators(String t) =>
      Stream.value(collabs[t] ?? const []);
  @override
  Future<List<TicketCollaborator>> getCollaborators(String t) async =>
      collabs[t] ?? const [];
}

void main() {
  late _FakeRepo repo;
  late DomainEventBus bus;
  late TicketWorkflowService service;
  late List<DomainEvent> events;

  setUp(() {
    repo = _FakeRepo();
    bus = DomainEventBus();
    service = TicketWorkflowService(
      repository: repo,
      eventBus: bus,
    );
    events = [];
    bus.on<DomainEvent>().listen(events.add);
  });

  test('createTicket persists and publishes TicketCreated', () async {
    final t = await service.createTicket(workspaceId: 'w', title: 'Do it');
    expect(repo.store[t.id]?.title, 'Do it');
    expect(t.status, TicketStatus.open);
    await Future<void>.delayed(Duration.zero);
    expect(events.whereType<TicketCreated>(), hasLength(1));
  });

  test('createTicket with parent publishes TicketDelegated', () async {
    await service.createTicket(
      workspaceId: 'w',
      title: 'Child',
      parentTicketId: 'parent',
      assignedAgentId: 'agent-1',
    );
    await Future<void>.delayed(Duration.zero);
    expect(events.whereType<TicketDelegated>(), hasLength(1));
    expect(events.whereType<TicketAssigned>(), hasLength(1));
  });

  test('completeTicket sets output, done status, fires events', () async {
    final t = await service.createTicket(workspaceId: 'w', title: 'X');
    await service.completeTicket(t.id, workspaceId: 'w', output: {'result': 'ok'});
    final stored = repo.store[t.id]!;
    expect(stored.status, TicketStatus.done);
    expect(stored.outputJson, {'result': 'ok'});
    await Future<void>.delayed(Duration.zero);
    expect(events.whereType<TicketCompleted>(), hasLength(1));
  });

  test('terminal guard: completing twice is a no-op', () async {
    final t = await service.createTicket(workspaceId: 'w', title: 'X');
    await service.completeTicket(t.id, workspaceId: 'w');
    await service.failTicket(t.id, 'boom', workspaceId: 'w');
    expect(repo.store[t.id]!.status, TicketStatus.done);
  });

  test('transitionStatus respects the transition graph', () async {
    final t = await service.createTicket(workspaceId: 'w', title: 'X');
    // open -> done is not a legal direct transition (must pass through work).
    await service.transitionStatus(t.id, TicketStatus.done, workspaceId: 'w');
    expect(repo.store[t.id]!.status, TicketStatus.open);
    // open -> inProgress -> done is legal.
    await service.transitionStatus(t.id, TicketStatus.inProgress,
        workspaceId: 'w');
    await service.transitionStatus(t.id, TicketStatus.done, workspaceId: 'w');
    expect(repo.store[t.id]!.status, TicketStatus.done);
  });

  test('transitionStatus with force bypasses the transition graph', () async {
    final t = await service.createTicket(workspaceId: 'w', title: 'X');
    await service.transitionStatus(t.id, TicketStatus.inProgress,
        workspaceId: 'w');
    // inProgress -> open is illegal in the graph, but a forced (user-driven)
    // transition applies it anyway.
    await service.transitionStatus(t.id, TicketStatus.open,
        workspaceId: 'w', force: true);
    expect(repo.store[t.id]!.status, TicketStatus.open);
  });

  test('transitionStatus with force can reopen a terminal ticket', () async {
    final t = await service.createTicket(workspaceId: 'w', title: 'X');
    await service.transitionStatus(t.id, TicketStatus.inProgress,
        workspaceId: 'w');
    await service.completeTicket(t.id, workspaceId: 'w');
    expect(repo.store[t.id]!.status, TicketStatus.done);
    expect(repo.store[t.id]!.finishedAt, isNotNull);
    // A non-forced transition out of a terminal state is a no-op...
    await service.transitionStatus(t.id, TicketStatus.inProgress,
        workspaceId: 'w');
    expect(repo.store[t.id]!.status, TicketStatus.done);
    // ...but a forced one reopens it and clears the finished timestamp.
    await service.transitionStatus(t.id, TicketStatus.inProgress,
        workspaceId: 'w', force: true);
    expect(repo.store[t.id]!.status, TicketStatus.inProgress);
    expect(repo.store[t.id]!.finishedAt, isNull);
  });

  test('addCollaborator stores and publishes', () async {
    final t = await service.createTicket(workspaceId: 'w', title: 'X');
    await service.addCollaborator(t.id, workspaceId: 'w', agentId: 'agent-2');
    expect(repo.collabs[t.id], hasLength(1));
    await Future<void>.delayed(Duration.zero);
    expect(events.whereType<TicketCollaboratorAdded>(), hasLength(1));
  });

  test('deleteTicket removes the ticket and its collaborators', () async {
    final t = await service.createTicket(workspaceId: 'w', title: 'X');
    await service.addCollaborator(t.id, workspaceId: 'w', agentId: 'agent-2');
    expect(repo.store[t.id], isNotNull);

    await service.deleteTicket(t.id, workspaceId: 'w');

    expect(repo.store[t.id], isNull);
    expect(repo.collabs[t.id] ?? const [], isEmpty);
  });

  test('deleteTicket on a missing ticket is a no-op', () async {
    await service.deleteTicket('does-not-exist', workspaceId: 'w');
    expect(repo.store, isEmpty);
  });

  group('pull request links', () {
    test('linkPullRequest appends the node id; relinking is idempotent',
        () async {
      final t = await service.createTicket(workspaceId: 'w', title: 'X');
      await service.linkPullRequest(t.id, 'PR_node_1', workspaceId: 'w');
      expect(repo.store[t.id]!.linkedPrIds, ['PR_node_1']);

      // Linking the same PR again does not duplicate it.
      await service.linkPullRequest(t.id, 'PR_node_1', workspaceId: 'w');
      expect(repo.store[t.id]!.linkedPrIds, ['PR_node_1']);

      await service.linkPullRequest(t.id, 'PR_node_2', workspaceId: 'w');
      expect(repo.store[t.id]!.linkedPrIds, ['PR_node_1', 'PR_node_2']);
    });

    test('unlinkPullRequest removes the node id; unlinking absent is a no-op',
        () async {
      final t = await service.createTicket(workspaceId: 'w', title: 'X');
      await service.linkPullRequest(t.id, 'PR_node_1', workspaceId: 'w');
      await service.linkPullRequest(t.id, 'PR_node_2', workspaceId: 'w');

      await service.unlinkPullRequest(t.id, 'PR_node_1', workspaceId: 'w');
      expect(repo.store[t.id]!.linkedPrIds, ['PR_node_2']);

      // Unlinking a PR that isn't linked leaves the list untouched.
      await service.unlinkPullRequest(t.id, 'PR_node_1', workspaceId: 'w');
      expect(repo.store[t.id]!.linkedPrIds, ['PR_node_2']);
    });
  });

  group('workspace isolation', () {
    test('deleteTicket from a different workspace is rejected and the ticket '
        'survives', () async {
      final t = await service.createTicket(workspaceId: 'w', title: 'X');

      await expectLater(
        () => service.deleteTicket(t.id, workspaceId: 'other-ws'),
        throwsA(isA<WorkspaceMismatchException>()),
      );
      expect(repo.store[t.id], isNotNull);

      // The owning workspace can delete it.
      await service.deleteTicket(t.id, workspaceId: 'w');
      expect(repo.store[t.id], isNull);
    });

    test('rejects a mutation from a different workspace with an explicit '
        'WorkspaceMismatchException and leaves the ticket untouched', () async {
      final t = await service.createTicket(workspaceId: 'w', title: 'X');

      await expectLater(
        () => service.completeTicket(t.id, workspaceId: 'other-ws'),
        throwsA(isA<WorkspaceMismatchException>()),
      );
      // The cross-workspace caller never mutated the ticket.
      expect(repo.store[t.id]!.status, TicketStatus.open);

      // The owning workspace can still operate normally.
      await service.completeTicket(t.id, workspaceId: 'w');
      expect(repo.store[t.id]!.status, TicketStatus.done);
    });

    test('every by-id mutation enforces the workspace guard', () async {
      final t = await service.createTicket(workspaceId: 'w', title: 'X');
      const wrong = 'other-ws';
      await expectLater(
        () => service.failTicket(t.id, 'boom', workspaceId: wrong),
        throwsA(isA<WorkspaceMismatchException>()),
      );
      await expectLater(
        () => service.cancelTicket(t.id, workspaceId: wrong),
        throwsA(isA<WorkspaceMismatchException>()),
      );
      await expectLater(
        () => service.assign(t.id, workspaceId: wrong, agentId: 'a'),
        throwsA(isA<WorkspaceMismatchException>()),
      );
      await expectLater(
        () => service.addCollaborator(t.id, workspaceId: wrong, agentId: 'a'),
        throwsA(isA<WorkspaceMismatchException>()),
      );
      await expectLater(
        () => service.linkPullRequest(t.id, 'PR_x', workspaceId: wrong),
        throwsA(isA<WorkspaceMismatchException>()),
      );
      await expectLater(
        () => service.unlinkPullRequest(t.id, 'PR_x', workspaceId: wrong),
        throwsA(isA<WorkspaceMismatchException>()),
      );
      // Untouched throughout.
      expect(repo.store[t.id]!.status, TicketStatus.open);
      expect(repo.collabs[t.id] ?? const [], isEmpty);
      expect(repo.store[t.id]!.linkedPrIds, isEmpty);
    });
  });
}
