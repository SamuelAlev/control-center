import 'package:cc_domain/features/calendar/domain/entities/calendar_event.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:test/test.dart';

import 'helpers/test_database.dart';

/// Exercises [DaoCalendarRepository] against the real Drift database. The
/// repository is a thin mapper+delegate layer over the calendar DAO; these
/// tests assert the round-trip through the domain entities for accounts,
/// sources, events, alerts, and meeting links — plus workspace scoping.
void main() {
  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;
  late DaoCalendarRepository repo;

  setUp(() async {
    global = createTestGlobalDatabase();
    dbs = createTestWorkspaceDatabases(global: global);
    await seedTestWorkspace(global, dbs, 'w-1');
    await seedTestWorkspace(global, dbs, 'w-2');
    repo = DaoCalendarRepository(dbs);
    // The calendar tables FK-reference workspaces; seed two for isolation tests.
  });

  tearDown(() async {
    await dbs.closeAll();
    await global.close();
  });

  CalendarAccount account(
    String id,
    String ws, {
    String email = 'ada@example.com',
    String providerId = 'google',
    String? displayName,
    DateTime? lastSyncedAt,
    DateTime? authExpiredAt,
  }) => CalendarAccount(
    id: id,
    workspaceId: ws,
    providerId: providerId,
    accountEmail: email,
    displayName: displayName,
    lastSyncedAt: lastSyncedAt,
    authExpiredAt: authExpiredAt,
  );

  group('DaoCalendarRepository accounts', () {
    test('upsertAccount + getAccounts round-trips the entity', () async {
      await repo.upsertAccount(
        account('acc-1', 'w-1', email: 'ada@example.com', displayName: 'Ada'),
      );
      final rows = await repo.getAccounts('w-1');
      expect(rows.single.id, 'acc-1');
      expect(rows.single.accountEmail, 'ada@example.com');
      expect(rows.single.displayName, 'Ada');
    });

    test('getAccounts is workspace-scoped', () async {
      await repo.upsertAccount(account('acc-1', 'w-1'));
      await repo.upsertAccount(account('acc-2', 'w-2'));
      expect((await repo.getAccounts('w-1')).single.id, 'acc-1');
      expect((await repo.getAccounts('w-2')).single.id, 'acc-2');
    });

    test('upsertAccount replaces on the same id', () async {
      await repo.upsertAccount(account('acc-1', 'w-1', displayName: 'Old'));
      await repo.upsertAccount(account('acc-1', 'w-1', displayName: 'New'));
      expect((await repo.getAccounts('w-1')).single.displayName, 'New');
    });

    test('watchAccounts emits only the workspace rows', () async {
      await repo.upsertAccount(account('acc-1', 'w-1'));
      await repo.upsertAccount(account('acc-2', 'w-2'));
      expect((await repo.watchAccounts('w-1').first).single.id, 'acc-1');
    });

    test('setLastSyncedAt stamps the sync time', () async {
      final at = DateTime.utc(2026, 7, 1, 9);
      await repo.upsertAccount(account('acc-1', 'w-1'));
      await repo.setLastSyncedAt('w-1', 'acc-1', at);
      final rows = await repo.getAccounts('w-1');
      expect(rows.single.lastSyncedAt!.toUtc(), at.toUtc());
    });

    test('markNeedsReauth sets authExpiredAt and returns true', () async {
      final at = DateTime.utc(2026, 7, 1, 9);
      await repo.upsertAccount(account('acc-1', 'w-1'));
      final ok = await repo.markNeedsReauth('w-1', 'acc-1', at);
      expect(ok, isTrue);
      final rows = await repo.getAccounts('w-1');
      expect(rows.single.authExpiredAt!.toUtc(), at.toUtc());
    });

    test('deleteAccount removes the row', () async {
      await repo.upsertAccount(account('acc-1', 'w-1'));
      await repo.deleteAccount('w-1', 'acc-1');
      expect(await repo.getAccounts('w-1'), isEmpty);
    });
  });

  group('DaoCalendarRepository sources', () {
    test('upsertSources + watchSources round-trips the entity', () async {
      await repo.upsertAccount(account('acc-1', 'w-1'));
      await repo.upsertSources(
        workspaceId: 'w-1',
        accountId: 'acc-1',
        sources: [
          const CalendarSource(
            workspaceId: 'w-1',
            accountId: 'acc-1',
            id: 'primary',
            summary: 'Primary',
            backgroundColor: '#ff0000',
            primary: true,
            writable: true,
          ),
        ],
      );
      final rows = await repo.watchSources('w-1', 'acc-1').first;
      expect(rows.single.id, 'primary');
      expect(rows.single.summary, 'Primary');
      expect(rows.single.primary, isTrue);
      expect(rows.single.writable, isTrue);
    });

    test('upsertSources replaces the whole set atomically', () async {
      await repo.upsertAccount(account('acc-1', 'w-1'));
      await repo.upsertSources(
        workspaceId: 'w-1',
        accountId: 'acc-1',
        sources: [
          const CalendarSource(
            workspaceId: 'w-1',
            accountId: 'acc-1',
            id: 'a',
            summary: 'A',
          ),
        ],
      );
      await repo.upsertSources(
        workspaceId: 'w-1',
        accountId: 'acc-1',
        sources: [
          const CalendarSource(
            workspaceId: 'w-1',
            accountId: 'acc-1',
            id: 'b',
            summary: 'B',
          ),
          const CalendarSource(
            workspaceId: 'w-1',
            accountId: 'acc-1',
            id: 'c',
            summary: 'C',
          ),
        ],
      );
      final rows = await repo.watchSources('w-1', 'acc-1').first;
      expect(rows.map((s) => s.id).toSet(), {'b', 'c'});
    });
  });

  group('DaoCalendarRepository events', () {
    // Events FK-reference accounts; seed one per workspace before each test.
    // Account id is the PK, so use distinct ids across workspaces.
    setUp(() async {
      await repo.upsertAccount(account('acc-1', 'w-1'));
      await repo.upsertAccount(account('acc-2', 'w-2'));
    });

    final start = DateTime.utc(2026, 6, 11, 10);
    final end = start.add(const Duration(minutes: 30));

    CalendarEvent event(
      String id,
      String ws, {
      String accountId = 'acc-1',
      String externalEventId = 'ext-1',
      String title = 'Event',
      List<CalendarAttendee> attendees = const [],
      CalendarEventStatus status = CalendarEventStatus.confirmed,
    }) => CalendarEvent(
      id: id,
      workspaceId: ws,
      accountId: accountId,
      externalEventId: externalEventId,
      calendarId: 'primary',
      title: title,
      startTime: start,
      endTime: end,
      status: status,
      attendees: attendees,
      updatedAt: start,
    );

    test('upsertEvents + watchEventsInRange round-trips the entity', () async {
      await repo.upsertEvents([
        event(
          'e-1',
          'w-1',
          title: 'Standup',
          attendees: const [CalendarAttendee(email: 'a@x.com', self: true)],
        ),
      ]);
      final rows = await repo
          .watchEventsInRange(
            'w-1',
            DateTime.utc(2026, 6, 1),
            DateTime.utc(2026, 7, 1),
          )
          .first;
      expect(rows.single.title, 'Standup');
      expect(rows.single.attendees.single.email, 'a@x.com');
    });

    test(
      'upsertEvents is idempotent on (accountId, externalEventId)',
      () async {
        await repo.upsertEvents([event('local-1', 'w-1', title: 'Old')]);
        await repo.upsertEvents([event('local-2', 'w-1', title: 'New')]);
        final rows = await repo
            .watchEventsInRange(
              'w-1',
              DateTime.utc(2026, 6, 1),
              DateTime.utc(2026, 7, 1),
            )
            .first;
        expect(rows, hasLength(1));
        expect(rows.single.id, 'local-1');
        expect(rows.single.title, 'New');
      },
    );

    test('watchEventsInRange is workspace-scoped', () async {
      await repo.upsertEvents([event('e-1', 'w-1')]);
      await repo.upsertEvents([event('e-2', 'w-2', accountId: 'acc-2')]);
      final inOne = await repo
          .watchEventsInRange(
            'w-1',
            DateTime.utc(2026, 6, 1),
            DateTime.utc(2026, 7, 1),
          )
          .first;
      final inTwo = await repo
          .watchEventsInRange(
            'w-2',
            DateTime.utc(2026, 6, 1),
            DateTime.utc(2026, 7, 1),
          )
          .first;
      expect(inOne.single.id, 'e-1');
      expect(inTwo.single.id, 'e-2');
    });

    test('watchEventById emits the single event', () async {
      await repo.upsertEvents([event('e-1', 'w-1')]);
      final row = await repo.watchEventById('w-1', 'e-1').first;
      expect(row, isNotNull);
      expect(row!.id, 'e-1');
    });

    test('deleteEventsMissingFrom clobbers gone external ids', () async {
      await repo.upsertEvents([
        event('e-1', 'w-1', externalEventId: 'keep'),
        event('e-2', 'w-1', externalEventId: 'drop'),
      ]);
      await repo.deleteEventsMissingFrom(
        workspaceId: 'w-1',
        accountId: 'acc-1',
        calendarId: 'primary',
        from: DateTime.utc(2026, 6, 1),
        to: DateTime.utc(2026, 7, 1),
        keepExternalIds: const {'keep'},
      );
      final rows = await repo
          .watchEventsInRange(
            'w-1',
            DateTime.utc(2026, 6, 1),
            DateTime.utc(2026, 7, 1),
          )
          .first;
      expect(rows.single.externalEventId, 'keep');
    });

    test(
      'getUpcomingEventsNeedingAlert returns only unalerted events',
      () async {
        await repo.upsertEvents([event('e-1', 'w-1')]);
        final rows = await repo.getUpcomingEventsNeedingAlert(
          'w-1',
          DateTime.utc(2026, 6, 10),
          DateTime.utc(2026, 6, 12),
        );
        expect(rows.single.id, 'e-1');
      },
    );

    test('markAlerted stamps alertedAt', () async {
      final at = DateTime.utc(2026, 6, 11, 9);
      await repo.upsertEvents([event('e-1', 'w-1')]);
      await repo.markAlerted('w-1', 'e-1', at);
      // After alerting, the event is no longer "needing alert".
      final rows = await repo.getUpcomingEventsNeedingAlert(
        'w-1',
        DateTime.utc(2026, 6, 10),
        DateTime.utc(2026, 6, 12),
      );
      expect(rows, isEmpty);
    });
  });

  group('DaoCalendarRepository meeting links', () {
    final start = DateTime.utc(2026, 6, 11, 10);

    // The link table FK-references accounts, events, and meetings — seed all.
    setUp(() async {
      await repo.upsertAccount(account('acc-1', 'w-1'));
      await repo.upsertEvents([
        CalendarEvent(
          id: 'e-1',
          workspaceId: 'w-1',
          accountId: 'acc-1',
          externalEventId: 'ext-1',
          calendarId: 'primary',
          title: 'Standup',
          startTime: start,
          endTime: start.add(const Duration(minutes: 30)),
          updatedAt: start,
        ),
      ]);
      final db = dbs.of('w-1');
      await db
          .into(db.meetingsTable)
          .insert(
            MeetingsTableCompanion.insert(
              id: 'm-1',
              workspaceId: 'w-1',
              title: 'Standup',
            ),
          );
    });

    test(
      'linkMeetingToEvent + getEventForMeeting resolves the linked event',
      () async {
        await repo.linkMeetingToEvent(
          workspaceId: 'w-1',
          meetingId: 'm-1',
          calendarEventId: 'e-1',
        );
        final linked = await repo.getEventForMeeting('w-1', 'm-1');
        expect(linked, isNotNull);
        expect(linked!.id, 'e-1');
        expect(await repo.getMeetingIdForEvent('w-1', 'e-1'), 'm-1');
      },
    );

    test('unlinkMeeting removes the link', () async {
      await repo.linkMeetingToEvent(
        workspaceId: 'w-1',
        meetingId: 'm-1',
        calendarEventId: 'e-1',
      );
      await repo.unlinkMeeting('w-1', 'm-1');
      expect(await repo.getEventForMeeting('w-1', 'm-1'), isNull);
    });

    test('getEventForMeeting returns null when no link exists', () async {
      expect(await repo.getEventForMeeting('w-1', 'none'), isNull);
    });

    test('getMeetingIdForEvent returns null when no link exists', () async {
      expect(await repo.getMeetingIdForEvent('w-1', 'none'), isNull);
    });
  });
}
