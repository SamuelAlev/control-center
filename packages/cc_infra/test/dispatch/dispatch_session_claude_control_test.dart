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
import 'package:cc_domain/features/dispatch/domain/prompts/prompt_builder.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_commit_identity.dart';
import 'package:cc_domain/features/settings/domain/entities/claude_session_settings.dart';
import 'package:cc_domain/features/subscriptions/subscriptions.dart';
import 'package:cc_infra/src/dispatch/backends/cli_backends.dart';
import 'package:cc_infra/src/dispatch/claude_idle_compactor.dart';
import 'package:cc_infra/src/dispatch/dispatch_session.dart';
import 'package:cc_infra/src/sandboxing/claude_native_session.dart';
import 'package:test/test.dart';

import '../helpers/windows_safe_delete.dart';

/// A `claude` that answers stdin line by line, as the real one does. Each
/// launch is one [_Attempt]; the process runs until its stdin closes.
class _ConversingSandbox implements SandboxPort {
  _ConversingSandbox(this.onLine);

  /// Called with each decoded stdin frame; returns the lines to print.
  final List<String> Function(Map<String, dynamic> frame, int attempt) onLine;

  final attempts = <_Attempt>[];
  StreamController<SandboxEvent>? _events;
  bool destroyed = false;
  Completer<int>? _running;

  void print(String line) =>
      _events?.add(SandboxEvent(type: SandboxEventType.stdout, content: line));

  @override
  SandboxBackend get backend => SandboxBackend.none;

  @override
  Stream<SandboxEvent> events(SandboxHandle handle) {
    // ignore: close_sinks, lives as long as the fake run.
    final controller = StreamController<SandboxEvent>.broadcast();
    _events = controller;
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
    final attempt = _Attempt(argv);
    final index = attempts.length;
    attempts.add(attempt);
    final running = Completer<int>();
    _running = running;
    stdinStream?.listen(
      (raw) {
        final frame = jsonDecode(raw) as Map<String, dynamic>;
        attempt.frames.add(frame);
        scheduleMicrotask(() => onLine(frame, index).forEach(print));
      },
      onDone: () {
        if (!running.isCompleted) {
          running.complete(0);
        }
      },
    );
    onPid?.call(4242);
    final code = await running.future;
    await Future<void>.delayed(Duration.zero);
    _events?.add(const SandboxEvent(type: SandboxEventType.exit));
    return code;
  }

  @override
  Future<void> destroy(SandboxHandle handle) async {
    destroyed = true;
    final running = _running;
    if (running != null && !running.isCompleted) {
      running.complete(-15);
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Attempt {
  _Attempt(this.argv);

  final List<String> argv;
  final frames = <Map<String, dynamic>>[];

  Iterable<Map<String, dynamic>> get prompts =>
      frames.where((f) => f['type'] == 'user');

  Iterable<String?> get controlSubtypes => frames
      .where((f) => f['type'] == 'control_request')
      .map((f) => (f['request'] as Map)['subtype'] as String?);
}

class _NoopBroker implements CredentialBrokerPort {
  @override
  Future<ScopedCredentials> mint({
    required String conversationId,
    required ForgeTokenScope scope,
    String? repoOwner,
    String? repoName,
    String? actingUserId,
    String? workspaceId,
    bool personal = false,
  }) async => const ScopedCredentials(handle: 'h', environment: {});

  @override
  Future<void> revoke(String handle) async {}
}

class _UnusedAgentRepo implements AgentRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

String _controlSuccess(Map<String, dynamic> frame, Map<String, Object?> body) =>
    jsonEncode({
      'type': 'control_response',
      'response': {
        'subtype': 'success',
        'request_id': frame['request_id'],
        'response': body,
      },
    });

String _init() => jsonEncode({
  'type': 'system',
  'subtype': 'init',
  'session_id': 'sess-1',
  'tools': ['Bash', 'mcp__control-center__ask_user'],
  'mcp_servers': const [],
});

String _success({int inputTokens = 0}) => jsonEncode({
  'type': 'result',
  'is_error': false,
  'result': 'ok',
  'usage': {'input_tokens': inputTokens, 'output_tokens': 1},
  'total_cost_usd': 0.25,
});

String _rateLimit(Map<String, Object?> info) =>
    jsonEncode({'type': 'rate_limit_event', 'rate_limit_info': info});

/// The start of a main-thread call, which is what sizes the context.
String _callStart(int inputTokens) => jsonEncode({
  'type': 'stream_event',
  'parent_tool_use_id': null,
  'event': {
    'type': 'message_start',
    'message': {
      'usage': {'input_tokens': inputTokens, 'output_tokens': 1},
    },
  },
});

/// A clean result whose call wrote the prompt cache for [ttlKey].
String _cachedSuccess(String ttlKey) => jsonEncode({
  'type': 'result',
  'is_error': false,
  'result': 'ok',
  'usage': {
    'input_tokens': 1,
    'output_tokens': 1,
    'cache_creation': {ttlKey: 500},
  },
  'total_cost_usd': 0.25,
});

String _compactBoundary() => jsonEncode({
  'type': 'system',
  'subtype': 'compact_boundary',
  'compact_metadata': {'trigger': 'manual', 'pre_tokens': 250000},
});

AgentPromptParts _parts(
  String userText, {
  List<PromptConversationEntry> entries = const [],
}) => AgentPromptParts(
  userText: userText,
  standing: 'standing brief',
  turnContext: '',
  conversationContext: entries.map((e) => e.text).join('\n'),
  fullPrompt: userText,
  standingRevision: PromptBuilder.promptRevisionOf('standing brief'),
  conversationEntries: entries,
  turnSections: const [],
);

PromptConversationEntry _entry(String id) => PromptConversationEntry(
  key: '$id#${PromptBuilder.promptRevisionOf(id)}',
  text: id,
  provenance: PromptConversationProvenance.other,
);

/// Records what a session reports instead of waiting on any timer.
class _SpyCompactor extends ClaudeIdleCompactor {
  _SpyCompactor() : super(enabled: () => false);

  final started = <String>[];
  final settled = <ClaudeSettledTurn>[];

  @override
  void runStarted(String workspaceId, String conversationId) =>
      started.add('$workspaceId/$conversationId');

  @override
  void turnSettled(ClaudeSettledTurn turn) => settled.add(turn);
}

const _servers = {
  'control-center': {
    'type': 'http',
    'url': 'http://127.0.0.1:1/mcp',
    'headers': {'Authorization': 'Bearer secret-token'},
  },
};

void main() {
  late Directory temp;
  late String newClaude;
  late String oldClaude;

  String fakeBinary(String name, String version) {
    final file = File('${temp.path}/$name')
      ..writeAsStringSync('#!/bin/sh\necho "$version (Claude Code)"\n');
    Process.runSync('/bin/chmod', ['+x', file.path]);
    return file.path;
  }

  setUp(() {
    temp = Directory.systemTemp.createTempSync('cc_claude_control_');
    newClaude = fakeBinary('claude-new', '2.1.316');
    oldClaude = fakeBinary('claude-old', '2.1.200');
    Directory('${temp.path}/acct').createSync();
    File(
      '${temp.path}/acct/.credentials.json',
    ).writeAsStringSync(jsonEncode({'claudeAiOauth': {}}));
  });

  tearDown(() => deleteDirBestEffort(temp));

  ({
    DispatchSession session,
    List<SandboxSpec> specs,
    List<({String configDir, List<SubscriptionWindow> windows})> windows,
    List<({String accountId, DateTime? resetsAt})> exhausted,
  })
  build(
    _ConversingSandbox sandbox, {
    String? binary,
    List<({String accountId, String configDir})> accounts = const [],
    Future<String?> Function(String)? configFile,
    ClaudeNativeSessionStore? store,
    AgentPromptParts? promptParts,
    ClaudeIdleCompactor? compactor,
    ClaudeSessionSettings? settings,
  }) {
    final specs = <SandboxSpec>[];
    final windows = <({String configDir, List<SubscriptionWindow> windows})>[];
    final exhausted = <({String accountId, DateTime? resetsAt})>[];
    final deps = SandboxDispatchDeps(
      sandbox: sandbox,
      broker: _NoopBroker(),
      agentRepo: _UnusedAgentRepo(),
      runLogRepo: null,
      eventBus: null,
      resolveCommitIdentity: (_, {workspaceId}) async =>
          AgentCommitIdentity.owner(
            name: 'Test User',
            email: 'test@example.test',
          ),
      backendRegistry: BackendRegistry({'claude': const ClaudeCliBackend()}),
      mcpServersResolver:
          ({workspaceId, agentId, conversationId, spaceId, runToken}) async =>
              _servers,
      mcpConfigPathResolver:
          (cwd, {workspaceId, agentId, conversationId, spaceId, runToken}) =>
              (configFile ?? (_) async => null)(cwd),
      onClaudeUsageWindows: (configDir, w) =>
          windows.add((configDir: configDir, windows: w)),
      claudeSessionStore: store,
      claudeIdleCompactor: compactor,
      claudeSessionSettings: settings == null ? null : () => settings,
    );
    final session = DispatchSession(
      deps: deps,
      onResolveHandle:
          ({
            required String sessionId,
            required SandboxSpec spec,
            required void Function(AgentProcessEvent) emit,
          }) async {
            specs.add(spec);
            return SandboxHandle(
              sessionId: sessionId,
              backend: SandboxBackend.none,
              state: SandboxState.warm,
            );
          },
      onScheduleCooldown: (_) {},
      dispatchId: 'd-claude',
      cliName: 'claude',
      prompt: promptParts?.userText ?? 'hello',
      promptParts: promptParts,
      agentDirHostPath: temp.path,
      modelId: null,
      callerEnv: const {},
      agentId: compactor == null ? null : 'agent-1',
      workspaceId: 'ws-1',
      spaceId: 'space-1',
      conversationId: 'conv-1',
      runLogId: 'run-1',
      mode: Mode.chat,
      claudeAccounts: accounts,
      onClaudeAccountExhausted: ({required accountId, resetsAt}) async =>
          exhausted.add((accountId: accountId, resetsAt: resetsAt)),
      resolveBinary: (name) async => binary ?? newClaude,
    );
    return (
      session: session,
      specs: specs,
      windows: windows,
      exhausted: exhausted,
    );
  }

  /// Answers the setup, then one turn, the way a healthy CLI does.
  List<String> healthy(Map<String, dynamic> frame, int _) {
    if (frame['type'] == 'control_request') {
      return [
        _controlSuccess(frame, {
          'added': ['control-center'],
          'errors': <String, Object?>{},
        }),
      ];
    }
    return [_init(), _success()];
  }

  group('MCP server over stdin', () {
    test(
      'the secret stays off argv and out of the working directory',
      () async {
        final stale = File('${temp.path}/.mcp.json')..writeAsStringSync('{}');
        final sandbox = _ConversingSandbox(healthy);
        final run = build(sandbox);

        await run.session.run();

        final attempt = sandbox.attempts.single;
        expect(attempt.argv, isNot(contains('--mcp-config')));
        expect(attempt.argv, contains('--strict-mcp-config'));
        expect(attempt.argv.join(' '), isNot(contains('secret-token')));
        expect(stale.existsSync(), isFalse);
      },
    );

    test('the servers go first and the prompt waits for the answer', () async {
      final answered = Completer<void>();
      late Map<String, dynamic> setup;
      final sandbox = _ConversingSandbox((frame, _) {
        if (frame['type'] == 'control_request') {
          setup = frame;
          answered.complete();
          return const [];
        }
        return [_init(), _success()];
      });
      final run = build(sandbox);

      final done = run.session.run();
      await answered.future;
      await Future<void>.delayed(const Duration(milliseconds: 20));
      final attempt = sandbox.attempts.single;

      expect(attempt.controlSubtypes, ['mcp_set_servers']);
      expect((setup['request'] as Map)['servers'], _servers);
      expect(attempt.prompts, isEmpty);

      sandbox.print(_controlSuccess(setup, {'added': <String>[]}));
      await done;

      expect(attempt.prompts, hasLength(1));
      expect(attempt.frames.first['type'], 'control_request');
    });

    test('a server that failed to connect still lets the turn run', () async {
      final sandbox = _ConversingSandbox((frame, _) {
        if (frame['type'] == 'control_request') {
          return [
            _controlSuccess(frame, {
              'errors': {'control-center': 'ECONNREFUSED'},
            }),
          ];
        }
        return [
          jsonEncode({
            'type': 'system',
            'subtype': 'init',
            'session_id': 's',
            'tools': ['Bash'],
            'mcp_servers': const [],
          }),
          _success(),
        ];
      });
      final run = build(sandbox);
      final events = run.session.controller.stream.toList();

      await run.session.run();
      final all = await events;

      expect(sandbox.attempts.single.prompts, hasLength(1));
      expect(
        all.whereType<ErrorEvent>().map((e) => e.content).join(),
        contains('no mcp__* tools'),
      );
      expect(
        all.whereType<DebugEvent>().map((e) => e.content).join(),
        contains('ECONNREFUSED'),
      );
    });

    test('an older CLI still gets the config file', () async {
      final config = File('${temp.path}/.mcp.json')
        ..writeAsStringSync(jsonEncode({'mcpServers': _servers}));
      final sandbox = _ConversingSandbox(healthy);
      final run = build(
        sandbox,
        binary: oldClaude,
        configFile: (_) async => config.path,
      );

      await run.session.run();

      final attempt = sandbox.attempts.single;
      expect(attempt.argv, contains('--mcp-config'));
      expect(attempt.controlSubtypes, isEmpty);
      expect(attempt.prompts, hasLength(1));
      expect(attempt.argv, isNot(contains('--thinking-display')));
    });
  });

  group('stopping a turn', () {
    /// Starts a run whose turn is in flight: answers the setup and init, and
    /// leaves the turn open.
    Future<
      ({
        _ConversingSandbox sandbox,
        Future<void> done,
        DispatchSession session,
        Future<List<AgentProcessEvent>> events,
      })
    >
    midTurn(List<String> Function(Map<String, dynamic>) onInterrupt) async {
      final started = Completer<void>();
      final sandbox = _ConversingSandbox((frame, _) {
        if (frame['type'] == 'user') {
          scheduleMicrotask(started.complete);
          return [_init()];
        }
        final subtype = (frame['request'] as Map)['subtype'];
        return subtype == 'interrupt'
            ? onInterrupt(frame)
            : [
                _controlSuccess(frame, {'added': <String>[]}),
              ];
      });
      final run = build(sandbox);
      final events = run.session.controller.stream.toList();
      final done = run.session.run();
      await started.future;
      await Future<void>.delayed(const Duration(milliseconds: 20));
      return (
        sandbox: sandbox,
        done: done,
        session: run.session,
        events: events,
      );
    }

    test('asks the CLI first, so the turn reports what it spent', () async {
      final run = await midTurn(
        (frame) => [
          _controlSuccess(frame, {'still_queued': <String>[]}),
          jsonEncode({
            'type': 'result',
            'subtype': 'error_during_execution',
            'is_error': true,
            'usage': {'input_tokens': 900, 'output_tokens': 40},
            'total_cost_usd': 0.5,
          }),
        ],
      );

      await run.session.terminate();
      await run.done;
      final all = await run.events;

      expect(
        run.sandbox.attempts.single.controlSubtypes,
        contains('interrupt'),
      );
      expect(all.whereType<UsageEvent>(), isNotEmpty);
      expect(run.sandbox.destroyed, isTrue);
    });

    test('a CLI that ignores it is killed after the grace period', () async {
      final run = await midTurn((_) => const []);

      final stopped = Stopwatch()..start();
      await run.session.terminate();
      await run.done;

      expect(run.sandbox.destroyed, isTrue);
      expect(stopped.elapsed, lessThan(const Duration(seconds: 6)));
    });

    test('a turn that has not started is not interrupted', () async {
      final answered = Completer<void>();
      final sandbox = _ConversingSandbox((frame, _) {
        answered.complete();
        return const [];
      });
      final run = build(sandbox);
      final done = run.session.run();
      await answered.future;

      final stopped = Stopwatch()..start();
      await run.session.terminate();
      await done;

      expect(sandbox.attempts.single.controlSubtypes, ['mcp_set_servers']);
      expect(stopped.elapsed, lessThan(const Duration(seconds: 2)));
    });
  });

  group('rate limit reports', () {
    ({String accountId, String configDir}) acct(String id) =>
        (accountId: id, configDir: '${temp.path}/acct');

    test('a blocked plan is recorded before the turn fails, once', () async {
      final blocked = _rateLimit({
        'status': 'rejected',
        'rateLimitType': 'five_hour',
        'resetsAt': 1893456000,
      });
      final sandbox = _ConversingSandbox((frame, _) {
        if (frame['type'] == 'control_request') {
          return [_controlSuccess(frame, const {})];
        }
        return [
          _init(),
          blocked,
          blocked,
          jsonEncode({
            'type': 'result',
            'is_error': true,
            'result': 'an unfamiliar sentence',
          }),
        ];
      });
      final run = build(sandbox, accounts: [acct('a1')]);

      await run.session.run();

      final at = DateTime.utc(2030);
      expect(run.exhausted.first, (accountId: 'a1', resetsAt: at));
      expect(run.exhausted.every((e) => e.resetsAt == at), isTrue);
    });

    test('a report outranks the wording, so the run fails over', () async {
      final sandbox = _ConversingSandbox((frame, attempt) {
        if (frame['type'] == 'control_request') {
          return [_controlSuccess(frame, const {})];
        }
        if (attempt > 0) {
          return [_init(), _success()];
        }
        return [
          _init(),
          _rateLimit({'status': 'rejected', 'rateLimitType': 'seven_day'}),
          jsonEncode({
            'type': 'result',
            'is_error': true,
            'result': 'an unfamiliar sentence',
          }),
        ];
      });
      final run = build(sandbox, accounts: [acct('a1'), acct('a2')]);

      await run.session.run();

      expect(sandbox.attempts, hasLength(2));
    });

    test('extra usage keeps an account in rotation', () async {
      final sandbox = _ConversingSandbox((frame, _) {
        if (frame['type'] == 'control_request') {
          return [_controlSuccess(frame, const {})];
        }
        return [
          _init(),
          _rateLimit({
            'status': 'rejected',
            'rateLimitType': 'five_hour',
            'overageStatus': 'allowed',
          }),
          _success(),
        ];
      });
      final run = build(sandbox, accounts: [acct('a1')]);

      await run.session.run();

      expect(run.exhausted, isEmpty);
    });

    test('a live report reaches the usage reading', () async {
      final sandbox = _ConversingSandbox((frame, _) {
        if (frame['type'] == 'control_request') {
          return [_controlSuccess(frame, const {})];
        }
        return [
          _init(),
          _rateLimit({
            'status': 'allowed_warning',
            'rateLimitType': 'five_hour',
            'unifiedWindows': {
              'five_hour': {'utilization': 0.91, 'resetsAt': 1893456000},
              'seven_day': {'utilization': 0.2},
            },
          }),
          _success(),
        ];
      });
      final run = build(sandbox, accounts: [acct('a1')]);
      final events = run.session.controller.stream.toList();

      await run.session.run();
      final debug = (await events)
          .whereType<DebugEvent>()
          .map((e) => e.content)
          .join('\n');

      final reported = run.windows.single;
      expect(reported.configDir, '${temp.path}/acct');
      expect(reported.windows.map((w) => w.id), ['5h', '7d']);
      expect(reported.windows.first.usedFraction, closeTo(0.91, 1e-9));
      expect(reported.windows.first.resetsAt, DateTime.utc(2030));
      expect(debug, contains('nearing its five_hour limit at 91%'));
      expect(run.exhausted, isEmpty);
    });
  });

  group('idle compaction', () {
    const resumable = '/usr/local/bin/claude-resumable';

    setUp(
      () => ClaudeCliBackend.cacheFor(
        resumable,
        const ClaudeCliCapabilities(
          supportsEffort: true,
          supportsResume: true,
          supportsSessionId: true,
          restoresSessionTotals: true,
          version: '2.1.316',
        ),
      ),
    );

    /// Runs an ordinary first turn, so [store] holds a session to compact.
    Future<void> firstTurn(
      InMemoryClaudeNativeSessionStore store, {
      List<PromptConversationEntry> entries = const [],
    }) async {
      final sandbox = _ConversingSandbox((_, _) => [_init(), _success()]);
      await build(
        sandbox,
        binary: resumable,
        store: store,
        promptParts: _parts('first', entries: entries),
      ).session.run();
      await Future<void>.delayed(Duration.zero);
    }

    Future<List<AgentProcessEvent>> compact(
      _ConversingSandbox sandbox,
      InMemoryClaudeNativeSessionStore store, {
      List<({String accountId, String configDir})> accounts = const [],
      ClaudeIdleCompactor? compactor,
    }) async {
      final session = build(
        sandbox,
        binary: resumable,
        store: store,
        promptParts: _parts(kClaudeIdleCompactionPrompt),
        accounts: accounts,
        compactor: compactor,
      ).session;
      final events = <AgentProcessEvent>[];
      session.controller.stream.listen(events.add);
      await session.run();
      await Future<void>.delayed(Duration.zero);
      return events;
    }

    test('resumes the session and sends only the command', () async {
      final store = InMemoryClaudeNativeSessionStore();
      await firstTurn(store);
      final sandbox = _ConversingSandbox(
        (_, _) => [_init(), _compactBoundary(), _success()],
      );

      final events = await compact(sandbox, store);

      final attempt = sandbox.attempts.single;
      expect(attempt.argv, containsAllInOrder(['--resume', 'sess-1']));
      expect(
        (attempt.prompts.single['message'] as Map)['content'].toString(),
        contains(kClaudeIdleCompactionPrompt),
      );
      expect(
        (attempt.prompts.single['message'] as Map)['content'].toString(),
        isNot(contains('standing brief')),
      );
      expect(
        events.whereType<TextEvent>().map((e) => e.content).join(),
        contains('250000'),
      );
    });

    test('leaves what the next turn still has to deliver', () async {
      final store = InMemoryClaudeNativeSessionStore();
      await firstTurn(store, entries: [_entry('m1')]);
      Future<ClaudeNativeSessionRecord?> record() async {
        final keys = store.records.keys.toList();
        return store.records[keys.single];
      }

      final before = (await record())!.conversationRevision;
      expect(before, isNotEmpty);

      await compact(
        _ConversingSandbox((_, _) => [_init(), _compactBoundary(), _success()]),
        store,
      );

      expect((await record())!.conversationRevision, before);
    });

    test('never starts a session just to compact it', () async {
      final sandbox = _ConversingSandbox((_, _) => [_init(), _success()]);

      final events = await compact(sandbox, InMemoryClaudeNativeSessionStore());

      expect(sandbox.attempts, isEmpty);
      expect(events.whereType<ErrorEvent>(), isEmpty);
      expect(events.whereType<DoneEvent>(), hasLength(1));
    });

    test('a failure is quiet and never fails over', () async {
      final store = InMemoryClaudeNativeSessionStore();
      await firstTurn(store);
      final sandbox = _ConversingSandbox(
        (_, _) => [
          _init(),
          jsonEncode({
            'type': 'result',
            'is_error': true,
            'result': 'Credit balance is too low',
          }),
        ],
      );

      final events = await compact(sandbox, store);

      expect(sandbox.attempts, hasLength(1));
      expect(events.whereType<ErrorEvent>(), isEmpty);
    });

    test('a turn reports its size and cache lifetime when it ends', () async {
      final compactor = _SpyCompactor();
      final sandbox = _ConversingSandbox(
        (_, _) => [
          _init(),
          _callStart(250000),
          _cachedSuccess('ephemeral_1h_input_tokens'),
        ],
      );

      await build(
        sandbox,
        binary: resumable,
        store: InMemoryClaudeNativeSessionStore(),
        promptParts: _parts('first'),
        compactor: compactor,
      ).session.run();

      expect(compactor.started, ['ws-1/conv-1']);
      final turn = compactor.settled.single;
      expect(turn.conversationId, 'conv-1');
      expect(turn.spaceId, 'space-1');
      expect(turn.agentId, 'agent-1');
      expect(turn.contextTokens, greaterThanOrEqualTo(250000));
      expect(turn.cacheTtl, const Duration(hours: 1));
    });

    test('a compaction does not schedule another one', () async {
      final store = InMemoryClaudeNativeSessionStore();
      await firstTurn(store);
      final compactor = _SpyCompactor();

      await compact(
        _ConversingSandbox(
          (_, _) => [
            _init(),
            _compactBoundary(),
            _cachedSuccess('ephemeral_5m_input_tokens'),
          ],
        ),
        store,
        compactor: compactor,
      );

      expect(compactor.settled, isEmpty);
    });

    test('the configured window reaches the CLI settings', () async {
      final sandbox = _ConversingSandbox((_, _) => [_init(), _success()]);

      await build(
        sandbox,
        binary: resumable,
        settings: ClaudeSessionSettings(autoCompactWindow: 300000),
      ).session.run();

      final argv = sandbox.attempts.single.argv;
      final settings = argv[argv.indexOf('--settings') + 1];
      expect(jsonDecode(settings), containsPair('autoCompactWindow', 300000));
    });
  });

  test('the run asks for its process tree to be supervised', () async {
    final sandbox = _ConversingSandbox(healthy);
    final run = build(sandbox);

    await run.session.run();

    expect(run.specs.single.superviseProcessGroup, isTrue);
  });
}
