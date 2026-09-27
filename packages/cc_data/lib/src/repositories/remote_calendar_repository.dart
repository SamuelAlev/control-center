import 'package:cc_domain/cc_domain.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// Reads synced calendar events + connected accounts over the RPC client instead of a local
/// database.
///
/// Backs the web build and the desktop in REMOTE mode.
/// All render subscriptions carry an explicit workspace id so a provider
/// reload cannot serve a snapshot from the previously selected workspace.
class RemoteCalendarRepository {
  /// Creates a [RemoteCalendarRepository] over [_client].
  RemoteCalendarRepository(this._client);

  final RemoteRpcClient _client;

  /// Live connected accounts in [workspaceId].
  Stream<List<CalendarAccountDto>> watchAccounts({
    required String workspaceId,
  }) => _client
      .subscribe('calendar.watchAccounts', {'workspace_id': workspaceId})
      .map(_accounts);

  /// Live calendar sources for one account in the requested workspace.
  Stream<List<CalendarSourceDto>> watchSources(
    String accountId, {
    required String workspaceId,
  }) => _client
      .subscribe('calendar.watchSources', {
        'account_id': accountId,
        'workspace_id': workspaceId,
      })
      .map(_sources);

  /// Connected accounts in [workspaceId].
  Future<List<CalendarAccountDto>> getAccounts(String workspaceId) async {
    final data = await _client.call('calendar.getAccounts', {
      'workspace_id': workspaceId,
    });
    return _accounts(data);
  }

  /// Live events overlapping `[from, to)` in [workspaceId].
  Stream<List<CalendarEventDto>> watchEventsInRange(
    DateTime from,
    DateTime to, {
    required String workspaceId,
  }) => _client
      .subscribe('calendar.watchEventsInRange', {
        'from': from.toIso8601String(),
        'to': to.toIso8601String(),
        'workspace_id': workspaceId,
      })
      .map(_events);

  /// Live single event by id in [workspaceId]; null when absent.
  Stream<CalendarEventDto?> watchEventById(
    String eventId, {
    required String workspaceId,
  }) => _client
      .subscribe('calendar.watchEventById', {
        'event_id': eventId,
        'workspace_id': workspaceId,
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
