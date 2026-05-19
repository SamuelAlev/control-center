import 'dart:typed_data';

import 'package:cc_data/src/repositories/remote_memory_fact_repository.dart';
import 'package:cc_data/src/repositories/rpc_memory_fact_repository.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/entities/memory_fact.dart';
import 'package:cc_domain/core/domain/value_objects/agent_role.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:test/test.dart';

/// Edge-case coverage for [RpcMemoryFactRepository] + [RemoteMemoryFactRepository]
/// — drives the branches the broad `remote_repositories_test.dart` host leaves
/// cold: epoch timestamp fallback in `_fromDto`, `getById` notFound → null,
/// `recallPolyphonic`, `getActiveByWorkspace` superseded filtering, `markRecalled`
/// no-op and the `RemoteMemoryFactRepository.getById` null-decode.
void main() {
  late _Host host;
  late RemoteRpcClient client;

  setUp(() {
    final (server, clientChannel) = InProcessRpcChannel.pair();
    host = _Host(server);
    client = RemoteRpcClient(clientChannel)..start();
  });

  tearDown(() async => client.close());

  Map<String, dynamic> factJson(
    String id, {
    String topic = 'preferences',
    String? author,
    String? authoredByRole = 'coder',
    String? supersededBy,
    int? confidence,
    String? createdAt,
    String? updatedAt,
  }) => {
    'id': id,
    'workspace_id': 'ws1',
    'domain': 'memory',
    'topic': topic,
    'content': 'body for $topic',
    'source_observation_ids': ['obs1', 'obs2'],
    'confidence': ?confidence,
    'authored_by_agent_id': ?author,
    'authored_by_role': ?authoredByRole,
    'superseded_by': ?supersededBy,
    'created_at': ?createdAt,
    'updated_at': ?updatedAt,
  };

  group('RpcMemoryFactRepository epoch fallbacks', () {
    test(
      'getByWorkspace falls back to the epoch when timestamps are absent',
      () async {
        host.callResults['memory_fact.getByWorkspace'] = {
          'facts': [factJson('mf1')],
        };
        final facts = await RpcMemoryFactRepository(
          client,
        ).getByWorkspace('ws1');
        expect(facts.single.createdAt, DateTime.fromMillisecondsSinceEpoch(0));
        expect(facts.single.updatedAt, DateTime.fromMillisecondsSinceEpoch(0));
      },
    );

    test(
      'watchByWorkspace falls back to the epoch when timestamps are absent',
      () async {
        host.snapshotFor('memory_fact.watchForWorkspace', {
          'facts': [factJson('mf1')],
        });
        final facts = await RpcMemoryFactRepository(
          client,
        ).watchByWorkspace('ws1').first;
        expect(facts.single.createdAt, DateTime.fromMillisecondsSinceEpoch(0));
        expect(facts.single.updatedAt, DateTime.fromMillisecondsSinceEpoch(0));
      },
    );
  });

  group('RpcMemoryFactRepository getById null handling', () {
    test('returns null when the host reports notFound', () async {
      host.errorCodes['memory_fact.getById'] = RpcErrorCodes.notFound;
      expect(
        await RpcMemoryFactRepository(client).getById('ws1', 'missing'),
        isNull,
      );
    });

    test('returns null when the fact payload is absent', () async {
      host.callResults['memory_fact.getById'] = const {};
      expect(
        await RpcMemoryFactRepository(client).getById('ws1', 'missing'),
        isNull,
      );
    });

    test('rethrows a non-notFound RPC error', () async {
      host.errorCodes['memory_fact.getById'] = RpcErrorCodes.internalError;
      expect(
        () => RpcMemoryFactRepository(client).getById('ws1', 'x'),
        throwsA(isA<RemoteRpcException>()),
      );
    });

    test('returns the mapped fact when present', () async {
      host.callResults['memory_fact.getById'] = {
        'fact': factJson('mf1', author: 'agent-7'),
      };
      final fact = await RpcMemoryFactRepository(client).getById('ws1', 'mf1');
      expect(fact!.id, 'mf1');
      expect(fact.authoredByAgentId, 'agent-7');
      expect(fact.authoredByRole, AgentRole.coder);
    });
  });

  group('RpcMemoryFactRepository recall / active filtering', () {
    test('recallPolyphonic caps the result to topK', () async {
      host.callResults['memory_fact.search'] = {
        'facts': [factJson('mf1'), factJson('mf2'), factJson('mf3')],
      };
      final recalled = await RpcMemoryFactRepository(
        client,
      ).recallPolyphonic('ws1', 'q', topK: 2);
      expect(recalled.length, 2);
      expect(recalled.first.id, 'mf1');
      expect(recalled.last.id, 'mf2');
    });

    test(
      'recallPolyphonic ignores the embedding query (degrades to FTS5)',
      () async {
        host.callResults['memory_fact.search'] = {
          'facts': [factJson('mf1')],
        };
        // Should NOT throw (unlike search(), which throws on embeddings).
        final recalled = await RpcMemoryFactRepository(
          client,
        ).recallPolyphonic('ws1', 'q', queryEmbedding: Float32List(4));
        expect(recalled.single.id, 'mf1');
      },
    );

    test('search throws when an embedding is supplied', () async {
      expect(
        () => RpcMemoryFactRepository(
          client,
        ).search('ws1', 'q', queryEmbedding: Float32List(4)),
        throwsUnsupportedError,
      );
    });

    test('getActiveByWorkspace filters out superseded facts', () async {
      host.callResults['memory_fact.getByWorkspace'] = {
        'facts': [factJson('mf1'), factJson('mf2', supersededBy: 'mf3')],
      };
      final active = await RpcMemoryFactRepository(
        client,
      ).getActiveByWorkspace('ws1');
      expect(active.length, 1);
      expect(active.single.id, 'mf1');
    });
  });

  group('RpcMemoryFactRepository markRecalled', () {
    test('is a host-owned no-op on the thin client', () async {
      await RpcMemoryFactRepository(client).markRecalled('ws1', ['mf1']);
      // No `repo/call` should have been issued.
      expect(host.calls, isEmpty);
    });
  });

  group('RpcMemoryFactRepository upsert/delete', () {
    test('upsert forwards the fact DTO', () async {
      await RpcMemoryFactRepository(client).upsert(
        MemoryFact(
          id: 'mf9',
          workspaceId: 'ws1',
          domain: 'memory',
          topic: 'goals',
          content: 'ship',
          createdAt: DateTime.utc(2026),
          updatedAt: DateTime.utc(2026),
        ),
      );
      final fact = host.lastCall('memory_fact.upsert')!.args['fact'] as Map;
      expect(fact['id'], 'mf9');
    });

    test('delete forwards the fact id', () async {
      await RpcMemoryFactRepository(client).delete('ws1', 'mf9');
      expect(host.lastCall('memory_fact.delete')!.args['fact_id'], 'mf9');
    });
  });

  group('RemoteMemoryFactRepository', () {
    test('getById returns null when fact is not a Map', () async {
      host.callResults['memory_fact.getById'] = {'fact': 'bad'};
      expect(await RemoteMemoryFactRepository(client).getById('mf1'), isNull);
    });
  });
}

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

class _Host {
  _Host(this.channel) {
    channel.incoming.listen(_onFrame);
  }

  final RemoteRpcChannelPort channel;
  final List<_Call> calls = [];
  final List<_Sub> subs = [];
  final Map<String, Map<String, dynamic>> callResults = {};
  final Map<String, Map<String, dynamic>> snapshots = {};
  final Map<String, int> errorCodes = {};

  _Call? lastCall(String op) => calls.lastWhere(
    (c) => c.op == op,
    orElse: () => const _Call(op: '', args: {}),
  );
  _Sub? get lastSubscribe => subs.isEmpty ? null : subs.last;

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
        final err = errorCodes[op];
        if (err != null) {
          channel.send({
            'jsonrpc': '2.0',
            'id': id,
            'error': {'code': err, 'message': 'scripted'},
          });
        } else {
          _reply(id, {
            'op': op,
            'data': callResults[op] ?? const <String, dynamic>{},
          });
        }
      default:
        _reply(id, const <String, dynamic>{});
    }
  }

  void _reply(dynamic id, Map<String, dynamic> result) =>
      channel.send({'jsonrpc': '2.0', 'id': id, 'result': result});
}
