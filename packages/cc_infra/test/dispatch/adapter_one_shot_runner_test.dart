import 'dart:async';
import 'dart:convert';

import 'package:cc_domain/features/sandboxing/domain/host_execution_posture.dart';
import 'package:cc_domain/features/sandboxing/domain/sandbox_config.dart';
import 'package:cc_domain/features/settings/domain/entities/adapter.dart';
import 'package:cc_harness/messages.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_harness_runtime/cc_harness_runtime.dart';
import 'package:cc_infra/src/dispatch/adapter_one_shot_runner.dart';
import 'package:cc_infra/src/dispatch/host_execution_gate.dart';
import 'package:cc_infra/src/dispatch/one_shot_confinement.dart';
import 'package:cc_infra/src/sandboxing/sandbox_manager.dart';
import 'package:test/test.dart';

/// Exercises [AdapterOneShotRunner]'s shipped transports with a fake launcher,
/// so no CLI has to exist on the host. Covers: the harness lane's credential
/// resolution, the `claude -p` argv and piped prompt, a synthetic ACP
/// handshake (the ACP protocol path), a non-zero exit, and the "not installed /
/// unknown adapter" quiet skips.
void main() {
  late _FakeCredStore creds;
  late _FakeFactory factory;
  late _RecordingLauncher launcher;

  setUp(() {
    creds = _FakeCredStore();
    factory = _FakeFactory();
    launcher = _RecordingLauncher();
  });

  AdapterOneShotRunner runner({
    Set<String> installed = const {'claude'},
    List<Adapter> extra = const [],
    OneShotConfinement confinement = const OneShotConfinement(
      gate: HostExecutionGate(posture: HostExecutionPosture.offByOwner),
    ),
  }) => AdapterOneShotRunner(
    credentials: creds,
    confinement: confinement,
    factory: factory,
    launcher: launcher.launch,
    resolveBinary: (cli) async =>
        installed.contains(cli) ? '/usr/local/bin/$cli' : null,
    adapters: [...predefinedAdapters, ...extra],
  );

  Future<String?> complete(String adapterId, {String? modelId}) =>
      runner().complete(
        workspaceId: 'ws-1',
        requestedByUserId: 'olga',
        adapterId: adapterId,
        modelId: modelId,
        systemPrompt: 'Name it.',
        prompt: 'How do I rebase?',
        timeout: const Duration(seconds: 5),
      );

  group('routing', () {
    test('unknown adapter id → null, nothing spawned', () async {
      expect(await complete('not-an-adapter'), isNull);
      expect(launcher.spawns, isEmpty);
    });

    test('a CLI that is not installed → null, nothing spawned', () async {
      final result = await runner(installed: const {}).complete(
        workspaceId: 'ws-1',
        requestedByUserId: 'olga',
        adapterId: 'claude-code',
        systemPrompt: 's',
        prompt: 'p',
        timeout: const Duration(seconds: 5),
      );
      expect(result, isNull);
      expect(launcher.spawns, isEmpty);
    });
  });

  group('harness transport', () {
    test('spawns no process and streams one completion', () async {
      factory.reply = 'Git rebase question';

      final out = await complete('cc-harness', modelId: 'anthropic/haiku');

      expect(out, 'Git rebase question');
      expect(launcher.spawns, isEmpty, reason: 'the harness runs in-process');
      expect(factory.calls.single.providerId, 'anthropic');
      expect(factory.calls.single.model, 'haiku');
    });

    test('no credential for the provider → null', () async {
      creds.credential = null;
      expect(await complete('cc-harness', modelId: 'anthropic/haiku'), isNull);
    });
  });

  group('claudeCli transport', () {
    test('drives a tool-less `claude -p` with the piped prompt', () async {
      launcher.stdoutLines = ['Git rebase question'];

      final out = await complete('claude-code', modelId: 'sonnet');

      expect(out?.trim(), 'Git rebase question');
      final spawn = launcher.spawns.single;
      expect(spawn.executable, '/usr/local/bin/claude');
      expect(spawn.arguments, [..._lockedDownClaudeArgs, '--model', 'sonnet']);
      // The system prompt replaces Claude Code's own; stdin is the prompt.
      expect(spawn.process.stdinWrites.single, 'How do I rebase?');
      expect(spawn.process.stdinClosed, isTrue);
    });

    test('omits --model when no model is set', () async {
      launcher.stdoutLines = ['T'];
      await complete('claude-code');
      expect(launcher.spawns.single.arguments, _lockedDownClaudeArgs);
    });

    test(
      'a non-zero exit throws rather than returning a partial title',
      () async {
        launcher
          ..stdoutLines = ['half an ans']
          ..exitCode = 1;

        await expectLater(complete('claude-code'), throwsA(isA<StateError>()));
      },
    );

    test('the process is killed even when the run throws', () async {
      launcher
        ..stdoutLines = ['x']
        ..exitCode = 2;

      await complete('claude-code').then<void>((_) {}, onError: (_) {});

      expect(launcher.spawns.single.process.killed, isTrue);
    });
  });

  group('acp transport', () {
    const acpAdapter = Adapter(
      id: 'acp-test',
      name: 'ACP test',
      description: 'synthetic ACP runner to keep the handshake path covered',
      cliName: 'acp-test',
      transport: AdapterTransport.acp,
      acpArgs: 'acp',
    );

    test(
      'runs initialize → session/new → session/prompt and collects text',
      () async {
        launcher.acpScript = true;

        final out =
            await runner(
              installed: const {'acp-test'},
              extra: const [acpAdapter],
            ).complete(
              workspaceId: 'ws-1',
              requestedByUserId: 'olga',
              adapterId: 'acp-test',
              modelId: 'grok',
              systemPrompt: 'Name it.',
              prompt: 'How do I rebase?',
              timeout: const Duration(seconds: 5),
            );

        expect(out, 'Git rebase question');
        final spawn = launcher.spawns.single;
        expect(spawn.executable, '/usr/local/bin/acp-test');
        expect(spawn.arguments, ['acp']);

        final methods = spawn.process.stdinWrites
            .map((l) => (jsonDecode(l) as Map<String, dynamic>)['method'])
            .toList();
        expect(methods, ['initialize', 'session/new', 'session/prompt']);

        final promptCall =
            jsonDecode(spawn.process.stdinWrites.last) as Map<String, dynamic>;
        final params = promptCall['params'] as Map<String, dynamic>;
        expect(params['sessionId'], 'sess-1');
        expect(params['prompt'], 'Name it.\n\nHow do I rebase?');

        final sessionNew =
            jsonDecode(spawn.process.stdinWrites[1]) as Map<String, dynamic>;
        expect((sessionNew['params'] as Map)['model'], 'grok');
      },
    );

    // The ACP CLI is the server OS user's own install and config, so who may
    // reach it, and how, follows the host execution posture.
    group('confinement', () {
      const owner = 'olga';
      Future<String?> ask(
        OneShotConfinement confinement, {
        required String? requestedBy,
      }) {
        launcher.acpScript = true;
        return runner(
          installed: const {'acp-test'},
          extra: const [acpAdapter],
          confinement: confinement,
        ).complete(
          workspaceId: 'ws-1',
          requestedByUserId: requestedBy,
          adapterId: 'acp-test',
          systemPrompt: 'Name it.',
          prompt: 'How do I rebase?',
          timeout: const Duration(seconds: 5),
        );
      }

      OneShotConfinement under(
        HostExecutionPosture posture, {
        _FakeManager? manager,
      }) => OneShotConfinement(
        gate: HostExecutionGate(
          posture: posture,
          ownerAccountable:
              ({required workspaceId, required requestedByUserId}) async =>
                  requestedByUserId == owner,
        ),
        sandboxManager: manager,
        protectedPaths: (_) async => const ['/src/checkout'],
      );

      for (final requestedBy in [owner, 'eve', null]) {
        test('sandboxed: wrapped for ${requestedBy ?? 'nobody'}', () async {
          final manager = _FakeManager();
          final out = await ask(
            under(HostExecutionPosture.sandboxed, manager: manager),
            requestedBy: requestedBy,
          );
          expect(out, 'Git rebase question');
          final spawn = launcher.spawns.single;
          expect(spawn.executable, '/usr/bin/sandbox-exec');
          expect(spawn.arguments, ['-f', 'profile', ..._acpArgv]);
          final config = manager.configs.single;
          expect(config.sessionId, startsWith('oneshot-'));
          expect(
            config.filesystem.denyWrite,
            contains('/src/checkout'),
            reason: "the workspace's checkouts stay unwritable",
          );
          expect(manager.disposed, [config.sessionId]);
        });

        test('off by the owner: bare for ${requestedBy ?? 'nobody'}', () async {
          final out = await ask(
            under(HostExecutionPosture.offByOwner),
            requestedBy: requestedBy,
          );
          expect(out, 'Git rebase question');
          final spawn = launcher.spawns.single;
          expect([spawn.executable, ...spawn.arguments], _acpArgv);
        });

        final ownerAsks = requestedBy == owner;
        test('unavailable: ${ownerAsks ? 'bare' : 'nothing'} for '
            '${requestedBy ?? 'nobody'}', () async {
          final out = await ask(
            under(HostExecutionPosture.unavailable),
            requestedBy: requestedBy,
          );
          if (ownerAsks) {
            expect(out, 'Git rebase question');
            final spawn = launcher.spawns.single;
            expect([spawn.executable, ...spawn.arguments], _acpArgv);
          } else {
            expect(out, isNull);
            expect(launcher.spawns, isEmpty);
          }
        });
      }

      test(
        'sandboxed with no manager to confine with: the owner rule',
        () async {
          final confinement = under(HostExecutionPosture.sandboxed);
          expect(await ask(confinement, requestedBy: 'eve'), isNull);
          expect(launcher.spawns, isEmpty);
          expect(await ask(confinement, requestedBy: owner), isNotNull);
          expect(launcher.spawns, hasLength(1));
        },
      );
    });
  });
}

const _acpArgv = ['/usr/local/bin/acp-test', 'acp'];

/// Records what it is asked to wrap and returns a recognisable argv.
class _FakeManager extends SandboxManager {
  _FakeManager() : super.test();

  final List<SandboxConfig> configs = [];
  final List<String> disposed = [];

  @override
  Future<SandboxWrapResult> wrap({
    required SandboxConfig config,
    required List<String> argv,
    String? workingDirectory,
  }) async {
    configs.add(config);
    return SandboxWrapResult(
      executable: '/usr/bin/sandbox-exec',
      argv: ['-f', 'profile', ...argv],
      environment: const {'HTTPS_PROXY': 'http://127.0.0.1:1'},
    );
  }

  @override
  Future<void> disposeSession(String sessionId) async =>
      disposed.add(sessionId);
}

class _Spawn {
  _Spawn(this.executable, this.arguments, this.process);

  final String executable;
  final List<String> arguments;
  final _FakeProcess process;
}

/// Records every spawn and replays canned stdout. With [acpScript] on, it
/// answers the JSON-RPC handshake instead, so the ACP lane is driven end to
/// end through the real `AcpClient`.
class _RecordingLauncher {
  final List<_Spawn> spawns = [];
  List<String> stdoutLines = const [];
  int exitCode = 0;
  bool acpScript = false;

  Future<OneShotProcess> launch(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
  }) async {
    final process = _FakeProcess(exitCode: exitCode, acpScript: acpScript);
    spawns.add(_Spawn(executable, arguments, process));
    if (!acpScript) {
      // Deliver stdout only once the caller has subscribed.
      scheduleMicrotask(() {
        for (final line in stdoutLines) {
          process.emit(line);
        }
        process.finish();
      });
    }
    return process;
  }
}

class _FakeProcess implements OneShotProcess {
  _FakeProcess({required this._exitCode, required this._acpScript});

  final int _exitCode;
  final bool _acpScript;
  final _stdout = StreamController<String>();
  final _done = Completer<int>();

  final List<String> stdinWrites = [];
  bool stdinClosed = false;
  bool killed = false;

  void emit(String line) {
    if (!_stdout.isClosed) {
      _stdout.add(line);
    }
  }

  void finish() {
    if (!_stdout.isClosed) {
      unawaited(_stdout.close());
    }
    if (!_done.isCompleted) {
      _done.complete(_exitCode);
    }
  }

  @override
  Stream<String> get stdoutLines => _stdout.stream;

  @override
  void writeStdin(String data) {
    stdinWrites.add(data.trimRight());
    if (!_acpScript) {
      return;
    }
    // Answer the JSON-RPC request the client just wrote.
    final req = jsonDecode(data) as Map<String, dynamic>;
    final id = req['id'];
    switch (req['method']) {
      case 'initialize':
        emit(jsonEncode({'jsonrpc': '2.0', 'id': id, 'result': {}}));
      case 'session/new':
        emit(
          jsonEncode({
            'jsonrpc': '2.0',
            'id': id,
            'result': {'sessionId': 'sess-1'},
          }),
        );
      case 'session/prompt':
        // Updates precede the result, as a real agent sends them.
        emit(
          jsonEncode({
            'jsonrpc': '2.0',
            'method': 'session/update',
            'params': {
              'sessionId': 'sess-1',
              'update': {
                'sessionUpdate': 'agent_message_chunk',
                'content': {'type': 'text', 'text': 'Git rebase question'},
              },
            },
          }),
        );
        emit(jsonEncode({'jsonrpc': '2.0', 'id': id, 'result': {}}));
    }
  }

  @override
  Future<void> closeStdin() async {
    stdinClosed = true;
  }

  @override
  Future<int> get exitCode => _done.future;

  @override
  void kill() {
    killed = true;
    finish();
  }
}

class _FakeCredStore implements ProviderCredentialStore {
  ProviderCredential? credential = const ProviderCredential(
    providerId: 'anthropic',
    method: HarnessAuthMethod.apiKey,
    apiKey: 'k',
  );

  @override
  Future<ProviderCredential?> activeCredential(String providerId) async =>
      credential;

  @override
  dynamic noSuchMethod(Invocation invocation) {}
}

class _FakeFactory implements HarnessProviderFactory {
  final List<({String providerId, String? model})> calls = [];
  String reply = '';

  @override
  ParsedModel parseModel(
    String? modelId, {
    String defaultProvider = 'anthropic',
  }) => const HarnessProviderFactory().parseModel(
    modelId,
    defaultProvider: defaultProvider,
  );

  @override
  LlmProviderPort create({
    required String providerId,
    String? model,
    ProviderCredential? credential,
    ProviderTokenResolver? tokenResolver,
  }) {
    calls.add((providerId: providerId, model: model));
    return _FakeProvider(reply);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {}
}

class _FakeProvider extends LlmProviderPort {
  _FakeProvider(this.reply);

  final String reply;

  @override
  Stream<LlmEvent> complete({
    required List<HarnessMessage> messages,
    List<LlmToolSchema> tools = const [],
    LlmCompleteConfig config = const LlmCompleteConfig(),
  }) async* {
    yield LlmTextDelta(reply);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {}
}

/// A plain completion: no built-in tools, no MCP servers, no slash commands,
/// no saved session, and the caller's system prompt instead of Claude Code's.
const _lockedDownClaudeArgs = [
  '-p',
  '--output-format',
  'text',
  '--tools',
  '',
  '--strict-mcp-config',
  '--disable-slash-commands',
  '--no-session-persistence',
  '--system-prompt',
  'Name it.',
];
