import 'dart:convert';
import 'dart:typed_data';

import 'package:cc_domain/core/domain/events/calendar_events.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/features/calendar/domain/entities/calendar_event.dart';
import 'package:cc_infra/src/calendar/calendar_sync_service.dart';
import 'package:cc_infra/src/network/google_calendar_api_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fake_calendar_repository.dart';

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter({required this.events, required this.calendars});

  /// Returned for `/events` requests.
  final Map<String, dynamic> events;

  /// Returned for `/calendarList` requests.
  final Map<String, dynamic> calendars;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final body =
        options.uri.path.contains('calendarList') ? calendars : events;
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Builds a client returning [events] for event requests and, by default, a
/// single primary calendar for the calendar-list request.
GoogleCalendarApiClient _clientReturning(
  Map<String, dynamic> events, {
  Map<String, dynamic>? calendars,
}) {
  final dio = Dio()
    ..httpClientAdapter = _FakeAdapter(
      events: events,
      calendars: calendars ??
          <String, dynamic>{
            'items': [
              {
                'id': 'primary',
                'summary': 'Primary',
                'primary': true,
                'selected': true,
                'accessRole': 'owner',
              },
            ],
          },
    );
  return GoogleCalendarApiClient(dio);
}

void main() {
  group('CalendarSyncService', () {
    late FakeCalendarRepository repo;
    late DomainEventBus bus;

    setUp(() {
      repo = FakeCalendarRepository();
      bus = DomainEventBus();
    });

    tearDown(() => bus.dispose());

    test('syncs events, records lastSyncedAt, publishes refreshed', () async {
      repo.account = const CalendarAccount(
        id: 'acc-1',
        workspaceId: 'ws-A',
        providerId: 'google',
        accountEmail: 'a@x.com',
      );
      final client = _clientReturning({
        'items': [
          {
            'id': 'g-1',
            'status': 'confirmed',
            'summary': 'Standup',
            'start': {'dateTime': '2026-06-11T10:00:00Z'},
            'end': {'dateTime': '2026-06-11T10:30:00Z'},
          },
          {
            'id': 'g-2',
            'status': 'confirmed',
            'summary': 'Holiday',
            'start': {'date': '2026-06-12'},
            'end': {'date': '2026-06-13'},
          },
        ],
      });
      final refreshed = <CalendarEventsRefreshed>[];
      bus.on<CalendarEventsRefreshed>().listen(refreshed.add);

      final service = CalendarSyncService(
        apiClient: client,
        repository: repo,
        eventBus: bus,
        activeWorkspaceId: () => 'ws-A',
      );
      await service.refreshNow();
      await Future<void>.delayed(Duration.zero);

      expect(repo.upsertedEvents, hasLength(2));
      expect(repo.upsertedEvents.map((e) => e.externalEventId), ['g-1', 'g-2']);
      expect(repo.upsertedEvents[1].isAllDay, isTrue);
      expect(repo.lastSynced, hasLength(1));
      expect(repo.lastSynced.single.accountId, 'acc-1');
      expect(refreshed, hasLength(1));
      expect(refreshed.single.workspaceId, 'ws-A');
    });

    test('backfills attendee display names from the organizer/creator',
        () async {
      repo.account = const CalendarAccount(
        id: 'acc-1',
        workspaceId: 'ws-A',
        providerId: 'google',
        accountEmail: 'a@x.com',
      );
      final client = _clientReturning({
        'items': [
          {
            'id': 'g-1',
            'status': 'confirmed',
            'summary': 'Standup',
            'start': {'dateTime': '2026-06-11T10:00:00Z'},
            'end': {'dateTime': '2026-06-11T10:30:00Z'},
            'organizer': {'email': 'lead@x.com', 'displayName': 'Team Lead'},
            'creator': {'email': 'maker@x.com', 'displayName': 'The Maker'},
            'attendees': [
              // Has its own name: kept as-is.
              {'email': 'ada@x.com', 'displayName': 'Ada Lovelace'},
              // No name, matches the organizer: backfilled.
              {'email': 'lead@x.com', 'organizer': true},
              // No name, matches the creator: backfilled.
              {'email': 'maker@x.com'},
              // No name, no match: left null (UI derives from the email).
              {'email': 'grace@x.com'},
            ],
          },
        ],
      });
      final service = CalendarSyncService(
        apiClient: client,
        repository: repo,
        eventBus: bus,
        activeWorkspaceId: () => 'ws-A',
      );
      await service.refreshNow();
      await Future<void>.delayed(Duration.zero);

      final attendees = repo.upsertedEvents.single.attendees;
      final byEmail = {for (final a in attendees) a.email: a.displayName};
      expect(byEmail['ada@x.com'], 'Ada Lovelace');
      expect(byEmail['lead@x.com'], 'Team Lead');
      expect(byEmail['maker@x.com'], 'The Maker');
      expect(byEmail['grace@x.com'], isNull);
    });

    test('reconciles deletions: each calendar is swept with its fetched ids',
        () async {
      repo.account = const CalendarAccount(
        id: 'acc-1',
        workspaceId: 'ws-A',
        providerId: 'google',
        accountEmail: 'a@x.com',
      );
      final client = _clientReturning({
        'items': [
          {
            'id': 'g-1',
            'status': 'confirmed',
            'summary': 'Kept',
            'start': {'dateTime': '2026-06-11T10:00:00Z'},
            'end': {'dateTime': '2026-06-11T10:30:00Z'},
          },
        ],
      });
      final service = CalendarSyncService(
        apiClient: client,
        repository: repo,
        eventBus: bus,
        activeWorkspaceId: () => 'ws-A',
      );
      await service.refreshNow();
      await Future<void>.delayed(Duration.zero);

      // One reconciliation per fetched calendar, keeping exactly the ids the
      // provider returned — so anything else in that window is swept away.
      expect(repo.reconciled, hasLength(1));
      final sweep = repo.reconciled.single;
      expect(sweep.workspaceId, 'ws-A');
      expect(sweep.accountId, 'acc-1');
      expect(sweep.calendarId, 'primary');
      expect(sweep.keepExternalIds, {'g-1'});
    });

    test('syncs every calendar, tags events, skips freeBusyReader', () async {
      repo.account = const CalendarAccount(
        id: 'acc-1',
        workspaceId: 'ws-A',
        providerId: 'google',
        accountEmail: 'a@x.com',
      );
      final client = _clientReturning(
        {
          'items': [
            {
              'id': 'e-1',
              'status': 'confirmed',
              'summary': 'X',
              'start': {'dateTime': '2026-06-11T10:00:00Z'},
              'end': {'dateTime': '2026-06-11T10:30:00Z'},
            },
          ],
        },
        calendars: <String, dynamic>{
          'items': [
            {
              'id': 'primary',
              'summary': 'Primary',
              'primary': true,
              'selected': true,
              'accessRole': 'owner',
            },
            {
              'id': 'team@group',
              'summary': 'Team',
              'selected': true,
              'accessRole': 'reader',
            },
            {
              'id': 'busy@group',
              'summary': 'Free/busy only',
              'accessRole': 'freeBusyReader',
            },
          ],
        },
      );
      final service = CalendarSyncService(
        apiClient: client,
        repository: repo,
        eventBus: bus,
        activeWorkspaceId: () => 'ws-A',
      );
      await service.refreshNow();
      await Future<void>.delayed(Duration.zero);

      // primary + team are fetched (1 event each); the freeBusy calendar is
      // skipped.
      expect(repo.upsertedEvents, hasLength(2));
      expect(
        repo.upsertedEvents.map((e) => e.calendarId).toSet(),
        {'primary', 'team@group'},
      );

      // The full calendar list (incl. the free/busy one) is persisted as
      // sources so the sidebar can render it; the host owns the OAuth tokens,
      // so thin clients read this via watchSources instead of calling Google.
      expect(repo.upsertedSources, hasLength(1));
      final persisted = repo.upsertedSources.single;
      expect(persisted.workspaceId, 'ws-A');
      expect(persisted.accountId, 'acc-1');
      expect(
        persisted.sources.map((s) => s.id).toSet(),
        {'primary', 'team@group', 'busy@group'},
      );
      final byId = {for (final s in persisted.sources) s.id: s};
      expect(byId['primary']!.primary, isTrue);
      expect(byId['primary']!.writable, isTrue); // owner
      expect(byId['team@group']!.writable, isFalse); // reader
      expect(byId['busy@group']!.writable, isFalse); // freeBusyReader
    });

    test('syncs every connected account, tagging events per account', () async {
      repo.accounts = const [
        CalendarAccount(
          id: 'acc-1',
          workspaceId: 'ws-A',
          providerId: 'google',
          accountEmail: 'a@x.com',
        ),
        CalendarAccount(
          id: 'acc-2',
          workspaceId: 'ws-A',
          providerId: 'google',
          accountEmail: 'b@x.com',
        ),
      ];
      final client = _clientReturning({
        'items': [
          {
            'id': 'e-1',
            'status': 'confirmed',
            'summary': 'X',
            'start': {'dateTime': '2026-06-11T10:00:00Z'},
            'end': {'dateTime': '2026-06-11T10:30:00Z'},
          },
        ],
      });
      final service = CalendarSyncService(
        apiClient: client,
        repository: repo,
        eventBus: bus,
        activeWorkspaceId: () => 'ws-A',
      );
      await service.refreshNow();
      await Future<void>.delayed(Duration.zero);

      // One event per account (each account has one primary calendar).
      expect(repo.upsertedEvents, hasLength(2));
      expect(
        repo.upsertedEvents.map((e) => e.accountId).toSet(),
        {'acc-1', 'acc-2'},
      );
      expect(repo.lastSynced.map((s) => s.accountId).toSet(), {'acc-1', 'acc-2'});
    });

    test('is a no-op when no account is connected', () async {
      final client = _clientReturning({'items': []});
      final service = CalendarSyncService(
        apiClient: client,
        repository: repo,
        eventBus: bus,
        activeWorkspaceId: () => 'ws-A',
      );
      await service.refreshNow();
      expect(repo.upsertedEvents, isEmpty);
      expect(repo.lastSynced, isEmpty);
    });

    test('is a no-op when there is no active workspace', () async {
      repo.account = const CalendarAccount(
        id: 'acc-1',
        workspaceId: 'ws-A',
        providerId: 'google',
        accountEmail: 'a@x.com',
      );
      final client = _clientReturning({'items': []});
      final service = CalendarSyncService(
        apiClient: client,
        repository: repo,
        eventBus: bus,
        activeWorkspaceId: () => null,
      );
      await service.refreshNow();
      expect(repo.lastSynced, isEmpty);
    });

    test('ensureRangeLoaded is a no-op inside the rolling window', () async {
      repo.account = const CalendarAccount(
        id: 'acc-1',
        workspaceId: 'ws-A',
        providerId: 'google',
        accountEmail: 'a@x.com',
      );
      final client = _clientReturning({
        'items': [
          {
            'id': 'g-1',
            'status': 'confirmed',
            'summary': 'Soon',
            'start': {'dateTime': '2026-06-13T10:00:00Z'},
            'end': {'dateTime': '2026-06-13T10:30:00Z'},
          },
        ],
      });
      final service = CalendarSyncService(
        apiClient: client,
        repository: repo,
        eventBus: bus,
        activeWorkspaceId: () => 'ws-A',
      );
      final now = DateTime.now();
      // Inside the default ±window — the periodic sync owns this range.
      await service.ensureRangeLoaded(
        'ws-A',
        now.add(const Duration(days: 1)),
        now.add(const Duration(days: 2)),
      );
      expect(repo.upsertedEvents, isEmpty);
    });

    test('ensureRangeLoaded fetches an out-of-window range once, then caches',
        () async {
      repo.account = const CalendarAccount(
        id: 'acc-1',
        workspaceId: 'ws-A',
        providerId: 'google',
        accountEmail: 'a@x.com',
      );
      final client = _clientReturning({
        'items': [
          {
            'id': 'g-far',
            'status': 'confirmed',
            'summary': 'Far future',
            'start': {'dateTime': '2026-12-10T10:00:00Z'},
            'end': {'dateTime': '2026-12-10T10:30:00Z'},
          },
        ],
      });
      final service = CalendarSyncService(
        apiClient: client,
        repository: repo,
        eventBus: bus,
        activeWorkspaceId: () => 'ws-A',
      );
      final now = DateTime.now();
      final from = now.add(const Duration(days: 180));
      final to = now.add(const Duration(days: 210));

      await service.ensureRangeLoaded('ws-A', from, to);
      await Future<void>.delayed(Duration.zero);
      expect(repo.upsertedEvents, hasLength(1));

      // Same range again is served from the in-memory coverage — no refetch.
      await service.ensureRangeLoaded('ws-A', from, to);
      expect(repo.upsertedEvents, hasLength(1));
    });
  });
}
