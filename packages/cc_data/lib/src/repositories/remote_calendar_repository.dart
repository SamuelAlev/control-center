import 'package:cc_domain/cc_domain.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// Reads synced calendar events + connected accounts over the RPC client
/// instead of a local database.
///
/// Backs the web build and the desktop in REMOTE mode. The calendar surface is
/// workspace-scoped, and the workspace is bound server-side (via
/// `session/set_workspace`), so the reads never pass a `workspace_id` — the host
/// injects the authoritative one and scopes every query by it. Mirrors the
/// `calendar.*` ops + the `calendar.watch*` subscriptions in the host catalog.
///
/// The READ surface plus the OAuth-free meeting↔event linking writes are
/// exposed. Account/RSVP writes, the sync reconciler, and the alert sweep all
/// depend on the host-resident OAuth tokens + Google API client, so they run
/// host-side and have no RPC surface; meeting linking is a pure junction-table
/// write, so it IS served (the recorded meeting is workspace-scoped host-side).
class RemoteCalendarRepository {
  /// Creates a [RemoteCalendarRepository] over [_client].
  RemoteCalendarRepository(this._client);

  final RemoteRpcClient _client;

  /// Live connected accounts in the bound workspace.
  Stream<List<CalendarAccountDto>> watchAccounts() =>
      _client.subscribe('calendar.watchAccounts', const {}).map(_accounts);

  /// Live calendar sources for one account in the bound workspace (the
  /// account's calendar list — primary first). `accountId` is the connected
  /// account id whose calendar list to stream.
  Stream<List<CalendarSourceDto>> watchSources(String accountId) => _client
      .subscribe('calendar.watchSources', {'account_id': accountId})
      .map(_sources);

  /// Connected accounts in the bound workspace.
  Future<List<CalendarAccountDto>> getAccounts() async {
    final data = await _client.call('calendar.getAccounts', const {});
    return _accounts(data);
  }

  /// Live events overlapping `[from, to)` in the bound workspace.
  Stream<List<CalendarEventDto>> watchEventsInRange(
    DateTime from,
    DateTime to,
  ) => _client
      .subscribe('calendar.watchEventsInRange', {
        'from': from.toIso8601String(),
        'to': to.toIso8601String(),
      })
      .map(_events);

  /// Live single event by id in the bound workspace (null when absent).
  Stream<CalendarEventDto?> watchEventById(String eventId) => _client
      .subscribe('calendar.watchEventById', {'event_id': eventId})
      .map(_event);

  /// The event a meeting was recorded for, or null.
  Future<CalendarEventDto?> getEventForMeeting(String meetingId) async {
    final data = await _client.call('calendar.getEventForMeeting', {
      'meeting_id': meetingId,
    });
    return _event(data);
  }

  /// The id of the meeting recorded for an event, if any.
  Future<String?> getMeetingIdForEvent(String calendarEventId) async {
    final data = await _client.call('calendar.getMeetingIdForEvent', {
      'calendar_event_id': calendarEventId,
    });
    return data['meeting_id'] as String?;
  }

  /// Links meeting [meetingId] to calendar event [calendarEventId] (1:1; the
  /// host replaces any prior link). Pure junction-table write — no OAuth.
  Future<void> linkMeetingToEvent({
    required String meetingId,
    required String calendarEventId,
  }) => _client.call('calendar.linkMeetingToEvent', {
    'meeting_id': meetingId,
    'calendar_event_id': calendarEventId,
  });

  /// Removes meeting [meetingId]'s calendar link.
  Future<void> unlinkMeeting(String meetingId) =>
      _client.call('calendar.unlinkMeeting', {'meeting_id': meetingId});

  List<CalendarAccountDto> _accounts(Map<String, dynamic> data) =>
      ((data['accounts'] as List?) ?? const [])
          .whereType<Map>()
          .map((a) => CalendarAccountDto.fromJson(a.cast<String, dynamic>()))
          .toList();

  List<CalendarSourceDto> _sources(Map<String, dynamic> data) =>
      ((data['sources'] as List?) ?? const [])
          .whereType<Map>()
          .map((s) => CalendarSourceDto.fromJson(s.cast<String, dynamic>()))
          .toList();

  List<CalendarEventDto> _events(Map<String, dynamic> data) =>
      ((data['events'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => CalendarEventDto.fromJson(e.cast<String, dynamic>()))
          .toList();

  CalendarEventDto? _event(Map<String, dynamic> data) {
    final event = data['event'];
    return event is Map
        ? CalendarEventDto.fromJson(event.cast<String, dynamic>())
        : null;
  }
}
