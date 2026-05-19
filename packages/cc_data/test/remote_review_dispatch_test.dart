import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:test/test.dart';

/// Exercises [RemoteReviewDispatch] and [RemoteOrchestrationActions] — the
/// server-side executor forwarders over RPC. Pins the op names + args shape.
void main() {
  late _Host host;
  late RemoteRpcClient client;

  setUp(() {
    final (server, clientChannel) = InProcessRpcChannel.pair();
    host = _Host(server);
    client = RemoteRpcClient(clientChannel)..start();
  });

  tearDown(() async => client.close());

  group('RemoteReviewDispatch', () {
    test('dispatch forwards agent_id + prompt + channel_id', () async {
      final dispatch = RemoteReviewDispatch(client);
      await dispatch.dispatch(
        agentId: 'ag-1',
        prompt: 'fix the tests',
        channelId: 'c-1',
      );
      final call = host.lastCall('dispatch.reviewFeedbackAgent')!;
      expect(call.args['agent_id'], 'ag-1');
      expect(call.args['prompt'], 'fix the tests');
      expect(call.args['channel_id'], 'c-1');
    });
  });

  group('RemoteOrchestrationActions', () {
    test('approve forwards the orchestration_id', () async {
      final actions = RemoteOrchestrationActions(client);
      await actions.approve('orch-1');
      expect(
        host.lastCall('orchestration.approve')!.args['orchestration_id'],
        'orch-1',
      );
    });

    test('cancel forwards the orchestration_id', () async {
      final actions = RemoteOrchestrationActions(client);
      await actions.cancel('orch-1');
      expect(
        host.lastCall('orchestration.cancel')!.args['orchestration_id'],
        'orch-1',
      );
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
        _reply(id, const <String, dynamic>{});
      default:
        _reply(id, const <String, dynamic>{});
    }
  }

  void _reply(dynamic id, Map<String, dynamic> result) =>
      channel.send({'jsonrpc': '2.0', 'id': id, 'result': result});
}
