import 'package:cc_domain/features/ticketing/domain/entities/ticket.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_collaborator.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_provider.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_status.dart';

/// Persistence boundary for tickets — a dumb issue-tracking artifact. The
/// pipeline-coupling / suspend-resume methods moved to the agent-run layer
/// (`AgentRunLogRepository`); tickets now carry only mirror + overlay data.
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
  /// overlay (assignee/team/channel).
  Future<void> upsertMirror(Ticket ticket);

  /// Deletes a ticket (and its collaborators + child tickets via cascade),
  /// scoped to [workspaceId]. A ticket belonging to another workspace is not
  /// matched.
  Future<void> delete(String ticketId, {required String workspaceId});

  /// Fetches a ticket by id (collaborators hydrated), or null.
  Future<Ticket?> getById(String id);

  /// Fetches a ticket by its provider + external key, or null.
  Future<Ticket?> getByExternal(TicketProvider provider, String externalKey);

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
