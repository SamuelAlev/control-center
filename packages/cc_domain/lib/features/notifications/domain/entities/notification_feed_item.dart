import 'dart:convert';

/// One entry in a workspace's durable notification feed: the raw
/// `notifications/*` frame ([method] + [params]) the server recorded when the
/// originating domain event fired, stamped with the server-side [createdAt].
///
/// The feed deliberately stores the *wire frame*, not rendered text: the
/// client renders each item through the same frame → notification mapping it
/// uses for live pushes, so titles/bodies localize in the viewer's current
/// locale and the per-principal routing rules (PRD 16 §7 — mentions,
/// requested-by, human assignee) apply identically at read time. An item one
/// user's client suppresses is simply not rendered for them; it is never a
/// different stored row.
class NotificationFeedItem {
  /// Creates a [NotificationFeedItem].
  NotificationFeedItem({
    required this.id,
    required this.workspaceId,
    required this.method,
    required this.params,
    required this.createdAt,
  }) : assert(id != '', 'id must not be empty'),
       assert(workspaceId != '', 'workspaceId must not be empty'),
       assert(
         method.startsWith('notifications/'),
         'method must be a notifications/* frame method',
       );

  /// Unique item identifier.
  final String id;

  /// Owning workspace (the isolation boundary).
  final String workspaceId;

  /// The JSON-RPC notification method, e.g. `notifications/pr_merged`.
  final String method;

  /// The frame's wire params, exactly as the forwarder pushes them.
  final Map<String, dynamic> params;

  /// When the server recorded the item (server clock — clients never stamp).
  final DateTime createdAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationFeedItem &&
          id == other.id &&
          workspaceId == other.workspaceId &&
          method == other.method &&
          jsonEncode(params) == jsonEncode(other.params) &&
          createdAt == other.createdAt;

  @override
  int get hashCode =>
      Object.hash(id, workspaceId, method, jsonEncode(params), createdAt);
}
