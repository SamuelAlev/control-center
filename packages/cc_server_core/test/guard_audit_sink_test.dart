import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/core/domain/events/agent_events.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/features/environments/domain/ports/environment_port.dart';
import 'package:cc_domain/features/evals/domain/value_objects/agent_config_hash.dart'
    show canonicalHash;
import 'package:cc_domain/features/guardrails/domain/entities/action_policy_rule.dart';
import 'package:cc_domain/features/guardrails/domain/entities/guard_decision.dart';
import 'package:cc_domain/features/guardrails/domain/repositories/action_policy_repository.dart';
import 'package:cc_domain/features/guardrails/domain/services/action_guard_service.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_decision.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_infra/src/dispatch/agent_environment_gateway.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_server_core/src/agent_action_blocked_publisher.dart';
import 'package:cc_server_core/src/catalog/catalog_wire.dart'
    show guardDecisionToWire;
import 'package:cc_server_core/src/guard_audit_sink.dart';
import 'package:drift/native.dart';
import 'package:test/test.dart';

/// Every guard verdict reaches the workspace's hash-chained audit bounded:
/// a summary is stored whole up to 16 KiB and cut with its full length past
/// that; the denial's log line and blocked-action event carry at most 2 KiB.
void main() {
  late Directory tmp;
  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;
  late DaoGuardDecisionRepository repo;
  late DomainEventBus bus;
  late List<AgentActionBlocked> blocked;
  late List<GuardDecision> siem;
  late List<String> logged;
  late GuardAuditSink sink;
  const ws = 'ws-1';

  setUp(() async {
    tmp = Directory.systemTemp.createTempSync('guard_audit_sink_');
    global = GlobalDatabase.forTesting(NativeDatabase.memory());
    dbs = WorkspaceDatabaseManager(
      dataDir: tmp.path,
      global: global,
      executorFactory: (id) =>
          NativeDatabase(File(workspaceDatabasePath(tmp.path, id))),
    );
    await dbs.loadInstallId();
    repo = DaoGuardDecisionRepository(dbs);
    bus = DomainEventBus();
    blocked = [];
    bus.on<AgentActionBlocked>().listen(blocked.add);
    siem = [];
    logged = [];
    CcHostLog.sink = (level, message, [error, stackTrace]) =>
        logged.add(message);
    sink = GuardAuditSink(
      decisions: repo,
      blocked: AgentActionBlockedPublisher(eventBus: bus, agents: _Agents()),
      siem: siem.add,
    );
  });

  tearDown(() async {
    CcHostLog.sink = null;
    bus.dispose();
    await dbs.closeAll();
    await global.close();
    if (tmp.existsSync()) {
      tmp.deleteSync(recursive: true);
    }
  });

  GuardAudit audit(
    String summary, {
    ActionDecision decision = ActionDecision.allow,
    String? command,
  }) => GuardAudit(
    workspaceId: ws,
    decision: decision,
    reason: 'by rule',
    source: 'workspace',
    agentId: 'agent-1',
    actionSummary: summary,
    command: command,
  );

  /// The appends are fire-and-forget; waits until [count] rows are stored.
  Future<List<GuardDecision>> stored(int count) async {
    for (var i = 0; i < 600; i++) {
      final rows = await repo.pageFrom(ws, 1, limit: count + 1);
      if (rows.length >= count) {
        return rows;
      }
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    fail('$count rows were not stored');
  }

  int bytes(String s) => utf8.encode(s).length;

  test('500 script commands at the bound are stored whole, 500 × 16 KiB, and '
      'the chain verifies', () async {
    final command = 'a' * (GuardDecision.maxActionNameBytes - 6);
    expect(
      ActionGuardService.scriptActionRefusal('bash: $command'),
      isNull,
      reason: 'a script may run it',
    );
    for (var i = 0; i < 500; i++) {
      sink.record(audit('bash: $command', command: command));
    }

    final rows = await stored(500);
    expect(rows, hasLength(500));
    expect(rows.every((r) => r.actionName == 'bash: $command'), isTrue);
    expect(
      rows.fold<int>(0, (n, r) => n + bytes(r.actionName)),
      500 * GuardDecision.maxActionNameBytes,
    );
    expect((await repo.verifyChain(ws)).intact, isTrue);
  });

  test('a card nobody answered is stored and copied as unanswered, apart '
      'from a decline, and raises no blocked-action event', () async {
    for (final unanswered in [true, false]) {
      sink.record(
        GuardAudit(
          workspaceId: ws,
          decision: ActionDecision.deny,
          reason: 'by rule',
          source: 'workspace',
          agentId: 'agent-1',
          actionSummary: 'git push',
          prompted: true,
          unanswered: unanswered,
        ),
      );
    }
    final rows = await stored(2);
    expect([for (final r in rows) r.unanswered], [true, false]);
    expect([for (final d in siem) d.unanswered], [true, false]);
    // The audit page's wire names it only when set.
    expect(guardDecisionToWire(rows.first)['unanswered'], isTrue);
    expect(guardDecisionToWire(rows.last).containsKey('unanswered'), isFalse);
    expect((await repo.verifyChain(ws)).intact, isTrue);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(blocked, isEmpty, reason: 'a person was asked');
  });

  test('a direct 100 KiB command is stored cut, with its length and its '
      'digest, and the chain verifies over what is stored', () async {
    final command = 'a' * (100 * 1024);
    sink.record(audit('bash: $command', command: command));

    final row = (await stored(1)).single;
    final full = bytes('bash: $command');
    expect(
      row.actionName,
      '${'bash: $command'.substring(0, GuardDecision.maxActionNameBytes)} … '
      '[cut, $full bytes in full; argsDigest hashes all of it]',
    );
    expect(
      bytes(row.actionName),
      lessThan(GuardDecision.maxActionNameBytes + 80),
    );
    expect(row.argsDigest, canonicalHash({'command': command}));
    expect(siem.single.actionName, row.actionName, reason: 'the SIEM copy');
    expect((await repo.verifyChain(ws)).intact, isTrue);
  });

  test(
    'a command that ends in a forged cut marker is stored at exactly its '
    'own length, at the bound; a real cut is longer than the bound',
    () async {
      const forged =
          ' … [cut, 99999 bytes in full; argsDigest hashes all of it]';
      final pad = GuardDecision.maxActionNameBytes - bytes('bash: $forged');
      final command = '${'f' * pad}$forged';
      expect(bytes('bash: $command'), GuardDecision.maxActionNameBytes);
      sink.record(audit('bash: $command', command: command));
      final cut = 'a' * GuardDecision.maxActionNameBytes;
      sink.record(audit('bash: $cut', command: cut));

      final rows = await stored(2);
      final whole = rows.singleWhere((r) => r.actionName.startsWith('bash: f'));
      expect(whole.actionName, 'bash: $command');
      expect(bytes(whole.actionName), GuardDecision.maxActionNameBytes);
      expect(whole.argsDigest, canonicalHash({'command': command}));
      final real = rows.singleWhere((r) => r != whole);
      expect(
        bytes(real.actionName),
        greaterThan(GuardDecision.maxActionNameBytes),
      );
      expect(real.argsDigest, canonicalHash({'command': cut}));
    },
  );

  test('a script\'s eval cell at the bound is stored whole, its digest over '
      'the cell', () async {
    final cell = 'y' * (GuardDecision.maxActionNameBytes - bytes('eval: '));
    expect(ActionGuardService.scriptActionRefusal('eval: $cell'), isNull);
    sink.record(audit('eval: $cell', command: cell));

    final row = (await stored(1)).single;
    expect(row.actionName, 'eval: $cell');
    expect(row.argsDigest, canonicalHash({'command': cell}));
  });

  test('a chain holding a row stored whole before the bound still verifies '
      'once bounded rows follow it', () async {
    final old = 'bash: ${'b' * (200 * 1024)}';
    await repo.append(
      GuardDecision(
        id: 'old',
        workspaceId: ws,
        occurredAt: DateTime.utc(2026, 1, 1),
        actorType: 'agent',
        actorId: 'agent-1',
        surface: GuardSurface.harness,
        actionName: old,
        decision: ActionDecision.allow,
      ),
    );
    sink.record(audit('bash: ${'c' * (100 * 1024)}'));

    final rows = await stored(2);
    expect(rows.first.actionName, old, reason: 'read back as stored');
    final verification = await repo.verifyChain(ws);
    expect(verification.intact, isTrue);
    expect(verification.rowsChecked, 2);
  });

  test('a denial\'s log line and blocked-action event carry at most 2 KiB of '
      'the summary', () async {
    sink.record(
      audit('bash: ${'d' * (100 * 1024)}', decision: ActionDecision.deny),
    );
    await stored(1);
    for (var i = 0; i < 50 && blocked.isEmpty; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }

    final line = logged.singleWhere((l) => l.startsWith('guardrail deny'));
    final shown = line.substring(
      'guardrail deny [workspace] '.length,
      line.length - ': by rule'.length,
    );
    expect(bytes(shown), lessThanOrEqualTo(kMaxShownActionSummaryBytes));
    expect(shown, endsWith('bytes, truncated]'));
    expect(
      bytes(blocked.single.actionSummary),
      lessThanOrEqualTo(kMaxShownActionSummaryBytes),
    );
    expect(blocked.single.actionSummary, endsWith('bytes, truncated]'));
  });

  group('a gateway command', () {
    const caller = AgentEnvironmentCaller(
      workspaceId: ws,
      spaceId: 'space-1',
      conversationId: 'conversation-1',
      runId: 'run-1',
      scriptApprovals: [],
    );

    /// Runs `docker [arguments]` through the environment gateway, checked by
    /// a real guard that audits into [sink]; the stored row.
    Future<GuardDecision> run(List<String> arguments) async {
      final gateway = AgentEnvironmentGateway(
        environments: _Environments(),
        context: _Context(),
        guard: ActionGuardService(repository: _NoRules(), onAudit: sink.record),
        runHost:
            (
              binary,
              arguments, {
              required workingDirectory,
              environment = const {},
            }) async => const AgentEnvironmentResult(exitCode: 0),
      );
      await gateway.handle(caller, 'docker', arguments);
      return (await stored(1)).single;
    }

    test(
      'of 20 KiB is stored cut, its digest over the whole command',
      () async {
        final arguments = ['compose', 'exec', 'web', 'sh', '-c', 'a' * 20480];
        final command = 'docker ${arguments.join(' ')}';

        final row = await run(arguments);

        expect(
          row.actionName,
          GuardDecision.boundActionName(command, digested: true),
        );
        expect(bytes(row.actionName), lessThan(bytes(command)));
        expect(row.argsDigest, canonicalHash({'command': command}));
        expect((await repo.verifyChain(ws)).intact, isTrue);
      },
    );

    test(
      'under the bound is stored whole, not repeated, with its digest',
      () async {
        final arguments = ['compose', 'exec', 'web', 'ls'];
        final command = 'docker ${arguments.join(' ')}';

        final row = await run(arguments);

        expect(row.actionName, command);
        expect(row.argsDigest, canonicalHash({'command': command}));
      },
    );
  });
}

class _Agents implements AgentRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _NoRules implements ActionPolicyRepository {
  @override
  Future<List<ActionPolicyRule>> rules(String workspaceId) async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Environments implements EnvironmentPort {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A space with a host compose project, which is all `docker compose` reads.
class _Context implements AgentEnvironmentContext {
  @override
  Future<AgentComposeProject?> hostComposeProject(
    String workspaceId,
    String spaceId,
  ) async => const AgentComposeProject(name: 'cc-mine', directory: '/state');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
