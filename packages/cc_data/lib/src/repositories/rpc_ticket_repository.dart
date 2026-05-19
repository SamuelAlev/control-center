import 'package:cc_data/src/repositories/remote_ticket_repository.dart';
import 'package:cc_data/src/sync/row_entity_cache.dart';
import 'package:cc_data/src/sync/synced_store.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/value_objects/principal.dart';
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
  /// Creates an [RpcTicketRepository] over [client]. When [sync] is supplied
  /// and its `tickets` kill-switch is on, [watchForWorkspace] (and the
  /// `watchByStatus`/`watchByAssignee`/`forAgent`/`childrenOf` methods that
  /// delegate to it) adopt the deterministic sync engine (PRD 16 §6) instead
  /// of re-querying the legacy full-snapshot `tickets.watchForWorkspace`
  /// subscription on every change.
  RpcTicketRepository(RemoteRpcClient client, {ClientSyncEngine? sync})
    : _remote = RemoteTicketRepository(client),
      _sync = sync;

  final RemoteTicketRepository _remote;
  final ClientSyncEngine? _sync;

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
      _ticketStatusByName[name] ?? TicketStatus.values.first;
  static TicketPriority _priority(String name) =>
      _ticketPriorityByName[name] ?? TicketPriority.none;
  static TicketProvider _provider(String name) =>
      _ticketProviderByName[name] ?? TicketProvider.local;
  static TicketOriginKind _originKind(String? name) =>
      _ticketOriginKindByName[name] ?? TicketOriginKind.manual;

  @override
  Stream<List<Ticket>> watchForWorkspace(String workspaceId) {
    final store = _sync?.storeFor('tickets', workspaceId);
    if (store == null) {
      // Kill-switch OFF (or the store demoted itself) — the legacy path.
      // [workspaceId] is threaded into the subscription (not left to the
      // client's ambient active-workspace injection, which flips on a switch
      // independently of the workspace being asked about) so this stream is
      // always the workspace the caller named.
      return _remote
          .watch(workspaceId: workspaceId)
          .map((dtos) => dtos.map(_fromDto).toList());
    }
    return _watchAdopted(store, workspaceId);
  }

  /// Seeds [store]'s `tickets` table from the FIRST emission of the legacy
  /// snapshot watch (`.first` subscribes then auto-cancels once it resolves,
  /// so the legacy subscription doesn't stay open), then follows the store's
  /// own delta-fed rows — sorted to match the server's
  /// `tickets.watchForWorkspace` ordering (newest-`updatedAt`-first; see
  /// `TicketDao.watchForWorkspace`).
  Stream<List<Ticket>> _watchAdopted(
    SyncedStore store,
    String workspaceId,
  ) async* {
    // Seed ONCE per (store, workspace). The mirror is shared, so a second
    // subscriber (`myAssignedTickets`, or a `ticketByIdProvider` per open
    // detail pane) arriving later would otherwise pull the whole table again
    // to rebuild state the store already holds and keeps current.
    if (!store.isSeeded('tickets')) {
      final seedDtos = await _remote.watch(workspaceId: workspaceId).first;
      store.seed(
        'tickets',
        seedDtos.map((d) => d.toJson()).toList(),
        (row) => row['ticket_id'] as String,
      );
    }
    // Per-subscription entity memo: an unchanged row comes back as the SAME
    // Map instance, so its Ticket is reused instead of re-decoded. Without
    // it, one field change on one ticket rebuilt every ticket in the
    // workspace (seven `DateTime.parse` apiece) on the UI isolate.
    final cache = RowEntityCache<Ticket>();
    yield* store
        .watchRows('tickets')
        .map((rows) => _rowsToSortedTickets(rows, cache));
  }

  static List<Ticket> _rowsToSortedTickets(
    List<Map<String, dynamic>> rows,
    RowEntityCache<Ticket> cache,
  ) =>
      cache
          .map(rows, (row) => _fromDto(TicketDto.fromJson(row)))
          .toList(growable: false)
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  @override
  Stream<List<Ticket>> watchByStatus(String workspaceId, TicketStatus status) =>
      watchForWorkspace(
        workspaceId,
      ).map((list) => list.where((t) => t.status == status).toList());

  @override
  Stream<List<Ticket>> watchByAssignee(String workspaceId, String agentId) =>
      watchForWorkspace(
        workspaceId,
      ).map((list) => list.where((t) => t.assignedAgentId == agentId).toList());

  @override
  Future<Ticket?> getById(String workspaceId, String id) async {
    try {
      return _fromDto(await _remote.get(workspaceId, id));
    } on RemoteRpcException catch (e) {
      if (e.code == RpcErrorCodes.notFound) {
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<List<Ticket>> forAgent(String workspaceId, String agentId) async =>
      (await _remote.listForAgent(
        workspaceId,
        agentId,
      )).map(_fromDto).toList(growable: false);

  @override
  Future<List<Ticket>> childrenOf(
    String workspaceId,
    String parentTicketId,
  ) async => (await _remote.listChildren(
    workspaceId,
    parentTicketId,
  )).map(_fromDto).toList(growable: false);

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
      _remote.delete(workspaceId, ticketId);

  @override
  Future<void> addCollaborator(
    String workspaceId,
    TicketCollaborator collaborator,
  ) => _remote.addCollaborator(
    workspaceId: workspaceId,
    id: collaborator.id,
    ticketId: collaborator.ticketId,
    principalId: collaborator.principalId,
    collaboratorType: collaborator.collaboratorType.wireName,
    role: collaborator.role.toStorageString(),
    joinedAt: collaborator.joinedAt.toIso8601String(),
  );

  @override
  Future<void> removeCollaborator(
    String workspaceId,
    String ticketId,
    String principalId,
  ) => _remote.removeCollaborator(workspaceId, ticketId, principalId);

  @override
  Stream<List<TicketCollaborator>> watchCollaborators(
    String workspaceId,
    String ticketId,
  ) => _remote
      .watchCollaborators(workspaceId, ticketId)
      .map((list) => list.map(_collaboratorFromDto).toList());

  @override
  Future<List<TicketCollaborator>> getCollaborators(
    String workspaceId,
    String ticketId,
  ) async {
    final list = await _remote.getCollaborators(workspaceId, ticketId);
    return list.map(_collaboratorFromDto).toList();
  }

  /// Rebuilds a [TicketCollaborator] from its wire map (`role` as its stored
  /// name; `joined_at` as ISO-8601).
  static TicketCollaborator _collaboratorFromDto(Map<String, dynamic> w) =>
      TicketCollaborator(
        id: w['id'] as String,
        ticketId: w['ticket_id'] as String,
        principalId: w['principal_id'] as String,
        collaboratorType:
            PrincipalType.fromWire(w['collaborator_type'] as String?) ??
            PrincipalType.agent,
        role: TicketCollaboratorRole.fromStorage(w['role'] as String?),
        joinedAt: w['joined_at'] is String
            ? DateTime.parse(w['joined_at'] as String)
            : DateTime.fromMillisecondsSinceEpoch(0),
      );
}

// Enum name→value lookups, built ONCE.
//
// `EnumType.values.asNameMap()` ALLOCATES A NEW MAP on every call, and
// these run per field per row per emission — the delta path re-maps a whole
// table on every frame, so a single ticket change built four fresh maps per
// ticket in the workspace.
final Map<String, TicketOriginKind> _ticketOriginKindByName = TicketOriginKind
    .values
    .asNameMap();
final Map<String, TicketPriority> _ticketPriorityByName = TicketPriority.values
    .asNameMap();
final Map<String, TicketProvider> _ticketProviderByName = TicketProvider.values
    .asNameMap();
final Map<String, TicketStatus> _ticketStatusByName = TicketStatus.values
    .asNameMap();
