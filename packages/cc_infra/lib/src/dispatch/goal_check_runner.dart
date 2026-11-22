import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/core/domain/ports/workspace_filesystem_port.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/features/dispatch/domain/ports/worktree_fingerprint_port.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_checks_outcome.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_contract.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_verification.dart';
import 'package:cc_domain/features/environments/domain/entities/environment_run.dart';
import 'package:cc_domain/features/environments/domain/ports/environment_port.dart';
import 'package:cc_domain/features/guardrails/domain/services/action_guard_service.dart';
import 'package:cc_domain/features/sandboxing/domain/host_execution_posture.dart';
import 'package:cc_infra/src/dispatch/host_execution_gate.dart';
import 'package:cc_infra/src/dispatch/network_egress.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:cc_infra/src/process/child_process.dart';
import 'package:cc_infra/src/process/process_tree.dart';
import 'package:cc_infra/src/sandboxing/process_group_supervisor.dart';
import 'package:cc_infra/src/sandboxing/process_sandbox.dart';
import 'package:cc_infra/src/sandboxing/sandbox_manager.dart';
import 'package:cc_natives/cc_natives.dart' show IsolatedGit;
import 'package:path/path.dart' as p;

/// Starts one check's process: [ChildProcess.start] with the toolchain on
/// the path, or a fake in tests.
typedef GoalCheckProcessStarter =
    Future<Process> Function(
      String executable,
      List<String> arguments, {
      required String workingDirectory,
      required Map<String, String> environment,
    });

/// Runs a goal's checks (plan section 8, "Checks"): each worktree command in
/// a one-shot sandbox over the conversation's worktree, confined like the
/// agent's own `bash`, and each environment check as the space environment's
/// task, the same path `environment_run_task` takes. Checks run in contract
/// order; a failing check does not stop the rest.
///
/// Without a sandbox nothing runs: a goal's checks are automation, not a
/// person at the host, so there is no owner fallback
/// ([GoalChecksStatus.sandboxUnavailable], kind `sandbox_unavailable`). The
/// one exception is [HostExecutionPosture.offByOwner]: the owner turned the
/// sandbox off for every run, the agent's own `bash` runs unconfined there,
/// and the checks run as it does.
///
/// A check that cannot run as written is broken, not failed: exit 126 or
/// 127, a spawn failure, no worktree to run in, or an environment task that
/// does not exist or is blocked. Exits 1 and 2 are ordinary failures.
final class GoalCheckRunner {
  /// Creates a runner.
  GoalCheckRunner({
    required this.gate,
    required this.sandboxManager,
    required this.filesystem,
    required this.fingerprints,
    required this.environments,
    this.protectedPaths,
    this.actionGuard,
    GoalCheckProcessStarter? start,
    this.killTree = ChildProcess.killTree,
    this.pipeGrace = const Duration(seconds: 2),
  }) : _start = start ?? _childProcessStart;

  /// The server's posture.
  final HostExecutionGate gate;

  /// Wraps a check in the sandbox; null when this host has none.
  final SandboxManager? sandboxManager;

  /// Where a space's worktrees are: `<space dir>/repos/<slug>`.
  final WorkspaceFilesystemPort filesystem;

  /// The worktree fingerprint taken before the checks run.
  final WorktreeFingerprintPort fingerprints;

  /// Runs environment checks; null when the server has no environments, in
  /// which case an environment check is broken.
  final EnvironmentPort? environments;

  /// The workspace's source checkouts, which no sandbox may write.
  final Future<List<String>> Function(String workspaceId)? protectedPaths;

  /// Reads the workspace's network-egress rule.
  final ActionGuardService? actionGuard;

  /// Ends a check's process tree on its timeout.
  final ProcessTreeKill killTree;

  /// How long the pipes may stay open after the check exits.
  final Duration pipeGrace;

  final GoalCheckProcessStarter _start;

  static int _sessions = 0;

  static Future<Process> _childProcessStart(
    String executable,
    List<String> arguments, {
    required String workingDirectory,
    required Map<String, String> environment,
  }) => ChildProcess.start(
    executable,
    arguments,
    workingDirectory: workingDirectory,
    environment: environment,
    toolchain: true,
  );

  /// Runs [contract]'s checks for [agentId]'s goal in [conversationId] of
  /// [spaceId] in [workspaceId].
  Future<GoalChecksOutcome> run({
    required String workspaceId,
    required String spaceId,
    required String conversationId,
    required String agentId,
    required GoalContract contract,
  }) async {
    final fingerprint = await _fingerprint(workspaceId, conversationId);
    final checks = contract.checks;
    final hasWorktreeChecks = checks.any(
      (check) => check.where == GoalCheckLocation.worktree,
    );
    final manager = sandboxManager;
    final confined =
        gate.posture == HostExecutionPosture.sandboxed && manager != null;
    if (hasWorktreeChecks &&
        !confined &&
        gate.posture != HostExecutionPosture.offByOwner) {
      return GoalChecksOutcome.sandboxUnavailable(fingerprint: fingerprint);
    }

    final workdir = hasWorktreeChecks
        ? await _workdir(workspaceId, spaceId)
        : null;
    final sessionId = 'goal-check-${++_sessions}';
    _Spawn? spawn;
    if (workdir != null) {
      try {
        spawn = confined
            ? await _confined(manager, sessionId, workspaceId, agentId, workdir)
            : _Spawn.unconfined;
      } on Object catch (e) {
        // The sandbox could not be set up: as without one, nothing runs.
        CcInfraLog.warning('goal check: sandbox setup failed: $e');
        await _release(manager, sessionId, confined: confined);
        return GoalChecksOutcome.sandboxUnavailable(fingerprint: fingerprint);
      }
    }
    final results = <GoalCheckResult>[];
    try {
      for (final check in checks) {
        if (check.where == GoalCheckLocation.environment) {
          results.add(
            await _environmentCheck(workspaceId, spaceId, agentId, check),
          );
        } else if (workdir == null || spawn == null) {
          results.add(
            _brokenResult(
              check,
              'This conversation has no worktree to run in.',
            ),
          );
        } else {
          results.add(await _worktreeCheck(check, workdir, spawn));
        }
      }
    } finally {
      if (spawn != null) {
        await _release(manager, sessionId, confined: confined);
      }
    }
    return GoalChecksOutcome(
      status: GoalChecksStatus.ran,
      results: results,
      fingerprint: fingerprint,
    );
  }

  static Future<void> _release(
    SandboxManager? manager,
    String sessionId, {
    required bool confined,
  }) async {
    if (!confined || manager == null) {
      return;
    }
    try {
      await manager.disposeSession(sessionId);
    } on Object catch (e) {
      CcInfraLog.warning('goal check: sandbox session release failed: $e');
    }
  }

  Future<String?> _fingerprint(
    String workspaceId,
    String conversationId,
  ) async {
    try {
      return await fingerprints.fingerprint(
        workspaceId: workspaceId,
        conversationId: conversationId,
      );
    } on Object catch (e) {
      CcInfraLog.warning('goal check: fingerprint failed: $e');
      return null;
    }
  }

  /// The conversation's worktree: the one checkout of the space, or the
  /// `repos` directory over several. Null when there is none.
  Future<String?> _workdir(String workspaceId, String spaceId) async {
    try {
      final reposDir = Directory(
        p.join(await filesystem.spaceDir(workspaceId, spaceId), 'repos'),
      );
      if (!reposDir.existsSync()) {
        return null;
      }
      final worktrees = reposDir
          .listSync(followLinks: false)
          .whereType<Directory>()
          .toList();
      return switch (worktrees.length) {
        0 => null,
        1 => worktrees.single.path,
        _ => reposDir.path,
      };
    } on Object catch (e) {
      CcInfraLog.warning('goal check: worktree lookup failed: $e');
      return null;
    }
  }

  Future<_Spawn> _confined(
    SandboxManager manager,
    String sessionId,
    String workspaceId,
    String agentId,
    String workdir,
  ) async {
    final config = await processSandboxConfig(
      processSandboxSpec(
        sessionId: sessionId,
        workspaceId: workspaceId,
        agentId: agentId,
        workdir: workdir,
        networkEnabled: await resolveNetworkEgress(
          actionGuard,
          workspaceId: workspaceId,
          mode: Mode.chat,
          label: 'goal check',
          agentId: agentId,
        ),
        mode: Mode.chat,
        protectedPaths: await _protected(workspaceId),
        execGrantRoots: const [],
        loopbackPorts: const [],
        environmentScope: null,
      ),
    );
    return _Spawn((argv) async {
      final wrap = await manager.wrap(
        config: config,
        argv: argv,
        workingDirectory: workdir,
      );
      return (
        executable: wrap.executable,
        argv: wrap.argv,
        environment: wrap.environment,
      );
    });
  }

  Future<List<String>> _protected(String workspaceId) async {
    final resolve = protectedPaths;
    if (resolve == null) {
      return const [];
    }
    try {
      return await resolve(workspaceId);
    } on Object catch (e) {
      CcInfraLog.warning('goal check: protected-paths lookup failed: $e');
      return const [];
    }
  }

  Future<GoalCheckResult> _worktreeCheck(
    GoalCheck check,
    String workdir,
    _Spawn spawn,
  ) async {
    final marker = newProcessTreeMarker();
    final Process process;
    try {
      final prepared = await spawn.prepare(['bash', '-lc', check.run]);
      final launch = canSuperviseProcessGroup
          ? superviseProcessGroup(prepared.executable, prepared.argv)
          : (executable: prepared.executable, argv: prepared.argv);
      process = await _start(
        launch.executable,
        launch.argv,
        workingDirectory: workdir,
        environment: {
          ...prepared.environment,
          // No host git configuration: no credential helper, no global hooks
          // or signing program.
          ...IsolatedGit.isolationEnvironment,
          processTreeMarkerVariable: marker,
        },
      );
    } on Object catch (e) {
      return _brokenResult(check, 'The check could not be started: $e');
    }

    final tail = _Tail(GoalCheckResult.maxOutputTail);
    const decoder = Utf8Decoder(allowMalformed: true);
    final outSub = process.stdout.transform(decoder).listen(tail.add);
    final errSub = process.stderr.transform(decoder).listen(tail.add);
    var exited = false;
    unawaited(process.exitCode.then((_) => exited = true));
    var timedOut = false;
    final exitCode = await process.exitCode.timeout(
      Duration(seconds: check.timeoutSeconds),
      onTimeout: () async {
        timedOut = true;
        await killTree(process.pid, exited: () => exited, marker: marker);
        return -1;
      },
    );
    await Future.wait([
      outSub.asFuture<void>(),
      errSub.asFuture<void>(),
    ]).timeout(pipeGrace, onTimeout: () => const <void>[]);
    await outSub.cancel();
    await errSub.cancel();
    if (timedOut) {
      return GoalCheckResult(
        run: check.run,
        where: check.where,
        timedOut: true,
        outputTail: tail.text,
      );
    }
    return GoalCheckResult(
      run: check.run,
      where: check.where,
      exitCode: exitCode,
      outputTail: tail.text,
      broken: exitCode == 126 || exitCode == 127,
    );
  }

  Future<GoalCheckResult> _environmentCheck(
    String workspaceId,
    String spaceId,
    String agentId,
    GoalCheck check,
  ) async {
    final port = environments;
    if (port == null) {
      return _brokenResult(check, 'This server runs no environments.');
    }
    final EnvironmentRun run;
    try {
      run = await port
          .runTask(workspaceId, spaceId, check.run, by: AgentPrincipal(agentId))
          .timeout(Duration(seconds: check.timeoutSeconds));
    } on TimeoutException {
      // The task keeps running in the environment; only the wait ends.
      return GoalCheckResult(
        run: check.run,
        where: check.where,
        timedOut: true,
      );
    } on Object catch (e) {
      return _brokenResult(check, '$e');
    }
    final output = _Tail(GoalCheckResult.maxOutputTail)
      ..add(run.output)
      ..add(run.error == null || run.error!.isEmpty ? '' : '\n${run.error}');
    return switch (run.status) {
      EnvironmentRunStatus.blocked => _brokenResult(check, output.text),
      EnvironmentRunStatus.timedOut => GoalCheckResult(
        run: check.run,
        where: check.where,
        timedOut: true,
        outputTail: output.text,
      ),
      EnvironmentRunStatus.succeeded => GoalCheckResult(
        run: check.run,
        where: check.where,
        exitCode: run.exitCode ?? 0,
        outputTail: output.text,
      ),
      EnvironmentRunStatus.failed ||
      EnvironmentRunStatus.running => GoalCheckResult(
        run: check.run,
        where: check.where,
        // A failed run that reports no code still did not pass.
        exitCode: run.exitCode == null || run.exitCode == 0 ? 1 : run.exitCode,
        outputTail: output.text,
      ),
    };
  }

  static GoalCheckResult _brokenResult(GoalCheck check, String why) {
    final tail = _Tail(GoalCheckResult.maxOutputTail)..add(why);
    return GoalCheckResult(
      run: check.run,
      where: check.where,
      broken: true,
      outputTail: tail.text,
    );
  }
}

/// How a worktree check's argv is turned into what is spawned.
final class _Spawn {
  const _Spawn(this.prepare);

  static final _Spawn unconfined = _Spawn(
    (argv) async => (
      executable: argv.first,
      argv: argv.sublist(1),
      environment: const <String, String>{},
    ),
  );

  final Future<
    ({String executable, List<String> argv, Map<String, String> environment})
  >
  Function(List<String> argv)
  prepare;
}

/// The last [max] characters of a stream of text, in bounded memory.
final class _Tail {
  _Tail(this.max);

  final int max;
  String _text = '';

  void add(String chunk) {
    if (chunk.isEmpty) {
      return;
    }
    final joined = _text + chunk;
    _text = joined.length > max
        ? joined.substring(joined.length - max)
        : joined;
  }

  String get text => _text;
}
