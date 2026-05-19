
import 'package:control_center/core/database/app_database.dart';
import 'package:control_center/core/database/daos/ticket_dao.dart';
import 'package:control_center/core/errors/app_exceptions.dart';
import 'package:control_center/features/ticketing/data/repositories/dao_ticket_repository.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket_collaborator.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket_origin_kind.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket_priority.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket_provider.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket_status.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_database.dart';

/// Constructs a [Ticket] with defaults suitable for testing.
Ticket _ticket({
  String id = 't-1',
  String workspaceId = 'ws-1',
  String title = 'Test ticket',
  TicketStatus status = TicketStatus.open,
  TicketProvider provider = TicketProvider.local,
  DateTime? createdAt,
  DateTime? updatedAt,
  int version = 0,
  String? assignedAgentId,
  String? assignedTeamId,
  String? pipelineRunId,
  String? pipelineStepId,
  String? parentTicketId,
  String? externalKey,
  String? url,
  String? description,
  List<String> labels = const [],
  TicketPriority priority = TicketPriority.none,
  TicketOriginKind originKind = TicketOriginKind.manual,
}) {
  final now = DateTime(2026, 6, 1);
  return Ticket(
    id: id,
    workspaceId: workspaceId,
    title: title,
    status: status,
    provider: provider,
    createdAt: createdAt ?? now,
    updatedAt: updatedAt ?? now,
    version: version,
    assignedAgentId: assignedAgentId,
    assignedTeamId: assignedTeamId,
    pipelineRunId: pipelineRunId,
    pipelineStepId: pipelineStepId,
    parentTicketId: parentTicketId,
    externalKey: externalKey,
    url: url,
    description: description,
    labels: labels,
    priority: priority,
    originKind: originKind,
  );
}

/// Constructs a [TicketCollaborator] with defaults.
TicketCollaborator _collaborator({
  String id = 'c-1',
  String ticketId = 't-1',
  String agentId = 'agent-1',
  DateTime? joinedAt,
}) {
  return TicketCollaborator(
    id: id,
    ticketId: ticketId,
    agentId: agentId,
    joinedAt: joinedAt ?? DateTime(2026, 6, 1),
  );
}

/// Inserts a pipeline run row so FK constraints on `tickets.pipeline_run_id`
/// are satisfied.
Future<void> _seedPipelineRun(
  AppDatabase db, {
  required String id,
  String templateId = 'tmpl-1',
  String workspaceId = 'ws-1',
}) =>
    db.into(db.pipelineRunsTable).insert(
          PipelineRunsTableCompanion.insert(
            id: id,
            templateId: templateId,
            workspaceId: workspaceId,
          ),
        );

void main() {
  late AppDatabase db;
  late TicketDao dao;
  late DaoTicketRepository repo;

  setUp(() {
    db = createTestDatabase();
    dao = TicketDao(db);
    repo = DaoTicketRepository(dao);
  });

  tearDown(() async {
    await db.close();
  });

  // ---------------------------------------------------------------------------
  // CRUD
  // ---------------------------------------------------------------------------

  group('insert', () {
    test('inserts a ticket which can be fetched back', () async {
      final ticket = _ticket(id: 't-1', title: 'Hello');
      await repo.insert(ticket);

      final fetched = await repo.getById('t-1');
      expect(fetched, isNotNull);
      expect(fetched!.id, 't-1');
      expect(fetched.title, 'Hello');
      expect(fetched.status, TicketStatus.open);
      expect(fetched.workspaceId, 'ws-1');
      expect(fetched.version, 0);
    });

    test('inserted ticket has collaborators empty by default', () async {
      await repo.insert(_ticket(id: 't-1'));

      final fetched = await repo.getById('t-1');
      expect(fetched!.collaborators, isEmpty);
    });
  });

  group('getById', () {
    test('returns null for non-existent ticket', () async {
      final result = await repo.getById('nonexistent');
      expect(result, isNull);
    });

    test('returns ticket with hydrated collaborators', () async {
      await repo.insert(_ticket(id: 't-1'));
      await repo.addCollaborator(_collaborator(ticketId: 't-1', agentId: 'alice'));
      await repo.addCollaborator(_collaborator(
        id: 'c-2',
        ticketId: 't-1',
        agentId: 'bob',
      ));

      final ticket = await repo.getById('t-1');
      expect(ticket!.collaborators.length, 2);
      expect(
        ticket.collaborators.map((c) => c.agentId),
        containsAll(['alice', 'bob']),
      );
    });
  });

  group('update', () {
    test('updates ticket fields', () async {
      await repo.insert(_ticket(id: 't-1', title: 'Old', version: 0));
      final updated = _ticket(
        id: 't-1',
        title: 'New',
        status: TicketStatus.inProgress,
        version: 1,
      );
      await repo.update(updated);

      final fetched = await repo.getById('t-1');
      expect(fetched!.title, 'New');
      expect(fetched.status, TicketStatus.inProgress);
      expect(fetched.version, 1);
    });

    test('blind update (no expectedVersion) succeeds', () async {
      await repo.insert(_ticket(id: 't-1', version: 0));
      await repo.update(_ticket(id: 't-1', title: 'Blind', version: 1));

      final fetched = await repo.getById('t-1');
      expect(fetched!.title, 'Blind');
    });

    test('optimistic update with correct expectedVersion succeeds', () async {
      await repo.insert(_ticket(id: 't-1', title: 'v0', version: 0));
      await repo.update(
        _ticket(id: 't-1', title: 'v1', version: 1),
        expectedVersion: 0,
      );

      final fetched = await repo.getById('t-1');
      expect(fetched!.title, 'v1');
      expect(fetched.version, 1);
    });

    test('optimistic update with stale expectedVersion throws', () async {
      await repo.insert(_ticket(id: 't-1', title: 'v0', version: 0));

      // First update bumps version to 1.
      await repo.update(
        _ticket(id: 't-1', title: 'v1', version: 1),
        expectedVersion: 0,
      );

      // Second update with stale expectedVersion of 0 should throw.
      await expectLater(
        repo.update(
          _ticket(id: 't-1', title: 'v2', version: 2),
          expectedVersion: 0,
        ),
        throwsA(isA<ConcurrencyConflictException>()),
      );
    });

    test('optimistic update on non-existent ticket throws', () async {
      await expectLater(
        repo.update(
          _ticket(id: 'no-such', title: 'Ghost', version: 1),
          expectedVersion: 0,
        ),
        throwsA(isA<ConcurrencyConflictException>()),
      );
    });

    test('update preserves workspace scoping', () async {
      await repo.insert(_ticket(id: 't-1', workspaceId: 'ws-1', title: 'WS1'));
      await repo.update(_ticket(id: 't-1', workspaceId: 'ws-1', title: 'UPD', version: 1));

      final ticket = await repo.getById('t-1');
      expect(ticket!.title, 'UPD');
      expect(ticket.workspaceId, 'ws-1');
    });
  });

  group('delete', () {
    test('deletes a ticket so getById returns null', () async {
      await repo.insert(_ticket(id: 't-1'));
      await repo.delete('t-1', workspaceId: 'ws-1');

      expect(await repo.getById('t-1'), isNull);
    });

    test('delete with wrong workspace scoping does not delete', () async {
      await repo.insert(_ticket(id: 't-1', workspaceId: 'ws-1'));
      await repo.delete('t-1', workspaceId: 'ws-2');

      // Ticket should still exist — wrong workspace.
      expect(await repo.getById('t-1'), isNotNull);
    });

    test('delete of non-existent ticket does not throw', () async {
      await repo.delete('no-such', workspaceId: 'ws-1');
      // No exception thrown = pass.
    });

    test('delete cascades to collaborators', () async {
      await repo.insert(_ticket(id: 't-1'));
      await repo.addCollaborator(_collaborator(ticketId: 't-1', agentId: 'alice'));

      await repo.delete('t-1', workspaceId: 'ws-1');

      // Re-insert and confirm no collaborators remain.
      await repo.insert(_ticket(id: 't-1'));
      final ticket = await repo.getById('t-1');
      expect(ticket!.collaborators, isEmpty);
    });

    test('delete cascades to child tickets', () async {
      await repo.insert(_ticket(id: 't-1', workspaceId: 'ws-1'));
      await repo.insert(_ticket(
        id: 't-2',
        workspaceId: 'ws-1',
        parentTicketId: 't-1',
      ));

      await repo.delete('t-1', workspaceId: 'ws-1');

      expect(await repo.getById('t-1'), isNull);
      expect(await repo.getById('t-2'), isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // Workspace Scoping
  // ---------------------------------------------------------------------------

  group('workspace scoping', () {
    test('getById returns ticket regardless of workspace (no scope filter)', () async {
      await repo.insert(_ticket(id: 't-1', workspaceId: 'ws-1'));
      await repo.insert(_ticket(id: 't-2', workspaceId: 'ws-2'));

      // getById has no workspace param — it finds by id alone.
      expect((await repo.getById('t-1'))!.workspaceId, 'ws-1');
      expect((await repo.getById('t-2'))!.workspaceId, 'ws-2');
    });

    test('forPipelineRun scopes to workspace', () async {
      await _seedPipelineRun(db, id: 'run-1');
      await repo.insert(_ticket(
        id: 't-1',
        workspaceId: 'ws-1',
        pipelineRunId: 'run-1',
      ));
      await repo.insert(_ticket(
        id: 't-2',
        workspaceId: 'ws-2',
        pipelineRunId: 'run-1',
      ));

      final ws1 = await repo.forPipelineRun('ws-1', 'run-1');
      expect(ws1.length, 1);
      expect(ws1.single.id, 't-1');

      final ws2 = await repo.forPipelineRun('ws-2', 'run-1');
      expect(ws2.length, 1);
      expect(ws2.single.id, 't-2');
    });

    test('forAgent scopes to workspace', () async {
      await repo.insert(_ticket(
        id: 't-1',
        workspaceId: 'ws-1',
        assignedAgentId: 'alice',
      ));
      await repo.insert(_ticket(
        id: 't-2',
        workspaceId: 'ws-2',
        assignedAgentId: 'alice',
      ));

      final ws1 = await repo.forAgent('ws-1', 'alice');
      expect(ws1.map((t) => t.id), ['t-1']);

      final ws2 = await repo.forAgent('ws-2', 'alice');
      expect(ws2.map((t) => t.id), ['t-2']);
    });

    test('childrenOf scopes to workspace', () async {
      await repo.insert(_ticket(id: 'parent', workspaceId: 'ws-1'));
      await repo.insert(_ticket(
        id: 'c-1',
        workspaceId: 'ws-1',
        parentTicketId: 'parent',
      ));
      await repo.insert(_ticket(
        id: 'c-2',
        workspaceId: 'ws-2',
        parentTicketId: 'parent',
      ));

      final ws1Children = await repo.childrenOf('ws-1', 'parent');
      expect(ws1Children.map((t) => t.id), ['c-1']);

      final ws2Children = await repo.childrenOf('ws-2', 'parent');
      expect(ws2Children.map((t) => t.id), ['c-2']);
    });

    test('forPipelineStep scopes to workspace', () async {
      await _seedPipelineRun(db, id: 'run-1');
      await repo.insert(_ticket(
        id: 't-1',
        workspaceId: 'ws-1',
        pipelineRunId: 'run-1',
        pipelineStepId: 'step-1',
      ));
      await repo.insert(_ticket(
        id: 't-2',
        workspaceId: 'ws-2',
        pipelineRunId: 'run-1',
        pipelineStepId: 'step-1',
      ));

      final ws1 = await repo.forPipelineStep('ws-1', 'run-1', 'step-1');
      expect(ws1.map((t) => t.id), ['t-1']);

      final ws2 = await repo.forPipelineStep('ws-2', 'run-1', 'step-1');
      expect(ws2.map((t) => t.id), ['t-2']);
    });
  });

  // ---------------------------------------------------------------------------
  // Watch Streams
  // ---------------------------------------------------------------------------

  group('watchForWorkspace', () {
    test('emits empty list when no tickets', () async {
      final tickets = await repo.watchForWorkspace('ws-1').first;
      expect(tickets, isEmpty);
    });

    test('emits tickets for the workspace, newest first', () async {
      await repo.insert(_ticket(
        id: 'older',
        workspaceId: 'ws-1',
        title: 'Older',
        updatedAt: DateTime(2026, 6, 1),
      ));
      await repo.insert(_ticket(
        id: 'newer',
        workspaceId: 'ws-1',
        title: 'Newer',
        updatedAt: DateTime(2026, 6, 10),
      ));

      final tickets = await repo.watchForWorkspace('ws-1').first;
      expect(tickets.length, 2);
      expect(tickets[0].id, 'newer');
      expect(tickets[1].id, 'older');
    });

    test('does not emit tickets from other workspaces', () async {
      await repo.insert(_ticket(id: 't-1', workspaceId: 'ws-1'));
      await repo.insert(_ticket(id: 't-2', workspaceId: 'ws-2'));

      final ws1 = await repo.watchForWorkspace('ws-1').first;
      expect(ws1.map((t) => t.id), ['t-1']);

      final ws2 = await repo.watchForWorkspace('ws-2').first;
      expect(ws2.map((t) => t.id), ['t-2']);
    });

    test('live stream emits updated list after insert', () async {
      final stream = repo.watchForWorkspace('ws-1');

      // First emission: empty.
      final first = await stream.first;
      expect(first, isEmpty);

      // Insert a ticket and start a new subscription to see it.
      await repo.insert(_ticket(id: 'live-1', workspaceId: 'ws-1'));

      final after = await repo.watchForWorkspace('ws-1').first;
      expect(after.map((t) => t.id), ['live-1']);
    });

    test('live stream emits updated list after update', () async {
      await repo.insert(_ticket(id: 't-1', workspaceId: 'ws-1', title: 'Old'));

      final stream = repo.watchForWorkspace('ws-1');
      final first = await stream.first;
      expect(first.single.title, 'Old');

      await repo.update(_ticket(
        id: 't-1',
        workspaceId: 'ws-1',
        title: 'New',
        version: 1,
        updatedAt: DateTime(2026, 6, 11),
      ));

      // New subscription sees updated data.
      final after = await repo.watchForWorkspace('ws-1').first;
      expect(after.single.title, 'New');
    });

    test('live stream emits after delete', () async {
      await repo.insert(_ticket(id: 't-1', workspaceId: 'ws-1'));
      final first = await repo.watchForWorkspace('ws-1').first;
      expect(first.length, 1);

      await repo.delete('t-1', workspaceId: 'ws-1');

      final after = await repo.watchForWorkspace('ws-1').first;
      expect(after, isEmpty);
    });
  });

  group('watchByStatus', () {
    test('emits only tickets matching the status', () async {
      await repo.insert(_ticket(
        id: 'open-1',
        workspaceId: 'ws-1',
        status: TicketStatus.open,
        updatedAt: DateTime(2026, 6, 1),
      ));
      await repo.insert(_ticket(
        id: 'done-1',
        workspaceId: 'ws-1',
        status: TicketStatus.done,
        updatedAt: DateTime(2026, 6, 2),
      ));
      await repo.insert(_ticket(
        id: 'open-2',
        workspaceId: 'ws-1',
        status: TicketStatus.open,
        updatedAt: DateTime(2026, 6, 3),
      ));

      final openTickets = await repo.watchByStatus('ws-1', TicketStatus.open).first;
      expect(openTickets.map((t) => t.id), ['open-2', 'open-1']);

      final doneTickets = await repo.watchByStatus('ws-1', TicketStatus.done).first;
      expect(doneTickets.map((t) => t.id), ['done-1']);
    });

    test('scoped to workspace — excludes other workspace tickets', () async {
      await repo.insert(_ticket(
        id: 't-1',
        workspaceId: 'ws-1',
        status: TicketStatus.open,
      ));
      await repo.insert(_ticket(
        id: 't-2',
        workspaceId: 'ws-2',
        status: TicketStatus.open,
      ));

      final ws1 = await repo.watchByStatus('ws-1', TicketStatus.open).first;
      expect(ws1.map((t) => t.id), ['t-1']);
    });

    test('emits empty when no tickets match that status', () async {
      await repo.insert(_ticket(
        id: 't-1',
        workspaceId: 'ws-1',
        status: TicketStatus.open,
      ));

      final done = await repo.watchByStatus('ws-1', TicketStatus.done).first;
      expect(done, isEmpty);
    });
  });

  group('watchByAssignee', () {
    test('emits tickets assigned to the agent', () async {
      await repo.insert(_ticket(
        id: 't-1',
        workspaceId: 'ws-1',
        assignedAgentId: 'alice',
        updatedAt: DateTime(2026, 6, 1),
      ));
      await repo.insert(_ticket(
        id: 't-2',
        workspaceId: 'ws-1',
        assignedAgentId: 'bob',
        updatedAt: DateTime(2026, 6, 2),
      ));
      await repo.insert(_ticket(
        id: 't-3',
        workspaceId: 'ws-1',
        assignedAgentId: 'alice',
        updatedAt: DateTime(2026, 6, 3),
      ));

      final aliceTickets = await repo.watchByAssignee('ws-1', 'alice').first;
      expect(aliceTickets.map((t) => t.id), ['t-3', 't-1']);

      final bobTickets = await repo.watchByAssignee('ws-1', 'bob').first;
      expect(bobTickets.map((t) => t.id), ['t-2']);
    });

    test('scoped to workspace', () async {
      await repo.insert(_ticket(
        id: 't-1',
        workspaceId: 'ws-1',
        assignedAgentId: 'alice',
      ));
      await repo.insert(_ticket(
        id: 't-2',
        workspaceId: 'ws-2',
        assignedAgentId: 'alice',
      ));

      final ws1 = await repo.watchByAssignee('ws-1', 'alice').first;
      expect(ws1.map((t) => t.id), ['t-1']);
    });

    test('emits empty when no tickets assigned to that agent', () async {
      await repo.insert(_ticket(id: 't-1', workspaceId: 'ws-1'));
      final result = await repo.watchByAssignee('ws-1', 'alice').first;
      expect(result, isEmpty);
    });
  });

  group('watchForPipelineRun', () {
    test('emits tickets for the pipeline run', () async {
      await _seedPipelineRun(db, id: 'run-1');
      await _seedPipelineRun(db, id: 'run-2');
      await repo.insert(_ticket(
        id: 't-1',
        workspaceId: 'ws-1',
        pipelineRunId: 'run-1',
      ));
      await repo.insert(_ticket(
        id: 't-2',
        workspaceId: 'ws-1',
        pipelineRunId: 'run-1',
      ));
      await repo.insert(_ticket(
        id: 't-3',
        workspaceId: 'ws-1',
        pipelineRunId: 'run-2',
      ));

      final run1 = await repo.watchForPipelineRun('ws-1', 'run-1').first;
      expect(run1.length, 2);
      expect(run1.map((t) => t.id), containsAll(['t-1', 't-2']));
    });

    test('scoped to workspace', () async {
      await _seedPipelineRun(db, id: 'run-1');
      await repo.insert(_ticket(
        id: 't-1',
        workspaceId: 'ws-1',
        pipelineRunId: 'run-1',
      ));
      await repo.insert(_ticket(
        id: 't-2',
        workspaceId: 'ws-2',
        pipelineRunId: 'run-1',
      ));

      final ws1 = await repo.watchForPipelineRun('ws-1', 'run-1').first;
      expect(ws1.map((t) => t.id), ['t-1']);
    });

    test('emits empty when no tickets for that pipeline run', () async {
      await repo.insert(_ticket(id: 't-1', workspaceId: 'ws-1'));
      final result = await repo.watchForPipelineRun('ws-1', 'no-such-run').first;
      expect(result, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // Filtering (read queries)
  // ---------------------------------------------------------------------------

  group('getByExternal', () {
    test('finds ticket by provider + external key', () async {
      await repo.insert(_ticket(
        id: 't-1',
        provider: TicketProvider.linear,
        externalKey: 'LIN-42',
      ));

      final ticket = await repo.getByExternal(TicketProvider.linear, 'LIN-42');
      expect(ticket, isNotNull);
      expect(ticket!.id, 't-1');
    });

    test('returns null when provider does not match', () async {
      await repo.insert(_ticket(
        id: 't-1',
        provider: TicketProvider.linear,
        externalKey: 'LIN-42',
      ));

      final ticket =
          await repo.getByExternal(TicketProvider.jira, 'LIN-42');
      expect(ticket, isNull);
    });

    test('returns null when external key does not match', () async {
      await repo.insert(_ticket(
        id: 't-1',
        provider: TicketProvider.linear,
        externalKey: 'LIN-42',
      ));

      final ticket =
          await repo.getByExternal(TicketProvider.linear, 'LIN-99');
      expect(ticket, isNull);
    });

    test('returns null when no ticket exists at all', () async {
      final ticket =
          await repo.getByExternal(TicketProvider.linear, 'LIN-42');
      expect(ticket, isNull);
    });
  });

  group('forPipelineRun', () {
    test('returns empty when no tickets for pipeline run', () async {
      final result = await repo.forPipelineRun('ws-1', 'no-run');
      expect(result, isEmpty);
    });

    test('excludes tickets from different pipeline runs', () async {
      await _seedPipelineRun(db, id: 'run-A');
      await _seedPipelineRun(db, id: 'run-B');
      await repo.insert(_ticket(
        id: 't-1',
        workspaceId: 'ws-1',
        pipelineRunId: 'run-A',
      ));
      await repo.insert(_ticket(
        id: 't-2',
        workspaceId: 'ws-1',
        pipelineRunId: 'run-B',
      ));

      final runA = await repo.forPipelineRun('ws-1', 'run-A');
      expect(runA.map((t) => t.id), ['t-1']);
    });
  });

  group('forPipelineStep', () {
    test('finds tickets by run + step', () async {
      await _seedPipelineRun(db, id: 'run-1');
      await repo.insert(_ticket(
        id: 't-1',
        workspaceId: 'ws-1',
        pipelineRunId: 'run-1',
        pipelineStepId: 'step-A',
      ));
      await repo.insert(_ticket(
        id: 't-2',
        workspaceId: 'ws-1',
        pipelineRunId: 'run-1',
        pipelineStepId: 'step-B',
      ));

      final stepA = await repo.forPipelineStep('ws-1', 'run-1', 'step-A');
      expect(stepA.map((t) => t.id), ['t-1']);
    });

    test('returns empty when no matching step', () async {
      await _seedPipelineRun(db, id: 'run-1');
      await repo.insert(_ticket(
        id: 't-1',
        workspaceId: 'ws-1',
        pipelineRunId: 'run-1',
        pipelineStepId: 'step-A',
      ));

      final result = await repo.forPipelineStep('ws-1', 'run-1', 'no-step');
      expect(result, isEmpty);
    });


    test('excludes tickets from different runs even if same step id', () async {
      await _seedPipelineRun(db, id: 'run-1');
      await _seedPipelineRun(db, id: 'run-2');
      await repo.insert(_ticket(
        id: 't-1',
        workspaceId: 'ws-1',
        pipelineRunId: 'run-1',
        pipelineStepId: 'step-1',
      ));
      await repo.insert(_ticket(
        id: 't-2',
        workspaceId: 'ws-1',
        pipelineRunId: 'run-2',
        pipelineStepId: 'step-1',
      ));

      final result = await repo.forPipelineStep('ws-1', 'run-1', 'step-1');
      expect(result.map((t) => t.id), ['t-1']);
    });
  });

  group('forAgent', () {
    test('returns empty when agent has no tickets', () async {
      await repo.insert(_ticket(id: 't-1', workspaceId: 'ws-1'));
      final result = await repo.forAgent('ws-1', 'alice');
      expect(result, isEmpty);
    });

    test('returns only tickets assigned to the agent', () async {
      await repo.insert(_ticket(
        id: 't-1',
        workspaceId: 'ws-1',
        assignedAgentId: 'alice',
      ));
      await repo.insert(_ticket(
        id: 't-2',
        workspaceId: 'ws-1',
        assignedAgentId: 'bob',
      ));

      final alice = await repo.forAgent('ws-1', 'alice');
      expect(alice.map((t) => t.id), ['t-1']);
    });
  });

  group('childrenOf', () {
    test('returns direct children', () async {
      await repo.insert(_ticket(id: 'parent', workspaceId: 'ws-1'));
      await repo.insert(_ticket(id: 'other', workspaceId: 'ws-1'));
      await repo.insert(_ticket(
        id: 'c-1',
        workspaceId: 'ws-1',
        parentTicketId: 'parent',
      ));
      await repo.insert(_ticket(
        id: 'c-2',
        workspaceId: 'ws-1',
        parentTicketId: 'parent',
      ));
      await repo.insert(_ticket(
        id: 'c-3',
        workspaceId: 'ws-1',
        parentTicketId: 'other',
      ));

      final children = await repo.childrenOf('ws-1', 'parent');
      expect(children.map((t) => t.id), containsAll(['c-1', 'c-2']));
      expect(children.length, 2);
      expect(children.any((t) => t.id == 'c-3'), isFalse);
    });

    test('returns empty when ticket has no children', () async {
      await repo.insert(_ticket(id: 't-1', workspaceId: 'ws-1'));
      final children = await repo.childrenOf('ws-1', 't-1');
      expect(children, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // Upsert Mirror
  // ---------------------------------------------------------------------------

  group('upsertMirror', () {
    test('inserts when no existing ticket matches external key', () async {
      final ticket = _ticket(
        id: 'ext-1',
        provider: TicketProvider.linear,
        externalKey: 'LIN-123',
        title: 'External ticket',
        status: TicketStatus.inProgress,
        assignedAgentId: 'alice',
      );

      await repo.upsertMirror(ticket);

      final fetched = await repo.getByExternal(TicketProvider.linear, 'LIN-123');
      expect(fetched, isNotNull);
      expect(fetched!.id, 'ext-1');
      expect(fetched.title, 'External ticket');
      expect(fetched.status, TicketStatus.inProgress);
    });

    test('updates only mirror columns on existing ticket', () async {
      await _seedPipelineRun(db, id: 'run-1');
      // Insert with overlay data.
      final initial = _ticket(
        id: 't-1',
        workspaceId: 'ws-1',
        provider: TicketProvider.linear,
        externalKey: 'LIN-42',
        title: 'Old title',
        status: TicketStatus.open,
        assignedAgentId: 'alice',
        assignedTeamId: 'team-alpha',
        pipelineRunId: 'run-1',
        priority: TicketPriority.none,
      );
      await repo.insert(initial);

      // Upsert a mirror refresh — different title/status but no overlay.
      final mirrorRefresh = _ticket(
        id: 'new-id',
        workspaceId: 'ws-1',
        provider: TicketProvider.linear,
        externalKey: 'LIN-42',
        title: 'New title',
        status: TicketStatus.done,
        priority: TicketPriority.high,
      );

      await repo.upsertMirror(mirrorRefresh);

      // Should still be the same row (keyed by provider+externalKey).
      final fetched = await repo.getByExternal(TicketProvider.linear, 'LIN-42');
      expect(fetched, isNotNull);
      // Mirror fields should be updated.
      expect(fetched!.title, 'New title');
      expect(fetched.status, TicketStatus.done);
      expect(fetched.priority, TicketPriority.high);
      // Overlay fields should be preserved (toMirrorCompanion doesn't touch them).
      // The row id should still be the original.
      expect(fetched.id, 't-1');
      expect(fetched.assignedAgentId, 'alice');
      expect(fetched.assignedTeamId, 'team-alpha');
      expect(fetched.pipelineRunId, 'run-1');
    });

    test('inserts when externalKey is null (local-only ticket)', () async {
      final ticket = _ticket(
        id: 'local-1',
        provider: TicketProvider.local,
        title: 'Local ticket',
      );

      await repo.upsertMirror(ticket);

      final fetched = await repo.getById('local-1');
      expect(fetched, isNotNull);
      expect(fetched!.title, 'Local ticket');
    });

    test('multiple upserts do not duplicate rows', () async {
      final ticket = _ticket(
        id: 'ext-1',
        provider: TicketProvider.linear,
        externalKey: 'LIN-7',
        title: 'First',
      );

      await repo.upsertMirror(ticket);
      await repo.upsertMirror(ticket);

      // Should be exactly one ticket with this external key.
      final fetched = await repo.getByExternal(TicketProvider.linear, 'LIN-7');
      expect(fetched, isNotNull);
    });
  });

  // ---------------------------------------------------------------------------
  // Collaborators
  // ---------------------------------------------------------------------------

  group('addCollaborator', () {
    test('adds a collaborator to a ticket', () async {
      await repo.insert(_ticket(id: 't-1'));
      await repo.addCollaborator(_collaborator(ticketId: 't-1', agentId: 'alice'));

      final ticket = await repo.getById('t-1');
      expect(ticket!.collaborators.length, 1);
      expect(ticket.collaborators.single.agentId, 'alice');
    });

    test('is idempotent on (ticketId, agentId)', () async {
      await repo.insert(_ticket(id: 't-1'));
      await repo.addCollaborator(_collaborator(
        id: 'c-1',
        ticketId: 't-1',
        agentId: 'alice',
      ));
      // Add same agent again with a different row id.
      await repo.addCollaborator(_collaborator(
        id: 'c-2',
        ticketId: 't-1',
        agentId: 'alice',
      ));

      final ticket = await repo.getById('t-1');
      expect(ticket!.collaborators.length, 1);
    });
  });

  group('removeCollaborator', () {
    test('removes a collaborator', () async {
      await repo.insert(_ticket(id: 't-1'));
      await repo.addCollaborator(_collaborator(ticketId: 't-1', agentId: 'alice'));
      await repo.addCollaborator(_collaborator(
        id: 'c-2',
        ticketId: 't-1',
        agentId: 'bob',
      ));

      await repo.removeCollaborator('t-1', 'alice');

      final ticket = await repo.getById('t-1');
      expect(ticket!.collaborators.length, 1);
      expect(ticket.collaborators.single.agentId, 'bob');
    });

    test('does not throw when collaborator does not exist', () async {
      await repo.insert(_ticket(id: 't-1'));
      await repo.removeCollaborator('t-1', 'no-such');
      // No exception thrown.
    });
  });

  group('watchCollaborators', () {
    test('emits empty when no collaborators', () async {
      await repo.insert(_ticket(id: 't-1'));
      final collabs = await repo.watchCollaborators('t-1').first;
      expect(collabs, isEmpty);
    });

    test('emits collaborators ordered by joinedAt', () async {
      await repo.insert(_ticket(id: 't-1'));
      await repo.addCollaborator(_collaborator(
        id: 'c-1',
        ticketId: 't-1',
        agentId: 'alice',
        joinedAt: DateTime(2026, 6, 3),
      ));
      await repo.addCollaborator(_collaborator(
        id: 'c-2',
        ticketId: 't-1',
        agentId: 'bob',
        joinedAt: DateTime(2026, 6, 1),
      ));
      await repo.addCollaborator(_collaborator(
        id: 'c-3',
        ticketId: 't-1',
        agentId: 'carol',
        joinedAt: DateTime(2026, 6, 2),
      ));

      final collabs = await repo.watchCollaborators('t-1').first;
      expect(collabs.map((c) => c.agentId), ['bob', 'carol', 'alice']);
    });

    test('live stream emits after add', () async {
      await repo.insert(_ticket(id: 't-1'));

      final first = await repo.watchCollaborators('t-1').first;
      expect(first, isEmpty);

      await repo.addCollaborator(_collaborator(ticketId: 't-1', agentId: 'alice'));

      final after = await repo.watchCollaborators('t-1').first;
      expect(after.map((c) => c.agentId), ['alice']);
    });

    test('live stream emits after remove', () async {
      await repo.insert(_ticket(id: 't-1'));
      await repo.addCollaborator(_collaborator(ticketId: 't-1', agentId: 'alice'));
      await repo.addCollaborator(_collaborator(
        id: 'c-2',
        ticketId: 't-1',
        agentId: 'bob',
      ));

      // Confirm both present.
      final before = await repo.watchCollaborators('t-1').first;
      expect(before.length, 2);

      await repo.removeCollaborator('t-1', 'alice');

      final after = await repo.watchCollaborators('t-1').first;
      expect(after.map((c) => c.agentId), ['bob']);
    });
  });

  group('getCollaborators', () {
    test('returns collaborators for a ticket', () async {
      await repo.insert(_ticket(id: 't-1'));
      await repo.addCollaborator(_collaborator(ticketId: 't-1', agentId: 'alice'));

      final collabs = await repo.getCollaborators('t-1');
      expect(collabs.length, 1);
      expect(collabs.single.agentId, 'alice');
    });

    test('returns empty when no collaborators', () async {
      await repo.insert(_ticket(id: 't-1'));
      final collabs = await repo.getCollaborators('t-1');
      expect(collabs, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // Edge Cases
  // ---------------------------------------------------------------------------

  group('edge cases', () {
    test('insert preserves all fields round-trip', () async {
      await _seedPipelineRun(db, id: 'run-1');
      await repo.insert(_ticket(id: 'parent-1', workspaceId: 'ws-1', title: 'Parent'));
      final now = DateTime(2026, 6, 1);
      final ticket = Ticket(
        id: 'full-1',
        workspaceId: 'ws-1',
        provider: TicketProvider.linear,
        externalKey: 'LIN-99',
        url: 'https://linear.app/issue/LIN-99',
        title: 'Full featured ticket',
        description: 'A description',
        priority: TicketPriority.high,
        labels: ['bug', 'frontend'],
        status: TicketStatus.inProgress,
        rawStatus: 'In Progress',
        parentTicketId: 'parent-1',
        projectId: 'proj-1',
        assignedAgentId: 'agent-7',
        assignedTeamId: 'team-1',
        delegatedByAgentId: 'agent-3',
        channelId: 'chan-1',
        pipelineRunId: 'run-1',
        pipelineStepId: 'step-3',
        expectedOutputSchema: {'type': 'object'},
        outputJson: {'result': 'ok'},
        errorMessage: null,
        linkedPrIds: ['pr-1', 'pr-2'],
        metadata: {'key': 'value'},
        createdAt: now,
        updatedAt: now,
        version: 5,
        originKind: TicketOriginKind.pipelineStep,
        checkoutRunId: 'checkout-1',
        executionLockedAt: now,
        checkoutAgentId: 'agent-7',
        executionPolicyJson: '{"stages":[]}',
        executionStateJson: '{"current":0}',
        recoveryActionsJson: '[]',
      );

      await repo.insert(ticket);

      final fetched = await repo.getById('full-1');
      expect(fetched, isNotNull);
      expect(fetched!.id, 'full-1');
      expect(fetched.workspaceId, 'ws-1');
      expect(fetched.provider, TicketProvider.linear);
      expect(fetched.externalKey, 'LIN-99');
      expect(fetched.url, 'https://linear.app/issue/LIN-99');
      expect(fetched.title, 'Full featured ticket');
      expect(fetched.description, 'A description');
      expect(fetched.priority, TicketPriority.high);
      expect(fetched.labels, ['bug', 'frontend']);
      expect(fetched.status, TicketStatus.inProgress);
      expect(fetched.rawStatus, 'In Progress');
      expect(fetched.parentTicketId, 'parent-1');
      expect(fetched.projectId, 'proj-1');
      expect(fetched.assignedAgentId, 'agent-7');
      expect(fetched.assignedTeamId, 'team-1');
      expect(fetched.delegatedByAgentId, 'agent-3');
      expect(fetched.channelId, 'chan-1');
      expect(fetched.pipelineRunId, 'run-1');
      expect(fetched.pipelineStepId, 'step-3');
      expect(fetched.expectedOutputSchema, {'type': 'object'});
      expect(fetched.outputJson, {'result': 'ok'});
      expect(fetched.errorMessage, isNull);
      expect(fetched.linkedPrIds, ['pr-1', 'pr-2']);
      expect(fetched.metadata, {'key': 'value'});
      expect(fetched.version, 5);
      expect(fetched.originKind, TicketOriginKind.pipelineStep);
      expect(fetched.checkoutRunId, 'checkout-1');
      expect(fetched.executionLockedAt, now);
      expect(fetched.checkoutAgentId, 'agent-7');
      expect(fetched.executionPolicyJson, '{"stages":[]}');
      expect(fetched.executionStateJson, '{"current":0}');
      expect(fetched.recoveryActionsJson, '[]');
    });

    test('nullable fields round-trip null correctly', () async {
      final ticket = _ticket(
        id: 'min-1',
        title: 'Minimal ticket',
        assignedAgentId: null,
        assignedTeamId: null,
        pipelineRunId: null,
        pipelineStepId: null,
        parentTicketId: null,
        externalKey: null,
        url: null,
        description: null,
      );

      await repo.insert(ticket);

      final fetched = await repo.getById('min-1');
      expect(fetched!.assignedAgentId, isNull);
      expect(fetched.assignedTeamId, isNull);
      expect(fetched.pipelineRunId, isNull);
      expect(fetched.pipelineStepId, isNull);
      expect(fetched.parentTicketId, isNull);
      expect(fetched.externalKey, isNull);
      expect(fetched.url, isNull);
      expect(fetched.description, isNull);
      expect(fetched.rawStatus, isNull);
    });

    test('empty labels and linkedPrIds round-trip correctly', () async {
      final ticket = _ticket(
        id: 'empty-arrays',
        title: 'Empty arrays',
        labels: [],
      );

      await repo.insert(ticket);

      final fetched = await repo.getById('empty-arrays');
      expect(fetched!.labels, isEmpty);
      expect(fetched.linkedPrIds, isEmpty);
    });

    test('empty metadata round-trips correctly', () async {
      final ticket = _ticket(id: 'm-1', title: 'No metadata');

      await repo.insert(ticket);

      final fetched = await repo.getById('m-1');
      expect(fetched!.metadata, isEmpty);
    });

    test('forPipelineRun excludes tickets without a pipeline run', () async {
      await _seedPipelineRun(db, id: 'run-1');
      await repo.insert(_ticket(
        id: 't-1',
        workspaceId: 'ws-1',
        pipelineRunId: 'run-1',
      ));
      await repo.insert(_ticket(
        id: 't-2',
        workspaceId: 'ws-1',
      )); // No pipelineRunId set.

      final result = await repo.forPipelineRun('ws-1', 'run-1');
      expect(result.map((t) => t.id), ['t-1']);
    });

    test('forAgent excludes unassigned tickets', () async {
      await repo.insert(_ticket(
        id: 't-1',
        workspaceId: 'ws-1',
        assignedAgentId: 'alice',
      ));
      await repo.insert(_ticket(
        id: 't-2',
        workspaceId: 'ws-1',
      )); // No assignedAgentId.

      final result = await repo.forAgent('ws-1', 'alice');
      expect(result.map((t) => t.id), ['t-1']);
    });

    test('forAgent returns empty when agent has tickets in other workspace', () async {
      await repo.insert(_ticket(
        id: 't-1',
        workspaceId: 'ws-2',
        assignedAgentId: 'alice',
      ));

      final result = await repo.forAgent('ws-1', 'alice');
      expect(result, isEmpty);
    });

    test('multiple statuses can all coexist and be queried independently', () async {
      for (final status in TicketStatus.values) {
        await repo.insert(_ticket(
          id: 't-${status.name}',
          workspaceId: 'ws-1',
          title: status.name,
          status: status,
        ));
      }

      // All tickets are in the workspace.
      final all = await repo.watchForWorkspace('ws-1').first;
      expect(all.length, TicketStatus.values.length);

      // Each status query returns exactly one ticket.
      for (final status in TicketStatus.values) {
        final filtered = await repo.watchByStatus('ws-1', status).first;
        expect(filtered.length, 1);
        expect(filtered.single.status, status);
      }
    });

    test('watches are independent — modifying one stream does not affect another', () async {
      await repo.insert(_ticket(
        id: 't-1',
        workspaceId: 'ws-1',
        status: TicketStatus.open,
      ));

      final wsStream = repo.watchForWorkspace('ws-1');
      final openStream = repo.watchByStatus('ws-1', TicketStatus.open);
      final doneStream = repo.watchByStatus('ws-1', TicketStatus.done);

      final ws = await wsStream.first;
      final open = await openStream.first;
      final done = await doneStream.first;

      expect(ws.length, 1);
      expect(open.length, 1);
      expect(done, isEmpty);
    });
  });
}
