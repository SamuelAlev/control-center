import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/features/environments/domain/entities/space_environment.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_command.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_component.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_status.dart';
import 'package:cc_domain/features/sandboxing/domain/terminal_session_port.dart';
import 'package:cc_infra/src/environments/environment_command_runner.dart';
import 'package:cc_infra/src/environments/environment_contract.dart';
import 'package:cc_infra/src/environments/environment_log_ring.dart';
import 'package:cc_infra/src/environments/environment_probes.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:cc_infra/src/process/binary_resolver.dart';
import 'package:path/path.dart' as p;

/// Which rules a supervised command follows.
enum EnvironmentSupervisedKind {
  /// A server: starts with the environment, gates `ready`, restarts.
  process,

  /// A desktop window: exits are normal, and nothing relaunches it.
  app,
}

/// One command to supervise, with its placeholders already expanded.
class EnvironmentProcessSpec {
  /// Creates an [EnvironmentProcessSpec].
  const EnvironmentProcessSpec({
    required this.workspaceId,
    required this.spaceId,
    required this.environmentId,
    required this.componentId,
    required this.kind,
    required this.argv,
    required this.workingDirectory,
    required this.stateDir,
    this.environment = const {},
    this.label,
    this.ready,
    this.restart = EnvironmentRestartPolicy.onFailure,
    this.isolateHome = false,
  });

  /// The spec of a `process` component.
  factory EnvironmentProcessSpec.forProcess({
    required ProcessEnvironmentComponent component,
    required EnvironmentContract contract,
    required String workspaceId,
  }) {
    final values = contract.values;
    final ready = component.ready;
    return EnvironmentProcessSpec(
      workspaceId: workspaceId,
      spaceId: contract.input.spaceId,
      environmentId: contract.input.id,
      componentId: component.id,
      kind: EnvironmentSupervisedKind.process,
      argv: _argv(component.command, contract),
      workingDirectory: contract.workingDirectory(component.cwd),
      stateDir: contract.input.stateDir,
      environment: contract.forComponent(component),
      label: component.displayName,
      ready: ready == null
          ? null
          : EnvironmentReadyProbe(
              http: ready.http == null ? null : values.expand(ready.http!),
              tcp: ready.tcp == null ? null : values.expand(ready.tcp!),
              logMatch: ready.logMatch,
              expectBelow: ready.expectBelow,
              timeoutSeconds: ready.timeoutSeconds,
            ),
      restart: component.restart,
    );
  }

  /// The spec of an `app` component.
  factory EnvironmentProcessSpec.forApp({
    required AppEnvironmentComponent component,
    required EnvironmentContract contract,
    required String workspaceId,
  }) => EnvironmentProcessSpec(
    workspaceId: workspaceId,
    spaceId: contract.input.spaceId,
    environmentId: contract.input.id,
    componentId: component.id,
    kind: EnvironmentSupervisedKind.app,
    argv: _argv(component.command, contract),
    workingDirectory: contract.workingDirectory(component.cwd),
    stateDir: contract.input.stateDir,
    environment: contract.forComponent(component),
    label: component.displayName,
    restart: EnvironmentRestartPolicy.never,
    isolateHome: component.isolateHome,
  );

  static List<String> _argv(
    EnvironmentCommand command,
    EnvironmentContract contract,
  ) => EnvironmentCommandRunner.argvFor(command, contract.values);

  /// Owning workspace.
  final String workspaceId;

  /// Owning space.
  final String spaceId;

  /// The environment.
  final String environmentId;

  /// The component.
  final String componentId;

  /// Which rules apply.
  final EnvironmentSupervisedKind kind;

  /// What to run.
  final List<String> argv;

  /// Where.
  final String workingDirectory;

  /// The environment's state directory.
  final String stateDir;

  /// Its variables.
  final Map<String, String> environment;

  /// What to show.
  final String? label;

  /// How to tell it is up.
  final EnvironmentReadyProbe? ready;

  /// What to do when it exits.
  final EnvironmentRestartPolicy restart;

  /// Give this process alone a private home.
  final bool isolateHome;

  /// The terminal owner tag.
  String get owner => 'environment:$environmentId/$componentId';

  /// `<stateDir>/home`.
  String get homeDir => p.join(stateDir, 'home');

  /// The private-home variables.
  Map<String, String> get homeVariables => {
    'HOME': homeDir,
    'CFFIXED_USER_HOME': homeDir,
    'XDG_CONFIG_HOME': p.join(homeDir, '.config'),
    'XDG_DATA_HOME': p.join(homeDir, '.local', 'share'),
    'XDG_STATE_HOME': p.join(homeDir, '.local', 'state'),
    'XDG_CACHE_HOME': p.join(homeDir, '.cache'),
    'XDG_RUNTIME_DIR': p.join(homeDir, '.run'),
  };
}

/// Why a supervised command went away.
class EnvironmentProcessExit {
  /// Creates an [EnvironmentProcessExit].
  const EnvironmentProcessExit({
    required this.workspaceId,
    required this.spaceId,
    required this.environmentId,
    required this.componentId,
    required this.exitCode,
    required this.state,
  });

  /// Owning workspace.
  final String workspaceId;

  /// Owning space.
  final String spaceId;

  /// The environment.
  final String environmentId;

  /// The component.
  final String componentId;

  /// The exit code, `-signal` if killed.
  final int exitCode;

  /// The component state it left: `starting` when a restart is scheduled.
  final String state;
}

/// A component's state changed.
class EnvironmentProcessStateChange {
  /// Creates an [EnvironmentProcessStateChange].
  const EnvironmentProcessStateChange({
    required this.workspaceId,
    required this.spaceId,
    required this.environmentId,
    required this.state,
  });

  /// Owning workspace.
  final String workspaceId;

  /// Owning space.
  final String spaceId;

  /// The environment. Component ids only mean something inside one.
  final String environmentId;

  /// Where the component stands now.
  final EnvironmentComponentState state;
}

/// The OS identity of a running component.
class EnvironmentProcessIds {
  /// Creates an [EnvironmentProcessIds].
  const EnvironmentProcessIds({required this.pid, required this.processGroup});

  /// The command's pid.
  final int pid;

  /// Its process group. A PTY child leads its own, so this equals [pid] on
  /// every POSIX host.
  final int processGroup;
}

/// OS process-group operations. A seam for tests.
abstract interface class EnvironmentProcessGroups {
  /// Signals every process in [group]. False when none is left.
  bool signal(int group, ProcessSignal signal);

  /// The live members of [group], leader first when it is alive.
  Future<List<int>> members(int group);

  /// A stable start stamp for [pid], or null when it isn't running.
  Future<String?> startTime(int pid);
}

/// [EnvironmentProcessGroups] on this host, through `kill(2)` and `ps`.
class HostProcessGroups implements EnvironmentProcessGroups {
  /// Creates a [HostProcessGroups].
  const HostProcessGroups();

  @override
  bool signal(int group, ProcessSignal signal) {
    try {
      // A negative pid addresses the group. Windows has neither.
      return Process.killPid(Platform.isWindows ? group : -group, signal);
    } on Object {
      return false;
    }
  }

  @override
  Future<List<int>> members(int group) async {
    if (Platform.isWindows) {
      return await startTime(group) == null ? const [] : [group];
    }
    final result = await Process.run('ps', ['-A', '-o', 'pid=,pgid=,stat=']);
    if (result.exitCode != 0) {
      return const [];
    }
    final members = <int>[];
    for (final line in const LineSplitter().convert('${result.stdout}')) {
      final parts = line.trim().split(RegExp(r'\s+'));
      if (parts.length < 2 || int.tryParse(parts[1]) != group) {
        continue;
      }
      // A zombie has already exited. `stat` is advisory: restricted `ps`
      // builds print it empty.
      if (parts.length > 2 && parts[2].startsWith('Z')) {
        continue;
      }
      final pid = int.tryParse(parts[0]);
      if (pid != null) {
        members.add(pid);
      }
    }
    members.sort((a, b) => a == group ? -1 : (b == group ? 1 : a - b));
    return members;
  }

  @override
  Future<String?> startTime(int pid) async {
    if (Platform.isWindows) {
      return null;
    }
    final result = await Process.run('ps', ['-o', 'lstart=', '-p', '$pid']);
    final text = '${result.stdout}'.trim();
    return result.exitCode == 0 && text.isNotEmpty ? text : null;
  }
}

class _Supervised {
  _Supervised(this.spec, this.ring);

  EnvironmentProcessSpec spec;
  final EnvironmentLogRing ring;

  String state = 'pending';
  String? detail;
  int restarts = 0;
  int? lastExitCode;

  OwnedTerminalSession? session;
  bool exited = true;
  bool stopping = false;
  int generation = 0;
  DateTime? startedAt;
  bool logMatched = false;

  final List<DateTime> failures = [];
  int consecutiveFailures = 0;
  Timer? backoff;

  /// This component's own states, for whoever is waiting on it. The supervisor
  /// closes it with the entry.
  // ignore: close_sinks
  final StreamController<String> changes = StreamController.broadcast();
}

/// Runs an environment's long-lived commands, each in a PTY it owns.
///
/// Sessions come from [OwnedTerminalSessionPort], so a tab can open and type
/// into one, closing that tab leaves it running, and port detection sees it.
/// Everything else lives here: readiness, restart, logs, and surviving a
/// server restart through pid files.
class EnvironmentProcessSupervisor {
  /// Creates an [EnvironmentProcessSupervisor].
  EnvironmentProcessSupervisor({
    required this._terminals,
    this._groups = const HostProcessGroups(),
    this._binaryResolver = resolveBinaryPath,
    this._httpProbe = probeHttpStatus,
    this._tcpProbe = probeTcpConnect,
    bool Function()? hasGuiSession,
    this._now = DateTime.now,
    this.backoffStart = const Duration(seconds: 2),
    this.backoffMax = const Duration(seconds: 60),
    this.failureLimit = 5,
    this.failureWindow = const Duration(minutes: 10),
    this.sigtermAfter = const Duration(seconds: 10),
    this.sigkillAfter = const Duration(seconds: 20),
    this.probeInterval = const Duration(milliseconds: 500),
    this.exitPollInterval = const Duration(milliseconds: 100),
    this.reapGrace = const Duration(seconds: 2),
    this.logRingBytes = 2 * 1024 * 1024,
    this.failureLogLines = 20,
  }) : _hasGuiSession = hasGuiSession ?? _detectGuiSession;

  final OwnedTerminalSessionPort _terminals;
  final EnvironmentProcessGroups _groups;
  final EnvironmentBinaryResolver _binaryResolver;
  final EnvironmentHttpProbe _httpProbe;
  final EnvironmentTcpProbe _tcpProbe;
  final bool Function() _hasGuiSession;
  final DateTime Function() _now;

  /// The first restart delay, doubled per consecutive failure.
  final Duration backoffStart;

  /// The longest restart delay. A run that lasted this long resets the count.
  final Duration backoffMax;

  /// Failures in [failureWindow] after which `on-failure` gives up.
  final int failureLimit;

  /// See [failureLimit].
  final Duration failureWindow;

  /// When a stop escalates from SIGINT to SIGTERM.
  final Duration sigtermAfter;

  /// When a stop escalates to SIGKILL, from the start of the stop.
  final Duration sigkillAfter;

  /// Between readiness attempts.
  final Duration probeInterval;

  /// Between checks that a stopped group has gone.
  final Duration exitPollInterval;

  /// Between SIGTERM and SIGKILL for a group found at boot.
  final Duration reapGrace;

  /// The size of each log ring.
  final int logRingBytes;

  /// Lines quoted when something fails.
  final int failureLogLines;

  final Map<String, _Supervised> _entries = {};
  final StreamController<EnvironmentProcessStateChange> _states =
      StreamController.broadcast();
  final StreamController<EnvironmentProcessExit> _exits =
      StreamController.broadcast();

  static bool _detectGuiSession() {
    if (!Platform.isLinux) {
      return true;
    }
    final environment = Platform.environment;
    return (environment['DISPLAY'] ?? '').isNotEmpty ||
        (environment['WAYLAND_DISPLAY'] ?? '').isNotEmpty;
  }

  static String _key(String environmentId, String componentId) =>
      '$environmentId/$componentId';

  /// Asked before a crashed process comes back. Throwing keeps it down.
  ///
  /// Whoever owns admission sets this: a restart runs whatever is in the
  /// worktree now, which may not be what was admitted at the start.
  Future<void> Function(EnvironmentProcessSpec spec)? respawnGate;

  /// Every state change.
  Stream<EnvironmentProcessStateChange> get states => _states.stream;

  /// Every exit that wasn't asked for.
  Stream<EnvironmentProcessExit> get exits => _exits.stream;

  /// Starts [spec], or does nothing when it is already running.
  ///
  /// Returns once the command is spawned: see [waitReady]. Throws
  /// [EnvironmentDriverException] when it can't be spawned at all.
  Future<void> start(EnvironmentProcessSpec spec) async {
    if (spec.kind == EnvironmentSupervisedKind.app && !_hasGuiSession()) {
      throw const EnvironmentDriverException(
        EnvironmentError(
          code: 'no-gui-session',
          message:
              'This server has no GUI session, so a desktop app has nowhere '
              'to open its window',
        ),
      );
    }
    final key = _key(spec.environmentId, spec.componentId);
    var entry = _entries[key];
    if (entry != null && !entry.exited) {
      if (entry.state == 'failed' &&
          spec.kind == EnvironmentSupervisedKind.process) {
        // Still running, but its readiness timed out. A new Start is a new
        // chance: probe again rather than repeat the old verdict.
        _set(entry, 'starting');
        unawaited(_awaitReadiness(entry, entry.generation));
      }
      return;
    }
    if (entry == null) {
      final ring = EnvironmentLogRing(
        path: _logPath(spec.stateDir, spec.componentId),
        maxBytes: logRingBytes,
      );
      await ring.load();
      entry = _entries[key] = _Supervised(spec, ring);
    }
    entry
      ..spec = spec
      ..stopping = false
      ..restarts = 0
      ..failures.clear()
      ..consecutiveFailures = 0;
    entry.backoff?.cancel();
    await _spawn(entry);
  }

  /// Waits until [componentId] is up.
  ///
  /// Rides through restarts: a process that crashes once on the way up is
  /// still on its way up. Throws [EnvironmentDriverException] when it ends in
  /// any state that isn't up.
  Future<EnvironmentComponentState> waitReady(
    String environmentId,
    String componentId,
  ) async {
    final entry = _require(environmentId, componentId);
    bool isFinal(String state) =>
        const {'ready', 'running'}.contains(state) || _isDown(state);
    final state = isFinal(entry.state)
        ? entry.state
        : await entry.changes.stream.firstWhere(isFinal);
    if (_isDown(state)) {
      throw EnvironmentDriverException(
        EnvironmentError(
          code: 'process-$state',
          message: entry.detail ?? '$componentId is $state',
          exitCode: entry.lastExitCode,
        ),
      );
    }
    return _snapshot(entry);
  }

  static bool _isDown(String state) =>
      const {'failed', 'stopped', 'closed', 'crashed'}.contains(state);

  /// Stops [componentId]: SIGINT to the group, then SIGTERM, then SIGKILL.
  ///
  /// It stays stopped until [start] or [restart] says otherwise.
  Future<void> stop(String environmentId, String componentId) async {
    final entry = _entries[_key(environmentId, componentId)];
    if (entry == null) {
      return;
    }
    entry.stopping = true;
    entry.backoff?.cancel();
    final session = entry.session;
    if (session != null && !entry.exited) {
      final group = session.pid;
      _groups.signal(group, ProcessSignal.sigint);
      if (!await _isGone(entry, group, sigtermAfter)) {
        _groups.signal(group, ProcessSignal.sigterm);
        if (!await _isGone(entry, group, sigkillAfter - sigtermAfter)) {
          _groups.signal(group, ProcessSignal.sigkill);
          await _isGone(entry, group, reapGrace);
        }
      }
      await _terminals.killOwned(
        workspaceId: entry.spec.workspaceId,
        sessionId: session.sessionId,
        owner: entry.spec.owner,
      );
    }
    entry
      ..session = null
      ..exited = true;
    await _deletePidFile(entry.spec);
    await entry.ring.flush();
    _set(
      entry,
      entry.spec.kind == EnvironmentSupervisedKind.app ? 'closed' : 'stopped',
    );
  }

  /// Stops and starts [componentId], clearing its failure history.
  Future<void> restart(String environmentId, String componentId) async {
    final entry = _require(environmentId, componentId);
    final restarts = entry.restarts;
    await stop(environmentId, componentId);
    await start(entry.spec);
    entry.restarts = restarts + 1;
    _publish(entry);
  }

  /// Stops every component of [environmentId], last started first.
  Future<void> stopEnvironment(String environmentId) async {
    final entries = _entries.values
        .where((entry) => entry.spec.environmentId == environmentId)
        .toList(growable: false)
        .reversed;
    for (final entry in entries) {
      await stop(environmentId, entry.spec.componentId);
    }
  }

  /// Forgets [environmentId] after a destroy. Its components must be stopped.
  Future<void> forget(String environmentId) async {
    final keys = _entries.keys
        .where((key) => key.startsWith('$environmentId/'))
        .toList(growable: false);
    for (final key in keys) {
      final entry = _entries.remove(key);
      await entry?.ring.close();
      await entry?.changes.close();
    }
  }

  /// Where [componentId] stands, or null when it was never started.
  EnvironmentComponentState? stateOf(String environmentId, String componentId) {
    final entry = _entries[_key(environmentId, componentId)];
    return entry == null ? null : _snapshot(entry);
  }

  /// The pid and process group of [componentId], or null when not running.
  /// This is what finding a component's windows starts from.
  EnvironmentProcessIds? processOf(String environmentId, String componentId) {
    final entry = _entries[_key(environmentId, componentId)];
    final session = entry?.session;
    if (entry == null || session == null || entry.exited) {
      return null;
    }
    return EnvironmentProcessIds(pid: session.pid, processGroup: session.pid);
  }

  /// Every live pid in [componentId]'s group: a launcher and what it launched.
  Future<List<int>> processTreeOf(
    String environmentId,
    String componentId,
  ) async {
    final ids = processOf(environmentId, componentId);
    return ids == null ? const [] : _groups.members(ids.processGroup);
  }

  /// The last [tail] lines of [componentId], from this run or, when it isn't
  /// supervised right now, from what it left in [stateDir].
  Future<List<String>> logs({
    required String environmentId,
    required String componentId,
    required String stateDir,
    int tail = 200,
  }) async {
    final entry = _entries[_key(environmentId, componentId)];
    if (entry != null) {
      return entry.ring.tail(tail);
    }
    final ring = EnvironmentLogRing(
      path: _logPath(stateDir, componentId),
      maxBytes: logRingBytes,
    );
    await ring.load();
    return ring.tail(tail);
  }

  /// [tail] lines of [componentId], then new ones as they come.
  Stream<String> followLogs(
    String environmentId,
    String componentId, {
    int tail = 200,
  }) async* {
    final entry = _require(environmentId, componentId);
    final live = StreamController<String>();
    final subscription = entry.ring.lines.listen(
      live.add,
      onDone: () => unawaited(live.close()),
    );
    final history = entry.ring.tail(tail);
    try {
      yield* Stream.fromIterable(history);
      yield* live.stream;
    } finally {
      await subscription.cancel();
      // Not awaited: `close` never completes on a stream nobody listened to,
      // which is the case when this is cancelled while replaying history.
      unawaited(live.close());
    }
  }

  /// Kills the groups a previous server left behind in [stateDir].
  ///
  /// A pid is only trusted when the process still has the recorded start time,
  /// because after a reboot the number may belong to something else entirely.
  /// With the leader gone a group id can't be reused while any member lives,
  /// so a group that still has members is still ours.
  ///
  /// Returns the components it killed.
  Future<List<String>> reapSurvivors(String stateDir) async {
    final directory = Directory(p.join(stateDir, 'pids'));
    if (!directory.existsSync()) {
      return const [];
    }
    final reaped = <String>[];
    await for (final entry in directory.list()) {
      if (entry is! File) {
        continue;
      }
      final record = _parsePidFile(entry);
      if (record != null && await _isOurs(record.group, record.startTime)) {
        _groups.signal(record.group, ProcessSignal.sigterm);
        await Future<void>.delayed(reapGrace);
        if ((await _groups.members(record.group)).isNotEmpty) {
          _groups.signal(record.group, ProcessSignal.sigkill);
        }
        reaped.add(p.basename(entry.path));
      }
      if (entry.existsSync()) {
        await entry.delete();
      }
    }
    return reaped;
  }

  /// Boot: reaps [stateDir], then starts [specs]. Apps never come back on their
  /// own, so they are skipped: a window appearing after a reboot is unwelcome,
  /// and someone may have closed it on purpose.
  Future<void> recover({
    required String stateDir,
    required List<EnvironmentProcessSpec> specs,
  }) async {
    await reapSurvivors(stateDir);
    for (final spec in specs) {
      if (spec.kind == EnvironmentSupervisedKind.process) {
        await start(spec);
      }
    }
  }

  /// Stops supervising without touching any process: pid files stay, so the
  /// next boot deals with what is still running.
  Future<void> dispose() async {
    for (final entry in _entries.values) {
      entry
        ..stopping = true
        ..backoff?.cancel();
      await entry.ring.close();
      await entry.changes.close();
    }
    _entries.clear();
    await _states.close();
    await _exits.close();
  }

  _Supervised _require(String environmentId, String componentId) {
    final entry = _entries[_key(environmentId, componentId)];
    if (entry == null) {
      throw EnvironmentDriverException(
        EnvironmentError(
          code: 'process-unknown',
          message: '$componentId is not running',
        ),
      );
    }
    return entry;
  }

  Future<void> _spawn(_Supervised entry) async {
    final spec = entry.spec;
    // Checked here because the PTY layer can't report either: it ignores a
    // failed `chdir`, and a failed `exec` leaves the forked child running.
    if (!Directory(spec.workingDirectory).existsSync()) {
      throw EnvironmentDriverException(
        EnvironmentError(
          code: 'cwd-missing',
          message: 'Working directory ${spec.workingDirectory} does not exist',
        ),
      );
    }
    final executable = await resolveEnvironmentExecutable(
      spec.argv.first,
      workingDirectory: spec.workingDirectory,
      resolver: _binaryResolver,
    );
    final variables = <String, String>{...spec.environment};
    if (spec.isolateHome) {
      final home = spec.homeVariables;
      for (final directory in home.values.toSet()) {
        await Directory(directory).create(recursive: true);
      }
      variables.addAll(home);
    }

    final generation = ++entry.generation;
    entry
      ..logMatched = false
      ..startedAt = _now();
    final matcher = spec.ready?.logMatch == null
        ? null
        : RegExp(spec.ready!.logMatch!);
    StreamSubscription<String>? watch;
    if (matcher != null) {
      watch = entry.ring.lines.listen((line) {
        if (generation == entry.generation && matcher.hasMatch(line)) {
          entry.logMatched = true;
          unawaited(watch?.cancel());
        }
      });
    }

    final session = await _terminals.spawnOwned(
      workspaceId: spec.workspaceId,
      spaceId: spec.spaceId,
      owner: spec.owner,
      executable: executable,
      arguments: spec.argv.sublist(1),
      environment: environmentProcessVariables(
        variables,
        executable: executable,
      ),
      cwd: spec.workingDirectory,
      onOutput: entry.ring.addBytes,
    );
    entry
      ..session = session
      ..exited = false;
    await _writePidFile(spec, session.pid);
    unawaited(
      session.exitCode.then((code) => _onExit(entry, generation, code)),
    );

    if (spec.kind == EnvironmentSupervisedKind.app) {
      _set(entry, 'running');
    } else {
      _set(entry, 'starting');
      unawaited(_awaitReadiness(entry, generation));
    }
  }

  /// Runs [argv] on a terminal for a person to answer, unsupervised: nothing
  /// restarts it and nothing watches for readiness.
  Future<OwnedTerminalSession> startInteractive({
    required String workspaceId,
    required String spaceId,
    required String owner,
    required List<String> argv,
    required Map<String, String> environment,
    required String workingDirectory,
    void Function(List<int> bytes)? onOutput,
  }) async {
    final executable = await resolveEnvironmentExecutable(
      argv.first,
      workingDirectory: workingDirectory,
      resolver: _binaryResolver,
    );
    return _terminals.spawnOwned(
      workspaceId: workspaceId,
      spaceId: spaceId,
      owner: owner,
      executable: executable,
      arguments: argv.sublist(1),
      environment: environmentProcessVariables({
        ...environment,
        'TERM': 'xterm-256color',
      }, executable: executable),
      cwd: workingDirectory,
      onOutput: onOutput,
    );
  }

  /// Ends what [startInteractive] started.
  Future<void> stopInteractive({
    required String workspaceId,
    required String sessionId,
    required String owner,
  }) => _terminals.killOwned(
    workspaceId: workspaceId,
    sessionId: sessionId,
    owner: owner,
  );

  Future<void> _awaitReadiness(_Supervised entry, int generation) async {
    final probe = entry.spec.ready;
    if (probe == null ||
        (probe.http == null && probe.tcp == null && probe.logMatch == null)) {
      _set(entry, 'ready');
      return;
    }
    final limit = Duration(seconds: probe.timeoutSeconds);
    final elapsed = Stopwatch()..start();
    while (generation == entry.generation && !entry.stopping && !entry.exited) {
      if (await _passes(entry, probe)) {
        if (generation == entry.generation && !entry.exited) {
          _set(entry, 'ready');
        }
        return;
      }
      if (elapsed.elapsed > limit) {
        _set(
          entry,
          'failed',
          detail: _withLastLines(entry, 'Not ready after ${limit.inSeconds} s'),
        );
        return;
      }
      await Future<void>.delayed(probeInterval);
    }
  }

  Future<bool> _passes(_Supervised entry, EnvironmentReadyProbe probe) async {
    if (probe.logMatch != null && !entry.logMatched) {
      return false;
    }
    final http = probe.http;
    if (http != null) {
      final status = await _httpProbe(Uri.parse(http));
      if (status == null || status >= probe.expectBelow) {
        return false;
      }
    }
    final tcp = probe.tcp;
    if (tcp != null) {
      final separator = tcp.lastIndexOf(':');
      final port = int.tryParse(tcp.substring(separator + 1));
      if (separator <= 0 ||
          port == null ||
          !await _tcpProbe(tcp.substring(0, separator), port)) {
        return false;
      }
    }
    return true;
  }

  Future<void> _onExit(_Supervised entry, int generation, int code) async {
    if (generation != entry.generation) {
      return;
    }
    entry
      ..exited = true
      ..lastExitCode = code;
    entry.ring.finishLine();
    if (entry.stopping) {
      return;
    }
    final spec = entry.spec;
    final pid = entry.session?.pid;
    entry.session = null;
    await _deletePidFile(spec);

    final String state;
    if (spec.kind == EnvironmentSupervisedKind.app) {
      state = code == 0 ? 'closed' : 'crashed';
      _set(
        entry,
        state,
        detail: code == 0
            ? null
            : _withLastLines(entry, 'Crashed with exit code $code'),
      );
    } else {
      // Whatever the leader left running still holds its ports, and the next
      // start would lose to it.
      if (pid != null) {
        _groups.signal(pid, ProcessSignal.sigterm);
      }
      state = _afterProcessExit(entry, code);
    }
    await entry.ring.flush();
    if (!_exits.isClosed) {
      _exits.add(
        EnvironmentProcessExit(
          workspaceId: spec.workspaceId,
          spaceId: spec.spaceId,
          environmentId: spec.environmentId,
          componentId: spec.componentId,
          exitCode: code,
          state: state,
        ),
      );
    }
  }

  /// A server has no reason to exit, so any exit counts as a failure here,
  /// including a clean one.
  String _afterProcessExit(_Supervised entry, int code) {
    final now = _now();
    final policy = entry.spec.restart;
    final ranFor = entry.startedAt == null
        ? Duration.zero
        : now.difference(entry.startedAt!);
    if (ranFor >= backoffMax) {
      entry.consecutiveFailures = 0;
    }
    entry.failures
      ..add(now)
      ..removeWhere((at) => now.difference(at) > failureWindow);

    if (policy == EnvironmentRestartPolicy.never) {
      _set(
        entry,
        'failed',
        detail: _withLastLines(entry, 'Exited with code $code'),
      );
      return 'failed';
    }
    if (policy == EnvironmentRestartPolicy.onFailure &&
        entry.failures.length >= failureLimit) {
      _set(
        entry,
        'failed',
        detail: _withLastLines(
          entry,
          'Gave up after ${entry.failures.length} failures in '
          '${failureWindow.inMinutes} minutes (last exit code $code)',
        ),
      );
      return 'failed';
    }
    final delay = backoffFor(entry.consecutiveFailures);
    entry
      ..consecutiveFailures += 1
      ..restarts += 1;
    _set(
      entry,
      'starting',
      detail: 'Exited with code $code, restarting in ${delay.inSeconds} s',
    );
    entry.backoff = Timer(delay, () => unawaited(_respawn(entry)));
    return 'starting';
  }

  /// The delay before the restart after [failures] consecutive failures.
  Duration backoffFor(int failures) {
    final shift = failures > 16 ? 16 : failures;
    final delay = backoffStart * (1 << shift);
    return delay > backoffMax ? backoffMax : delay;
  }

  Future<void> _respawn(_Supervised entry) async {
    if (entry.stopping) {
      return;
    }
    final generation = entry.generation;
    try {
      await respawnGate?.call(entry.spec);
      // A stop or a start may have got there while the gate was deciding.
      if (entry.stopping || entry.generation != generation) {
        return;
      }
      await _spawn(entry);
    } on Object catch (e) {
      if (!entry.stopping) {
        _set(entry, 'failed', detail: 'Could not restart: $e');
      }
    }
  }

  /// Polls until the leader has exited and the group is empty, or [limit]
  /// passes. The leader alone isn't enough: a wrapper tends to exit first and
  /// leave the server it started still shutting down.
  Future<bool> _isGone(_Supervised entry, int group, Duration limit) async {
    final elapsed = Stopwatch()..start();
    while (true) {
      if (entry.exited && (await _groups.members(group)).isEmpty) {
        return true;
      }
      if (elapsed.elapsed > limit) {
        return false;
      }
      await Future<void>.delayed(exitPollInterval);
    }
  }

  Future<bool> _isOurs(int group, String? recorded) async {
    final current = await _groups.startTime(group);
    if (current != null) {
      if (recorded == current) {
        return true;
      }
      CcInfraLog.info('pid $group was reused, leaving it alone');
      return false;
    }
    return (await _groups.members(group)).isNotEmpty;
  }

  String _withLastLines(_Supervised entry, String message) {
    final lines = entry.ring.tail(failureLogLines);
    return lines.isEmpty ? message : '$message\n${lines.join('\n')}';
  }

  void _set(_Supervised entry, String state, {String? detail}) {
    entry
      ..state = state
      ..detail = detail;
    _publish(entry);
  }

  void _publish(_Supervised entry) {
    if (!entry.changes.isClosed) {
      entry.changes.add(entry.state);
    }
    if (!_states.isClosed) {
      _states.add(
        EnvironmentProcessStateChange(
          workspaceId: entry.spec.workspaceId,
          spaceId: entry.spec.spaceId,
          environmentId: entry.spec.environmentId,
          state: _snapshot(entry),
        ),
      );
    }
  }

  EnvironmentComponentState _snapshot(_Supervised entry) =>
      EnvironmentComponentState(
        id: entry.spec.componentId,
        kind: entry.spec.kind.name,
        state: entry.state,
        label: entry.spec.label,
        detail: entry.detail,
        restarts: entry.restarts,
        sessionId: entry.session?.sessionId,
        lastExitCode: entry.lastExitCode,
      );

  static String _logPath(String stateDir, String componentId) =>
      p.join(stateDir, 'logs', '$componentId.log');

  static File _pidFile(EnvironmentProcessSpec spec) =>
      File(p.join(spec.stateDir, 'pids', spec.componentId));

  Future<void> _writePidFile(EnvironmentProcessSpec spec, int group) async {
    final file = _pidFile(spec);
    await file.parent.create(recursive: true);
    await file.writeAsString(
      jsonEncode({'group': group, 'startTime': await _groups.startTime(group)}),
    );
  }

  Future<void> _deletePidFile(EnvironmentProcessSpec spec) async {
    final file = _pidFile(spec);
    if (file.existsSync()) {
      await file.delete();
    }
  }

  ({int group, String? startTime})? _parsePidFile(File file) {
    try {
      final json = jsonDecode(file.readAsStringSync());
      if (json is Map && json['group'] is int) {
        return (
          group: json['group'] as int,
          startTime: json['startTime'] as String?,
        );
      }
    } on Object catch (e) {
      CcInfraLog.warning('unreadable pid file ${file.path}: $e');
    }
    return null;
  }
}
