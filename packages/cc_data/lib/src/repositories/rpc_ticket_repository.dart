import 'package:cc_data/src/repositories/remote_ticket_repository.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_collaborator.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_origin_kind.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_priority.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_provider.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_status.dart';
import 'package:cc_domain/features/ticketing/domain/repositories/ticket_repository.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// A [TicketRepository] backed by the RPC client — the thin-client data path.
///
/// Implements the domain interface over the host's `tickets.*` ops + the
/// `tickets.watchForWorkspace` subscription, mapping the `TicketDto` wire shape
/// back to [Ticket]. The host is the single source of truth and owns all
/// persistence; this client never touches a database. Read + watch are served;
/// write/collaborator mutations are intentionally not exposed to a remote
/// client (the host owns them) and throw [UnsupportedError].
class RpcTicketRepository implements TicketRepository {
  /// Creates an [RpcTicketRepository] over [client].
  RpcTicketRepository(RemoteRpcClient client)
    : _remote = RemoteTicketRepository(client);

  final RemoteTicketRepository _remote;

  /// Rebuilds a [Ticket] from its wire DTO. The DTO is lossless (see
  /// `ticketToWire`): enum fields are encoded as `.name`; a missing required
  /// timestamp falls back to the epoch so the entity stays valid, optional ones
  /// stay null.
  static Ticket _fromDto(TicketDto d) {
    DateTime? parse(String? iso) => iso == null ? null : DateTime.parse(iso);
    DateTime parseOr(String? iso) =>
        parse(iso) ?? DateTime.fromMillisecondsSinceEpoch(0);
    return Ticket(
      id: d.id,
      workspaceId: d.workspaceId ?? '',
      title: d.title,
      externalKey: d.key.isEmpty ? null : d.key,
      url: d.url,
      description: d.description,
      status: _status(d.status),
      rawStatus: d.rawStatus,
      priority: _priority(d.priority),
      provider: _provider(d.provider),
      labels: d.labels,
      parentTicketId: d.parentTicketId,
      projectId: d.projectId,
      assignedAgentId: d.assignee,
      assignedTeamId: d.assignedTeamId,
      delegatedByAgentId: d.delegatedByAgentId,
      channelId: d.channelId,
      errorMessage: d.errorMessage,
      linkedPrIds: d.linkedPrIds,
      metadata: d.metadata,
      version: d.version,
      originKind: _originKind(d.originKind),
      createdAt: parseOr(d.createdAt),
      startedAt: parse(d.startedAt),
      blockedAt: parse(d.blockedAt),
      cancelledAt: parse(d.cancelledAt),
      completedAt: parse(d.completedAt),
      finishedAt: parse(d.finishedAt),
      updatedAt: parseOr(d.updatedAt),
    );
  }

  /// Serializes a [Ticket] to its wire DTO for the host mutation ops. The
  /// inverse of [_fromDto] — must stay lossless so a read-modify-write never
  /// drops a field.
  static TicketDto _toDto(Ticket t) => TicketDto(
    id: t.id,
    key: t.externalKey ?? '',
    title: t.title,
    status: t.status.name,
    priority: t.priority.name,
    provider: t.provider.name,
    assignee: t.assignedAgentId,
    url: t.url,
    workspaceId: t.workspaceId,
    description: t.description,
    rawStatus: t.rawStatus,
    labels: t.labels,
    parentTicketId: t.parentTicketId,
    projectId: t.projectId,
    assignedTeamId: t.assignedTeamId,
    delegatedByAgentId: t.delegatedByAgentId,
    channelId: t.channelId,
    errorMessage: t.errorMessage,
    linkedPrIds: t.linkedPrIds,
    metadata: t.metadata,
    version: t.version,
    originKind: t.originKind.name,
    createdAt: t.createdAt.toIso8601String(),
    startedAt: t.startedAt?.toIso8601String(),
    blockedAt: t.blockedAt?.toIso8601String(),
    cancelledAt: t.cancelledAt?.toIso8601String(),
    completedAt: t.completedAt?.toIso8601String(),
    finishedAt: t.finishedAt?.toIso8601String(),
    updatedAt: t.updatedAt.toIso8601String(),
  );

  static TicketStatus _status(String name) =>
      TicketStatus.values.asNameMap()[name] ?? TicketStatus.values.first;
  static TicketPriority _priority(String name) =>
      TicketPriority.values.asNameMap()[name] ?? TicketPriority.none;
  static TicketProvider _provider(String name) =>
      TicketProvider.values.asNameMap()[name] ?? TicketProvider.local;
  static TicketOriginKind _originKind(String? name) =>
      TicketOriginKind.values.asNameMap()[name] ?? TicketOriginKind.manual;

  @override
  Stream<List<Ticket>> watchForWorkspace(String workspaceId) =>
      _remote.watch().map((dtos) => dtos.map(_fromDto).toList());

  @override
  Stream<List<Ticket>> watchByStatus(String workspaceId, TicketStatus status) =>
      watchForWorkspace(workspaceId)
          .map((list) => list.where((t) => t.status == status).toList());

  @override
  Stream<List<Ticket>> watchByAssignee(String workspaceId, String agentId) =>
      watchForWorkspace(workspaceId)
          .map((list) => list.where((t) => t.assignedAgentId == agentId).toList());

  @override
  Future<Ticket?> getById(String id) async {
    try {
      return _fromDto(await _remote.get(id));
    } on RemoteRpcException catch (e) {
      if (e.code == RpcErrorCodes.notFound) {
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<List<Ticket>> forAgent(String workspaceId, String agentId) async {
    final all = await watchForWorkspace(workspaceId).first;
    return all.where((t) => t.assignedAgentId == agentId).toList();
  }

  @override
  Future<List<Ticket>> childrenOf(
    String workspaceId,
    String parentTicketId,
  ) async {
    final all = await watchForWorkspace(workspaceId).first;
    return all.where((t) => t.parentTicketId == parentTicketId).toList();
  }

  @override
  Future<Ticket?> getByExternal(TicketProvider provider, String externalKey) =>
      throw UnsupportedError('getByExternal is not available over RPC');

  // ---- Mutations: routed to the host over RPC. The client-side
  // TicketWorkflowService drives create/edit/transition through these. ----
  @override
  Future<void> insert(Ticket ticket) => _remote.insert(_toDto(ticket));

  @override
  Future<void> update(Ticket ticket, {int? expectedVersion}) async {
    try {
      await _remote.update(_toDto(ticket), expectedVersion: expectedVersion);
    } on RemoteRpcException catch (e) {
      // Re-throw the host's optimistic-lock rejection as the domain exception
      // so TicketWorkflowService._mutate recognizes it and re-reads/retries.
      if (e.code == RpcErrorCodes.conflict) {
        throw ConcurrencyConflictException(e.message);
      }
      rethrow;
    }
  }

  /// `upsertMirror` is the remote-provider sync path (Linear → local mirror),
  /// which only ever runs host-side — a thin client never imports a mirror.
  @override
  Future<void> upsertMirror(Ticket ticket) =>
      throw UnsupportedError('upsertMirror is host-side only');

  @override
  Future<void> delete(String ticketId, {required String workspaceId}) =>
      _remote.delete(ticketId);

  @override
  Future<void> addCollaborator(TicketCollaborator collaborator) =>
      _remote.addCollaborator(
        id: collaborator.id,
        ticketId: collaborator.ticketId,
        agentId: collaborator.agentId,
        role: collaborator.role.toStorageString(),
        joinedAt: collaborator.joinedAt.toIso8601String(),
      );

  @override
  Future<void> removeCollaborator(String ticketId, String agentId) =>
      _remote.removeCollaborator(ticketId, agentId);

  @override
  Stream<List<TicketCollaborator>> watchCollaborators(String ticketId) =>
      _remote
          .watchCollaborators(ticketId)
          .map((list) => list.map(_collaboratorFromDto).toList());

  @override
  Future<List<TicketCollaborator>> getCollaborators(String ticketId) async {
    final list = await _remote.getCollaborators(ticketId);
    return list.map(_collaboratorFromDto).toList();
  }

  /// Rebuilds a [TicketCollaborator] from its wire map (`role` as its stored
  /// name; `joined_at` as ISO-8601).
  static TicketCollaborator _collaboratorFromDto(Map<String, dynamic> w) =>
      TicketCollaborator(
        id: w['id'] as String,
        ticketId: w['ticket_id'] as String,
        agentId: w['agent_id'] as String,
        role: TicketCollaboratorRole.fromStorage(w['role'] as String?),
        joinedAt: w['joined_at'] is String
            ? DateTime.parse(w['joined_at'] as String)
            : DateTime.fromMillisecondsSinceEpoch(0),
      );
}
