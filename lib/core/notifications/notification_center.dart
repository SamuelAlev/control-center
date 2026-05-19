import 'dart:async';
import 'dart:convert';

import 'package:cc_domain/core/domain/notifications/notification_category.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A single entry in the in-app notification center: an [AppNotification]
/// captured when it was produced, with a received timestamp and read state.
///
/// Distinct from the ephemeral OS toast: these persist so the user has a
/// durable "what happened" history (the live-activity surface).
class NotificationEntry {
  /// Creates a [NotificationEntry].
  const NotificationEntry({
    required this.notification,
    required this.receivedAt,
    this.read = false,
  });

  /// The captured notification payload.
  final AppNotification notification;

  /// When the notification was recorded.
  final DateTime receivedAt;

  /// Whether the user has seen this entry.
  final bool read;

  /// Returns a copy of this entry marked as read.
  NotificationEntry markRead() => NotificationEntry(
        notification: notification,
        receivedAt: receivedAt,
        read: true,
      );
}

/// Persistent (across restarts), session-spanning store of recent
/// notifications, backed by `shared_preferences` (notifications are
/// non-sensitive, so no keychain/Drift schema is involved).
///
/// Fed by `RecordingNotificationPort`, which records every [AppNotification]
/// the `NotificationEventMapper` produces (before any OS-level suppression),
/// so the in-app center stays complete even when a toast is hidden during
/// focus mode / quiet hours / on-route.
class NotificationCenter extends Notifier<List<NotificationEntry>> {
  /// Maximum entries retained (most-recent-first).
  static const int maxEntries = 50;

  /// `shared_preferences` key holding the serialized entries.
  static const String prefsKey = 'notification_center_entries_v1';

  @override
  List<NotificationEntry> build() => _load();

  /// Records a newly-produced notification at the head of the list.
  void add(AppNotification notification) {
    final entry = NotificationEntry(
      notification: notification,
      receivedAt: DateTime.now(),
    );
    final next = <NotificationEntry>[entry, ...state];
    state = next.length > maxEntries ? next.sublist(0, maxEntries) : next;
    _persist();
  }

  /// Marks every entry as read. No-op if all are already read.
  void markAllRead() {
    if (state.every((e) => e.read)) {
      return;
    }
    state = [for (final e in state) e.read ? e : e.markRead()];
    _persist();
  }

  /// Removes all entries.
  void clear() {
    state = const [];
    _persist();
  }

  List<NotificationEntry> _load() {
    final raw = ref.read(appPreferencesProvider).getString(prefsKey);
    if (raw == null || raw.isEmpty) {
      return const [];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const [];
      }
      final entries = <NotificationEntry>[];
      for (final item in decoded) {
        if (item is! Map<String, dynamic>) {
          continue;
        }
        final entry = _entryFromJson(item);
        if (entry != null) {
          entries.add(entry);
        }
      }
      return entries.length > maxEntries
          ? entries.sublist(0, maxEntries)
          : entries;
    } catch (_) {
      return const [];
    }
  }

  void _persist() {
    final raw = jsonEncode([for (final e in state) _entryToJson(e)]);
    unawaited(ref.read(appPreferencesProvider).setString(prefsKey, raw));
  }

  Map<String, dynamic> _entryToJson(NotificationEntry e) => {
        'category': e.notification.category.name,
        'title': e.notification.title,
        'body': e.notification.body,
        'route': e.notification.route,
        'workspaceId': e.notification.workspaceId,
        'channelId': e.notification.channelId,
        'receivedAt': e.receivedAt.toIso8601String(),
        'read': e.read,
      };

  NotificationEntry? _entryFromJson(Map<String, dynamic> json) {
    final category = _categoryByName(json['category'] as String?);
    if (category == null) {
      return null;
    }
    final receivedAt = DateTime.tryParse(json['receivedAt'] as String? ?? '');
    if (receivedAt == null) {
      return null;
    }
    return NotificationEntry(
      notification: AppNotification(
        category: category,
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        route: json['route'] as String? ?? '/',
        workspaceId: json['workspaceId'] as String?,
        channelId: json['channelId'] as String?,
      ),
      receivedAt: receivedAt,
      read: json['read'] as bool? ?? false,
    );
  }

  NotificationCategory? _categoryByName(String? name) {
    if (name == null) {
      return null;
    }
    for (final category in NotificationCategory.values) {
      if (category.name == name) {
        return category;
      }
    }
    return null;
  }
}

/// Persistent notification center store.
final notificationCenterProvider =
    NotifierProvider<NotificationCenter, List<NotificationEntry>>(
  NotificationCenter.new,
);

/// Count of unread notification entries, for the top-bar bell badge.
final unreadNotificationCountProvider = Provider<int>(
  (ref) => ref.watch(notificationCenterProvider).where((e) => !e.read).length,
);
