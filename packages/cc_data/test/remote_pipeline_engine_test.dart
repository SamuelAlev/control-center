import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:test/test.dart';

/// Exercises [RemotePipelineEngine] and [RpcPipelineEnginePort] — the
/// run-control surface over RPC. Pins the `pipeline.*` ops, the args shape
/// (incl. optional passthroughs), the run DTO mapping and the resumeAll no-op.
void main() {
  late _Host host;
  late RemoteRpcClient client;

  const runPayload = {
    'id': 'run-1',
    'template_id': 't-1',
    'workspace_id': 'ws-1',
    'status': 'running',
    'started_at': '2026-07-01T09:00:00.000',
  };

  setUp(() {
    final (server, clientChannel) = InProcessRpcChannel.pair();
    host = _Host(server);
    client = RemoteRpcClient(clientChannel)..start();
  });

  tearDown(() async => client.close());

  group('RemotePipelineEngine', () {
    test('start maps the run DTO and forwards all args', () async {
      host.callResults['pipeline.start'] = {'run': runPayload};
      final engine = RemotePipelineEngine(client);
      final run = await engine.start(
        't-1',
        workspaceId: 'ws-1',
        triggerEventType: 'push',
        triggerPayload: {'a': 1},
        dedupKey: 'k',
        parentPipelineRunId: 'pr-1',
        parentStepId: 's-1',
        dryRun: true,
      );
      expect(run, isNotNull);
      expect(run!.id, 'run-1');
      expect(run.templateId, 't-1');
      final call = host.lastCall('pipeline.start')!;
      // A run has to be created somewhere: the workspace is named on the wire.
      expect(call.args['workspace_id'], 'ws-1');
      expect(call.args['template_id'], 't-1');
      expect(call.args['trigger_event_type'], 'push');
      expect(call.args['trigger_payload'], {'a': 1});
      expect(call.args['dedup_key'], 'k');
      expect(call.args['parent_pipeline_run_id'], 'pr-1');
      expect(call.args['parent_step_id'], 's-1');
      expect(call.args['dry_run'], isTrue);
    });

    test('start returns null when run is absent', () async {
      host.callResults['pipeline.start'] = const {};
      final engine = RemotePipelineEngine(client);
      expect(await engine.start('t-1', workspaceId: 'ws-1'), isNull);
    });

    test('start returns null when run is not a Map', () async {
      host.callResults['pipeline.start'] = {'run': 'nope'};
      final engine = RemotePipelineEngine(client);
      expect(await engine.start('t-1', workspaceId: 'ws-1'), isNull);
    });

    test('cancel names the workspace that owns the run', () async {
      final engine = RemotePipelineEngine(client);
      await engine.cancel('ws-1', 'run-1');
      // The host is stateless: its handler reads the workspace out of the args,
      // so omitting it would leave the call depending on whichever workspace the
      // client's route happened to be on.
      expect(host.lastCall('pipeline.cancel')!.args, {
        'workspace_id': 'ws-1',
        'pipeline_run_id': 'run-1',
      });
    });

    test('retry names the workspace that owns the run', () async {
      final engine = RemotePipelineEngine(client);
      await engine.retry('ws-1', 'run-1');
      expect(host.lastCall('pipeline.retry')!.args, {
        'workspace_id': 'ws-1',
        'pipeline_run_id': 'run-1',
      });
    });

    test('killStep names the workspace that owns the step run', () async {
      final engine = RemotePipelineEngine(client);
      await engine.killStep('ws-1', 'step-1');
      // A STEP-run id is not routable on its own — it is always paired with a
      // workspace.
      expect(host.lastCall('pipeline.killStep')!.args, {
        'workspace_id': 'ws-1',
        'step_run_id': 'step-1',
      });
    });
  });

  group('RpcPipelineEnginePort', () {
    test('start maps the DTO to a PipelineRun entity', () async {
      host.callResults['pipeline.start'] = {'run': runPayload};
      final port = RpcPipelineEnginePort(client);
      final run = await port.start('t-1', workspaceId: 'ws-1');
      expect(run, isNotNull);
      expect(run!.id, 'run-1');
      expect(host.lastCall('pipeline.start')!.args['workspace_id'], 'ws-1');
    });

    test('start returns null when the engine declines', () async {
      host.callResults['pipeline.start'] = const {};
      final port = RpcPipelineEnginePort(client);
      expect(await port.start('t-1', workspaceId: 'ws-1'), isNull);
    });

    test('resumeAll is a documented no-op', () async {
      final port = RpcPipelineEnginePort(client);
      await port.resumeAll();
      // No pipeline.* op should have been sent.
      expect(host.calls.where((c) => c.op.startsWith('pipeline.')), isEmpty);
    });

    test('cancel delegates the workspace + run id', () async {
      final port = RpcPipelineEnginePort(client);
      await port.cancel('ws-1', 'run-1');
      final args = host.lastCall('pipeline.cancel')!.args;
      expect(args['workspace_id'], 'ws-1');
      expect(args['pipeline_run_id'], 'run-1');
    });

    test('retry delegates the workspace + run id', () async {
      final port = RpcPipelineEnginePort(client);
      await port.retry('ws-1', 'run-1');
      final args = host.lastCall('pipeline.retry')!.args;
      expect(args['workspace_id'], 'ws-1');
      expect(args['pipeline_run_id'], 'run-1');
    });

    test('killStep delegates the workspace + step_run_id', () async {
      final port = RpcPipelineEnginePort(client);
      await port.killStep('ws-1', 'step-1');
      final args = host.lastCall('pipeline.killStep')!.args;
      expect(args['workspace_id'], 'ws-1');
      expect(args['step_run_id'], 'step-1');
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
  _Host(this.space) {
    space.incoming.listen(_onFrame);
  }

  final RemoteRpcChannelPort space;
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
      space.send({'jsonrpc': '2.0', 'id': id, 'result': result});
}
