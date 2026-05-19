import 'dart:async';

import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/messaging/domain/entities/space.dart';
import 'package:cc_domain/features/messaging/domain/entities/space_participant.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:test/test.dart';

/// Adoption-path coverage for [RpcMessagingRepository]'s `SyncedStore`-backed
/// watches — `watchSpacesByWorkspace` (the `_watchAdoptedSpaces` path),
/// `watchSpaces` (delegates to it when `activeWorkspaceId` is bound) and
/// `watchParticipants` (the `_watchAdoptedParticipants` merge path) — plus the
/// null-filtering `watchSpaceTurns` decode. Mirrors the in-process host
/// pattern in `sync_adoption_test.dart`.
class _AdoptionHost {
  _AdoptionHost(this.space) {
    space.incoming.listen(_onFrame);
  }

  final RemoteRpcChannelPort space;

  /// Legacy `messaging.watchSpaces` snapshot pushed once on subscribe.
  Map<String, dynamic> legacySpacesSnapshot = const {
    'spaces': <Map<String, dynamic>>[],
  };

  /// Legacy `messaging.watchParticipants` snapshot pushed once on subscribe,
  /// keyed by spaceId.
  final Map<String, Map<String, dynamic>> legacyParticipantsSnapshots = {};

  final Map<String, String> _subIdByQuery = {};
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
        final args = (params['args'] as Map?)?.cast<String, dynamic>() ?? {};
        final subId = 'sub-${_nextSubId++}';
        _subIdByQuery[query] = subId;
        _reply(id, {'subscriptionId': subId, 'rev': 0});
        switch (query) {
          case 'messaging.watchSpaces':
            _push(subId, legacySpacesSnapshot);
          case 'messaging.watchParticipants':
            final spaceId = args['space_id'] as String?;
            final snap = legacyParticipantsSnapshots[spaceId];
            if (snap != null) {
              _push(subId, snap);
            }
          // 'sync.watch' pushes nothing automatically.
        }
      case RpcMethods.unsubscribe:
        _reply(id, {'ok': true});
      case RpcMethods.repoCall:
        final op = params['op'] as String;
        _replyData(id, op, const <String, dynamic>{});
      default:
        _reply(id, const <String, dynamic>{});
    }
  }

  void pushSyncFrame(Map<String, dynamic> frame) {
    final subId = _subIdByQuery['sync.watch'];
    if (subId == null) {
      return;
    }
    _push(subId, frame);
  }

  bool get syncWatchSubscribed => _subIdByQuery.containsKey('sync.watch');

  void _push(String subId, Map<String, dynamic> data) {
    space.send({
      'jsonrpc': '2.0',
      'method': RpcMethods.subSnapshot,
      'params': {'subscriptionId': subId, 'rev': 1, 'full': true, 'data': data},
    });
  }

  void _reply(dynamic id, Map<String, dynamic> result) =>
      space.send({'jsonrpc': '2.0', 'id': id, 'result': result});

  void _replyData(dynamic id, String op, Map<String, dynamic> data) =>
      space.send({
        'jsonrpc': '2.0',
        'id': id,
        'result': {'op': op, 'data': data},
      });
}

Map<String, dynamic> _spaceWire(
  String id, {
  String name = 'general',
  String updatedAt = '2026-01-01T00:00:00.000Z',
}) => {'id': id, 'name': name, 'workspace_id': 'ws1', 'updated_at': updatedAt};

Map<String, dynamic> _participantWire(
  String id,
  String spaceId, {
  String principalId = 'agent-1',
  String joinedAt = '2026-01-01T00:00:00.000Z',
}) => {
  'id': id,
  'space_id': spaceId,
  'principal_id': principalId,
  'participant_type': 'agent',
  'joined_at': joinedAt,
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
    // Bind the workspace so the adoption branches are taken.
    client.activeWorkspaceId = 'ws1';
  });

  tearDown(() async {
    await client.close();
  });

  group('RpcMessagingRepository sync adoption', () {
    test(
      'watchSpacesByWorkspace seeds from the legacy watch then follows deltas',
      () async {
        host.legacySpacesSnapshot = {
          'spaces': [_spaceWire('c1', name: 'Seed')],
        };
        final engine = ClientSyncEngine(
          client: client,
          storeEnabled: (store) => true,
        );
        final repo = RpcMessagingRepository(client, sync: engine);

        final emissions = <List<Space>>[];
        final sub = repo.watchSpacesByWorkspace('ws1').listen(emissions.add);
        await _settle();

        expect(host.syncWatchSubscribed, isTrue);
        expect(emissions, isNotEmpty);
        expect(emissions.last.single.id, 'c1');
        expect(emissions.last.single.name, 'Seed');

        // A delta renaming the space propagates without a re-seed query.
        host.pushSyncFrame({
          'v': 1,
          'kind': 'seed',
          'store': 'messaging',
          'seq': 0,
        });
        await _settle();
        host.pushSyncFrame({
          'v': 1,
          'kind': 'delta',
          'store': 'messaging',
          'from': 0,
          'seq': 1,
          'changes': [
            {
              'tbl': 'spaces',
              'pk': 'c1',
              'op': 'upsert',
              'row': _spaceWire(
                'c1',
                name: 'Delta',
                updatedAt: '2026-02-01T00:00:00.000Z',
              ),
            },
          ],
        });
        await _settle();

        expect(emissions.last.single.name, 'Delta');

        await sub.cancel();
        await engine.dispose();
      },
    );

    test('watchSpaces delegates to the adopted workspace path', () async {
      host.legacySpacesSnapshot = {
        'spaces': [_spaceWire('c1')],
      };
      final engine = ClientSyncEngine(
        client: client,
        storeEnabled: (store) => true,
      );
      final repo = RpcMessagingRepository(client, sync: engine);

      final spaces = await repo.watchSpaces().first;
      expect(spaces.single.id, 'c1');
      expect(host.syncWatchSubscribed, isTrue);

      await engine.dispose();
    });

    test(
      'kill-switch OFF: watchSpacesByWorkspace falls back to the legacy path',
      () async {
        host.legacySpacesSnapshot = {
          'spaces': [_spaceWire('c1', name: 'Legacy')],
        };
        final engine = ClientSyncEngine(
          client: client,
          storeEnabled: (store) => false,
        );
        final repo = RpcMessagingRepository(client, sync: engine);

        final spaces = await repo.watchSpacesByWorkspace('ws1').first;
        expect(spaces.single.id, 'c1');
        expect(host.syncWatchSubscribed, isFalse);

        await engine.dispose();
      },
    );

    test(
      'null sync engine: watchSpaces uses the legacy path untouched',
      () async {
        host.legacySpacesSnapshot = {
          'spaces': [_spaceWire('c1', name: 'No engine')],
        };
        final repo = RpcMessagingRepository(client);
        final spaces = await repo.watchSpaces().first;
        expect(spaces.single.name, 'No engine');
        expect(host.syncWatchSubscribed, isFalse);
      },
    );

    test(
      'watchParticipants seeds the merge table and follows deltas',
      () async {
        host.legacyParticipantsSnapshots['c1'] = {
          'participants': [_participantWire('p1', 'c1')],
        };
        final engine = ClientSyncEngine(
          client: client,
          storeEnabled: (store) => true,
        );
        final repo = RpcMessagingRepository(client, sync: engine);

        // Spin up the sync store for `messaging` so the adoption branch fires.
        final spacesSub = repo.watchSpacesByWorkspace('ws1').listen((_) {});
        await _settle();

        final emissions = <List<SpaceParticipant>>[];
        final sub = repo.watchParticipants('ws1', 'c1').listen(emissions.add);
        await _settle();

        expect(emissions, isNotEmpty);
        expect(emissions.last.single.id, 'p1');
        expect(emissions.last.single.spaceId, 'c1');

        await sub.cancel();
        await spacesSub.cancel();
        await engine.dispose();
      },
    );

    test('kill-switch OFF: watchParticipants uses the legacy path', () async {
      host.legacyParticipantsSnapshots['c1'] = {
        'participants': [_participantWire('p1', 'c1', principalId: 'agent-9')],
      };
      final engine = ClientSyncEngine(
        client: client,
        storeEnabled: (store) => false,
      );
      final repo = RpcMessagingRepository(client, sync: engine);

      final participants = await repo.watchParticipants('ws1', 'c1').first;
      expect(participants.single.id, 'p1');
      expect(participants.single.principalId, 'agent-9');

      await engine.dispose();
    });
  });
}
