import 'package:control_center/core/database/app_database.dart';
import 'package:control_center/core/database/tables/ticket_collaborators_table.dart';
import 'package:control_center/core/database/tables/tickets_table.dart';
import 'package:control_center/core/errors/app_exceptions.dart';
import 'package:drift/drift.dart';

part 'ticket_dao.g.dart';

/// Data access for tickets + their collaborators.
@DriftAccessor(tables: [TicketsTable, TicketCollaboratorsTable])
class TicketDao extends DatabaseAccessor<AppDatabase> with _$TicketDaoMixin {
  /// Creates a [TicketDao].
  TicketDao(super.db);

  // --- writes ---

  /// Inserts a new ticket row.
  Future<void> insert(TicketsTableCompanion ticket) =>
      into(ticketsTable).insert(ticket);

  Future<void> updateById(
    String id,
    TicketsTableCompanion ticket, {
    int? expectedVersion,
  }) async {
    final query = update(ticketsTable)..where((t) => t.id.equals(id));
    if (expectedVersion != null) {
      query.where((t) => t.version.equals(expectedVersion));
    }
    final rows = await query.write(ticket);
    if (expectedVersion != null && rows == 0) {
      throw ConcurrencyConflictException(
        'Ticket $id was modified by another operation '
        '(expected version $expectedVersion)',
      );
    }
  }

  /// Deletes a ticket scoped to [workspaceId]. Its collaborators and any child
  /// tickets are removed via `ON DELETE CASCADE`. Scoping by `workspaceId`
  /// means a ticket from another workspace is simply not matched. Returns the
  /// number of rows deleted.
  Future<int> deleteTicket(String id, String workspaceId) =>
      (delete(ticketsTable)
            ..where((t) =>
                t.id.equals(id) & t.workspaceId.equals(workspaceId)))
          .go();

  // --- reads ---

  /// Fetches a ticket by id.
  Future<TicketsTableData?> getById(String id) =>
      (select(ticketsTable)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Fetches a ticket by provider + external key.
  Future<TicketsTableData?> getByExternalKey(
    String provider,
    String externalKey,
  ) =>
      (select(ticketsTable)
            ..where(
              (t) =>
                  t.provider.equals(provider) &
                  t.externalKey.equals(externalKey),
            ))
          .getSingleOrNull();

  /// Tickets created within a pipeline run, scoped to [workspaceId].
  Future<List<TicketsTableData>> forPipelineRun(
    String workspaceId,
    String pipelineRunId,
  ) =>
      (select(ticketsTable)
            ..where((t) =>
                t.workspaceId.equals(workspaceId) &
                t.pipelineRunId.equals(pipelineRunId)))
          .get();

  /// Tickets created by a specific pipeline step (resume-listener hot path),
  /// scoped to [workspaceId].
  Future<List<TicketsTableData>> forPipelineStep(
    String workspaceId,
    String pipelineRunId,
    String pipelineStepId,
  ) =>
      (select(ticketsTable)
            ..where((t) =>
                t.workspaceId.equals(workspaceId) &
                t.pipelineRunId.equals(pipelineRunId) &
                t.pipelineStepId.equals(pipelineStepId)))
          .get();

  /// Tickets assigned to an agent, scoped to [workspaceId].
  Future<List<TicketsTableData>> forAgent(
    String workspaceId,
    String agentId,
  ) =>
      (select(ticketsTable)
            ..where((t) =>
                t.workspaceId.equals(workspaceId) &
                t.assignedAgentId.equals(agentId)))
          .get();

  /// Direct children of a parent ticket, scoped to [workspaceId].
  Future<List<TicketsTableData>> childrenOf(
    String workspaceId,
    String parentTicketId,
  ) =>
      (select(ticketsTable)
            ..where((t) =>
                t.workspaceId.equals(workspaceId) &
                t.parentTicketId.equals(parentTicketId)))
          .get();

  // --- watches ---

  /// Watches all tickets in a workspace, newest first.
  Stream<List<TicketsTableData>> watchForWorkspace(String workspaceId) =>
      (select(ticketsTable)
            ..where((t) => t.workspaceId.equals(workspaceId))
            ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
          .watch();

  /// Watches tickets in a workspace filtered by status.
  Stream<List<TicketsTableData>> watchByStatus(
    String workspaceId,
    String status,
  ) =>
      (select(ticketsTable)
            ..where((t) =>
                t.workspaceId.equals(workspaceId) & t.status.equals(status))
            ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
          .watch();

  /// Watches tickets assigned to an agent, scoped to [workspaceId].
  Stream<List<TicketsTableData>> watchByAssignee(
    String workspaceId,
    String agentId,
  ) =>
      (select(ticketsTable)
            ..where((t) =>
                t.workspaceId.equals(workspaceId) &
                t.assignedAgentId.equals(agentId))
            ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
          .watch();

  /// Watches all tickets created within a pipeline run, scoped to [workspaceId].
  Stream<List<TicketsTableData>> watchForPipelineRun(
    String workspaceId,
    String pipelineRunId,
  ) =>
      (select(ticketsTable)
            ..where((t) =>
                t.workspaceId.equals(workspaceId) &
                t.pipelineRunId.equals(pipelineRunId)))
          .watch();

  // --- collaborators ---

  Future<void> addCollaborator(TicketCollaboratorsTableCompanion c) async {
    await into(ticketCollaboratorsTable).insert(
      c,
      mode: InsertMode.insertOrIgnore,
    );
  }

  /// Removes a collaborator.
  Future<void> removeCollaborator(String ticketId, String agentId) =>
      (delete(ticketCollaboratorsTable)
            ..where((t) =>
                t.ticketId.equals(ticketId) & t.agentId.equals(agentId)))
          .go();

  /// Watches the collaborators of a ticket.
  Stream<List<TicketCollaboratorsTableData>> watchCollaborators(
    String ticketId,
  ) =>
      (select(ticketCollaboratorsTable)
            ..where((t) => t.ticketId.equals(ticketId))
            ..orderBy([(t) => OrderingTerm.asc(t.joinedAt)]))
          .watch();

  /// Reads the collaborators of a ticket.
  Future<List<TicketCollaboratorsTableData>> getCollaborators(
    String ticketId,
  ) =>
      (select(ticketCollaboratorsTable)
            ..where((t) => t.ticketId.equals(ticketId))
            ..orderBy([(t) => OrderingTerm.asc(t.joinedAt)]))
          .get();
}
