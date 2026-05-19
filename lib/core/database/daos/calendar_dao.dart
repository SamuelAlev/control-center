import 'package:control_center/core/database/app_database.dart';
import 'package:control_center/core/database/tables/calendar_accounts.dart';
import 'package:control_center/core/database/tables/calendar_events.dart';
import 'package:control_center/core/database/tables/meeting_calendar_links.dart';
import 'package:drift/drift.dart';

part 'calendar_dao.g.dart';

@DriftAccessor(
  tables: [
    CalendarAccountsTable,
    CalendarEventsTable,
    MeetingCalendarLinksTable,
  ],
)
/// Data access for the calendar feature: connected accounts, synced events,
/// and meeting↔event links.
///
/// Every query is scoped to a `workspaceId`. The Google account is
/// per-workspace, so there is deliberately NO cross-workspace sweep here — the
/// workspace clause, not id uniqueness, is the isolation boundary.
class CalendarDao extends DatabaseAccessor<AppDatabase>
    with _$CalendarDaoMixin {
  /// Creates a [CalendarDao].
  CalendarDao(super.attachedDatabase);

  // ── Accounts ──

  /// The connected accounts for [workspaceId] (oldest first), empty when none.
  Future<List<CalendarAccountsTableData>> getAccounts(String workspaceId) =>
      (select(calendarAccountsTable)
            ..where((t) => t.workspaceId.equals(workspaceId))
            ..orderBy([(t) => OrderingTerm.asc(t.accountEmail)]))
          .get();

  /// Watches the connected accounts for [workspaceId].
  Stream<List<CalendarAccountsTableData>> watchAccounts(String workspaceId) =>
      (select(calendarAccountsTable)
            ..where((t) => t.workspaceId.equals(workspaceId))
            ..orderBy([(t) => OrderingTerm.asc(t.accountEmail)]))
          .watch();

  /// Inserts or updates an account, reusing the existing row id when one
  /// already exists for `(workspaceId, accountEmail)` — so a workspace can hold
  /// several Google accounts and reconnecting one updates it in place.
  Future<void> upsertAccount(CalendarAccountsTableCompanion account) async {
    await transaction(() async {
      final workspaceId = account.workspaceId.value;
      final accountEmail = account.accountEmail.value;
      final existing = await (select(calendarAccountsTable)
            ..where((t) =>
                t.workspaceId.equals(workspaceId) &
                t.accountEmail.equals(accountEmail)))
          .getSingleOrNull();
      if (existing == null) {
        await into(calendarAccountsTable).insert(account);
      } else {
        await (update(calendarAccountsTable)
              ..where((t) => t.id.equals(existing.id)))
            .write(account.copyWith(id: const Value.absent()));
      }
    });
  }

  /// Records the last-synced timestamp for an account and clears any
  /// [CalendarAccountsTable.authExpiredAt] flag — a successful sync proves the
  /// account's tokens are healthy again, so a stale "reconnect" banner is
  /// dismissed automatically.
  Future<void> setLastSyncedAt(
    String workspaceId,
    String accountId,
    DateTime at,
  ) =>
      (update(calendarAccountsTable)
            ..where((t) =>
                t.id.equals(accountId) & t.workspaceId.equals(workspaceId)))
          .write(CalendarAccountsTableCompanion(
            lastSyncedAt: Value(at),
            authExpiredAt: const Value(null),
          ));

  /// Flags an account as needing the user to reconnect (its OAuth refresh token
  /// is dead). Workspace-scoped: a foreign-workspace id is simply not found.
  ///
  /// Returns `true` only on the genuine null→set transition, so the caller can
  /// notify the user exactly once per disconnection episode even though the
  /// failing refresh is retried every sync. Returns `false` when the account is
  /// absent or already flagged. The compare-and-set runs inside a transaction
  /// so concurrent refreshes can't both observe a null and both notify.
  Future<bool> markNeedsReauth(
    String workspaceId,
    String accountId,
    DateTime at,
  ) async {
    return transaction(() async {
      final row = await (select(calendarAccountsTable)
            ..where((t) =>
                t.id.equals(accountId) & t.workspaceId.equals(workspaceId)))
          .getSingleOrNull();
      if (row == null || row.authExpiredAt != null) {
        return false;
      }
      await (update(calendarAccountsTable)
            ..where((t) =>
                t.id.equals(accountId) & t.workspaceId.equals(workspaceId)))
          .write(CalendarAccountsTableCompanion(authExpiredAt: Value(at)));
      return true;
    });
  }

  /// Deletes an account (cascades to its events), scoped to [workspaceId].
  Future<void> deleteAccount(String workspaceId, String id) =>
      (delete(calendarAccountsTable)..where(
            (t) => t.id.equals(id) & t.workspaceId.equals(workspaceId),
          ))
          .go();

  // ── Events ──

  /// Inserts or updates events, idempotent on `(accountId, externalEventId)`.
  ///
  /// Re-syncs update the existing row in place (reusing its id) and **preserve
  /// `alertedAt`** so a fired "starting soon" alert is never replayed. The
  /// incoming companions must therefore NOT set `id`-overriding or `alertedAt`.
  Future<void> upsertEvents(List<CalendarEventsTableCompanion> events) async {
    await transaction(() async {
      for (final event in events) {
        final accountId = event.accountId.value;
        final externalId = event.externalEventId.value;
        final existing = await (select(calendarEventsTable)
              ..where((t) =>
                  t.accountId.equals(accountId) &
                  t.externalEventId.equals(externalId)))
            .getSingleOrNull();
        if (existing == null) {
          await into(calendarEventsTable).insert(event);
        } else {
          await (update(calendarEventsTable)
                ..where((t) => t.id.equals(existing.id)))
              .write(event.copyWith(
                id: const Value.absent(),
                alertedAt: const Value.absent(),
              ));
        }
      }
    });
  }

  /// Watches events overlapping `[from, to)` in [workspaceId], earliest first.
  Stream<List<CalendarEventsTableData>> watchEventsInRange(
    String workspaceId,
    DateTime from,
    DateTime to,
  ) =>
      (select(calendarEventsTable)
            ..where((t) =>
                t.workspaceId.equals(workspaceId) &
                t.startTime.isSmallerThanValue(to) &
                t.endTime.isBiggerThanValue(from))
            ..orderBy([(t) => OrderingTerm.asc(t.startTime)]))
          .watch();

  /// Reconciles deletions for one calendar+window: deletes events in
  /// [calendarId] (on [accountId] in [workspaceId]) that overlap `[from, to)`
  /// but whose provider id is **not** in [keepExternalIds] — i.e. events the
  /// provider no longer returns for that window (deleted on the server, or moved
  /// out of range). Returns the number of rows removed.
  ///
  /// The overlap predicate mirrors [watchEventsInRange] (and Google's
  /// `timeMin`/`timeMax` semantics), and the calendar scope ensures an event one
  /// calendar owns is never removed because a *different* calendar's fetch
  /// omitted it. An empty [keepExternalIds] clears the whole calendar+window.
  Future<int> deleteEventsMissingFrom({
    required String workspaceId,
    required String accountId,
    required String calendarId,
    required DateTime from,
    required DateTime to,
    required Set<String> keepExternalIds,
  }) {
    return (delete(calendarEventsTable)
          ..where((t) {
            var predicate = t.workspaceId.equals(workspaceId) &
                t.accountId.equals(accountId) &
                t.calendarId.equals(calendarId) &
                t.startTime.isSmallerThanValue(to) &
                t.endTime.isBiggerThanValue(from);
            if (keepExternalIds.isNotEmpty) {
              predicate = predicate &
                  t.externalEventId.isNotIn(keepExternalIds.toList());
            }
            return predicate;
          }))
        .go();
  }

  /// Watches a single event by id, scoped to [workspaceId] (null when absent).
  /// Unlike [watchEventsInRange] there is no time window, so the detail panel
  /// can resolve an event no matter how far in the past it lies.
  Stream<CalendarEventsTableData?> watchEventById(
    String workspaceId,
    String eventId,
  ) =>
      (select(calendarEventsTable)
            ..where((t) =>
                t.id.equals(eventId) & t.workspaceId.equals(workspaceId)))
          .watchSingleOrNull();

  /// Timed events in [workspaceId] whose start falls in
  /// `[windowStart, windowEnd]` and which have not yet been alerted.
  Future<List<CalendarEventsTableData>> getUpcomingEventsNeedingAlert(
    String workspaceId,
    DateTime windowStart,
    DateTime windowEnd,
  ) =>
      (select(calendarEventsTable)
            ..where((t) =>
                t.workspaceId.equals(workspaceId) &
                t.isAllDay.equals(false) &
                t.alertedAt.isNull() &
                t.startTime.isBiggerOrEqualValue(windowStart) &
                t.startTime.isSmallerOrEqualValue(windowEnd))
            ..orderBy([(t) => OrderingTerm.asc(t.startTime)]))
          .get();

  /// Marks an event's "starting soon" alert as fired.
  Future<void> markAlerted(String workspaceId, String eventId, DateTime at) =>
      (update(calendarEventsTable)
            ..where((t) =>
                t.id.equals(eventId) & t.workspaceId.equals(workspaceId)))
          .write(CalendarEventsTableCompanion(alertedAt: Value(at)));

  // ── Meeting ↔ event links ──

  /// Links a meeting to its source event (1:1 per meeting; relink updates).
  Future<void> linkMeetingToEvent(
    MeetingCalendarLinksTableCompanion link,
  ) async {
    await transaction(() async {
      final meetingId = link.meetingId.value;
      final existing = await (select(meetingCalendarLinksTable)
            ..where((t) => t.meetingId.equals(meetingId)))
          .getSingleOrNull();
      if (existing == null) {
        await into(meetingCalendarLinksTable).insert(link);
      } else {
        await (update(meetingCalendarLinksTable)
              ..where((t) => t.id.equals(existing.id)))
            .write(link.copyWith(id: const Value.absent()));
      }
    });
  }

  /// Removes a meeting's calendar link, scoped to [workspaceId] (no-op when the
  /// meeting isn't linked). The meeting and event are untouched.
  Future<void> unlinkMeeting(String workspaceId, String meetingId) =>
      (delete(meetingCalendarLinksTable)..where(
            (t) =>
                t.meetingId.equals(meetingId) &
                t.workspaceId.equals(workspaceId),
          ))
          .go();

  /// Propagates linked events' titles onto their meetings within [workspaceId],
  /// for every meeting whose title is NOT user-customized (`title_is_custom =
  /// 0`) and whose linked event has a non-empty, differing title. This is the
  /// "keep in sync" half of calendar↔meeting linking: a meeting seeded from an
  /// event tracks the event's title across renames, until the user edits the
  /// title themselves (which flips `title_is_custom`). Runs after each calendar
  /// sync.
  ///
  /// A single cross-table UPDATE (the links + events tables are this DAO's; the
  /// meetings table is reached via raw SQL on the shared connection). Scoped to
  /// [workspaceId] on every clause so a foreign workspace is never touched.
  Future<void> syncLinkedMeetingTitles(String workspaceId) =>
      customStatement(
        '''
        UPDATE meetings_table
        SET title = (
          SELECT e.title
          FROM meeting_calendar_links_table l
          JOIN calendar_events_table e ON e.id = l.calendar_event_id
          WHERE l.meeting_id = meetings_table.id AND l.workspace_id = ?
        )
        WHERE workspace_id = ?
          AND title_is_custom = 0
          AND EXISTS (
            SELECT 1
            FROM meeting_calendar_links_table l
            JOIN calendar_events_table e ON e.id = l.calendar_event_id
            WHERE l.meeting_id = meetings_table.id
              AND l.workspace_id = ?
              AND e.title IS NOT NULL
              AND e.title <> ''
              AND e.title <> meetings_table.title
          )
        ''',
        [workspaceId, workspaceId, workspaceId],
      );

  /// The link for a meeting, scoped to [workspaceId].
  Future<MeetingCalendarLinksTableData?> getLinkForMeeting(
    String workspaceId,
    String meetingId,
  ) =>
      (select(meetingCalendarLinksTable)..where((t) =>
              t.meetingId.equals(meetingId) &
              t.workspaceId.equals(workspaceId)))
          .getSingleOrNull();

  /// The id of the meeting recorded for [calendarEventId], if any, scoped to
  /// [workspaceId].
  Future<String?> getMeetingIdForEvent(
    String workspaceId,
    String calendarEventId,
  ) async {
    final row = await (select(meetingCalendarLinksTable)..where((t) =>
            t.calendarEventId.equals(calendarEventId) &
            t.workspaceId.equals(workspaceId)))
        .getSingleOrNull();
    return row?.meetingId;
  }

  /// The event a meeting was recorded for, scoped to [workspaceId].
  Future<CalendarEventsTableData?> getEventForMeeting(
    String workspaceId,
    String meetingId,
  ) async {
    final link = await getLinkForMeeting(workspaceId, meetingId);
    if (link == null) {
      return null;
    }
    return (select(calendarEventsTable)..where((t) =>
            t.id.equals(link.calendarEventId) &
            t.workspaceId.equals(workspaceId)))
        .getSingleOrNull();
  }
}
