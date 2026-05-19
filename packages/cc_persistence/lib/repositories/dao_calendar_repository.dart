import 'package:cc_domain/features/calendar/domain/entities/calendar_event.dart';
import 'package:cc_domain/features/calendar/domain/repositories/calendar_repository.dart';
import 'package:cc_persistence/database/daos/calendar_dao.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:cc_persistence/database/workspace_database_manager.dart';
import 'package:cc_persistence/mappers/calendar_event_mapper.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

/// DAO-backed [CalendarRepository]. Converts domain entities to/from Drift
/// companions via [CalendarEventMapper] and delegates to the per-workspace
/// [CalendarDao]s.
///
/// Holds the [WorkspaceDatabaseManager] and resolves
/// `_dbs.of(workspaceId).calendarDao` per call: accounts, sources and events
/// live in their workspace's own database file, so the workspace id picks the
/// file before any SQL runs.
class DaoCalendarRepository implements CalendarRepository {
  /// Creates a [DaoCalendarRepository] over the per-workspace databases.
  DaoCalendarRepository(this._dbs, {Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final WorkspaceDatabaseManager _dbs;
  final CalendarEventMapper _mapper = const CalendarEventMapper();
  final Uuid _uuid;

  CalendarDao _dao(String workspaceId) => _dbs.of(workspaceId).calendarDao;

  @override
  Future<List<CalendarAccount>> getAccounts(String workspaceId) async {
    final rows = await _dao(workspaceId).getAccounts(workspaceId);
    return rows.map(_mapper.accountToDomain).toList(growable: false);
  }

  @override
  Stream<List<CalendarAccount>> watchAccounts(String workspaceId) =>
      _dao(workspaceId)
          .watchAccounts(workspaceId)
          .map(
            (rows) => rows.map(_mapper.accountToDomain).toList(growable: false),
          );

  @override
  Stream<List<CalendarSource>> watchSources(
    String workspaceId,
    String accountId,
  ) => _dao(workspaceId)
      .watchSources(workspaceId, accountId)
      .map((rows) => rows.map(_mapper.sourceToDomain).toList(growable: false));

  @override
  Future<void> upsertSources({
    required String workspaceId,
    required String accountId,
    required List<CalendarSource> sources,
  }) {
    final now = DateTime.now();
    final companions = sources
        .map(
          (s) => CalendarSourcesTableCompanion(
            id: Value(_uuid.v4()),
            workspaceId: Value(workspaceId),
            accountId: Value(accountId),
            calendarId: Value(s.id),
            summary: Value(s.summary),
            backgroundColor: Value(s.backgroundColor),
            primary: Value(s.primary),
            writable: Value(s.writable),
            updatedAt: Value(now),
          ),
        )
        .toList(growable: false);
    return _dao(workspaceId).replaceSources(workspaceId, accountId, companions);
  }

  @override
  Future<void> upsertAccount(CalendarAccount account) {
    // The account carries its own workspace, so the file is picked from the
    // entity rather than from a parameter that could disagree with it.
    return _dao(account.workspaceId).upsertAccount(
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
  ) => _dao(workspaceId).setLastSyncedAt(workspaceId, accountId, at);

  @override
  Future<bool> markNeedsReauth(
    String workspaceId,
    String accountId,
    DateTime at,
  ) => _dao(workspaceId).markNeedsReauth(workspaceId, accountId, at);

  @override
  Future<void> deleteAccount(String workspaceId, String id) =>
      _dao(workspaceId).deleteAccount(workspaceId, id);

  @override
  Future<void> upsertEvents(List<CalendarEvent> events) async {
    // Each event names the workspace whose file it belongs in, so the batch is
    // grouped by workspace and written one file at a time. A sync pass only ever
    // hands over one workspace's events, but grouping keeps a mixed list correct
    // instead of writing every event into whichever workspace came first.
    final byWorkspace = <String, List<CalendarEventsTableCompanion>>{};
    for (final e in events) {
      byWorkspace
          .putIfAbsent(e.workspaceId, () => [])
          .add(
            CalendarEventsTableCompanion(
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
          );
    }
    for (final entry in byWorkspace.entries) {
      await _dao(entry.key).upsertEvents(entry.value);
    }
  }

  @override
  Stream<List<CalendarEvent>> watchEventsInRange(
    String workspaceId,
    DateTime from,
    DateTime to,
  ) => _dao(workspaceId)
      .watchEventsInRange(workspaceId, from, to)
      .map((rows) => rows.map(_mapper.toDomain).toList(growable: false));

  @override
  Stream<CalendarEvent?> watchEventById(String workspaceId, String eventId) =>
      _dao(workspaceId)
          .watchEventById(workspaceId, eventId)
          .map((row) => row == null ? null : _mapper.toDomain(row));

  @override
  Future<void> deleteEventsMissingFrom({
    required String workspaceId,
    required String accountId,
    required String calendarId,
    required DateTime from,
    required DateTime to,
    required Set<String> keepExternalIds,
  }) => _dao(workspaceId).deleteEventsMissingFrom(
    workspaceId: workspaceId,
    accountId: accountId,
    calendarId: calendarId,
    from: from,
    to: to,
    keepExternalIds: keepExternalIds,
  );

  @override
  Future<void> deleteEventsByExternalIds({
    required String workspaceId,
    required String accountId,
    required String calendarId,
    required Set<String> externalIds,
  }) => _dao(workspaceId).deleteEventsByExternalIds(
    workspaceId: workspaceId,
    accountId: accountId,
    calendarId: calendarId,
    externalIds: externalIds,
  );

  @override
  Future<({String token, DateTime? mintedAt})?> getSyncState(
    String workspaceId,
    String accountId,
    String calendarId,
  ) => _dao(workspaceId).getSyncState(workspaceId, accountId, calendarId);

  @override
  Future<void> setSyncState(
    String workspaceId,
    String accountId,
    String calendarId, {
    required String? token,
    required DateTime? mintedAt,
  }) => _dao(workspaceId).setSyncState(
    workspaceId,
    accountId,
    calendarId,
    token: token,
    mintedAt: mintedAt,
  );

  @override
  Future<List<CalendarEvent>> getUpcomingEventsNeedingAlert(
    String workspaceId,
    DateTime windowStart,
    DateTime windowEnd,
  ) async {
    final rows = await _dao(
      workspaceId,
    ).getUpcomingEventsNeedingAlert(workspaceId, windowStart, windowEnd);
    return rows.map(_mapper.toDomain).toList(growable: false);
  }

  @override
  Future<void> markAlerted(String workspaceId, String eventId, DateTime at) =>
      _dao(workspaceId).markAlerted(workspaceId, eventId, at);

  @override
  Future<void> linkMeetingToEvent({
    required String workspaceId,
    required String meetingId,
    required String calendarEventId,
  }) {
    return _dao(workspaceId).linkMeetingToEvent(
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
      _dao(workspaceId).unlinkMeeting(workspaceId, meetingId);

  @override
  Future<void> syncLinkedMeetingTitles(String workspaceId) =>
      _dao(workspaceId).syncLinkedMeetingTitles(workspaceId);

  @override
  Future<CalendarEvent?> getEventForMeeting(
    String workspaceId,
    String meetingId,
  ) async {
    final row = await _dao(
      workspaceId,
    ).getEventForMeeting(workspaceId, meetingId);
    return row == null ? null : _mapper.toDomain(row);
  }

  @override
  Future<String?> getMeetingIdForEvent(
    String workspaceId,
    String calendarEventId,
  ) => _dao(workspaceId).getMeetingIdForEvent(workspaceId, calendarEventId);
}
