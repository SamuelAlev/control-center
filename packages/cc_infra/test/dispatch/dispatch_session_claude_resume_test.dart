import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/task_lifecycle_events.dart';
import 'package:cc_domain/core/domain/ports/credential_broker_port.dart';
import 'package:cc_domain/core/domain/ports/sandbox_port.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/value_objects/llm_call_purpose.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/core/domain/value_objects/run_cost.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_backend.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_event.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_handle.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_spec.dart';
import 'package:cc_domain/core/domain/value_objects/usage_scope.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_process_event.dart';
import 'package:cc_domain/features/dispatch/domain/ports/agent_backend.dart';
import 'package:cc_domain/features/dispatch/domain/prompts/prompt_builder.dart';
import 'package:cc_domain/features/observability/domain/run_stage.dart';
import 'package:cc_harness/loop.dart';
import 'package:cc_infra/src/dispatch/backends/cli_backends.dart';
import 'package:cc_infra/src/dispatch/dispatch_session.dart';
import 'package:cc_infra/src/sandboxing/claude_mcp_discovery_cache.dart';
import 'package:cc_infra/src/sandboxing/claude_native_session.dart';
import 'package:test/test.dart';

import '../helpers/windows_safe_delete.dart';

/// A stand-in `claude`: reads stdin as stream-json user messages, hands each to
/// [onMessage], and exits once stdin closes — what the real CLI does. Enough to
/// pin the LAUNCH PATH: the argv it was handed and the first message it read.
class _ScriptedClaude implements SandboxPort {
  /// Each user message the process read, in order.
  final List<String> received = [];

  /// Called with every user message the process reads.
  void Function(String text)? onMessage;

  /// The argv the process was launched with.
  List<String> argv = const [];

  /// The environment the process was launched with.
  Map<String, String>? env;

  Completer<void>? _closed;

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

  /// Ends the process without a `result` (a crash / interruption).
  void exitWithoutResult() => _closed?.complete();

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
    this.env = env;
    final closed = Completer<void>();
    _closed = closed;
    stdinStream!.listen(
      (chunk) {
        final message = (jsonDecode(chunk) as Map)['message'] as Map;
        received.add(message['content'] as String);
        onMessage?.call(message['content'] as String);
      },
      onDone: () {
        if (!closed.isCompleted) {
          closed.complete();
        }
      },
    );
    await closed.future;
    return 0;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

String _init(String sessionId) => jsonEncode({
  'type': 'system',
  'subtype': 'init',
  'session_id': sessionId,
  'model': 'claude-sonnet-4-5-20250929',
  'tools': ['Bash', 'mcp__cc__complete_ticket'],
  'mcp_servers': [
    {'name': 'cc', 'status': 'connected'},
  ],
});

String _result({
  double cost = 1.0,
  int input = 100,
  int output = 10,
  String sessionId = 'sess-A',
  Map<String, Object?>? modelUsage,
}) => jsonEncode({
  'type': 'result',
  'subtype': 'success',
  'session_id': sessionId,
  'usage': {
    'input_tokens': input,
    'output_tokens': output,
    'cache_read_input_tokens': 0,
    'cache_creation_input_tokens': 0,
  },
  'total_cost_usd': cost,
  'modelUsage':
      modelUsage ??
      {
        'claude-sonnet-4-5-20250929': {
          'inputTokens': input,
          'outputTokens': output,
          'cacheReadInputTokens': 0,
          'cacheCreationInputTokens': 0,
          'costUSD': cost,
        },
      },
});

class _NoopBroker implements CredentialBrokerPort {
  final revoked = <String>[];

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
  Future<void> revoke(String handle) async => revoked.add(handle);
}

class _UnusedAgentRepo implements AgentRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// One conversation entry, keyed exactly the way the real builder keys it: the
/// message kind + id + a digest of its rendered text, so an EDIT changes the
/// key and an untouched message keeps it.
PromptConversationEntry entry(
  String id,
  String text, {
  PromptConversationProvenance provenance = PromptConversationProvenance.other,
  String? runId,
}) => PromptConversationEntry(
  key: '$id#${PromptBuilder.promptRevisionOf(text)}',
  text: text,
  provenance: provenance,
  runId: runId,
);

/// Builds prompt parts the way the real preparation does.
AgentPromptParts partsOf(
  String userText, {
  String turnContext = '',
  String standing = 'standing brief',
  List<PromptConversationEntry> conversationEntries = const [],
  List<PromptTurnSection> turnSections = const [],
}) => AgentPromptParts(
  userText: userText,
  standing: standing,
  turnContext: turnContext,
  conversationContext: conversationEntries.map((e) => e.text).join('\n'),
  fullPrompt: userText,
  standingRevision: PromptBuilder.promptRevisionOf(standing),
  conversationEntries: conversationEntries,
  turnSections: turnSections,
);

/// A per-turn section keyed the way the builder keys it.
PromptTurnSection section(
  String label,
  String text, {
  bool alwaysDeliver = false,
}) => PromptTurnSection(
  key: 'turn:$label#${PromptBuilder.promptRevisionOf(text)}',
  text: text,
  alwaysDeliver: alwaysDeliver,
);

void main() {
  late Directory temp;

  setUp(() {
    temp = Directory.systemTemp.createTempSync('cc_claude_resume_');
    // Exercise the verified modern CLI: help advertises resume/effort, while
    // the separate version probe proves cumulative totals survive a resume.
    ClaudeCliBackend.cacheFor(
      '/usr/local/bin/claude',
      const ClaudeCliCapabilities(
        supportsEffort: true,
        supportsResume: true,
        supportsSessionId: true,
        restoresSessionTotals: true,
        version: '2.1.293',
      ),
    );
  });

  tearDown(() => deleteDirBestEffort(temp));

  DispatchSession buildSession(
    _ScriptedClaude sandbox, {
    required InMemoryClaudeNativeSessionStore store,
    String prompt = 'hello',
    AgentPromptParts? promptParts,
    bool claudeResumeReset = false,
    String? effortLevel,
    String conversationId = 'conv-1',
    String? claudeConfigDir,
    String agentDirHostPath = '/work/tree',
    DateTime? runStartedAt,
    bool creditAgent = true,
    bool hasGitIdentity = true,
    Object? attributionFailure,
    Object? identityFailure,
    _NoopBroker? broker,
    DomainEventBus? eventBus,
    Map<String, String> adapterEnv = const {},
    Map<String, String> callerEnv = const {},
    ClaudeMcpDiscoveryCachePolicy discoveryCache =
        ClaudeMcpDiscoveryCachePolicy.disabled,
  }) => DispatchSession(
    deps: SandboxDispatchDeps(
      sandbox: sandbox,
      broker: broker ?? _NoopBroker(),
      agentRepo: _UnusedAgentRepo(),
      runLogRepo: null,
      eventBus: eventBus,
      backendRegistry: BackendRegistry({'claude': const ClaudeCliBackend()}),
      claudeSessionStore: store,
      claudeMcpDiscoveryCache: discoveryCache,
      resolveAgentAttribution: (_, {workspaceId}) async {
        if (attributionFailure != null) {
          throw attributionFailure;
        }
        return creditAgent;
      },
      resolveGitIdentity: (_, {workspaceId}) async {
        if (identityFailure != null) {
          throw identityFailure;
        }
        return hasGitIdentity
            ? (name: 'Requesting User', email: 'requester@example.test')
            : null;
      },
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
    prompt: prompt,
    promptParts: promptParts,
    claudeResumeReset: claudeResumeReset,
    runStartedAt: runStartedAt,
    effortLevel: effortLevel,
    agentDirHostPath: agentDirHostPath,
    modelId: null,
    callerEnv: callerEnv,
    adapterEnvOverride: adapterEnv,
    agentId: null,
    workspaceId: 'ws-1',
    conversationId: conversationId,
    runLogId: 'run-1',
    mode: Mode.chat,
    claudeConfigDir: claudeConfigDir,
    resolveBinary: (name) async => '/usr/local/bin/$name',
  );

  /// One timer turn, so asynchronously-delivered stdout events and the
  /// unawaited record persistence have both landed before assertions.
  Future<void> settle() => Future<void>.delayed(Duration.zero);

  /// Runs a session that answers its first message with an init + a result.
  Future<void> runAnswering(
    _ScriptedClaude sandbox,
    DispatchSession session, {
    String sessionId = 'sess-A',
    double cost = 1.0,
  }) async {
    sandbox.onMessage = (text) {
      sandbox.emit(_init(sessionId));
      sandbox.emit(_result(cost: cost, sessionId: sessionId));
    };
    await session.run();
    await settle();
  }

  group('effort on the real launch path', () {
    test('carries --effort when the agent configures one', () async {
      final sandbox = _ScriptedClaude();
      final store = InMemoryClaudeNativeSessionStore();
      final session = buildSession(sandbox, store: store, effortLevel: 'high');
      await runAnswering(sandbox, session);
      final i = sandbox.argv.indexOf('--effort');
      expect(i, isNot(-1));
      expect(sandbox.argv[i + 1], 'high');
    });

    test('omits --effort when none is configured', () async {
      final sandbox = _ScriptedClaude();
      final session = buildSession(
        sandbox,
        store: InMemoryClaudeNativeSessionStore(),
      );
      await runAnswering(sandbox, session);
      expect(sandbox.argv, isNot(contains('--effort')));
    });
  });

  for (final creditAgent in [true, false]) {
    test(
      'commits belong to the requester with agent credit $creditAgent',
      () async {
        final sandbox = _ScriptedClaude();
        await runAnswering(
          sandbox,
          buildSession(
            sandbox,
            store: InMemoryClaudeNativeSessionStore(),
            creditAgent: creditAgent,
            callerEnv: const {
              'GIT_AUTHOR_NAME': 'Old Agent',
              'GIT_AUTHOR_EMAIL': 'old@example.test',
              'GIT_COMMITTER_NAME': 'Old Agent',
              'GIT_COMMITTER_EMAIL': 'old@example.test',
              'CC_GIT_COAUTHOR_TRAILER':
                  'Co-Authored-By: Old Agent <old@example.test>',
            },
            adapterEnv: const {
              'GIT_AUTHOR_NAME': 'Claude',
              'GIT_COMMITTER_EMAIL': 'claude@example.test',
            },
          ),
        );
        Future<String> git(List<String> args) async {
          final result = await Process.run(
            'git',
            args,
            workingDirectory: temp.path,
            environment: sandbox.env,
          );
          expect(result.exitCode, 0, reason: '${result.stderr}');
          return '${result.stdout}'.trim();
        }

        await git(['init', '--quiet']);
        final trailer = sandbox.env![DispatchSession.coAuthorTrailerEnvKey]!;
        await git([
          '-c',
          'commit.gpgsign=false',
          '-c',
          'core.hooksPath=${temp.path}/no-hooks',
          'commit',
          '--allow-empty',
          '--quiet',
          '-m',
          'Requester change',
          if (trailer.isNotEmpty) ...['-m', trailer],
        ]);
        expect(
          await git(['log', '-1', '--format=%an <%ae>%n%cn <%ce>%n%B']),
          'Requesting User <requester@example.test>\n'
          'Requesting User <requester@example.test>\n'
          'Requester change'
          '${creditAgent ? '\n\nCo-Authored-By: Control Center <hi@usectrl.dev>' : ''}',
        );
      },
    );
  }

  test(
    'changing attribution forks a native session and removes old credit',
    () async {
      final store = InMemoryClaudeNativeSessionStore();
      final enabled = _ScriptedClaude();
      await runAnswering(
        enabled,
        buildSession(enabled, store: store, promptParts: partsOf('first')),
      );
      final disabled = _ScriptedClaude();
      await runAnswering(
        disabled,
        buildSession(
          disabled,
          store: store,
          promptParts: partsOf('second'),
          creditAgent: false,
        ),
        sessionId: 'sess-B',
      );
      expect(disabled.argv, isNot(contains('--resume')));
    },
  );

  for (final creditAgent in [true, false]) {
    for (final failure in ['settings', 'missing identity', 'identity lookup']) {
      test('$failure failure releases credentials and fails the task '
          '(agent credit: $creditAgent)', () async {
        final sandbox = _ScriptedClaude();
        final broker = _NoopBroker();
        final bus = DomainEventBus();
        final lifecycle = <TaskLifecycleEvent>[];
        final subscription = bus.on<TaskLifecycleEvent>().listen(lifecycle.add);
        addTearDown(subscription.cancel);
        addTearDown(bus.dispose);
        final session = buildSession(
          sandbox,
          store: InMemoryClaudeNativeSessionStore(),
          creditAgent: creditAgent,
          hasGitIdentity: failure != 'missing identity',
          attributionFailure: failure == 'settings'
              ? StateError('Settings unavailable')
              : null,
          identityFailure: failure == 'identity lookup'
              ? StateError('Identity unavailable')
              : null,
          broker: broker,
          eventBus: bus,
        );
        final events = session.controller.stream.toList();
        await session.run();
        await events;
        await settle();
        expect(sandbox.argv, isEmpty);
        expect(broker.revoked, ['h']);
        expect(lifecycle.whereType<TaskFailed>(), hasLength(1));
        expect(lifecycle.whereType<TaskCompleted>(), isEmpty);
      });
    }
  }

  group('native session lineage', () {
    test(
      'a first turn sends the FULL prompt and records the native id',
      () async {
        final sandbox = _ScriptedClaude();
        final store = InMemoryClaudeNativeSessionStore();
        final session = buildSession(
          sandbox,
          store: store,
          promptParts: partsOf('delta-only'),
        );
        await runAnswering(sandbox, session, sessionId: 'sess-A');

        // No stored session yet: no resume, and the delta must NOT be used —
        // sending it without --resume would drop the standing brief.
        expect(sandbox.argv, isNot(contains('--resume')));
        expect(sandbox.received, ['hello']);

        final records = store.records.values.toList();
        expect(records, hasLength(1));
        expect(records.single.sessionId, 'sess-A');
        expect(records.single.turns, 1);
      },
    );

    test('a follow-up turn resumes that id and sends only the delta', () async {
      final store = InMemoryClaudeNativeSessionStore();

      final firstSandbox = _ScriptedClaude();
      final first = buildSession(
        firstSandbox,
        store: store,
        promptParts: partsOf('delta-only'),
      );
      await runAnswering(firstSandbox, first, sessionId: 'sess-A');

      final secondSandbox = _ScriptedClaude();
      final second = buildSession(
        secondSandbox,
        store: store,
        prompt: 'full second prompt',
        promptParts: partsOf('delta-only'),
      );
      await runAnswering(secondSandbox, second, sessionId: 'sess-A');

      final i = secondSandbox.argv.indexOf('--resume');
      expect(i, isNot(-1));
      expect(secondSandbox.argv[i + 1], 'sess-A');
      expect(secondSandbox.received, ['delta-only']);
      expect(secondSandbox.argv, isNot(contains('--continue')));
    });

    test(
      'an interrupted run keeps the id but never fabricates continuity',
      () async {
        final store = InMemoryClaudeNativeSessionStore();
        final sandbox = _ScriptedClaude();
        final session = buildSession(
          sandbox,
          store: store,
          promptParts: partsOf('delta'),
        );
        sandbox.onMessage = (text) {
          sandbox.emit(_init('sess-crash'));
          sandbox.exitWithoutResult();
        };
        await session.run();
        await settle();

        final record = store.records.values.single;
        expect(record.sessionId, 'sess-crash');
        expect(record.cumulativeCostUsd, 0);
        expect(record.turns, 0);
        // No clean exit → no cursor and no restorable baseline.
        expect(record.conversationRevision, isEmpty);
        expect(record.cliRestoresTotals, isFalse);

        // The next dispatch sends the FULL prompt on a fresh session: a delta
        // would drop everything the interrupted session may never have read.
        final nextSandbox = _ScriptedClaude();
        final next = buildSession(
          nextSandbox,
          store: store,
          promptParts: partsOf('delta'),
        );
        await runAnswering(nextSandbox, next, sessionId: 'sess-fresh');
        expect(nextSandbox.argv, isNot(contains('--resume')));
        expect(nextSandbox.received, ['hello']);
        // That clean run DID establish continuity.
        expect(store.records.values.single.conversationRevision, isNotEmpty);

        // So the turn after it resumes for real.
        final thirdSandbox = _ScriptedClaude();
        final third = buildSession(
          thirdSandbox,
          store: store,
          promptParts: partsOf('delta'),
        );
        await runAnswering(thirdSandbox, third, sessionId: 'sess-fresh');
        final i = thirdSandbox.argv.indexOf('--resume');
        expect(i, isNot(-1));
        expect(thirdSandbox.argv[i + 1], 'sess-fresh');
        expect(thirdSandbox.received, ['delta']);
      },
    );

    test(
      'an interrupted queued turn cannot establish a fresh cursor',
      () async {
        final store = InMemoryClaudeNativeSessionStore();
        final sandbox = _ScriptedClaude();
        final session = buildSession(
          sandbox,
          store: store,
          promptParts: partsOf(
            'delta',
            conversationEntries: [entry('recent:m1', 'Alice: hi')],
          ),
        );
        session.onHarnessStarted = () {
          session.steer('second', channel: SteeringChannel.followUp);
        };
        sandbox.onMessage = (text) {
          if (text == 'hello') {
            sandbox.emit(_init('sess-partial'));
            sandbox.emit(_result(sessionId: 'sess-partial'));
          } else {
            sandbox.exitWithoutResult();
          }
        };
        await session.run();
        await settle();

        expect(sandbox.received, ['hello', 'second']);
        final record = store.records.values.single;
        expect(record.turns, 1, reason: 'the first result was accounted');
        expect(record.conversationRevision, isEmpty);
        expect(record.cliRestoresTotals, isFalse);
        final nextSandbox = _ScriptedClaude();
        await runAnswering(
          nextSandbox,
          buildSession(
            nextSandbox,
            store: store,
            promptParts: partsOf('delta'),
          ),
        );
        expect(nextSandbox.argv, isNot(contains('--resume')));
        expect(nextSandbox.received, ['hello']);
      },
    );

    test('a different conversation cannot resume', () async {
      final store = InMemoryClaudeNativeSessionStore();
      final firstSandbox = _ScriptedClaude();
      await runAnswering(
        firstSandbox,
        buildSession(firstSandbox, store: store, promptParts: partsOf('d')),
      );

      final other = _ScriptedClaude();
      final session = buildSession(
        other,
        store: store,
        conversationId: 'conv-2',
        promptParts: partsOf('d'),
      );
      await runAnswering(other, session);

      expect(other.argv, isNot(contains('--resume')));
      expect(other.received, ['hello']);
    });

    test('a different account cannot resume', () async {
      final store = InMemoryClaudeNativeSessionStore();
      final firstSandbox = _ScriptedClaude();
      await runAnswering(
        firstSandbox,
        buildSession(
          firstSandbox,
          store: store,
          claudeConfigDir: '/accounts/a',
          promptParts: partsOf('d'),
        ),
      );

      final other = _ScriptedClaude();
      final session = buildSession(
        other,
        store: store,
        claudeConfigDir: '/accounts/b',
        promptParts: partsOf('d'),
      );
      await runAnswering(other, session);

      expect(other.argv, isNot(contains('--resume')));
    });

    test('a different worktree cannot resume', () async {
      final store = InMemoryClaudeNativeSessionStore();
      final firstSandbox = _ScriptedClaude();
      await runAnswering(
        firstSandbox,
        buildSession(
          firstSandbox,
          store: store,
          agentDirHostPath: '/work/one',
          promptParts: partsOf('d'),
        ),
      );

      final other = _ScriptedClaude();
      final session = buildSession(
        other,
        store: store,
        agentDirHostPath: '/work/two',
        promptParts: partsOf('d'),
      );
      await runAnswering(other, session);

      expect(other.argv, isNot(contains('--resume')));
    });

    test(
      'an explicit reset drops the stored session and records a new one',
      () async {
        final store = InMemoryClaudeNativeSessionStore();
        final firstSandbox = _ScriptedClaude();
        await runAnswering(
          firstSandbox,
          buildSession(firstSandbox, store: store, promptParts: partsOf('d')),
          sessionId: 'sess-A',
        );

        final reset = _ScriptedClaude();
        final session = buildSession(
          reset,
          store: store,
          promptParts: partsOf('d'),
          claudeResumeReset: true,
        );
        await runAnswering(reset, session, sessionId: 'sess-B');

        expect(reset.argv, isNot(contains('--resume')));
        expect(store.records.values.single.sessionId, 'sess-B');
      },
    );

    test('a dispatch with no prompt parts never resumes', () async {
      final store = InMemoryClaudeNativeSessionStore();
      final firstSandbox = _ScriptedClaude();
      await runAnswering(
        firstSandbox,
        buildSession(firstSandbox, store: store, promptParts: partsOf('d')),
      );

      final other = _ScriptedClaude();
      final session = buildSession(other, store: store);
      await runAnswering(other, session);
      expect(other.argv, isNot(contains('--resume')));
      expect(other.received, ['hello']);
    });
  });

  group('cumulative accounting on the wire', () {
    test(
      'a second result reports the DELTA, not the cumulative total',
      () async {
        final sandbox = _ScriptedClaude();
        final store = InMemoryClaudeNativeSessionStore();
        final session = buildSession(sandbox, store: store);
        final events = <AgentProcessEvent>[];
        final sub = session.controller.stream.listen(events.add);

        session.onHarnessStarted = () {
          session.steer('second', channel: SteeringChannel.followUp);
        };
        sandbox.onMessage = (text) {
          sandbox.emit(_init('sess-A'));
          if (text == 'hello') {
            sandbox.emit(_result(cost: 1.00, input: 100, output: 10));
          } else if (text == 'second') {
            // modelUsage is CUMULATIVE, so the second result carries the
            // running whole-tree totals (140 = 100 + 40).
            sandbox.emit(
              _result(
                cost: 1.50,
                input: 40,
                output: 5,
                modelUsage: {
                  'claude-sonnet-4-5-20250929': {
                    'inputTokens': 140,
                    'outputTokens': 15,
                    'cacheReadInputTokens': 0,
                    'cacheCreationInputTokens': 0,
                    'costUSD': 1.50,
                  },
                },
              ),
            );
          }
        };
        await session.run();
        await settle();
        await sub.cancel();

        final usage = events.whereType<UsageEvent>().toList();
        final turns = usage.where((e) => e.scope == UsageScope.turn).toList();
        final cumulative = usage
            .where((e) => e.scope == UsageScope.runCumulative)
            .toList();

        expect(turns, hasLength(2));
        expect(turns[0].usage.estimatedCostCents, 100);
        expect(turns[1].usage.estimatedCostCents, 50);
        expect(turns[1].usage.inputTokens, 40);

        // The absolute snapshot carries the CLI's own running total, and keeps
        // the legacy cents axis at zero so a cents-summing consumer cannot add
        // it on top of the deltas.
        expect(cumulative, isNotEmpty);
        expect(cumulative.last.usage.costMicros, 1500000);
        expect(cumulative.last.usage.estimatedCostCents, 0);
        expect(cumulative.last.usage.costBasis, CostBasis.subscription);
        expect(cumulative.last.usage.inputTokens, 140);

        // The persisted baseline is the CLI's cumulative, for the next resume.
        expect(
          store.records.values.single.cumulativeCostUsd,
          closeTo(1.50, 1e-9),
        );
      },
    );

    test(
      'the serving model, purpose and lineage are stamped on usage events',
      () async {
        final sandbox = _ScriptedClaude();
        final session = buildSession(
          sandbox,
          store: InMemoryClaudeNativeSessionStore(),
        );
        final events = <AgentProcessEvent>[];
        final sub = session.controller.stream.listen(events.add);
        await runAnswering(sandbox, session);
        await settle();
        await sub.cancel();

        final usage = events.whereType<UsageEvent>().toList();
        expect(usage, isNotEmpty);
        for (final event in usage) {
          expect(event.modelId, 'claude-sonnet-4-5-20250929');
          expect(event.provider, 'anthropic');
          expect(event.purpose, LlmCallPurpose.main);
          // Lineage for the paired resume-vs-reconstruction experiment.
          expect(event.nativeSessionId, 'sess-A');
          expect(event.resumedNativeSession, isFalse);
        }
      },
    );

    test('a resumed run marks its usage as resumed', () async {
      final store = InMemoryClaudeNativeSessionStore();
      final firstSandbox = _ScriptedClaude();
      await runAnswering(
        firstSandbox,
        buildSession(firstSandbox, store: store, promptParts: partsOf('d')),
      );

      final secondSandbox = _ScriptedClaude();
      final second = buildSession(
        secondSandbox,
        store: store,
        promptParts: partsOf('d'),
      );
      final events = <AgentProcessEvent>[];
      final sub = second.controller.stream.listen(events.add);
      await runAnswering(secondSandbox, second);
      await settle();
      await sub.cancel();

      final usage = events.whereType<UsageEvent>().toList();
      expect(usage, isNotEmpty);
      expect(usage.every((e) => e.resumedNativeSession), isTrue);
    });
  });

  group('MCP discovery cache opt-in', () {
    test('is off by default: no discovery env is injected', () async {
      final sandbox = _ScriptedClaude();
      final session = buildSession(
        sandbox,
        store: InMemoryClaudeNativeSessionStore(),
      );
      await runAnswering(sandbox, session);
      expect(sandbox.env?['MCP_DISCOVERY_CACHE'], isNull);
    });

    test(
      'an opted-in run pins the cache OFF until this scope has a record',
      () async {
        final store = InMemoryClaudeNativeSessionStore();
        const policy = ClaudeMcpDiscoveryCachePolicy(enabled: true);

        // First run in this scope: nothing is known about this tool surface, so
        // no cached list may be trusted.
        final firstSandbox = _ScriptedClaude();
        await runAnswering(
          firstSandbox,
          buildSession(firstSandbox, store: store, discoveryCache: policy),
        );
        expect(firstSandbox.env?['MCP_DISCOVERY_CACHE'], '0');

        // Second run: same scope + policy already ran here, so the cache is used
        // with bounded staleness.
        final secondSandbox = _ScriptedClaude();
        await runAnswering(
          secondSandbox,
          buildSession(secondSandbox, store: store, discoveryCache: policy),
        );
        expect(secondSandbox.env?['MCP_DISCOVERY_CACHE'], '1');
        expect(secondSandbox.env?['MCP_DISCOVERY_CACHE_MAX_STALE_S'], '3600');
      },
    );
  });

  group('review boundaries', () {
    tearDown(ClaudeCliBackend.clearCapabilityCache);

    test(
      'a restored baseline is not re-reported as this run\'s spend',
      () async {
        // Turn one costs $1.00 and is recorded as a restorable baseline. A
        // resumed call then reports $1.50 total: the run's own total must be the
        // $0.50 DELTA, never $1.50.
        final store = InMemoryClaudeNativeSessionStore();
        final firstSandbox = _ScriptedClaude();
        await runAnswering(
          firstSandbox,
          buildSession(firstSandbox, store: store, promptParts: partsOf('d')),
          cost: 1.00,
        );
        final seeded = store.records.values.single;
        expect(seeded.cliRestoresTotals, isTrue);
        expect(seeded.cumulativeCostUsd, closeTo(1.00, 1e-9));

        final sandbox = _ScriptedClaude();
        final session = buildSession(
          sandbox,
          store: store,
          promptParts: partsOf('d'),
        );
        final events = <AgentProcessEvent>[];
        final sub = session.controller.stream.listen(events.add);
        await runAnswering(sandbox, session, cost: 1.50);
        await settle();
        await sub.cancel();

        final cumulative = events
            .whereType<UsageEvent>()
            .where((e) => e.scope == UsageScope.runCumulative)
            .toList();
        expect(cumulative, isNotEmpty);
        // 0.50, not the native 1.50.
        expect(cumulative.last.usage.costMicros, 500000);
        expect(cumulative.last.usage.inputTokens, 0);
      },
    );

    test(
      'an unsupported --resume sends the full prompt, not a delta',
      () async {
        final store = InMemoryClaudeNativeSessionStore();
        final firstSandbox = _ScriptedClaude();
        await runAnswering(
          firstSandbox,
          buildSession(firstSandbox, store: store, promptParts: partsOf('d')),
        );

        // The resolved binary cannot resume.
        ClaudeCliBackend.cacheFor(
          '/usr/local/bin/claude',
          ClaudeCliCapabilities.minimal,
        );

        final sandbox = _ScriptedClaude();
        final session = buildSession(
          sandbox,
          store: store,
          promptParts: partsOf('delta-only'),
        );
        await runAnswering(sandbox, session);
        expect(sandbox.argv, isNot(contains('--resume')));
        expect(sandbox.received, [
          'hello',
        ], reason: 'the full prompt, not the delta');
      },
    );

    test(
      'unchanged history is omitted and a new shared message is kept',
      () async {
        final store = InMemoryClaudeNativeSessionStore();
        final alice = entry('recent:m1', 'Alice: hi');
        // First turn delivers Alice's message.
        final firstSandbox = _ScriptedClaude();
        await runAnswering(
          firstSandbox,
          buildSession(
            firstSandbox,
            store: store,
            promptParts: partsOf('d', conversationEntries: [alice]),
          ),
        );

        // Another participant posted while this session was parked; Alice's
        // message is untouched.
        final secondSandbox = _ScriptedClaude();
        final session = buildSession(
          secondSandbox,
          store: store,
          promptParts: partsOf(
            'next',
            turnSections: [
              section('Wake', 'Why you were woken', alwaysDeliver: true),
            ],
            conversationEntries: [alice, entry('recent:m2', 'Bob: status?')],
          ),
        );
        await runAnswering(secondSandbox, session);

        final message = secondSandbox.received.single;
        // The NEW entry and the new per-turn context are delivered exactly once…
        expect(message, contains('Bob: status?'));
        expect(message, contains('Why you were woken'));
        expect(message, endsWith('next'));
        // …and the history the session already holds is NOT replayed.
        expect(message, isNot(contains('Alice: hi')));
      },
    );

    test('an edited message is re-delivered', () async {
      final store = InMemoryClaudeNativeSessionStore();
      final original = entry('recent:m1', 'Alice: draft');
      final firstSandbox = _ScriptedClaude();
      await runAnswering(
        firstSandbox,
        buildSession(
          firstSandbox,
          store: store,
          promptParts: partsOf('d', conversationEntries: [original]),
        ),
      );

      final secondSandbox = _ScriptedClaude();
      final session = buildSession(
        secondSandbox,
        store: store,
        // Same message id, different text: the key changes, so it is new.
        promptParts: partsOf(
          'd',
          conversationEntries: [entry('recent:m1', 'Alice: final')],
        ),
      );
      await runAnswering(secondSandbox, session);

      final message = secondSandbox.received.single;
      expect(message, contains('Alice: final'));
      expect(message, isNot(contains('Alice: draft')));
    });

    test('only output PROVEN produced by this session is skipped', () async {
      final store = InMemoryClaudeNativeSessionStore();
      final alice = entry('recent:m1', 'Alice: hi');
      final firstSandbox = _ScriptedClaude();
      await runAnswering(
        firstSandbox,
        buildSession(
          firstSandbox,
          store: store,
          promptParts: partsOf('d', conversationEntries: [alice]),
        ),
      );
      // The clean run recorded ITS OWN run id as produced by this session.
      expect(store.records.values.single.producedRunIds, contains('run-1'));

      final secondSandbox = _ScriptedClaude();
      final session = buildSession(
        secondSandbox,
        store: store,
        promptParts: partsOf(
          'next',
          conversationEntries: [
            alice,
            // Proven: produced by THIS session's run.
            entry(
              'recent:m2',
              '- [you · 12:00] previous answer',
              provenance: PromptConversationProvenance.self,
              runId: 'run-1',
            ),
            entry('recent:m3', 'Bob: status?'),
          ],
        ),
      );
      await runAnswering(secondSandbox, session);

      final message = secondSandbox.received.single;
      expect(message, contains('Bob: status?'));
      expect(message, isNot(contains('previous answer')));
      expect(message, isNot(contains('Alice: hi')));
    });

    test(
      'parked-A/B: another session\'s output for the same agent is sent',
      () async {
        final store = InMemoryClaudeNativeSessionStore();
        final firstSandbox = _ScriptedClaude();
        await runAnswering(
          firstSandbox,
          buildSession(firstSandbox, store: store, promptParts: partsOf('d')),
        );

        // Same agent, but this message came from a run this session never
        // produced (the agent was dispatched on another account/model while this
        // session was parked). Sender identity alone must NOT suppress it.
        final secondSandbox = _ScriptedClaude();
        final session = buildSession(
          secondSandbox,
          store: store,
          promptParts: partsOf(
            'next',
            conversationEntries: [
              entry(
                'recent:m9',
                '- [you · 13:00] answer from the other session',
                provenance: PromptConversationProvenance.self,
                runId: 'run-B',
              ),
            ],
          ),
        );
        await runAnswering(secondSandbox, session);
        expect(
          secondSandbox.received.single,
          contains('answer from the other session'),
        );
      },
    );

    test('an unchanged dynamic section is not re-sent', () async {
      final store = InMemoryClaudeNativeSessionStore();
      final memory = section('Memory', 'remember this');
      final firstSandbox = _ScriptedClaude();
      await runAnswering(
        firstSandbox,
        buildSession(
          firstSandbox,
          store: store,
          promptParts: partsOf('d', turnSections: [memory]),
        ),
      );

      final secondSandbox = _ScriptedClaude();
      final session = buildSession(
        secondSandbox,
        store: store,
        // Same section, same text, plus a REAL wake reason.
        promptParts: partsOf(
          'next',
          turnSections: [
            memory,
            section('Wake', 'user replied', alwaysDeliver: true),
          ],
        ),
      );
      await runAnswering(secondSandbox, session);

      final message = secondSandbox.received.single;
      expect(message, contains('user replied'));
      expect(message, isNot(contains('remember this')));
      expect(message, endsWith('next'));
    });

    test('a changed dynamic section is re-sent', () async {
      final store = InMemoryClaudeNativeSessionStore();
      final firstSandbox = _ScriptedClaude();
      await runAnswering(
        firstSandbox,
        buildSession(
          firstSandbox,
          store: store,
          promptParts: partsOf(
            'd',
            turnSections: [section('Memory', 'remember this')],
          ),
        ),
      );

      final secondSandbox = _ScriptedClaude();
      final session = buildSession(
        secondSandbox,
        store: store,
        promptParts: partsOf(
          'next',
          turnSections: [section('Memory', 'remember this AND that')],
        ),
      );
      await runAnswering(secondSandbox, session);
      expect(secondSandbox.received.single, contains('remember this AND that'));
    });

    test('nothing new means the delta is just the message', () async {
      final store = InMemoryClaudeNativeSessionStore();
      final alice = entry('recent:m1', 'Alice: hi');
      final firstSandbox = _ScriptedClaude();
      await runAnswering(
        firstSandbox,
        buildSession(
          firstSandbox,
          store: store,
          promptParts: partsOf('d', conversationEntries: [alice]),
        ),
      );

      final secondSandbox = _ScriptedClaude();
      final session = buildSession(
        secondSandbox,
        store: store,
        promptParts: partsOf('next', conversationEntries: [alice]),
      );
      await runAnswering(secondSandbox, session);

      expect(secondSandbox.received, ['next']);
    });

    test('a record whose cursor was never established starts fresh', () async {
      final store = InMemoryClaudeNativeSessionStore();
      final sandbox = _ScriptedClaude();
      final session = buildSession(
        sandbox,
        store: store,
        promptParts: partsOf(
          'delta',
          conversationEntries: [entry('recent:m1', 'Alice: hi')],
        ),
      );
      // The run is interrupted: the id survives but no cursor does.
      sandbox.onMessage = (text) {
        sandbox.emit(_init('sess-A'));
        sandbox.exitWithoutResult();
      };
      await session.run();
      await settle();
      expect(store.records.values.single.conversationRevision, isEmpty);

      final nextSandbox = _ScriptedClaude();
      final next = buildSession(
        nextSandbox,
        store: store,
        promptParts: partsOf(
          'delta',
          conversationEntries: [entry('recent:m1', 'Alice: hi')],
        ),
      );
      await runAnswering(nextSandbox, next, sessionId: 'sess-A');
      expect(nextSandbox.argv, isNot(contains('--resume')));
      expect(nextSandbox.received, ['hello']);
    });

    test('an API-key lane reports estimated cost, not subscription', () async {
      final sandbox = _ScriptedClaude();
      final session = buildSession(
        sandbox,
        store: InMemoryClaudeNativeSessionStore(),
      );
      final events = <AgentProcessEvent>[];
      final sub = session.controller.stream.listen(events.add);
      sandbox.onMessage = (text) {
        sandbox.emit(
          jsonEncode({
            'type': 'system',
            'subtype': 'init',
            'session_id': 'sess-A',
            'model': 'claude-sonnet-4-5-20250929',
            'tools': ['Bash'],
            'mcp_servers': const [],
            'apiKeySource': 'api_key',
          }),
        );
        sandbox.emit(_result(cost: 0.25));
      };
      await session.run();
      await settle();
      await sub.cancel();

      final usage = events.whereType<UsageEvent>().toList();
      expect(usage, isNotEmpty);
      expect(
        usage.every((e) => e.usage.costBasis == CostBasis.estimated),
        isTrue,
      );
    });

    test('stage offsets measure from the shared run epoch', () async {
      final sandbox = _ScriptedClaude();
      final session = buildSession(
        sandbox,
        store: InMemoryClaudeNativeSessionStore(),
        // The run started 30s before this adapter was reached (a directory-lock
        // wait, say); the first-byte offset must include it.
        runStartedAt: DateTime.now().subtract(const Duration(seconds: 30)),
      );
      final events = <AgentProcessEvent>[];
      final sub = session.controller.stream.listen(events.add);
      await runAnswering(sandbox, session);
      await settle();
      await sub.cancel();

      final byte = events.whereType<StageTimingEvent>().firstWhere(
        (e) => e.stage == RunStage.firstResponseByte,
      );
      expect(byte.offsetMs, greaterThanOrEqualTo(30000));
      expect(byte.source, RunTimingSource.transport);
    });
  });
}
