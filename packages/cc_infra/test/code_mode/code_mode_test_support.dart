import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:cc_domain/core/domain/ports/embedding_port.dart';
import 'package:cc_domain/features/code_mode/domain/entities/code_execution.dart';
import 'package:cc_domain/features/code_mode/domain/entities/code_execution_call.dart';
import 'package:cc_domain/features/code_mode/domain/ports/code_execution_repository.dart';
import 'package:cc_domain/features/code_mode/domain/ports/code_mode_store_repository.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_execution_status.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode_store_write.dart';
import 'package:cc_infra/src/code_mode/bundled_code_runner.dart';
import 'package:cc_infra/src/code_mode/code_sandbox_process.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// The real `cc_codemode` for tests, named by `CC_CODEMODE_RUNNER`. Fails
/// (never skips) when it is unset or missing, because a host test that
/// silently skips proves nothing about the sandbox. There is no install-path
/// fallback: the build script picks the install directory per machine.
String realRunnerPath() {
  const hint =
      'These tests need the real code mode runner. Build it with '
      '`CARGO_TARGET_DIR=build/cargo/codemode cargo build --release --locked '
      '--manifest-path packages/cc_natives/native/codemode/Cargo.toml` and '
      'set CC_CODEMODE_RUNNER to the absolute path of the built '
      '`cc_codemode`.';
  final override = Platform.environment[BundledCodeRunner.environmentOverride];
  if (override == null || override.isEmpty) {
    fail('$hint CC_CODEMODE_RUNNER is not set.');
  }
  try {
    return BundledCodeRunner.locate(
      appSupportRoot: Directory.systemTemp.path,
    ).executable;
  } on CodeRunnerNotFoundException catch (e) {
    fail('$hint ${e.message}');
  }
}

/// Whether the process [pid] still exists.
bool processAlive(int pid) =>
    Process.runSync('/bin/kill', ['-0', '$pid']).exitCode == 0;

/// The protocol a fake runner speaks: the host's.
const int fakeProtocol = CodeSandboxProcess.protocolVersion;

/// The `ready` frame of a fake runner that claims full lockdown.
const String fakeReadyFull =
    '{"type":"ready","protocol":$fakeProtocol,"engine":"fake 1","runner":"0",'
    '"lockdown":{"level":"full","os":"test","controls":[],"failed":[]}}';

/// The skip reason for a test that runs [FakeRunners] on Windows, which can
/// exec neither their `/bin/sh` scripts nor the `/bin` tools they call.
final String? fakeRunnersSkip = Platform.isWindows
    ? 'fake runners are /bin/sh scripts'
    : null;

/// Writes fake runners: `/bin/sh` scripts that speak the protocol badly.
class FakeRunners {
  FakeRunners(this.dir);

  final Directory dir;
  var _n = 0;

  /// A script running [body] after it writes its pid to [pidFile]. The body
  /// uses absolute paths: the runner gets an empty `PATH`. Asked for its
  /// `--version`, it prints [version].
  String script(
    String body, {
    String version = 'cc_codemode 0 fake protocol $fakeProtocol',
  }) {
    final n = ++_n;
    final file = File(p.join(dir.path, 'runner_$n.sh'));
    file.writeAsStringSync(
      '#!/bin/sh\n'
      // The protocol check before every self-test (`--version`).
      'if [ "\$1" = "--version" ]; then\n'
      '  /bin/echo "$version"; exit 0\n'
      'fi\n'
      'echo \$\$ > ${pidFile(n)}\n$body\n',
    );
    final chmod = Process.runSync('/bin/chmod', ['+x', file.path]);
    expect(chmod.exitCode, 0);
    return file.path;
  }

  /// Where script [n] writes its pid.
  String pidFile(int n) => p.join(dir.path, 'runner_$n.pid');

  /// The pid the most recent script wrote, or null.
  int? lastPid() {
    final file = File(pidFile(_n));
    if (!file.existsSync()) {
      return null;
    }
    return int.tryParse(file.readAsStringSync().trim());
  }
}

/// An in-memory [CodeExecutionRepository] that keeps the DAO's rules: a
/// record is begun running, gains call rows while it runs, and is finished
/// once; a finished record never changes.
class MemoryExecutions implements CodeExecutionRepository {
  final Map<String, CodeExecutionDetail> rows = {};

  /// Ids in the order they were begun, and in the order they were finished.
  final List<String> begins = [];
  final List<String> finishes = [];

  /// Runs with no run log: [begin] refuses them, as the DAO does.
  final Set<String> runsWithoutLog = {};
  Object? failBeginWith;
  Object? failFinishWith;

  /// Spaces the workspace no longer has: [begin] refuses them, as the DAO
  /// does.
  final Set<String> goneSpaces = {};

  /// Ids [close] ended, in order.
  final List<String> closes = [];

  /// Called when [begin] is entered, before anything is written.
  void Function(CodeExecution execution)? onBegin;

  @override
  Future<void> begin(
    String workspaceId,
    CodeExecution execution, {
    required String source,
  }) async {
    onBegin?.call(execution);
    final failure = failBeginWith;
    if (failure != null) {
      throw failure;
    }
    if (execution.status != CodeExecutionStatus.running) {
      throw ArgumentError.value(execution.status, 'status', 'not running');
    }
    if (runsWithoutLog.contains(execution.runId)) {
      throw CodeExecutionBeginRefused(
        CodeExecutionBeginRefusal.noRun,
        execution.id,
      );
    }
    if (rows.containsKey(execution.id)) {
      throw CodeExecutionBeginRefused(
        CodeExecutionBeginRefusal.idTaken,
        execution.id,
      );
    }
    if (goneSpaces.contains(execution.spaceId)) {
      throw CodeExecutionBeginRefused(
        CodeExecutionBeginRefusal.spaceGone,
        execution.id,
      );
    }
    begins.add(execution.id);
    rows[execution.id] = CodeExecutionDetail(
      execution: execution,
      payload: CodeExecutionPayload(
        executionId: execution.id,
        source: source,
        output: '',
        console: '',
      ),
      calls: const [],
    );
  }

  @override
  Future<CodeExecutionAppendOutcome> appendCall(
    String workspaceId,
    CodeExecutionCall call,
  ) async {
    final row = rows[call.executionId];
    if (row == null || row.execution.status != CodeExecutionStatus.running) {
      return CodeExecutionAppendOutcome.notRunning;
    }
    if (row.calls.any((c) => c.sequence == call.sequence)) {
      return CodeExecutionAppendOutcome.sequenceTaken;
    }
    rows[call.executionId] = CodeExecutionDetail(
      execution: row.execution,
      payload: row.payload,
      calls: [...row.calls, call],
    );
    return CodeExecutionAppendOutcome.appended;
  }

  @override
  Future<bool> close(
    String workspaceId,
    String executionId, {
    required CodeExecutionStatus status,
    required String errorKind,
    required int durationMs,
  }) async {
    final row = rows[executionId];
    if (row == null || row.execution.status != CodeExecutionStatus.running) {
      return false;
    }
    closes.add(executionId);
    rows[executionId] = CodeExecutionDetail(
      execution: row.execution.ended(
        status: status,
        durationMs: durationMs,
        errorKind: errorKind,
      ),
      payload: row.payload,
      calls: row.calls,
    );
    return true;
  }

  @override
  Future<CodeExecutionFinishResult> finish(
    String workspaceId,
    CodeExecution execution, {
    required CodeExecutionPayload payload,
    required List<CodeExecutionCall> calls,
  }) async {
    final failure = failFinishWith;
    if (failure != null) {
      throw failure;
    }
    if (execution.status == CodeExecutionStatus.running) {
      throw ArgumentError.value(execution.status, 'status', 'still running');
    }
    final row = rows[execution.id];
    if (row == null) {
      return CodeExecutionFinishResult.gone;
    }
    if (row.execution.status != CodeExecutionStatus.running) {
      throw StateError('${execution.id} is already finished');
    }
    finishes.add(execution.id);
    rows[execution.id] = CodeExecutionDetail(
      execution: execution,
      payload: CodeExecutionPayload(
        executionId: execution.id,
        source: row.payload!.source,
        output: payload.output,
        console: payload.console,
        errorName: payload.errorName,
      ),
      calls: [
        ...row.calls,
        for (final c in calls)
          if (!row.calls.any((r) => r.sequence == c.sequence)) c,
      ]..sort((a, b) => a.sequence.compareTo(b.sequence)),
    );
    return CodeExecutionFinishResult.finished;
  }

  @override
  Future<int> highestIdSuffix(
    String workspaceId, {
    required String runId,
    required String toolCallId,
  }) async {
    final base = CodeExecution.idFor(runId: runId, toolCallId: toolCallId);
    var highest = 0;
    for (final id in rows.keys) {
      if (id == base) {
        highest = math.max(highest, 1);
      } else if (id.startsWith('$base#')) {
        final n = int.tryParse(id.substring(base.length + 1));
        if (n != null) {
          highest = math.max(highest, n);
        }
      }
    }
    return highest;
  }

  @override
  Future<CodeExecutionPage> list(
    String workspaceId,
    CodeExecutionQuery query,
  ) async =>
      CodeExecutionPage(items: [for (final r in rows.values) r.execution]);

  @override
  Future<CodeExecutionDetail?> get(
    String workspaceId,
    String executionId,
  ) async => rows[executionId];
}

/// An in-memory [CodeModeStoreRepository] that applies the store rules.
class MemoryStore implements CodeModeStoreRepository {
  final Map<String, Map<String, String>> values = {};
  Object? failCommitWith;
  int commits = 0;

  String _key(String c, String a) => '$c|$a';

  @override
  Future<Map<String, String>> readAll(
    String workspaceId, {
    required String conversationId,
    required String agentId,
  }) async => Map.of(values[_key(conversationId, agentId)] ?? const {});

  @override
  Future<void> commit(
    String workspaceId, {
    required String conversationId,
    required String agentId,
    required List<CodeModeStoreWrite> writes,
  }) async {
    final failure = failCommitWith;
    if (failure != null) {
      throw failure;
    }
    commits++;
    final key = _key(conversationId, agentId);
    values[key] = CodeModeStoreRules.apply(values[key] ?? const {}, writes);
  }
}

/// An embedder that maps a text to a fixed vector by its first letter.
class FakeEmbeddings extends EmbeddingPort {
  FakeEmbeddings({this.ready = true, this.batchDelay = Duration.zero});

  final bool ready;
  int calls = 0;

  /// How long each batch takes, and the most batches embedded at once.
  final Duration batchDelay;
  int batchesInFlight = 0;
  int maxBatchesInFlight = 0;

  @override
  Future<List<Float32List>> embedAll(List<String> texts) async {
    batchesInFlight++;
    maxBatchesInFlight = math.max(maxBatchesInFlight, batchesInFlight);
    try {
      await Future<void>.delayed(batchDelay);
      return await super.embedAll(texts);
    } finally {
      batchesInFlight--;
    }
  }

  @override
  bool get isReady => ready;

  @override
  int get dimension => 3;

  @override
  Future<Float32List> embed(String text) async {
    calls++;
    final c = text.isEmpty ? 'z' : text[0].toLowerCase();
    return Float32List.fromList(switch (c) {
      'a' => [1, 0, 0],
      'b' => [0, 1, 0],
      _ => [0, 0, 1],
    });
  }
}
