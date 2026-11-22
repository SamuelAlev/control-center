import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/core/domain/ports/sandbox_port.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/core/domain/value_objects/run_cost.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_backend.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_event.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_handle.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_spec.dart';
import 'package:cc_domain/core/domain/value_objects/usage_scope.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_process_event.dart';
import 'package:cc_domain/features/dispatch/domain/ports/agent_backend.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_commit_identity.dart';
import 'package:cc_domain/features/model_routing/domain/entities/model_info.dart';
import 'package:cc_domain/features/sandboxing/domain/host_execution_posture.dart';
import 'package:cc_infra/src/dispatch/backends/cli_backends.dart';
import 'package:cc_infra/src/dispatch/dispatch_session.dart';
import 'package:cc_infra/src/dispatch/host_execution_gate.dart';
import 'package:test/test.dart';

import '../helpers/windows_safe_delete.dart';

/// Replays scripted NDJSON per attempt, as `claude -p` would print it.
class _ScriptedSandbox implements SandboxPort {
  _ScriptedSandbox(this.stdoutPerAttempt);

  final List<List<String>> stdoutPerAttempt;
  var _attempt = 0;
  StreamController<SandboxEvent>? _current;

  @override
  SandboxBackend get backend => SandboxBackend.none;

  @override
  Stream<SandboxEvent> events(SandboxHandle handle) {
    // Lives for the dispatch, like the real sandbox's event stream.
    // ignore: close_sinks
    final controller = StreamController<SandboxEvent>.broadcast();
    _current = controller;
    return controller.stream;
  }

  @override
  Future<int> exec(
    SandboxHandle handle,
    List<String> argv, {
    Map<String, String>? env,
    String? workdir,
    Duration? timeout,
    void Function(int pid)? onPid,
    String? stdinInput,
    Stream<String>? stdinStream,
  }) async {
    final attempt = _attempt++;
    stdinStream?.listen((_) {});
    onPid?.call(4242);
    if (attempt < stdoutPerAttempt.length) {
      for (final line in stdoutPerAttempt[attempt]) {
        _current?.add(
          SandboxEvent(type: SandboxEventType.stdout, content: line),
        );
      }
      await Future<void>.delayed(Duration.zero);
    }
    _current?.add(const SandboxEvent(type: SandboxEventType.exit));
    return 0;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Records the run row's cost writes; the rest of the row is not under test.
class _CostRecordingRunLogs implements AgentRunLogRepository {
  final List<RunCost> costs = [];

  @override
  Future<void> updateCost(
    String workspaceId,
    String runId,
    RunCost cost,
  ) async {
    costs.add(cost);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #updateRuntime) {
      return Future<bool>.value(true);
    }
    if (invocation.memberName == #getById) {
      return Future<Null>.value();
    }
    return super.noSuchMethod(invocation);
  }
}

class _UnusedAgentRepo implements AgentRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _model = 'claude-opus-5-5';

/// Three micro-dollars per uncached input token, one per cache read, four
/// per cache write and fifteen per output token.
const _price = ModelCost(input: 3, output: 15, cacheRead: 1, cacheWrite: 4);

int _micros({int input = 0, int read = 0, int write = 0, int output = 0}) =>
    3 * input + read + 4 * write + 15 * output;

String _init() => jsonEncode({
  'type': 'system',
  'subtype': 'init',
  'session_id': 'sess-1',
  'model': _model,
  'tools': ['Bash'],
  'mcp_servers': const [],
});

String _start(String id, {int input = 0, int read = 0, int write = 0}) =>
    jsonEncode({
      'type': 'stream_event',
      'event': {
        'type': 'message_start',
        'message': {
          'id': id,
          'model': _model,
          'usage': {
            'input_tokens': input,
            'cache_read_input_tokens': read,
            'cache_creation_input_tokens': write,
            'output_tokens': 1,
          },
        },
      },
    });

String _delta(int output) => jsonEncode({
  'type': 'stream_event',
  'event': {
    'type': 'message_delta',
    'usage': {'output_tokens': output},
  },
});

String _subagentToolCall(String id, {int read = 0, int output = 0}) =>
    jsonEncode({
      'type': 'assistant',
      'parent_tool_use_id': 'toolu_task',
      'message': {
        'id': id,
        'model': _model,
        'content': [
          {'type': 'tool_use', 'id': 'toolu_$id', 'name': 'Glob', 'input': {}},
        ],
        'usage': {'cache_read_input_tokens': read, 'output_tokens': output},
      },
    });

/// A successful `result` whose whole-tree `modelUsage` is [read] cache reads
/// and [output] output tokens, at [costUsd].
String _result({
  required int read,
  required int output,
  required double costUsd,
}) => jsonEncode({
  'type': 'result',
  'subtype': 'success',
  'is_error': false,
  'result': 'done',
  'session_id': 'sess-1',
  'total_cost_usd': costUsd,
  'usage': {'cache_read_input_tokens': read, 'output_tokens': output},
  'modelUsage': {
    _model: {
      'cacheReadInputTokens': read,
      'outputTokens': output,
      'costUSD': costUsd,
    },
  },
});

/// The crashed result `claude` sends with every counter zeroed.
String _zeroedCrash() => jsonEncode({
  'type': 'result',
  'subtype': 'error_during_execution',
  'is_error': true,
  'result': 'crashed',
  'total_cost_usd': 0,
  'usage': {
    'input_tokens': 0,
    'output_tokens': 0,
    'cache_read_input_tokens': 0,
    'cache_creation_input_tokens': 0,
  },
  'modelUsage': const {},
});

String _usageLimit() => jsonEncode({
  'type': 'result',
  'is_error': true,
  'result': 'Claude AI usage limit reached|1787601441',
});

typedef _Run = ({
  List<AgentProcessEvent> events,
  _CostRecordingRunLogs runLogs,
  int costWritesAtDone,
});

Future<_Run> _dispatch(
  List<List<String>> stdoutPerAttempt, {
  List<({String accountId, String configDir})> accounts = const [],
  String? claudeConfigDir,
}) async {
  final runLogs = _CostRecordingRunLogs();
  final deps = SandboxDispatchDeps(
    hostExecution: const HostExecutionGate(
      posture: HostExecutionPosture.offByOwner,
    ),
    sandbox: _ScriptedSandbox(stdoutPerAttempt),
    agentRepo: _UnusedAgentRepo(),
    runLogRepo: runLogs,
    eventBus: null,
    resolveCommitIdentity: (_, {workspaceId, runLogId, forge}) async =>
        AgentCommitIdentity.person((
          name: 'Test User',
          email: 'test@example.test',
        )),
    backendRegistry: BackendRegistry({'claude': const ClaudeCliBackend()}),
    modelResolver: (qualified) => qualified == 'anthropic/$_model'
        ? const ModelInfo(
            id: _model,
            providerId: 'anthropic',
            name: 'Opus',
            cost: _price,
          )
        : null,
  );
  final session = DispatchSession(
    freshHistory: false,
    readOnly: false,
    deps: deps,
    onResolveHandle:
        ({
          required String sessionId,
          required SandboxSpec spec,
          required void Function(AgentProcessEvent) emit,
        }) async => SandboxHandle(
          sessionId: sessionId,
          backend: SandboxBackend.none,
          state: SandboxState.warm,
        ),
    onScheduleCooldown: (_) {},
    dispatchId: 'd-claude',
    cliName: 'claude',
    prompt: 'hello',
    agentDirHostPath: Directory.systemTemp.path,
    modelId: null,
    callerEnv: const {},
    agentId: null,
    workspaceId: 'ws-1',
    conversationId: 'conv-1',
    runLogId: 'run-1',
    mode: Mode.chat,
    claudeConfigDir: claudeConfigDir,
    claudeAccounts: accounts,
    onClaudeAccountExhausted: ({required accountId, resetsAt}) async {},
    onClaudeAccountAuthFailed: ({required accountId, reason}) async {},
    resolveBinary: (name) async => '/usr/local/bin/$name',
  );
  var costWritesAtDone = -1;
  final events = <AgentProcessEvent>[];
  final done = Completer<void>();
  session.controller.stream.listen((e) {
    events.add(e);
    if (e is DoneEvent) {
      costWritesAtDone = runLogs.costs.length;
    }
  }, onDone: done.complete);
  await session.run();
  await done.future;
  return (events: events, runLogs: runLogs, costWritesAtDone: costWritesAtDone);
}

/// The run's last absolute usage report.
RunUsage _lastCumulative(List<AgentProcessEvent> events) => events
    .whereType<UsageEvent>()
    .lastWhere((e) => e.scope == UsageScope.runCumulative)
    .usage;

String _debug(List<AgentProcessEvent> events) =>
    events.whereType<DebugEvent>().map((e) => e.content).join('\n');

void main() {
  setUp(() {
    ClaudeCliBackend.cacheFor(
      '/usr/local/bin/claude',
      ClaudeCliCapabilities.baseline,
    );
  });

  // A process that dies mid-turn never sends its `result`, which used to be
  // the only usage report: the run recorded nothing for everything it spent.
  test(
    'calls a process streamed before dying without a result count',
    () async {
      final run = await _dispatch([
        [
          _init(),
          _start('m1', input: 2, read: 1000, write: 300),
          _delta(50),
          _subagentToolCall('s1', read: 400, output: 20),
          _start('m2', input: 2, read: 1350),
        ],
      ]);

      final usage = _lastCumulative(run.events);
      expect(usage.inputTokens, 4);
      expect(usage.cachedReadTokens, 1000 + 400 + 1350);
      expect(usage.cachedWriteTokens, 300);
      // m1's final output from its delta, s1's from its line, m2's first token.
      expect(usage.outputTokens, 50 + 20 + 1);
      expect(
        usage.costMicros,
        _micros(input: 2, read: 1000, write: 300, output: 50) +
            _micros(read: 400, output: 20) +
            _micros(input: 2, read: 1350, output: 1),
      );
      expect(
        _debug(run.events),
        contains('3 model calls ended without a result'),
      );

      // The row carries it, and no write lands after the run's terminal event.
      expect(run.runLogs.costs.last.cachedReadTokens, 2750);
      expect(run.runLogs.costs.last.costMicros, usage.costMicros);
      expect(run.costWritesAtDone, run.runLogs.costs.length);
    },
  );

  test('the running turn moves the row before its result lands', () async {
    final run = await _dispatch([
      [_init(), _start('m1', read: 500), _delta(10)],
    ]);
    // Written while the turn ran, not only at its end.
    expect(run.runLogs.costs.first.cachedReadTokens, 500);
  });

  test('a result replaces the estimate with what it reports', () async {
    final run = await _dispatch([
      [
        _init(),
        _start('m1', input: 2, read: 1000),
        _delta(50),
        _result(read: 1000, output: 50, costUsd: 0.25),
      ],
    ]);

    final usage = _lastCumulative(run.events);
    expect(usage.cachedReadTokens, 1000);
    expect(usage.outputTokens, 50);
    expect(usage.costMicros, 250000, reason: 'the reported cost, not ours');
    expect(_debug(run.events), isNot(contains('ended without a result')));
    expect(run.runLogs.costs.last.costMicros, 250000);
  });

  test('a zeroed crash result leaves its calls to be counted', () async {
    final run = await _dispatch([
      [_init(), _start('m1', read: 800), _delta(30), _zeroedCrash()],
    ]);

    final usage = _lastCumulative(run.events);
    expect(usage.cachedReadTokens, 800);
    expect(usage.outputTokens, 30);
    expect(usage.costMicros, _micros(read: 800, output: 30));
    expect(_debug(run.events), contains('1 model call ended without a result'));
  });

  // A partial result can report its cost without any token counters: the
  // turn's tokens stay counted from the stream, and its cost is counted once.
  test('a cost-only result keeps the streamed tokens, its cost once', () async {
    final run = await _dispatch([
      [
        _init(),
        _start('m1', read: 600),
        _delta(20),
        jsonEncode({
          'type': 'result',
          'subtype': 'success',
          'is_error': false,
          'result': 'done',
          'total_cost_usd': 0.1,
        }),
      ],
    ]);

    final usage = _lastCumulative(run.events);
    expect(usage.cachedReadTokens, 600);
    expect(usage.outputTokens, 20);
    expect(usage.costMicros, 100000, reason: 'the reported cost, once');
  });

  group('failover', () {
    late Directory temp;

    setUp(() => temp = Directory.systemTemp.createTempSync('cc_unreported_'));
    tearDown(() => deleteDirBestEffort(temp));

    ({String accountId, String configDir}) account(String id) {
      final dir = Directory('${temp.path}/claude-accounts/$id')
        ..createSync(recursive: true);
      File('${dir.path}/.credentials.json').writeAsStringSync('{}');
      return (accountId: id, configDir: dir.path);
    }

    // The attempt that hit the limit already spent a call; the next account's
    // reports must build on it rather than replace it.
    test('a spent attempt\'s streamed calls stay on the run', () async {
      final a = account('work');
      final b = account('personal');
      final run = await _dispatch(
        [
          [_init(), _start('m1', read: 700), _usageLimit()],
          [
            _init(),
            _start('m2', read: 900),
            _delta(40),
            _result(read: 900, output: 40, costUsd: 0.5),
          ],
        ],
        accounts: [a, b],
        claudeConfigDir: a.configDir,
      );

      final usage = _lastCumulative(run.events);
      expect(usage.cachedReadTokens, 700 + 900);
      expect(usage.outputTokens, 1 + 40);
      expect(usage.costMicros, _micros(read: 700, output: 1) + 500000);
    });
  });
}
