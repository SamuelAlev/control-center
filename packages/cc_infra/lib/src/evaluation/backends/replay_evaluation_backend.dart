import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/features/evals/domain/evaluation/evaluation_attempt.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_backend_port.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_plan.dart';
import 'package:path/path.dart' as p;

/// One recorded attempt plus the workspace change it produced.
class EvaluationReplayRecording {
  /// Creates an [EvaluationReplayRecording].
  const EvaluationReplayRecording({required this.attempt, required this.diff});

  /// The attempt as it was observed live.
  final EvaluationAttempt attempt;

  /// The unified diff of the workspace change the attempt left behind.
  final String diff;
}

/// OFFLINE REPLAY: re-verifies a *recorded* attempt without calling a model.
///
/// This is the only mode that is not a live evaluation, and it is deliberately
/// shaped so it cannot be mistaken for one:
///
///  * [callsModel] is false and every attempt it produces is stamped
///    [EvaluationExecutionMode.offlineReplay];
///  * the recording must exist — a missing cassette is an ERROR attempt, never
///    a synthesized pass;
///  * only the recorded workspace change is replayed, then the acceptance
///    checks are re-run for real with [VerificationProvenance.replayDeterministic]
///    provenance, so a replay answers exactly one question: "does the recorded
///    artifact still satisfy this task's behavioral checks".
class ReplayEvaluationBackend implements EvaluationBackendPort {
  /// Creates a [ReplayEvaluationBackend].
  ReplayEvaluationBackend({required this.recordingsDir});

  /// Directory holding one `<attemptId>.json` recording per attempt, as written
  /// by a previous live campaign.
  final String recordingsDir;

  @override
  String get id => 'replay';

  @override
  bool get callsModel => false;

  /// Everything this backend cannot actually execute for [effective]. Null when
  /// the arm is implementable — a replay re-verifies behavior that already
  /// happened, so it never has to implement a policy.
  @override
  String? unsupportedReason(EvaluationEffectiveConfig effective) => null;

  @override
  Future<EvaluationAttempt> execute(EvaluationAttemptRequest request) async {
    throw StateError(
      'replay is driven through the evaluation engine, which owns workspace '
      'restoration; call missingRecording() for an absent cassette',
    );
  }

  /// Loads the recording for [attemptId], or null when it is absent/unreadable.
  Future<EvaluationReplayRecording?> recordingFor(String attemptId) async {
    final file = File(p.join(recordingsDir, '$attemptId.json'));
    if (!file.existsSync()) {
      return null;
    }
    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      final attemptJson = decoded['attempt'];
      if (attemptJson is! Map) {
        return null;
      }
      return EvaluationReplayRecording(
        attempt: EvaluationAttempt.fromJson(
          attemptJson.cast<String, dynamic>(),
        ),
        diff: decoded['diff'] as String? ?? '',
      );
    } on Object {
      return null;
    }
  }

  /// The recorded attempt with the replay stamps applied.
  EvaluationAttempt asReplay(
    EvaluationReplayRecording recording,
    EvaluationAttemptRequest request,
  ) {
    final recorded = recording.attempt;
    return EvaluationAttempt(
      attemptId: request.attemptId,
      taskId: request.task.id,
      taskKind: request.task.kind,
      armId: request.arm.id,
      effective: request.effective,
      stratum: request.stratum,
      repetition: request.repetition,
      seed: request.seed,
      ordinal: request.ordinal,
      startedAtEpochMs: DateTime.now().millisecondsSinceEpoch,
      executionMode: EvaluationExecutionMode.offlineReplay,
      resumedSession: recorded.resumedSession,
      sessionId: recorded.sessionId,
      servedModel: recorded.servedModel,
      servedEffort: recorded.servedEffort,
      completed: recorded.completed,
      error: recorded.error,
      tokens: recorded.tokens,
      cost: recorded.cost,
      latency: recorded.latency,
      metrics: recorded.metrics,
      toolEvents: recorded.toolEvents,
      verification: const [],
      filesTouched: const [],
      notes: 'offline replay of ${recorded.attemptId}',
    );
  }

  /// Applies the recording's diff to [workspaceRoot].
  ///
  /// Returns null on success or a human-readable failure, which becomes the
  /// attempt's error — a recording whose patch no longer applies is a genuine
  /// unknown, not a pass.
  Future<String?> restoreWorkspace({
    required EvaluationReplayRecording recording,
    required String workspaceRoot,
  }) async {
    if (recording.diff.trim().isEmpty) {
      return null;
    }
    final patch = File(
      p.join(
        Directory.systemTemp.path,
        'cc-eval-replay-${DateTime.now().microsecondsSinceEpoch}.patch',
      ),
    );
    try {
      await patch.writeAsString(
        recording.diff.endsWith('\n') ? recording.diff : '${recording.diff}\n',
      );
      final result = await Process.run('git', [
        '-C',
        workspaceRoot,
        'apply',
        '--binary',
        patch.path,
      ]);
      if (result.exitCode != 0) {
        return 'recorded patch does not apply: ${result.stderr}';
      }
      return null;
    } finally {
      if (patch.existsSync()) {
        patch.deleteSync();
      }
    }
  }

  /// A missing cassette, expressed as an honest error attempt.
  EvaluationAttempt missingRecording(EvaluationAttemptRequest request) =>
      EvaluationAttempt(
        attemptId: request.attemptId,
        taskId: request.task.id,
        taskKind: request.task.kind,
        armId: request.arm.id,
        effective: request.effective,
        stratum: request.stratum,
        repetition: request.repetition,
        seed: request.seed,
        ordinal: request.ordinal,
        startedAtEpochMs: DateTime.now().millisecondsSinceEpoch,
        executionMode: EvaluationExecutionMode.offlineReplay,
        completed: false,
        error:
            'no recording for attempt ${request.attemptId} in "$recordingsDir" '
            '— replay cannot invent one',
        verification: const [],
        notes: 'offline replay (missing recording)',
      );
}
