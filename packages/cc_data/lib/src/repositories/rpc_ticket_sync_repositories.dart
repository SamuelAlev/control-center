import 'package:cc_domain/features/ticketing/domain/sync/sync_direction.dart';
import 'package:cc_domain/features/ticketing/domain/sync/ticket_sync_config.dart';
import 'package:cc_domain/features/ticketing/domain/sync/ticket_sync_log_entry.dart';
import 'package:cc_domain/features/ticketing/domain/sync/ticket_sync_repositories.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// Read-only thin-client view of the multi-vendor sync CONFIGS over RPC, backing
/// the sync-health surface (§188). Writes (upsert/delete) and the one-shot
/// reads are **server-owned** — the sync engine + coordinator run entirely on
/// `cc_server`, so those throw [UnsupportedError] here; the client only watches.
/// Mirrors the `ticket_sync_config.watchForWorkspace` subscription, which
/// carries its own workspace id.
class RpcTicketSyncConfigRepository implements TicketSyncConfigRepository {
  /// Creates an [RpcTicketSyncConfigRepository] over [_client].
  RpcTicketSyncConfigRepository(this._client);

  final RemoteRpcClient _client;

  static TicketSyncConfig _fromWire(Map<String, dynamic> w) => TicketSyncConfig(
    id: w['id'] as String? ?? '',
    workspaceId: w['workspace_id'] as String? ?? '',
    vendor: w['vendor'] as String? ?? '',
    vendorProjectId: w['vendor_project_id'] as String? ?? '',
    direction: SyncDirection.fromStorage(w['direction'] as String?),
    enabled: w['enabled'] as bool? ?? true,
    createdAt:
        DateTime.tryParse(w['created_at'] as String? ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0),
    updatedAt:
        DateTime.tryParse(w['updated_at'] as String? ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0),
  );

  @override
  // Explicit `workspace_id` rather than the client's ambient active workspace,
  // which flips on a switch independently of the workspace a keyed caller is
  // asking about.
  Stream<List<TicketSyncConfig>> watchForWorkspace(String workspaceId) =>
      _client
          .subscribe('ticket_sync_config.watchForWorkspace', {
            'workspace_id': workspaceId,
          })
          .map(
            (data) => ((data['configs'] as List?) ?? const [])
                .whereType<Map>()
                .map((m) => _fromWire(m.cast<String, dynamic>()))
                .toList(),
          );

  @override
  Future<void> upsert(TicketSyncConfig config) => _serverOwned();

  @override
  Future<List<TicketSyncConfig>> enabledForWorkspace(String workspaceId) =>
      _serverOwned();

  @override
  Future<TicketSyncConfig?> forVendor(String workspaceId, String vendor) =>
      _serverOwned();

  @override
  Future<List<TicketSyncConfig>> forWorkspace(String workspaceId) =>
      _serverOwned();

  @override
  Future<int> delete(String id, {required String workspaceId}) =>
      _serverOwned();

  Never _serverOwned() => throw UnsupportedError(
    'Ticket sync config writes/one-shot reads run server-side; the thin '
    'client only watches via watchForWorkspace.',
  );
}

/// Read-only thin-client view of the append-only sync LOG over RPC, backing the
/// sync-health surface (§188). Appends + the dedupe check + one-shot reads are
/// server-owned (throw [UnsupportedError]); the client only watches. Mirrors the
/// `ticket_sync_log.watchForWorkspace` subscription.
class RpcTicketSyncLogRepository implements TicketSyncLogRepository {
  /// Creates an [RpcTicketSyncLogRepository] over [_client].
  RpcTicketSyncLogRepository(this._client);

  final RemoteRpcClient _client;

  static TicketSyncLogEntry _fromWire(Map<String, dynamic> w) =>
      TicketSyncLogEntry(
        id: w['id'] as String? ?? '',
        workspaceId: w['workspace_id'] as String? ?? '',
        ticketId: w['ticket_id'] as String?,
        vendor: w['vendor'] as String? ?? '',
        direction: SyncDirection.fromStorage(w['direction'] as String?),
        outcome: SyncOutcome.fromStorage(w['outcome'] as String?),
        message: w['message'] as String?,
        createdAt:
            DateTime.tryParse(w['created_at'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );

  @override
  Stream<List<TicketSyncLogEntry>> watchForWorkspace(
    String workspaceId, {
    int limit = 100,
  }) => _client
      .subscribe('ticket_sync_log.watchForWorkspace', {
        'workspace_id': workspaceId,
      })
      .map(
        (data) => ((data['logs'] as List?) ?? const [])
            .whereType<Map>()
            .map((m) => _fromWire(m.cast<String, dynamic>()))
            .toList(),
      );

  @override
  Future<void> append(TicketSyncLogEntry entry) => _serverOwned();

  @override
  Future<bool> hasProcessed(
    String workspaceId,
    String vendor,
    String dedupeKey,
  ) => _serverOwned();

  @override
  Future<List<TicketSyncLogEntry>> recentForWorkspace(
    String workspaceId, {
    int limit = 100,
  }) => _serverOwned();

  Never _serverOwned() => throw UnsupportedError(
    'Ticket sync log appends/one-shot reads run server-side; the thin '
    'client only watches via watchForWorkspace.',
  );
}
