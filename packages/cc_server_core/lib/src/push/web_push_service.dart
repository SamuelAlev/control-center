import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cc_domain/features/notifications/domain/entities/notification_feed_item.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_server_core/src/push/web_push_repository.dart';
import 'package:cc_server_core/src/push/web_push_transport.dart';
import 'package:webpush_encryption/webpush_encryption.dart'
    show PublicWebPushKey;

/// Cross-workspace by design: paired devices are global user identity; an
/// individual event is still scoped to one registered workspace and rechecks
/// membership before each external delivery.
class WebPushService {
  /// Binds live identity/visibility checks to the server's persisted push state.
  WebPushService({
    required this.repository,
    required this.devices,
    required this.workspaceExists,
    required this.isMember,
    required this.canViewNotification,
    required this.ownerUserId,
    required this.viewerLogin,
    required this.vapid,
    this._transport = const WebPushTransport(),
  });

  /// Owner-only subscription and signing-key persistence.
  final WebPushRepository repository;

  /// Global paired-device identity, re-read before each delivery.
  final PairedDeviceDao devices;

  /// Checks that an event's workspace is still registered and not deleted.
  final Future<bool> Function(String workspaceId) workspaceExists;

  /// Checks the recipient's current workspace membership.
  final Future<bool> Function(String workspaceId, String userId) isMember;

  /// Live feed visibility, including linked repository and space grants.
  final Future<bool> Function(NotificationFeedItem item, String userId)
  canViewNotification;

  /// Server owner used to scope legacy PR frames without an explicit recipient.
  final String ownerUserId;

  /// Resolves forge logins to avoid notifying actors about their own actions.
  final Future<String> Function(String userId) viewerLogin;

  /// Stable server-wide signer shared by registered browser subscriptions.
  final VapidIdentity vapid;
  final WebPushTransport _transport;
  int _inFlight = 0;
  bool _closed = false;
  final Set<Future<void>> _pending = {};

  /// Admission limit for transient alerts; the durable Activity row is retained.
  static const maxConcurrent = 4;

  /// Never expose endpoint or auth keys through the RPC read response.
  Future<Map<String, dynamic>> status(String userId, String deviceId) async {
    await _assertDevice(userId, deviceId);
    final record = await repository.read(deviceId);
    return {
      'enabled': record != null,
      'quiet': record?.quiet ?? false,
      'categories': record == null
          ? <String>[]
          : (record.categories.toList()..sort()),
      'vapid_public_key': vapid.publicKey,
    };
  }

  /// Validates and replaces an active device's subscription and preferences.
  Future<Map<String, dynamic>> register({
    required String userId,
    required String deviceId,
    required String endpoint,
    required String p256dh,
    required String auth,
    required Set<String> categories,
    required bool quiet,
  }) async {
    await _assertDevice(userId, deviceId);
    validatedPushEndpoint(endpoint);
    if (p256dh.length > 100 ||
        auth.length > 32 ||
        categories.length > pushCategories.length ||
        base64Url.decode(base64Url.normalize(p256dh)).length != 65 ||
        base64Url.decode(base64Url.normalize(auth)).length != 16 ||
        !categories.every(pushCategories.contains)) {
      throw const FormatException('Invalid WebPush subscription');
    }
    try {
      await PublicWebPushKey.fromMap({
        'p256dh': base64Url.decode(base64Url.normalize(p256dh)),
        'auth': base64Url.decode(base64Url.normalize(auth)),
      });
    } on Object {
      throw const FormatException('Invalid WebPush public key');
    }
    await repository.save(
      deviceId,
      PushSubscriptionRecord(
        endpoint: endpoint,
        p256dh: p256dh,
        auth: auth,
        categories: categories,
        quiet: quiet,
      ),
    );
    try {
      return await status(userId, deviceId);
    } on Object {
      if ((await repository.read(deviceId))?.endpoint == endpoint) {
        await repository.remove(deviceId);
      }
      rethrow;
    }
  }

  /// Removes a subscription only for its authenticated, active owner device.
  Future<void> remove(String userId, String deviceId) async {
    await _assertDevice(userId, deviceId);
    await repository.remove(deviceId);
  }

  /// Deletes subscription state when the pairing authority revokes a device.
  Future<void> revokeDevice(String deviceId) =>
      repository.revokeDevice(deviceId);

  Future<void> _assertDevice(String userId, String deviceId) async {
    final device = await devices.getById(deviceId);
    if (device == null ||
        device.userId != userId ||
        device.status != PairedDeviceStatus.active ||
        (device.expiresAt != null &&
            !device.expiresAt!.isAfter(DateTime.now()))) {
      throw StateError('Device is not active');
    }
  }

  /// Called only after the durable feed write succeeds. Saturation drops a
  /// transient alert; the row remains in the feed for the user to read later.
  void onRecorded(NotificationFeedItem item) {
    if (_closed || _inFlight >= maxConcurrent) {
      return;
    }
    final category = categoryForPush(item.method);
    if (category == null) {
      return;
    }
    _inFlight++;
    late final Future<void> task;
    task = _deliver(item, category)
        .catchError((Object _) {
          // No endpoint / capability or untrusted upstream exception in logs.
        })
        .whenComplete(() {
          _inFlight--;
          _pending.remove(task);
        });
    _pending.add(task);
  }

  Future<void> _deliver(NotificationFeedItem item, String category) async {
    if (!await workspaceExists(item.workspaceId)) {
      return;
    }
    final rows = await devices.getAll();
    for (final device in rows) {
      if (_closed) {
        return;
      }
      if (device.userId == null ||
          device.status != PairedDeviceStatus.active ||
          (device.expiresAt != null &&
              !device.expiresAt!.isAfter(DateTime.now()))) {
        continue;
      }
      final record = await repository.read(device.id);
      final categoryForDevice = category == 'message'
          ? ((item.params['mentions'] as List?)?.contains(
                      'user:${device.userId}',
                    ) ==
                    true
                ? 'newMessage'
                : 'agentRunCompleted')
          : category;
      if (record == null ||
          record.quiet ||
          !record.categories.contains(categoryForDevice) ||
          !pushFrameTargetsUser(item.method, item.params, device.userId!)) {
        continue;
      }
      if (_ownerOnlyPrMethod(item.method) &&
          item.params['for_user_id'] == null &&
          device.userId != ownerUserId) {
        continue;
      }
      final actor = [
        item.params['merged_by_login'],
        item.params['approver_login'],
        item.params['author_login'],
      ].whereType<String>().where((value) => value.isNotEmpty).firstOrNull;
      if (actor != null) {
        String login;
        try {
          login = await viewerLogin(
            device.userId!,
          ).timeout(const Duration(seconds: 2), onTimeout: () => '');
        } on Object {
          login = '';
        }
        // Unknown identity is not license to alert the actor about their own
        // action. Keep the durable feed row for later.
        if (login.isEmpty || login.toLowerCase() == actor.toLowerCase()) {
          continue;
        }
      }
      // Recheck against the database before each POST, after asynchronous
      // encryption/DNS work in the transport another revocation may still race.
      if (!await isMember(item.workspaceId, device.userId!)) {
        continue;
      }
      if (!await canViewNotification(item, device.userId!)) {
        continue;
      }
      final current = await devices.getById(device.id);
      if (current == null ||
          current.status != PairedDeviceStatus.active ||
          current.userId != device.userId ||
          (current.expiresAt != null &&
              !current.expiresAt!.isAfter(DateTime.now()))) {
        await repository.remove(device.id);
        continue;
      }
      try {
        final route = safePushRoute(item.workspaceId, item.method, item.params);
        final payload = Uint8List.fromList(
          utf8.encode(
            jsonEncode({
              'v': 1,
              'route': route,
              'kind': category == 'agentAwaitingInput'
                  ? 'attention'
                  : 'activity',
            }),
          ),
        );
        final outcome = await _transport.send(
          subscription: record,
          vapid: vapid,
          payload: payload,
          maySend: () async {
            if (_closed ||
                !await workspaceExists(item.workspaceId) ||
                !await isMember(item.workspaceId, device.userId!) ||
                !await canViewNotification(item, device.userId!)) {
              return false;
            }
            final live = await devices.getById(device.id);
            final currentRecord = await repository.read(device.id);
            return live != null &&
                live.status == PairedDeviceStatus.active &&
                live.userId == device.userId &&
                (live.expiresAt == null ||
                    live.expiresAt!.isAfter(DateTime.now())) &&
                currentRecord?.endpoint == record.endpoint &&
                currentRecord?.p256dh == record.p256dh &&
                currentRecord?.quiet == false &&
                currentRecord!.categories.contains(categoryForDevice);
          },
        );
        if (outcome == PushDeliveryResult.expired) {
          // A concurrently renewed subscription must not be deleted.
          if ((await repository.read(device.id))?.endpoint == record.endpoint) {
            await repository.remove(device.id);
          }
        }
      } on Object {
        // A malformed/unreachable provider must not block feed persistence.
      }
    }
  }

  /// Shutdown stops admission and allows bounded outstanding sends to finish.
  Future<void> dispose() async {
    _closed = true;
    await Future.wait(
      _pending.toList(),
    ).timeout(const Duration(seconds: 12), onTimeout: () => <void>[]);
  }
}

/// Persisted per-device opt-in categories accepted by registration.
const pushCategories = <String>{
  'agentRunCompleted',
  'agentAwaitingInput',
  'newMessage',
  'pullRequestPublished',
  'prMerged',
  'prMentioned',
  'reviewRequested',
  'reviewStale',
  'prMergeReadiness',
  'prReviewDecision',
  'prChecksStatus',
  'prThreadActivity',
  'ticketAssigned',
  'ticketStatusChanged',
  'meetingStartsSoon',
  'calendarAuthExpired',
  'rigStatusChanged',
};

/// Maps durable notification methods to delivery categories, excluding unknowns.
String? categoryForPush(String method) => switch (method) {
  'notifications/message_received' => 'message',
  'notifications/agent_awaiting_input' ||
  'notifications/agent_action_blocked' => 'agentAwaitingInput',
  'notifications/pr_published' => 'pullRequestPublished',
  'notifications/pr_merged' || 'notifications/external_pr_merged' => 'prMerged',
  'notifications/pr_mentioned' => 'prMentioned',
  'notifications/pr_review_requested' => 'reviewRequested',
  'notifications/review_stale' => 'reviewStale',
  'notifications/pr_ready_to_merge' ||
  'notifications/pr_merge_blocked' => 'prMergeReadiness',
  'notifications/pr_approved' ||
  'notifications/pr_changes_requested' ||
  'notifications/pr_review_dismissed' => 'prReviewDecision',
  'notifications/pr_checks_failed' ||
  'notifications/pr_checks_recovered' => 'prChecksStatus',
  'notifications/pr_comment_mentioned' ||
  'notifications/pr_thread_replied' ||
  'notifications/pr_thread_resolved' => 'prThreadActivity',
  'notifications/ticket_assigned' => 'ticketAssigned',
  'notifications/ticket_status_changed' => 'ticketStatusChanged',
  'notifications/meeting_starting_soon' => 'meetingStartsSoon',
  'notifications/calendar_auth_expired' => 'calendarAuthExpired',
  'notifications/rig_control_changed' ||
  'notifications/rig_reaped' ||
  'notifications/rig_closed' => 'rigStatusChanged',
  _ => null,
};
bool _ownerOnlyPrMethod(String method) => const {
  'notifications/pr_mentioned',
  'notifications/pr_review_requested',
  'notifications/pr_ready_to_merge',
  'notifications/pr_merge_blocked',
  'notifications/pr_approved',
  'notifications/pr_changes_requested',
  'notifications/pr_review_dismissed',
  'notifications/pr_checks_failed',
  'notifications/pr_checks_recovered',
  'notifications/pr_comment_mentioned',
  'notifications/pr_thread_replied',
  'notifications/pr_thread_resolved',
}.contains(method);

/// Fail closed for directed events; self-authored messages are not alerts.
bool pushFrameTargetsUser(
  String method,
  Map<String, dynamic> p,
  String userId,
) {
  final recipient = p['for_user_id'];
  if (recipient != null && recipient != userId) {
    return false;
  }
  if (method == 'notifications/message_received') {
    if (p['sender_user_id'] == userId ||
        (p['content_preview'] as String? ?? '').trim().isEmpty) {
      return false;
    }
    final mentions = p['mentions'];
    if (mentions is List && mentions.contains('user:$userId')) {
      return true;
    }
    final requestedBy = p['requested_by_user_id'];
    return p['is_agent_message'] == true &&
        (requestedBy == null || requestedBy == userId);
  }
  if (method == 'notifications/ticket_assigned' &&
      p['assignee_type'] == 'user') {
    return p['assigned_agent_id'] == userId;
  }
  if (method == 'notifications/rig_control_changed' && p['held'] == true) {
    return p['controller'] != 'user:$userId';
  }
  return true;
}

/// Only known PWA route shapes. Never trust a URL embedded in the event frame.
String safePushRoute(
  String workspaceId,
  String method,
  Map<String, dynamic> p,
) {
  final ws = Uri.encodeQueryComponent(workspaceId);
  if (method == 'notifications/message_received' ||
      method == 'notifications/agent_awaiting_input') {
    final space = p['space_id'];
    if (space is String && RegExp(r'^[a-zA-Z0-9_-]{1,128}$').hasMatch(space)) {
      return Uri(
        pathSegments: ['', 'spaces', space],
        queryParameters: {
          'workspace_id': workspaceId,
          if (p['conversation_id'] case final String conversation
              when conversation.isNotEmpty && conversation.length <= 128)
            'conversation_id': conversation,
          if (p['message_id'] case final String message
              when message.isNotEmpty && message.length <= 128)
            'message_id': message,
        },
      ).toString();
    }
  }
  return '/inbox?workspace_id=$ws';
}
