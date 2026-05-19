import 'package:control_center/core/database/app_database.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_database.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = createTestDatabase();
    // The calendar tables use real foreign keys; disable enforcement so tests
    // can insert events/links without seeding the full workspace→account→meeting
    // graph. These tests exercise workspace *filtering* and unique indexes,
    // both of which are independent of FK enforcement.
    await db.customStatement('PRAGMA foreign_keys = OFF');
  });

  tearDown(() async {
    await db.close();
  });

  CalendarEventsTableCompanion event({
    required String id,
    required String workspaceId,
    required String accountId,
    required String externalEventId,
    required DateTime start,
    DateTime? end,
    bool isAllDay = false,
    String title = 'Event',
    String calendarId = 'primary',
  }) {
    return CalendarEventsTableCompanion.insert(
      id: id,
      workspaceId: workspaceId,
      accountId: accountId,
      externalEventId: externalEventId,
      calendarId: calendarId,
      title: title,
      startTime: start,
      endTime: end ?? start.add(const Duration(minutes: 30)),
      isAllDay: Value(isAllDay),
      updatedAt: Value(start),
    );
  }

  group('CalendarDao.upsertEvents', () {
    test('is idempotent on (accountId, externalEventId)', () async {
      final t = DateTime.utc(2026, 6, 11, 10);
      await db.calendarDao.upsertEvents([
        event(
          id: 'local-1',
          workspaceId: 'ws-A',
          accountId: 'acc-A',
          externalEventId: 'ext-1',
          start: t,
          title: 'Original',
        ),
      ]);
      // Re-sync with a *different* local id but the same natural key.
      await db.calendarDao.upsertEvents([
        event(
          id: 'local-2',
          workspaceId: 'ws-A',
          accountId: 'acc-A',
          externalEventId: 'ext-1',
          start: t,
          title: 'Updated',
        ),
      ]);

      final rows = await db.calendarDao.watchEventsInRange(
        'ws-A',
        DateTime.utc(2026, 6, 1),
        DateTime.utc(2026, 7, 1),
      ).first;
      expect(rows, hasLength(1));
      expect(rows.single.id, 'local-1'); // original id preserved
      expect(rows.single.title, 'Updated'); // columns updated in place
    });

    test('preserves alertedAt across re-sync', () async {
      final t = DateTime.utc(2026, 6, 11, 10);
      await db.calendarDao.upsertEvents([
        event(
          id: 'local-1',
          workspaceId: 'ws-A',
          accountId: 'acc-A',
          externalEventId: 'ext-1',
          start: t,
        ),
      ]);
      await db.calendarDao.markAlerted('ws-A', 'local-1', DateTime.utc(2026, 6, 11, 9, 55));

      await db.calendarDao.upsertEvents([
        event(
          id: 'local-1',
          workspaceId: 'ws-A',
          accountId: 'acc-A',
          externalEventId: 'ext-1',
          start: t,
          title: 'Changed',
        ),
      ]);

      final rows = await db.calendarDao.watchEventsInRange(
        'ws-A',
        DateTime.utc(2026, 6, 1),
        DateTime.utc(2026, 7, 1),
      ).first;
      // Drift round-trips DateTimes through a UTC epoch and returns a local
      // DateTime, so compare the instant (not the object, whose isUtc differs).
      expect(rows.single.alertedAt, isNotNull);
      expect(
        rows.single.alertedAt!.isAtSameMomentAs(DateTime.utc(2026, 6, 11, 9, 55)),
        isTrue,
      );
    });
  });

  group('CalendarDao.deleteEventsMissingFrom', () {
    final winFrom = DateTime.utc(2026, 6, 1);
    final winTo = DateTime.utc(2026, 7, 1);

    test('removes events not in the keep set, retains those that are', () async {
      final t = DateTime.utc(2026, 6, 11, 10);
      await db.calendarDao.upsertEvents([
        event(id: 'keep', workspaceId: 'ws-A', accountId: 'acc-A', externalEventId: 'ext-keep', start: t),
        event(id: 'gone', workspaceId: 'ws-A', accountId: 'acc-A', externalEventId: 'ext-gone', start: t),
      ]);

      final removed = await db.calendarDao.deleteEventsMissingFrom(
        workspaceId: 'ws-A',
        accountId: 'acc-A',
        calendarId: 'primary',
        from: winFrom,
        to: winTo,
        keepExternalIds: {'ext-keep'},
      );

      expect(removed, 1);
      final rows = await db.calendarDao.watchEventsInRange('ws-A', winFrom, winTo).first;
      expect(rows.map((e) => e.externalEventId), ['ext-keep']);
    });

    test('does not touch other calendars or events outside the window', () async {
      final inWindow = DateTime.utc(2026, 6, 11, 10);
      final outOfWindow = DateTime.utc(2026, 8, 1, 10);
      await db.calendarDao.upsertEvents([
        // Same calendar, in window, absent from keep → deleted.
        event(id: 'gone', workspaceId: 'ws-A', accountId: 'acc-A', externalEventId: 'ext-gone', start: inWindow),
        // Different calendar → untouched even though absent from keep.
        event(id: 'other-cal', workspaceId: 'ws-A', accountId: 'acc-A', externalEventId: 'ext-team', start: inWindow, calendarId: 'team@group'),
        // Same calendar but outside the window → untouched.
        event(id: 'later', workspaceId: 'ws-A', accountId: 'acc-A', externalEventId: 'ext-later', start: outOfWindow),
      ]);

      final removed = await db.calendarDao.deleteEventsMissingFrom(
        workspaceId: 'ws-A',
        accountId: 'acc-A',
        calendarId: 'primary',
        from: winFrom,
        to: winTo,
        keepExternalIds: const {},
      );

      expect(removed, 1);
      final rows = await db.calendarDao
          .watchEventsInRange('ws-A', winFrom, DateTime.utc(2026, 9, 1))
          .first;
      expect(
        rows.map((e) => e.externalEventId).toSet(),
        {'ext-team', 'ext-later'},
      );
    });

    test('is workspace-scoped', () async {
      final t = DateTime.utc(2026, 6, 11, 10);
      await db.calendarDao.upsertEvents([
        event(id: 'a-1', workspaceId: 'ws-A', accountId: 'acc-A', externalEventId: 'ext-1', start: t),
        // Another workspace's event sharing the external id → must survive.
        event(id: 'b-1', workspaceId: 'ws-B', accountId: 'acc-B', externalEventId: 'ext-1', start: t),
      ]);

      await db.calendarDao.deleteEventsMissingFrom(
        workspaceId: 'ws-A',
        accountId: 'acc-A',
        calendarId: 'primary',
        from: winFrom,
        to: winTo,
        keepExternalIds: const {}, // clears everything ws-A owns in window
      );

      final bRows = await db.calendarDao.watchEventsInRange('ws-B', winFrom, winTo).first;
      expect(bRows.map((e) => e.id), ['b-1']);
    });
  });

  group('CalendarDao workspace isolation', () {
    test('watchEventsInRange never returns another workspace\'s events',
        () async {
      final t = DateTime.utc(2026, 6, 11, 10);
      await db.calendarDao.upsertEvents([
        event(
          id: 'a-1',
          workspaceId: 'ws-A',
          accountId: 'acc-A',
          externalEventId: 'ext-A',
          start: t,
        ),
        event(
          id: 'b-1',
          workspaceId: 'ws-B',
          accountId: 'acc-B',
          externalEventId: 'ext-B',
          start: t,
        ),
      ]);

      final aRows = await db.calendarDao.watchEventsInRange(
        'ws-A',
        DateTime.utc(2026, 6, 1),
        DateTime.utc(2026, 7, 1),
      ).first;
      expect(aRows.map((e) => e.id), ['a-1']);
    });

    test('getUpcomingEventsNeedingAlert is workspace-scoped', () async {
      final t = DateTime.utc(2026, 6, 11, 10);
      await db.calendarDao.upsertEvents([
        event(id: 'a-1', workspaceId: 'ws-A', accountId: 'acc-A', externalEventId: 'x', start: t),
        event(id: 'b-1', workspaceId: 'ws-B', accountId: 'acc-B', externalEventId: 'y', start: t),
      ]);
      final due = await db.calendarDao.getUpcomingEventsNeedingAlert(
        'ws-A',
        DateTime.utc(2026, 6, 11, 9),
        DateTime.utc(2026, 6, 11, 11),
      );
      expect(due.map((e) => e.id), ['a-1']);
    });

    test('getEventForMeeting is workspace-scoped', () async {
      final t = DateTime.utc(2026, 6, 11, 10);
      await db.calendarDao.upsertEvents([
        event(id: 'e-A', workspaceId: 'ws-A', accountId: 'acc-A', externalEventId: 'x', start: t),
      ]);
      await db.calendarDao.linkMeetingToEvent(
        MeetingCalendarLinksTableCompanion.insert(
          id: 'link-1',
          workspaceId: 'ws-A',
          meetingId: 'm-A',
          calendarEventId: 'e-A',
        ),
      );
      expect(
        (await db.calendarDao.getEventForMeeting('ws-A', 'm-A'))?.id,
        'e-A',
      );
      // Same meeting id, wrong workspace → not found.
      expect(await db.calendarDao.getEventForMeeting('ws-B', 'm-A'), isNull);
    });
  });

  group('CalendarDao.getUpcomingEventsNeedingAlert', () {
    test('filters by window, alertedAt null, and excludes all-day', () async {
      await db.calendarDao.upsertEvents([
        // In window.
        event(id: 'in', workspaceId: 'ws-A', accountId: 'acc-A', externalEventId: '1', start: DateTime.utc(2026, 6, 11, 10)),
        // Out of window.
        event(id: 'out', workspaceId: 'ws-A', accountId: 'acc-A', externalEventId: '2', start: DateTime.utc(2026, 6, 11, 23)),
        // All-day in window — excluded.
        event(id: 'allday', workspaceId: 'ws-A', accountId: 'acc-A', externalEventId: '3', start: DateTime.utc(2026, 6, 11, 10), isAllDay: true),
      ]);
      final due = await db.calendarDao.getUpcomingEventsNeedingAlert(
        'ws-A',
        DateTime.utc(2026, 6, 11, 9, 30),
        DateTime.utc(2026, 6, 11, 10, 30),
      );
      expect(due.map((e) => e.id), ['in']);
    });

    test('markAlerted excludes the row on the next query', () async {
      await db.calendarDao.upsertEvents([
        event(id: 'in', workspaceId: 'ws-A', accountId: 'acc-A', externalEventId: '1', start: DateTime.utc(2026, 6, 11, 10)),
      ]);
      await db.calendarDao.markAlerted('ws-A', 'in', DateTime.utc(2026, 6, 11, 9, 55));
      final due = await db.calendarDao.getUpcomingEventsNeedingAlert(
        'ws-A',
        DateTime.utc(2026, 6, 11, 9, 30),
        DateTime.utc(2026, 6, 11, 10, 30),
      );
      expect(due, isEmpty);
    });
  });

  group('CalendarDao accounts + links', () {
    test('upsertAccount updates in place per (workspace, email)', () async {
      await db.calendarDao.upsertAccount(
        CalendarAccountsTableCompanion.insert(
          id: 'acc-1',
          workspaceId: 'ws-A',
          accountEmail: 'a@x.com',
          displayName: const Value('First'),
        ),
      );
      await db.calendarDao.upsertAccount(
        CalendarAccountsTableCompanion.insert(
          id: 'acc-1b', // different id, same workspace + email
          workspaceId: 'ws-A',
          accountEmail: 'a@x.com',
          displayName: const Value('Renamed'),
        ),
      );
      final accounts = await db.calendarDao.getAccounts('ws-A');
      expect(accounts, hasLength(1));
      expect(accounts.single.displayName, 'Renamed'); // updated in place
    });

    test('upsertAccount allows several accounts per workspace', () async {
      await db.calendarDao.upsertAccount(
        CalendarAccountsTableCompanion.insert(
          id: 'acc-1',
          workspaceId: 'ws-A',
          accountEmail: 'a@x.com',
        ),
      );
      await db.calendarDao.upsertAccount(
        CalendarAccountsTableCompanion.insert(
          id: 'acc-2',
          workspaceId: 'ws-A',
          accountEmail: 'b@x.com',
        ),
      );
      final accounts = await db.calendarDao.getAccounts('ws-A');
      expect(accounts, hasLength(2));
      expect(
        accounts.map((a) => a.accountEmail).toSet(),
        {'a@x.com', 'b@x.com'},
      );
    });

    test('linkMeetingToEvent relinking the same meeting updates in place',
        () async {
      await db.calendarDao.linkMeetingToEvent(
        MeetingCalendarLinksTableCompanion.insert(
          id: 'l-1',
          workspaceId: 'ws-A',
          meetingId: 'm-1',
          calendarEventId: 'e-1',
        ),
      );
      await db.calendarDao.linkMeetingToEvent(
        MeetingCalendarLinksTableCompanion.insert(
          id: 'l-2',
          workspaceId: 'ws-A',
          meetingId: 'm-1', // same meeting
          calendarEventId: 'e-2',
        ),
      );
      final link = await db.calendarDao.getLinkForMeeting('ws-A', 'm-1');
      expect(link!.calendarEventId, 'e-2');
      final all = await db.select(db.meetingCalendarLinksTable).get();
      expect(all, hasLength(1));
    });
  });

  group('CalendarDao.markNeedsReauth', () {
    final at = DateTime.utc(2026, 6, 11, 9);

    Future<void> seedAccount(String workspaceId, String id) =>
        db.calendarDao.upsertAccount(
          CalendarAccountsTableCompanion.insert(
            id: id,
            workspaceId: workspaceId,
            accountEmail: '$id@x.com',
          ),
        );

    Future<DateTime?> flagOf(String workspaceId, String id) async {
      final accounts = await db.calendarDao.getAccounts(workspaceId);
      return accounts.firstWhere((a) => a.id == id).authExpiredAt;
    }

    test('returns true on the null→set transition, false when already set',
        () async {
      await seedAccount('ws-A', 'acc-A');

      expect(await db.calendarDao.markNeedsReauth('ws-A', 'acc-A', at), isTrue);
      // drift returns the stored instant as a local DateTime, so compare the
      // moment rather than the (utc-vs-local) object.
      expect((await flagOf('ws-A', 'acc-A'))!.isAtSameMomentAs(at), isTrue);
      // Second call is the dedup boundary: already flagged → no transition.
      expect(await db.calendarDao.markNeedsReauth('ws-A', 'acc-A', at), isFalse);
    });

    test('is a no-op for a foreign workspace (isolation)', () async {
      await seedAccount('ws-A', 'acc-A');
      // Same account id, wrong workspace → not found → false, flag untouched.
      expect(await db.calendarDao.markNeedsReauth('ws-B', 'acc-A', at), isFalse);
      expect(await flagOf('ws-A', 'acc-A'), isNull);
    });

    test('returns false for an absent account', () async {
      expect(
        await db.calendarDao.markNeedsReauth('ws-A', 'nope', at),
        isFalse,
      );
    });

    test('setLastSyncedAt clears the flag (successful sync = healthy)',
        () async {
      await seedAccount('ws-A', 'acc-A');
      await db.calendarDao.markNeedsReauth('ws-A', 'acc-A', at);
      expect(await flagOf('ws-A', 'acc-A'), isNotNull);

      await db.calendarDao.setLastSyncedAt('ws-A', 'acc-A', at);
      expect(await flagOf('ws-A', 'acc-A'), isNull);
      // And the flag can be re-set afterwards (true transition again).
      expect(await db.calendarDao.markNeedsReauth('ws-A', 'acc-A', at), isTrue);
    });
  });

  group('CalendarDao.syncLinkedMeetingTitles', () {
    final t = DateTime.utc(2026, 6, 11, 10);

    Future<void> insertMeeting({
      required String id,
      required String workspaceId,
      required String title,
      bool titleIsCustom = false,
    }) =>
        db.meetingDao.upsertMeeting(
          MeetingsTableCompanion.insert(
            id: id,
            workspaceId: workspaceId,
            title: title,
            titleIsCustom: Value(titleIsCustom),
            startedAt: Value(t),
            createdAt: Value(t),
            updatedAt: Value(t),
          ),
        );

    Future<void> link(String ws, String meetingId, String eventId) =>
        db.calendarDao.linkMeetingToEvent(
          MeetingCalendarLinksTableCompanion.insert(
            id: 'link-$meetingId',
            workspaceId: ws,
            meetingId: meetingId,
            calendarEventId: eventId,
          ),
        );

    Future<String> titleOf(String ws, String id) async =>
        (await db.meetingDao.getById(ws, id))!.title;

    test('adopts the event title for a non-custom linked meeting', () async {
      await db.calendarDao.upsertEvents([
        event(
          id: 'e1',
          workspaceId: 'ws-A',
          accountId: 'acc-A',
          externalEventId: 'x1',
          start: t,
          title: 'Sprint planning',
        ),
      ]);
      await insertMeeting(
        id: 'm1',
        workspaceId: 'ws-A',
        title: 'Meeting 2026-06-11 10:00',
      );
      await link('ws-A', 'm1', 'e1');

      await db.calendarDao.syncLinkedMeetingTitles('ws-A');

      expect(await titleOf('ws-A', 'm1'), 'Sprint planning');
    });

    test('leaves a user-customized title untouched', () async {
      await db.calendarDao.upsertEvents([
        event(
          id: 'e1',
          workspaceId: 'ws-A',
          accountId: 'acc-A',
          externalEventId: 'x1',
          start: t,
          title: 'Sprint planning',
        ),
      ]);
      await insertMeeting(
        id: 'm1',
        workspaceId: 'ws-A',
        title: 'My own title',
        titleIsCustom: true,
      );
      await link('ws-A', 'm1', 'e1');

      await db.calendarDao.syncLinkedMeetingTitles('ws-A');

      expect(await titleOf('ws-A', 'm1'), 'My own title');
    });

    test('leaves an unlinked meeting untouched', () async {
      await insertMeeting(
        id: 'm1',
        workspaceId: 'ws-A',
        title: 'Meeting 2026-06-11 10:00',
      );

      await db.calendarDao.syncLinkedMeetingTitles('ws-A');

      expect(await titleOf('ws-A', 'm1'), 'Meeting 2026-06-11 10:00');
    });

    test('is workspace-scoped (a foreign workspace is never touched)', () async {
      await db.calendarDao.upsertEvents([
        event(
          id: 'e1',
          workspaceId: 'ws-B',
          accountId: 'acc-B',
          externalEventId: 'x1',
          start: t,
          title: 'B event',
        ),
      ]);
      await insertMeeting(
        id: 'm1',
        workspaceId: 'ws-B',
        title: 'Meeting 2026-06-11 10:00',
      );
      await link('ws-B', 'm1', 'e1');

      // Sync a DIFFERENT workspace; ws-B's meeting must be left alone.
      await db.calendarDao.syncLinkedMeetingTitles('ws-A');

      expect(await titleOf('ws-B', 'm1'), 'Meeting 2026-06-11 10:00');
    });
  });

  group('CalendarDao.unlinkMeeting', () {
    test('removes the link', () async {
      await db.calendarDao.upsertEvents([
        event(
          id: 'e1',
          workspaceId: 'ws-A',
          accountId: 'acc-A',
          externalEventId: 'x1',
          start: DateTime.utc(2026, 6, 11, 10),
        ),
      ]);
      await db.calendarDao.linkMeetingToEvent(
        MeetingCalendarLinksTableCompanion.insert(
          id: 'l1',
          workspaceId: 'ws-A',
          meetingId: 'm1',
          calendarEventId: 'e1',
        ),
      );
      expect(await db.calendarDao.getMeetingIdForEvent('ws-A', 'e1'), 'm1');

      await db.calendarDao.unlinkMeeting('ws-A', 'm1');

      expect(await db.calendarDao.getMeetingIdForEvent('ws-A', 'e1'), isNull);
    });
  });
}
