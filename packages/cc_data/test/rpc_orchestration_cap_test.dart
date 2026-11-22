import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart' show PipelineRunDto, RpcMethods;
import 'package:cc_rpc/cc_rpc.dart';
import 'package:test/test.dart';

/// `orchestration.raiseCap` from the client (op name, args, the reply's
/// before and after) and a held run's `can_raise_cap` on the wire.
void main() {
  group('raiseCap', () {
    late _Host host;
    late RemoteRpcClient client;

    setUp(() {
      final (server, clientChannel) = InProcessRpcChannel.pair();
      host = _Host(server);
      client = RemoteRpcClient(clientChannel)..start();
    });

    tearDown(() async => client.close());

    test('sends the id and the new cap, and reads the change', () async {
      host.result = {
        'orchestration_id': 'orch-1',
        'old_micros': 2000000,
        'new_micros': 9000000,
      };
      final raise = await RpcOrchestrationRepository(
        client,
      ).raiseCap('ws-1', 'orch-1', 9000000);
      expect(host.op, 'orchestration.raiseCap');
      expect(host.args, {
        'orchestration_id': 'orch-1',
        'max_cost_micros': 9000000,
      });
      expect(raise.oldMicros, 2000000);
      expect(raise.newMicros, 9000000);
    });
  });

  group('can_raise_cap', () {
    Map<String, dynamic> wire([Map<String, dynamic> extra = const {}]) => {
      'id': 'run-1',
      'template_id': 'tpl-1',
      'workspace_id': 'ws-1',
      'status': 'suspended',
      'started_at': '2026-11-19T09:00:00.000Z',
      ...extra,
    };

    test('a held run carries the viewer\'s right to raise', () {
      for (final (extra, expected) in [
        (<String, dynamic>{'can_raise_cap': true}, true),
        (<String, dynamic>{'can_raise_cap': false}, false),
        (<String, dynamic>{}, null),
      ]) {
        final run = RpcPipelineRunRepository.runFromDto(
          PipelineRunDto.fromJson(wire(extra)),
        );
        expect(run.canRaiseCap, expected, reason: '$extra');
      }
    });
  });
}

class _Host {
  _Host(this.space) {
    space.incoming.listen(_onFrame);
  }

  final RemoteRpcChannelPort space;
  Map<String, dynamic> result = const {};
  String? op;
  Map<String, dynamic>? args;

  void _onFrame(Map<String, dynamic> frame) {
    final id = frame['id'];
    final params = (frame['params'] as Map?)?.cast<String, dynamic>() ?? {};
    switch (frame['method'] as String?) {
      case 'initialize':
        _reply(id, {'capabilities': <String, dynamic>{}});
      case RpcMethods.repoCall:
        op = params['op'] as String;
        args = (params['args'] as Map?)?.cast<String, dynamic>() ?? {};
        _reply(id, {'op': op, 'data': result});
      default:
        _reply(id, const <String, dynamic>{});
    }
  }

  void _reply(dynamic id, Map<String, dynamic> result) =>
      space.send({'jsonrpc': '2.0', 'id': id, 'result': result});
}
