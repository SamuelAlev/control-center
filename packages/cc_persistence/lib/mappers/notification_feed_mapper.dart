import 'dart:convert';

import 'package:cc_domain/features/notifications/domain/entities/notification_feed_item.dart';
import 'package:cc_domain/features/notifications/domain/entities/notification_item_state.dart';
import 'package:cc_domain/features/notifications/domain/entities/notification_read_mark.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';

/// Maps between the notification-feed domain entities and their table rows.
class NotificationFeedMapper {
  /// Creates a [NotificationFeedMapper].
  const NotificationFeedMapper();

  /// To domain.
  NotificationFeedItem toDomain(NotificationFeedTableData row) =>
      NotificationFeedItem(
        id: row.id,
        workspaceId: row.workspaceId,
        method: row.method,
        params: _decodeParams(row.paramsJson),
        createdAt: row.createdAt,
      );

  /// To domain list.
  List<NotificationFeedItem> toDomainList(
    List<NotificationFeedTableData> rows,
  ) => rows.map(toDomain).toList(growable: false);

  /// To domain read mark.
  NotificationReadMark markToDomain(NotificationReadMarksTableData row) =>
      NotificationReadMark(
        workspaceId: row.workspaceId,
        userId: row.userId,
        lastSeenAt: row.lastSeenAt,
        clearedBefore: row.clearedBefore,
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

  static Map<String, dynamic> _decodeParams(String raw) {
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : const {};
    } on FormatException {
      return const {};
    }
  }
}
