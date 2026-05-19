import 'package:cc_data/src/repositories/remote_calendar_repository.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/calendar/domain/entities/calendar_event.dart';
import 'package:cc_domain/features/calendar/domain/repositories/calendar_repository.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// A [CalendarRepository] backed by the RPC client — the thin-client data path.
///
/// Implements the domain interface over the host's `calendar.*` ops + the
/// `calendar.watch*` subscriptions, mapping the [CalendarEventDto] /
/// [CalendarAccountDto] wire shapes back to [CalendarEvent] / [CalendarAccount].
/// The host is the single source of truth and owns all persistence; this client
/// never touches a database.
///
/// Every read method takes a leading `workspaceId` (the workspace-isolation
/// contract), but it is NOT sent over the wire: the host injects the
/// authoritative bound workspace per session (`session/set_workspace`) and
/// scopes every query by it, so the client's `workspaceId` arg is validated
/// server-side via the session binding.
///
/// The WRITE surface — account connect/disconnect ([upsertAccount] /
/// [deleteAccount]), the RSVP write ([upsertEvents]), the sync reconciler
/// ([setLastSyncedAt] / [markNeedsReauth] / [deleteEventsMissingFrom] /
/// [syncLinkedMeetingTitles]), the alert sweep ([getUpcomingEventsNeedingAlert]
/// / [markAlerted]), and meeting linking ([linkMeetingToEvent] / [unlinkMeeting])
/// — all depend on the host-resident OAuth tokens + Google API client, so they
/// run host-side and throw [UnsupportedError] (never reached from a thin client).
class RpcCalendarRepository implements CalendarRepository {
  /// Creates an [RpcCalendarRepository] over [client].
  RpcCalendarRepository(RemoteRpcClient client)
    : _remote = RemoteCalendarRepository(client);

  final RemoteCalendarRepository _remote;

  static DateTime _parse(String? iso) => iso == null || iso.isEmpty
      ? DateTime.fromMillisecondsSinceEpoch(0)
      : DateTime.parse(iso);

  static DateTime? _parseNullable(String? iso) =>
      iso == null || iso.isEmpty ? null : DateTime.parse(iso);

  static CalendarAttendee _attendeeFromDto(CalendarAttendeeDto d) =>
      CalendarAttendee(
        email: d.email,
        displayName: d.displayName,
        responseStatus: d.responseStatus,
        self: d.self,
        organizer: d.organizer,
      );

  /// Rebuilds a [CalendarEvent], filling its [CalendarEvent.workspaceId] from the
  /// caller-supplied [workspaceId] (the host validated it via the session
  /// binding; the wire shape omits it).
  static CalendarEvent _eventFromDto(String workspaceId, CalendarEventDto d) =>
      CalendarEvent(
        id: d.id,
        workspaceId: workspaceId,
        accountId: d.accountId,
        externalEventId: d.externalEventId,
        calendarId: d.calendarId,
        title: d.title,
        description: d.description,
        location: d.location,
        startTime: _parse(d.startTime),
        endTime: _parse(d.endTime),
        isAllDay: d.isAllDay,
        attendees: d.attendees.map(_attendeeFromDto).toList(),
        meetingUrl: d.meetingUrl,
        status: CalendarEventStatus.fromStorage(d.status),
        recurringEventId: d.recurringEventId,
        alertedAt: _parseNullable(d.alertedAt),
        updatedAt: _parse(d.updatedAt),
      );

  static CalendarAccount _accountFromDto(
    String workspaceId,
    CalendarAccountDto d,
  ) => CalendarAccount(
    id: d.id,
    workspaceId: workspaceId,
    providerId: d.providerId,
    accountEmail: d.accountEmail,
    displayName: d.displayName,
    lastSyncedAt: _parseNullable(d.lastSyncedAt),
    authExpiredAt: _parseNullable(d.authExpiredAt),
  );

  static CalendarSource _sourceFromDto(
    String workspaceId,
    CalendarSourceDto d,
  ) => CalendarSource(
    workspaceId: workspaceId,
    accountId: d.accountId,
    id: d.id,
    summary: d.summary,
    backgroundColor: d.backgroundColor,
    primary: d.primary,
    writable: d.writable,
  );

  // ---- Reads & watches (served over RPC) ----

  @override
  Future<List<CalendarAccount>> getAccounts(String workspaceId) async {
    final dtos = await _remote.getAccounts();
    return dtos.map((d) => _accountFromDto(workspaceId, d)).toList();
  }

  @override
  Stream<List<CalendarAccount>> watchAccounts(String workspaceId) => _remote
      .watchAccounts()
      .map((list) => list.map((d) => _accountFromDto(workspaceId, d)).toList());

  @override
  Stream<List<CalendarSource>> watchSources(
    String workspaceId,
    String accountId,
  ) => _remote
      .watchSources(accountId)
      .map((list) => list.map((d) => _sourceFromDto(workspaceId, d)).toList());

  @override
  Stream<List<CalendarEvent>> watchEventsInRange(
    String workspaceId,
    DateTime from,
    DateTime to,
  ) => _remote
      .watchEventsInRange(from, to)
      .map((list) => list.map((d) => _eventFromDto(workspaceId, d)).toList());

  @override
  Stream<CalendarEvent?> watchEventById(String workspaceId, String eventId) =>
      _remote
          .watchEventById(eventId)
          .map((d) => d == null ? null : _eventFromDto(workspaceId, d));

  @override
  Future<CalendarEvent?> getEventForMeeting(
    String workspaceId,
    String meetingId,
  ) async {
    final dto = await _remote.getEventForMeeting(meetingId);
    return dto == null ? null : _eventFromDto(workspaceId, dto);
  }

  @override
  Future<String?> getMeetingIdForEvent(
    String workspaceId,
    String calendarEventId,
  ) => _remote.getMeetingIdForEvent(calendarEventId);

  // ---- Host-owned surface: account connect/disconnect, RSVP, the sync
  // reconciler (incl. calendar-source persistence), the alert sweep, and
  // meeting linking all depend on the host-resident OAuth tokens + Google API
  // client, so they never reach a thin client. ----

  @override
  Future<void> upsertAccount(CalendarAccount account) =>
      throw UnsupportedError('calendar account writes are host-side only');

  @override
  Future<void> upsertSources({
    required String workspaceId,
    required String accountId,
    required List<CalendarSource> sources,
  }) => throw UnsupportedError('calendar sync runs host-side only');

  @override
  Future<void> setLastSyncedAt(
    String workspaceId,
    String accountId,
    DateTime at,
  ) => throw UnsupportedError('calendar sync runs host-side only');

  @override
  Future<bool> markNeedsReauth(
    String workspaceId,
    String accountId,
    DateTime at,
  ) => throw UnsupportedError('calendar sync runs host-side only');

  @override
  Future<void> deleteAccount(String workspaceId, String id) =>
      throw UnsupportedError('calendar account writes are host-side only');

  @override
  Future<void> upsertEvents(List<CalendarEvent> events) =>
      throw UnsupportedError('calendar event writes are host-side only');

  @override
  Future<void> deleteEventsMissingFrom({
    required String workspaceId,
    required String accountId,
    required String calendarId,
    required DateTime from,
    required DateTime to,
    required Set<String> keepExternalIds,
  }) => throw UnsupportedError('calendar sync runs host-side only');

  @override
  Future<List<CalendarEvent>> getUpcomingEventsNeedingAlert(
    String workspaceId,
    DateTime windowStart,
    DateTime windowEnd,
  ) => throw UnsupportedError('calendar alerts run host-side only');

  @override
  Future<void> markAlerted(String workspaceId, String eventId, DateTime at) =>
      throw UnsupportedError('calendar alerts run host-side only');

  @override
  Future<void> linkMeetingToEvent({
    required String workspaceId,
    required String meetingId,
    required String calendarEventId,
  }) => _remote.linkMeetingToEvent(
    meetingId: meetingId,
    calendarEventId: calendarEventId,
  );

  @override
  Future<void> unlinkMeeting(String workspaceId, String meetingId) =>
      _remote.unlinkMeeting(meetingId);

  @override
  Future<void> syncLinkedMeetingTitles(String workspaceId) =>
      throw UnsupportedError('calendar sync runs host-side only');
}
