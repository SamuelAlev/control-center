import 'package:control_center/core/database/app_database.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('TicketDao', () {
    test('insert and get a ticket', () async {
      await db.ticketDao.insert(
        TicketsTableCompanion.insert(
          id: 't-1',
          workspaceId: 'w-1',
          title: 'First ticket',
        ),
      );
      final row = await db.ticketDao.getById('t-1');
      expect(row, isNotNull);
      expect(row!.title, 'First ticket');
      expect(row.provider, 'local');
      expect(row.status, 'open');
    });

    test('updateById writes only the given columns', () async {
      await db.ticketDao.insert(
        TicketsTableCompanion.insert(
          id: 't-2',
          workspaceId: 'w-1',
          title: 'Mutable',
        ),
      );
      await db.ticketDao.updateById(
        't-2',
        const TicketsTableCompanion(status: Value('inProgress')),
      );
      final row = await db.ticketDao.getById('t-2');
      expect(row!.status, 'inProgress');
      expect(row.title, 'Mutable'); // untouched
    });

    test('watchForWorkspace emits inserted tickets', () async {
      await db.ticketDao.insert(
        TicketsTableCompanion.insert(
          id: 't-3',
          workspaceId: 'w-2',
          title: 'Watched',
        ),
      );
      final tickets = await db.ticketDao.watchForWorkspace('w-2').first;
      expect(tickets, hasLength(1));
      expect(tickets.first.id, 't-3');
    });

    test('collaborators add (idempotent) + watch', () async {
      await db.ticketDao.insert(
        TicketsTableCompanion.insert(
          id: 't-4',
          workspaceId: 'w-1',
          title: 'Collab',
        ),
      );
      await db.ticketDao.addCollaborator(
        TicketCollaboratorsTableCompanion.insert(
          id: 'c-1',
          ticketId: 't-4',
          agentId: 'agent-1',
        ),
      );
      // Duplicate (ticketId, agentId) is ignored.
      await db.ticketDao.addCollaborator(
        TicketCollaboratorsTableCompanion.insert(
          id: 'c-2',
          ticketId: 't-4',
          agentId: 'agent-1',
        ),
      );
      final collaborators = await db.ticketDao.getCollaborators('t-4');
      expect(collaborators, hasLength(1));
    });

    test('forPipelineStep filters by run + step', () async {
      // The pipeline run must exist (tickets.pipeline_run_id has an FK).
      await db.into(db.pipelineRunsTable).insert(
            PipelineRunsTableCompanion.insert(
              id: 'run-1',
              templateId: 'tmpl-1',
              workspaceId: 'ws-1',
            ),
          );
      await db.ticketDao.insert(
        TicketsTableCompanion.insert(
          id: 't-5',
          workspaceId: 'w-1',
          title: 'Pipelined',
          pipelineRunId: const Value('run-1'),
          pipelineStepId: const Value('step-1'),
        ),
      );
      final forStep =
          await db.ticketDao.forPipelineStep('w-1', 'run-1', 'step-1');
      expect(forStep, hasLength(1));
      final other =
          await db.ticketDao.forPipelineStep('w-1', 'run-1', 'step-2');
      expect(other, isEmpty);
      // A different workspace must not see this pipeline's tickets.
      final crossWs =
          await db.ticketDao.forPipelineStep('other-ws', 'run-1', 'step-1');
      expect(crossWs, isEmpty);
    });

    test('deleteTicket is workspace-scoped and cascades to collaborators',
        () async {
      await db.ticketDao.insert(
        TicketsTableCompanion.insert(
          id: 't-6',
          workspaceId: 'w-1',
          title: 'Deletable',
        ),
      );
      await db.ticketDao.addCollaborator(
        TicketCollaboratorsTableCompanion.insert(
          id: 'c-3',
          ticketId: 't-6',
          agentId: 'agent-1',
        ),
      );

      // A foreign workspace cannot delete it (WHERE workspaceId mismatch).
      final foreign = await db.ticketDao.deleteTicket('t-6', 'other-ws');
      expect(foreign, 0);
      expect(await db.ticketDao.getById('t-6'), isNotNull);

      // The owning workspace deletes it; collaborators cascade away.
      final deleted = await db.ticketDao.deleteTicket('t-6', 'w-1');
      expect(deleted, 1);
      expect(await db.ticketDao.getById('t-6'), isNull);
      expect(await db.ticketDao.getCollaborators('t-6'), isEmpty);
    });
  });
}
