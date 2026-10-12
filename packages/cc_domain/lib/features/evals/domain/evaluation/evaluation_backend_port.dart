import 'package:cc_domain/features/evals/domain/evaluation/evaluation_attempt.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_manifest.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_plan.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_task.dart';

/// Everything a backend needs to run one attempt.
///
/// The isolated workspace is created by the engine (so every adapter gets the
/// same fixture and teardown semantics) and passed in by [workspaceRoot].
class EvaluationAttemptRequest {
  /// Creates an [EvaluationAttemptRequest].
  const EvaluationAttemptRequest({
    required this.task,
    required this.arm,
    required this.effective,
    required this.manifest,
    required this.workspaceRoot,
    required this.stratum,
    required this.repetition,
    required this.seed,
    required this.ordinal,
    required this.attemptId,
    this.executionMode = EvaluationExecutionMode.live,
    this.replaySourceDir,
    this.outputDir,
    this.sessionId,
  });

  /// The corpus task.
  final EvaluationTask task;

  /// The arm being run.
  final EvaluationArm arm;

  /// The effective configuration for this attempt.
  final EvaluationEffectiveConfig effective;

  /// The pinned manifest (for provider/model/CLI identity).
  final EvaluationManifest manifest;

  /// Absolute path to the isolated workspace the agent may work in.
  final String workspaceRoot;

  /// Cache stratum this attempt belongs to.
  final CacheStratum stratum;

  /// Repetition index within (task, arm, stratum).
  final int repetition;

  /// The derived repeat seed. Adapters that support sampling pass it through;
  /// the built-in harness records it as its RNG seed for reproducibility.
  final int seed;

  /// Scheduled position in the randomized order.
  final int ordinal;

  /// The attempt id to stamp on the produced record.
  final String attemptId;

  /// Live or offline replay.
  final EvaluationExecutionMode executionMode;

  /// Where recorded attempts live (replay only).
  final String? replaySourceDir;

  /// Where the backend may write its own artifacts (transcripts, raw streams).
  final String? outputDir;

  /// A native session id to resume, when the arm resumes sessions.
  final String? sessionId;
}

/// What an adapter must implement to be an evaluation backend.
///
/// The contract is deliberately narrow: run one attempt in its workspace and
/// return a record whose [EvaluationAttempt.verification] is EMPTY. The engine
/// runs the independent behavioral verifiers afterwards, so a backend can
/// never mark its own run successful.
abstract interface class EvaluationBackendPort {
  /// Stable backend id (`builtin`, `claude-cli`, `replay`).
  String get id;

  /// Whether this backend calls a model. Offline replay returns false, which
  /// is what keeps a replay report distinguishable from a live one.
  bool get callsModel;

  /// Runs one attempt.
  Future<EvaluationAttempt> execute(EvaluationAttemptRequest request);

  /// Why this backend cannot actually execute [effective], or null when it can.
  ///
  /// This is the campaign's preflight: an arm whose experimental policy the
  /// backend cannot implement (a memory policy with no compactor, a snapshot
  /// arm on a text-only reader, a Claude-only feature on the builtin harness)
  /// must be REFUSED before anything is spent — never executed as the default
  /// and reported as if the policy had run.
  String? unsupportedReason(EvaluationEffectiveConfig effective);
}
