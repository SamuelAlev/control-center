import 'package:control_center/features/ticketing/domain/entities/ticket.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket_collaborator.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket_provider.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket_status.dart';

/// Persistence boundary for tickets. A superset of the old `TaskRepository`
/// (so the pipeline engine + resume listener keep their methods) plus
/// remote-mirror upsert, status/orchestration updates, and collaborators.
abstract interface class TicketRepository {
  /// Inserts a new ticket.
  Future<void> insert(Ticket ticket);

  /// Persists changes to an existing ticket (mirror + overlay columns).
  ///
  /// [expectedVersion] is the version the row is expected to currently hold
  /// (i.e. the version read *before* mutating). The write only lands when the
  /// row still matches it; otherwise a `ConcurrencyConflictException` is thrown.
  /// Pass the pre-mutation version here and the post-mutation (incremented)
  /// version on [ticket]. Omit [expectedVersion] for an unguarded blind write.
  Future<void> update(Ticket ticket, {int? expectedVersion});

  /// Upserts only the mirror columns from a remote sync, preserving the local
  /// orchestration overlay (assignee/team/channel/pipeline coupling).
  Future<void> upsertMirror(Ticket ticket);

  /// Deletes a ticket (and its collaborators + child tickets via cascade),
  /// scoped to [workspaceId]. A ticket belonging to another workspace is not
  /// matched.
  Future<void> delete(String ticketId, {required String workspaceId});

  /// Fetches a ticket by id (collaborators hydrated), or null.
  Future<Ticket?> getById(String id);

  /// Fetches a ticket by its provider + external key, or null.
  Future<Ticket?> getByExternal(TicketProvider provider, String externalKey);

  /// All tickets created within a pipeline run, scoped to [workspaceId].
  Future<List<Ticket>> forPipelineRun(String workspaceId, String pipelineRunId);

  /// Tickets created by a specific pipeline step (resume-listener hot path),
  /// scoped to [workspaceId].
  Future<List<Ticket>> forPipelineStep(
    String workspaceId,
    String pipelineRunId,
    String pipelineStepId,
  );

  /// Tickets assigned to an agent, scoped to [workspaceId].
  Future<List<Ticket>> forAgent(String workspaceId, String agentId);

  /// Direct children of a parent ticket, scoped to [workspaceId].
  Future<List<Ticket>> childrenOf(String workspaceId, String parentTicketId);

  /// Watches all tickets in a workspace (newest first).
  Stream<List<Ticket>> watchForWorkspace(String workspaceId);

  /// Watches tickets in a workspace filtered by status.
  Stream<List<Ticket>> watchByStatus(String workspaceId, TicketStatus status);

  /// Watches tickets assigned to an agent, scoped to [workspaceId].
  Stream<List<Ticket>> watchByAssignee(String workspaceId, String agentId);

  /// Watches all tickets created within a pipeline run, scoped to [workspaceId].
  Stream<List<Ticket>> watchForPipelineRun(
    String workspaceId,
    String pipelineRunId,
  );

  // --- collaborators ---

  /// Adds a collaborator (idempotent on (ticketId, agentId)).
  Future<void> addCollaborator(TicketCollaborator collaborator);

  /// Removes a collaborator.
  Future<void> removeCollaborator(String ticketId, String agentId);

  /// Watches the collaborators of a ticket.
  Stream<List<TicketCollaborator>> watchCollaborators(String ticketId);

  /// Reads the collaborators of a ticket.
  Future<List<TicketCollaborator>> getCollaborators(String ticketId);
}
