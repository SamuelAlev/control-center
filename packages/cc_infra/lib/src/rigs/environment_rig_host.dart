import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/features/environments/domain/ports/environment_port.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_component.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_definition.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_status.dart';
import 'package:cc_domain/features/rigs/domain/entities/rig.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_image_settings.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_spec.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_status.dart';
import 'package:cc_infra/src/environments/compose_plan.dart';
import 'package:cc_infra/src/environments/environment_service_ports.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:cc_infra/src/rigs/rig_ports.dart' show RigPortForward;
import 'package:cc_infra/src/rigs/rig_service.dart';
import 'package:cc_infra/src/rigs/smolvm_enclosure_backend.dart';
import 'package:cc_natives/cc_natives.dart' show RigWorktreeGuard;
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

/// A stack's images could not be worked out, so neither could what its machine
/// may reach. Egress is fixed at boot: a guess is either a stack that cannot
/// pull or a hole in the allowlist.
class EnvironmentRigImagesUnresolved implements Exception {
  /// Creates an [EnvironmentRigImagesUnresolved].
  const EnvironmentRigImagesUnresolved(this.message);

  /// What could not be resolved.
  final String message;

  @override
  String toString() => 'EnvironmentRigImagesUnresolved: $message';
}

/// A compose stack did not come up in its rig.
class EnvironmentRigStackFailure implements Exception {
  /// Creates an [EnvironmentRigStackFailure].
  const EnvironmentRigStackFailure(this.message);

  /// What went wrong, with the guest's own words where there are some.
  final String message;

  @override
  String toString() => 'EnvironmentRigStackFailure: $message';
}

final RegExp _fromLine = RegExp(
  r'^\s*FROM\s+(?:--\S+\s+)*(\S+)(?:\s+AS\s+(\S+))?',
  caseSensitive: false,
  multiLine: true,
);

/// The base images of [dockerfile]'s text. Stage names are not images.
Set<String> dockerfileBaseImages(String dockerfile) {
  final stages = <String>{'scratch'};
  final images = <String>{};
  for (final match in _fromLine.allMatches(dockerfile)) {
    final image = match.group(1)!;
    if (!stages.contains(image.toLowerCase())) {
      if (image.contains(r'$')) {
        throw EnvironmentRigImagesUnresolved(
          'A Dockerfile names its base image through a variable ("$image"), '
          'so the images a rig must reach cannot be known before it boots.',
        );
      }
      images.add(image);
    }
    final stage = match.group(2);
    if (stage != null) {
      stages.add(stage.toLowerCase());
    }
  }
  return images;
}

/// Every image a compose [model] pulls, built services' bases included.
///
/// Only [services] count when given. A build context resolves against
/// [directory] and must stay inside [root]: the file comes from the repo, which
/// on a fork is not ours, and this read happens on the host.
Set<String> composeModelImages(
  Map<String, dynamic> model, {
  Iterable<String>? services,
  String? directory,
  String? root,
}) {
  final declared = model['services'];
  if (declared is! Map) {
    return const {};
  }
  final wanted = services == null || services.isEmpty ? null : services.toSet();
  final images = <String>{};
  for (final entry in declared.entries) {
    if ((wanted != null && !wanted.contains(entry.key)) ||
        entry.value is! Map) {
      continue;
    }
    final service = entry.value as Map;
    final build = service['build'];
    if (build == null) {
      final image = service['image'];
      // An unset `${VAR}` leaves no image at all, and skipping the service
      // would boot a machine whose allowlist cannot pull it.
      if (image is! String || image.trim().isEmpty) {
        throw EnvironmentRigImagesUnresolved(
          'Service "${entry.key}" names no image, or names it through an '
          'unset variable.',
        );
      }
      images.add(image);
      continue;
    }
    images.addAll(
      dockerfileBaseImages(_dockerfileOf(entry.key, build, directory, root)),
    );
  }
  return images;
}

String _dockerfileOf(
  Object? service,
  Object build,
  String? base,
  String? root,
) {
  final spec = build is String ? {'context': build} : build as Map;
  if (spec['dockerfile_inline'] case final String inline) {
    return inline;
  }
  final context = spec['context'] ?? '.';
  if (context is! String || context.contains('://')) {
    throw EnvironmentRigImagesUnresolved(
      'Service "$service" builds from a context outside the worktree, so its '
      'base images cannot be read.',
    );
  }
  final directory = p.normalize(p.join(base ?? '', context));
  final file = p.normalize(
    p.join(directory, spec['dockerfile'] as String? ?? 'Dockerfile'),
  );
  if (root != null && !p.isWithin(root, file)) {
    throw EnvironmentRigImagesUnresolved(
      'Service "$service" builds from outside the worktree.',
    );
  }
  try {
    return File(file).readAsStringSync();
  } on FileSystemException {
    throw EnvironmentRigImagesUnresolved(
      'Service "$service" builds from a Dockerfile that does not exist.',
    );
  }
}

final RegExp _variable = RegExp(r'\$\$|\$\{(\w+)(?::?[-?+]([^}]*))?\}|\$(\w+)');

/// [text] with compose's `$VAR`, `${VAR}` and `${VAR:-default}` filled in.
String interpolateCompose(String text, Map<String, String> variables) =>
    text.replaceAllMapped(_variable, (match) {
      if (match.group(0) == r'$$') {
        return r'$';
      }
      final name = match.group(1) ?? match.group(3)!;
      final value = variables[name];
      return value == null || value.isEmpty ? (match.group(2) ?? '') : value;
    });

/// `KEY=VALUE` lines, as compose reads a `.env`.
Map<String, String> parseDotEnv(String text) => {
  for (final line in const LineSplitter().convert(text))
    if (!line.trimLeft().startsWith('#') && line.contains('='))
      line.substring(0, line.indexOf('=')).trim(): line
          .substring(line.indexOf('=') + 1)
          .trim()
          .replaceAll(RegExp('^["\']|["\']\$'), ''),
};

/// Every image of the compose file at [file], read here on the host.
///
/// Not `docker compose config`: rig placement exists to keep a compose file
/// nobody reviewed away from the host's Docker. [variables] win over the
/// directory's `.env`. `include` and `extends` are refused rather than half
/// understood.
Set<String> composeFileImages(
  String file, {
  Map<String, String> variables = const {},
  Iterable<String>? services,
  String? root,
}) {
  final directory = p.dirname(file);
  final dotEnv = File(p.join(directory, '.env'));
  final merged = {
    if (dotEnv.existsSync()) ...parseDotEnv(dotEnv.readAsStringSync()),
    ...variables,
  };
  final Object? parsed;
  try {
    parsed = loadYaml(
      interpolateCompose(File(file).readAsStringSync(), merged),
    );
  } on YamlException catch (e) {
    throw EnvironmentRigImagesUnresolved('The compose file is not valid: $e');
  }
  if (parsed is! Map) {
    throw const EnvironmentRigImagesUnresolved(
      'The compose file holds no services.',
    );
  }
  final model = jsonDecode(jsonEncode(parsed)) as Map<String, dynamic>;
  final declared = model['services'];
  final extending =
      declared is Map &&
      declared.values.any((s) => s is Map && s['extends'] != null);
  if (model['include'] != null || extending) {
    throw const EnvironmentRigImagesUnresolved(
      'The compose file uses include or extends, which a rig cannot read '
      'ahead of booting. Inline those services.',
    );
  }
  return composeModelImages(
    model,
    services: services,
    directory: directory,
    root: root ?? directory,
  );
}

/// One service, as `docker compose ps --format json` reports it.
class EnvironmentRigService {
  /// Creates an [EnvironmentRigService].
  const EnvironmentRigService({
    required this.name,
    required this.state,
    this.health = '',
    this.exitCode = 0,
    this.publishedPorts = const [],
  });

  /// The compose service.
  final String name;

  /// The container state: `running`, `exited` and so on.
  final String state;

  /// `healthy`, `starting`, `unhealthy`, or empty with no healthcheck.
  final String health;

  /// The exit code, once exited.
  final int exitCode;

  /// The guest ports it publishes.
  final List<int> publishedPorts;

  /// Whether it has failed for good.
  bool get isFailed =>
      health == 'unhealthy' ||
      state == 'dead' ||
      (state == 'exited' && exitCode != 0);

  /// Whether nothing more needs waiting for. A one-shot that exited 0 counts,
  /// which is what `up --wait` gets wrong.
  bool get isSettled =>
      (state == 'running' && (health.isEmpty || health == 'healthy')) ||
      (state == 'exited' && exitCode == 0);
}

/// Parses `compose ps --format json`: one object per line, or an array.
List<EnvironmentRigService> parseComposePs(String output) {
  final text = output.trim();
  if (text.isEmpty) {
    return const [];
  }
  final rows = text.startsWith('[')
      ? (jsonDecode(text) as List).cast<Object?>()
      : [
          for (final line in const LineSplitter().convert(text))
            jsonDecode(line),
        ];
  return [
    for (final row in rows.whereType<Map<String, dynamic>>())
      EnvironmentRigService(
        name: row['Service'] as String? ?? '',
        state: row['State'] as String? ?? '',
        health: row['Health'] as String? ?? '',
        exitCode: (row['ExitCode'] as num?)?.toInt() ?? 0,
        publishedPorts: {
          for (final publisher in (row['Publishers'] as List?) ?? const [])
            if (publisher is Map &&
                publisher['PublishedPort'] is num &&
                publisher['PublishedPort'] != 0)
              (publisher['PublishedPort'] as num).toInt(),
        }.toList(growable: false),
      ),
  ];
}

/// The guest path of each role's worktree. The anchor role gets the workdir.
Map<String, String> environmentRigMountPoints(
  EnvironmentDefinition definition,
  Map<String, String> worktrees,
) {
  if (worktrees.isEmpty) {
    throw ArgumentError.value(worktrees, 'worktrees', 'Nothing to mount');
  }
  final anchors = definition.repos.where((role) => role.anchor);
  final anchor = anchors.isNotEmpty && worktrees.containsKey(anchors.first.key)
      ? anchors.first.key
      : worktrees.keys.first;
  return {
    anchor: kSmolvmEnvironmentWorkdir,
    for (final role in worktrees.keys)
      if (role != anchor) role: _extraMountPoint(role),
  };
}

String _extraMountPoint(String role) {
  // The key comes from a definition, which can come from the repo.
  if (!RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(role)) {
    throw ArgumentError.value(role, 'role', 'Not usable in a guest path');
  }
  return '/workspaces/$role';
}

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

  /// Refuses any [paths] that are not one of the space's worktrees, after
  /// following symlinks, and quarantines the rest before a rig sees them.
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
    final allowed = {
      for (final root in await source(workspaceId, spaceId))
        if (Directory(root).existsSync()) _real(root),
    };
    for (final path in paths) {
      if (!Directory(path).existsSync() || !allowed.contains(_real(path))) {
        throw EnvironmentRigStackFailure(
          'Refusing to mount $path: it is not one of this space\'s worktrees.',
        );
      }
      RigWorktreeGuard.quarantine(path);
    }
  }

  static String _real(String path) =>
      p.normalize(Directory(path).resolveSymbolicLinksSync());

  /// Lifts each mounted worktree's quarantine, unless its git metadata
  /// changed: that one stays guarded until a person looks.
  void _releaseMounts(Rig rig) {
    final paths = [?rig.spec.worktreePath, ...rig.spec.extraMounts.values];
    for (final path in paths) {
      if (!RigWorktreeGuard.release(path)) {
        CcInfraLog.warning(
          'rig/${rig.id}: the git metadata of $path changed while it was '
          'mounted; it stays quarantined',
        );
      }
    }
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
    final Rig rig;
    if (existing != null) {
      await _rigs.resumeEnvironmentRig(
        workspaceId: workspaceId,
        rigId: existing.id,
      );
      rig = await _awaitReady(workspaceId, existing.id);
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
      await _admitMounts(workspaceId, spaceId, [
        for (final role in mounts.keys) worktrees[role]!,
      ]);
      final opened = await _rigs.open(
        workspaceId: workspaceId,
        spec: RigSpec.environment(
          conversationId: spaceId,
          environmentId: environmentId,
          worktreePath: worktrees[primary]!,
          // Throws RigPrivateRegistryException before anything boots.
          egressAllowlist: environmentRigEgressHosts(images),
          ttlHours: definition.policy.rigTtlHours,
          extraMounts: {
            for (final mount in mounts.entries)
              if (mount.key != primary) mount.value: worktrees[mount.key]!,
          },
        ),
        openedBy: openedBy,
      );
      rig = await _awaitReady(workspaceId, opened.id);
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
  Future<void> stop({required String workspaceId, required String rigId}) =>
      _rigs.stopEnvironmentRig(workspaceId: workspaceId, rigId: rigId);

  @override
  Future<void> destroy({
    required String workspaceId,
    required String rigId,
  }) async {
    final rig = await _rigs.get(workspaceId, rigId);
    await _rigs.close(workspaceId: workspaceId, rigId: rigId);
    if (rig != null && rig.spec.isEnvironment) {
      _releaseMounts(rig);
    }
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
    final opened = await _rigs.open(
      workspaceId: workspaceId,
      spec: RigSpec.environment(
        conversationId: spaceId,
        environmentId: _taskSlot,
        worktreePath: worktree,
        egressAllowlist: const [],
      ),
      openedBy: openedBy,
    );
    return _awaitReady(workspaceId, opened.id);
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

/// One endpoint per forwarded port. [forwards] maps guest to host ports, and
/// [http] names the services that get a URL. A service's first port is its
/// role; later ones add the port, so each role stays unique.
List<EnvironmentEndpoint> environmentRigEndpoints(
  List<EnvironmentRigService> services,
  Map<int, int> forwards, {
  List<String>? http,
}) => [
  for (final service in services)
    for (final (index, port) in service.publishedPorts.indexed)
      if (forwards[port] case final hostPort?)
        EnvironmentEndpoint(
          role: index == 0 ? service.name : '${service.name}-$port',
          hostPort: hostPort,
          url: http != null && http.contains(service.name)
              ? 'http://127.0.0.1:$hostPort'
              : null,
        ),
];
