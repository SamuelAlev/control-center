import 'package:control_center/core/database/daos/ticket_dao.dart';
import 'package:control_center/features/ticketing/data/mappers/ticket_mapper.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket_collaborator.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket_provider.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket_status.dart';
import 'package:control_center/features/ticketing/domain/repositories/ticket_repository.dart';

/// Drift-backed [TicketRepository].
class DaoTicketRepository implements TicketRepository {
  /// Creates a [DaoTicketRepository].
  DaoTicketRepository(this._dao);

  final TicketDao _dao;
  static const _mapper = TicketMapper();

  @override
  Future<void> insert(Ticket ticket) =>
      _dao.insert(_mapper.toCompanion(ticket));

  @override
  Future<void> update(Ticket ticket, {int? expectedVersion}) =>
      _dao.updateById(
        ticket.id,
        _mapper.toCompanion(ticket),
        expectedVersion: expectedVersion,
      );

  @override
  Future<void> upsertMirror(Ticket ticket) async {
    final existing = ticket.externalKey == null
        ? null
        : await _dao.getByExternalKey(
            ticket.provider.toStorageString(),
            ticket.externalKey!,
          );
    if (existing == null) {
      await _dao.insert(_mapper.toCompanion(ticket));
    } else {
      await _dao.updateById(existing.id, _mapper.toMirrorCompanion(ticket));
    }
  }

  @override
  Future<void> delete(String ticketId, {required String workspaceId}) =>
      _dao.deleteTicket(ticketId, workspaceId);

  @override
  Future<Ticket?> getById(String id) async {
    final row = await _dao.getById(id);
    if (row == null) {
      return null;
    }
    final collaborators = await _collaborators(id);
    return _mapper.fromRow(row, collaborators: collaborators);
  }

  @override
  Future<Ticket?> getByExternal(
    TicketProvider provider,
    String externalKey,
  ) async {
    final row =
        await _dao.getByExternalKey(provider.toStorageString(), externalKey);
    return row == null ? null : _mapper.fromRow(row);
  }

  @override
  Future<List<Ticket>> forPipelineRun(
    String workspaceId,
    String pipelineRunId,
  ) async {
    final rows = await _dao.forPipelineRun(workspaceId, pipelineRunId);
    return rows.map((r) => _mapper.fromRow(r)).toList();
  }

  @override
  Future<List<Ticket>> forPipelineStep(
    String workspaceId,
    String pipelineRunId,
    String pipelineStepId,
  ) async {
    final rows =
        await _dao.forPipelineStep(workspaceId, pipelineRunId, pipelineStepId);
    return rows.map((r) => _mapper.fromRow(r)).toList();
  }

  @override
  Future<List<Ticket>> forAgent(String workspaceId, String agentId) async {
    final rows = await _dao.forAgent(workspaceId, agentId);
    return rows.map((r) => _mapper.fromRow(r)).toList();
  }

  @override
  Future<List<Ticket>> childrenOf(
    String workspaceId,
    String parentTicketId,
  ) async {
    final rows = await _dao.childrenOf(workspaceId, parentTicketId);
    return rows.map((r) => _mapper.fromRow(r)).toList();
  }

  @override
  Stream<List<Ticket>> watchForWorkspace(String workspaceId) =>
      _dao.watchForWorkspace(workspaceId).map(
            (rows) => rows.map((r) => _mapper.fromRow(r)).toList(),
          );

  @override
  Stream<List<Ticket>> watchByStatus(String workspaceId, TicketStatus status) =>
      _dao.watchByStatus(workspaceId, status.toStorageString()).map(
            (rows) => rows.map((r) => _mapper.fromRow(r)).toList(),
          );

  @override
  Stream<List<Ticket>> watchByAssignee(String workspaceId, String agentId) =>
      _dao.watchByAssignee(workspaceId, agentId).map(
            (rows) => rows.map((r) => _mapper.fromRow(r)).toList(),
          );

  @override
  Stream<List<Ticket>> watchForPipelineRun(
    String workspaceId,
    String pipelineRunId,
  ) =>
      _dao.watchForPipelineRun(workspaceId, pipelineRunId).map(
            (rows) => rows.map((r) => _mapper.fromRow(r)).toList(),
          );

  @override
  Future<void> addCollaborator(TicketCollaborator collaborator) =>
      _dao.addCollaborator(_mapper.collaboratorToCompanion(collaborator));

  @override
  Future<void> removeCollaborator(String ticketId, String agentId) =>
      _dao.removeCollaborator(ticketId, agentId);

  @override
  Stream<List<TicketCollaborator>> watchCollaborators(String ticketId) =>
      _dao.watchCollaborators(ticketId).map(
            (rows) => rows.map(_mapper.collaboratorFromRow).toList(),
          );

  @override
  Future<List<TicketCollaborator>> getCollaborators(String ticketId) =>
      _collaborators(ticketId);

  Future<List<TicketCollaborator>> _collaborators(String ticketId) async {
    final rows = await _dao.getCollaborators(ticketId);
    return rows.map(_mapper.collaboratorFromRow).toList();
  }
}
