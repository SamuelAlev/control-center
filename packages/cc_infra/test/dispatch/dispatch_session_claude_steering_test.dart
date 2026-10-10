import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/core/domain/ports/credential_broker_port.dart';
import 'package:cc_domain/core/domain/ports/sandbox_port.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_backend.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_event.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_handle.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_spec.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_process_event.dart';
import 'package:cc_domain/features/dispatch/domain/ports/agent_backend.dart';
import 'package:cc_harness/loop.dart';
import 'package:cc_infra/src/dispatch/backends/cli_backends.dart';
import 'package:cc_infra/src/dispatch/dispatch_session.dart';
import 'package:test/test.dart';

import '../helpers/windows_safe_delete.dart';

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
    final closed = Completer<void>();
    stdinStream!.listen(
      (chunk) {
        expect(chunk, endsWith('\n'));
        final message = (jsonDecode(chunk) as Map)['message'] as Map;
        final text = message['content'] as String;
        received.add(text);
        onMessage?.call(text);
      },
      onDone: () {
        onStdinClosed?.call();
        closed.complete();
      },
    );
    await closed.future;
    return 0;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

String _result({bool isError = false}) => jsonEncode({
  'type': 'result',
  'is_error': isError,
  'result': isError ? 'overloaded' : 'ok',
});

class _NoopBroker implements CredentialBrokerPort {
  @override
  Future<ScopedCredentials> mint({
    required String conversationId,
    required ForgeTokenScope scope,
    String? repoOwner,
    String? repoName,
    String? actingUserId,
    String? workspaceId,
  }) async => const ScopedCredentials(handle: 'h', environment: {});

  @override
  Future<void> revoke(String handle) async {}
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

  DispatchSession buildSession(_ScriptedClaude sandbox) => DispatchSession(
    deps: SandboxDispatchDeps(
      sandbox: sandbox,
      broker: _NoopBroker(),
      agentRepo: _UnusedAgentRepo(),
      runLogRepo: null,
      eventBus: null,
      backendRegistry: BackendRegistry({'claude': const ClaudeCliBackend()}),
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
          steered = session.steer('nudge');
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
    expect(session.steer('too late'), isFalse);
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
        session.steer('afterwards', channel: SteeringChannel.followUp);
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
      session.steer('afterwards', channel: SteeringChannel.followUp);
      sandbox.emit(_result(isError: true));
    };

    await session.run();

    expect(sandbox.received, ['hello']);
    // Left for the run-end conversion, not dropped.
    expect(session.steeringQueue.hasFollowUp, isTrue);
  });
}
