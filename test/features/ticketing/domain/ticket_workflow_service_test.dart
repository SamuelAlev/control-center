import 'package:control_center/core/domain/events/domain_event_bus.dart';
import 'package:control_center/core/domain/events/ticketing_events.dart';
import 'package:control_center/core/errors/app_exceptions.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket_collaborator.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket_priority.dart';
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

  group('tryStart', () {
    test('open -> inProgress returns true and publishes events', () async {
      final t = await service.createTicket(workspaceId: 'w', title: 'X');
      final result = await service.tryStart(t.id, workspaceId: 'w');
      expect(result, isTrue);
      expect(repo.store[t.id]!.status, TicketStatus.inProgress);
      expect(repo.store[t.id]!.startedAt, isNotNull);
      await Future<void>.delayed(Duration.zero);
      expect(events.whereType<TicketStatusChanged>(), hasLength(1));
      expect(events.whereType<TicketStarted>(), hasLength(1));
    });

    test('backlog -> inProgress returns true and publishes events', () async {
      final t = await service.createTicket(
        workspaceId: 'w',
        title: 'X',
        status: TicketStatus.backlog,
      );
      final result = await service.tryStart(t.id, workspaceId: 'w');
      expect(result, isTrue);
      expect(repo.store[t.id]!.status, TicketStatus.inProgress);
      await Future<void>.delayed(Duration.zero);
      expect(events.whereType<TicketStarted>(), hasLength(1));
    });

    test('returns false when already started', () async {
      final t = await service.createTicket(workspaceId: 'w', title: 'X');
      await service.tryStart(t.id, workspaceId: 'w');
      final result = await service.tryStart(t.id, workspaceId: 'w');
      expect(result, isFalse);
    });

    test('returns false when terminal', () async {
      final t = await service.createTicket(workspaceId: 'w', title: 'X');
      await service.completeTicket(t.id, workspaceId: 'w');
      final result = await service.tryStart(t.id, workspaceId: 'w');
      expect(result, isFalse);
    });

    test('returns false when ticket does not exist', () async {
      final result = await service.tryStart('does-not-exist', workspaceId: 'w');
      expect(result, isFalse);
    });
  });

  test('startTicket delegates to tryStart', () async {
    final t = await service.createTicket(workspaceId: 'w', title: 'X');
    await service.startTicket(t.id, workspaceId: 'w');
    expect(repo.store[t.id]!.status, TicketStatus.inProgress);
  });

  test('failTicket sets status, error message, and publishes events', () async {
    final t = await service.createTicket(workspaceId: 'w', title: 'X');
    await service.failTicket(t.id, 'something broke', workspaceId: 'w');
    final stored = repo.store[t.id]!;
    expect(stored.status, TicketStatus.failed);
    expect(stored.errorMessage, 'something broke');
    expect(stored.finishedAt, isNotNull);
    await Future<void>.delayed(Duration.zero);
    expect(events.whereType<TicketFailed>(), hasLength(1));
    final failedEvent = events.whereType<TicketFailed>().single;
    expect(failedEvent.errorMessage, 'something broke');
    expect(events.whereType<TicketStatusChanged>(), hasLength(1));
  });

  test('failTicket with force on already-terminal ticket applies anyway',
      () async {
    final t = await service.createTicket(workspaceId: 'w', title: 'X');
    await service.completeTicket(t.id, workspaceId: 'w');
    await service.failTicket(t.id, 'override', workspaceId: 'w', force: true);
    expect(repo.store[t.id]!.status, TicketStatus.failed);
    expect(repo.store[t.id]!.errorMessage, 'override');
  });

  test('cancelTicket sets status, finishedAt, and publishes events', () async {
    final t = await service.createTicket(workspaceId: 'w', title: 'X');
    await service.cancelTicket(t.id, workspaceId: 'w');
    final stored = repo.store[t.id]!;
    expect(stored.status, TicketStatus.cancelled);
    expect(stored.finishedAt, isNotNull);
    await Future<void>.delayed(Duration.zero);
    expect(events.whereType<TicketCancelled>(), hasLength(1));
    expect(events.whereType<TicketStatusChanged>(), hasLength(1));
  });

  test('cancelTicket with force on already-terminal ticket applies anyway',
      () async {
    final t = await service.createTicket(workspaceId: 'w', title: 'X');
    await service.completeTicket(t.id, workspaceId: 'w');
    await service.cancelTicket(t.id, workspaceId: 'w', force: true);
    expect(repo.store[t.id]!.status, TicketStatus.cancelled);
  });

  test('completeTicket with force on already-terminal ticket applies anyway',
      () async {
    final t = await service.createTicket(workspaceId: 'w', title: 'X');
    await service.cancelTicket(t.id, workspaceId: 'w');
    await service.completeTicket(t.id, workspaceId: 'w', force: true);
    expect(repo.store[t.id]!.status, TicketStatus.done);
  });

  group('assign', () {
    test('assigns agent and publishes TicketAssigned', () async {
      final t = await service.createTicket(workspaceId: 'w', title: 'X');
      await service.assign(t.id, workspaceId: 'w', agentId: 'agent-1');
      expect(repo.store[t.id]!.assignedAgentId, 'agent-1');
      await Future<void>.delayed(Duration.zero);
      expect(events.whereType<TicketAssigned>(), hasLength(1));
    });

    test('assigns team and publishes TicketAssigned', () async {
      final t = await service.createTicket(workspaceId: 'w', title: 'X');
      await service.assign(t.id, workspaceId: 'w', teamId: 'team-1');
      expect(repo.store[t.id]!.assignedTeamId, 'team-1');
    });
  });

  group('reassign', () {
    test('reassigns to new agent, publishes TicketReassigned and '
        'TicketAssigned', () async {
      final t = await service.createTicket(
        workspaceId: 'w',
        title: 'X',
        assignedAgentId: 'agent-1',
      );
      // Drain create events, then use a fresh list for reassign events only.
      await Future<void>.delayed(Duration.zero);
      final reassignEvents = <DomainEvent>[];
      final sub = bus.on<DomainEvent>().listen(reassignEvents.add);
      await service.reassign(t.id, workspaceId: 'w', toAgentId: 'agent-2');
      expect(repo.store[t.id]!.assignedAgentId, 'agent-2');
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();
      expect(reassignEvents.whereType<TicketReassigned>(), hasLength(1));
      final reassignEvent = reassignEvents.whereType<TicketReassigned>().single;
      expect(reassignEvent.fromAgentId, 'agent-1');
      expect(reassignEvent.toAgentId, 'agent-2');
      expect(reassignEvents.whereType<TicketAssigned>(), hasLength(1));
    });

    test('reassign to null fires TicketReassigned but no TicketAssigned',
        () async {
      final t = await service.createTicket(
        workspaceId: 'w',
        title: 'X',
        assignedAgentId: 'agent-1',
      );
      await Future<void>.delayed(Duration.zero);
      final reassignEvents = <DomainEvent>[];
      final sub = bus.on<DomainEvent>().listen(reassignEvents.add);
      // reassign with null toAgentId — copyWith treats null as "keep current"
      // so assignedAgentId stays 'agent-1', but the event still fires.
      await service.reassign(t.id, workspaceId: 'w', toAgentId: null);
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();
      // assignedAgentId unchanged (copyWith null means "keep current").
      expect(repo.store[t.id]!.assignedAgentId, 'agent-1');
      expect(reassignEvents.whereType<TicketReassigned>(), hasLength(1));
      expect(reassignEvents.whereType<TicketAssigned>(), isEmpty);
    });
  });

  test('updateDetails updates fields and publishes TicketDetailsUpdated',
      () async {
    final t = await service.createTicket(workspaceId: 'w', title: 'Old');
    await service.updateDetails(
      t.id,
      workspaceId: 'w',
      title: 'New Title',
      description: 'New Desc',
    );
    final stored = repo.store[t.id]!;
    expect(stored.title, 'New Title');
    expect(stored.description, 'New Desc');
    await Future<void>.delayed(Duration.zero);
    expect(events.whereType<TicketDetailsUpdated>(), hasLength(1));
  });

  test('attachChannel sets channelId and is idempotent', () async {
    final t = await service.createTicket(workspaceId: 'w', title: 'X');
    await service.attachChannel(t.id, 'ch-1', workspaceId: 'w');
    expect(repo.store[t.id]!.channelId, 'ch-1');
    final versionAfterFirst = repo.store[t.id]!.version;
    // Second attach with same channel is a no-op.
    await service.attachChannel(t.id, 'ch-1', workspaceId: 'w');
    expect(repo.store[t.id]!.version, versionAfterFirst);
    // Attach to a different channel does mutate.
    await service.attachChannel(t.id, 'ch-2', workspaceId: 'w');
    expect(repo.store[t.id]!.channelId, 'ch-2');
    expect(repo.store[t.id]!.version, greaterThan(versionAfterFirst));
  });

  group('setParent', () {
    test('sets parent and publishes TicketDetailsUpdated', () async {
      final parent = await service.createTicket(workspaceId: 'w', title: 'P');
      final child = await service.createTicket(workspaceId: 'w', title: 'C');
      await service.setParent(child.id, parent.id, workspaceId: 'w');
      expect(repo.store[child.id]!.parentTicketId, parent.id);
      await Future<void>.delayed(Duration.zero);
      expect(events.whereType<TicketDetailsUpdated>(), hasLength(1));
    });

    test('throws ArgumentError when ticket is its own parent', () async {
      final t = await service.createTicket(workspaceId: 'w', title: 'X');
      await expectLater(
        () => service.setParent(t.id, t.id, workspaceId: 'w'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('throws ArgumentError when parent does not exist', () async {
      final t = await service.createTicket(workspaceId: 'w', title: 'X');
      await expectLater(
        () => service.setParent(t.id, 'does-not-exist', workspaceId: 'w'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test(
        'throws WorkspaceMismatchException when parent is in a different '
        'workspace', () async {
      final parent =
          await service.createTicket(workspaceId: 'other', title: 'P');
      final child = await service.createTicket(workspaceId: 'w', title: 'C');
      await expectLater(
        () => service.setParent(child.id, parent.id, workspaceId: 'w'),
        throwsA(isA<WorkspaceMismatchException>()),
      );
    });

    test('throws ArgumentError when setting parent would create a cycle',
        () async {
      final a = await service.createTicket(workspaceId: 'w', title: 'A');
      final b = await service.createTicket(workspaceId: 'w', title: 'B');
      final c = await service.createTicket(workspaceId: 'w', title: 'C');
      // a -> b -> c
      await service.setParent(b.id, a.id, workspaceId: 'w');
      await service.setParent(c.id, b.id, workspaceId: 'w');
      // Setting a's parent to c would create a cycle (c -> b -> a).
      await expectLater(
        () => service.setParent(a.id, c.id, workspaceId: 'w'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('setParent to same parent is a no-op', () async {
      final parent = await service.createTicket(workspaceId: 'w', title: 'P');
      final child = await service.createTicket(workspaceId: 'w', title: 'C');
      await service.setParent(child.id, parent.id, workspaceId: 'w');
      final versionAfterFirst = repo.store[child.id]!.version;
      await service.setParent(child.id, parent.id, workspaceId: 'w');
      expect(repo.store[child.id]!.version, versionAfterFirst);
    });
  });

  group('clearParent', () {
    test('clears parent and publishes TicketDetailsUpdated', () async {
      final parent = await service.createTicket(workspaceId: 'w', title: 'P');
      final child = await service.createTicket(workspaceId: 'w', title: 'C');
      await service.setParent(child.id, parent.id, workspaceId: 'w');
      await service.clearParent(child.id, workspaceId: 'w');
      expect(repo.store[child.id]!.parentTicketId, isNull);
    });

    test('clearParent when already null is a no-op', () async {
      final t = await service.createTicket(workspaceId: 'w', title: 'X');
      final versionBefore = repo.store[t.id]!.version;
      await service.clearParent(t.id, workspaceId: 'w');
      expect(repo.store[t.id]!.version, versionBefore);
    });
  });

  group('setProject', () {
    test('sets project and publishes TicketDetailsUpdated', () async {
      final t = await service.createTicket(workspaceId: 'w', title: 'X');
      await service.setProject(t.id, 'proj-1', workspaceId: 'w');
      expect(repo.store[t.id]!.projectId, 'proj-1');
    });

    test('setting same project is idempotent', () async {
      final t = await service.createTicket(workspaceId: 'w', title: 'X');
      await service.setProject(t.id, 'proj-1', workspaceId: 'w');
      final versionAfterFirst = repo.store[t.id]!.version;
      await service.setProject(t.id, 'proj-1', workspaceId: 'w');
      expect(repo.store[t.id]!.version, versionAfterFirst);
    });

    test('clears project when null is passed', () async {
      final t = await service.createTicket(workspaceId: 'w', title: 'X');
      await service.setProject(t.id, 'proj-1', workspaceId: 'w');
      await service.setProject(t.id, null, workspaceId: 'w');
      expect(repo.store[t.id]!.projectId, isNull);
    });
  });

  test('delegate creates a child ticket with parent and assignee', () async {
    await service.delegate(
      workspaceId: 'w',
      title: 'Sub-task',
      parentTicketId: 'parent-1',
      delegatedByAgentId: 'delegator',
      assignedAgentId: 'assignee',
    );
    final child = repo.store.values.first;
    expect(child.title, 'Sub-task');
    expect(child.parentTicketId, 'parent-1');
    expect(child.delegatedByAgentId, 'delegator');
    expect(child.assignedAgentId, 'assignee');
    expect(child.provider, TicketProvider.local);
    await Future<void>.delayed(Duration.zero);
    expect(events.whereType<TicketDelegated>(), hasLength(1));
    expect(events.whereType<TicketAssigned>(), hasLength(1));
  });

  group('transitionStatus non-terminal targets', () {
    test('open -> blocked', () async {
      final t = await service.createTicket(workspaceId: 'w', title: 'X');
      await service.transitionStatus(t.id, TicketStatus.blocked,
          workspaceId: 'w');
      expect(repo.store[t.id]!.status, TicketStatus.blocked);
    });

    test('inProgress -> inReview', () async {
      final t = await service.createTicket(workspaceId: 'w', title: 'X');
      await service.tryStart(t.id, workspaceId: 'w');
      await service.transitionStatus(t.id, TicketStatus.inReview,
          workspaceId: 'w');
      expect(repo.store[t.id]!.status, TicketStatus.inReview);
    });

    test('blocked -> inProgress', () async {
      final t = await service.createTicket(workspaceId: 'w', title: 'X');
      await service.transitionStatus(t.id, TicketStatus.blocked,
          workspaceId: 'w');
      await service.transitionStatus(t.id, TicketStatus.inProgress,
          workspaceId: 'w');
      expect(repo.store[t.id]!.status, TicketStatus.inProgress);
    });

    test('inReview -> inProgress (revision)', () async {
      final t = await service.createTicket(workspaceId: 'w', title: 'X');
      await service.tryStart(t.id, workspaceId: 'w');
      await service.transitionStatus(t.id, TicketStatus.inReview,
          workspaceId: 'w');
      await service.transitionStatus(t.id, TicketStatus.inProgress,
          workspaceId: 'w');
      expect(repo.store[t.id]!.status, TicketStatus.inProgress);
    });

    test('backlog -> open', () async {
      final t = await service.createTicket(
        workspaceId: 'w',
        title: 'X',
        status: TicketStatus.backlog,
      );
      await service.transitionStatus(t.id, TicketStatus.open, workspaceId: 'w');
      expect(repo.store[t.id]!.status, TicketStatus.open);
    });

    test('backlog -> cancelled (terminal via transitionStatus)', () async {
      final t = await service.createTicket(
        workspaceId: 'w',
        title: 'X',
        status: TicketStatus.backlog,
      );
      await service.transitionStatus(t.id, TicketStatus.cancelled,
          workspaceId: 'w');
      expect(repo.store[t.id]!.status, TicketStatus.cancelled);
    });
  });

  test('transitionStatus on missing ticket is a no-op', () async {
    await service.transitionStatus(
        'does-not-exist', TicketStatus.inProgress, workspaceId: 'w');
    expect(repo.store, isEmpty);
  });

  test('transitionStatus illegal non-terminal target is a no-op', () async {
    final t = await service.createTicket(workspaceId: 'w', title: 'X');
    // open -> inReview is not a legal transition.
    await service.transitionStatus(t.id, TicketStatus.inReview,
        workspaceId: 'w');
    expect(repo.store[t.id]!.status, TicketStatus.open);
  });

  test('transitionStatus from terminal (no force) is a no-op', () async {
    final t = await service.createTicket(workspaceId: 'w', title: 'X');
    await service.completeTicket(t.id, workspaceId: 'w');
    await service.transitionStatus(t.id, TicketStatus.inProgress,
        workspaceId: 'w');
    expect(repo.store[t.id]!.status, TicketStatus.done);
  });

  test('addCollaborator on missing ticket is a no-op', () async {
    await service.addCollaborator('does-not-exist',
        workspaceId: 'w', agentId: 'agent-1');
    expect(repo.collabs, isEmpty);
  });

  test('createTicket with local provider generates externalKey', () async {
    final t = await service.createTicket(workspaceId: 'w', title: 'X');
    expect(t.provider, TicketProvider.local);
    expect(t.externalKey, isNotNull);
  });

  test('createTicket with non-local provider has null externalKey', () async {
    final t = await service.createTicket(
      workspaceId: 'w',
      title: 'X',
      provider: TicketProvider.linear,
    );
    expect(t.externalKey, isNull);
  });

  group('addCollaborator edge cases', () {
    test('addCollaborator with custom role', () async {
      final t = await service.createTicket(workspaceId: 'w', title: 'X');
      await service.addCollaborator(t.id, workspaceId: 'w', agentId: 'agent-2',
          role: TicketCollaboratorRole.reviewer);
      final collabs = repo.collabs[t.id]!;
      expect(collabs, hasLength(1));
      expect(collabs.first.role, TicketCollaboratorRole.reviewer);
    });

    test('adding duplicate collaborator adds twice', () async {
      final t = await service.createTicket(workspaceId: 'w', title: 'X');
      await service.addCollaborator(t.id, workspaceId: 'w', agentId: 'agent-2');
      await service.addCollaborator(t.id, workspaceId: 'w', agentId: 'agent-2');
      expect(repo.collabs[t.id], hasLength(2));
    });

    test('addCollaborator on missing ticket is a no-op', () async {
      await service.addCollaborator('does-not-exist',
          workspaceId: 'w', agentId: 'agent-1');
      expect(repo.collabs, isEmpty);
    });
  });


  group('createTicket advanced', () {
    test('createTicket with all optional fields populated', () async {
      final t = await service.createTicket(
        workspaceId: 'w',
        title: 'Full',
        description: 'A detailed description.',
        priority: TicketPriority.urgent,
        labels: ['backend', 'urgent'],
        projectId: 'proj-1',
        channelId: 'ch-pre',
        pipelineRunId: 'run-1',
        pipelineStepId: 'step-3',
        expectedOutputSchema: {'type': 'object'},
      );
      expect(t.title, 'Full');
      expect(t.description, 'A detailed description.');
      expect(t.priority, TicketPriority.urgent);
      expect(t.labels, ['backend', 'urgent']);
      expect(t.projectId, 'proj-1');
      expect(t.channelId, 'ch-pre');
      expect(t.pipelineRunId, 'run-1');
      expect(t.pipelineStepId, 'step-3');
      expect(t.expectedOutputSchema, {'type': 'object'});
    });

    test('createTicket with custom id preserves it', () async {
      final t = await service.createTicket(
        id: 'custom-id-123',
        workspaceId: 'w',
        title: 'Custom',
      );
      expect(t.id, 'custom-id-123');
      expect(repo.store['custom-id-123']!.title, 'Custom');
    });

    test('createTicket with duplicate id overwrites in store', () async {
      await service.createTicket(
        id: 'dup-id',
        workspaceId: 'w',
        title: 'First',
      );
      await service.createTicket(
        id: 'dup-id',
        workspaceId: 'w',
        title: 'Second',
      );
      expect(repo.store['dup-id']!.title, 'Second');
    });
  });

  group('updateDetails cherry-picking', () {
    test('updateDetails with only title does not touch other fields', () async {
      final t = await service.createTicket(
        workspaceId: 'w',
        title: 'Old',
        description: 'Old desc',
        priority: TicketPriority.urgent,
      );
      await service.updateDetails(t.id, workspaceId: 'w', title: 'New');
      final stored = repo.store[t.id]!;
      expect(stored.title, 'New');
      expect(stored.description, 'Old desc');
      expect(stored.priority, TicketPriority.urgent);
    });

    test('updateDetails with only priority does not touch title', () async {
      final t = await service.createTicket(
        workspaceId: 'w',
        title: 'Keep title',
        priority: TicketPriority.low,
      );
      await service.updateDetails(t.id, workspaceId: 'w',
          priority: TicketPriority.high);
      expect(repo.store[t.id]!.title, 'Keep title');
      expect(repo.store[t.id]!.priority, TicketPriority.high);
    });

    test('updateDetails with only description preserves title', () async {
      final t = await service.createTicket(workspaceId: 'w', title: 'Keep');
      await service.updateDetails(t.id, workspaceId: 'w',
          description: 'New desc');
      expect(repo.store[t.id]!.title, 'Keep');
      expect(repo.store[t.id]!.description, 'New desc');
    });
  });

  group('createTicket status variants', () {
    test('createTicket with backlog status', () async {
      final t = await service.createTicket(
        workspaceId: 'w',
        title: 'Backlog item',
        status: TicketStatus.backlog,
      );
      expect(t.status, TicketStatus.backlog);
      expect(repo.store[t.id]!.status, TicketStatus.backlog);
    });

    test('backlog ticket can be started', () async {
      final t = await service.createTicket(
        workspaceId: 'w',
        title: 'Backlog item',
        status: TicketStatus.backlog,
      );
      final result = await service.tryStart(t.id, workspaceId: 'w');
      expect(result, isTrue);
      expect(repo.store[t.id]!.status, TicketStatus.inProgress);
    });
  });
}
