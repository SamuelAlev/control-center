import 'dart:convert';

import 'package:cc_domain/core/domain/value_objects/feed_position.dart';
import 'package:cc_domain/features/notifications/domain/entities/notification_feed_item.dart';
import 'package:cc_domain/features/notifications/domain/entities/notification_item_state.dart';
import 'package:cc_domain/features/notifications/domain/entities/notification_read_mark.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';

/// Maps between the notification-feed domain entities and their table rows.
class NotificationFeedMapper {
  /// Creates a [NotificationFeedMapper].
  const NotificationFeedMapper();

  /// To domain. [seq] is the row's `rowid`.
  NotificationFeedItem toDomain(NotificationFeedTableData row, int seq) =>
      NotificationFeedItem(
        id: row.id,
        workspaceId: row.workspaceId,
        method: row.method,
        params: _decodeParams(row.paramsJson),
        createdAt: row.createdAt,
        seq: seq,
      );

  /// To domain list.
  List<NotificationFeedItem> toDomainList(
    List<({NotificationFeedTableData row, int seq})> rows,
  ) => [for (final r in rows) toDomain(r.row, r.seq)];

  /// To domain read mark.
  NotificationReadMark markToDomain(NotificationReadMarksTableData row) =>
      NotificationReadMark(
        workspaceId: row.workspaceId,
        userId: row.userId,
        lastSeen: _position(row.lastSeenAt, row.lastSeenSeq),
        cleared: _position(row.clearedBefore, row.clearedBeforeSeq),
      );

  /// To domain per-item state.
  NotificationItemState itemStateToDomain(
    NotificationItemStatesTableData row,
  ) => NotificationItemState(
    workspaceId: row.workspaceId,
    userId: row.userId,
    itemId: row.itemId,
    readAt: row.readAt,
    dismissedAt: row.dismissedAt,
  );

  /// To domain per-item state list.
  List<NotificationItemState> itemStatesToDomain(
    List<NotificationItemStatesTableData> rows,
  ) => rows.map(itemStateToDomain).toList(growable: false);

  static FeedPosition? _position(DateTime? at, int seq) =>
      at == null ? null : FeedPosition(at: at, seq: seq);

  static Map<String, dynamic> _decodeParams(String raw) {
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : const {};
    } on FormatException {
      return const {};
    }
  }
}
