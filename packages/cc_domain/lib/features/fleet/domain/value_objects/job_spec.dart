import 'dart:convert';

import 'package:cc_domain/features/fleet/domain/value_objects/worker_capabilities.dart';

/// The kind of executable work a job represents (PRD 20 §2).
enum JobKind {
  /// A single agent run (dispatch).
  agentRun('agentRun'),

  /// A pipeline step execution.
  pipelineStep('pipelineStep'),

  /// A repo code-index build.
  codeIndex('codeIndex'),

  /// A PRD 18 UI visual golden render (requires `flutter`).
  goldenRender('goldenRender'),

  /// A performance benchmark run.
  benchmark('benchmark'),

  /// A PRD 21 eval batch (prefers `parallel` throwaway capacity).
  evalBatch('evalBatch');

  const JobKind(this.wire);

  /// Stable wire/storage string.
  final String wire;

  /// Parses a [JobKind] from its [wire] string.
  static JobKind fromWire(String value) => JobKind.values.firstWhere(
    (k) => k.wire == value,
    orElse: () => JobKind.agentRun,
  );
}

/// A typed, serializable specification of executable work (PRD 20 §2).
///
/// Everything executable becomes a `JobSpec`. The kind-specific payload lives
/// in the subtype; capability requirements/preferences and priority are carried
/// on the enclosing job row (so the scheduler never parses the payload). Each
/// spec exposes [defaultRequiredCaps]/[defaultPreferredCaps] the submitter uses
/// to seed those columns.
sealed class JobSpec {
  const JobSpec();

  /// Reconstructs the concrete spec for [kind] from its JSON payload.
  factory JobSpec.fromJson(JobKind kind, Map<String, dynamic> json) {
    switch (kind) {
      case JobKind.agentRun:
        return AgentRunJobSpec.fromJson(json);
      case JobKind.pipelineStep:
        return PipelineStepJobSpec.fromJson(json);
      case JobKind.codeIndex:
        return CodeIndexJobSpec.fromJson(json);
      case JobKind.goldenRender:
        return GoldenRenderJobSpec.fromJson(json);
      case JobKind.benchmark:
        return BenchmarkJobSpec.fromJson(json);
      case JobKind.evalBatch:
        return EvalBatchJobSpec.fromJson(json);
    }
  }

  /// Parses a spec from a `(kind, jsonString)` pair.
  factory JobSpec.fromJsonString(JobKind kind, String source) =>
      JobSpec.fromJson(
        kind,
        source.trim().isEmpty
            ? const {}
            : jsonDecode(source) as Map<String, dynamic>,
      );

  /// This spec's kind.
  JobKind get kind;

  /// The capability keys a worker MUST have to run this kind by default.
  Set<String> get defaultRequiredCaps => const {};

  /// The capability keys preferred (tie-breaker) for this kind by default.
  Set<String> get defaultPreferredCaps => const {};

  /// Serializes the kind-specific payload.
  Map<String, dynamic> toJson();

  /// Serializes the payload to a JSON string.
  String toJsonString() => jsonEncode(toJson());
}

/// A single agent run (PRD 20 §2).
class AgentRunJobSpec extends JobSpec {
  /// Creates an [AgentRunJobSpec].
  const AgentRunJobSpec({
    required this.agentId,
    this.conversationId,
    this.runLogId,
    this.prompt,
    this.mode,
    this.repoRemote,
    this.headSha,
    this.requestedByUserId,
    this.extraRequiredCaps = const {},
    this.extraPreferredCaps = const {},
  });

  /// Parses from JSON.
  factory AgentRunJobSpec.fromJson(Map<String, dynamic> json) =>
      AgentRunJobSpec(
        agentId: json['agentId'] as String? ?? '',
        conversationId: json['conversationId'] as String?,
        runLogId: json['runLogId'] as String?,
        prompt: json['prompt'] as String?,
        mode: json['mode'] as String?,
        repoRemote: json['repoRemote'] as String?,
        headSha: json['headSha'] as String?,
        requestedByUserId: json['requestedByUserId'] as String?,
        extraRequiredCaps: ((json['extraRequiredCaps'] as List?) ?? const [])
            .cast<String>()
            .toSet(),
        extraPreferredCaps: ((json['extraPreferredCaps'] as List?) ?? const [])
            .cast<String>()
            .toSet(),
      );

  /// The agent to run.
  final String agentId;

  /// The conversation (channel) the run belongs to.
  final String? conversationId;

  /// The run-log id to write under (if pre-allocated).
  final String? runLogId;

  /// The initial prompt.
  final String? prompt;

  /// The conversation mode (`chat`/`review`/`plan`).
  final String? mode;

  /// Canonical remote the worktree materializes from.
  final String? repoRemote;

  /// Pinned SHA to materialize at.
  final String? headSha;

  /// Principal on whose behalf the run executes.
  final String? requestedByUserId;

  /// Extra required capability keys beyond the kind default.
  final Set<String> extraRequiredCaps;

  /// Extra preferred capability keys beyond the kind default.
  final Set<String> extraPreferredCaps;

  @override
  JobKind get kind => JobKind.agentRun;

  @override
  Set<String> get defaultRequiredCaps => extraRequiredCaps;

  @override
  Set<String> get defaultPreferredCaps => extraPreferredCaps;

  @override
  Map<String, dynamic> toJson() => {
    'agentId': agentId,
    if (conversationId != null) 'conversationId': conversationId,
    if (runLogId != null) 'runLogId': runLogId,
    if (prompt != null) 'prompt': prompt,
    if (mode != null) 'mode': mode,
    if (repoRemote != null) 'repoRemote': repoRemote,
    if (headSha != null) 'headSha': headSha,
    if (requestedByUserId != null) 'requestedByUserId': requestedByUserId,
    if (extraRequiredCaps.isNotEmpty)
      'extraRequiredCaps': extraRequiredCaps.toList()..sort(),
    if (extraPreferredCaps.isNotEmpty)
      'extraPreferredCaps': extraPreferredCaps.toList()..sort(),
  };
}

/// A pipeline step execution (PRD 20 §2).
class PipelineStepJobSpec extends JobSpec {
  /// Creates a [PipelineStepJobSpec].
  const PipelineStepJobSpec({
    required this.pipelineRunId,
    required this.stepRunId,
    this.requiredCaps = const {},
  });

  /// Parses from JSON.
  factory PipelineStepJobSpec.fromJson(Map<String, dynamic> json) =>
      PipelineStepJobSpec(
        pipelineRunId: json['pipelineRunId'] as String? ?? '',
        stepRunId: json['stepRunId'] as String? ?? '',
        requiredCaps: ((json['requiredCaps'] as List?) ?? const [])
            .cast<String>()
            .toSet(),
      );

  /// The owning pipeline run.
  final String pipelineRunId;

  /// The step run to execute.
  final String stepRunId;

  /// Capability keys this step requires.
  final Set<String> requiredCaps;

  @override
  JobKind get kind => JobKind.pipelineStep;

  @override
  Set<String> get defaultRequiredCaps => requiredCaps;

  @override
  Map<String, dynamic> toJson() => {
    'pipelineRunId': pipelineRunId,
    'stepRunId': stepRunId,
    if (requiredCaps.isNotEmpty) 'requiredCaps': requiredCaps.toList()..sort(),
  };
}

/// A repo code-index build (PRD 20 §2).
class CodeIndexJobSpec extends JobSpec {
  /// Creates a [CodeIndexJobSpec].
  const CodeIndexJobSpec({required this.repoId, this.repoRemote, this.headSha});

  /// Parses from JSON.
  factory CodeIndexJobSpec.fromJson(Map<String, dynamic> json) =>
      CodeIndexJobSpec(
        repoId: json['repoId'] as String? ?? '',
        repoRemote: json['repoRemote'] as String?,
        headSha: json['headSha'] as String?,
      );

  /// The repo to index.
  final String repoId;

  /// Canonical remote to materialize from.
  final String? repoRemote;

  /// Pinned SHA to index at.
  final String? headSha;

  @override
  JobKind get kind => JobKind.codeIndex;

  @override
  Map<String, dynamic> toJson() => {
    'repoId': repoId,
    if (repoRemote != null) 'repoRemote': repoRemote,
    if (headSha != null) 'headSha': headSha,
  };
}

/// A PRD 18 UI visual golden render (PRD 20 §6 — requires `flutter`).
class GoldenRenderJobSpec extends JobSpec {
  /// Creates a [GoldenRenderJobSpec].
  const GoldenRenderJobSpec({
    required this.prNodeId,
    required this.repoId,
    this.repoRemote,
    this.headSha,
  });

  /// Parses from JSON.
  factory GoldenRenderJobSpec.fromJson(Map<String, dynamic> json) =>
      GoldenRenderJobSpec(
        prNodeId: json['prNodeId'] as String? ?? '',
        repoId: json['repoId'] as String? ?? '',
        repoRemote: json['repoRemote'] as String?,
        headSha: json['headSha'] as String?,
      );

  /// The PR being visually diffed.
  final String prNodeId;

  /// The repo whose components render.
  final String repoId;

  /// Canonical remote to materialize from.
  final String? repoRemote;

  /// Pinned SHA to render at.
  final String? headSha;

  @override
  JobKind get kind => JobKind.goldenRender;

  @override
  Set<String> get defaultRequiredCaps => const {FleetCaps.flutter};

  @override
  Map<String, dynamic> toJson() => {
    'prNodeId': prNodeId,
    'repoId': repoId,
    if (repoRemote != null) 'repoRemote': repoRemote,
    if (headSha != null) 'headSha': headSha,
  };
}

/// A performance benchmark run (PRD 20 §2).
class BenchmarkJobSpec extends JobSpec {
  /// Creates a [BenchmarkJobSpec].
  const BenchmarkJobSpec({required this.name, this.paramsJson = '{}'});

  /// Parses from JSON.
  factory BenchmarkJobSpec.fromJson(Map<String, dynamic> json) =>
      BenchmarkJobSpec(
        name: json['name'] as String? ?? '',
        paramsJson: json['paramsJson'] as String? ?? '{}',
      );

  /// Benchmark name.
  final String name;

  /// Opaque benchmark parameters JSON.
  final String paramsJson;

  @override
  JobKind get kind => JobKind.benchmark;

  @override
  Map<String, dynamic> toJson() => {'name': name, 'paramsJson': paramsJson};
}

/// A PRD 21 eval batch fanned out to parallel workers (PRD 20 §6).
class EvalBatchJobSpec extends JobSpec {
  /// Creates an [EvalBatchJobSpec].
  const EvalBatchJobSpec({
    required this.evalRunId,
    required this.suiteId,
    required this.configHash,
    this.repetitionIndex = 0,
  });

  /// Parses from JSON.
  factory EvalBatchJobSpec.fromJson(Map<String, dynamic> json) =>
      EvalBatchJobSpec(
        evalRunId: json['evalRunId'] as String? ?? '',
        suiteId: json['suiteId'] as String? ?? '',
        configHash: json['configHash'] as String? ?? '',
        repetitionIndex: (json['repetitionIndex'] as num?)?.toInt() ?? 0,
      );

  /// The parent eval run.
  final String evalRunId;

  /// The suite being evaluated.
  final String suiteId;

  /// The config hash under evaluation.
  final String configHash;

  /// Which repetition of the batch this shard is.
  final int repetitionIndex;

  @override
  JobKind get kind => JobKind.evalBatch;

  @override
  Set<String> get defaultPreferredCaps => const {FleetCaps.parallel};

  @override
  Map<String, dynamic> toJson() => {
    'evalRunId': evalRunId,
    'suiteId': suiteId,
    'configHash': configHash,
    'repetitionIndex': repetitionIndex,
  };
}
