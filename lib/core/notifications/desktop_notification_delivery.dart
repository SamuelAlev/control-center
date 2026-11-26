import 'dart:io';

import 'package:cc_domain/core/domain/notifications/notification_category.dart';
import 'package:flutter/services.dart';
import 'package:local_notifier/local_notifier.dart';

/// The localized titles of a notification's Approve and Deny buttons.
typedef ApprovalActionLabels = ({String approve, String deny});

/// Answers the approval [approvalId] from a notification's action button.
typedef NotificationApprovalHandler =
    void Function(String approvalId, {required bool approved});

/// The localized titles of a meeting notification's buttons.
typedef MeetingActionLabels = ({
  String join,
  String joinAndRecord,
  String record,
});

/// What a meeting notification's button asks for.
enum MeetingNotificationAction {
  /// Open the call link.
  join('join'),

  /// Open the call link and record the meeting.
  joinAndRecord('joinAndRecord'),

  /// Record a meeting that has no call link.
  record('record');

  const MeetingNotificationAction(this.wire);

  /// The value the native side reports the button as.
  final String wire;
}

/// Acts on [meeting] from a notification's action button.
typedef NotificationMeetingHandler =
    void Function(
      NotificationMeeting meeting,
      MeetingNotificationAction action,
    );

/// The buttons a notification for [meeting] carries, in display order: Join
/// and Join and record when there is a call link, otherwise Record alone.
List<MeetingNotificationAction> meetingNotificationActions(
  NotificationMeeting meeting,
) => meeting.joinable
    ? const [
        MeetingNotificationAction.join,
        MeetingNotificationAction.joinAndRecord,
      ]
    : const [MeetingNotificationAction.record];

String _meetingActionLabel(
  MeetingNotificationAction action,
  MeetingActionLabels labels,
) => switch (action) {
  MeetingNotificationAction.join => labels.join,
  MeetingNotificationAction.joinAndRecord => labels.joinAndRecord,
  MeetingNotificationAction.record => labels.record,
};

/// Port for the final OS-level delivery of a desktop notification.
///
/// `LocalNotificationService` owns all preference/suppression/sound logic and
/// then hands a fully-decided notification to a [DesktopNotificationDelivery]
/// for actual display. Isolating the native call behind this seam lets macOS
/// use the modern `UNUserNotificationCenter` (which has a real authorization
/// model and shows banners reliably on macOS 11+) while Windows and Linux keep
/// the `local_notifier` package.
abstract interface class DesktopNotificationDelivery {
  /// Requests OS permission to post notifications, where the platform requires
  /// it. A no-op where notifications need no explicit grant (Windows/Linux via
  /// `local_notifier`). On macOS this triggers the one-time system prompt and
  /// registers the app under System Settings → Notifications.
  Future<void> requestPermission();

  /// Displays a native notification. [route] is carried through so a click can
  /// navigate back into the app via the injected `onNavigate` callback.
  ///
  /// A notification already delivered under [id] is replaced, and the
  /// replacement alerts again. That is how a reminder re-raises a wait.
  ///
  /// [timeSensitive] asks the OS to treat the notification as time-sensitive
  /// (macOS: it may break through a Focus the operator allowed it in).
  /// [approvalId] adds Approve and Deny buttons that answer that approval
  /// through the injected approval handler. [meeting] adds the meeting
  /// buttons ([meetingNotificationActions]), answered by the meeting handler.
  Future<void> show({
    required String id,
    required String title,
    required String body,
    required String route,
    bool timeSensitive = false,
    String? approvalId,
    NotificationMeeting? meeting,
  });

  /// Removes the notification delivered under [id], whether it is still on
  /// screen or only in the system's list. A no-op for an unknown [id].
  Future<void> remove(String id);

  /// Releases any native resources / listeners.
  void dispose();
}

/// Returns the [DesktopNotificationDelivery] appropriate for the host platform:
/// the native `UNUserNotificationCenter` channel on macOS, `local_notifier`
/// elsewhere. [onNavigate] handles click-through routing, [onApproval] the
/// Approve/Deny buttons, titled by [actionLabels] at show time, and
/// [onMeetingAction] the meeting buttons, titled by [meetingLabels].
DesktopNotificationDelivery createDesktopNotificationDelivery({
  required void Function(String route) onNavigate,
  required NotificationApprovalHandler onApproval,
  required ApprovalActionLabels Function() actionLabels,
  required NotificationMeetingHandler onMeetingAction,
  required MeetingActionLabels Function() meetingLabels,
}) {
  if (Platform.isMacOS) {
    return MacOsChannelNotificationDelivery(
      onNavigate: onNavigate,
      onApproval: onApproval,
      actionLabels: actionLabels,
      onMeetingAction: onMeetingAction,
      meetingLabels: meetingLabels,
    );
  }
  return LocalNotifierNotificationDelivery(
    onNavigate: onNavigate,
    onApproval: onApproval,
    actionLabels: actionLabels,
    onMeetingAction: onMeetingAction,
    meetingLabels: meetingLabels,
  );
}

/// macOS delivery backed by the native `UNUserNotificationCenter` method
/// channel (`com.controlcenter/notifications`, see
/// `macos/Runner/MacOsNotifier.swift`).
class MacOsChannelNotificationDelivery implements DesktopNotificationDelivery {
  /// Creates a [MacOsChannelNotificationDelivery]. [channel] is injectable for
  /// tests; production uses the shared `com.controlcenter/notifications` channel.
  MacOsChannelNotificationDelivery({
    required this._onNavigate,
    required this._onApproval,
    required this._actionLabels,
    required this._onMeetingAction,
    required this._meetingLabels,
    MethodChannel? channel,
  }) : _channel =
           channel ?? const MethodChannel('com.controlcenter/notifications') {
    _channel.setMethodCallHandler(_handleNativeCall);
  }

  final void Function(String route) _onNavigate;
  final NotificationApprovalHandler _onApproval;
  final ApprovalActionLabels Function() _actionLabels;
  final NotificationMeetingHandler _onMeetingAction;
  final MeetingActionLabels Function() _meetingLabels;
  final MethodChannel _channel;

  Future<dynamic> _handleNativeCall(MethodCall call) async {
    final args = call.arguments;
    if (args is! Map) {
      return null;
    }
    switch (call.method) {
      case 'onNotificationClick':
        final route = args['route'] as String?;
        if (route != null && route.isNotEmpty) {
          _onNavigate(route);
        }
      case 'onNotificationAction':
        final meeting = _meetingFromNative(args);
        if (meeting != null) {
          final action = MeetingNotificationAction.values
              .where((a) => a.wire == args['action'])
              .firstOrNull;
          // A button the meeting does not offer (Join with no link) is
          // ignored rather than trusted.
          if (action != null &&
              meetingNotificationActions(meeting).contains(action)) {
            _onMeetingAction(meeting, action);
          }
          return null;
        }
        final approvalId = args['approvalId'] as String?;
        if (approvalId == null || approvalId.isEmpty) {
          return null;
        }
        switch (args['action']) {
          case 'approve':
            _onApproval(approvalId, approved: true);
          case 'deny':
            _onApproval(approvalId, approved: false);
        }
    }
    return null;
  }

  /// The meeting a native action names, or null when it names none.
  static NotificationMeeting? _meetingFromNative(Map<dynamic, dynamic> args) {
    final workspaceId = args['meetingWorkspaceId'];
    final eventId = args['meetingEventId'];
    final url = args['meetingUrl'];
    if (workspaceId is! String ||
        workspaceId.isEmpty ||
        eventId is! String ||
        eventId.isEmpty) {
      return null;
    }
    return NotificationMeeting(
      workspaceId: workspaceId,
      eventId: eventId,
      meetingUrl: url is String && url.isNotEmpty ? url : null,
    );
  }

  @override
  Future<void> requestPermission() =>
      _channel.invokeMethod<void>('requestAuthorization');

  @override
  Future<void> show({
    required String id,
    required String title,
    required String body,
    required String route,
    bool timeSensitive = false,
    String? approvalId,
    NotificationMeeting? meeting,
  }) {
    final labels = approvalId == null ? null : _actionLabels();
    final meetingLabels = meeting == null ? null : _meetingLabels();
    return _channel.invokeMethod<void>('notify', {
      'identifier': id,
      'title': title,
      'body': body,
      'route': route,
      'timeSensitive': timeSensitive,
      if (approvalId != null && labels != null) ...{
        'approvalId': approvalId,
        'approveLabel': labels.approve,
        'denyLabel': labels.deny,
      },
      if (meeting != null && meetingLabels != null) ...{
        'meetingWorkspaceId': meeting.workspaceId,
        'meetingEventId': meeting.eventId,
        'meetingUrl': ?meeting.meetingUrl,
        'meetingActions': [
          for (final action in meetingNotificationActions(meeting))
            {
              'id': action.wire,
              'label': _meetingActionLabel(action, meetingLabels),
            },
        ],
      },
    });
  }

  @override
  Future<void> remove(String id) =>
      _channel.invokeMethod<void>('remove', {'identifier': id});

  @override
  void dispose() => _channel.setMethodCallHandler(null);
}

/// Windows/Linux delivery backed by the `local_notifier` package.
///
/// Neither platform has a time-sensitive level through this package, so
/// [show]'s `timeSensitive` is ignored here; the Approve/Deny buttons are
/// supported on both.
class LocalNotifierNotificationDelivery implements DesktopNotificationDelivery {
  /// Creates a [LocalNotifierNotificationDelivery]. [_onNavigate] is invoked when
  /// the user clicks a delivered notification.
  LocalNotifierNotificationDelivery({
    required this._onNavigate,
    required this._onApproval,
    required this._actionLabels,
    required this._onMeetingAction,
    required this._meetingLabels,
  });

  final void Function(String route) _onNavigate;
  final NotificationApprovalHandler _onApproval;
  final ApprovalActionLabels Function() _actionLabels;
  final NotificationMeetingHandler _onMeetingAction;
  final MeetingActionLabels Function() _meetingLabels;

  /// Notifications still open, by identifier, so a replacement or a
  /// withdrawal can close the one already on screen.
  final Map<String, LocalNotification> _open = {};

  @override
  Future<void> requestPermission() async {}

  @override
  Future<void> show({
    required String id,
    required String title,
    required String body,
    required String route,
    bool timeSensitive = false,
    String? approvalId,
    NotificationMeeting? meeting,
  }) async {
    await remove(id);
    final labels = approvalId == null ? null : _actionLabels();
    final meetingActions = meeting == null
        ? const <MeetingNotificationAction>[]
        : meetingNotificationActions(meeting);
    final meetingLabels = meeting == null ? null : _meetingLabels();
    final notification = LocalNotification(
      identifier: id,
      title: title,
      body: body,
      actions: labels != null
          ? [
              LocalNotificationAction(text: labels.approve),
              LocalNotificationAction(text: labels.deny),
            ]
          : meetingLabels != null
          ? [
              for (final action in meetingActions)
                LocalNotificationAction(
                  text: _meetingActionLabel(action, meetingLabels),
                ),
            ]
          : null,
    )..onClick = () => _onNavigate(route);
    // Close events are matched by identifier, so the close of a replaced
    // notification can reach its replacement: forget only this instance.
    notification.onClose = (_) {
      if (identical(_open[id], notification)) {
        _open.remove(id);
      }
    };
    if (approvalId != null) {
      // Button order is fixed above: 0 approves, 1 denies.
      notification.onClickAction = (index) => switch (index) {
        0 => _onApproval(approvalId, approved: true),
        1 => _onApproval(approvalId, approved: false),
        _ => null,
      };
    } else if (meeting != null) {
      notification.onClickAction = (index) {
        if (index >= 0 && index < meetingActions.length) {
          _onMeetingAction(meeting, meetingActions[index]);
        }
      };
    }
    _open[id] = notification;
    return notification.show();
  }

  @override
  Future<void> remove(String id) async {
    final previous = _open.remove(id);
    if (previous != null) {
      await previous.destroy();
    }
  }

  @override
  void dispose() {}
}
