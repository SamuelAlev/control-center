import 'dart:async';

import 'package:cc_domain/cc_domain.dart' show NotFoundException;
import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/features/environments/domain/ports/environment_port.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_component.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_definition.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_status.dart';
import 'package:cc_domain/features/rigs/domain/entities/rig.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_image_settings.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_spec.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_status.dart';
import 'package:cc_infra/src/environments/compose_driver.dart'
    show ComposeServiceState;
import 'package:cc_infra/src/environments/compose_plan.dart';
import 'package:cc_infra/src/environments/environment_service_ports.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:cc_infra/src/rigs/environment_rig_compose.dart';
import 'package:cc_infra/src/rigs/environment_rig_quarantine.dart';
import 'package:cc_infra/src/rigs/rig_ports.dart' show RigPortForward;
import 'package:cc_infra/src/rigs/rig_service.dart';
import 'package:cc_infra/src/rigs/smolvm_enclosure_backend.dart';
import 'package:path/path.dart' as p;

export 'package:cc_infra/src/rigs/environment_rig_compose.dart';
export 'package:cc_infra/src/rigs/environment_rig_quarantine.dart'
    show EnvironmentRigStackFailure;

/// Where one compose component's stack lives, on both sides of the mount.
class _ComposeTarget {
  const _ComposeTarget(
    this.component,
    this.hostFile,
    this.guestFile,
    this.root,
  );

  final ComposeEnvironmentComponent component;
  final String hostFile;
  final String guestFile;
  final String root;
}

/// Runs an environment's `compose` and `task` components in a dedicated microVM.
///
/// The compose file runs as it is, with no override: the VM has its own ports
/// and names, so nothing needs rewriting. No host Docker is involved.
class RigEnvironmentHost implements EnvironmentRigHost {
  /// Creates a [RigEnvironmentHost].
  ///
  /// `worktreeOf` finds a space's worktree, for a task that has to boot a
  /// machine with no environment behind it. Null refuses those.
  RigEnvironmentHost(
    this._rigs, {
    this._worktreeOf,
    this._spaceWorktrees,
    this.pollInterval = const Duration(seconds: 1),
    this.forwardTimeout = const Duration(seconds: 20),
    this.openedBy = const AgentPrincipal('environment-service'),
  });

  final RigService _rigs;
  final Future<String?> Function(String workspaceId, String spaceId)?
  _worktreeOf;

  /// The space's registered worktrees: the only directories a rig may mount.
  /// Null refuses every mount, because nothing could vouch for one.
  final Future<List<String>> Function(String workspaceId, String spaceId)?
  _spaceWorktrees;

  /// Admits [paths] as mounts of [spaceId]'s rig: each must be one of the
  /// space's worktrees, and all of them are quarantined.
  Future<void> _admitMounts(
    String workspaceId,
    String spaceId,
    Iterable<String> paths,
  ) async {
    final source = _spaceWorktrees;
    if (source == null) {
      throw const EnvironmentRigStackFailure(
        'This server cannot say which directories belong to the space, so it '
        'mounts none.',
      );
    }
    admitEnvironmentRigMounts(await source(workspaceId, spaceId), paths);
  }

  /// How often readiness is polled.
  final Duration pollInterval;

  /// How long a published port may take to get its host forward.
  final Duration forwardTimeout;

  /// Who rigs are opened as.
  final Principal openedBy;

  /// The slot of a machine that belongs to no environment.
  static const String _taskSlot = 'tasks';

  @override
  Future<EnvironmentRigInstance> start({
    required String workspaceId,
    required String spaceId,
    required String environmentId,
    required EnvironmentDefinition definition,
    required Map<String, String> worktrees,
    required Map<String, String> environment,
    Future<void> Function(String rigId)? onRigOpened,
  }) async {
    final mounts = environmentRigMountPoints(definition, worktrees);
    final targets = [
      for (final component
          in definition.components.whereType<ComposeEnvironmentComponent>())
        _targetOf(component, worktrees, mounts),
    ];
    final existing = _rigs.environmentRigFor(
      workspaceId,
      spaceId,
      environmentId,
    );
    final String rigId;
    if (existing != null) {
      rigId = existing.id;
      await _opened(workspaceId, rigId, onRigOpened);
      await _rigs.resumeEnvironmentRig(workspaceId: workspaceId, rigId: rigId);
    } else {
      final images = {
        for (final target in targets)
          ...composeFileImages(
            target.hostFile,
            variables: {...environment, ...target.component.env},
            services: target.component.services,
            root: target.root,
          ),
      };
      final primary = mounts.entries
          .firstWhere((mount) => mount.value == kSmolvmEnvironmentWorkdir)
          .key;
      // Worked out before anything is quarantined: it throws
      // RigPrivateRegistryException for an image the rig could not pull.
      final egress = environmentRigEgressHosts(images);
      final paths = [for (final role in mounts.keys) worktrees[role]!];
      await _admitMounts(workspaceId, spaceId, paths);
      final Rig opened;
      try {
        opened = await _rigs.open(
          workspaceId: workspaceId,
          spec: RigSpec.environment(
            spaceId: spaceId,
            environmentId: environmentId,
            worktreePath: worktrees[primary]!,
            egressAllowlist: egress,
            ttlHours: definition.policy.rigTtlHours,
            extraMounts: {
              for (final mount in mounts.entries)
                if (mount.key != primary) mount.value: worktrees[mount.key]!,
            },
          ),
          openedBy: openedBy,
        );
      } on Object {
        // Nothing mounted them, so nothing can have changed them.
        releaseEnvironmentRigPaths('(unopened)', paths);
        rethrow;
      }
      rigId = opened.id;
      await _opened(workspaceId, rigId, onRigOpened);
    }
    final Rig rig;
    try {
      rig = await _awaitReady(workspaceId, rigId);
    } on EnvironmentRigStackFailure {
      // A rig that never came up holds nothing worth keeping, and its
      // worktrees stay quarantined for as long as it exists.
      await destroy(workspaceId: workspaceId, rigId: rigId);
      rethrow;
    }
    final endpoints = <EnvironmentEndpoint>[];
    for (final target in targets) {
      endpoints.addAll(
        await _bringUp(workspaceId, rig.id, environmentId, target, {
          ...environment,
          ...target.component.env,
        }),
      );
    }
    return EnvironmentRigInstance(rigId: rig.id, endpoints: endpoints);
  }

  /// Tells the owner about [rigId], closing it when the owner can't take it:
  /// a rig nobody recorded is a rig nobody tears down.
  Future<void> _opened(
    String workspaceId,
    String rigId,
    Future<void> Function(String rigId)? onRigOpened,
  ) async {
    if (onRigOpened == null) {
      return;
    }
    try {
      await onRigOpened(rigId);
    } on Object {
      await destroy(workspaceId: workspaceId, rigId: rigId);
      rethrow;
    }
  }

  _ComposeTarget _targetOf(
    ComposeEnvironmentComponent component,
    Map<String, String> worktrees,
    Map<String, String> mounts,
  ) {
    final primary = mounts.entries
        .firstWhere((mount) => mount.value == kSmolvmEnvironmentWorkdir)
        .key;
    final role = component.cwd?.role ?? primary;
    final worktree = worktrees[role];
    if (worktree == null) {
      throw EnvironmentRigStackFailure(
        'Component "${component.id}" runs in role "$role", which has no '
        'worktree here.',
      );
    }
    final relative = component.cwd?.path ?? '';
    if (relative.isNotEmpty && !isSafeRelativePath(relative)) {
      throw EnvironmentRigStackFailure(
        'Component "${component.id}" runs outside its worktree.',
      );
    }
    final hostDir = p.join(worktree, relative);
    final hostFile = discoverComposeFile(hostDir, explicit: component.file);
    return _ComposeTarget(
      component,
      hostFile,
      p.posix.join(
        mounts[role]!,
        p.posix.joinAll(p.split(p.relative(hostFile, from: worktree))),
      ),
      worktree,
    );
  }

  List<String> _compose(String environmentId, _ComposeTarget target) => [
    'docker',
    'compose',
    '-p',
    composeProjectName(environmentId),
    '-f',
    target.guestFile,
  ];

  Future<List<EnvironmentEndpoint>> _bringUp(
    String workspaceId,
    String rigId,
    String environmentId,
    _ComposeTarget target,
    Map<String, String> environment,
  ) async {
    final component = target.component;
    final compose = _compose(environmentId, target);
    final directory = p.posix.dirname(target.guestFile);
    final limit = Duration(seconds: component.timeoutSeconds);
    final up = await _rigs.execInEnvironmentRig(
      workspaceId: workspaceId,
      rigId: rigId,
      // Not `--wait`: it exits 1 on any one-shot service. A cold boot pulls
      // every image here, so this takes more than readiness does.
      argv: [
        ...compose,
        'up',
        '-d',
        if (component.build) '--build',
        ...component.services,
      ],
      workdir: directory,
      environment: environment,
      timeout: limit + const Duration(minutes: 10),
    );
    if (up.exitCode != 0) {
      throw EnvironmentRigStackFailure(
        'docker compose up failed in the rig: ${up.stderr}',
      );
    }
    final deadline = DateTime.now().add(limit);
    while (true) {
      final ps = await _rigs.execInEnvironmentRig(
        workspaceId: workspaceId,
        rigId: rigId,
        argv: [...compose, 'ps', '-a', '--format', 'json'],
        workdir: directory,
        environment: environment,
        timeout: const Duration(seconds: 30),
      );
      final services = parseComposePs('${ps.stdout}');
      final failed = services.where((service) => service.isFailed);
      if (failed.isNotEmpty) {
        throw EnvironmentRigStackFailure(
          'In the rig, ${failed.map((s) => s.name).join(', ')} failed.',
        );
      }
      if (services.isNotEmpty && services.every((s) => s.isSettled)) {
        return _endpointsOf(workspaceId, rigId, component, services);
      }
      if (DateTime.now().isAfter(deadline)) {
        throw EnvironmentRigStackFailure(
          'Timed out after ${limit.inSeconds} s waiting for the stack in the '
          'rig.',
        );
      }
      await Future<void>.delayed(pollInterval);
    }
  }

  Future<List<EnvironmentEndpoint>> _endpointsOf(
    String workspaceId,
    String rigId,
    ComposeEnvironmentComponent component,
    List<EnvironmentRigService> services,
  ) async {
    final wanted = {
      for (final service in services)
        for (final port in service.publishedPorts) port: service.name,
    };
    final forwards = <int, int>{};
    final deadline = DateTime.now().add(forwardTimeout);
    while (forwards.length < wanted.length &&
        DateTime.now().isBefore(deadline)) {
      final snapshot = _rigs.ports.snapshotFor(workspaceId, rigId);
      for (final port in snapshot?.ports ?? const <RigPortForward>[]) {
        if (wanted.containsKey(port.guestPort)) {
          forwards[port.guestPort] = port.hostPort;
        }
      }
      if (forwards.length < wanted.length) {
        await Future<void>.delayed(pollInterval);
      }
    }
    for (final port in wanted.keys) {
      if (!forwards.containsKey(port)) {
        CcInfraLog.warning(
          'rig/$rigId: guest port $port never got a host forward',
        );
      }
    }
    return environmentRigEndpoints(services, forwards, http: component.http);
  }

  @override
  Future<void> stop({
    required String workspaceId,
    required String rigId,
  }) async {
    final rig = await _rigs.get(workspaceId, rigId);
    if (rig == null || !rig.spec.isEnvironment || rig.status.phase.isTerminal) {
      // Gone already; only a quarantine can be left of it.
      if (rig != null) {
        releaseEnvironmentRigMounts(rig);
      }
      return;
    }
    if (!rig.status.isLive) {
      // Still booting: there is no disk worth keeping yet.
      await destroy(workspaceId: workspaceId, rigId: rigId);
      return;
    }
    try {
      await _rigs.stopEnvironmentRig(workspaceId: workspaceId, rigId: rigId);
    } on NotFoundException {
      // A row from a previous server: its machine went with that process.
      await destroy(workspaceId: workspaceId, rigId: rigId);
    }
  }

  @override
  Future<void> destroy({
    required String workspaceId,
    required String rigId,
  }) async {
    final rig = await _rigs.get(workspaceId, rigId);
    await _rigs.close(workspaceId: workspaceId, rigId: rigId);
    if (rig != null) {
      releaseEnvironmentRigMounts(rig);
    }
  }

  @override
  Future<List<ComposeServiceState>> services({
    required String workspaceId,
    required String rigId,
    required String environmentId,
  }) async {
    final ps = await _rigs.execInEnvironmentRig(
      workspaceId: workspaceId,
      rigId: rigId,
      // By project name alone: compose reads no file for `ps`.
      argv: [
        'docker',
        'compose',
        '-p',
        composeProjectName(environmentId),
        'ps',
        '-a',
        '--format',
        'json',
      ],
      timeout: const Duration(seconds: 30),
    );
    if (ps.exitCode != 0) {
      throw EnvironmentRigStackFailure(
        'docker compose ps failed in the rig: ${ps.stderr}',
      );
    }
    return [
      for (final service in parseComposePs('${ps.stdout}'))
        service.toServiceState(),
    ];
  }

  /// A stopped rig still exists but does not run, so it reads as false.
  @override
  Future<bool> isRunning({
    required String workspaceId,
    required String rigId,
  }) async {
    final rig = await _rigs.get(workspaceId, rigId);
    return rig != null && rig.spec.isEnvironment && rig.status is RigReady;
  }

  @override
  Future<EnvironmentExecResult> exec({
    required String workspaceId,
    required String spaceId,
    required List<String> argv,
    String? rigId,
    String? workingDirectory,
    Map<String, String> environment = const {},
    Duration? timeout,
  }) async {
    final target = rigId ?? (await _spaceRig(workspaceId, spaceId)).id;
    final result = await _rigs.execInEnvironmentRig(
      workspaceId: workspaceId,
      rigId: target,
      argv: argv,
      workdir: workingDirectory,
      environment: environment,
      timeout: timeout ?? const Duration(minutes: 10),
    );
    return EnvironmentExecResult(
      exitCode: result.exitCode,
      stdout: '${result.stdout}',
      stderr: '${result.stderr}',
    );
  }

  /// The space's machine, booting one when there is none. It pulls nothing, so
  /// it may reach nothing.
  Future<Rig> _spaceRig(String workspaceId, String spaceId) async {
    final existing = _rigs.environmentRigIn(workspaceId, spaceId);
    if (existing != null) {
      return existing;
    }
    final worktree = await _worktreeOf?.call(workspaceId, spaceId);
    if (worktree == null) {
      throw StateError('This space has no environment rig to run in.');
    }
    await _admitMounts(workspaceId, spaceId, [worktree]);
    final Rig opened;
    try {
      opened = await _rigs.open(
        workspaceId: workspaceId,
        spec: RigSpec.environment(
          spaceId: spaceId,
          environmentId: _taskSlot,
          worktreePath: worktree,
          egressAllowlist: const [],
        ),
        openedBy: openedBy,
      );
    } on Object {
      releaseEnvironmentRigPaths('(unopened)', [worktree]);
      rethrow;
    }
    try {
      return await _awaitReady(workspaceId, opened.id);
    } on EnvironmentRigStackFailure {
      await destroy(workspaceId: workspaceId, rigId: opened.id);
      rethrow;
    }
  }

  Future<Rig> _awaitReady(String workspaceId, String rigId) async {
    final deadline = DateTime.now().add(const Duration(minutes: 10));
    while (DateTime.now().isBefore(deadline)) {
      final rig = await _rigs.get(workspaceId, rigId);
      switch (rig?.status) {
        case RigReady():
          return rig!;
        case RigFailed(:final message):
          throw EnvironmentRigStackFailure(
            'The environment rig failed to start: $message',
          );
        case RigClosed():
        case null:
          throw const EnvironmentRigStackFailure(
            'The environment rig closed while starting.',
          );
        default:
          await Future<void>.delayed(pollInterval);
      }
    }
    throw const EnvironmentRigStackFailure(
      'The environment rig did not come up in time.',
    );
  }
}
