import 'dart:convert';

import 'package:cc_domain/features/notifications/domain/entities/notification_feed_item.dart';
import 'package:cc_domain/features/notifications/domain/entities/notification_item_state.dart';
import 'package:cc_domain/features/notifications/domain/entities/notification_read_mark.dart';
import 'package:cc_domain/features/notifications/domain/repositories/notification_feed_repository.dart';
import 'package:cc_persistence/database/daos/notification_feed_dao.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:cc_persistence/database/workspace_database_manager.dart';
import 'package:cc_persistence/mappers/notification_feed_mapper.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

/// Drift-backed [NotificationFeedRepository].
///
/// The feed and its read marks live in the workspace's own database file, so
/// each method resolves its DAO from the `workspaceId` it was given. [record]
/// is deliberately NOT on the domain interface: only the server's
/// domain-event listener writes the feed, so the write exists solely on this
/// server-side implementation.
class DaoNotificationFeedRepository implements NotificationFeedRepository {
  /// Creates a [DaoNotificationFeedRepository] over the per-workspace
  /// databases.
  DaoNotificationFeedRepository(this._dbs);

  final WorkspaceDatabaseManager _dbs;
  final NotificationFeedMapper _mapper = const NotificationFeedMapper();
  final Uuid _uuid = const Uuid();

  NotificationFeedDao _dao(String workspaceId) =>
      _dbs.of(workspaceId).notificationFeedDao;

  @override
  Stream<List<NotificationFeedItem>> watchFeed(
    String workspaceId, {
    int limit = 50,
  }) => _dao(
    workspaceId,
  ).watchRecent(workspaceId, limit: limit).map(_mapper.toDomainList);

  @override
  Stream<NotificationReadMark?> watchReadMark(
    String workspaceId,
    String userId,
  ) => _dao(workspaceId)
      .watchReadMark(workspaceId, userId)
      .map((row) => row == null ? null : _mapper.markToDomain(row));

  @override
  Stream<List<NotificationItemState>> watchItemStates(
    String workspaceId,
    String userId,
  ) => _dao(
    workspaceId,
  ).watchItemStates(workspaceId, userId).map(_mapper.itemStatesToDomain);

  @override
  Future<void> markAllRead(String workspaceId, String userId) => _dao(
    workspaceId,
  ).markAllRead(workspaceId, userId, DateTime.now());

  @override
  Future<void> clearAll(String workspaceId, String userId) =>
      _dao(workspaceId).clearAll(workspaceId, userId, DateTime.now());

  @override
  Future<void> setItemRead(
    String workspaceId,
    String userId,
    String itemId, {
    required bool read,
  }) => _dao(workspaceId).setItemRead(
    workspaceId,
    userId,
    itemId,
    read ? DateTime.now() : null,
  );

  @override
  Future<void> dismissItem(
    String workspaceId,
    String userId,
    String itemId,
  ) => _dao(workspaceId).dismissItem(
    workspaceId,
    userId,
    itemId,
    DateTime.now(),
  );

  /// Records one `notifications/*` frame into [workspaceId]'s feed (pruning
  /// beyond the retention cap) and returns the stored item.
  Future<NotificationFeedItem> record(
    String workspaceId,
    String method,
    Map<String, dynamic> params,
  ) async {
    final item = NotificationFeedItem(
      id: _uuid.v4(),
      workspaceId: workspaceId,
      method: method,
      params: params,
      createdAt: DateTime.now(),
    );
    await _dao(workspaceId).insertAndPrune(
      NotificationFeedTableCompanion.insert(
        id: item.id,
        workspaceId: item.workspaceId,
        method: item.method,
        paramsJson: jsonEncode(item.params),
        createdAt: Value(item.createdAt),
      ),
    );
    return item;
  }
}
