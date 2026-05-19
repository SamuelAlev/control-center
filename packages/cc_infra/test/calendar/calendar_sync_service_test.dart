import 'package:cc_domain/features/calendar/domain/entities/calendar_event.dart';
import 'package:cc_domain/features/calendar/domain/repositories/calendar_repository.dart';
import 'package:cc_infra/cc_infra.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

class _NullDio implements Dio {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ===========================================================================
// Fake Google Calendar API client
// ===========================================================================
class FakeGoogleCalendarApiClient extends GoogleCalendarApiClient {
  FakeGoogleCalendarApiClient() : super(_NullDio());

  /// Scripted full-sync result (used when `syncToken` is null).
  GoogleCalendarEventsSyncResult fullResult =
      const GoogleCalendarEventsSyncResult(events: [], nextSyncToken: 'tok-1');

  /// Scripted incremental result (used when a `syncToken` is presented).
  GoogleCalendarEventsSyncResult incrementalResult =
      const GoogleCalendarEventsSyncResult(events: [], nextSyncToken: 'tok-2');

  /// When set, an incremental request throws 410 (token expired).
  bool expireToken = false;

  final List<String?> syncTokenCalls = [];

  @override
  Future<List<GoogleCalendarListEntry>> listCalendars({
    required String accountId,
    CancelToken? cancelToken,
  }) async => const [
    GoogleCalendarListEntry(
      id: 'cal-1',
      summary: 'Primary',
      primary: true,
      accessRole: 'owner',
    ),
  ];

  @override
  Future<GoogleCalendarEventsSyncResult> listEventsSync({
    required String accountId,
    String calendarId = 'primary',
    DateTime? timeMin,
    DateTime? timeMax,
    String? syncToken,
    CancelToken? cancelToken,
  }) async {
    syncTokenCalls.add(syncToken);
    if (syncToken != null) {
      if (expireToken) {
        throw const CalendarSyncTokenExpired();
      }
      return incrementalResult;
    }
    return fullResult;
  }
}

// ===========================================================================
// Fake CalendarRepository — in-memory, only the sync-relevant surface
// ===========================================================================
class FakeCalendarRepository implements CalendarRepository {
  final List<CalendarAccount> accounts = [];

  /// Upserted events keyed by externalEventId.
  final Map<String, CalendarEvent> events = {};

  /// Sync state keyed by `accountId|calendarId`.
  final Map<String, ({String token, DateTime? mintedAt})> syncStates = {};

  final List<Set<String>> deletedByExternalIds = [];
  int deleteMissingCalls = 0;
  int upsertSourcesCalls = 0;

  @override
  Future<List<CalendarAccount>> getAccounts(String workspaceId) async =>
      accounts;

  @override
  Future<void> upsertSources({
    required String workspaceId,
    required String accountId,
    required List<CalendarSource> sources,
  }) async {
    upsertSourcesCalls++;
  }

  @override
  Future<void> upsertEvents(List<CalendarEvent> incoming) async {
    for (final e in incoming) {
      events[e.externalEventId] = e;
    }
  }

  @override
  Future<void> deleteEventsMissingFrom({
    required String workspaceId,
    required String accountId,
    required String calendarId,
    required DateTime from,
    required DateTime to,
    required Set<String> keepExternalIds,
  }) async {
    deleteMissingCalls++;
    events.removeWhere((id, _) => !keepExternalIds.contains(id));
  }

  @override
  Future<void> deleteEventsByExternalIds({
    required String workspaceId,
    required String accountId,
    required String calendarId,
    required Set<String> externalIds,
  }) async {
    deletedByExternalIds.add(externalIds);
    events.removeWhere((id, _) => externalIds.contains(id));
  }

  @override
  Future<({String token, DateTime? mintedAt})?> getSyncState(
    String workspaceId,
    String accountId,
    String calendarId,
  ) async => syncStates['$accountId|$calendarId'];

  @override
  Future<void> setSyncState(
    String workspaceId,
    String accountId,
    String calendarId, {
    required String? token,
    required DateTime? mintedAt,
  }) async {
    final key = '$accountId|$calendarId';
    if (token == null) {
      syncStates.remove(key);
    } else {
      syncStates[key] = (token: token, mintedAt: mintedAt);
    }
  }

  @override
  Future<void> setLastSyncedAt(
    String workspaceId,
    String accountId,
    DateTime at,
  ) async {}

  @override
  Future<void> syncLinkedMeetingTitles(String workspaceId) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

// ===========================================================================
// Helpers
// ===========================================================================
GoogleCalendarEvent _gEvent(
  String id, {
  String status = 'confirmed',
  String summary = 'Standup',
}) => GoogleCalendarEvent.fromJson({
  'id': id,
  'status': status,
  'summary': summary,
  'start': {'dateTime': '2026-01-05T10:00:00Z'},
  'end': {'dateTime': '2026-01-05T10:30:00Z'},
});

CalendarAccount _account() => const CalendarAccount(
  id: 'acc-1',
  workspaceId: 'ws1',
  providerId: 'google',
  accountEmail: 'a@b.c',
);

void main() {
  late FakeGoogleCalendarApiClient api;
  late FakeCalendarRepository repository;
  late CalendarSyncService service;

  setUp(() {
    api = FakeGoogleCalendarApiClient();
    repository = FakeCalendarRepository();
    repository.accounts.add(_account());
    service = CalendarSyncService(
      apiClient: api,
      repository: repository,
      activeWorkspaceId: () => 'ws1',
    );
  });

  tearDown(() {
    service.dispose();
  });

  test('first sweep is a token-minting full sync', () async {
    api.fullResult = GoogleCalendarEventsSyncResult(
      events: [_gEvent('e1'), _gEvent('e2')],
      nextSyncToken: 'tok-1',
    );

    await service.refreshNow();

    expect(api.syncTokenCalls, [null], reason: 'no token yet → full sync');
    expect(repository.events.keys, containsAll(['e1', 'e2']));
    expect(repository.syncStates['acc-1|cal-1']?.token, 'tok-1');
    expect(repository.deleteMissingCalls, 1);
  });

  test('a held token drives an incremental (changes-only) sweep', () async {
    api.fullResult = GoogleCalendarEventsSyncResult(
      events: [_gEvent('e1')],
      nextSyncToken: 'tok-1',
    );
    await service.refreshNow();

    api.incrementalResult = GoogleCalendarEventsSyncResult(
      events: [
        _gEvent('e2', summary: 'New meeting'),
        _gEvent('e1', status: 'cancelled'),
      ],
      nextSyncToken: 'tok-2',
    );
    await service.refreshNow();

    expect(api.syncTokenCalls, [null, 'tok-1']);
    expect(repository.events.keys, [
      'e2',
    ], reason: 'e1 was cancelled → deleted; e2 upserted');
    expect(repository.deletedByExternalIds.single, {'e1'});
    expect(repository.syncStates['acc-1|cal-1']?.token, 'tok-2');
    expect(
      repository.deleteMissingCalls,
      1,
      reason: 'incremental sweeps never window-reconcile',
    );
  });

  test('a 410 falls back to a token-minting full re-sync', () async {
    api.fullResult = GoogleCalendarEventsSyncResult(
      events: [_gEvent('e1')],
      nextSyncToken: 'tok-1',
    );
    await service.refreshNow();

    api.expireToken = true;
    api.fullResult = GoogleCalendarEventsSyncResult(
      events: [_gEvent('e3')],
      nextSyncToken: 'tok-3',
    );
    await service.refreshNow();

    expect(api.syncTokenCalls, [null, 'tok-1', null]);
    expect(repository.syncStates['acc-1|cal-1']?.token, 'tok-3');
    expect(repository.events.keys, ['e3']);
  });

  test(
    'a stale token (past the re-anchor threshold) forces a full sync',
    () async {
      repository.syncStates['acc-1|cal-1'] = (
        token: 'old-token',
        mintedAt: DateTime.now().subtract(const Duration(hours: 30)),
      );
      api.fullResult = GoogleCalendarEventsSyncResult(
        events: [_gEvent('e1')],
        nextSyncToken: 'tok-fresh',
      );

      await service.refreshNow();

      expect(api.syncTokenCalls, [
        null,
      ], reason: 'stale token → full re-anchor');
      expect(repository.syncStates['acc-1|cal-1']?.token, 'tok-fresh');
    },
  );
}
