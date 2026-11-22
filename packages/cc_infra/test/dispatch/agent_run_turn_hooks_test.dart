import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/core/domain/ports/confirmation_port.dart';
import 'package:cc_domain/core/domain/ports/credential_broker_port.dart';
import 'package:cc_domain/features/guardrails/domain/entities/action_policy_rule.dart';
import 'package:cc_domain/features/guardrails/domain/repositories/action_policy_repository.dart';
import 'package:cc_domain/features/guardrails/domain/services/action_guard_service.dart';
import 'package:cc_infra/src/dispatch/agent_run_gateway.dart';
import 'package:test/test.dart';

/// Claude Code's `Stop` and `PreCompact` hooks: registered in the settings
/// file the gateway writes only when the owner configured the scripts, and
/// answered by the gateway through the real agent run client.

class _Rules implements ActionPolicyRepository {
  @override
  Future<List<ActionPolicyRule>> rules(String workspaceId) async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Confirm implements ConfirmationPort {
  @override
  Future<bool> requestApproval(ConfirmationRequest request) async => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Broker implements CredentialBrokerPort {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Programmed scripts: [stopAnswers] in turn (null = let the turn end).
class _Scripts implements ClaudeTurnHookScripts {
  _Scripts({
    this.hasStop = true,
    this.hasPreCompact = true,
    this.stopAnswers = const [],
    this.focus,
  });

  @override
  final bool hasStop;
  @override
  final bool hasPreCompact;
  final List<String?> stopAnswers;
  final String? focus;
  final List<Map<String, Object?>> stopEvents = [];
  final List<Map<String, Object?>> preCompactEvents = [];

  @override
  Future<String?> stop(Map<String, Object?> event) async {
    stopEvents.add(event);
    final i = stopEvents.length - 1;
    return i < stopAnswers.length ? stopAnswers[i] : null;
  }

  @override
  Future<String?> preCompact(Map<String, Object?> event) async {
    preCompactEvents.add(event);
    return focus;
  }
}

Object _needsPosixShell() =>
    Platform.isWindows ? 'the hook commands are POSIX shell' : false;

void main() {
  late HttpServer host;
  late AgentRunGateway gateway;

  setUp(() async {
    host = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    gateway = AgentRunGateway(
      guard: ActionGuardService(
        repository: _Rules(),
        confirmationPort: _Confirm(),
      ),
      broker: _Broker(),
      loopbackBase: () async => Uri.parse('http://127.0.0.1:${host.port}'),
    );
    host.listen(gateway.handle);
  });

  tearDown(() => host.close(force: true));

  Future<AgentRunLease> open({
    ClaudeTurnHookScripts? scripts,
    bool claudeHook = true,
  }) async => (await gateway.open(
    AgentRunGrant(
      workspaceId: 'w1',
      conversationId: 'c1',
      mcpEndpoint: true,
      claudeHook: claudeHook,
      readOnly: false,
      claudeTurnHooks: scripts,
      agentId: 'a1',
    ),
  ))!;

  Map<Object?, Object?> hooksOf(AgentRunLease lease) =>
      (jsonDecode(
            AgentRunLease.claudeHookSettings(lease, readOnly: false),
          ) as Map)['hooks']
          as Map;

  /// Runs the registered command of [event] with [input] on stdin.
  Future<({int exitCode, String out, String err})> run(
    AgentRunLease lease,
    String event,
    Map<String, Object?> input,
  ) async {
    final entry = (hooksOf(lease)[event] as List).single as Map;
    final handler = (entry['hooks'] as List).single as Map;
    final process = await Process.start(
      'sh',
      ['-c', handler['command'] as String],
      environment: {AgentRunLease.tokenEnvKey: lease.secret},
    );
    final out = process.stdout.transform(utf8.decoder).join();
    final err = process.stderr.transform(utf8.decoder).join();
    process.stdin.write(jsonEncode(input));
    await process.stdin.close();
    return (exitCode: await process.exitCode, out: await out, err: await err);
  }

  group('the settings file', () {
    test('registers Stop and PreCompact when the owner has both', () async {
      final hooks = hooksOf(await open(scripts: _Scripts()));
      for (final event in ['Stop', 'PreCompact']) {
        final entry = (hooks[event] as List).single as Map;
        // No matcher: a Stop or PreCompact hook applies to every event.
        expect(entry.containsKey('matcher'), isFalse);
        final handler = (entry['hooks'] as List).single as Map;
        expect(handler['type'], 'command');
        expect(handler['timeout'], AgentRunGateway.turnHookTimeout.inSeconds);
      }
      expect(
        (((hooks['Stop'] as List).single as Map)['hooks'] as List).single,
        containsPair('command', endsWith(' stop')),
      );
      expect(
        (((hooks['PreCompact'] as List).single as Map)['hooks'] as List).single,
        containsPair('command', endsWith(' pre-compact')),
      );
      expect(hooks.containsKey('PreToolUse'), isTrue);
    });

    test('registers only what is configured', () async {
      final onlyStop = hooksOf(
        await open(scripts: _Scripts(hasPreCompact: false)),
      );
      expect(onlyStop.containsKey('Stop'), isTrue);
      expect(onlyStop.containsKey('PreCompact'), isFalse);
      final onlyPreCompact = hooksOf(
        await open(scripts: _Scripts(hasStop: false)),
      );
      expect(onlyPreCompact.containsKey('Stop'), isFalse);
      expect(onlyPreCompact.containsKey('PreCompact'), isTrue);
      final none = hooksOf(await open());
      expect(none.keys, ['PreToolUse']);
      final noLease =
          (jsonDecode(
            AgentRunLease.claudeHookSettings(null, readOnly: false),
          ) as Map)['hooks']
              as Map;
      expect(noLease.keys, ['PreToolUse']);
    });
  });

  group('the hooks, end to end', () {
    test('a block exits 2 with the owner\'s text on stderr', () async {
      final scripts = _Scripts(stopAnswers: ['Run the tests first.']);
      final lease = await open(scripts: scripts);
      final result = await run(lease, 'Stop', {
        'hook_event_name': 'Stop',
        'stop_hook_active': false,
        'last_assistant_message': 'All done.',
      });
      expect(result.exitCode, 2);
      expect(result.err.trim(), 'Run the tests first.');
      expect(scripts.stopEvents.single, {
        'event': 'stop',
        'last_message': 'All done.',
        'stop_hook_active': false,
      });
    });

    test('Claude Code\'s stop_hook_active reaches the script (A7)', () async {
      final scripts = _Scripts();
      final lease = await open(scripts: scripts);
      await run(lease, 'Stop', {
        'hook_event_name': 'Stop',
        'stop_hook_active': true,
        'last_assistant_message': 'Done again.',
      });
      await run(lease, 'Stop', {'hook_event_name': 'Stop'});
      expect(scripts.stopEvents.map((e) => e['stop_hook_active']), [
        true,
        false,
      ]);
    });

    test('no block exits 0 and the turn ends', () async {
      final lease = await open(scripts: _Scripts());
      final result = await run(lease, 'Stop', {'hook_event_name': 'Stop'});
      expect(result.exitCode, 0);
      expect(result.err, isEmpty);
    });

    test('a gateway that does not answer lets the turn end', () async {
      final lease = await open(scripts: _Scripts(stopAnswers: ['block']));
      final entry = (hooksOf(lease)['Stop'] as List).single as Map;
      final handler = (entry['hooks'] as List).single as Map;
      await host.close(force: true);
      final process = await Process.start(
        'sh',
        ['-c', handler['command'] as String],
        environment: {AgentRunLease.tokenEnvKey: lease.secret},
      );
      unawaited(process.stdout.drain<void>());
      unawaited(process.stderr.drain<void>());
      await process.stdin.close();
      expect(await process.exitCode, 0);
    });

    test('pre-compact prints the owner\'s text and exits 0', () async {
      final scripts = _Scripts(focus: 'Keep the migration plan.');
      final lease = await open(scripts: scripts);
      final result = await run(lease, 'PreCompact', {
        'hook_event_name': 'PreCompact',
        'trigger': 'auto',
        'custom_instructions': '',
      });
      expect(result.exitCode, 0);
      expect(result.out.trim(), 'Keep the migration plan.');
      expect(scripts.preCompactEvents.single, {
        'event': 'pre_compact',
        'trigger': 'auto',
      });
    });

    test('pre-compact with nothing to add prints nothing', () async {
      final lease = await open(scripts: _Scripts());
      final result = await run(lease, 'PreCompact', {'trigger': 'manual'});
      expect(result.exitCode, 0);
      expect(result.out, isEmpty);
    });
  }, skip: _needsPosixShell());

  group('the routes', () {
    Future<int> post(AgentRunLease lease, String path) async {
      final client = HttpClient();
      try {
        final request = await client.post('127.0.0.1', host.port, path);
        request.headers.set(AgentRunLease.tokenHeader, lease.secret);
        request.write('{}');
        final response = await request.close();
        await response.drain<void>();
        return response.statusCode;
      } finally {
        client.close(force: true);
      }
    }

    test('refuse a run without the owner\'s scripts', () async {
      final lease = await open();
      expect(await post(lease, AgentRunGateway.stopHookPath), 401);
      expect(await post(lease, AgentRunGateway.preCompactHookPath), 401);
    });

    test('refuse a run that is not Claude Code', () async {
      final lease = await open(scripts: _Scripts(), claudeHook: false);
      expect(await post(lease, AgentRunGateway.stopHookPath), 401);
      expect(await post(lease, AgentRunGateway.preCompactHookPath), 401);
    });
  });
}
