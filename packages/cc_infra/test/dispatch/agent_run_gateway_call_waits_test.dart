import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/core/domain/ports/confirmation_port.dart';
import 'package:cc_domain/core/domain/ports/credential_broker_port.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode_limits.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/script_approval_budget.dart';
import 'package:cc_domain/features/environments/domain/ports/environment_port.dart';
import 'package:cc_domain/features/guardrails/domain/entities/action_policy_rule.dart';
import 'package:cc_domain/features/guardrails/domain/repositories/action_policy_repository.dart';
import 'package:cc_domain/features/guardrails/domain/services/action_guard_service.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_decision.dart';
import 'package:cc_infra/agent_run_client.dart';
import 'package:cc_infra/src/dispatch/agent_environment_gateway.dart';
import 'package:cc_infra/src/dispatch/agent_run_gateway.dart';
import 'package:cc_infra/src/harness/harness_command_runner.dart'
    show CommandWait;
import 'package:test/test.dart';

/// A harness `bash` command's push that the agent run gateway holds for a
/// person stops that command's tool call clocks, through a per-command call
/// token that authorizes nothing and decides nothing.
void main() {
  late _Confirm confirm;
  late AgentRunGateway gateway;
  late HttpServer host;
  late AgentRunLease lease;
  late HttpClient client;
  late List<GuardAudit> audits;

  setUp(() async {
    confirm = _Confirm();
    audits = [];
    host = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    gateway = AgentRunGateway(
      // No rules: "Push to a remote" asks first by default.
      guard: ActionGuardService(
        repository: _Rules(),
        confirmationPort: confirm,
        onAudit: audits.add,
      ),
      broker: _Broker(),
      loopbackBase: () async => Uri.parse('http://127.0.0.1:${host.port}'),
      repoAllowed: (_, _, _, _) async => true,
    );
    host.listen(gateway.handle);
    lease = (await gateway.open(
      const AgentRunGrant(
        workspaceId: 'w1',
        conversationId: 'c1',
        mcpEndpoint: true,
        claudeHook: true,
        readOnly: false,
        spaceId: 's1',
        repos: [_widgets],
      ),
    ))!;
    client = HttpClient();
  });

  tearDown(() async {
    client.close(force: true);
    await host.close(force: true);
  });

  String tokenOf(CommandWait wait) =>
      wait.environment[AgentRunLease.callTokenEnvKey]!;

  /// A push of `main` on [secret], naming [calls] as its call tokens.
  Future<({int status, String body})> push({
    String? secret,
    List<String> calls = const [],
  }) async {
    final request = await client.openUrl(
      'POST',
      Uri.parse(
        'http://127.0.0.1:${host.port}'
        '/agent/git/github.com/acme/widgets.git/git-receive-pack',
      ),
    );
    request.headers.set(AgentRunLease.tokenHeader, secret ?? lease.secret);
    for (final call in calls) {
      request.headers.add(AgentRunLease.callTokenHeader, call);
    }
    request.add(_push('refs/heads/main'));
    final response = await request.close();
    return (
      status: response.statusCode,
      body: await response.transform(utf8.decoder).join(),
    );
  }

  test('the registration gives the command a token and the git config that '
      'sends it, after the entries the run already has', () {
    final env = lease.environment(const {});
    final wait = lease.register((_) {}, env, decided: (_) {});
    final count = int.parse(env['GIT_CONFIG_COUNT']!);

    expect(tokenOf(wait), matches(RegExp(r'^[A-Za-z0-9_-]{43}$')));
    expect(wait.environment['GIT_CONFIG_COUNT'], '${count + 1}');
    expect(
      wait.environment['GIT_CONFIG_KEY_$count'],
      'http.${lease.base}/agent/git/.extraHeader',
    );
    expect(
      wait.environment['GIT_CONFIG_VALUE_$count'],
      '${AgentRunLease.callTokenHeader}: ${tokenOf(wait)}',
    );
    expect(wait.environment.values, isNot(contains(lease.secret)));
    expect(
      tokenOf(lease.register((_) {}, env, decided: (_) {})),
      isNot(tokenOf(wait)),
      reason: 'one token per command',
    );
  });

  test('a held push for a registered call tells its listener when the ask '
      'starts and when it ends', () async {
    final heard = <bool>[];
    final wait = lease.register(heard.add, const {}, decided: (_) {});
    confirm.hold();

    final pushed = push(calls: [tokenOf(wait)]);
    await confirm.requested!.future;
    expect(heard, [true]);
    confirm.pending!.complete(false);
    final r = await pushed;

    expect(heard, [true, false]);
    expect(r.body, contains('ng refs/heads/main'));
    expect(confirm.asked, hasLength(1));
  });

  test('what a person decided about a registered call\'s push reaches that '
      'call, declined or approved', () async {
    final decided = <bool>[];
    final wait = lease.register((_) {}, const {}, decided: decided.add);

    confirm.answer = false;
    await push(calls: [tokenOf(wait)]);
    confirm.answer = true;
    await push(calls: [tokenOf(wait)]);

    expect(decided, [false, true]);
  });

  group('decided exactly as without one, and nobody hears', () {
    /// Pushes once with no call token and once naming [calls] (`own` is a
    /// token registered on this run, `foreign` one registered on another).
    Future<void> expectUnheard(List<String> calls) async {
      final heard = <bool>[];
      final decided = <bool>[];
      final own = lease.register(heard.add, const {}, decided: decided.add);
      final other = (await gateway.open(
        const AgentRunGrant(
          workspaceId: 'w1',
          conversationId: 'c2',
          mcpEndpoint: true,
          claudeHook: true,
          readOnly: false,
        ),
      ))!;
      final foreign = other.register(heard.add, const {}, decided: decided.add);
      confirm.answer = false;

      final plain = await push();
      final named = await push(
        calls: [
          for (final c in calls)
            switch (c) {
              'own' => tokenOf(own),
              'foreign' => tokenOf(foreign),
              _ => c,
            },
        ],
      );

      expect(heard, isEmpty);
      expect(decided, isEmpty);
      expect(named.status, plain.status);
      expect(named.body, plain.body);
      expect(confirm.asked, hasLength(2));
      expect(audits, hasLength(2));
      expect(
        (audits[1].decision, audits[1].prompted, audits[1].reason),
        (audits[0].decision, audits[0].prompted, audits[0].reason),
      );
      await gateway.close(other);
    }

    test('an unknown token', () => expectUnheard(['not-a-token']));

    test('a token registered on another run', () => expectUnheard(['foreign']));

    test('two tokens, even when both are its own', () {
      return expectUnheard(['own', 'own']);
    });

    test('a token whose command ended', () async {
      final heard = <bool>[];
      final wait = lease.register(heard.add, const {}, decided: (_) {});
      wait.release();
      confirm.answer = false;

      await push(calls: [tokenOf(wait)]);

      expect(heard, isEmpty);
      expect(confirm.asked, hasLength(1));
    });
  });

  test('the token alone is no credential', () async {
    final wait = lease.register((_) {}, const {}, decided: (_) {});

    final r = await push(secret: tokenOf(wait), calls: [tokenOf(wait)]);

    expect(r.status, HttpStatus.unauthorized);
    expect(confirm.asked, isEmpty);
  });

  test(
    'a command that ends during the ask closes the wait then, once',
    () async {
      final heard = <bool>[];
      final wait = lease.register(heard.add, const {}, decided: (_) {});
      confirm.hold();

      final pushed = push(calls: [tokenOf(wait)]);
      await confirm.requested!.future;
      wait.release();
      expect(heard, [true, false]);
      confirm.pending!.complete(false);
      await pushed;

      expect(heard, [true, false]);
    },
  );

  test('closing the run closes an open wait', () async {
    final heard = <bool>[];
    final wait = lease.register(heard.add, const {}, decided: (_) {});
    confirm.hold();

    final pushed = push(calls: [tokenOf(wait)]);
    await confirm.requested!.future;
    await gateway.close(lease);
    expect(heard, [true, false]);
    confirm.pending!.complete(false);
    await pushed;

    expect(heard, [true, false]);
    expect(
      lease.register(heard.add, const {}, decided: (_) {}).environment,
      isEmpty,
      reason: 'a closed run registers nothing',
    );
  });

  group('an environment command', () {
    setUp(() {
      gateway.environments = AgentEnvironmentGateway(
        environments: _NoEnvironments(),
        context: _NoContext(),
        guard: ActionGuardService(
          repository: _Rules(),
          confirmationPort: confirm,
          onAudit: audits.add,
        ),
        runHost:
            (
              binary,
              arguments, {
              required workingDirectory,
              environment = const {},
            }) async => throw StateError('nothing runs on the host here'),
      );
    });

    /// `cc-env up` on this run, naming [calls] as its call tokens.
    Future<({String exit, String stderr})> envUp({
      List<String> calls = const [],
    }) async {
      final request = await client.openUrl(
        'POST',
        Uri.parse('http://127.0.0.1:${host.port}${AgentRunGateway.envPath}'),
      );
      request.headers
        ..set(AgentRunLease.tokenHeader, lease.secret)
        ..set('X-CC-Env-Tool', 'cc-env');
      for (final call in calls) {
        request.headers.add(AgentRunLease.callTokenHeader, call);
      }
      request.write('up\u0000');
      final response = await request.close();
      await response.drain<void>();
      return (
        exit: response.headers.value('X-CC-Exit-Code') ?? '',
        stderr: utf8.decode(
          base64.decode(response.headers.value('X-CC-Stderr') ?? ''),
        ),
      );
    }

    test('held for a registered call tells its listener when the ask starts '
        'and when it ends', () async {
      final heard = <bool>[];
      final decided = <bool>[];
      final wait = lease.register(heard.add, const {}, decided: decided.add);
      confirm.hold();

      final ran = envUp(calls: [tokenOf(wait)]);
      await confirm.requested!.future;
      expect(heard, [true]);
      confirm.pending!.complete(false);
      final r = await ran;

      expect(heard, [true, false]);
      expect(r.exit, '1');
      expect(r.stderr, startsWith('Control Center policy:'));
      expect(confirm.asked, hasLength(1));
      // The decline reaches the call that ran the command, for its record.
      expect(decided, [false]);
    });

    test('decided exactly as without one, and nobody hears, for an unknown '
        'token', () async {
      final heard = <bool>[];
      lease.register(heard.add, const {}, decided: (_) {});
      confirm.answer = false;

      final plain = await envUp();
      final named = await envUp(calls: ['not-a-token']);

      expect(heard, isEmpty);
      expect(named, plain);
      expect(confirm.asked, hasLength(2));
      expect(
        (audits[1].decision, audits[1].prompted, audits[1].reason),
        (audits[0].decision, audits[0].prompted, audits[0].reason),
      );
    });
  });

  group('while a script of the run is in flight', () {
    /// The pre-tool-use hook's answer for `git push` on this run.
    Future<String> hookPush() async {
      final request = await client.openUrl(
        'POST',
        Uri.parse('http://127.0.0.1:${host.port}/agent/hooks/pre-tool-use'),
      );
      request.headers.set(AgentRunLease.tokenHeader, lease.secret);
      request.write(
        jsonEncode({
          'tool_name': 'Bash',
          'tool_input': {
            'command': 'git push origin feature/x',
            'description': 'Push the branch',
          },
        }),
      );
      final response = await request.close();
      return (await response.transform(utf8.decoder).join()).trim();
    }

    test('eleven pushes from its command raise ten cards, with or without '
        'the call header, and the refusal is audited as one', () async {
      final budget = ScriptApprovalBudget();
      addTearDown(lease.holdScriptApprovals(budget));
      final wait = lease.register((_) {}, const {}, decided: (_) {});

      for (var i = 0; i < CodeModeLimits.maxApprovalAsks + 1; i++) {
        // A process in the sandbox can drop the header: half of them do.
        await push(calls: i.isEven ? [tokenOf(wait)] : const []);
      }

      expect(confirm.asked, hasLength(CodeModeLimits.maxApprovalAsks));
      expect(budget.refusal, ScriptApprovalBudget.exhaustedReason);
      final refused = audits.last;
      expect(refused.decision, ActionDecision.deny);
      expect(refused.prompted, isFalse);
      expect(refused.reason, ScriptApprovalBudget.exhaustedReason);
    });

    test('after a decline the next card is never raised', () async {
      final budget = ScriptApprovalBudget();
      addTearDown(lease.holdScriptApprovals(budget));
      confirm.answer = false;

      await push();
      confirm.answer = true;
      final second = await push();

      expect(confirm.asked, hasLength(1));
      expect(second.body, contains('ng refs/heads/main'));
      expect(audits.last.reason, ScriptApprovalBudget.declinedReason);
      expect(audits.last.prompted, isFalse);
    });

    test('a hook ask counts against it and stops after a decline', () async {
      final budget = ScriptApprovalBudget();
      addTearDown(lease.holdScriptApprovals(budget));
      confirm.answer = false;

      expect(await hookPush(), isNot('allow'));
      confirm.answer = true;
      expect(await hookPush(), endsWith(ScriptApprovalBudget.declinedReason));
      expect(confirm.asked, hasLength(1));
    });

    test('an environment command counts against it too', () async {
      gateway.environments = AgentEnvironmentGateway(
        environments: _NoEnvironments(),
        context: _NoContext(),
        guard: ActionGuardService(
          repository: _Rules(),
          confirmationPort: confirm,
          onAudit: audits.add,
        ),
        runHost:
            (
              binary,
              arguments, {
              required workingDirectory,
              environment = const {},
            }) async => throw StateError('nothing runs on the host here'),
      );
      final budget = ScriptApprovalBudget();
      addTearDown(lease.holdScriptApprovals(budget));
      confirm.answer = false;

      Future<String> envUp() async {
        final request = await client.openUrl(
          'POST',
          Uri.parse('http://127.0.0.1:${host.port}${AgentRunGateway.envPath}'),
        );
        request.headers
          ..set(AgentRunLease.tokenHeader, lease.secret)
          ..set('X-CC-Env-Tool', 'cc-env');
        request.write('up\u0000');
        final response = await request.close();
        await response.drain<void>();
        return utf8.decode(
          base64.decode(response.headers.value('X-CC-Stderr') ?? ''),
        );
      }

      await envUp();
      confirm.answer = true;
      final second = await envUp();

      expect(confirm.asked, hasLength(1));
      expect(second, contains(ScriptApprovalBudget.declinedReason));
      expect(budget.refusal, ScriptApprovalBudget.declinedReason);
    });

    test('a run with no script in flight is unaffected, and so is one whose '
        'script ended', () async {
      confirm.answer = false;
      final release = lease.holdScriptApprovals(ScriptApprovalBudget());
      release();
      // Released twice: still nothing held, nothing else released.
      release();

      for (var i = 0; i < 3; i++) {
        await push();
      }

      expect(confirm.asked, hasLength(3));
      expect(audits.every((a) => a.prompted), isTrue);
    });

    test(
      'every script in flight is charged, and a decline stops both',
      () async {
        final first = ScriptApprovalBudget();
        final second = ScriptApprovalBudget();
        addTearDown(lease.holdScriptApprovals(first));
        addTearDown(lease.holdScriptApprovals(second));
        confirm.answer = false;

        await push();
        await push();

        expect(confirm.asked, hasLength(1));
        expect(first.refusal, ScriptApprovalBudget.declinedReason);
        expect(second.refusal, ScriptApprovalBudget.declinedReason);
      },
    );
  });

  test(
    'a shell command\'s check through the hook names its call too',
    () async {
      final heard = <bool>[];
      final wait = lease.register(heard.add, const {}, decided: (_) {});
      final request = await client.openUrl(
        'POST',
        Uri.parse('http://127.0.0.1:${host.port}/agent/hooks/pre-tool-use'),
      );
      request.headers
        ..set(AgentRunLease.tokenHeader, lease.secret)
        ..set(AgentRunLease.callTokenHeader, tokenOf(wait));
      request.write(
        jsonEncode({
          'tool_name': 'Bash',
          'tool_input': {
            'command': 'git push origin feature/x',
            'description': 'Push the branch',
          },
        }),
      );
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      expect(body.trim(), 'allow');
      expect(heard, [true, false]);
    },
  );

  test('the agent run client and git both send the call token beside the '
      'secret', () async {
    final seen = <(String?, List<String>?)>[];
    final recorder = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    recorder.listen((request) async {
      seen.add((
        request.headers.value(AgentRunLease.tokenHeader),
        request.headers[AgentRunLease.callTokenHeader],
      ));
      await request.drain<void>();
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
    });
    final elsewhere = AgentRunGateway(
      guard: ActionGuardService(repository: _Rules()),
      broker: _Broker(),
      loopbackBase: () async => Uri.parse('http://127.0.0.1:${recorder.port}'),
    );
    final run = (await elsewhere.open(
      const AgentRunGrant(
        workspaceId: 'w1',
        conversationId: 'c1',
        mcpEndpoint: true,
        claudeHook: true,
        readOnly: false,
      ),
    ))!;
    final home = Directory.systemTemp.createTempSync('cc_call_token_');
    try {
      final base = {
        'GIT_CONFIG_NOSYSTEM': '1',
        'GIT_CONFIG_GLOBAL': '${home.path}/no-gitconfig',
        'GIT_TERMINAL_PROMPT': '0',
        'HOME': home.path,
        'PATH': Platform.environment['PATH'] ?? '/usr/bin:/bin',
      };
      final env = {...base, ...run.environment(base)};
      final wait = run.register((_) {}, env, decided: (_) {});
      final commandEnv = {...env, ...wait.environment};

      await Process.run('git', [
        'ls-remote',
        '${run.base}/agent/git/github.com/acme/widgets.git',
      ], environment: commandEnv);
      await runAgentRunClient(
        const ['forge-token', 'acme/widgets'],
        environment: commandEnv,
        output: IOSink(_Drain()),
        errors: IOSink(_Drain()),
      );

      expect(seen, hasLength(greaterThanOrEqualTo(2)));
      for (final (secret, calls) in seen) {
        expect(secret, run.secret);
        expect(calls, [tokenOf(wait)]);
      }
    } finally {
      await recorder.close(force: true);
      home.deleteSync(recursive: true);
    }
  }, skip: Platform.isWindows ? 'Uses the POSIX git.' : false);
}

const _widgets = (forge: ForgeHost.github, owner: 'acme', name: 'widgets');

/// A receive-pack body updating [ref]: its commands, a flush and the pack.
List<int> _push(String ref) => utf8.encode(
  [
    _pkt('${'0' * 40} ${'1' * 40} $ref\u0000report-status side-band-64k\n'),
    '0000',
    'PACK-bytes',
  ].join(),
);

String _pkt(String line) =>
    '${(line.length + 4).toRadixString(16).padLeft(4, '0')}$line';

class _Rules implements ActionPolicyRepository {
  @override
  Future<List<ActionPolicyRule>> rules(String workspaceId) async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Answers [answer], or holds the answer until [pending] completes.
class _Confirm implements ConfirmationPort {
  bool answer = true;
  final List<ConfirmationRequest> asked = [];
  Completer<bool>? pending;
  Completer<void>? requested;

  void hold() {
    pending = Completer<bool>();
    requested = Completer<void>();
  }

  @override
  Future<bool> requestApproval(ConfirmationRequest request) async {
    asked.add(request);
    requested?.complete();
    return pending?.future ?? answer;
  }
}

/// No environment: every command here is decided before one is read.
class _NoEnvironments implements EnvironmentPort {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoContext implements AgentEnvironmentContext {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Mints nothing: no test here gets as far as forwarding a push.
class _Broker implements CredentialBrokerPort {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Takes whatever is written and keeps none of it.
class _Drain implements StreamConsumer<List<int>> {
  @override
  Future<void> addStream(Stream<List<int>> stream) => stream.drain<void>();

  @override
  Future<void> close() async {}
}
