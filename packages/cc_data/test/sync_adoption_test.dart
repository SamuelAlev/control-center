import 'dart:async';

import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:test/test.dart';

/// A minimal in-process host serving BOTH the legacy full-snapshot
/// `tickets.watchForWorkspace` subscription AND the deterministic sync
/// engine's `sync.watch` / `sync.pull` (PRD 16 §6), so a repository's
/// adoption path (seed from the legacy watch, then follow deltas) can be
/// proven end to end. Mirrors the pattern in `test/synced_store_test.dart`.
class _AdoptionHost {
  _AdoptionHost(this.channel) {
    channel.incoming.listen(_onFrame);
  }

  final RemoteRpcChannelPort channel;

  /// The `{'tickets': [...]}` payload the legacy `tickets.watchForWorkspace`
  /// subscription pushes once, on subscribe.
  Map<String, dynamic> legacyTicketsSnapshot = const {
    'tickets': <Map<String, dynamic>>[],
  };

  /// The `{'channels': [...]}` payload the legacy `messaging.watchChannels`
  /// subscription pushes once, on subscribe.
  Map<String, dynamic> legacyChannelsSnapshot = const {
    'channels': <Map<String, dynamic>>[],
  };

  final Map<String, String> _subIdByQuery = {};
  final List<({String op, Map<String, dynamic> args})> repoCalls = [];
  int _nextSubId = 0;

  void _onFrame(Map<String, dynamic> frame) {
    final id = frame['id'];
    final method = frame['method'] as String?;
    final params = (frame['params'] as Map?)?.cast<String, dynamic>() ?? {};
    switch (method) {
      case 'initialize':
        _reply(id, {'capabilities': <String, dynamic>{}});
      case RpcMethods.subscribe:
        final query = params['query'] as String;
        final subId = 'sub-${_nextSubId++}';
        _subIdByQuery[query] = subId;
        _reply(id, {'subscriptionId': subId, 'rev': 0});
        switch (query) {
          case 'tickets.watchForWorkspace':
            _push(subId, legacyTicketsSnapshot);
          case 'messaging.watchChannels':
            _push(subId, legacyChannelsSnapshot);
          // 'sync.watch' pushes nothing automatically — the test drives its
          // seed/delta frames explicitly via [pushSyncFrame].
        }
      case RpcMethods.unsubscribe:
        _reply(id, {'ok': true});
      case RpcMethods.repoCall:
        final op = params['op'] as String;
        final args = (params['args'] as Map?)?.cast<String, dynamic>() ?? {};
        repoCalls.add((op: op, args: args));
        _replyData(id, op, const <String, dynamic>{});
      default:
        _reply(id, const <String, dynamic>{});
    }
  }

  /// Pushes a `sync.watch` frame (seed marker or delta packet, PRD 16 §6) to
  /// the live subscription — a no-op if nothing has subscribed yet.
  void pushSyncFrame(Map<String, dynamic> frame) {
    final subId = _subIdByQuery['sync.watch'];
    if (subId == null) {
      return;
    }
    _push(subId, frame);
  }

  /// Whether the `sync.watch` query was ever subscribed (i.e. the sync
  /// engine's store was actually created for this workspace/store pair).
  bool get syncWatchSubscribed => _subIdByQuery.containsKey('sync.watch');

  void _push(String subId, Map<String, dynamic> data) {
    channel.send({
      'jsonrpc': '2.0',
      'method': RpcMethods.subSnapshot,
      'params': {'subscriptionId': subId, 'rev': 1, 'full': true, 'data': data},
    });
  }

  void _reply(dynamic id, Map<String, dynamic> result) =>
      channel.send({'jsonrpc': '2.0', 'id': id, 'result': result});

  void _replyData(dynamic id, String op, Map<String, dynamic> data) =>
      channel.send({
        'jsonrpc': '2.0',
        'id': id,
        'result': {'op': op, 'data': data},
      });
}

/// A `ticketToWire`-shaped row (the exact shape `tickets.watchForWorkspace`'s
/// snapshot elements AND `sync.watch`'s `tickets` delta rows both carry — see
/// `cc_server_core`'s `ticketToWire` and the `SyncFeedService` ticket loader).
Map<String, dynamic> _ticketWire(
  String id,
  String title, {
  String updatedAt = '2026-01-01T00:00:00.000Z',
}) => {
  'ticket_id': id,
  'key': '',
  'title': title,
  'status': 'open',
  'priority': 'none',
  'provider': 'local',
  'workspace_id': 'ws1',
  'labels': <String>[],
  'linked_pr_ids': <String>[],
  'metadata': <String, dynamic>{},
  'version': 0,
  'origin_kind': 'manual',
  'created_at': '2026-01-01T00:00:00.000Z',
  'updated_at': updatedAt,
};

Future<void> _settle() =>
    Future<void>.delayed(const Duration(milliseconds: 40));

void main() {
  late _AdoptionHost host;
  late RemoteRpcClient client;

  setUp(() {
    final (server, clientChannel) = InProcessRpcChannel.pair();
    host = _AdoptionHost(server);
    client = RemoteRpcClient(clientChannel)..start();
  });

  tearDown(() async {
    await client.close();
  });

  group('RpcTicketRepository sync-engine adoption (PRD 16 §6)', () {
    test(
      'seeds watchForWorkspace from the legacy watch, then follows deltas',
      () async {
        host.legacyTicketsSnapshot = {
          'tickets': [_ticketWire('t1', 'Seed')],
        };
        final engine = ClientSyncEngine(
          client: client,
          storeEnabled: (store) => true,
        );
        final repo = RpcTicketRepository(client, sync: engine);

        final emissions = <List<Ticket>>[];
        final sub = repo.watchForWorkspace('ws1').listen(emissions.add);
        await _settle();

        expect(host.syncWatchSubscribed, isTrue);
        expect(emissions, isNotEmpty);
        expect(emissions.last.single.id, 't1');
        expect(emissions.last.single.title, 'Seed');

        // The store's own delta feed reports the seed marker, then a delta
        // that changes the title — the adopted watch must pick it up without
        // ever re-querying the legacy snapshot.
        host.pushSyncFrame({
          'v': 1,
          'kind': 'seed',
          'store': 'tickets',
          'seq': 0,
        });
        await _settle();
        host.pushSyncFrame({
          'v': 1,
          'kind': 'delta',
          'store': 'tickets',
          'from': 0,
          'seq': 1,
          'changes': [
            {
              'tbl': 'tickets',
              'pk': 't1',
              'op': 'upsert',
              'row': _ticketWire(
                't1',
                'Delta',
                updatedAt: '2026-01-02T00:00:00.000Z',
              ),
            },
          ],
        });
        await _settle();

        expect(emissions.last.single.title, 'Delta');

        await sub.cancel();
        await engine.dispose();
      },
    );

    test(
      'kill-switch OFF: the engine returns no store and the legacy path alone '
      'serves the watch',
      () async {
        host.legacyTicketsSnapshot = {
          'tickets': [_ticketWire('t1', 'Legacy only')],
        };
        final engine = ClientSyncEngine(
          client: client,
          storeEnabled: (store) => false,
        );
        final repo = RpcTicketRepository(client, sync: engine);

        final ticket = await repo.watchForWorkspace('ws1').first;

        expect(ticket.single.id, 't1');
        expect(ticket.single.title, 'Legacy only');
        // The kill-switch being off means `storeFor` never created a store,
        // so no `sync.watch` subscription was ever opened.
        expect(host.syncWatchSubscribed, isFalse);

        await engine.dispose();
      },
    );

    test('a null sync engine (never wired) behaves exactly like the pre-PRD-16 '
        'legacy repository', () async {
      host.legacyTicketsSnapshot = {
        'tickets': [_ticketWire('t1', 'No engine')],
      };
      final repo = RpcTicketRepository(client);

      final ticket = await repo.watchForWorkspace('ws1').first;

      expect(ticket.single.title, 'No engine');
      expect(host.syncWatchSubscribed, isFalse);
    });
  });
}
