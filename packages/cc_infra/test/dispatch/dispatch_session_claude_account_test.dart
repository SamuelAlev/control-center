import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/core/domain/ports/credential_broker_port.dart';
import 'package:cc_domain/core/domain/ports/run_credential_gate_port.dart';
import 'package:cc_domain/core/domain/ports/sandbox_port.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/value_objects/agent_capabilities.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_backend.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_event.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_handle.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_spec.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_process_event.dart';
import 'package:cc_domain/features/dispatch/domain/ports/agent_backend.dart';
import 'package:cc_infra/src/dispatch/backends/cli_backends.dart';
import 'package:cc_infra/src/dispatch/dispatch_session.dart';
import 'package:test/test.dart';

import '../helpers/windows_safe_delete.dart';

/// Records what the sandbox was asked to launch and with what environment.
class _RecordingSandbox implements SandboxPort {
  _RecordingSandbox({this.stdoutPerAttempt = const []});

  final List<List<String>> execArgs = [];
  final List<Map<String, String>?> execEnvs = [];

  /// NDJSON lines the CLI "emits" on each successive attempt, so a test can
  /// make the first account hit a usage limit and the second succeed.
  final List<List<String>> stdoutPerAttempt;

  final _controllers = <StreamController<SandboxEvent>>[];
  StreamController<SandboxEvent>? _current;

  @override
  SandboxBackend get backend => SandboxBackend.none;

  @override
  Stream<SandboxEvent> events(SandboxHandle handle) {
    final controller = StreamController<SandboxEvent>.broadcast();
    _controllers.add(controller);
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
  }) async {
    final attempt = execArgs.length;
    execArgs.add(argv);
    execEnvs.add(env);
    onPid?.call(4242);
    if (attempt < stdoutPerAttempt.length) {
      for (final line in stdoutPerAttempt[attempt]) {
        _current?.add(
          SandboxEvent(type: SandboxEventType.stdout, content: line),
        );
      }
      // Let the forwarded events reach the parser before exec resolves.
      await Future<void>.delayed(Duration.zero);
    }
    return 0;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// One NDJSON line: a terminal `result` failure.
String _resultError(String text, {int? status}) => jsonEncode({
  'type': 'result',
  'is_error': true,
  'result': text,
  'api_error_status': ?status,
});

/// One NDJSON line: a streamed assistant text delta.
String _textDelta(String text) => jsonEncode({
  'type': 'stream_event',
  'event': {
    'type': 'content_block_delta',
    'index': 0,
    'delta': {'type': 'text_delta', 'text': text},
  },
});

class _NoopBroker implements CredentialBrokerPort {
  @override
  Future<ScopedCredentials> mint({
    required String conversationId,
    required AgentCapabilities capabilities,
    String? repoOwner,
    String? repoName,
    String? actingUserId,
  }) async => const ScopedCredentials(handle: 'h', environment: {});

  @override
  Future<void> revoke(String handle) async {}
}

class _UnusedAgentRepo implements AgentRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Runs one `claude-code` dispatch and reports what the sandbox saw.
Future<
  ({
    _RecordingSandbox sandbox,
    List<SandboxSpec> specs,
    String log,
    String debug,
    List<String> exhausted,
    List<String> authFailed,
  })
>
_dispatchClaude({
  required String cwd,
  String? claudeConfigDir,
  List<({String accountId, String configDir})> accounts = const [],
  ClaudeAccountRefusal? spent,
  List<List<String>> stdoutPerAttempt = const [],
  RunCredentialGatePort? credentialGate,
  Future<bool> Function(String accountId)? syncClaudeCredential,
}) async {
  final sandbox = _RecordingSandbox(stdoutPerAttempt: stdoutPerAttempt);
  final specs = <SandboxSpec>[];
  final events = StringBuffer();
  final debug = StringBuffer();
  final exhausted = <String>[];
  final authFailed = <String>[];

  final deps = SandboxDispatchDeps(
    sandbox: sandbox,
    broker: _NoopBroker(),
    agentRepo: _UnusedAgentRepo(),
    runLogRepo: null,
    defaultCaps: AgentCapabilities.safeDefault,
    eventBus: null,
    backendRegistry: BackendRegistry({'claude': const ClaudeCliBackend()}),
    credentialGate: credentialGate,
    syncClaudeCredential: syncClaudeCredential,
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
    prompt: 'hello',
    agentDirHostPath: cwd,
    modelId: null,
    callerEnv: const {},
    agentId: null,
    workspaceId: 'ws-1',
    conversationId: 'conv-1',
    runLogId: 'run-1',
    mode: Mode.chat,
    claudeConfigDir: claudeConfigDir,
    claudeAccounts: accounts,
    claudeAccountsSpent: spent,
    onClaudeAccountExhausted: ({required accountId, resetsAt}) async =>
        exhausted.add(accountId),
    onClaudeAccountAuthFailed: ({required accountId, reason}) async =>
        authFailed.add(accountId),
    // The real probe would need Claude Code installed on the test machine.
    resolveBinary: (name) async => '/usr/local/bin/$name',
  );

  // `toList()` (not `listen` + cancel) so the assertion sees every event the
  // session emitted — a cancel racing `run()` drops the buffered tail, which is
  // exactly where a fail-fast error lands.
  final collected = session.controller.stream.toList();
  await session.run();
  for (final e in await collected) {
    if (e is ErrorEvent) {
      events.writeln(e.content);
    }
    if (e is DebugEvent) {
      debug.writeln(e.content);
    }
  }
  return (
    sandbox: sandbox,
    specs: specs,
    log: events.toString(),
    debug: debug.toString(),
    exhausted: exhausted,
    authFailed: authFailed,
  );
}

void main() {
  late Directory temp;
  late Directory account;

  setUp(() {
    temp = Directory.systemTemp.createTempSync('cc_dispatch_claude_');
    account = Directory('${temp.path}/claude-accounts/work')
      ..createSync(recursive: true);
  });

  tearDown(() => deleteDirBestEffort(temp));

  test(
    'the account directory reaches the child as CLAUDE_CONFIG_DIR',
    () async {
      File('${account.path}/.credentials.json').writeAsStringSync('{}');
      final run = await _dispatchClaude(
        cwd: temp.path,
        claudeConfigDir: account.path,
      );
      expect(run.sandbox.execArgs, hasLength(1));
      expect(run.sandbox.execEnvs.single?['CLAUDE_CONFIG_DIR'], account.path);
    },
  );

  // The env alone is not the fix. On macOS the account dir can sit inside a
  // region the profile denies (the data dir under a checkout), and the CLI
  // REWRITES `.credentials.json` when it renews the token — so the same path
  // has to reach the sandbox's writable set or long runs 401 mid-turn.
  test('the same directory is declared writable to the sandbox', () async {
    File('${account.path}/.credentials.json').writeAsStringSync('{}');
    final run = await _dispatchClaude(
      cwd: temp.path,
      claudeConfigDir: account.path,
    );
    expect(run.specs.single.runnerStateDirs, [account.path]);
  });

  test('with no account configured nothing is forced on the CLI', () async {
    // Unchanged pre-feature behaviour: the CLI resolves its own credential.
    final run = await _dispatchClaude(cwd: temp.path);
    expect(run.sandbox.execArgs, hasLength(1));
    expect(
      run.sandbox.execEnvs.single?.containsKey('CLAUDE_CONFIG_DIR'),
      isFalse,
    );
    expect(run.specs.single.runnerStateDirs, isEmpty);
  });

  // Spawned signed-out, `claude -p` prints `Not logged in · Please run /login`
  // on STDOUT and exits 0 — so the turn "succeeds", that sentence lands in the
  // transcript looking like something the agent said, and the operator is told
  // to run a slash command in a CLI they never opened.
  test(
    'a signed-out account fails before spawning, with a real reason',
    () async {
      final run = await _dispatchClaude(
        cwd: temp.path,
        claudeConfigDir: account.path,
      );
      expect(
        run.sandbox.execArgs,
        isEmpty,
        reason: 'a signed-out account must not burn a turn',
      );
      expect(run.log, contains('signed out'));
      expect(run.log, contains(account.path));
    },
  );

  test('a token in the environment counts as signed in', () async {
    // `CLAUDE_CODE_OAUTH_TOKEN` authenticates the CLI with no file in the
    // config dir, so an empty directory must not be refused out of hand.
    final sandbox = _RecordingSandbox();
    final deps = SandboxDispatchDeps(
      sandbox: sandbox,
      broker: _NoopBroker(),
      agentRepo: _UnusedAgentRepo(),
      runLogRepo: null,
      defaultCaps: AgentCapabilities.safeDefault,
      eventBus: null,
      backendRegistry: BackendRegistry({'claude': const ClaudeCliBackend()}),
    );
    final session = DispatchSession(
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
      dispatchId: 'd-claude-env',
      cliName: 'claude',
      prompt: 'hello',
      agentDirHostPath: temp.path,
      modelId: null,
      callerEnv: const {'CLAUDE_CODE_OAUTH_TOKEN': 'sk-ant-oat01-x'},
      agentId: null,
      workspaceId: 'ws-1',
      conversationId: 'conv-1',
      runLogId: 'run-1',
      mode: Mode.chat,
      claudeConfigDir: account.path,
      resolveBinary: (name) async => '/usr/local/bin/$name',
    );
    final drained = session.controller.stream.drain<void>();
    await session.run();
    await drained;
    expect(sandbox.execArgs, hasLength(1));
  });

  group('failover across the pool', () {
    ({String accountId, String configDir}) account(String id) {
      final dir = Directory('${temp.path}/claude-accounts/$id')
        ..createSync(recursive: true);
      File('${dir.path}/.credentials.json').writeAsStringSync('{}');
      return (accountId: id, configDir: dir.path);
    }

    // The point of the whole feature: a `/goal` that hits a usage limit
    // continues on the next account instead of ending the turn.
    test('a usage limit re-runs the SAME prompt on the next account', () async {
      final a = account('work');
      final b = account('personal');
      final run = await _dispatchClaude(
        cwd: temp.path,
        claudeConfigDir: a.configDir,
        accounts: [a, b],
        stdoutPerAttempt: [
          [_resultError('Claude AI usage limit reached|1787601441')],
          [_textDelta('hello')],
        ],
      );

      expect(run.sandbox.execArgs, hasLength(2), reason: 'it retried');
      expect(run.sandbox.execEnvs[0]?['CLAUDE_CONFIG_DIR'], a.configDir);
      expect(run.sandbox.execEnvs[1]?['CLAUDE_CONFIG_DIR'], b.configDir);
      expect(run.exhausted, ['work'], reason: 'the spent one is remembered');
      expect(run.debug, contains('account fallback work → personal'));
      // The limit is not an error the operator has to read — the run continued.
      expect(run.log, isEmpty);
    });

    test('a 429 counts as a usage limit', () async {
      final a = account('work');
      final b = account('personal');
      final run = await _dispatchClaude(
        cwd: temp.path,
        claudeConfigDir: a.configDir,
        accounts: [a, b],
        stdoutPerAttempt: [
          [_resultError('Overloaded', status: 429)],
          [_textDelta('hello')],
        ],
      );
      expect(run.sandbox.execArgs, hasLength(2));
      expect(run.exhausted, ['work']);
    });

    // An expired credential is as much "this account, not this run" as a spent
    // plan is. Measured: three pooled accounts, the third one's OAuth token
    // expired overnight, and every review agent dispatched onto it died with
    // `401 OAuth access token has expired` while two signed-in accounts sat
    // unused beside it.
    test('an expired credential re-runs on the next account', () async {
      final a = account('work');
      final b = account('personal');
      final run = await _dispatchClaude(
        cwd: temp.path,
        claudeConfigDir: a.configDir,
        accounts: [a, b],
        stdoutPerAttempt: [
          [
            _resultError(
              'Failed to authenticate. API Error: 401 OAuth access token has '
              'expired. Re-authenticate to continue.',
              status: 401,
            ),
          ],
          [_textDelta('hello')],
        ],
      );

      expect(run.sandbox.execArgs, hasLength(2), reason: 'it retried');
      expect(run.sandbox.execEnvs[1]?['CLAUDE_CONFIG_DIR'], b.configDir);
      expect(run.debug, contains('account fallback work → personal'));
      expect(run.debug, contains('credential expired'));
      // A dead credential is NOT a cooldown: nothing but a human signing in
      // fixes it, so parking it on a timer would hand it back every 30 minutes.
      expect(run.authFailed, ['work']);
      expect(run.exhausted, isEmpty);
      expect(run.log, isEmpty, reason: 'the run continued');
    });

    test(
      'an auth failure with no status is classified from the message',
      () async {
        final a = account('work');
        final b = account('personal');
        final run = await _dispatchClaude(
          cwd: temp.path,
          claudeConfigDir: a.configDir,
          accounts: [a, b],
          stdoutPerAttempt: [
            [_resultError('Not logged in · Please run /login')],
            [_textDelta('hello')],
          ],
        );
        expect(run.sandbox.execArgs, hasLength(2));
        expect(run.authFailed, ['work']);
      },
    );

    test(
      'the last account reports the auth failure instead of looping',
      () async {
        final a = account('work');
        final run = await _dispatchClaude(
          cwd: temp.path,
          claudeConfigDir: a.configDir,
          accounts: [a],
          stdoutPerAttempt: [
            [_resultError('OAuth access token has expired.', status: 401)],
          ],
        );
        expect(run.sandbox.execArgs, hasLength(1));
        // Still recorded, so the NEXT dispatch does not lead with it.
        expect(run.authFailed, ['work']);
        expect(run.log, contains('token has expired'));
      },
    );

    // Retrying a bad model id or a rejected MCP config on each account in turn
    // would burn the whole pool to reach the same failure.
    test('a NON-capacity error never rotates', () async {
      final a = account('work');
      final b = account('personal');
      final run = await _dispatchClaude(
        cwd: temp.path,
        claudeConfigDir: a.configDir,
        accounts: [a, b],
        stdoutPerAttempt: [
          [_resultError('model_not_found', status: 404)],
          [_textDelta('hello')],
        ],
      );
      expect(run.sandbox.execArgs, hasLength(1));
      expect(run.exhausted, isEmpty);
      expect(run.log, contains('model_not_found'));
    });

    // Re-running would duplicate what the operator already read.
    test('a turn that produced output is not re-run', () async {
      final a = account('work');
      final b = account('personal');
      final run = await _dispatchClaude(
        cwd: temp.path,
        claudeConfigDir: a.configDir,
        accounts: [a, b],
        stdoutPerAttempt: [
          [_textDelta('partial answer'), _resultError('usage limit reached')],
          [_textDelta('hello')],
        ],
      );
      expect(run.sandbox.execArgs, hasLength(1));
      // …but the limit is still remembered, so the NEXT dispatch starts
      // somewhere with headroom rather than rediscovering it.
      expect(run.exhausted, ['work']);
      expect(run.log, contains('usage limit reached'));
    });

    test('the last account reports the limit instead of looping', () async {
      final a = account('work');
      final run = await _dispatchClaude(
        cwd: temp.path,
        claudeConfigDir: a.configDir,
        accounts: [a],
        stdoutPerAttempt: [
          [_resultError('usage limit reached')],
        ],
      );
      expect(run.sandbox.execArgs, hasLength(1));
      expect(run.exhausted, ['work']);
      expect(run.log, contains('usage limit reached'));
    });

    // The profile is generated once, before the spawn — a failover landing on
    // a directory it never opened would fail to read the credential it just
    // switched to.
    test('EVERY pooled directory is writable to the sandbox', () async {
      final a = account('work');
      final b = account('personal');
      final run = await _dispatchClaude(
        cwd: temp.path,
        claudeConfigDir: a.configDir,
        accounts: [a, b],
      );
      expect(
        run.specs.single.runnerStateDirs,
        containsAll([a.configDir, b.configDir]),
      );
    });
  });

  group('all accounts spent', () {
    ({String accountId, String configDir}) anAccount() {
      final dir = Directory('${temp.path}/claude-accounts/work')
        ..createSync(recursive: true);
      File('${dir.path}/.credentials.json').writeAsStringSync('{}');
      return (accountId: 'work', configDir: dir.path);
    }

    test('refuses before spawning and names the reset time', () async {
      final a = anAccount();
      final run = await _dispatchClaude(
        cwd: temp.path,
        claudeConfigDir: a.configDir,
        accounts: [a],
        spent: (
          reason: RunCredentialReason.planSpent,
          accountIds: ['work', 'personal'],
          earliestReset: DateTime.utc(2026, 8, 24, 14, 20),
        ),
      );
      expect(run.sandbox.execArgs, isEmpty);
      expect(run.log, contains('2 attached'));
      expect(run.log, contains('out of plan headroom'));
      expect(run.log, contains('resets at'));
    });

    test(
      'with no known reset it still refuses, without inventing a time',
      () async {
        final a = anAccount();
        final run = await _dispatchClaude(
          cwd: temp.path,
          claudeConfigDir: a.configDir,
          accounts: [a],
          spent: (
            reason: RunCredentialReason.planSpent,
            accountIds: ['work'],
            earliestReset: null,
          ),
        );
        expect(run.sandbox.execArgs, isEmpty);
        expect(run.log, contains('out of plan headroom'));
        expect(run.log, isNot(contains('resets at')));
      },
    );

    test('a signed-out pool says so, instead of blaming the plan', () async {
      final a = anAccount();
      final run = await _dispatchClaude(
        cwd: temp.path,
        claudeConfigDir: a.configDir,
        accounts: [a],
        spent: (
          reason: RunCredentialReason.signedOut,
          accountIds: ['work', 'personal'],
          earliestReset: null,
        ),
      );
      expect(run.log, contains('no attached Claude Code account is signed in'));
      expect(
        run.log,
        isNot(contains('headroom')),
        reason: 'an account nobody signed into is not rate limited',
      );
    });
  });

  // The whole point of the gate: a run that would have died at a launch branch
  // is PARKED instead, and continues in the same turn once the credential
  // works. Nothing here is about the registry (that is cc_host's test) — only
  // that the session asks, and honours the three answers.
  group('the credential gate', () {
    late Directory account;

    setUp(() {
      account = Directory('${temp.path}/gated-account')
        ..createSync(recursive: true);
    });

    test('a resolved block lets the SAME run go on to spawn', () async {
      final synced = <String>[];
      final run = await _dispatchClaude(
        cwd: temp.path,
        claudeConfigDir: account.path,
        accounts: [(accountId: 'work', configDir: account.path)],
        // The operator signs in while the run waits. On macOS that lands in the
        // Keychain, which is why the probe re-mirrors before re-testing.
        syncClaudeCredential: (id) async {
          synced.add(id);
          File('${account.path}/.credentials.json').writeAsStringSync('{}');
          return true;
        },
        credentialGate: _FakeGate(RunCredentialOutcome.resolved),
      );
      expect(synced, [
        'work',
      ], reason: 'the probe mirrors the Keychain before reading the directory');
      expect(
        run.sandbox.execArgs,
        isNotEmpty,
        reason: 'the turn continues rather than being retyped',
      );
      expect(
        run.log,
        isEmpty,
        reason: 'a parked run that resumed never failed',
      );
      expect(run.debug, contains('waiting for a sign-in'));
    });

    test('a cancelled block fails exactly as it did before the gate', () async {
      final run = await _dispatchClaude(
        cwd: temp.path,
        claudeConfigDir: account.path,
        accounts: [(accountId: 'work', configDir: account.path)],
        credentialGate: _FakeGate(RunCredentialOutcome.cancelled),
      );
      expect(run.sandbox.execArgs, isEmpty);
      expect(run.log, contains('signed out'));
      expect(run.log, contains(account.path));
    });

    test('a timed-out block fails exactly as it did before the gate', () async {
      final run = await _dispatchClaude(
        cwd: temp.path,
        claudeConfigDir: account.path,
        accounts: [(accountId: 'work', configDir: account.path)],
        credentialGate: _FakeGate(RunCredentialOutcome.timedOut),
      );
      expect(run.sandbox.execArgs, isEmpty);
      expect(run.log, contains('signed out'));
    });

    test('the block names the run, the agent and the lane', () async {
      final gate = _FakeGate(RunCredentialOutcome.cancelled);
      await _dispatchClaude(
        cwd: temp.path,
        claudeConfigDir: account.path,
        accounts: [(accountId: 'work', configDir: account.path)],
        credentialGate: gate,
      );
      final asked = gate.requests.single;
      expect(asked.lane, RunCredentialLane.claudeCode);
      expect(asked.reason, RunCredentialReason.signedOut);
      expect(asked.accountIds, ['work']);
      expect(asked.runLogId, 'run-1');
      expect(asked.workspaceId, 'ws-1');
      expect(
        asked.detail,
        contains('signed out'),
        reason: 'the dialog and the fallback error share one sentence',
      );
    });
  });
}

/// A gate that answers with a fixed outcome, recording what it was asked.
///
/// The recheck is still called once, because a gate that never probed would
/// hide the very thing the session has to get right — re-mirroring the
/// Keychain before re-reading the account directory.
class _FakeGate implements RunCredentialGatePort {
  _FakeGate(this.outcome);

  final RunCredentialOutcome outcome;
  final List<RunCredentialBlockRequest> requests = [];

  @override
  Future<RunCredentialOutcome> awaitCredentials(
    RunCredentialBlockRequest request, {
    required Future<bool> Function() recheck,
  }) async {
    requests.add(request);
    await recheck();
    return outcome;
  }
}
