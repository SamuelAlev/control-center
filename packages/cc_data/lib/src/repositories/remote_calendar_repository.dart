import 'package:cc_domain/cc_domain.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// Reads synced calendar events + connected accounts over the RPC client
/// instead of a local database.
///
/// Backs the web build and the desktop in REMOTE mode. The calendar surface is
/// workspace-scoped and the workspace rides in the request args (the host is
/// stateless — it binds no "current workspace"). Mirrors the `calendar.*` ops
/// + the `calendar.watch*` subscriptions in the host catalog.
///
/// The reads take an OPTIONAL `workspaceId`. Omitting it leaves
/// `RemoteRpcClient` to inject its ambient active workspace, which is what the
/// desktop wants — the calendar always follows the active route. A caller that
/// keeps a stream open ACROSS a workspace switch must name the workspace
/// instead: a subscription captures its args once and re-registers with them
/// on every reconnect, so an ambient-scoped stream opened in workspace A keeps
/// answering for A after the user moves to B.
///
/// The READ surface plus the OAuth-free meeting↔event linking writes are
/// exposed. Account/RSVP writes, the sync reconciler and the alert sweep all
/// depend on the host-resident OAuth tokens + Google API client, so they run
/// host-side and have no RPC surface; meeting linking is a pure junction-table
/// write, so it IS served (the recorded meeting is workspace-scoped host-side).
class RemoteCalendarRepository {
  /// Creates a [RemoteCalendarRepository] over [_client].
  RemoteCalendarRepository(this._client);

  final RemoteRpcClient _client;

  /// Live connected accounts in [workspaceId] (or the ambient workspace).
  Stream<List<CalendarAccountDto>> watchAccounts({String? workspaceId}) =>
      _client
          .subscribe('calendar.watchAccounts', {'workspace_id': ?workspaceId})
          .map(_accounts);

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

  /// Live events overlapping `[from, to)` in [workspaceId] (or the ambient
  /// workspace).
  Stream<List<CalendarEventDto>> watchEventsInRange(
    DateTime from,
    DateTime to, {
    String? workspaceId,
  }) => _client
      .subscribe('calendar.watchEventsInRange', {
        'from': from.toIso8601String(),
        'to': to.toIso8601String(),
        'workspace_id': ?workspaceId,
      })
      .map(_events);

  /// Live single event by id in [workspaceId] (or the ambient workspace);
  /// null when absent.
  Stream<CalendarEventDto?> watchEventById(
    String eventId, {
    String? workspaceId,
  }) => _client
      .subscribe('calendar.watchEventById', {
        'event_id': eventId,
        'workspace_id': ?workspaceId,
      })
      .map(_event);

  /// Asks the host to load [from, to) when the client scrolls outside the
  /// rolling sync window (`calendar.ensureRangeLoaded`). A cache fill: it
  /// returns once the range is present, and the live watch delivers the rows.
  Future<void> ensureRangeLoaded(
    DateTime from,
    DateTime to, {
    String? workspaceId,
  }) => _client.call('calendar.ensureRangeLoaded', {
    'from': from.toIso8601String(),
    'to': to.toIso8601String(),
    'workspace_id': ?workspaceId,
  });

  /// Re-syncs every connected account now (`calendar.refreshNow`). The OAuth
  /// tokens and the Google client are host-resident, so the client only asks.
  Future<void> refreshNow({String? workspaceId}) =>
      _client.call('calendar.refreshNow', {'workspace_id': ?workspaceId});

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
