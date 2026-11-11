import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/features/guardrails/domain/services/action_guard_service.dart';
import 'package:cc_domain/features/sandboxing/domain/host_execution_posture.dart';
import 'package:cc_infra/src/dispatch/dispatch_session_deps.dart';
import 'package:cc_infra/src/dispatch/host_execution_gate.dart';
import 'package:cc_infra/src/dispatch/network_egress.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:cc_infra/src/sandboxing/process_sandbox.dart';
import 'package:cc_infra/src/sandboxing/sandbox_manager.dart';

/// One way to start an ACP one-shot: [prepare] turns the CLI's argv into what
/// is spawned, and [release] frees what that took once the process is gone.
final class OneShotSpawn {
  /// Creates a [OneShotSpawn].
  const OneShotSpawn({required this.prepare, required this.release});

  /// Starts the argv as it is, on the host.
  static final OneShotSpawn unconfined = OneShotSpawn(
    prepare: (argv) async => (
      executable: argv.first,
      argv: argv.sublist(1),
      environment: const <String, String>{},
    ),
    release: () async {},
  );

  /// The executable, arguments and extra environment to spawn an argv with.
  final Future<
    ({String executable, List<String> argv, Map<String, String> environment})
  >
  Function(List<String> argv)
  prepare;

  /// Frees the sandbox session, when there is one.
  final Future<void> Function() release;
}

/// Where an ACP one-shot (a title, a side question, a goal step) may run.
///
/// The ACP CLI is the server OS user's own install with that user's personal
/// config, and it decides for itself whether to ask before using its tools,
/// so a member's text must not reach it unconfined on the host. Decided from
/// the dependencies a dispatched agent run uses: the posture and owner fact
/// of [gate], the sandbox manager, the workspace's protected checkouts and the
/// network-egress rule.
final class OneShotConfinement {
  /// Creates a [OneShotConfinement].
  const OneShotConfinement({
    required this.gate,
    this.sandboxManager,
    this.protectedPaths,
    this.actionGuard,
  });

  /// The confinement a dispatched run with [deps] would get.
  factory OneShotConfinement.of(SandboxDispatchDeps deps) => OneShotConfinement(
    gate: deps.hostExecution,
    sandboxManager: deps.sandboxManager,
    protectedPaths: deps.protectedPathsResolver,
    actionGuard: deps.actionGuard,
  );

  /// The posture and the owner fact.
  final HostExecutionGate gate;

  /// Wraps a confined one-shot; null when this host does not sandbox.
  final SandboxManager? sandboxManager;

  /// The workspace's source checkouts, which no sandbox may write.
  final Future<List<String>> Function(String workspaceId)? protectedPaths;

  /// Reads the network-egress rule.
  final ActionGuardService? actionGuard;

  static int _sessions = 0;

  /// How a one-shot [requestedByUserId] asked for in [workspaceId] starts in
  /// [workdir], or null when it may not run here.
  ///
  /// - [HostExecutionPosture.sandboxed]: inside the sandbox a dispatched ACP
  ///   run gets, in a session of its own: [workdir] writable, the data dir
  ///   and the workspace's checkouts out of reach, the network as the
  ///   workspace's rule allows it.
  /// - [HostExecutionPosture.offByOwner]: unconfined; the owner chose that
  ///   for everyone.
  /// - [HostExecutionPosture.unavailable], or a sandboxed posture with no
  ///   manager to confine with: unconfined only when the server owner is
  ///   accountable for the request, otherwise null.
  Future<OneShotSpawn?> spawnFor({
    required String? workspaceId,
    required String? requestedByUserId,
    required String workdir,
  }) async {
    final manager = sandboxManager;
    if (gate.posture == HostExecutionPosture.sandboxed && manager != null) {
      return _confined(manager, workspaceId: workspaceId, workdir: workdir);
    }
    if (gate.posture == HostExecutionPosture.offByOwner) {
      return OneShotSpawn.unconfined;
    }
    return await _ownerAccountable(workspaceId, requestedByUserId)
        ? OneShotSpawn.unconfined
        : null;
  }

  Future<OneShotSpawn> _confined(
    SandboxManager manager, {
    required String? workspaceId,
    required String workdir,
  }) async {
    final sessionId = 'oneshot-${++_sessions}';
    final config = await processSandboxConfig(
      processSandboxSpec(
        sessionId: sessionId,
        workspaceId: workspaceId ?? '',
        workdir: workdir,
        networkEnabled: await resolveNetworkEgress(
          actionGuard,
          workspaceId: workspaceId,
          mode: Mode.chat,
          label: 'one-shot',
        ),
        mode: Mode.chat,
        protectedPaths: await _protected(workspaceId),
        execGrantRoots: const [],
        loopbackPorts: const [],
        environmentScope: null,
      ),
    );
    return OneShotSpawn(
      prepare: (argv) async {
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
      },
      release: () => manager.disposeSession(sessionId),
    );
  }

  Future<List<String>> _protected(String? workspaceId) async {
    final resolve = protectedPaths;
    if (resolve == null || workspaceId == null || workspaceId.isEmpty) {
      return const [];
    }
    try {
      return await resolve(workspaceId);
    } on Object catch (e) {
      CcInfraLog.warning('one-shot: protected-paths lookup failed: $e');
      return const [];
    }
  }

  Future<bool> _ownerAccountable(
    String? workspaceId,
    String? requestedByUserId,
  ) async {
    final ownerAccountable = gate.ownerAccountable;
    if (ownerAccountable == null) {
      return false;
    }
    try {
      return await ownerAccountable(
        workspaceId: workspaceId,
        requestedByUserId: requestedByUserId,
      );
    } on Object catch (e) {
      CcInfraLog.warning('one-shot: owner check failed, not running: $e');
      return false;
    }
  }
}
