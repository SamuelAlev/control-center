import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/features/environments/domain/entities/environment_lease.dart';
import 'package:cc_domain/features/environments/domain/entities/environment_run.dart';
import 'package:cc_domain/features/environments/domain/repositories/environment_repositories.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_status.dart';
import 'package:cc_domain/features/sandboxing/domain/terminal_session_port.dart';
import 'package:cc_infra/src/environments/environment_command_runner.dart';
import 'package:cc_infra/src/environments/environment_process_supervisor.dart';

/// Leases in a list, with the uniqueness the real table enforces.
class InMemoryLeases implements EnvironmentLeaseRepository {
  final List<EnvironmentLease> leases = [];

  @override
  Future<List<EnvironmentLease>> all() async => [...leases];

  @override
  Future<EnvironmentLease?> forSpace(
    String workspaceId,
    String spaceId,
    String definitionId,
  ) async {
    for (final lease in leases) {
      if (lease.workspaceId == workspaceId &&
          lease.spaceId == spaceId &&
          lease.definitionId == definitionId) {
        return lease;
      }
    }
    return null;
  }

  @override
  Future<bool> tryInsert(EnvironmentLease lease) async {
    final taken = leases.any(
      (other) =>
          other.block == lease.block ||
          (lease.poolKey != null &&
              other.poolKey == lease.poolKey &&
              other.poolSlot == lease.poolSlot),
    );
    if (taken) {
      return false;
    }
    leases.add(lease);
    return true;
  }

  @override
  Future<void> release(
    String workspaceId,
    String spaceId,
    String definitionId,
  ) async => leases.removeWhere(
    (lease) =>
        lease.workspaceId == workspaceId &&
        lease.spaceId == spaceId &&
        lease.definitionId == definitionId,
  );

  @override
  Future<void> releaseSpace(String workspaceId, String spaceId) async =>
      leases.removeWhere(
        (lease) => lease.workspaceId == workspaceId && lease.spaceId == spaceId,
      );
}

/// Run records in a map.
class InMemoryRuns implements EnvironmentRunRepository {
  final Map<String, EnvironmentRun> runs = {};
  final List<String> outputWrites = [];
  final List<String> interruptedSweeps = [];

  @override
  Future<void> start(EnvironmentRun run) async => runs[run.id] = run;

  @override
  Future<void> updateOutput(
    String workspaceId,
    String id,
    String output,
  ) async => outputWrites.add(output);

  @override
  Future<void> finish(
    String workspaceId,
    String id, {
    required EnvironmentRunStatus status,
    required DateTime completedAt,
    int? exitCode,
    String? error,
    String? output,
  }) async {
    final run = runs[id]!;
    runs[id] = EnvironmentRun(
      id: run.id,
      workspaceId: run.workspaceId,
      spaceId: run.spaceId,
      environmentId: run.environmentId,
      definitionId: run.definitionId,
      repoId: run.repoId,
      kind: run.kind,
      label: run.label,
      status: status,
      startedAt: run.startedAt,
      completedAt: completedAt,
      exitCode: exitCode,
      error: error,
      output: output ?? '',
    );
  }

  @override
  Future<List<EnvironmentRun>> forSpace(
    String workspaceId,
    String spaceId, {
    int limit = 50,
  }) async => [...runs.values];

  @override
  Future<List<EnvironmentRun>> forDefinition(
    String workspaceId,
    String definitionId, {
    int limit = 50,
  }) async => [...runs.values];

  @override
  Future<EnvironmentRun?> get(String workspaceId, String id) async => runs[id];

  @override
  Future<void> failInterrupted(String workspaceId, DateTime now) async =>
      interruptedSweeps.add(workspaceId);
}

/// One recorded [FakeCommandRunner] call.
class FakeCall {
  FakeCall(this.argv, this.environment, this.workingDirectory, this.timeout);

  final List<String> argv;
  final Map<String, String> environment;
  final String? workingDirectory;
  final Duration? timeout;

  String get line => argv.join(' ');
}

/// A follow-style command a test drives by hand.
class FakeStream {
  FakeStream(this.call);

  final FakeCall call;
  final StreamController<EnvironmentCommandEvent> events =
      StreamController.broadcast(sync: true);
  final Completer<EnvironmentCommandResult> result = Completer();
  bool cancelled = false;

  void emit(String line) => events.add(EnvironmentCommandOutput(line));
}

/// Answers commands from [handler] without running anything.
class FakeCommandRunner extends EnvironmentCommandRunner {
  FakeCommandRunner(this.handler);

  EnvironmentCommandResult Function(FakeCall call) handler;
  final List<FakeCall> calls = [];

  /// Awaited before answering, so a test can hold a command open.
  Future<void> Function(FakeCall call)? beforeAnswer;
  final List<FakeStream> streams = [];

  /// The calls whose argv contains [word].
  List<FakeCall> callsWith(String word) =>
      calls.where((call) => call.argv.contains(word)).toList();

  @override
  Future<EnvironmentCommandResult> runArgv(
    List<String> argv, {
    String? workingDirectory,
    Map<String, String> environment = const {},
    Duration? timeout,
    void Function(EnvironmentCommandEvent event)? onEvent,
  }) async {
    final call = FakeCall(argv, environment, workingDirectory, timeout);
    calls.add(call);
    await beforeAnswer?.call(call);
    return handler(call);
  }

  @override
  EnvironmentCommandHandle startArgv(
    List<String> argv, {
    String? workingDirectory,
    Map<String, String> environment = const {},
    Duration? timeout,
  }) {
    final stream = FakeStream(
      FakeCall(argv, environment, workingDirectory, timeout),
    );
    streams.add(stream);
    return EnvironmentCommandHandle(
      events: stream.events.stream,
      result: stream.result.future,
      onCancel: () {
        stream.cancelled = true;
        if (!stream.result.isCompleted) {
          stream.result.complete(ok());
        }
      },
    );
  }
}

/// A successful result.
EnvironmentCommandResult ok([String stdout = '']) =>
    EnvironmentCommandResult(exitCode: 0, display: 'fake', stdout: stdout);

/// A failed result.
EnvironmentCommandResult failed(
  int exitCode, {
  String stderr = '',
  String stdout = '',
  EnvironmentError? error,
}) => EnvironmentCommandResult(
  exitCode: exitCode,
  display: 'fake',
  stderr: stderr,
  stdout: stdout,
  error:
      error ??
      EnvironmentError(
        code: 'command-failed',
        message: stderr.isEmpty ? 'exited $exitCode' : stderr,
        exitCode: exitCode,
      ),
);

/// One session of [FakeTerminals].
class FakeTerminalSession {
  FakeTerminalSession({
    required this.owner,
    required this.executable,
    required this.arguments,
    required this.environment,
    required this.cwd,
    required this.pid,
    required this.onOutput,
  });

  final String owner;
  final String executable;
  final List<String> arguments;
  final Map<String, String> environment;
  final String cwd;
  final int pid;
  final void Function(List<int> bytes)? onOutput;
  final Completer<int> exit = Completer();
  bool killed = false;

  void print(String text) => onOutput?.call(utf8.encode(text));
}

/// Spawns nothing. A test prints and exits by hand.
class FakeTerminals implements OwnedTerminalSessionPort {
  final List<FakeTerminalSession> sessions = [];
  int nextPid = 7000;

  /// Whether a stop's signals end the session on their own.
  FakeTerminalSession get last => sessions.last;

  @override
  Future<OwnedTerminalSession> spawnOwned({
    required String workspaceId,
    required String owner,
    required String executable,
    required String cwd,
    List<String> arguments = const [],
    Map<String, String> environment = const {},
    String? spaceId,
    int rows = 30,
    int cols = 120,
    void Function(List<int> bytes)? onOutput,
  }) async {
    final session = FakeTerminalSession(
      owner: owner,
      executable: executable,
      arguments: arguments,
      environment: environment,
      cwd: cwd,
      pid: nextPid++,
      onOutput: onOutput,
    );
    sessions.add(session);
    return OwnedTerminalSession(
      sessionId: 'session-${sessions.length}',
      pid: session.pid,
      exitCode: session.exit.future,
    );
  }

  @override
  Future<void> killOwned({
    required String workspaceId,
    required String sessionId,
    required String owner,
  }) async {
    final session = sessions[int.parse(sessionId.split('-').last) - 1];
    session.killed = true;
    if (!session.exit.isCompleted) {
      session.exit.complete(-9);
    }
  }

  @override
  String? ownerOf(String sessionId) => null;

  @override
  List<String> sessionsOwnedBy({
    required String workspaceId,
    required String ownerPrefix,
  }) => const [];
}

/// Process groups in a map.
class FakeGroups implements EnvironmentProcessGroups {
  final Map<int, List<int>> groups = {};
  final Map<int, String> startTimes = {};
  final List<(int, ProcessSignal)> signals = [];

  /// Called on every signal, to end a process the way a test wants.
  void Function(int group, ProcessSignal signal)? onSignal;

  @override
  bool signal(int group, ProcessSignal signal) {
    signals.add((group, signal));
    onSignal?.call(group, signal);
    return true;
  }

  @override
  Future<List<int>> members(int group) async => groups[group] ?? const [];

  @override
  Future<String?> startTime(int pid) async => startTimes[pid];
}

/// A temp directory removed when the test ends.
Directory tempDir(void Function(void Function()) addTearDown) {
  final directory = Directory.systemTemp.createTempSync('cc_env_');
  addTearDown(() {
    if (directory.existsSync()) {
      directory.deleteSync(recursive: true);
    }
  });
  return Directory(directory.resolveSymbolicLinksSync());
}
