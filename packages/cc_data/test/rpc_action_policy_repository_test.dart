import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_decision.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:test/test.dart';

/// Exercises [RpcActionPolicyRepository] — the guardrails rule surface over RPC.
/// Pins the ops + args, the watch query, the rule wire round-trip, and the
/// derived list/filter helpers.
void main() {
  late _Host host;
  late RemoteRpcClient client;

  Map<String, dynamic> ruleJson({
    String id = 'r-1',
    String scope = 'workspace',
    String decision = 'allow',
  }) => {
    'id': id,
    'workspace_id': 'ws-1',
    'scope_type': scope,
    'scope_id': '',
    'decision': decision,
    'action_class': 'processSpawn',
    'provenance': 'user',
    'created_at': '2026-07-01T09:00:00.000',
    'updated_at': '2026-07-01T09:00:00.000',
  };

  setUp(() {
    final (server, clientChannel) = InProcessRpcChannel.pair();
    host = _Host(server);
    client = RemoteRpcClient(clientChannel)..start();
  });

  tearDown(() async => client.close());

  group('RpcActionPolicyRepository rules', () {
    test('rules maps the rule array', () async {
      host.callResults['action_policy.list'] = {
        'rules': [
          ruleJson(id: 'r-1', decision: 'deny'),
          ruleJson(id: 'r-2', scope: 'agent'),
        ],
      };
      final repo = RpcActionPolicyRepository(client);
      final rules = await repo.rules('ws-1');
      expect(rules.length, 2);
      expect(rules.first.id, 'r-1');
      expect(rules.first.decision, ActionDecision.deny);
      expect(rules[1].scopeType, ActionScopeType.agent);
      // Names the workspace it was asked about rather than relying on the
      // client's ambient active workspace, which follows the route.
      expect(host.lastCall('action_policy.list')!.args, {
        'workspace_id': 'ws-1',
      });
    });

    test('rules returns empty when the key is absent', () async {
      host.callResults['action_policy.list'] = const {};
      final repo = RpcActionPolicyRepository(client);
      expect(await repo.rules('ws-1'), isEmpty);
    });

    test('watchRules maps the live stream', () async {
      host.snapshotFor('action_policy.watchForWorkspace', {
        'rules': [ruleJson()],
      });
      final repo = RpcActionPolicyRepository(client);
      final rules = await repo.watchRules('ws-1').first;
      expect(rules.first.id, 'r-1');
      final sub = host.lastSubscribe!;
      expect(sub.query, 'action_policy.watchForWorkspace');
      // The workspace rides in the args: a long-lived subscription must not
      // depend on the client's ambient active workspace, which flips under it
      // on a switch.
      expect(sub.args, {'workspace_id': 'ws-1'});
    });
  });

  group('RpcActionPolicyRepository writes', () {
    test('upsertRule sends the rule DTO JSON', () async {
      host.callResults['action_policy.list'] = {
        'rules': [ruleJson()],
      };
      final repo = RpcActionPolicyRepository(client);
      // Round-trip a rule read from the host through the upsert op.
      final rule = (await repo.rules('ws-1')).first;
      await repo.upsertRule(rule);
      final call = host.lastCall('action_policy.upsert')!;
      final sent = (call.args['rule'] as Map).cast<String, dynamic>();
      expect(sent['id'], 'r-1');
      expect(sent['decision'], 'allow');
      expect(sent['action_class'], 'processSpawn');
    });

    test('deleteRule forwards the id', () async {
      final repo = RpcActionPolicyRepository(client);
      await repo.deleteRule('ws-1', 'r-9');
      expect(host.lastCall('action_policy.delete')!.args['id'], 'r-9');
    });
  });

  group('RpcActionPolicyRepository derived reads', () {
    test('rulesForScope filters by scope_type + scope_id', () async {
      host.callResults['action_policy.list'] = {
        'rules': [
          ruleJson(id: 'a', scope: 'agent'),
          ruleJson(id: 'c', scope: 'channel'),
        ],
      };
      final repo = RpcActionPolicyRepository(client);
      final scoped = await repo.rulesForScope(
        'ws-1',
        ActionScopeType.channel,
        '',
      );
      expect(scoped.length, 1);
      expect(scoped.first.id, 'c');
    });

    test('ruleById returns the matching rule and null when absent', () async {
      host.callResults['action_policy.list'] = {
        'rules': [ruleJson(id: 'r-1')],
      };
      final repo = RpcActionPolicyRepository(client);
      expect((await repo.ruleById('ws-1', 'r-1'))?.id, 'r-1');
      expect(await repo.ruleById('ws-1', 'missing'), isNull);
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
        _reply(id, {
          'op': op,
          'data': callResults[op] ?? const <String, dynamic>{},
        });
      default:
        _reply(id, const <String, dynamic>{});
    }
  }

  void _reply(dynamic id, Map<String, dynamic> result) =>
      channel.send({'jsonrpc': '2.0', 'id': id, 'result': result});
}
