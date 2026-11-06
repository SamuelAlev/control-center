import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/features/environments/domain/entities/environment_lease.dart';
import 'package:cc_domain/features/environments/domain/entities/space_environment.dart';
import 'package:cc_domain/features/environments/domain/ports/environment_port.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_status.dart';
import 'package:cc_infra/src/environments/compose_plan.dart';
import 'package:cc_infra/src/environments/environment_command_runner.dart';
import 'package:cc_infra/src/environments/environment_lease_allocator.dart';
import 'package:cc_infra/src/environments/environment_probes.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:cc_infra/src/util/file_protection.dart';
import 'package:path/path.dart' as p;

/// Where one service stands.
class ComposeServiceState {
  /// Creates a [ComposeServiceState].
  const ComposeServiceState({
    required this.service,
    required this.state,
    this.containerState,
    this.health,
    this.exitCode,
    this.logTail,
  });

  /// The service.
  final String service;

  /// `ready`, `completed`, `waiting` or `failed`.
  final String state;

  /// Docker's state: `running`, `exited`, …
  final String? containerState;

  /// Docker's health, empty or null when it has no healthcheck.
  final String? health;

  /// The exit code of a stopped container.
  final int? exitCode;

  /// Its last log lines, when it failed.
  final String? logTail;

  /// Whether it needs no more waiting.
  bool get isSettled => state == 'ready' || state == 'completed';

  /// The shape [EnvironmentComponentState.services] holds.
  Map<String, dynamic> toJson({List<int> ports = const []}) => {
    'name': service,
    'state': state,
    if (health != null && health!.isNotEmpty) 'health': health,
    if (ports.isNotEmpty) 'ports': ports,
  };
}

/// A container carrying CC's labels.
class ComposeOwnedContainer {
  /// Creates a [ComposeOwnedContainer].
  const ComposeOwnedContainer({
    required this.id,
    required this.name,
    required this.state,
    required this.environmentId,
    this.workspaceId,
    this.spaceId,
    this.project,
  });

  /// Container id.
  final String id;

  /// Container name.
  final String name;

  /// Docker's state.
  final String state;

  /// The `cc.env` label.
  final String environmentId;

  /// The `cc.workspace` label.
  final String? workspaceId;

  /// The `cc.space` label.
  final String? spaceId;

  /// Its compose project.
  final String? project;
}

/// What [ComposeDriver.refresh] did.
class ComposeRefreshResult {
  /// Creates a [ComposeRefreshResult].
  const ComposeRefreshResult({required this.plan, required this.changed});

  /// The new plan.
  final ComposePlan plan;

  /// Whether the resolved config had changed, and so `up` ran.
  final bool changed;
}

/// Drives one compose stack through the `docker` CLI.
///
/// Readiness is CC's own: `up --wait` exits 1 on any one-shot service, so it is
/// never used. Every operation that starts anything passes the preflight first,
/// because a plan can be older than the file it came from.
///
/// The worktree's compose file is read only by [plan]. A running container can
/// write to the worktree, so `up` starts the model preflight checked, from the
/// state directory, and everything else finds the stack by project name.
class ComposeDriver {
  /// Creates a [ComposeDriver].
  ComposeDriver({
    EnvironmentCommandRunner? runner,
    this._httpProbe = probeHttpStatus,
    this.pollInterval = const Duration(seconds: 2),
    this.upTimeout = const Duration(minutes: 30),
    this.commandTimeout = const Duration(minutes: 2),
    this.failureLogLines = 20,
  }) : _runner = runner ?? EnvironmentCommandRunner();

  /// The oldest Compose with `!reset` and `!override`.
  static const List<int> minimumVersion = [2, 24, 4];

  /// The file holding the hash of what `up` last applied.
  static const String appliedHashFile = 'compose.config.sha256';

  final EnvironmentCommandRunner _runner;
  final EnvironmentHttpProbe _httpProbe;

  /// The fallback between `ps` reads when no event arrives.
  final Duration pollInterval;

  /// The ceiling on `up`, which pulls and builds. The component's own timeout
  /// is for readiness, which only starts afterwards.
  final Duration upTimeout;

  /// The ceiling on every other call.
  final Duration commandTimeout;

  /// Log lines attached to a failed service.
  final int failureLogLines;

  final Map<String, StreamController<String>> _followers = {};

  /// Resolves the stack, refusing remote resources before anything fetches
  /// them, and gives every published port an index in [lease].
  ///
  /// [existingPorts] are the environment's assignments so far. They never move.
  Future<ComposePlan> plan(
    ComposeContext context, {
    required EnvironmentLease lease,
    Map<String, int> existingPorts = const {},
  }) async {
    final component = context.component;
    final file = discoverComposeFile(
      context.workingDirectory,
      explicit: component.file,
    );
    assertNoRemoteComposeResources(file);

    final envFiles = context.untrusted
        ? await _envFiles(context, file)
        : const <String, List<String>>{};
    final model = await _config(context, file);
    final services = model['services'] is Map
        ? Map<String, dynamic>.from(model['services'] as Map)
        : <String, dynamic>{};

    final selected = composeServiceClosure(services, component.services);
    _refuseReplicatedPorts(services, selected);
    final targets = composePublishedTargets(services, selected);
    final ports = assignEnvironmentPorts(
      lease: lease,
      keys: targets.map((port) => composePortKey(port.service, port.target)),
      existing: existingPorts,
    );
    final published = [
      for (final port in targets)
        ComposePublishedPort(
          service: port.service,
          target: port.target,
          protocol: port.protocol,
          hostPort: ports[composePortKey(port.service, port.target)]!,
        ),
    ];
    final overrideYaml = renderComposeOverride(
      context: context,
      services: selected,
      published: published,
    );
    return ComposePlan(
      context: context,
      file: file,
      model: model,
      services: selected,
      published: published,
      ports: ports,
      overrideYaml: overrideYaml,
      configHash: composeConfigHash(model, overrideYaml),
      envFiles: envFiles,
      warnings: [
        for (final service in component.healthchecks.keys)
          if (!selected.contains(service))
            'Healthcheck for $service ignored: it is not a selected service',
      ],
    );
  }

  /// `docker compose config`'s model of [file].
  Future<Map<String, dynamic>> _config(
    ComposeContext context,
    String file, {
    List<String> flags = const [],
  }) async {
    final result = await _runner.runArgv(
      [
        'docker',
        'compose',
        '-p',
        context.projectName,
        '-f',
        file,
        'config',
        ...flags,
        '--format',
        'json',
      ],
      workingDirectory: context.workingDirectory,
      environment: _variables(context),
      timeout: commandTimeout,
    );
    if (!result.succeeded) {
      throw _commandFailure('compose-config-failed', result);
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(result.rawStdout);
    } on FormatException catch (e) {
      throw _failure(
        'compose-config-failed',
        'docker compose config printed something unreadable: ${e.message}',
      );
    }
    if (decoded is! Map) {
      throw _failure(
        'compose-config-failed',
        'docker compose config did not print a model',
      );
    }
    return Map<String, dynamic>.from(decoded);
  }

  /// What each service of an untrusted stack names in `env_file`.
  ///
  /// `config` folds those files into `environment` and drops the key, so a file
  /// from anywhere on the host looks like any other variable in the model. A
  /// Compose too old for this flag fails here, and the stack doesn't start.
  Future<Map<String, List<String>>> _envFiles(
    ComposeContext context,
    String file,
  ) async {
    final model = await _config(
      context,
      file,
      flags: const ['--no-env-resolution'],
    );
    final services = model['services'];
    return {
      if (services is Map)
        for (final entry in services.entries)
          if (entry.value is Map && (entry.value as Map)['env_file'] != null)
            '${entry.key}': composeEnvFilePaths(
              (entry.value as Map)['env_file'],
            ),
    };
  }

  /// Checks what [plan] would do before it does it.
  Future<ComposePreflightResult> preflight(ComposePlan plan) async {
    final context = plan.context;
    final services = plan.model['services'] is Map
        ? Map<String, dynamic>.from(plan.model['services'] as Map)
        : <String, dynamic>{};
    final missing = <ComposeMissingBind>[];
    for (final bind in composeBindSources(services, plan.services)) {
      if (FileSystemEntity.typeSync(bind.source) ==
          FileSystemEntityType.notFound) {
        missing.add(
          ComposeMissingBind(
            service: bind.service,
            source: bind.source,
            relativePath: p.isWithin(context.workingDirectory, bind.source)
                ? p.relative(bind.source, from: context.workingDirectory)
                : bind.source,
            gitignored: await _isGitignored(context, bind.source),
          ),
        );
      }
    }
    final findings = composePolicyFindings(
      model: plan.model,
      names: plan.services,
      allowedRoots: context.allowedRoots,
      untrusted: context.untrusted,
      envFiles: plan.envFiles,
    );
    return ComposePreflightResult(
      missingBinds: missing,
      warnings: context.untrusted ? const [] : findings,
      refusals: context.untrusted ? findings : const [],
    );
  }

  /// Writes the resolved stack and the override, then runs `up -d` on the
  /// planned services from those two files alone.
  ///
  /// The project directory becomes the state directory, which is what keeps the
  /// worktree's `.env` out of it. Nothing is lost: [ComposePlan.model] has every
  /// path absolute and every variable filled in.
  ///
  /// [build] defaults to the component's setting. Returns preflight warnings.
  /// Throws [EnvironmentDriverException] on anything preflight blocks or `up`
  /// fails on.
  Future<List<String>> up(
    ComposePlan plan, {
    bool? build,
    void Function(EnvironmentCommandEvent event)? onEvent,
  }) async {
    final preflight = await this.preflight(plan);
    preflight.throwIfBlocked();
    await writeOverride(plan);
    await _writeResolved(plan);
    final result = await _compose(
      plan,
      [
        '-f',
        plan.context.resolvedPath,
        '-f',
        plan.context.overridePath,
        'up',
        '-d',
        if (build ?? plan.context.component.build) '--build',
        ...plan.services,
      ],
      timeout: upTimeout,
      onEvent: onEvent,
    );
    if (!result.succeeded) {
      throw _commandFailure('compose-up-failed', result);
    }
    await _appliedHash(plan.context).writeAsString(plan.configHash);
    return [
      ...plan.warnings,
      for (final finding in preflight.warnings) finding.message,
    ];
  }

  /// Writes [plan]'s override, so terminals see the final `COMPOSE_FILE`.
  Future<void> writeOverride(ComposePlan plan) async {
    final file = File(plan.context.overridePath);
    await file.parent.create(recursive: true);
    await file.writeAsString(plan.overrideYaml);
  }

  /// Interpolated variables and folded `env_file`s can be secrets, so the file
  /// is its owner's before it holds any of them.
  Future<void> _writeResolved(ComposePlan plan) async {
    final file = File(plan.context.resolvedPath);
    await file.parent.create(recursive: true);
    final staged = File('${file.path}.tmp');
    await staged.writeAsString('');
    await restrictToOwner(staged.path, directory: false);
    await staged.writeAsString(composeResolvedFile(plan.model));
    await staged.rename(file.path);
  }

  /// Reads where every planned service stands.
  Future<List<ComposeServiceState>> status(ComposePlan plan) async {
    final result = await _compose(plan, const [
      'ps',
      '--all',
      '--format',
      'json',
    ]);
    if (!result.succeeded) {
      throw _commandFailure('compose-ps-failed', result);
    }
    final containers = _parseJsonLines(result.rawStdout);
    return [
      for (final service in plan.services)
        _serviceState(
          service,
          containers.where((row) => row['Service'] == service),
        ),
    ];
  }

  /// Waits until every service has settled.
  ///
  /// `docker events` says when to look and `ps` says what is true, so a missed
  /// event costs a [pollInterval] rather than a wrong answer.
  ///
  /// Throws [EnvironmentDriverException] when a service fails, with its last
  /// log lines, or at the timeout, naming what is still waiting.
  Future<List<ComposeServiceState>> waitReady(
    ComposePlan plan, {
    Duration? timeout,
  }) async {
    final limit =
        timeout ?? Duration(seconds: plan.context.component.timeoutSeconds);
    final deadline = DateTime.now().add(limit);
    final wake = StreamController<void>.broadcast();
    final events = _runner.startArgv(
      [
        'docker',
        'events',
        '--filter',
        'label=com.docker.compose.project=${plan.context.projectName}',
        '--format',
        '{{json .}}',
      ],
      workingDirectory: plan.context.workingDirectory,
      environment: _variables(plan.context),
    );
    final subscription = events.events.listen((_) => wake.add(null));
    try {
      while (true) {
        final states = await status(plan);
        final failed = states.where((state) => state.state == 'failed');
        if (failed.isNotEmpty) {
          throw await _serviceFailure(plan, failed.toList(growable: false));
        }
        if (states.every((state) => state.isSettled)) {
          return states;
        }
        final remaining = deadline.difference(DateTime.now());
        if (remaining <= Duration.zero) {
          final waiting = states.where((state) => !state.isSettled);
          throw _failure(
            'compose-timeout',
            'Timed out after ${limit.inSeconds} s waiting for '
                '${waiting.map(_describeWaiting).join(', ')}',
          );
        }
        await wake.stream.first
            .timeout(remaining < pollInterval ? remaining : pollInterval)
            .catchError((Object _) {});
      }
    } finally {
      await subscription.cancel();
      events.cancel();
      await wake.close();
    }
  }

  /// One loopback request per running published port.
  ///
  /// Those that answer HTTP become URL endpoints and the rest `host:port` rows.
  /// A component's `http` list replaces the guess.
  Future<List<EnvironmentEndpoint>> detectEndpoints(
    ComposePlan plan,
    List<ComposeServiceState> states,
  ) async {
    final running = {
      for (final state in states)
        if (state.state == 'ready') state.service,
    };
    final http = plan.context.component.http;
    final seen = <String>{};
    final ports = [
      for (final port in plan.published)
        if (running.contains(port.service) && seen.add(port.key)) port,
    ];
    final endpoints = <EnvironmentEndpoint>[];
    for (final port in ports) {
      final siblings = ports.where((other) => other.service == port.service);
      final role = siblings.length == 1
          ? port.service
          : '${port.service}-${port.target}';
      final url = 'http://127.0.0.1:${port.hostPort}';
      final isHttp = http != null
          ? http.contains(port.service)
          : port.protocol == 'tcp' &&
                await _httpProbe(Uri.parse('$url/')) != null;
      endpoints.add(
        EnvironmentEndpoint(
          role: role,
          url: isHttp ? url : null,
          hostPort: port.hostPort,
        ),
      );
    }
    return endpoints;
  }

  /// The last [tail] lines of [service].
  Future<String> logs(
    ComposePlan plan,
    String? service, {
    int tail = 200,
  }) async {
    final result = await _compose(plan, [
      'logs',
      '--no-color',
      '--tail',
      '$tail',
      ?service,
    ]);
    return result.stdout;
  }

  /// Streams [service]. Every follower of a service shares one `docker compose
  /// logs`, which runs from the first listener to the last, and those who join
  /// later see only what comes after.
  Stream<String> followLogs(
    ComposePlan plan,
    String? service, {
    int tail = 200,
  }) {
    final key = '${plan.context.projectName}/${service ?? '*'}';
    final existing = _followers[key]?.stream;
    if (existing != null) {
      return existing;
    }
    EnvironmentCommandHandle? handle;
    // Closed by its own onCancel, when the last follower leaves.
    // ignore: close_sinks
    late final StreamController<String> controller;
    controller = StreamController<String>.broadcast(
      onListen: () {
        final started = _runner.startArgv(
          _argv(plan, [
            'logs',
            '--no-color',
            '--tail',
            '$tail',
            '--follow',
            ?service,
          ]),
          workingDirectory: plan.context.workingDirectory,
          environment: _variables(plan.context),
        );
        handle = started;
        started.events.listen((event) {
          if (event is EnvironmentCommandOutput && !event.isStderr) {
            controller.add(event.line);
          }
        });
        // `logs --follow` ends when its containers go. Followers hear that as
        // the end of the stream, and the next one starts a fresh process.
        unawaited(
          started.result.then((_) {
            if (identical(_followers[key], controller)) {
              _followers.remove(key);
            }
            if (!controller.isClosed) {
              unawaited(controller.close());
            }
          }),
        );
      },
      onCancel: () {
        handle?.cancel();
        _followers.remove(key);
        unawaited(controller.close());
      },
    );
    _followers[key] = controller;
    return controller.stream;
  }

  /// `exec -T <service> <argv>`.
  Future<EnvironmentExecResult> exec(
    ComposePlan plan,
    String service,
    List<String> command, {
    Duration? timeout,
  }) async {
    final result = await _compose(plan, [
      'exec',
      '-T',
      service,
      ...command,
    ], timeout: timeout ?? commandTimeout);
    return EnvironmentExecResult(
      exitCode: result.exitCode,
      stdout: result.stdout,
      stderr: result.stderr,
    );
  }

  /// `restart <service>`.
  /// `restart <service>`, or every service.
  Future<void> restart(ComposePlan plan, String? service) =>
      _mustRun(plan, ['restart', ?service], 'compose-restart-failed');

  /// `stop` by project name alone, for when the file is gone or unreadable.
  Future<void> stopProject(String environmentId) async {
    final result = await _runner.runArgv(
      ['docker', 'compose', '-p', composeProjectName(environmentId), 'stop'],
      environment: const {'DOCKER_CLI_HINTS': 'false'},
      timeout: upTimeout,
    );
    if (!result.succeeded) {
      throw _commandFailure('compose-stop-failed', result);
    }
  }

  /// A published port is one fixed host port, and one host port can't front
  /// several containers: compose would fail on the second with a bind error.
  void _refuseReplicatedPorts(
    Map<String, dynamic> services,
    List<String> selected,
  ) {
    for (final name in selected) {
      final service = services[name];
      if (service is! Map) {
        continue;
      }
      final deploy = service['deploy'];
      final replicas =
          (deploy is Map ? deploy['replicas'] as num? : null) ??
          service['scale'] as num?;
      final ports = service['ports'];
      if (replicas != null &&
          replicas > 1 &&
          ports is List &&
          ports.isNotEmpty) {
        throw _failure(
          'compose-replicas-ports',
          'Service $name runs ${replicas.toInt()} replicas and publishes '
              'ports. Each published port gets one fixed host port, which only '
              'one container can hold. Set replicas to 1, or stop publishing its '
              'ports',
        );
      }
    }
  }

  /// `stop`, keeping containers and data.
  Future<void> stop(ComposePlan plan) =>
      _mustRun(plan, const ['stop'], 'compose-stop-failed');

  /// `up -d` after a stop.
  Future<List<String>> start(ComposePlan plan) => up(plan, build: false);

  /// `down -v`, then `up`. Running `create` tasks again is the caller's part.
  Future<List<String>> reset(ComposePlan plan) async {
    await _mustRun(plan, const ['down', '-v'], 'compose-reset-failed');
    return up(plan);
  }

  /// `down -v --remove-orphans --rmi local`.
  Future<void> destroy(ComposePlan plan) => _mustRun(plan, const [
    'down',
    '-v',
    '--remove-orphans',
    '--rmi',
    'local',
  ], 'compose-destroy-failed');

  /// Destroys a project whose compose file is gone, by name alone.
  Future<void> destroyProject(String environmentId) async {
    final project = composeProjectName(environmentId);
    final result = await _runner.runArgv(
      ['docker', 'compose', '-p', project, 'down', '-v', '--remove-orphans'],
      environment: const {'DOCKER_CLI_HINTS': 'false'},
      timeout: upTimeout,
    );
    if (!result.succeeded) {
      throw _commandFailure('compose-destroy-failed', result);
    }
  }

  /// Plans again, keeping every port, and applies the result if it changed.
  ///
  /// Compose leaves containers with an unchanged config hash running.
  Future<ComposeRefreshResult> refresh(
    ComposeContext context, {
    required EnvironmentLease lease,
    required Map<String, int> existingPorts,
  }) async {
    final next = await plan(
      context,
      lease: lease,
      existingPorts: existingPorts,
    );
    final file = _appliedHash(context);
    final applied = file.existsSync() ? await file.readAsString() : null;
    if (applied == next.configHash) {
      return ComposeRefreshResult(plan: next, changed: false);
    }
    await up(next, build: true);
    return ComposeRefreshResult(plan: next, changed: true);
  }

  /// Every container carrying `cc.env`, across all workspaces. For boot
  /// reconciliation only.
  Future<List<ComposeOwnedContainer>> ownedContainers() async {
    final result = await _runner.runArgv(const [
      'docker',
      'ps',
      '-a',
      '--filter',
      'label=cc.env',
      '--format',
      '{{json .}}',
    ], timeout: commandTimeout);
    if (!result.succeeded) {
      throw _commandFailure('compose-ps-failed', result);
    }
    return [
      for (final row in _parseJsonLines(result.rawStdout))
        ?_ownedContainer(row),
    ];
  }

  /// Owned containers whose environment isn't in [known].
  Future<List<ComposeOwnedContainer>> orphans(Set<String> known) async => [
    for (final container in await ownedContainers())
      if (!known.contains(container.environmentId)) container,
  ];

  /// The host's Compose against [minimumVersion].
  Future<EnvironmentCheckResult> versionCheck() async {
    const id = 'compose-version';
    final result = await _runner.runArgv(const [
      'docker',
      'compose',
      'version',
      '--short',
    ], timeout: commandTimeout);
    final version = result.rawStdout.trim();
    final parts = [
      for (final part in RegExp(
        r'\d+',
      ).allMatches(version).map((m) => m.group(0)!))
        int.parse(part),
    ];
    var recent = false;
    for (final (index, minimum) in minimumVersion.indexed) {
      final part = index < parts.length ? parts[index] : 0;
      if (part != minimum) {
        recent = part > minimum;
        break;
      }
      recent = true;
    }
    final ok = result.succeeded && recent;
    return EnvironmentCheckResult(
      id: id,
      label: result.succeeded
          ? 'Docker Compose $version'
          : 'Docker Compose not found',
      ok: ok,
      hint: ok
          ? null
          : 'Compose ${minimumVersion.join('.')} or later is needed',
    );
  }

  Future<bool?> _isGitignored(ComposeContext context, String path) async {
    final result = await _runner.runArgv(
      ['git', 'check-ignore', '-q', '--', path],
      workingDirectory: context.workingDirectory,
      timeout: const Duration(seconds: 10),
    );
    return switch (result.exitCode) {
      0 => true,
      1 => false,
      _ => null,
    };
  }

  ComposeServiceState _serviceState(
    String service,
    Iterable<Map<String, dynamic>> containers,
  ) {
    if (containers.isEmpty) {
      return ComposeServiceState(service: service, state: 'waiting');
    }
    // With replicas the service is as far along as its worst container.
    const rank = {'failed': 0, 'waiting': 1, 'ready': 2, 'completed': 3};
    final states = containers.map((row) => _containerState(service, row));
    return states.reduce(
      (worst, next) => rank[next.state]! < rank[worst.state]! ? next : worst,
    );
  }

  ComposeServiceState _containerState(
    String service,
    Map<String, dynamic> row,
  ) {
    final docker = row['State'] as String?;
    final health = row['Health'] as String? ?? '';
    final exit = (row['ExitCode'] as num?)?.toInt();
    final state = switch (docker) {
      'running' when health.isEmpty || health == 'healthy' => 'ready',
      'exited' when exit == 0 => 'completed',
      'exited' || 'dead' => 'failed',
      _ => 'waiting',
    };
    return ComposeServiceState(
      service: service,
      state: state,
      containerState: docker,
      health: health,
      exitCode: exit,
    );
  }

  String _describeWaiting(ComposeServiceState state) {
    final detail = [
      ?state.containerState,
      if (state.health?.isNotEmpty ?? false) state.health!,
    ].join(', ');
    return detail.isEmpty ? state.service : '${state.service} ($detail)';
  }

  Future<EnvironmentDriverException> _serviceFailure(
    ComposePlan plan,
    List<ComposeServiceState> failed,
  ) async {
    final sections = <String>[];
    for (final state in failed) {
      String log;
      try {
        log = await logs(plan, state.service, tail: failureLogLines);
      } on Object catch (e) {
        CcInfraLog.warning('could not read ${state.service} logs: $e');
        log = '';
      }
      sections.add(
        'Service ${state.service} exited with code ${state.exitCode ?? '?'}'
        '${log.trim().isEmpty ? '' : ':\n${log.trimRight()}'}',
      );
    }
    return _failure('compose-service-failed', sections.join('\n'));
  }

  ComposeOwnedContainer? _ownedContainer(Map<String, dynamic> row) {
    final labels = (row['Labels'] as String?) ?? '';
    String? label(String key) {
      final match = RegExp(
        '(?:^|,)${RegExp.escape(key)}=([^,]*)',
      ).firstMatch(labels);
      return match?.group(1);
    }

    final environmentId = label('cc.env');
    if (environmentId == null || environmentId.isEmpty) {
      return null;
    }
    return ComposeOwnedContainer(
      id: (row['ID'] as String?) ?? '',
      name: (row['Names'] as String?) ?? '',
      state: (row['State'] as String?) ?? '',
      environmentId: environmentId,
      workspaceId: label('cc.workspace'),
      spaceId: label('cc.space'),
      project: label('com.docker.compose.project'),
    );
  }

  /// Compose prints one object per line now and a single array before 2.21.
  List<Map<String, dynamic>> _parseJsonLines(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return const [];
    }
    final rows = <Map<String, dynamic>>[];
    void add(Object? value) {
      if (value is Map) {
        rows.add(Map<String, dynamic>.from(value));
      }
    }

    if (trimmed.startsWith('[')) {
      (jsonDecode(trimmed) as List).forEach(add);
      return rows;
    }
    for (final line in const LineSplitter().convert(trimmed)) {
      if (line.trim().isNotEmpty) {
        add(jsonDecode(line));
      }
    }
    return rows;
  }

  File _appliedHash(ComposeContext context) =>
      File(p.join(context.stateDir, appliedHashFile));

  Future<void> _mustRun(
    ComposePlan plan,
    List<String> arguments,
    String code,
  ) async {
    final result = await _compose(plan, arguments, timeout: upTimeout);
    if (!result.succeeded) {
      throw _commandFailure(code, result);
    }
  }

  Future<EnvironmentCommandResult> _compose(
    ComposePlan plan,
    List<String> arguments, {
    Duration? timeout,
    void Function(EnvironmentCommandEvent event)? onEvent,
  }) => _runner.runArgv(
    _argv(plan, arguments),
    workingDirectory: plan.context.workingDirectory,
    environment: _variables(plan.context),
    timeout: timeout ?? commandTimeout,
    onEvent: onEvent,
  );

  /// By project name, so Compose reads no file: containers carry their own
  /// config, and `-p` with no `-f` leaves the worktree's compose file alone.
  List<String> _argv(ComposePlan plan, List<String> arguments) => [
    'docker',
    'compose',
    '-p',
    plan.context.projectName,
    ...arguments,
  ];

  /// Remote resources are off for every call, not only refused by the scan:
  /// a reference built from `${VAR}` can't be seen until compose expands it.
  ///
  /// `COMPOSE_FILE` is for terminals and tasks. The driver names its files.
  Map<String, String> _variables(ComposeContext context) => {
    ...context.environment,
    'COMPOSE_PROJECT_NAME': context.projectName,
    'COMPOSE_EXPERIMENTAL_OCI_REMOTE': '0',
    'COMPOSE_EXPERIMENTAL_GIT_REMOTE': '0',
    'COMPOSE_ANSI': 'never',
    'DOCKER_CLI_HINTS': 'false',
  }..remove('COMPOSE_FILE');

  EnvironmentDriverException _commandFailure(
    String code,
    EnvironmentCommandResult result,
  ) => _failure(
    result.timedOut ? 'compose-timeout' : code,
    result.error?.message ?? 'docker compose exited ${result.exitCode}',
  );

  EnvironmentDriverException _failure(String code, String message) =>
      EnvironmentDriverException(
        EnvironmentError(code: code, message: message),
      );
}
