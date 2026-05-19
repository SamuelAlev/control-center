import 'package:control_center/core/database/app_database.dart';
import 'package:control_center/core/database/daos/calendar_dao.dart';
import 'package:control_center/features/calendar/data/mappers/calendar_event_mapper.dart';
import 'package:control_center/features/calendar/domain/entities/calendar_event.dart';
import 'package:control_center/features/calendar/domain/repositories/calendar_repository.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

/// DAO-backed [CalendarRepository]. Converts domain entities to/from Drift
/// companions via [CalendarEventMapper] and delegates to [CalendarDao].
class DaoCalendarRepository implements CalendarRepository {
  /// Creates a [DaoCalendarRepository].
  DaoCalendarRepository(this._dao, {Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final CalendarDao _dao;
  final CalendarEventMapper _mapper = const CalendarEventMapper();
  final Uuid _uuid;

  @override
  Future<List<CalendarAccount>> getAccounts(String workspaceId) async {
    final rows = await _dao.getAccounts(workspaceId);
    return rows.map(_mapper.accountToDomain).toList(growable: false);
  }

  @override
  Stream<List<CalendarAccount>> watchAccounts(String workspaceId) =>
      _dao.watchAccounts(workspaceId).map(
            (rows) => rows.map(_mapper.accountToDomain).toList(growable: false),
          );

  @override
  Future<void> upsertAccount(CalendarAccount account) {
    return _dao.upsertAccount(
      CalendarAccountsTableCompanion(
        id: Value(account.id),
        workspaceId: Value(account.workspaceId),
        providerId: Value(account.providerId),
        accountEmail: Value(account.accountEmail),
        displayName: Value(account.displayName),
        lastSyncedAt: Value(account.lastSyncedAt),
        // Reconnect passes a default (null) entity, so this overwrites any
        // stale "needs reauth" flag on the existing row — fresh tokens, clean
        // slate.
        authExpiredAt: Value(account.authExpiredAt),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> setLastSyncedAt(
    String workspaceId,
    String accountId,
    DateTime at,
  ) =>
      _dao.setLastSyncedAt(workspaceId, accountId, at);

  @override
  Future<bool> markNeedsReauth(
    String workspaceId,
    String accountId,
    DateTime at,
  ) =>
      _dao.markNeedsReauth(workspaceId, accountId, at);

  @override
  Future<void> deleteAccount(String workspaceId, String id) =>
      _dao.deleteAccount(workspaceId, id);

  @override
  Future<void> upsertEvents(List<CalendarEvent> events) {
    final companions = events
        .map(
          (e) => CalendarEventsTableCompanion(
            id: Value(e.id),
            workspaceId: Value(e.workspaceId),
            accountId: Value(e.accountId),
            externalEventId: Value(e.externalEventId),
            calendarId: Value(e.calendarId),
            title: Value(e.title),
            description: Value(e.description),
            location: Value(e.location),
            startTime: Value(e.startTime),
            endTime: Value(e.endTime),
            isAllDay: Value(e.isAllDay),
            attendeesJson: Value(_mapper.encodeAttendees(e.attendees)),
            meetingUrl: Value(e.meetingUrl),
            status: Value(e.status.toStorage()),
            recurringEventId: Value(e.recurringEventId),
            // alertedAt intentionally absent — preserved across re-syncs.
            updatedAt: Value(e.updatedAt),
          ),
        )
        .toList(growable: false);
    return _dao.upsertEvents(companions);
  }

  @override
  Stream<List<CalendarEvent>> watchEventsInRange(
    String workspaceId,
    DateTime from,
    DateTime to,
  ) =>
      _dao.watchEventsInRange(workspaceId, from, to).map(
            (rows) => rows.map(_mapper.toDomain).toList(growable: false),
          );

  @override
  Stream<CalendarEvent?> watchEventById(String workspaceId, String eventId) =>
      _dao.watchEventById(workspaceId, eventId).map(
            (row) => row == null ? null : _mapper.toDomain(row),
          );

  @override
  Future<void> deleteEventsMissingFrom({
    required String workspaceId,
    required String accountId,
    required String calendarId,
    required DateTime from,
    required DateTime to,
    required Set<String> keepExternalIds,
  }) =>
      _dao.deleteEventsMissingFrom(
        workspaceId: workspaceId,
        accountId: accountId,
        calendarId: calendarId,
        from: from,
        to: to,
        keepExternalIds: keepExternalIds,
      );

  @override
  Future<List<CalendarEvent>> getUpcomingEventsNeedingAlert(
    String workspaceId,
    DateTime windowStart,
    DateTime windowEnd,
  ) async {
    final rows = await _dao.getUpcomingEventsNeedingAlert(
      workspaceId,
      windowStart,
      windowEnd,
    );
    return rows.map(_mapper.toDomain).toList(growable: false);
  }

  @override
  Future<void> markAlerted(String workspaceId, String eventId, DateTime at) =>
      _dao.markAlerted(workspaceId, eventId, at);

  @override
  Future<void> linkMeetingToEvent({
    required String workspaceId,
    required String meetingId,
    required String calendarEventId,
  }) {
    return _dao.linkMeetingToEvent(
      MeetingCalendarLinksTableCompanion(
        id: Value(_uuid.v4()),
        workspaceId: Value(workspaceId),
        meetingId: Value(meetingId),
        calendarEventId: Value(calendarEventId),
      ),
    );
  }

  @override
  Future<void> unlinkMeeting(String workspaceId, String meetingId) =>
      _dao.unlinkMeeting(workspaceId, meetingId);

  @override
  Future<void> syncLinkedMeetingTitles(String workspaceId) =>
      _dao.syncLinkedMeetingTitles(workspaceId);

  @override
  Future<CalendarEvent?> getEventForMeeting(
    String workspaceId,
    String meetingId,
  ) async {
    final row = await _dao.getEventForMeeting(workspaceId, meetingId);
    return row == null ? null : _mapper.toDomain(row);
  }

  @override
  Future<String?> getMeetingIdForEvent(
    String workspaceId,
    String calendarEventId,
  ) =>
      _dao.getMeetingIdForEvent(workspaceId, calendarEventId);
}
