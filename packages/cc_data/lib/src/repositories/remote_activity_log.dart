import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/entities/activity_entry.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// Reads the workspace-scoped audit trail (the `activity_log` table) over the
/// RPC client instead of a local database — the read-only counterpart to the
/// desktop's in-process `ActivityLogDao` stream.
///
/// Backs the web build (the entity-timeline view). The trail is workspace-scoped
/// and the workspace is bound server-side (via `session/set_workspace`), so the
/// subscription never passes a `workspace_id` — the host injects the
/// authoritative one and scopes the query by it. Mirrors the
/// `activity.watchForEntity` subscription in the host catalog. The write path
/// (the domain-event audit bridge persisting `ActivityLogged` events) is
/// host-side and has no RPC surface.
class RemoteActivityLog {
  /// Creates a [RemoteActivityLog] over [_client].
  RemoteActivityLog(this._client);

  final RemoteRpcClient _client;

  /// Live audit-trail entries for one entity in the bound workspace, newest
  /// first. [workspaceId] is the bound workspace the client already holds; it is
  /// stamped onto each rebuilt [ActivityEntry] (the wire DTO omits it — the host
  /// scopes by the session binding, not a client arg).
  Stream<List<ActivityEntry>> watchForEntity(
    String workspaceId,
    String entityType,
    String entityId,
  ) =>
      _client
          .subscribe('activity.watchForEntity', {
            'entity_type': entityType,
            'entity_id': entityId,
          })
          .map(
            (data) => ((data['entries'] as List?) ?? const [])
                .whereType<Map>()
                .map(
                  (e) => _fromDto(
                    workspaceId,
                    ActivityEntryDto.fromJson(e.cast<String, dynamic>()),
                  ),
                )
                .toList(),
          );

  static DateTime _parse(String? iso) => iso == null || iso.isEmpty
      ? DateTime.fromMillisecondsSinceEpoch(0)
      : DateTime.parse(iso);

  static ActivityEntry _fromDto(String workspaceId, ActivityEntryDto d) =>
      ActivityEntry(
        id: d.id,
        actorType: d.actorType,
        action: d.action,
        entityType: d.entityType,
        createdAt: _parse(d.createdAt),
        actorId: d.actorId,
        entityId: d.entityId,
        details: d.details,
        workspaceId: workspaceId,
        runId: d.runId,
      );
}
