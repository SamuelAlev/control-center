import 'package:cc_domain/features/calendar/domain/entities/calendar_event.dart';
import 'package:cc_domain/features/calendar/domain/repositories/calendar_repository.dart';
import 'package:cc_domain/features/meetings/domain/services/conferencing_apps.dart';
import 'package:cc_domain/features/meetings/domain/services/meeting_detection.dart';
import 'package:cc_domain/features/meetings/domain/services/meeting_signal_collector.dart';

/// Emits a [MeetingSignalKind.calendarEvent] signal while a real, accepted
/// meeting is scheduled to be happening now. Fully portable — reads the synced
/// calendar the app already keeps. A separate [MeetingSignalKind.browserMeeting]
/// signal is emitted when the live event carries a known conferencing URL.
class CalendarMeetingSignalCollector implements MeetingSignalCollector {
  /// Creates a [CalendarMeetingSignalCollector].
  CalendarMeetingSignalCollector({
    required this.repository,
    required this.activeWorkspaceId,
    this.startGrace = const Duration(minutes: 2),
  });

  /// The calendar store.
  final CalendarRepository repository;

  /// Resolves the workspace whose calendar to read (null when none active).
  final String? Function() activeWorkspaceId;

  /// How long before an event's start time it is treated as "happening now".
  final Duration startGrace;

  @override
  Future<List<MeetingSignal>> sample(DateTime now) async {
    final workspaceId = activeWorkspaceId();
    if (workspaceId == null) {
      return const [];
    }
    // A snapshot wide enough to include anything live right now.
    final events = await repository
        .watchEventsInRange(
          workspaceId,
          now.subtract(const Duration(hours: 3)),
          now.add(const Duration(hours: 1)),
        )
        .first;

    final signals = <MeetingSignal>[];
    for (final e in events) {
      if (!_isLive(e, now)) {
        continue;
      }
      signals.add(MeetingSignal(
        kind: MeetingSignalKind.calendarEvent,
        active: true,
        at: now,
        label: e.title,
      ));
      final url = e.meetingUrl;
      if (url != null && matchMeetingUrl(url) != null) {
        signals.add(MeetingSignal(
          kind: MeetingSignalKind.browserMeeting,
          active: true,
          at: now,
          label: e.title,
        ));
      }
    }
    return signals;
  }

  bool _isLive(CalendarEvent e, DateTime now) {
    if (e.isAllDay || e.status == CalendarEventStatus.cancelled) {
      return false;
    }
    if (e.myResponseStatus == 'declined') {
      return false;
    }
    // Ignore solo blocks: a real meeting has other people or a join link.
    final isMeeting = (e.meetingUrl != null && e.meetingUrl!.isNotEmpty) ||
        e.attendees.length >= 2;
    if (!isMeeting) {
      return false;
    }
    final start = e.startTime.toLocal().subtract(startGrace);
    final end = e.endTime.toLocal();
    return !now.isBefore(start) && now.isBefore(end);
  }
}
