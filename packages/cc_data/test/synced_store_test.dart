import 'dart:async';

import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:test/test.dart';

/// A minimal in-process host serving `sync.watch` / `sync.pull` with
/// scripted frames, to prove the client store's ordering, gap, LWW-overlay,
/// and kill-switch behavior (PRD 16 §6 acceptance).
class _SyncHost {
  _SyncHost(this.channel) {
    channel.incoming.listen(_onFrame);
  }

  final RemoteRpcChannelPort channel;
  final List<({String op, Map<String, dynamic> args})> calls = [];
  dynamic _subId;
  Map<String, dynamic> pullResponse = const {
    'v': 1,
    'snapshot_required': false,
    'changes': <Map<String, dynamic>>[],
    'from': 0,
    'seq': 0,
  };

  void _onFrame(Map<String, dynamic> frame) {
    final id = frame['id'];
    final method = frame['method'] as String?;
    final params = (frame['params'] as Map?)?.cast<String, dynamic>() ?? {};
    switch (method) {
      case 'initialize':
        _reply(id, {'capabilities': <String, dynamic>{}});
      case RpcMethods.subscribe:
        _subId = 's1';
        _reply(id, {'subscriptionId': 's1', 'rev': 0});
      case RpcMethods.unsubscribe:
        _reply(id, {'ok': true});
      case RpcMethods.repoCall:
        final op = params['op'] as String;
        final args = (params['args'] as Map?)?.cast<String, dynamic>() ?? {};
        calls.add((op: op, args: args));
        if (op == 'sync.pull') {
          _reply(id, {'op': op, 'data': pullResponse});
        } else {
          _reply(id, {'op': op, 'data': const <String, dynamic>{}});
        }
      default:
        _reply(id, const <String, dynamic>{});
    }
  }

  /// Pushes one delta frame to the live subscription.
  void push(Map<String, dynamic> frame) {
    channel.send({
      'jsonrpc': '2.0',
      'method': RpcMethods.subSnapshot,
      'params': {
        'subscriptionId': _subId,
        'rev': 1,
        'full': true,
        'data': frame,
      },
    });
  }

  void _reply(dynamic id, Map<String, dynamic> result) =>
      channel.send({'jsonrpc': '2.0', 'id': id, 'result': result});
}

Map<String, dynamic> _ticketChange(
  String pk,
  Map<String, dynamic> row, {
  String op = 'upsert',
}) => {'tbl': 'tickets', 'pk': pk, 'op': op, if (op == 'upsert') 'row': row};

Future<void> _settle() =>
    Future<void>.delayed(const Duration(milliseconds: 40));

void main() {
  late _SyncHost host;
  late RemoteRpcClient client;
  late SyncedStore store;

  setUp(() {
    final (server, clientChannel) = InProcessRpcChannel.pair();
    host = _SyncHost(server);
    client = RemoteRpcClient(clientChannel)..start();
    store = SyncedStore(client: client, store: 'tickets', workspaceId: 'ws1')
      ..start();
  });

  tearDown(() async {
    await store.dispose();
    await client.close();
  });

  test('applies ordered deltas after the seed and emits merged rows', () async {
    final emissions = <List<Map<String, dynamic>>>[];
    final sub = store.watchRows('tickets').listen(emissions.add);
    await _settle();
    host.push({'v': 1, 'kind': 'seed', 'store': 'tickets', 'seq': 5});
    await _settle();
    host.push({
      'v': 1,
      'kind': 'delta',
      'store': 'tickets',
      'from': 5,
      'seq': 6,
      'changes': [
        _ticketChange('t1', {'id': 't1', 'title': 'One', 'priority': 0}),
      ],
    });
    await _settle();
    expect(emissions.last.single['title'], 'One');
    expect(store.lastSeq, 6);
    expect(store.mode, SyncedStoreMode.delta);
    await sub.cancel();
  });

  test(
    'deletes remove rows; channel deletes cascade to child tables',
    () async {
      host.push({'v': 1, 'kind': 'seed', 'store': 'messaging', 'seq': 0});
      await _settle();
      host.push({
        'v': 1,
        'kind': 'delta',
        'store': 'messaging',
        'from': 0,
        'seq': 3,
        'changes': [
          {
            'tbl': 'channels',
            'pk': 'c1',
            'op': 'upsert',
            'row': {'id': 'c1', 'name': 'chan'},
          },
          {
            'tbl': 'channel_messages',
            'pk': 'm1',
            'op': 'upsert',
            'row': {'id': 'm1', 'channel_id': 'c1'},
          },
        ],
      });
      await _settle();
      host.push({
        'v': 1,
        'kind': 'delta',
        'store': 'messaging',
        'from': 3,
        'seq': 4,
        'changes': [
          {'tbl': 'channels', 'pk': 'c1', 'op': 'delete'},
        ],
      });
      await _settle();
      final channels = <List<Map<String, dynamic>>>[];
      final messages = <List<Map<String, dynamic>>>[];
      final s1 = store.watchRows('channels').listen(channels.add);
      final s2 = store.watchRows('channel_messages').listen(messages.add);
      await _settle();
      expect(channels.last, isEmpty);
      expect(messages.last, isEmpty, reason: 'cascade removed the child row');
      await s1.cancel();
      await s2.cancel();
    },
  );

  test('flicker avoidance: a local unacknowledged edit keeps winning over '
      'incoming deltas for its fields, then resolves on ack', () async {
    final emissions = <List<Map<String, dynamic>>>[];
    final sub = store.watchRows('tickets').listen(emissions.add);
    await _settle();
    host.push({'v': 1, 'kind': 'seed', 'store': 'tickets', 'seq': 0});
    await _settle();
    host.push({
      'v': 1,
      'kind': 'delta',
      'store': 'tickets',
      'from': 0,
      'seq': 1,
      'changes': [
        _ticketChange('t1', {'id': 't1', 'title': 'Server', 'priority': 0}),
      ],
    });
    await _settle();

    // Local optimistic edit of the title (instant UI).
    final handle = store.applyOptimistic('tickets', 't1', {'title': 'Mine'});
    await _settle();
    expect(emissions.last.single['title'], 'Mine');

    // A remote delta for the SAME row arrives (another client changed the
    // priority): our unacknowledged title must NOT flicker back.
    host.push({
      'v': 1,
      'kind': 'delta',
      'store': 'tickets',
      'from': 1,
      'seq': 2,
      'changes': [
        _ticketChange('t1', {'id': 't1', 'title': 'Server', 'priority': 7}),
      ],
    });
    await _settle();
    expect(emissions.last.single['title'], 'Mine', reason: 'no flicker');
    expect(
      emissions.last.single['priority'],
      7,
      reason: 'the other client\'s field landed (per-field merge)',
    );

    // Server acked our patch and its delta landed → drop the overlay.
    host.push({
      'v': 1,
      'kind': 'delta',
      'store': 'tickets',
      'from': 2,
      'seq': 3,
      'changes': [
        _ticketChange('t1', {'id': 't1', 'title': 'Mine', 'priority': 7}),
      ],
    });
    await _settle();
    handle.ack();
    await _settle();
    expect(emissions.last.single['title'], 'Mine');
    await sub.cancel();
  });

  test('a failed mutation reverts the optimistic overlay', () async {
    final emissions = <List<Map<String, dynamic>>>[];
    final sub = store.watchRows('tickets').listen(emissions.add);
    await _settle();
    host.push({'v': 1, 'kind': 'seed', 'store': 'tickets', 'seq': 0});
    host.push({
      'v': 1,
      'kind': 'delta',
      'store': 'tickets',
      'from': 0,
      'seq': 1,
      'changes': [
        _ticketChange('t1', {'id': 't1', 'title': 'Server'}),
      ],
    });
    await _settle();
    final handle = store.applyOptimistic('tickets', 't1', {'title': 'Mine'});
    await _settle();
    expect(emissions.last.single['title'], 'Mine');
    handle.fail();
    await _settle();
    expect(emissions.last.single['title'], 'Server', reason: 'reverted');
    await sub.cancel();
  });

  test('a frame gap triggers a ranged pull that repairs the store', () async {
    host.pullResponse = {
      'v': 1,
      'snapshot_required': false,
      'from': 1,
      'seq': 5,
      'changes': [
        _ticketChange('t2', {'id': 't2', 'title': 'Pulled'}),
      ],
    };
    host.push({'v': 1, 'kind': 'seed', 'store': 'tickets', 'seq': 1});
    await _settle();
    // from=4 ≠ lastSeq=1 → GAP.
    host.push({
      'v': 1,
      'kind': 'delta',
      'store': 'tickets',
      'from': 4,
      'seq': 5,
      'changes': const [],
    });
    await _settle();
    expect(host.calls.any((c) => c.op == 'sync.pull'), isTrue);
    expect(
      host.calls.firstWhere((c) => c.op == 'sync.pull').args['from_seq'],
      1,
    );
    final rows = <List<Map<String, dynamic>>>[];
    final sub = store.watchRows('tickets').listen(rows.add);
    await _settle();
    expect(rows.last.single['title'], 'Pulled');
    expect(store.mode, SyncedStoreMode.delta);
    await sub.cancel();
  });

  test('kill-switch paths: a pruned pull or an unknown wire version drops the '
      'store to snapshot mode with no data loss', () async {
    host.pullResponse = {
      'v': 1,
      'snapshot_required': true,
      'from': 1,
      'seq': 9,
      'changes': const <Map<String, dynamic>>[],
    };
    final demotions = <SyncedStoreMode>[];
    store.modeChanges.listen(demotions.add);
    host.push({'v': 1, 'kind': 'seed', 'store': 'tickets', 'seq': 1});
    await _settle();
    host.push({
      'v': 1,
      'kind': 'delta',
      'store': 'tickets',
      'from': 7,
      'seq': 9,
      'changes': const [],
    });
    await _settle();
    expect(store.mode, SyncedStoreMode.snapshot);
    expect(demotions, [SyncedStoreMode.snapshot]);

    // Unknown wire version on a fresh store demotes immediately.
    final (server2, channel2) = InProcessRpcChannel.pair();
    _SyncHost(server2);
    final client2 = RemoteRpcClient(channel2)..start();
    final store2 = SyncedStore(
      client: client2,
      store: 'tickets',
      workspaceId: 'ws1',
    )..start();
    await _settle();
    // Reach into the frame path via the public subscription push.
    // (The host pushes an unversioned frame.)
    await server2.send({
      'jsonrpc': '2.0',
      'method': RpcMethods.subSnapshot,
      'params': {
        'subscriptionId': 's1',
        'rev': 1,
        'full': true,
        'data': {'v': 99, 'kind': 'seed', 'store': 'tickets', 'seq': 0},
      },
    });
    await _settle();
    expect(store2.mode, SyncedStoreMode.snapshot);
    await store2.dispose();
    await client2.close();
  });
}
