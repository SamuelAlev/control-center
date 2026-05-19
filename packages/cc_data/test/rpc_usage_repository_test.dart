import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:test/test.dart';

/// Exercises [RpcUsageRepository] — the usage-dashboard data path over RPC.
/// Pins the op name, the window_days arg, the DTO→entity mapping (incl. the
/// epoch fallback and the nextResetAt parse) and the empty-result default.
void main() {
  late _Host host;
  late RemoteRpcClient client;

  setUp(() {
    final (server, clientChannel) = InProcessRpcChannel.pair();
    host = _Host(server);
    client = RemoteRpcClient(clientChannel)..start();
  });

  tearDown(() async => client.close());

  group('RpcUsageRepository.costSummary', () {
    test('maps a full summary and forwards window_days', () async {
      host.callResults['usage.costSummary'] = {
        'total_usd': 12.4,
        'request_count': 100,
        'window_start': '2026-07-01T00:00:00.000',
        'next_reset_at': '2026-07-02T00:00:00.000',
        'by_provider': {'claude': 10.0, 'glm': 2.4},
        'by_model': {'claude/opus': 10.0},
      };
      final repo = RpcUsageRepository(client);
      final summary = await repo.costSummary(windowDays: 14);
      expect(summary.totalUsd, 12.4);
      expect(summary.requestCount, 100);
      expect(summary.windowStart, DateTime(2026, 7, 1));
      expect(summary.nextResetAt, DateTime(2026, 7, 2));
      expect(summary.byProvider, {'claude': 10.0, 'glm': 2.4});
      expect(summary.byModel, {'claude/opus': 10.0});
      expect(host.lastCall('usage.costSummary')!.args['window_days'], 14);
    });

    test('falls back to epoch when window_start is absent', () async {
      host.callResults['usage.costSummary'] = const {};
      final repo = RpcUsageRepository(client);
      final summary = await repo.costSummary();
      expect(summary.totalUsd, 0);
      expect(summary.requestCount, 0);
      expect(summary.windowStart, DateTime.fromMillisecondsSinceEpoch(0));
      expect(summary.nextResetAt, isNull);
      expect(summary.byProvider, isEmpty);
      expect(summary.byModel, isEmpty);
    });

    test('defaults window_days to 7', () async {
      host.callResults['usage.costSummary'] = const {};
      final repo = RpcUsageRepository(client);
      await repo.costSummary();
      expect(host.lastCall('usage.costSummary')!.args['window_days'], 7);
    });

    test('nextResetAt is null when absent', () async {
      host.callResults['usage.costSummary'] = {
        'total_usd': 1.0,
        'request_count': 1,
      };
      final repo = RpcUsageRepository(client);
      final summary = await repo.costSummary();
      expect(summary.nextResetAt, isNull);
    });
  });
}

/// Records a `repo/call` invocation.
class _Call {
  const _Call({required this.op, required this.args});
  final String op;
  final Map<String, dynamic> args;
}

class _Host {
  _Host(this.channel) {
    channel.incoming.listen(_onFrame);
  }

  final RemoteRpcChannelPort channel;
  final List<_Call> calls = [];
  final Map<String, Map<String, dynamic>> callResults = {};

  _Call? lastCall(String op) => calls.lastWhere(
    (c) => c.op == op,
    orElse: () => const _Call(op: '', args: {}),
  );

  void _onFrame(Map<String, dynamic> frame) {
    final id = frame['id'];
    final method = frame['method'] as String?;
    final params = (frame['params'] as Map?)?.cast<String, dynamic>() ?? {};
    switch (method) {
      case 'initialize':
        _reply(id, {'capabilities': <String, dynamic>{}});
      case RpcMethods.subscribe:
        _reply(id, {'subscriptionId': 's1', 'rev': 0});
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
