import 'package:cc_domain/features/evals/domain/evaluation/evaluation_arm_settings.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_manifest.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_outcome.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_task.dart';
import 'package:cc_domain/features/evals/domain/evaluation/task_route_policy.dart';

/// Whether a report came from live model executions or from replaying a
/// recorded campaign (HARNESS_RESEARCH §6: the offline mode exists only as a
/// clearly distinct deterministic verification, never as a stand-in for live
/// evaluation).
enum EvaluationExecutionMode {
  /// Real agent runs against real providers.
  live('live'),

  /// Deterministic re-verification of recorded attempts: no model is called,
  /// no new outcome is produced, and the report says so.
  offlineReplay('offline_replay');

  const EvaluationExecutionMode(this.wire);

  /// Stable wire string.
  final String wire;

  /// Parses a wire string, defaulting to [live].
  static EvaluationExecutionMode fromWire(String? raw) {
    for (final mode in values) {
      if (mode.wire == raw) {
        return mode;
      }
    }
    return EvaluationExecutionMode.live;
  }
}

/// Provider cache warmth when a trial ran (HARNESS_RESEARCH §6: "Separate
/// cold-start, warm-cache, and post-idle behavior").
enum CacheStratum {
  /// First run in a fresh account/cache.
  cold('cold'),

  /// A run whose prompt prefix was very likely already cached.
  warm('warm'),

  /// A run after an idle period long enough for provider caches to expire.
  postIdle('post_idle');

  const CacheStratum(this.wire);

  /// Stable wire string.
  final String wire;

  /// Parses a wire string, defaulting to [cold].
  static CacheStratum fromWire(String? raw) {
    for (final stratum in values) {
      if (stratum.wire == raw) {
        return stratum;
      }
    }
    return CacheStratum.cold;
  }

  /// Sentence-case label for reports.
  String get label => switch (this) {
    CacheStratum.cold => 'Cold start',
    CacheStratum.warm => 'Warm cache',
    CacheStratum.postIdle => 'Post-idle',
  };
}

/// The single dimension an [EvaluationArm] may deviate on.
enum EvaluationAxis {
  /// The pinned quality default — never deviates.
  baseline('baseline'),

  /// A different model id (4A/§6 routing).
  modelRouting('model_routing'),

  /// A different reasoning effort (report 4A).
  effortRouting('effort_routing'),

  /// A different context/memory policy (report 3D and 3G).
  memoryPolicy('memory_policy'),

  /// Fresh prompt reconstruction vs native session resume (report 4B).
  sessionContinuity('session_continuity'),

  /// MCP tool discovery caching on/off (report 4E).
  mcpDiscoveryCache('mcp_discovery_cache'),

  /// Serial waves vs work-conserving read-only overlap (report 3E).
  toolOverlap('tool_overlap'),

  /// Package exposure is the only deliberate difference between skill arms.
  skillIntervention('skill_intervention'),

  /// What a goal's completion claim is worth (`GoalVerificationMode`).
  goalVerification('goal_verification'),

  /// Whether the run has the `repl` script surface (`CodeModeSurface`).
  codeMode('code_mode');

  const EvaluationAxis(this.wire);

  /// Stable wire string.
  final String wire;

  /// Parses a wire string, defaulting to [baseline].
  static EvaluationAxis fromWire(String? raw) {
    for (final axis in values) {
      if (axis.wire == raw) {
        return axis;
      }
    }
    return EvaluationAxis.baseline;
  }

  /// Sentence-case label for reports.
  String get label => switch (this) {
    EvaluationAxis.baseline => 'Baseline (quality default)',
    EvaluationAxis.modelRouting => 'Model routing',
    EvaluationAxis.effortRouting => 'Effort routing',
    EvaluationAxis.memoryPolicy => 'Memory policy',
    EvaluationAxis.sessionContinuity => 'Session continuity',
    EvaluationAxis.mcpDiscoveryCache => 'MCP discovery cache',
    EvaluationAxis.toolOverlap => 'Tool overlap',
    EvaluationAxis.skillIntervention => 'Skill intervention',
    EvaluationAxis.goalVerification => 'Goal verification',
    EvaluationAxis.codeMode => 'Code mode',
  };
}

/// Which context-management policy an arm installs (report 3D: current vs
/// batched masking vs masking + structured summarization; report 3G: the
/// screenshot-based snapshot strategy as a separate experiment).
enum MemoryPolicyMode {
  /// Today's behaviour: drop empty/uneventful results, otherwise keep history.
  textCurrent('text_current'),

  /// Batched masking of stale observations with recoverable references.
  masking('masking'),

  /// Masking plus structured summarization at meaningful boundaries.
  hybridMaskingSummary('hybrid_masking_summary'),

  /// Screenshot-based text compaction (report 3G) — opt-in, fidelity-checked.
  snapshotImages('snapshot_images');

  const MemoryPolicyMode(this.wire);

  /// Stable wire string.
  final String wire;

  /// Parses a wire string, defaulting to [textCurrent].
  static MemoryPolicyMode fromWire(String? raw) {
    for (final mode in values) {
      if (mode.wire == raw) {
        return mode;
      }
    }
    return MemoryPolicyMode.textCurrent;
  }

  /// Whether this policy may discard an observation the model could still need.
  bool get rewritesHistory => this != MemoryPolicyMode.textCurrent;

  /// Sentence-case label for reports.
  String get label => switch (this) {
    MemoryPolicyMode.textCurrent => 'Current',
    MemoryPolicyMode.masking => 'Batched masking',
    MemoryPolicyMode.hybridMaskingSummary => 'Masking + summarization',
    MemoryPolicyMode.snapshotImages => 'Snapshot (images)',
  };
}

/// Whether follow-up turns reconstruct context or resume the native session
/// (report 4B).
enum SessionContinuityMode {
  /// The pre-existing behaviour: a new invocation carries a reconstructed
  /// conversation.
  fresh('fresh'),

  /// An explicit native session id is resumed and only the new turn is sent.
  nativeResume('native_resume'),

  /// Every turn after the first starts with no history, as a dispatch with
  /// `freshHistory` (a goal's `--fresh` segments): the turn's text and the
  /// workspace are all the run has.
  historyNone('history_none');

  const SessionContinuityMode(this.wire);

  /// Stable wire string.
  final String wire;

  /// Parses a wire string, defaulting to [fresh].
  static SessionContinuityMode fromWire(String? raw) {
    for (final mode in values) {
      if (mode.wire == raw) {
        return mode;
      }
    }
    return SessionContinuityMode.fresh;
  }
}

/// Whether Anthropic's MCP discovery cache is enabled (report 4E).
enum McpDiscoveryCacheMode {
  /// Detect the real configuration; cache nothing new.
  disabled('disabled'),

  /// Enable the discovery cache — only legitimate when tool availability and
  /// permissions are handled correctly.
  enabled('enabled');

  const McpDiscoveryCacheMode(this.wire);

  /// Stable wire string.
  final String wire;

  /// Parses a wire string, defaulting to [disabled].
  static McpDiscoveryCacheMode fromWire(String? raw) {
    for (final mode in values) {
      if (mode.wire == raw) {
        return mode;
      }
    }
    return McpDiscoveryCacheMode.disabled;
  }
}

/// Whether read-only tool calls may overlap with generation (report 3E).
enum ToolOverlapMode {
  /// Today's behaviour: calls run in bounded waves.
  serial('serial'),

  /// Work-conserving overlap of tools that declare themselves speculative-read
  /// safe. Opt-in only: barriers around mutations, dependencies, approvals and
  /// hooks stay in force.
  overlapReadOnly('overlap_read_only');

  const ToolOverlapMode(this.wire);

  /// Stable wire string.
  final String wire;

  /// Parses a wire string, defaulting to [serial].
  static ToolOverlapMode fromWire(String? raw) {
    for (final mode in values) {
      if (mode.wire == raw) {
        return mode;
      }
    }
    return ToolOverlapMode.serial;
  }
}

/// Requested target package exposure; the ambient inventory stays fixed.
enum SkillExposure {
  absent('absent'),
  available('available'),
  forced('forced');

  const SkillExposure(this.wire);
  final String wire;

  static SkillExposure fromWire(String raw) =>
      values.firstWhere((value) => value.wire == raw);
}

/// The configuration a trial actually ran under: the pinned manifest with one
/// arm's deliberate deviation applied.
class EvaluationEffectiveConfig {
  /// Creates an [EvaluationEffectiveConfig].
  const EvaluationEffectiveConfig({
    required this.adapter,
    required this.providerId,
    required this.modelId,
    this.effortLevel,
    this.memoryPolicy = MemoryPolicyMode.textCurrent,
    this.sessionContinuity = SessionContinuityMode.fresh,
    this.mcpDiscoveryCache = McpDiscoveryCacheMode.disabled,
    this.toolOverlap = ToolOverlapMode.serial,
    this.skillExposure,
    this.goalVerification,
    this.codeMode,
    this.cacheEnabled = true,
    this.toolDeferralEnabled = true,
  });

  /// Parses [toJson]'s output; an absent setting reads as its default.
  factory EvaluationEffectiveConfig.fromJson(Map<String, dynamic> json) =>
      EvaluationEffectiveConfig(
        adapter: json['adapter'] as String? ?? '',
        providerId: json['providerId'] as String? ?? '',
        modelId: json['modelId'] as String? ?? '',
        effortLevel: json['effortLevel'] as String?,
        memoryPolicy: MemoryPolicyMode.fromWire(
          json['memoryPolicy'] as String?,
        ),
        sessionContinuity: SessionContinuityMode.fromWire(
          json['sessionContinuity'] as String?,
        ),
        mcpDiscoveryCache: McpDiscoveryCacheMode.fromWire(
          json['mcpDiscoveryCache'] as String?,
        ),
        toolOverlap: ToolOverlapMode.fromWire(json['toolOverlap'] as String?),
        skillExposure: json['skillExposure'] == null
            ? null
            : SkillExposure.fromWire(json['skillExposure'] as String),
        goalVerification: json['goalVerification'] == null
            ? null
            : GoalVerificationMode.fromWire(json['goalVerification'] as String),
        codeMode: json['codeMode'] == null
            ? null
            : CodeModeSurface.fromWire(json['codeMode'] as String),
        cacheEnabled: json['cacheEnabled'] as bool? ?? true,
        toolDeferralEnabled: json['toolDeferralEnabled'] as bool? ?? true,
      );

  /// Builds the effective config for [arm] under [manifest].
  factory EvaluationEffectiveConfig.forArm(
    EvaluationManifest manifest,
    EvaluationArm arm,
  ) => EvaluationEffectiveConfig(
    adapter: manifest.adapter,
    providerId: manifest.providerId,
    modelId: arm.modelId ?? manifest.modelId,
    effortLevel: arm.effortLevel ?? manifest.effortLevel,
    memoryPolicy: arm.memoryPolicy ?? MemoryPolicyMode.textCurrent,
    sessionContinuity: arm.sessionContinuity ?? SessionContinuityMode.fresh,
    mcpDiscoveryCache: arm.mcpDiscoveryCache ?? McpDiscoveryCacheMode.disabled,
    toolOverlap: arm.toolOverlap ?? ToolOverlapMode.serial,
    skillExposure: arm.skillExposure,
    goalVerification: arm.goalVerification,
    codeMode: arm.codeMode,
    cacheEnabled: manifest.cacheEnabled,
    toolDeferralEnabled: manifest.toolDeferralEnabled,
  );

  /// Adapter under test.
  final String adapter;

  /// Provider id.
  final String providerId;

  /// Effective model id.
  final String modelId;

  /// Effective reasoning effort, or null when the adapter has none.
  final String? effortLevel;

  /// Effective context/memory policy.
  final MemoryPolicyMode memoryPolicy;

  /// Effective session continuity mode.
  final SessionContinuityMode sessionContinuity;

  /// Effective MCP discovery-cache mode.
  final McpDiscoveryCacheMode mcpDiscoveryCache;

  /// Effective tool-overlap mode (report 3E).
  final ToolOverlapMode toolOverlap;

  /// Target exposure, null outside skill comparisons.
  final SkillExposure? skillExposure;

  /// What a goal's claim is worth; null when the attempt is not a goal.
  final GoalVerificationMode? goalVerification;

  /// The `repl` surface; null leaves it to the campaign's script runner.
  final CodeModeSurface? codeMode;

  /// Whether provider prompt caching is requested.
  final bool cacheEnabled;

  /// Whether native tool-schema deferral is on.
  final bool toolDeferralEnabled;

  /// A compact human-readable identity used in report rows.
  String get label {
    final parts = <String>[
      modelId,
      if (effortLevel != null) 'effort=$effortLevel',
      'mem=${memoryPolicy.wire}',
      'session=${sessionContinuity.wire}',
      'mcpCache=${mcpDiscoveryCache.wire}',
      'overlap=${toolOverlap.wire}',
      if (skillExposure != null) 'skill=${skillExposure!.wire}',
      if (goalVerification != null) 'goal=${goalVerification!.wire}',
      if (codeMode != null) 'code=${codeMode!.wire}',
    ];
    return parts.join(' · ');
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'adapter': adapter,
    'providerId': providerId,
    'modelId': modelId,
    if (effortLevel != null) 'effortLevel': effortLevel,
    'memoryPolicy': memoryPolicy.wire,
    'sessionContinuity': sessionContinuity.wire,
    'mcpDiscoveryCache': mcpDiscoveryCache.wire,
    'toolOverlap': toolOverlap.wire,
    if (skillExposure != null) 'skillExposure': skillExposure!.wire,
    if (goalVerification != null) 'goalVerification': goalVerification!.wire,
    if (codeMode != null) 'codeMode': codeMode!.wire,
    'cacheEnabled': cacheEnabled,
    'toolDeferralEnabled': toolDeferralEnabled,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EvaluationEffectiveConfig &&
          adapter == other.adapter &&
          providerId == other.providerId &&
          modelId == other.modelId &&
          effortLevel == other.effortLevel &&
          memoryPolicy == other.memoryPolicy &&
          sessionContinuity == other.sessionContinuity &&
          mcpDiscoveryCache == other.mcpDiscoveryCache &&
          toolOverlap == other.toolOverlap &&
          skillExposure == other.skillExposure &&
          goalVerification == other.goalVerification &&
          codeMode == other.codeMode &&
          cacheEnabled == other.cacheEnabled &&
          toolDeferralEnabled == other.toolDeferralEnabled;

  @override
  int get hashCode => Object.hash(
    adapter,
    providerId,
    modelId,
    effortLevel,
    memoryPolicy,
    sessionContinuity,
    mcpDiscoveryCache,
    toolOverlap,
    skillExposure,
    goalVerification,
    codeMode,
    cacheEnabled,
    toolDeferralEnabled,
  );
}

/// One arm of a paired comparison. Exactly one axis may deviate from the
/// pinned quality default.
class EvaluationArm {
  /// Creates an [EvaluationArm].
  const EvaluationArm({
    required this.id,
    required this.axis,
    this.label = '',
    this.modelId,
    this.effortLevel,
    this.memoryPolicy,
    this.sessionContinuity,
    this.mcpDiscoveryCache,
    this.toolOverlap,
    this.skillExposure,
    this.taskRoutePolicyId,
    this.goalVerification,
    this.codeMode,
  });

  /// Parses from JSON.
  factory EvaluationArm.fromJson(Map<String, dynamic> json) => EvaluationArm(
    id: json['id'] as String? ?? '',
    axis: EvaluationAxis.fromWire(json['axis'] as String?),
    label: json['label'] as String? ?? '',
    modelId: json['modelId'] as String?,
    effortLevel: json['effortLevel'] as String?,
    memoryPolicy: json['memoryPolicy'] == null
        ? null
        : MemoryPolicyMode.fromWire(json['memoryPolicy'] as String?),
    sessionContinuity: json['sessionContinuity'] == null
        ? null
        : SessionContinuityMode.fromWire(json['sessionContinuity'] as String?),
    mcpDiscoveryCache: json['mcpDiscoveryCache'] == null
        ? null
        : McpDiscoveryCacheMode.fromWire(json['mcpDiscoveryCache'] as String?),
    toolOverlap: json['toolOverlap'] == null
        ? null
        : ToolOverlapMode.fromWire(json['toolOverlap'] as String?),
    skillExposure: json['skillExposure'] == null
        ? null
        : SkillExposure.fromWire(json['skillExposure'] as String),
    taskRoutePolicyId: json['taskRoutePolicyId'] as String?,
    goalVerification: json['goalVerification'] == null
        ? null
        : GoalVerificationMode.fromWire(json['goalVerification'] as String),
    codeMode: json['codeMode'] == null
        ? null
        : CodeModeSurface.fromWire(json['codeMode'] as String),
  );

  /// Stable arm id (unique within a plan).
  final String id;

  /// The one dimension this arm deviates on.
  final EvaluationAxis axis;

  /// Human-readable label for reports.
  final String label;

  /// Model override.
  final String? modelId;

  /// Effort override.
  final String? effortLevel;

  /// Memory-policy override.
  final MemoryPolicyMode? memoryPolicy;

  /// Session-continuity override.
  final SessionContinuityMode? sessionContinuity;

  /// MCP discovery-cache override.
  final McpDiscoveryCacheMode? mcpDiscoveryCache;

  /// Tool-overlap override (report 3E).
  final ToolOverlapMode? toolOverlap;

  /// Target package exposure for this arm.
  final SkillExposure? skillExposure;

  /// Links this arm to the routing policy that produced its overrides, when
  /// the arm was generated from a policy rather than declared by hand.
  final String? taskRoutePolicyId;

  /// Goal verification override.
  final GoalVerificationMode? goalVerification;

  /// `repl` surface override.
  final CodeModeSurface? codeMode;

  /// Whether this arm is the pinned quality default (the baseline).
  ///
  /// A baseline arm carries no overrides at all; that is what makes it the
  /// default every treatment must beat without losing quality.
  bool get isBaseline =>
      axis == EvaluationAxis.baseline &&
      modelId == null &&
      effortLevel == null &&
      memoryPolicy == null &&
      sessionContinuity == null &&
      mcpDiscoveryCache == null &&
      toolOverlap == null &&
      (skillExposure == null ||
          skillExposure == SkillExposure.absent ||
          skillExposure == SkillExposure.available) &&
      (goalVerification == null ||
          goalVerification == GoalVerificationMode.claimOnly) &&
      (codeMode == null || codeMode == CodeModeSurface.repl);

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'id': id,
    'axis': axis.wire,
    if (label.isNotEmpty) 'label': label,
    if (modelId != null) 'modelId': modelId,
    if (effortLevel != null) 'effortLevel': effortLevel,
    if (memoryPolicy != null) 'memoryPolicy': memoryPolicy!.wire,
    if (sessionContinuity != null) 'sessionContinuity': sessionContinuity!.wire,
    if (mcpDiscoveryCache != null) 'mcpDiscoveryCache': mcpDiscoveryCache!.wire,
    if (toolOverlap != null) 'toolOverlap': toolOverlap!.wire,
    if (skillExposure != null) 'skillExposure': skillExposure!.wire,
    if (taskRoutePolicyId != null) 'taskRoutePolicyId': taskRoutePolicyId,
    if (goalVerification != null) 'goalVerification': goalVerification!.wire,
    if (codeMode != null) 'codeMode': codeMode!.wire,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EvaluationArm &&
          id == other.id &&
          axis == other.axis &&
          label == other.label &&
          modelId == other.modelId &&
          effortLevel == other.effortLevel &&
          memoryPolicy == other.memoryPolicy &&
          sessionContinuity == other.sessionContinuity &&
          mcpDiscoveryCache == other.mcpDiscoveryCache &&
          toolOverlap == other.toolOverlap &&
          skillExposure == other.skillExposure &&
          taskRoutePolicyId == other.taskRoutePolicyId &&
          goalVerification == other.goalVerification &&
          codeMode == other.codeMode;

  @override
  int get hashCode => Object.hash(
    id,
    axis,
    label,
    modelId,
    effortLevel,
    memoryPolicy,
    sessionContinuity,
    mcpDiscoveryCache,
    toolOverlap,
    skillExposure,
    taskRoutePolicyId,
    goalVerification,
    codeMode,
  );
}

/// The controlled memory-policy experiment (report 3D + 3G).
///
/// A policy that rewrites history must keep the originals recoverable; the
/// screenshot strategy additionally needs an explicit fidelity check before it
/// may be considered at all ("Require explicit fidelity and recovery
/// evaluations before expanding this strategy").
class MemoryPolicyExperiment {
  /// Creates a [MemoryPolicyExperiment].
  const MemoryPolicyExperiment({
    required this.id,
    this.enabled = false,
    required this.modes,
    this.requireRecoverableReferences = true,
    this.requireSnapshotFidelityCheck = true,
    this.fidelityVerifiers = const [],
    this.notes = '',
  });

  /// Parses from JSON.
  factory MemoryPolicyExperiment.fromJson(Map<String, dynamic> json) =>
      MemoryPolicyExperiment(
        id: json['id'] as String? ?? '',
        enabled: json['enabled'] as bool? ?? false,
        modes: [
          for (final mode in (json['modes'] as List?) ?? const [])
            MemoryPolicyMode.fromWire(mode as String?),
        ],
        requireRecoverableReferences:
            json['requireRecoverableReferences'] as bool? ?? true,
        requireSnapshotFidelityCheck:
            json['requireSnapshotFidelityCheck'] as bool? ?? true,
        fidelityVerifiers:
            (json['fidelityVerifiers'] as List?)
                ?.map(
                  (e) => EvaluationVerifier.fromJson(
                    (e as Map).cast<String, dynamic>(),
                  ),
                )
                .toList() ??
            const [],
        notes: json['notes'] as String? ?? '',
      );

  /// Stable experiment id.
  final String id;

  /// Explicit opt-in. Defaults to false — the conservative text default stays
  /// in force until an operator asks for the experiment.
  final bool enabled;

  /// The policies under test: one arm each, every one paired against the
  /// baseline in the same campaign.
  final List<MemoryPolicyMode> modes;

  /// Whether masked observations must remain recoverable through a reference.
  final bool requireRecoverableReferences;

  /// Whether the screenshot strategy must carry its own fidelity verifiers.
  final bool requireSnapshotFidelityCheck;

  /// Deterministic checks that the surviving text still carries the facts the
  /// task needs (the fidelity guard for report 3G).
  final List<EvaluationVerifier> fidelityVerifiers;

  /// Operator notes.
  final String notes;

  /// Every way this experiment is not yet safe to enable.
  List<String> violations() {
    final problems = <String>[];
    if (!enabled) {
      return problems;
    }
    if (modes.isEmpty) {
      problems.add('experiment "$id" names no memory policy');
    }
    if (modes.any((m) => m.rewritesHistory) && !requireRecoverableReferences) {
      problems.add(
        'experiment "$id" rewrites history with no recoverable references',
      );
    }
    if (modes.contains(MemoryPolicyMode.snapshotImages)) {
      if (!requireSnapshotFidelityCheck) {
        problems.add(
          'experiment "$id" enables screenshot compaction without a fidelity '
          'check (report 3G)',
        );
      }
      if (fidelityVerifiers.isEmpty) {
        problems.add(
          'experiment "$id" enables screenshot compaction with no fidelity '
          'verifiers',
        );
      }
    }
    return problems;
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'id': id,
    'enabled': enabled,
    'modes': [for (final mode in modes) mode.wire],
    'requireRecoverableReferences': requireRecoverableReferences,
    'requireSnapshotFidelityCheck': requireSnapshotFidelityCheck,
    if (fidelityVerifiers.isNotEmpty)
      'fidelityVerifiers': [for (final v in fidelityVerifiers) v.toJson()],
    if (notes.isNotEmpty) 'notes': notes,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MemoryPolicyExperiment &&
          id == other.id &&
          enabled == other.enabled &&
          _listEq(modes, other.modes) &&
          requireRecoverableReferences == other.requireRecoverableReferences &&
          requireSnapshotFidelityCheck == other.requireSnapshotFidelityCheck &&
          notes == other.notes &&
          _listEq(fidelityVerifiers, other.fidelityVerifiers);

  @override
  int get hashCode => Object.hash(
    id,
    enabled,
    Object.hashAll(modes),
    requireRecoverableReferences,
    requireSnapshotFidelityCheck,
    notes,
    Object.hashAll(fidelityVerifiers),
  );
}

/// The controlled tool-scheduling experiment (report 3E).
///
/// Opt-in only, and only for tools that opt in individually: the overlap mode
/// must never remove a barrier around a mutation, a dependency, an approval or
/// a hook. [requiresBarrierCoverage] records that the campaign's corpus
/// contains a barrier task, so an overlap arm cannot be enabled from a corpus
/// that would never exercise the safety property.
class ToolOverlapExperiment {
  /// Creates a [ToolOverlapExperiment].
  const ToolOverlapExperiment({
    required this.id,
    this.enabled = false,
    required this.mode,
    this.maxParallel = 4,
    this.requiresBarrierCoverage = true,
    this.notes = '',
  });

  /// Parses from JSON.
  factory ToolOverlapExperiment.fromJson(Map<String, dynamic> json) =>
      ToolOverlapExperiment(
        id: json['id'] as String? ?? '',
        enabled: json['enabled'] as bool? ?? false,
        mode: ToolOverlapMode.fromWire(json['mode'] as String?),
        maxParallel: (json['maxParallel'] as num?)?.toInt() ?? 4,
        requiresBarrierCoverage:
            json['requiresBarrierCoverage'] as bool? ?? true,
        notes: json['notes'] as String? ?? '',
      );

  /// Stable experiment id.
  final String id;

  /// Explicit opt-in. Defaults to false.
  final bool enabled;

  /// The scheduling mode under test.
  final ToolOverlapMode mode;

  /// The wave/queue width.
  final int maxParallel;

  /// Whether the corpus must contain a task tagged `barrier` so the overlap arm
  /// is measured against the property it could break.
  final bool requiresBarrierCoverage;

  /// Operator notes.
  final String notes;

  /// Every way this experiment is not yet safe to enable.
  List<String> violations(List<EvaluationTask> tasks) {
    final problems = <String>[];
    if (!enabled) {
      return problems;
    }
    if (maxParallel < 1) {
      problems.add('experiment "$id" has maxParallel < 1');
    }
    if (requiresBarrierCoverage &&
        !tasks.any((t) => t.tags.contains('barrier'))) {
      problems.add(
        'experiment "$id" enables tool overlap with no "barrier" task in the '
        'corpus, so the mutation/dependency barrier is never exercised',
      );
    }
    return problems;
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'id': id,
    'enabled': enabled,
    'mode': mode.wire,
    'maxParallel': maxParallel,
    'requiresBarrierCoverage': requiresBarrierCoverage,
    if (notes.isNotEmpty) 'notes': notes,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ToolOverlapExperiment &&
          id == other.id &&
          enabled == other.enabled &&
          mode == other.mode &&
          maxParallel == other.maxParallel &&
          requiresBarrierCoverage == other.requiresBarrierCoverage &&
          notes == other.notes;

  @override
  int get hashCode => Object.hash(
    id,
    enabled,
    mode,
    maxParallel,
    requiresBarrierCoverage,
    notes,
  );
}

/// One cache-stratum bucket in a plan.
class StratumSpec {
  /// Creates a [StratumSpec].
  const StratumSpec({
    required this.stratum,
    this.repetitions = 1,
    this.idleFor,
  });

  /// Parses from JSON.
  factory StratumSpec.fromJson(Map<String, dynamic> json) => StratumSpec(
    stratum: CacheStratum.fromWire(json['stratum'] as String?),
    repetitions: (json['repetitions'] as num?)?.toInt() ?? 1,
    idleFor: json['idleMinutes'] == null
        ? null
        : Duration(minutes: (json['idleMinutes'] as num).toInt()),
  );

  /// Which stratum this bucket is.
  final CacheStratum stratum;

  /// How many paired repetitions to run in this bucket.
  final int repetitions;

  /// How long to idle before the bucket (post-idle only).
  final Duration? idleFor;

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'stratum': stratum.wire,
    'repetitions': repetitions,
    if (idleFor != null) 'idleMinutes': idleFor!.inMinutes,
  };
}

/// A recorded caveat about the campaign (account/cache conditions that make a
/// comparison less clean than it looks).
class EvaluationCaveat {
  /// Creates an [EvaluationCaveat].
  const EvaluationCaveat({required this.code, required this.message});

  /// Parses from JSON.
  factory EvaluationCaveat.fromJson(Map<String, dynamic> json) =>
      EvaluationCaveat(
        code: json['code'] as String? ?? '',
        message: json['message'] as String? ?? '',
      );

  /// Stable code (e.g. `shared_account`).
  final String code;

  /// Human-readable detail.
  final String message;

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {'code': code, 'message': message};

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EvaluationCaveat &&
          code == other.code &&
          message == other.message;

  @override
  int get hashCode => Object.hash(code, message);
}

/// The reproducible campaign plan: corpus tasks × arms × strata × repetitions,
/// with a seeded, randomized execution order (HARNESS_RESEARCH §6: "Use paired
/// runs and repeated trials… Randomize execution order and account for
/// provider-cache carryover").
class EvaluationPlan {
  /// Creates an [EvaluationPlan].
  const EvaluationPlan({
    required this.id,
    required this.hypothesis,
    required this.primaryOutcome,
    required this.minTasks,
    this.seed = 1,
    this.arms = const [],
    this.strata = const [
      StratumSpec(stratum: CacheStratum.cold, repetitions: 1),
      StratumSpec(stratum: CacheStratum.warm, repetitions: 1),
    ],
    this.randomizedOrder = true,
    this.alpha = 0.05,
    this.nonInferiorityMargin,
    this.interimAtTasks,
    this.maxCostRatio = 1.0,
    this.maxSpendUsd,
    this.contextWindowTokens,
    this.caveats = const [],
    this.routePolicy,
    this.memoryExperiment,
    this.overlapExperiment,
    this.taskTags = const [],
    this.notes = '',
  });

  /// Parses from JSON. Throws [FormatException] when the plan does not say
  /// what it asks (`hypothesis`, `primaryOutcome`); a missing `minTasks`
  /// loads as null and is a violation.
  factory EvaluationPlan.fromJson(Map<String, dynamic> json) => EvaluationPlan(
    id: json['id'] as String? ?? '',
    hypothesis: EvaluationHypothesis.fromWire(json['hypothesis'] as String?),
    primaryOutcome: EvaluationOutcomeMeasure.fromWire(
      json['primaryOutcome'] as String?,
    ),
    minTasks: (json['minTasks'] as num?)?.toInt(),
    seed: (json['seed'] as num?)?.toInt() ?? 1,
    arms:
        (json['arms'] as List?)
            ?.map(
              (e) => EvaluationArm.fromJson((e as Map).cast<String, dynamic>()),
            )
            .toList() ??
        const [],
    strata:
        (json['strata'] as List?)
            ?.map(
              (e) => StratumSpec.fromJson((e as Map).cast<String, dynamic>()),
            )
            .toList() ??
        const [
          StratumSpec(stratum: CacheStratum.cold, repetitions: 1),
          StratumSpec(stratum: CacheStratum.warm, repetitions: 1),
        ],
    randomizedOrder: json['randomizedOrder'] as bool? ?? true,
    alpha: (json['alpha'] as num?)?.toDouble() ?? 0.05,
    nonInferiorityMargin: (json['nonInferiorityMargin'] as num?)?.toDouble(),
    interimAtTasks: (json['interimAtTasks'] as num?)?.toInt(),
    maxCostRatio: (json['maxCostRatio'] as num?)?.toDouble() ?? 1.0,
    maxSpendUsd: (json['maxSpendUsd'] as num?)?.toDouble(),
    contextWindowTokens: (json['contextWindowTokens'] as num?)?.toInt(),
    caveats:
        (json['caveats'] as List?)
            ?.map(
              (e) =>
                  EvaluationCaveat.fromJson((e as Map).cast<String, dynamic>()),
            )
            .toList() ??
        const [],
    routePolicy: json['routePolicy'] == null
        ? null
        : TaskRoutePolicy.fromJson(
            (json['routePolicy'] as Map).cast<String, dynamic>(),
          ),
    memoryExperiment: json['memoryExperiment'] == null
        ? null
        : MemoryPolicyExperiment.fromJson(
            (json['memoryExperiment'] as Map).cast<String, dynamic>(),
          ),
    overlapExperiment: json['overlapExperiment'] == null
        ? null
        : ToolOverlapExperiment.fromJson(
            (json['overlapExperiment'] as Map).cast<String, dynamic>(),
          ),
    taskTags: [
      for (final tag in (json['taskTags'] as List?) ?? const []) '$tag',
    ],
    notes: json['notes'] as String? ?? '',
  );

  /// Stable plan id.
  final String id;

  /// The campaign seed. Every schedule and every per-trial repeat seed is
  /// derived from it, so a plan reproduces exactly.
  final int seed;

  /// The arms to compare. Order is ignored when [randomizedOrder] is true.
  final List<EvaluationArm> arms;

  /// The cache strata and their repetition counts.
  final List<StratumSpec> strata;

  /// Whether to shuffle the task order and each task's arm order.
  final bool randomizedOrder;

  /// What the plan asks of each treatment arm.
  final EvaluationHypothesis hypothesis;

  /// What each attempt is scored on.
  final EvaluationOutcomeMeasure primaryOutcome;

  /// Complete task blocks (both arms, every repetition scored) required
  /// before any verdict but "no decision": at least 10 for superiority and
  /// non-inferiority, at least 3 for a regression screen, none for a
  /// calibration plan.
  final int? minTasks;

  /// One-sided significance level per claim (Holm-adjusted across the
  /// plan's treatment arms).
  final double alpha;

  /// The loss a non-inferiority plan tolerates, in absolute points of the
  /// primary outcome's rate (`0.15` = 15 percentage points). Set exactly
  /// when the hypothesis is non-inferiority.
  final double? nonInferiorityMargin;

  /// The task blocks after which one interim look runs: the campaign stops
  /// early only when a superiority or inferiority claim has a one-sided p
  /// below 0.001. Null runs to the planned size.
  final int? interimAtTasks;

  /// The largest acceptable ratio of treatment cost to baseline cost for an
  /// adoption recommendation, over the used task blocks. May exceed 1 for a
  /// superiority plan; a non-inferiority adoption needs a ratio below 1.
  final double maxCostRatio;

  /// The plan's own spend ceiling in USD, when its owner set one: a live run
  /// is held to the lower of this and `--max-spend-usd`.
  final double? maxSpendUsd;

  /// Whether a stratum waits for the provider cache to expire, which keeps
  /// the global (unblocked) order.
  bool get hasPostIdleStratum =>
      strata.any((s) => s.stratum == CacheStratum.postIdle);

  /// The context window (tokens) an experimental context-management arm runs
  /// with.
  ///
  /// Required for any arm that rewrites history: the loop only compacts when it
  /// knows the window, so an arm without one would exercise nothing while
  /// claiming a policy.
  final int? contextWindowTokens;

  /// Account/cache caveats recorded with the report.
  final List<EvaluationCaveat> caveats;

  /// The opt-in task-boundary routing policy, if any.
  final TaskRoutePolicy? routePolicy;

  /// The opt-in memory-policy experiment, if any.
  final MemoryPolicyExperiment? memoryExperiment;

  /// The opt-in tool-overlap experiment, if any.
  final ToolOverlapExperiment? overlapExperiment;

  /// The campaign's task set: the corpus tasks carrying any of these tags.
  /// Empty runs the whole corpus.
  final List<String> taskTags;

  /// Operator notes.
  final String notes;

  /// The tasks this plan runs, in corpus order.
  List<EvaluationTask> selectTasks(List<EvaluationTask> tasks) => [
    for (final task in tasks)
      if (taskTags.isEmpty || task.tags.any(taskTags.contains)) task,
  ];

  /// The baseline arm (the pinned quality default).
  EvaluationArm? get baselineArm {
    for (final arm in arms) {
      if (arm.isBaseline) {
        return arm;
      }
    }
    return null;
  }

  /// Every reason the plan itself is not safe to execute.
  ///
  /// Reuses the route-policy and memory-experiment validators so a plan that
  /// would silently replace the user-selected quality default cannot run.
  List<String> violations(List<EvaluationTask> tasks) {
    final memory = memoryExperiment;
    final overlap = overlapExperiment;
    final route = routePolicy;
    final problems = <String>[
      ...?route?.violations(tasks: tasks, arms: arms),
      ...?memory?.violations(),
      ...?overlap?.violations(tasks),
    ];
    problems.addAll(_decisionViolations(tasks));
    if (baselineArm == null) {
      problems.add('plan "$id" has no baseline (quality default) arm');
    }
    if (arms.where((a) => a.isBaseline).length > 1) {
      problems.add('plan "$id" declares more than one baseline arm');
    }
    final seen = <String>{};
    for (final arm in arms) {
      if (!seen.add(arm.id)) {
        problems.add('plan "$id" has a duplicate arm id "${arm.id}"');
      }
      if (arm.axis == EvaluationAxis.skillIntervention &&
          (arm.skillExposure == null ||
              arm.skillExposure == SkillExposure.absent)) {
        problems.add('arm "${arm.id}" must expose the target skill');
      }
      if (arm.axis != EvaluationAxis.skillIntervention &&
          arm.axis != EvaluationAxis.baseline &&
          arm.skillExposure != null) {
        problems.add('arm "${arm.id}" changes skill exposure on another axis');
      }
      if (arm.axis == EvaluationAxis.skillIntervention &&
          (arm.modelId != null ||
              arm.effortLevel != null ||
              arm.memoryPolicy != null ||
              arm.sessionContinuity != null ||
              arm.mcpDiscoveryCache != null ||
              arm.toolOverlap != null ||
              arm.taskRoutePolicyId != null)) {
        problems.add('arm "${arm.id}" mixes skill exposure with another axis');
      }
      final runAxes = {
        if (arm.goalVerification != null) EvaluationAxis.goalVerification,
        if (arm.codeMode != null) EvaluationAxis.codeMode,
      };
      if (arm.axis != EvaluationAxis.baseline &&
          runAxes.any((axis) => axis != arm.axis)) {
        final other = runAxes.firstWhere((axis) => axis != arm.axis);
        problems.add('arm "${arm.id}" sets ${other.wire} off its axis');
      }
      if ((arm.axis == EvaluationAxis.goalVerification &&
              arm.goalVerification != GoalVerificationMode.checksReview) ||
          (arm.axis == EvaluationAxis.codeMode &&
              arm.codeMode != CodeModeSurface.withoutRepl)) {
        problems.add('arm "${arm.id}" does not deviate on ${arm.axis.wire}');
      }
      if (runAxes.contains(arm.axis) &&
          (arm.modelId != null ||
              arm.effortLevel != null ||
              arm.memoryPolicy != null ||
              arm.sessionContinuity != null ||
              arm.mcpDiscoveryCache != null ||
              arm.toolOverlap != null ||
              arm.skillExposure != null ||
              arm.taskRoutePolicyId != null)) {
        problems.add(
          'arm "${arm.id}" mixes ${arm.axis.wire} with another axis',
        );
      }
    }
    for (final spec in strata) {
      if (spec.repetitions < 1) {
        problems.add(
          'plan "$id" stratum ${spec.stratum.wire} has no repetitions',
        );
      }
      if (spec.stratum == CacheStratum.postIdle &&
          (spec.idleFor == null || spec.idleFor! <= Duration.zero)) {
        problems.add(
          'plan "$id" post-idle stratum needs a positive idle duration',
        );
      }
    }
    // A context-management arm needs a window, or the loop never compacts and
    // the arm measures nothing while claiming a policy.
    for (final arm in arms) {
      final rewrites =
          arm.memoryPolicy != null &&
          arm.memoryPolicy != MemoryPolicyMode.textCurrent;
      if (rewrites &&
          (contextWindowTokens == null || contextWindowTokens! <= 0)) {
        problems.add(
          'arm "${arm.id}" rewrites history but the plan declares no positive '
          'contextWindowTokens, so no compaction could run',
        );
      }
    }
    // An experiment must be opt-in AND actually applied by an arm, and an arm
    // must not apply a policy/experiment that was never declared: either way
    // the deviation would be unattributed, which is exactly how a routing
    // change becomes invisible.
    for (final arm in arms) {
      if (arm.taskRoutePolicyId != null &&
          arm.taskRoutePolicyId != routePolicy?.id) {
        problems.add(
          'arm "${arm.id}" references routing policy '
          '"${arm.taskRoutePolicyId}" which the plan does not declare',
        );
      }
      if (arm.memoryPolicy != null &&
          arm.memoryPolicy != MemoryPolicyMode.textCurrent &&
          (memory == null || !memory.modes.contains(arm.memoryPolicy))) {
        problems.add(
          'arm "${arm.id}" sets memory policy ${arm.memoryPolicy!.wire} '
          'without a matching enabled memory experiment (opt-in required)',
        );
      }
      if (arm.toolOverlap != null &&
          arm.toolOverlap != ToolOverlapMode.serial &&
          (overlap == null || overlap.mode != arm.toolOverlap)) {
        problems.add(
          'arm "${arm.id}" sets tool overlap ${arm.toolOverlap!.wire} without '
          'a matching enabled overlap experiment (opt-in required)',
        );
      }
    }
    if (overlap != null &&
        overlap.enabled &&
        !arms.any((a) => a.toolOverlap == overlap.mode)) {
      problems.add(
        'overlap experiment "${overlap.id}" is opted in but no arm '
        'uses ${overlap.mode.wire}',
      );
    }
    if (route != null &&
        route.enabled &&
        !arms.any((a) => a.taskRoutePolicyId == route.id)) {
      problems.add(
        'routing policy "${route.id}" is opted in but no arm applies it',
      );
    }
    for (final mode in memory?.modes ?? const <MemoryPolicyMode>[]) {
      if (memory!.enabled && !arms.any((a) => a.memoryPolicy == mode)) {
        problems.add(
          'memory experiment "${memory.id}" is opted in but no arm '
          'uses ${mode.wire}',
        );
      }
    }
    if (taskTags.isNotEmpty && selectTasks(tasks).isEmpty) {
      problems.add('plan "$id" selects no task tagged ${taskTags.join('/')}');
    }
    return problems;
  }

  /// What the plan's decision fields allow, by hypothesis.
  List<String> _decisionViolations(List<EvaluationTask> tasks) {
    final problems = <String>[];
    final calibration = hypothesis == EvaluationHypothesis.calibration;
    if (calibration) {
      if (arms.length != 1) {
        problems.add('calibration plan "$id" runs exactly one arm');
      }
      if (minTasks != null || interimAtTasks != null) {
        problems.add(
          'calibration plan "$id" reaches no verdict: it takes no minTasks '
          'and no interimAtTasks',
        );
      }
    } else if (arms.length < 2) {
      problems.add('plan "$id" needs at least two arms to pair');
    }
    final floor = switch (hypothesis) {
      EvaluationHypothesis.superiority ||
      EvaluationHypothesis.nonInferiority => 10,
      EvaluationHypothesis.regressionScreen => 3,
      EvaluationHypothesis.calibration => null,
    };
    if (floor != null && (minTasks == null || minTasks! < floor)) {
      problems.add(
        'plan "$id" minTasks must be at least $floor for ${hypothesis.wire}',
      );
    }
    final margin = nonInferiorityMargin;
    if (hypothesis == EvaluationHypothesis.nonInferiority) {
      if (margin == null || !margin.isFinite || margin <= 0 || margin > 0.5) {
        problems.add(
          'plan "$id" nonInferiorityMargin must be in (0, 0.5] absolute '
          'points for non_inferiority',
        );
      }
      if (maxCostRatio > 1) {
        problems.add(
          'plan "$id" maxCostRatio above 1 cannot support a non-inferiority '
          'adoption, which needs a saving',
        );
      }
    } else if (margin != null) {
      problems.add(
        'plan "$id" sets nonInferiorityMargin without the non_inferiority '
        'hypothesis',
      );
    }
    final interim = interimAtTasks;
    if (interim != null) {
      final planned = selectTasks(tasks).length;
      if (hypothesis != EvaluationHypothesis.superiority &&
          hypothesis != EvaluationHypothesis.nonInferiority) {
        problems.add('plan "$id" interimAtTasks needs a comparison plan');
      } else if (hasPostIdleStratum) {
        problems.add(
          'plan "$id" has a post-idle stratum, which is analysed only when '
          'complete: it takes no interimAtTasks',
        );
      } else if (interim < (minTasks ?? 0) || interim >= planned) {
        problems.add(
          'plan "$id" interimAtTasks must be at least minTasks and below the '
          '$planned planned task(s)',
        );
      }
    }
    if (alpha <= 0 || alpha >= 1 || !alpha.isFinite) {
      problems.add('plan "$id" alpha must be between 0 and 1');
    }
    if (!maxCostRatio.isFinite || maxCostRatio <= 0) {
      problems.add('plan "$id" maxCostRatio must be positive');
    }
    final spend = maxSpendUsd;
    if (spend != null && (!spend.isFinite || spend <= 0)) {
      problems.add('plan "$id" maxSpendUsd must be positive');
    }
    return problems;
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'id': id,
    'seed': seed,
    'hypothesis': hypothesis.wire,
    'primaryOutcome': primaryOutcome.wire,
    'minTasks': ?minTasks,
    'arms': [for (final a in arms) a.toJson()],
    'strata': [for (final s in strata) s.toJson()],
    'randomizedOrder': randomizedOrder,
    'alpha': alpha,
    'nonInferiorityMargin': ?nonInferiorityMargin,
    'interimAtTasks': ?interimAtTasks,
    'maxCostRatio': maxCostRatio,
    'maxSpendUsd': ?maxSpendUsd,
    if (contextWindowTokens != null) 'contextWindowTokens': contextWindowTokens,
    if (caveats.isNotEmpty) 'caveats': [for (final c in caveats) c.toJson()],
    if (routePolicy != null) 'routePolicy': routePolicy!.toJson(),
    if (memoryExperiment != null)
      'memoryExperiment': memoryExperiment!.toJson(),
    if (overlapExperiment != null)
      'overlapExperiment': overlapExperiment!.toJson(),
    if (taskTags.isNotEmpty) 'taskTags': taskTags,
    if (notes.isNotEmpty) 'notes': notes,
  };

  /// This plan with [extra] caveats appended (de-duplicated by code).
  ///
  /// Used by the runner to record conditions it observed at execution time
  /// (e.g. that the paired arms shared one provider cache) without mutating the
  /// operator's plan.
  EvaluationPlan withAdditionalCaveats(List<EvaluationCaveat> extra) {
    if (extra.isEmpty) {
      return this;
    }
    final seen = {for (final caveat in caveats) caveat.code};
    final merged = [
      ...caveats,
      for (final caveat in extra)
        if (seen.add(caveat.code)) caveat,
    ];
    return EvaluationPlan(
      id: id,
      hypothesis: hypothesis,
      primaryOutcome: primaryOutcome,
      minTasks: minTasks,
      seed: seed,
      arms: arms,
      strata: strata,
      randomizedOrder: randomizedOrder,
      alpha: alpha,
      nonInferiorityMargin: nonInferiorityMargin,
      interimAtTasks: interimAtTasks,
      maxCostRatio: maxCostRatio,
      maxSpendUsd: maxSpendUsd,
      contextWindowTokens: contextWindowTokens,
      caveats: merged,
      routePolicy: routePolicy,
      memoryExperiment: memoryExperiment,
      overlapExperiment: overlapExperiment,
      taskTags: taskTags,
      notes: notes,
    );
  }
}

bool _listEq(List<Object?> a, List<Object?> b) {
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}
