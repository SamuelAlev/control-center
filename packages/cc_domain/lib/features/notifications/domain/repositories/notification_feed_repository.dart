import 'package:cc_domain/features/notifications/domain/entities/notification_feed_item.dart';
import 'package:cc_domain/features/notifications/domain/entities/notification_read_mark.dart';

/// Read/acknowledge surface over a workspace's durable notification feed.
///
/// The feed is stored per workspace (server-side, in that workspace's own
/// database file); read/cleared state is per user. Recording is NOT part of
/// this interface — only the server's domain-event listener writes the feed,
/// so the write lives on the server-side implementation alone and a client
/// adapter cannot fabricate history.
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

  /// Marks everything currently in [userId]'s feed view as seen (bell
  /// opened). The stamp is the server clock.
  Future<void> markAllRead(String workspaceId, String userId);

  /// Hides everything currently in [userId]'s feed view ("clear all"). Also
  /// implies [markAllRead]. The stamp is the server clock.
  Future<void> clearAll(String workspaceId, String userId);
}
