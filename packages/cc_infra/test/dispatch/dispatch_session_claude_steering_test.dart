import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/events/agent_events.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/ports/sandbox_port.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/domain/value_objects/agent_skills.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_backend.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_event.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_handle.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_spec.dart';
import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_process_event.dart';
import 'package:cc_domain/features/dispatch/domain/entities/wake.dart';
import 'package:cc_domain/features/dispatch/domain/ports/agent_backend.dart';
import 'package:cc_domain/features/dispatch/domain/services/wake_admission.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_commit_identity.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/run_end_reason.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_values.dart';
import 'package:cc_domain/features/model_routing/domain/entities/model_info.dart';
import 'package:cc_domain/features/sandboxing/domain/host_execution_posture.dart';
import 'package:cc_harness/context.dart' show ToolCallForms;
import 'package:cc_harness/loop.dart';
import 'package:cc_infra/src/dispatch/backends/cli_backends.dart';
import 'package:cc_infra/src/dispatch/dispatch_session.dart';
import 'package:cc_infra/src/dispatch/host_execution_gate.dart';
import 'package:cc_infra/src/dispatch/steering_session_view.dart';
import 'package:cc_infra/src/dispatch/wake_queue_service.dart';
import 'package:test/test.dart';

import '../helpers/windows_safe_delete.dart';
import 'fake_wake_repository.dart';

/// Pins the `claude -p` steering lane: stdin stays open as stream-json input
/// for the turn, queued messages are written to it as they arrive, and the
/// turn's `result` closes it so the process can exit.
///
/// A stand-in `claude`: it reads stdin as stream-json user messages, hands
/// each to [onMessage], and exits once stdin closes — what the real CLI does.
class _ScriptedClaude implements SandboxPort {
  /// Each user message the process read, in order.
  final List<String> received = [];

  /// Called with every user message the process reads.
  void Function(String text)? onMessage;

  /// Called once stdin closes, before the process exits.
  void Function()? onStdinClosed;

  /// Called with every control request's subtype (`interrupt`, …).
  void Function(String subtype)? onControl;

  /// The argv the process was launched with.
  List<String> argv = const [];

  StreamController<SandboxEvent>? _events;

  @override
  SandboxBackend get backend => SandboxBackend.none;

  @override
  Stream<SandboxEvent> events(SandboxHandle handle) {
    // ignore: close_sinks
    final controller = StreamController<SandboxEvent>.broadcast();
    _events = controller;
    return controller.stream;
  }

  /// Writes one NDJSON line to the process's stdout.
  void emit(String line) =>
      _events?.add(SandboxEvent(type: SandboxEventType.stdout, content: line));

  /// Ends the running process, the way a kill does.
  void exit() {
    final running = _running;
    if (running != null && !running.isCompleted) {
      running.complete();
    }
  }

  Completer<void>? _running;

  @override
  Future<void> destroy(SandboxHandle handle) async => exit();

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
    this.argv = argv;
    expect(stdinInput, isNull, reason: 'the prompt rides the stream');
    final closed = _running = Completer<void>();
    stdinStream!.listen(
      (chunk) {
        expect(chunk, endsWith('\n'));
        final frame = jsonDecode(chunk) as Map;
        if (frame['type'] == 'control_request') {
          onControl?.call((frame['request'] as Map)['subtype'] as String);
          return;
        }
        final message = frame['message'] as Map;
        final text = message['content'] as String;
        received.add(text);
        onMessage?.call(text);
      },
      onDone: () {
        onStdinClosed?.call();
        exit();
      },
    );
    await closed.future;
    return 0;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

String _result({bool isError = false, double? costUsd}) => jsonEncode({
  'type': 'result',
  'is_error': isError,
  'result': isError ? 'overloaded' : 'ok',
  'total_cost_usd': ?costUsd,
});

/// One running row that takes the terminal write, the way the real store
/// does (a cost write only when asked).
class _OneRunLog implements AgentRunLogRepository {
  AgentRunLog row = AgentRunLog(
    id: 'run-1',
    agentId: 'agent-1',
    workspaceId: 'ws-1',
    conversationId: 'conv-1',
    spaceId: 'space-1',
    startedAt: DateTime.utc(2026, 7, 1),
    status: RunStatus.running,
  );

  @override
  Future<AgentRunLog?> getById(String workspaceId, String id) async =>
      id == row.id ? row : null;

  @override
  Future<bool> completeIfActive(
    AgentRunLog completed, {
    bool writeCost = true,
  }) async {
    if (completed.id != row.id || row.completedAt != null) {
      return false;
    }
    row = row.copyWith(
      status: completed.status,
      completedAt: completed.completedAt,
      endReason: completed.endReason,
      cost: writeCost ? completed.cost : row.cost,
    );
    return true;
  }

  @override
  Future<bool> updateRuntime(
    String workspaceId,
    String runId, {
    int? pid,
    bool markRunning = false,
    String? logPath,
    String? contextSnapshotJson,
    DateTime? lastOutputAt,
    RunLiveness? liveness,
    RunErrorFamily? errorFamily,
    String? summary,
    String? modelId,
    String? effort,
    String? taskFamily,
  }) async => runId == row.id && row.completedAt == null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UnusedAgentRepo implements AgentRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late Directory temp;

  setUp(() {
    temp = Directory.systemTemp.createTempSync('cc_claude_steer_');
  });

  tearDown(() => deleteDirBestEffort(temp));

  DispatchSession buildSession(
    _ScriptedClaude sandbox, {
    int? costCapMicros,
    ModelCost? price,
    AgentRunLogRepository? runLogRepo,
    DomainEventBus? eventBus,
  }) => DispatchSession(
    freshHistory: false,
    readOnly: false,
    deps: SandboxDispatchDeps(
      hostExecution: const HostExecutionGate(
        posture: HostExecutionPosture.offByOwner,
      ),
      sandbox: sandbox,
      agentRepo: _UnusedAgentRepo(),
      runLogRepo: runLogRepo,
      eventBus: eventBus,
      resolveCommitIdentity: (_, {workspaceId, runLogId, forge}) async =>
          AgentCommitIdentity.person((
            name: 'Test User',
            email: 'test@example.test',
          )),
      backendRegistry: BackendRegistry({'claude': const ClaudeCliBackend()}),
      modelResolver: price == null
          ? null
          : (id) => ModelInfo(
              id: id,
              providerId: 'anthropic',
              name: id,
              cost: price,
            ),
    ),
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
    agentDirHostPath: temp.path,
    modelId: null,
    callerEnv: const {},
    agentId: null,
    workspaceId: 'ws-1',
    conversationId: 'conv-1',
    runLogId: 'run-1',
    mode: Mode.chat,
    resolveBinary: (name) async => '/usr/local/bin/$name',
    costCapMicros: costCapMicros,
  );

  test('the prompt is the first stream-json message on stdin', () async {
    final sandbox = _ScriptedClaude();
    final session = buildSession(sandbox);
    sandbox.onMessage = (_) => sandbox.emit(_result());
    await session.run();
    expect(sandbox.argv.join(' '), contains('--input-format stream-json'));
    expect(sandbox.received, ['hello']);
  });

  test('a message steered mid-turn reaches the running process, and the '
      "turn's result closes stdin", () async {
    final sandbox = _ScriptedClaude();
    final session = buildSession(sandbox);
    bool? acceptedAtStart;
    session.onHarnessStarted = () => acceptedAtStart = session.acceptsSteering;
    bool? steered;
    bool? acceptsAfterResult;
    sandbox
      ..onMessage = (text) {
        if (text == 'hello') {
          steered = session.steer('nudge', source: null);
        } else if (text == 'nudge') {
          sandbox.emit(_result());
        }
      }
      // Between the result and the exit: steering must already be refused.
      ..onStdinClosed = () => acceptsAfterResult = session.acceptsSteering;

    await session.run();

    expect(acceptedAtStart, isTrue);
    expect(steered, isTrue);
    expect(sandbox.received, ['hello', 'nudge']);
    expect(acceptsAfterResult, isFalse);
    expect(session.steeringQueue.isEmpty, isTrue);
    // The run is over: what is queued now converts at run end instead.
    expect(session.steer('too late', source: null), isFalse);
  });

  test('steering is never a command: a slash-leading line, from anyone, '
      'reaches Claude Code fenced', () async {
    const fenced = 'A message, not a command:\n';
    final sandbox = _ScriptedClaude();
    final session = buildSession(sandbox);
    sandbox.onMessage = (text) {
      if (text == 'hello') {
        session
          ..steer('/compact', source: null)
          ..steer('/skill:lint now', source: 'rig:r1')
          ..steer('/plan', source: null, channel: SteeringChannel.followUp);
      } else if (text == '$fenced/skill:lint now') {
        sandbox.emit(_result());
      } else if (text == '$fenced/plan') {
        sandbox.emit(_result());
      }
    };
    await session.run();
    expect(sandbox.received, [
      'hello',
      '$fenced/compact',
      '$fenced/skill:lint now',
      '$fenced/plan',
    ]);
  });

  test('steering reports every message it writes through onDrained', () async {
    final sandbox = _ScriptedClaude();
    final session = buildSession(sandbox);
    final drained = <String?>[];
    session.onHarnessStarted = () {
      final queue = session.steeringQueue;
      queue.onDrained = (m) {
        drained.add(m.ref);
      };
      queue.pushSteering('card', ref: 'row-1');
    };
    sandbox.onMessage = (text) {
      if (text == 'card') {
        sandbox.emit(_result());
      }
    };

    await session.run();

    expect(sandbox.received, ['hello', 'card']);
    expect(drained, ['row-1']);
  });

  test('a follow-up waits for the result, then starts the next turn on the '
      'same process', () async {
    final sandbox = _ScriptedClaude();
    final session = buildSession(sandbox);
    int? readBeforeResult;
    sandbox.onMessage = (text) {
      if (text == 'hello') {
        session.steer(
          'afterwards',
          source: null,
          channel: SteeringChannel.followUp,
        );
        unawaited(
          Future<void>.delayed(Duration.zero).then((_) {
            readBeforeResult = sandbox.received.length;
            sandbox.emit(_result());
          }),
        );
      } else if (text == 'afterwards') {
        sandbox.emit(_result());
      }
    };

    await session.run();

    expect(readBeforeResult, 1, reason: 'held until the turn ended');
    expect(sandbox.received, ['hello', 'afterwards']);
  });

  test('a failed turn closes stdin even with a follow-up queued', () async {
    final sandbox = _ScriptedClaude();
    final session = buildSession(sandbox);
    sandbox.onMessage = (text) {
      session.steer(
        'afterwards',
        source: null,
        channel: SteeringChannel.followUp,
      );
      sandbox.emit(_result(isError: true));
    };

    await session.run();

    expect(sandbox.received, ['hello']);
    // Left for the run-end conversion, not dropped.
    expect(session.steeringQueue.hasFollowUp, isTrue);
  });

  group('cost cap', () {
    Future<List<AgentProcessEvent>> runCollecting(
      DispatchSession session,
    ) async {
      final events = <AgentProcessEvent>[];
      final sub = session.controller.stream.listen(events.add);
      await session.run();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await sub.cancel();
      return events;
    }

    test('a turn that reaches the cap starts nothing more and the run ends '
        'with budget', () async {
      final sandbox = _ScriptedClaude();
      final session = buildSession(sandbox, costCapMicros: 200000);
      sandbox.onMessage = (text) {
        session.steer(
          'afterwards',
          source: null,
          channel: SteeringChannel.followUp,
        );
        sandbox.emit(_result(costUsd: 0.25));
      };

      final events = await runCollecting(session);

      expect(sandbox.received, ['hello']);
      expect(session.steeringQueue.hasFollowUp, isTrue);
      expect(
        events.whereType<DoneEvent>().single.endReason,
        RunEndReason.budget,
      );
      expect(
        events.whereType<DebugEvent>().map((e) => e.content).join('\n'),
        contains('cost cap'),
      );
    });

    test(
      'at 90% of the cap the next turn opens with the wrap-up steer',
      () async {
        final sandbox = _ScriptedClaude();
        final session = buildSession(sandbox, costCapMicros: 270000);
        sandbox.onMessage = (text) {
          if (text == 'hello') {
            session.steer(
              'afterwards',
              source: null,
              channel: SteeringChannel.followUp,
            );
            sandbox.emit(_result(costUsd: 0.25));
          } else if (text == 'afterwards') {
            sandbox.emit(_result(costUsd: 0.25));
          }
        };

        final events = await runCollecting(session);

        expect(sandbox.received, ['hello', kRunCostWrapUpSteer, 'afterwards']);
        expect(events.whereType<DoneEvent>().single.endReason, isNull);
      },
    );

    test('one long turn is steered at 90% of the cap and interrupted at the '
        "cap, from its calls' streamed usage at the model's price", () async {
      const price = ModelCost(input: 3, output: 15);
      final prompt = price.estimateMicros(inputTokens: 90000);
      // The call's prompt alone is exactly 90% of the cap.
      final cap = prompt * 10 ~/ 9;
      final sandbox = _ScriptedClaude();
      final session = buildSession(sandbox, costCapMicros: cap, price: price);
      final controls = <String>[];
      String streamEvent(Map<String, Object?> event) =>
          jsonEncode({'type': 'stream_event', 'event': event});
      sandbox
        ..onMessage = (text) {
          if (text == 'hello') {
            sandbox
              ..emit(
                jsonEncode({
                  'type': 'system',
                  'subtype': 'init',
                  'model': 'claude-test',
                  'session_id': 'native-1',
                }),
              )
              ..emit(
                streamEvent({
                  'type': 'message_start',
                  'message': {
                    'usage': {'input_tokens': 90000, 'output_tokens': 1},
                  },
                }),
              );
          } else if (text == kRunCostWrapUpSteer) {
            // The same call keeps streaming output past the cap.
            sandbox.emit(
              streamEvent({
                'type': 'message_delta',
                'usage': {'output_tokens': 50000},
              }),
            );
          }
        }
        ..onControl = (subtype) {
          controls.add(subtype);
          if (subtype == 'interrupt') {
            sandbox.emit(_result(isError: true, costUsd: 0.4));
          }
        };

      final events = await runCollecting(session);

      expect(sandbox.received, ['hello', kRunCostWrapUpSteer]);
      expect(controls, contains('interrupt'));
      expect(
        events.whereType<DoneEvent>().single.endReason,
        RunEndReason.budget,
      );
    });

    test('a stopped run settles with what its turns reported, though its row '
        'held no cost', () async {
      final bus = DomainEventBus();
      addTearDown(bus.dispose);
      final settled = <AgentRunSettled>[];
      bus.on<AgentRunSettled>().listen(settled.add);
      final runLogs = _OneRunLog();
      final sandbox = _ScriptedClaude();
      final session = buildSession(sandbox, runLogRepo: runLogs, eventBus: bus);
      final secondTurn = Completer<void>();
      sandbox
        ..onMessage = (text) {
          if (text == 'hello') {
            session.steer(
              'afterwards',
              source: null,
              channel: SteeringChannel.followUp,
            );
            sandbox.emit(_result(costUsd: 0.12));
          } else if (text == 'afterwards') {
            secondTurn.complete();
          }
        }
        ..onControl = (subtype) {
          if (subtype == 'interrupt') {
            sandbox
              ..emit(_result(isError: true))
              ..exit();
          }
        };

      final running = session.run();
      await secondTurn.future.timeout(const Duration(seconds: 5));
      await session.terminate();
      await running.timeout(const Duration(seconds: 5));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(settled.single.endReason, RunEndReason.stoppedByUser);
      expect(settled.single.costMicros, 120000);
      expect(runLogs.row.cost.costMicros, 120000);
    });

    test('without a cap the cost never stops a turn', () async {
      final sandbox = _ScriptedClaude();
      final session = buildSession(sandbox);
      sandbox.onMessage = (text) {
        if (text == 'hello') {
          session.steer(
            'afterwards',
            source: null,
            channel: SteeringChannel.followUp,
          );
        }
        sandbox.emit(_result(costUsd: 50));
      };

      final events = await runCollecting(session);

      expect(sandbox.received, ['hello', 'afterwards']);
      expect(events.whereType<DoneEvent>().single.endReason, isNull);
    });
  });

  // The wake queue's lanes reach a live `claude -p` run through the same
  // stdin pump a person's steering uses: an aside at the next tool boundary,
  // a follow-up once the turn ends; each is delivered when written.
  group('wakes on the Claude stdin pump', () {
    for (final lane in WakeLane.values) {
      test('a ${lane.name} wake is written to stdin and delivered', () async {
        final sandbox = _ScriptedClaude();
        final session = buildSession(sandbox);
        final wakes = FakeWakeRepository();
        final ledger = FakeWakeRunLedger();
        final view = _WakeView(session);
        final now = DateTime.utc(2026, 7, 1, 9);
        final queue = WakeQueueService(
          wakes: wakes,
          runLedger: ledger,
          clock: () => now,
          timerFactory: (_, _) => Timer(const Duration(days: 1), () {}),
          nonce: () => 'nonce1',
          ports: WakeQueuePorts(
            workspaceActive: (_) async => true,
            conversationSpace: (_, _) async => 'space-1',
            agent: (_, id) async => Agent(
              id: id,
              name: 'Builder',
              title: 't',
              agentMdPath: '/tmp/a.md',
              workspaceId: 'ws-1',
              skills: AgentSkills(const []),
              createdAt: now,
            ),
            isMember: (_, _) async => true,
            takenOver: (_, _) async => false,
            budgetBlocked: (_, _) async => false,
            liveSessions: (_) => [view],
            hasLiveRun: (_, _, _) async => true,
            dispatch: (_) async => fail('a live run takes the wake'),
            postSystemRow:
                ({
                  required String workspaceId,
                  required String spaceId,
                  required String conversationId,
                  required String content,
                  required Map<String, Object?> metadata,
                }) async {},
          ),
        );
        // Nothing is delivered before the queue starts.
        await queue.start();
        WakeReceipt? receipt;
        session.onHarnessStarted = () {
          queue.handleHarnessStarted(view);
          unawaited(
            queue
                .enqueueAndDeliver(
                  Wake(
                    id: 'wk-1',
                    workspaceId: 'ws-1',
                    spaceId: 'space-1',
                    conversationId: 'conv-1',
                    agentId: 'agent-1',
                    reason: WakeReason.peerMessage,
                    lane: lane,
                    payload: 'look at the test',
                    dedupKey: 'k',
                    notBefore: now,
                    createdAt: now,
                  ),
                )
                .then((r) => receipt = r),
          );
        };
        sandbox.onMessage = (text) {
          if (text == 'hello') {
            if (lane == WakeLane.followUp) {
              // The follow-up waits for the turn to end.
              unawaited(
                Future<void>.delayed(
                  const Duration(milliseconds: 20),
                ).then((_) => sandbox.emit(_result())),
              );
            }
            return;
          }
          sandbox.emit(_result());
        };

        await session.run();
        await pumpEventQueue();

        expect(receipt, isA<WakePushed>());
        expect(sandbox.received, hasLength(2));
        expect(sandbox.received.last, startsWith('## Why you were woken\n'));
        expect(
          sandbox.received.last,
          contains('<wake-data id="nonce1">look at the test'),
        );
        final row = (await wakes.getById('ws-1', 'wk-1'))!;
        expect(row.state, WakeState.delivered);
        expect(row.deliveredRunId, 'run-1');
        expect(ledger.runs['ws-1']!['run-1'], ['wk-1']);
        await queue.stop();
      });
    }
  });
}

/// The session as the wake queue sees it, with the agent the test's
/// session leaves unset (an agent id would make it read the agent store).
class _WakeView implements SteeringSessionView {
  _WakeView(this._session);

  final DispatchSession _session;

  @override
  bool get acceptsSteering => _session.acceptsSteering;
  @override
  String? get workspaceId => _session.workspaceId;
  @override
  String? get conversationId => _session.conversationId;
  @override
  String? get agentId => 'agent-1';
  @override
  String? get spaceId => _session.spaceId;
  @override
  String? get runLogId => _session.runLogId;
  @override
  SteeringQueue get steeringQueue => _session.steeringQueue;

  @override
  ToolCallForms get toolForms => _session.toolForms;
  @override
  String? get requestedByUserId => _session.requestedByUserId;
  @override
  bool get readOnly => _session.readOnly;
  @override
  bool get freshHistory => _session.freshHistory;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
