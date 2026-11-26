import 'package:cc_domain/core/domain/notifications/notification_category.dart';
import 'package:control_center/di/demo_providers.dart';
import 'package:control_center/features/calendar/presentation/providers/record_and_link_provider.dart';
import 'package:control_center/router/routes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What recording from a meeting alert came to.
///
/// `route` is where the app should go next: the live recording when it
/// `started`, otherwise the event, where the person can try again. `error` is
/// the recorder's own message when it has one.
typedef MeetingAlertRecording = ({bool started, String route, String? error});

/// The actions a meeting-starting alert offers, for both surfaces that raise
/// one: the in-app banner and the OS notification. Neither has the event
/// loaded (or, for the OS notification, a widget tree), so these work from the
/// alert's [NotificationMeeting] alone and leave navigation to the caller.
class MeetingAlertActions {
  /// Creates a [MeetingAlertActions].
  MeetingAlertActions(this._ref);

  final Ref _ref;

  /// Opens the meeting's call link. False when it has none or the system
  /// refused it.
  bool join(NotificationMeeting meeting) {
    final url = meeting.meetingUrl;
    return url != null && _ref.read(calendarRecordAndLinkProvider).join(url);
  }

  /// Joins the call (when there is one) and records the meeting, linked to
  /// its calendar event. Closed on public demo workspaces, like the event's
  /// own record action.
  Future<MeetingAlertRecording> joinAndRecord(
    NotificationMeeting meeting,
  ) async {
    final eventRoute = calendarDetailRoute(
      meeting.workspaceId,
      meeting.eventId,
    );
    if (_ref.read(isDemoServerProvider)) {
      return (started: false, route: eventRoute, error: null);
    }
    final result = await _ref
        .read(calendarRecordAndLinkProvider)
        .startRecordingForEventId(
          workspaceId: meeting.workspaceId,
          eventId: meeting.eventId,
        );
    if (result.meetingId != null) {
      return (
        started: true,
        route: meetingsRecordRoute(meeting.workspaceId),
        error: null,
      );
    }
    // The event never loaded, so nothing joined the call yet: the alert's own
    // link still gets the person into the meeting.
    if (result.error == null) {
      join(meeting);
    }
    return (started: false, route: eventRoute, error: result.error);
  }
}

/// Provides the [MeetingAlertActions].
final meetingAlertActionsProvider = Provider<MeetingAlertActions>(
  MeetingAlertActions.new,
);
