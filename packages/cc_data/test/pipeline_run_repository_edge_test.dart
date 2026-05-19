import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_run.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_status.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:test/test.dart';

/// The workspace whose database file the step-run mutations address. A step-run
/// id does not route to a workspace on its own, so it is always paired with one.
const _workspaceId = 'ws1';

/// Edge-case coverage for [RpcPipelineRunRepository] — drives the paths the
/// broad `remote_repositories_test.dart` host leaves cold: `insertStepRun`
/// (and therefore `_stepToDto`), the `finishedAt?.toIso8601String()` branch in
/// `updateStepRun`, and the `getRun` notFound → null catch.
void main() {
  late _Host host;
  late RemoteRpcClient client;

  setUp(() {
    final (server, clientChannel) = InProcessRpcChannel.pair();
    host = _Host(server);
    client = RemoteRpcClient(clientChannel)..start();
  });

  tearDown(() async => client.close());

  group('RpcPipelineRunRepository step runs', () {
    test('insertStepRun forwards the mapped step-run DTO', () async {
      final step = PipelineStepRun(
        id: 'sr9',
        pipelineRunId: 'pr1',
        stepId: 'fetch_context',
        status: PipelineStepStatus.running,
        inputJson: '{"k":"v"}',
        outputJson: '{"ok":true}',
        channelId: 'c1',
        errorMessage: null,
        branchIndex: 2,
        attemptCount: 3,
        startedAt: DateTime.utc(2026, 7, 1, 9, 0, 0),
        finishedAt: DateTime.utc(2026, 7, 1, 9, 30, 0),
      );
      await RpcPipelineRunRepository(client).insertStepRun(step);
      final call = host.lastCall('pipeline_run.insertStepRun')!;
      final dto = call.args['step_run'] as Map;
      expect(dto['id'], 'sr9');
      expect(dto['pipeline_run_id'], 'pr1');
      expect(dto['step_id'], 'fetch_context');
      expect(dto['status'], 'running');
      expect(dto['input_json'], '{"k":"v"}');
      expect(dto['output_json'], '{"ok":true}');
      expect(dto['channel_id'], 'c1');
      expect(dto['branch_index'], 2);
      expect(dto['attempt_count'], 3);
      expect(dto['started_at'], step.startedAt.toIso8601String());
      expect(dto['finished_at'], step.finishedAt!.toIso8601String());
    });

    test('insertStepRun emits a null finished_at when absent', () async {
      final step = PipelineStepRun(
        id: 'sr9',
        pipelineRunId: 'pr1',
        stepId: 's1',
        status: PipelineStepStatus.running,
        startedAt: DateTime.utc(2026, 7, 1),
      );
      await RpcPipelineRunRepository(client).insertStepRun(step);
      final dto =
          host.lastCall('pipeline_run.insertStepRun')!.args['step_run'] as Map;
      expect(dto['finished_at'], isNull);
    });

    test(
      'updateStepRun forwards the workspace + finished_at as an ISO string',
      () async {
        final ts = DateTime.utc(2026, 7, 1, 10);
        await RpcPipelineRunRepository(client).updateStepRun(
          _workspaceId,
          'sr9',
          status: PipelineStepStatus.completed,
          finishedAt: ts,
        );
        final call = host.lastCall('pipeline_run.updateStepRun')!;
        expect(call.args['workspace_id'], _workspaceId);
        expect(call.args['step_run_id'], 'sr9');
        expect(call.args['finished_at'], ts.toIso8601String());
        expect(call.args['status'], 'completed');
      },
    );

    test('updateStepRun omits finished_at when absent', () async {
      await RpcPipelineRunRepository(client).updateStepRun(
        _workspaceId,
        'sr9',
        status: PipelineStepStatus.failed,
        errorMessage: 'boom',
        errorStackTrace: 'trace',
      );
      final args = host.lastCall('pipeline_run.updateStepRun')!.args;
      expect(args.containsKey('finished_at'), isFalse);
      expect(args['workspace_id'], _workspaceId);
      expect(args['error_message'], 'boom');
      expect(args['error_stack_trace'], 'trace');
    });
  });

  group('RpcPipelineRunRepository getRun error handling', () {
    test('returns null when the host reports notFound', () async {
      host.errorCodes['pipeline_run.getRun'] = RpcErrorCodes.notFound;
      expect(await RpcPipelineRunRepository(client).getRun('missing'), isNull);
    });

    test('rethrows a non-notFound RPC error', () async {
      host.errorCodes['pipeline_run.getRun'] = RpcErrorCodes.internalError;
      expect(
        () => RpcPipelineRunRepository(client).getRun('x'),
        throwsA(isA<RemoteRpcException>()),
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
  final Map<String, Map<String, dynamic>> callResults = {};
  final Map<String, int> errorCodes = {};

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
