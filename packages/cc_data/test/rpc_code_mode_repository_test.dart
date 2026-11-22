import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/code_mode/domain/entities/code_execution.dart';
import 'package:cc_domain/features/code_mode/domain/entities/code_execution_call.dart';
import 'package:cc_domain/features/code_mode/domain/ports/code_execution_repository.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_execution_status.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode_limits.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:test/test.dart';

/// Exercises [RpcCodeModeRepository]: what it sends for each `codeMode.*`
/// op and how it reads the answers.
void main() {
  late _Host host;
  late RemoteRpcClient client;
  late RpcCodeModeRepository repo;

  final started = DateTime.utc(2026, 11, 17, 9, 30);
  final execution = CodeExecution(
    id: CodeExecution.idFor(runId: 'run-1', toolCallId: 'call_1#2'),
    runId: 'run-1',
    toolCallId: 'call_1#2',
    surface: CodeExecutionSurface.harness,
    startedAt: started,
    durationMs: 120,
    status: CodeExecutionStatus.completed,
    sourceHash: 'ab' * 32,
    sourceBytes: 20,
    limits: CodeModeLimits.defaults,
    spaceId: 'space-1',
    description: 'count the tests',
  );

  setUp(() {
    final (server, clientChannel) = InProcessRpcChannel.pair();
    host = _Host(server);
    client = RemoteRpcClient(clientChannel)..start();
    repo = RpcCodeModeRepository(client);
  });

  tearDown(() async => client.close());

  test('status reads the workspace answer', () async {
    host.results['codeMode.status'] = {
      'status': CodeModeStatusDto(
        available: false,
        reason: 'lockdown is partial',
        limits: CodeModeLimits.defaults,
        limitOverrides: const {},
        runnerVersion: 'cc_codemode 0.1.0',
        maxProcesses: 8,
        maxParkedProcesses: 32,
        maxWorkspaceProcesses: 6,
        maxHeapBytes: 512 * 1024 * 1024,
      ).toJson(),
    };
    final status = await repo.status('ws-1');
    expect(status.available, isFalse);
    expect(status.reason, 'lockdown is partial');
    expect(status.maxProcesses, 8);
    expect(status.maxParkedProcesses, 32);
    expect(status.maxWorkspaceProcesses, 6);
    expect(status.maxHeapBytes, 512 * 1024 * 1024);
    expect(host.last('codeMode.status'), {'workspace_id': 'ws-1'});
  });

  test('a malformed status never reads as usable', () async {
    host.results['codeMode.status'] = {
      'status': {'available': 'yes', 'limits': 'many'},
    };
    final status = await repo.status('ws-1');
    expect(status.available, isFalse);
    expect(status.limits, CodeModeLimits.defaults);
  });

  test('a limits write names the key and sends the overrides', () async {
    await repo.setWorkspaceLimits('ws-1', {'wall_clock_ms': 5000});
    expect(host.last('codeMode.setWorkspaceSetting'), {
      'workspace_id': 'ws-1',
      'key': 'code_mode_limits',
      'value': {'wall_clock_ms': 5000},
    });
  });

  test('a refused write surfaces its kind', () async {
    host.errors['codeMode.setWorkspaceSetting'] = (
      code: RpcErrorCodes.validation,
      kind: 'code_mode_limit_out_of_range',
    );
    await expectLater(
      repo.setWorkspaceLimits('ws-1', {'wall_clock_ms': 1}),
      throwsA(
        isA<RemoteRpcException>()
            .having((e) => e.code, 'code', RpcErrorCodes.validation)
            .having(
              (e) => (e.data as Map?)?['kind'],
              'kind',
              'code_mode_limit_out_of_range',
            ),
      ),
    );
  });

  test('list sends every filter and reads the page', () async {
    host.results['codeMode.listExecutions'] = CodeExecutionPageDto(
      items: [execution],
      nextCursor: 'opaque-cursor',
    ).toJson();
    final page = await repo.listExecutions(
      'ws-1',
      CodeExecutionQuery(
        cursor: 'c0',
        limit: 25,
        runId: 'run-1',
        toolCallId: 'toolu_1',
        conversationId: 'conv-1',
        agentId: 'agent-1',
        spaceId: 'space-1',
        statuses: {CodeExecutionStatus.timedOut},
        surface: CodeExecutionSurface.mcp,
        since: started,
        until: started.add(const Duration(hours: 1)),
      ),
    );
    expect(page.items.single, execution);
    expect(page.nextCursor, 'opaque-cursor');
    expect(host.last('codeMode.listExecutions'), {
      'workspace_id': 'ws-1',
      'cursor': 'c0',
      'limit': 25,
      'run_id': 'run-1',
      'tool_call_id': 'toolu_1',
      'conversation_id': 'conv-1',
      'agent_id': 'agent-1',
      'space_id': 'space-1',
      'statuses': ['timed_out'],
      'surface': 'mcp',
      'since': '2026-11-17T09:30:00.000Z',
      'until': '2026-11-17T10:30:00.000Z',
    });

    await repo.listExecutions('ws-1', CodeExecutionQuery());
    expect(host.last('codeMode.listExecutions'), {
      'workspace_id': 'ws-1',
      'limit': 50,
    });
  });

  test('get sends the id untouched and reads the detail', () async {
    host.results['codeMode.getExecution'] = {
      'execution': CodeExecutionDetailDto(
        execution: execution,
        payload: CodeExecutionPayload(
          executionId: execution.id,
          source: 'return 1;',
          output: '1',
          console: '',
        ),
        calls: [
          CodeExecutionCall(
            executionId: execution.id,
            sequence: 1,
            toolCallId: CodeExecutionCall.nestedToolCallId('call_1#2', 1),
            toolName: 'read',
            startOffsetMs: 1,
            durationMs: 2,
            status: NestedCallStatus.completed,
            approvalWaitMs: 0,
            argumentBytes: 4,
            resultBytes: 8,
            argumentsJson: '{}',
          ),
        ],
      ).toJson(),
    };
    final detail = await repo.getExecution('ws-1', execution.id);
    expect(detail!.execution, execution);
    expect(detail.payload!.source, 'return 1;');
    expect(detail.calls.single.toolName, 'read');
    expect(host.last('codeMode.getExecution'), {
      'workspace_id': 'ws-1',
      'id': 'run-1/call_1#2',
    });
  });

  test('an id the workspace does not have reads as null', () async {
    host.errors['codeMode.getExecution'] = (
      code: RpcErrorCodes.notFound,
      kind: null,
    );
    expect(await repo.getExecution('ws-1', 'run-9/call_9'), isNull);

    host.errors['codeMode.getExecution'] = (
      code: RpcErrorCodes.unauthorized,
      kind: 'space_read_refused',
    );
    await expectLater(
      repo.getExecution('ws-1', 'run-9/call_9'),
      throwsA(isA<RemoteRpcException>()),
    );
  });
}

/// A server that answers `repo/call` from [results] or [errors].
class _Host {
  _Host(this.channel) {
    channel.incoming.listen(_onFrame);
  }

  final RemoteRpcChannelPort channel;
  final List<({String op, Map<String, dynamic> args})> calls = [];
  final Map<String, Map<String, dynamic>> results = {};
  final Map<String, ({int code, String? kind})> errors = {};

  Map<String, dynamic>? last(String op) =>
      calls.lastWhere((c) => c.op == op).args;

  void _onFrame(Map<String, dynamic> frame) {
    final id = frame['id'];
    final method = frame['method'] as String?;
    final params = (frame['params'] as Map?)?.cast<String, dynamic>() ?? {};
    switch (method) {
      case 'initialize':
        _send({
          'id': id,
          'result': {'capabilities': <String, dynamic>{}},
        });
      case RpcMethods.repoCall:
        final op = params['op'] as String;
        calls.add((
          op: op,
          args: (params['args'] as Map?)?.cast<String, dynamic>() ?? {},
        ));
        if (errors[op] case final error?) {
          _send({
            'id': id,
            'error': {
              'code': error.code,
              'message': 'refused',
              if (error.kind != null) 'data': {'kind': error.kind},
            },
          });
          return;
        }
        _send({
          'id': id,
          'result': {'op': op, 'data': results[op] ?? <String, dynamic>{}},
        });
      default:
        _send({'id': id, 'result': <String, dynamic>{}});
    }
  }

  void _send(Map<String, dynamic> frame) =>
      channel.send({'jsonrpc': '2.0', ...frame});
}
