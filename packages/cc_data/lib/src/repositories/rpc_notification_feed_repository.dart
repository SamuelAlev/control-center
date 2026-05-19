import 'package:cc_domain/features/notifications/domain/entities/notification_feed_item.dart';
import 'package:cc_domain/features/notifications/domain/entities/notification_read_mark.dart';
import 'package:cc_domain/features/notifications/domain/repositories/notification_feed_repository.dart';
import 'package:cc_rpc/cc_rpc.dart';

DateTime _parseDate(Object? iso) => iso is String
    ? DateTime.parse(iso)
    : DateTime.fromMillisecondsSinceEpoch(0);

NotificationFeedItem? _itemFromWire(Map<String, dynamic> w) {
  final id = w['id'] as String?;
  final workspaceId = w['workspace_id'] as String?;
  final method = w['method'] as String?;
  if (id == null || workspaceId == null || method == null) {
    return null;
  }
  final rawParams = w['params'];
  return NotificationFeedItem(
    id: id,
    workspaceId: workspaceId,
    method: method,
    params: rawParams is Map
        ? rawParams.cast<String, dynamic>()
        : const <String, dynamic>{},
    createdAt: _parseDate(w['created_at']),
  );
}

NotificationReadMark? _markFromWire(Object? raw) {
  if (raw is! Map) {
    return null;
  }
  final w = raw.cast<String, dynamic>();
  final workspaceId = w['workspace_id'] as String?;
  final userId = w['user_id'] as String?;
  if (workspaceId == null || userId == null) {
    return null;
  }
  final lastSeen = w['last_seen_at'];
  final cleared = w['cleared_before'];
  return NotificationReadMark(
    workspaceId: workspaceId,
    userId: userId,
    lastSeenAt: lastSeen is String ? DateTime.tryParse(lastSeen) : null,
    clearedBefore: cleared is String ? DateTime.tryParse(cleared) : null,
  );
}

List<Map<String, dynamic>> _maps(Object? raw) => ((raw as List?) ?? const [])
    .whereType<Map>()
    .map((m) => m.cast<String, dynamic>())
    .toList();

/// A [NotificationFeedRepository] backed by the RPC client.
///
/// The feed rows come from `notifications.watch`; read state from
/// `notifications.watchReadMark` + the `notifications.markAllRead`/`.clear`
/// ops. The server keys read state on the SESSION's authenticated user, so
/// the `userId` parameters here are advisory (interface parity with the
/// server-side implementation) — a client only ever reaches its own mark.
class RpcNotificationFeedRepository implements NotificationFeedRepository {
  /// Creates an [RpcNotificationFeedRepository] over the given client.
  RpcNotificationFeedRepository(this._client);

  final RemoteRpcClient _client;

  @override
  Stream<List<NotificationFeedItem>> watchFeed(
    String workspaceId, {
    int limit = 50,
  }) => _client
      .subscribe('notifications.watch', {'workspace_id': workspaceId})
      .map(
        (data) => _maps(
          data['items'],
        ).map(_itemFromWire).whereType<NotificationFeedItem>().toList(),
      );

  @override
  Stream<NotificationReadMark?> watchReadMark(
    String workspaceId,
    String userId,
  ) => _client
      .subscribe('notifications.watchReadMark', {'workspace_id': workspaceId})
      .map((data) => _markFromWire(data['mark']));

  @override
  Future<void> markAllRead(String workspaceId, String userId) =>
      _client.call('notifications.markAllRead', {'workspace_id': workspaceId});

  @override
  Future<void> clearAll(String workspaceId, String userId) =>
      _client.call('notifications.clear', {'workspace_id': workspaceId});
}
