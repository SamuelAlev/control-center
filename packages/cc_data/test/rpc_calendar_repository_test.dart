import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart' show RpcMethods;
import 'package:cc_domain/features/calendar/domain/entities/calendar_event.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:test/test.dart';

/// Exercises [RpcCalendarRepository] — the read/meeting-linking surface — over
/// an in-process JSON-RPC host. The repository is a thin delegate: it routes
/// every read through `RemoteCalendarRepository`'s `_client.call`/`_client.subscribe`
/// and maps the `CalendarEventDto` / `CalendarAccountDto` / `CalendarSourceDto`
/// wire shapes back to the domain entities. These tests pin the op name, the
/// args shape, the entity-from-DTO mapping, and the [UnsupportedError] guards.
void main() {
  late _Host host;
  late RemoteRpcClient client;

  setUp(() {
    final (server, clientChannel) = InProcessRpcChannel.pair();
    host = _Host(server);
    client = RemoteRpcClient(clientChannel)..start();
  });

  tearDown(() async => client.close());

  group('RpcCalendarRepository accounts', () {
    test(
      'getAccounts maps CalendarAccountDto to CalendarAccount with wsId',
      () async {
        host.callResults['calendar.getAccounts'] = {
          'accounts': [
            {
              'id': 'acc-1',
              'provider_id': 'google',
              'account_email': 'sam@example.com',
              'display_name': 'Sam',
              'last_synced_at': '2026-07-01T09:00:00.000',
              'auth_expired_at': null,
            },
          ],
        };
        final repo = RpcCalendarRepository(client);
        final accounts = await repo.getAccounts('ws-1');
        expect(accounts.length, 1);
        final a = accounts.first;
        expect(a.id, 'acc-1');
        expect(a.workspaceId, 'ws-1');
        expect(a.providerId, 'google');
        expect(a.accountEmail, 'sam@example.com');
        expect(a.displayName, 'Sam');
        expect(a.lastSyncedAt, DateTime(2026, 7, 1, 9));
        expect(a.authExpiredAt, isNull);
      },
    );

    test('watchAccounts maps the live stream', () async {
      host.snapshotFor('calendar.watchAccounts', {
        'accounts': [
          {
            'id': 'acc-1',
            'provider_id': 'google',
            'account_email': 'sam@example.com',
          },
        ],
      });
      final repo = RpcCalendarRepository(client);
      final accounts = await repo.watchAccounts('ws-1').first;
      expect(accounts.first.id, 'acc-1');
      expect(accounts.first.workspaceId, 'ws-1');
      expect(accounts.first.accountEmail, 'sam@example.com');
      // A missing last_synced_at stays null (the account reader is nullable).
      expect(accounts.first.lastSyncedAt, isNull);
      final sub = host.lastSubscribe!;
      expect(sub.query, 'calendar.watchAccounts');
      expect(sub.args, isEmpty);
    });
  });

  group('RpcCalendarRepository sources', () {
    test(
      'watchSources maps CalendarSourceDto and forwards accountId',
      () async {
        host.snapshotFor('calendar.watchSources', {
          'sources': [
            {
              'account_id': 'acc-1',
              'id': 'primary',
              'summary': 'Main',
              'primary': true,
              'writable': true,
              'background_color': '#ff0000',
            },
          ],
        });
        final repo = RpcCalendarRepository(client);
        final sources = await repo.watchSources('ws-1', 'acc-1').first;
        final s = sources.first;
        expect(s.workspaceId, 'ws-1');
        expect(s.accountId, 'acc-1');
        expect(s.id, 'primary');
        expect(s.summary, 'Main');
        expect(s.primary, isTrue);
        expect(s.writable, isTrue);
        expect(s.backgroundColor, '#ff0000');
        final sub = host.lastSubscribe!;
        expect(sub.args['account_id'], 'acc-1');
      },
    );
  });

  group('RpcCalendarRepository events', () {
    test(
      'watchEventsInRange maps events with attendees + range on wire',
      () async {
        host.snapshotFor('calendar.watchEventsInRange', {
          'events': [
            {
              'id': 'ev-1',
              'account_id': 'acc-1',
              'external_event_id': 'ext-1',
              'calendar_id': 'primary',
              'title': 'Sync',
              'start_time': '2026-07-01T09:00:00.000',
              'end_time': '2026-07-01T10:00:00.000',
              'updated_at': '2026-07-01T08:00:00.000',
              'description': 'Weekly',
              'location': 'Room 1',
              'meeting_url': 'https://meet/x',
              'is_all_day': false,
              'status': 'tentative',
              'attendees': [
                {
                  'email': 'a@x.com',
                  'display_name': 'A',
                  'response_status': 'accepted',
                  'self': false,
                  'organizer': true,
                },
              ],
            },
          ],
        });
        final repo = RpcCalendarRepository(client);
        final from = DateTime(2026, 7, 1);
        final to = DateTime(2026, 7, 2);
        final events = await repo.watchEventsInRange('ws-1', from, to).first;
        final e = events.first;
        expect(e.id, 'ev-1');
        expect(e.workspaceId, 'ws-1');
        expect(e.accountId, 'acc-1');
        expect(e.externalEventId, 'ext-1');
        expect(e.calendarId, 'primary');
        expect(e.title, 'Sync');
        expect(e.description, 'Weekly');
        expect(e.location, 'Room 1');
        expect(e.meetingUrl, 'https://meet/x');
        expect(e.isAllDay, isFalse);
        expect(e.status, CalendarEventStatus.tentative);
        expect(e.startTime, DateTime(2026, 7, 1, 9));
        expect(e.endTime, DateTime(2026, 7, 1, 10));
        expect(e.updatedAt, DateTime(2026, 7, 1, 8));
        expect(e.attendees.first.email, 'a@x.com');
        expect(e.attendees.first.organizer, isTrue);
        final sub = host.lastSubscribe!;
        expect(sub.args['from'], from.toIso8601String());
        expect(sub.args['to'], to.toIso8601String());
      },
    );

    test(
      'watchEventsInRange maps an empty-string timestamp to epoch',
      () async {
        host.snapshotFor('calendar.watchEventsInRange', {
          'events': [
            {
              'id': 'ev-2',
              'account_id': 'acc-1',
              'external_event_id': '',
              'calendar_id': 'primary',
              'title': 'NoTimes',
              'start_time': '',
              'end_time': '',
              'updated_at': '',
            },
          ],
        });
        final repo = RpcCalendarRepository(client);
        final events = await repo
            .watchEventsInRange(
              'ws-1',
              DateTime(2026, 7, 1),
              DateTime(2026, 7, 2),
            )
            .first;
        final e = events.first;
        expect(e.startTime, DateTime.fromMillisecondsSinceEpoch(0));
        expect(e.endTime, DateTime.fromMillisecondsSinceEpoch(0));
        expect(e.updatedAt, DateTime.fromMillisecondsSinceEpoch(0));
      },
    );

    test('watchEventById maps a present event and nulls when absent', () async {
      host.snapshotFor('calendar.watchEventById', {
        'event': {
          'id': 'ev-1',
          'account_id': 'acc-1',
          'external_event_id': 'ext-1',
          'calendar_id': 'primary',
          'title': 'Sync',
          'start_time': '2026-07-01T09:00:00.000',
          'end_time': '2026-07-01T10:00:00.000',
          'updated_at': '2026-07-01T08:00:00.000',
          'alerted_at': '2026-07-01T08:30:00.000',
        },
      });
      final repo = RpcCalendarRepository(client);
      final e = await repo.watchEventById('ws-1', 'ev-1').first;
      expect(e, isNotNull);
      expect(e!.id, 'ev-1');
      expect(e.workspaceId, 'ws-1');
      expect(e.alertedAt, DateTime(2026, 7, 1, 8, 30));
      final sub = host.lastSubscribe!;
      expect(sub.args['event_id'], 'ev-1');
    });

    test('watchEventById emits null when the event key is absent', () async {
      host.snapshotFor('calendar.watchEventById', const {});
      final repo = RpcCalendarRepository(client);
      expect(await repo.watchEventById('ws-1', 'ev-1').first, isNull);
    });

    test('getEventForMeeting maps a returned event', () async {
      host.callResults['calendar.getEventForMeeting'] = {
        'event': {
          'id': 'ev-1',
          'account_id': 'acc-1',
          'external_event_id': 'ext-1',
          'calendar_id': 'primary',
          'title': 'Linked',
          'start_time': '2026-07-01T09:00:00.000',
          'end_time': '2026-07-01T10:00:00.000',
          'updated_at': '2026-07-01T08:00:00.000',
        },
      };
      final repo = RpcCalendarRepository(client);
      final e = await repo.getEventForMeeting('ws-1', 'm-1');
      expect(e, isNotNull);
      expect(e!.id, 'ev-1');
      expect(e.workspaceId, 'ws-1');
      expect(
        host.lastCall('calendar.getEventForMeeting')!.args['meeting_id'],
        'm-1',
      );
    });

    test('getEventForMeeting returns null when no event is returned', () async {
      host.callResults['calendar.getEventForMeeting'] = const {};
      final repo = RpcCalendarRepository(client);
      expect(await repo.getEventForMeeting('ws-1', 'm-1'), isNull);
    });

    test('getMeetingIdForEvent returns the meeting_id', () async {
      host.callResults['calendar.getMeetingIdForEvent'] = {'meeting_id': 'm-9'};
      final repo = RpcCalendarRepository(client);
      expect(await repo.getMeetingIdForEvent('ws-1', 'ev-1'), 'm-9');
      final call = host.lastCall('calendar.getMeetingIdForEvent')!;
      expect(call.args['calendar_event_id'], 'ev-1');
    });

    test('getMeetingIdForEvent returns null when absent', () async {
      host.callResults['calendar.getMeetingIdForEvent'] = const {};
      final repo = RpcCalendarRepository(client);
      expect(await repo.getMeetingIdForEvent('ws-1', 'ev-1'), isNull);
    });
  });

  group('RpcCalendarRepository meeting linking', () {
    test('linkMeetingToEvent forwards both ids', () async {
      final repo = RpcCalendarRepository(client);
      await repo.linkMeetingToEvent(
        workspaceId: 'ws-1',
        meetingId: 'm-1',
        calendarEventId: 'ev-1',
      );
      final call = host.lastCall('calendar.linkMeetingToEvent')!;
      expect(call.args['meeting_id'], 'm-1');
      expect(call.args['calendar_event_id'], 'ev-1');
    });

    test('unlinkMeeting forwards the meeting id', () async {
      final repo = RpcCalendarRepository(client);
      await repo.unlinkMeeting('ws-1', 'm-1');
      final call = host.lastCall('calendar.unlinkMeeting')!;
      expect(call.args['meeting_id'], 'm-1');
    });
  });

  group('RpcCalendarRepository host-only surface throws', () {
    test('upsertAccount throws UnsupportedError', () async {
      final repo = RpcCalendarRepository(client);
      expect(
        () => repo.upsertAccount(_account('ws-1')),
        throwsUnsupportedError,
      );
    });

    test('upsertSources throws UnsupportedError', () async {
      final repo = RpcCalendarRepository(client);
      expect(
        () => repo.upsertSources(
          workspaceId: 'ws-1',
          accountId: 'acc-1',
          sources: const [],
        ),
        throwsUnsupportedError,
      );
    });

    test('setLastSyncedAt throws UnsupportedError', () async {
      final repo = RpcCalendarRepository(client);
      expect(
        () => repo.setLastSyncedAt('ws-1', 'acc-1', DateTime(2026)),
        throwsUnsupportedError,
      );
    });

    test('markNeedsReauth throws UnsupportedError', () async {
      final repo = RpcCalendarRepository(client);
      expect(
        () => repo.markNeedsReauth('ws-1', 'acc-1', DateTime(2026)),
        throwsUnsupportedError,
      );
    });

    test('deleteAccount throws UnsupportedError', () async {
      final repo = RpcCalendarRepository(client);
      expect(() => repo.deleteAccount('ws-1', 'acc-1'), throwsUnsupportedError);
    });

    test('upsertEvents throws UnsupportedError', () async {
      final repo = RpcCalendarRepository(client);
      expect(() => repo.upsertEvents(const []), throwsUnsupportedError);
    });

    test('deleteEventsMissingFrom throws UnsupportedError', () async {
      final repo = RpcCalendarRepository(client);
      expect(
        () => repo.deleteEventsMissingFrom(
          workspaceId: 'ws-1',
          accountId: 'acc-1',
          calendarId: 'primary',
          from: DateTime(2026, 7, 1),
          to: DateTime(2026, 7, 2),
          keepExternalIds: const {},
        ),
        throwsUnsupportedError,
      );
    });

    test('getUpcomingEventsNeedingAlert throws UnsupportedError', () async {
      final repo = RpcCalendarRepository(client);
      expect(
        () => repo.getUpcomingEventsNeedingAlert(
          'ws-1',
          DateTime(2026, 7, 1),
          DateTime(2026, 7, 2),
        ),
        throwsUnsupportedError,
      );
    });

    test('markAlerted throws UnsupportedError', () async {
      final repo = RpcCalendarRepository(client);
      expect(
        () => repo.markAlerted('ws-1', 'ev-1', DateTime(2026)),
        throwsUnsupportedError,
      );
    });

    test('syncLinkedMeetingTitles throws UnsupportedError', () async {
      final repo = RpcCalendarRepository(client);
      expect(
        () => repo.syncLinkedMeetingTitles('ws-1'),
        throwsUnsupportedError,
      );
    });
  });
}

CalendarAccount _account(String workspaceId) => CalendarAccount(
  id: 'acc-1',
  workspaceId: workspaceId,
  providerId: 'google',
  accountEmail: 'sam@example.com',
);

/// Records a `repo/call` invocation.
class _Call {
  const _Call({required this.op, required this.args});
  final String op;
  final Map<String, dynamic> args;
}

/// A recorded `sub/subscribe`.
class _Sub {
  const _Sub({required this.query, required this.args});
  final String query;
  final Map<String, dynamic> args;
}

/// In-process host that scripts `repo/call` results and `sub/subscribe`
/// snapshots. Mirrors the wire shape the server catalog emits.
class _Host {
  _Host(this.channel) {
    channel.incoming.listen(_onFrame);
  }

  final RemoteRpcChannelPort channel;
  final List<_Call> calls = [];
  final List<_Sub> subs = [];

  /// Scripted `repo/call` results keyed by op name.
  final Map<String, Map<String, dynamic>> callResults = {};

  /// Scripted snapshots keyed by watch query (pushed on subscribe).
  final Map<String, Map<String, dynamic>> snapshots = {};

  _Call? lastCall(String op) => calls.lastWhere(
    (c) => c.op == op,
    orElse: () => const _Call(op: '', args: {}),
  );
  _Sub? get lastSubscribe => subs.isEmpty ? null : subs.last;

  /// Scripts the snapshot pushed to the next subscription for [query].
  void snapshotFor(String query, Map<String, dynamic> data) =>
      snapshots[query] = data;

  void _onFrame(Map<String, dynamic> frame) {
    final id = frame['id'];
    final method = frame['method'] as String?;
    final params = (frame['params'] as Map?)?.cast<String, dynamic>() ?? {};
    switch (method) {
      case 'initialize':
        _reply(id, {'capabilities': <String, dynamic>{}});
      case RpcMethods.subscribe:
        final query = params['query'] as String;
        final args = (params['args'] as Map?)?.cast<String, dynamic>() ?? {};
        subs.add(_Sub(query: query, args: args));
        _reply(id, {'subscriptionId': 's1', 'rev': 0});
        // Immediately push the scripted snapshot for this query (if any).
        final snapshot = snapshots[query];
        if (snapshot != null) {
          channel.send({
            'jsonrpc': '2.0',
            'method': RpcMethods.subSnapshot,
            'params': {
              'subscriptionId': 's1',
              'rev': 1,
              'full': true,
              'data': snapshot,
            },
          });
        }
      case RpcMethods.unsubscribe:
        _reply(id, {'ok': true});
      case RpcMethods.repoCall:
        final op = params['op'] as String;
        final args = (params['args'] as Map?)?.cast<String, dynamic>() ?? {};
        calls.add(_Call(op: op, args: args));
        final data = callResults[op] ?? const <String, dynamic>{};
        _reply(id, {'op': op, 'data': data});
      default:
        _reply(id, const <String, dynamic>{});
    }
  }

  void _reply(dynamic id, Map<String, dynamic> result) =>
      channel.send({'jsonrpc': '2.0', 'id': id, 'result': result});
}
