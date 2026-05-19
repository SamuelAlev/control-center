import 'package:cc_domain/features/notifications/domain/entities/notification_feed_item.dart';
import 'package:cc_domain/features/notifications/domain/entities/notification_item_state.dart';
import 'package:cc_domain/features/notifications/domain/entities/notification_read_mark.dart';

/// Read/acknowledge surface over a workspace's durable notification feed.
///
/// The feed is stored per workspace (server-side, in that workspace's own
/// database file); read/cleared state is per user, in two layers: the bulk
/// watermarks ([watchReadMark]) and the per-item overrides
/// ([watchItemStates]). Recording is NOT part of this interface — only the
/// server's domain-event listener writes the feed, so the write lives on the
/// server-side implementation alone and a client adapter cannot fabricate
/// history.
abstract interface class NotificationFeedRepository {
  /// Watches the newest [limit] feed items for [workspaceId],
  /// most-recent-first.
  Stream<List<NotificationFeedItem>> watchFeed(
    String workspaceId, {
    int limit = 50,
  });

  /// Watches [userId]'s read mark in [workspaceId]. Emits null until the user
  /// first acknowledges anything.
  ///
  /// Over RPC the server keys on the session's authenticated user — a client
  /// only ever reaches its OWN mark, whatever [userId] it passes.
  Stream<NotificationReadMark?> watchReadMark(
    String workspaceId,
    String userId,
  );

  /// Watches [userId]'s per-item state overrides in [workspaceId].
  ///
  /// Bounded by the feed's retention (a state whose item was pruned is pruned
  /// with it), so this is a small set — the whole thing is streamed rather than
  /// queried per row.
  ///
  /// Over RPC the server keys on the session's authenticated user, exactly as
  /// [watchReadMark] does.
  Stream<List<NotificationItemState>> watchItemStates(
    String workspaceId,
    String userId,
  );

  /// Marks everything currently in [userId]'s feed view as seen ("mark all as
  /// read"). The stamp is the server clock.
  Future<void> markAllRead(String workspaceId, String userId);

  /// Hides everything currently in [userId]'s feed view ("clear all"). Also
  /// implies [markAllRead]. The stamp is the server clock.
  Future<void> clearAll(String workspaceId, String userId);

  /// Marks ONE item read ([read] true) or unread ([read] false) for [userId],
  /// overriding the watermark either way.
  Future<void> setItemRead(
    String workspaceId,
    String userId,
    String itemId, {
    required bool read,
  });

  /// Hides ONE item from [userId]'s list, and marks it read in the same write
  /// — a deleted row must not keep the bell badged.
  Future<void> dismissItem(String workspaceId, String userId, String itemId);
}
