// Maps the connected `cc_server`'s pushed `notifications/*` JSON-RPC frames to
// [AppNotification]s — the thin-client replacement for the old
// `NotificationEventMapper` (which subscribed to the local `DomainEventBus`,
// a bus that only ever saw events the desktop's OWN in-process execution
// raised — dead since the thin-client flip, since execution now happens
// server-side).
//
// The server is stateless — every event it forwards carries its own
// `workspace_id` (or none, for the genuinely cross-workspace external-PR
// signal) — so this filters to the session's active workspace before
// rendering, mirroring the workspace-scoped activity feed.
//
// The actual per-method frame → [AppNotification] building (including the
// PRD 16 §7 principal routing rules) lives in `notification_frame_mapper.dart`
// and is shared with the server-fed notification center, so the live toast and
// the durable bell history always agree.
library;

import 'dart:async';

import 'package:cc_domain/cc_domain.dart' show JsonRpcNotification;
import 'package:cc_domain/core/domain/notifications/notification_category.dart';
import 'package:cc_domain/core/domain/ports/notification_port.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:control_center/core/notifications/notification_frame_mapper.dart';
import 'package:control_center/l10n/app_localizations.dart';

/// Subscribes to the connected [RemoteRpcClient]'s push notifications and maps
/// the `notifications/*` frames the server's `RemoteEventForwarder` sends to
/// [AppNotification]s. Pure mapping logic — the actual display is delegated to
/// [NotificationPort].
class RpcNotificationMapper {
  /// Creates an [RpcNotificationMapper] and subscribes to [client].
  RpcNotificationMapper({
    required RemoteRpcClient client,
    required this._notificationPort,
    required this._localizations,
    required this._activeWorkspaceId,
    this._currentUserId,
    this._mutedRepos,
    this._viewerLogins,
  }) {
    _sub = client.notifications.listen(_onFrame);
  }

  final NotificationPort _notificationPort;
  final AppLocalizations Function() _localizations;
  final String? Function() _activeWorkspaceId;

  /// Resolves the signed-in user's id for principal-aware routing (PRD 16
  /// §7). Null (not wired, or identity still loading) degrades every routing
  /// rule to its pre-multiplayer fallback — never a silently dropped
  /// notification.
  final String? Function()? _currentUserId;

  /// Resolves the repositories whose notifications the operator muted. Read at
  /// call time, not construction, so toggling a mute takes effect on the next
  /// frame rather than on the next app launch.
  final Set<String> Function()? _mutedRepos;

  /// Resolves the operator's lower-cased account name on each connected forge,
  /// so a frame describing the operator's OWN action can be dropped. Read at
  /// call time so connecting a forge takes effect on the next frame.
  final Set<String> Function()? _viewerLogins;
  late final StreamSubscription<JsonRpcNotification> _sub;

  void _onFrame(JsonRpcNotification frame) {
    final workspaceId = frame.params['workspace_id'] as String?;
    // The forwarder is stateless and pushes every workspace's events; only
    // render the ones scoped to the session's active workspace (or carrying
    // none — those are genuinely cross-workspace, e.g. external-PR polling).
    if (workspaceId != null && workspaceId != _activeWorkspaceId()) {
      return;
    }
    // PRD 16 §7(c): approval-needed and task-failure pings are deliberately
    // NOT routed/filtered here. They are not broadcast in the first place —
    // approval requests already resolve to a specific responsible principal
    // upstream (`ApprovalEscalationSweeper`/the approval workflow) and the
    // frame mapper has no case for them at all (there is no
    // `notifications/approval_needed` frame; task-lifecycle frames like
    // `notifications/task_failed` are pushed but not rendered as an OS
    // notification here). Nothing to suppress — "keep notifying" is a no-op.
    final notification = mapNotificationFrame(
      frame.method,
      frame.params,
      l10n: _localizations(),
      currentUserId: _currentUserId?.call(),
      mutedRepos: _mutedRepos?.call() ?? const {},
      viewerLogins: _viewerLogins?.call() ?? const {},
    );
    if (notification == null) {
      return;
    }
    _notificationPort.show(notification);
  }

  /// Cancels the notification subscription.
  void dispose() {
    _sub.cancel();
  }
}
