import 'dart:math' as math;

import 'package:cc_domain/features/evals/domain/evaluation/evaluation_manifest.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_task.dart';

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
  skillIntervention('skill_intervention');

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
  nativeResume('native_resume');

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
    this.cacheEnabled = true,
    this.toolDeferralEnabled = true,
  });

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
          skillExposure == SkillExposure.available);

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
          taskRoutePolicyId == other.taskRoutePolicyId;

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
  );
}

/// One task-boundary routing decision (report 4A: "Prefer changing
/// model/effort at task boundaries rather than repeatedly mid-session").
class RoutingDecision {
  /// Creates a [RoutingDecision].
  const RoutingDecision({this.modelId, this.effortLevel, this.note = ''});

  /// Parses from JSON.
  factory RoutingDecision.fromJson(Map<String, dynamic> json) =>
      RoutingDecision(
        modelId: json['modelId'] as String?,
        effortLevel: json['effortLevel'] as String?,
        note: json['note'] as String? ?? '',
      );

  /// Model to use, or null to keep the pinned model.
  final String? modelId;

  /// Effort to use, or null to keep the pinned effort.
  final String? effortLevel;

  /// Why this route was chosen (audit trail).
  final String note;

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    if (modelId != null) 'modelId': modelId,
    if (effortLevel != null) 'effortLevel': effortLevel,
    if (note.isNotEmpty) 'note': note,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RoutingDecision &&
          modelId == other.modelId &&
          effortLevel == other.effortLevel &&
          note == other.note;

  @override
  int get hashCode => Object.hash(modelId, effortLevel, note);
}

/// An OPT-IN, task-boundary routing policy (report 4A + §6).
///
/// The policy is inert unless [enabled] is explicitly set, and even then it
/// may only route *away* from the pinned quality default for task classes the
/// operator enumerated AND whose acceptance evidence is independently
/// checkable. [violations] enumerates every way a policy would silently
/// degrade a user-selected default; the runner refuses to apply a policy that
/// reports any.
class TaskRoutePolicy {
  /// Creates a [TaskRoutePolicy].
  const TaskRoutePolicy({
    required this.id,
    this.version = 1,
    this.enabled = false,
    this.description = '',
    this.optedInBy = '',
    this.byTaskKind = const {},
    this.byTaskId = const {},
    this.defaultDecision = const RoutingDecision(),
    this.allowUncheckedRouting = false,
  });

  /// Parses from JSON.
  factory TaskRoutePolicy.fromJson(Map<String, dynamic> json) =>
      TaskRoutePolicy(
        id: json['id'] as String? ?? '',
        version: (json['version'] as num?)?.toInt() ?? 1,
        enabled: json['enabled'] as bool? ?? false,
        description: json['description'] as String? ?? '',
        optedInBy: json['optedInBy'] as String? ?? '',
        byTaskKind: {
          for (final e
              in (json['byTaskKind'] as Map?)?.entries ??
                  const Iterable<MapEntry<dynamic, dynamic>>.empty())
            EvaluationTaskKind.fromWire('${e.key}'): RoutingDecision.fromJson(
              (e.value as Map).cast<String, dynamic>(),
            ),
        },
        byTaskId: {
          for (final e
              in (json['byTaskId'] as Map?)?.entries ??
                  const Iterable<MapEntry<dynamic, dynamic>>.empty())
            '${e.key}': RoutingDecision.fromJson(
              (e.value as Map).cast<String, dynamic>(),
            ),
        },
        defaultDecision: json['defaultDecision'] == null
            ? const RoutingDecision()
            : RoutingDecision.fromJson(
                (json['defaultDecision'] as Map).cast<String, dynamic>(),
              ),
        allowUncheckedRouting: json['allowUncheckedRouting'] as bool? ?? false,
      );

  /// Stable policy id.
  final String id;

  /// Policy revision — recorded with every routed trial.
  final int version;

  /// Whether the operator explicitly turned routing on. Defaults to false:
  /// an unconfigured policy never routes.
  final bool enabled;

  /// What the policy is for.
  final String description;

  /// Who opted in (an audit string: operator/account).
  final String optedInBy;

  /// Per-task-class routes.
  final Map<EvaluationTaskKind, RoutingDecision> byTaskKind;

  /// Per-task-id routes (win over [byTaskKind]).
  final Map<String, RoutingDecision> byTaskId;

  /// The route for a task with no explicit entry. Kept empty by design: the
  /// default route is the pinned quality default.
  final RoutingDecision defaultDecision;

  /// Whether to allow routing a task whose acceptance evidence is not fully
  /// behavioral. Off by default; turning it on is recorded as a caveat rather
  /// than silently accepted.
  final bool allowUncheckedRouting;

  /// The route for [task], or null to keep the quality default.
  RoutingDecision? decisionFor(EvaluationTask task) {
    if (!enabled) {
      return null;
    }
    final byId = byTaskId[task.id];
    if (byId != null) {
      return byId;
    }
    return byTaskKind[task.kind];
  }

  /// Every way this policy would silently replace the pinned quality default.
  ///
  /// Empty when the policy is inert, or when it only routes task classes the
  /// operator enumerated whose evidence is independently checkable.
  List<String> violations({
    required List<EvaluationTask> tasks,
    required List<EvaluationArm> arms,
  }) {
    final problems = <String>[];
    if (!enabled) {
      return problems;
    }
    if (optedInBy.trim().isEmpty) {
      problems.add(
        'policy "$id" is enabled without an opt-in record (optedInBy)',
      );
    }
    if (byTaskKind.isEmpty && byTaskId.isEmpty) {
      problems.add('policy "$id" is enabled but routes nothing');
    }
    if (arms.where((a) => a.isBaseline).isEmpty) {
      problems.add(
        'policy "$id" has no baseline arm, so non-inferiority cannot be '
        'established',
      );
    }
    for (final task in tasks) {
      final decision = decisionFor(task);
      if (decision == null) {
        continue;
      }
      if (!task.independentlyCheckable && !allowUncheckedRouting) {
        problems.add(
          'policy "$id" routes task "${task.id}" (${task.kind.wire}) whose '
          'acceptance evidence is not fully behavioral',
        );
      }
      if ((decision.modelId == null || decision.modelId!.trim().isEmpty) &&
          (decision.effortLevel == null ||
              decision.effortLevel!.trim().isEmpty) &&
          decision.note.trim().isEmpty) {
        problems.add('policy "$id" has an empty route for task "${task.id}"');
      }
    }
    return problems;
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'id': id,
    'version': version,
    'enabled': enabled,
    if (description.isNotEmpty) 'description': description,
    if (optedInBy.isNotEmpty) 'optedInBy': optedInBy,
    if (byTaskKind.isNotEmpty)
      'byTaskKind': {
        for (final e in byTaskKind.entries) e.key.wire: e.value.toJson(),
      },
    if (byTaskId.isNotEmpty)
      'byTaskId': {for (final e in byTaskId.entries) e.key: e.value.toJson()},
    if (defaultDecision != const RoutingDecision())
      'defaultDecision': defaultDecision.toJson(),
    if (allowUncheckedRouting) 'allowUncheckedRouting': true,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskRoutePolicy &&
          id == other.id &&
          version == other.version &&
          enabled == other.enabled &&
          description == other.description &&
          optedInBy == other.optedInBy &&
          defaultDecision == other.defaultDecision &&
          allowUncheckedRouting == other.allowUncheckedRouting &&
          _mapEq(byTaskKind, other.byTaskKind) &&
          _mapEq(byTaskId, other.byTaskId);

  @override
  int get hashCode => Object.hash(
    id,
    version,
    enabled,
    description,
    optedInBy,
    defaultDecision,
    allowUncheckedRouting,
    byTaskKind.length,
    byTaskId.length,
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
    required this.mode,
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
        mode: MemoryPolicyMode.fromWire(json['mode'] as String?),
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

  /// The policy under test.
  final MemoryPolicyMode mode;

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
    if (mode.rewritesHistory && !requireRecoverableReferences) {
      problems.add(
        'experiment "$id" rewrites history with no recoverable references',
      );
    }
    if (mode == MemoryPolicyMode.snapshotImages) {
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
    'mode': mode.wire,
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
          mode == other.mode &&
          requireRecoverableReferences == other.requireRecoverableReferences &&
          requireSnapshotFidelityCheck == other.requireSnapshotFidelityCheck &&
          notes == other.notes &&
          _listEq(fidelityVerifiers, other.fidelityVerifiers);

  @override
  int get hashCode => Object.hash(
    id,
    enabled,
    mode,
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

/// One scheduled trial: which task, which arm, in which stratum, at which
/// repetition, with which derived repeat seed.
class EvaluationTrial {
  /// Creates an [EvaluationTrial].
  const EvaluationTrial({
    required this.ordinal,
    required this.taskId,
    required this.armId,
    required this.stratum,
    required this.repetition,
    required this.seed,
    this.executionMode = EvaluationExecutionMode.live,
  });

  /// Parses from JSON.
  factory EvaluationTrial.fromJson(Map<String, dynamic> json) =>
      EvaluationTrial(
        ordinal: (json['ordinal'] as num?)?.toInt() ?? 0,
        taskId: json['taskId'] as String? ?? '',
        armId: json['armId'] as String? ?? '',
        stratum: CacheStratum.fromWire(json['stratum'] as String?),
        repetition: (json['repetition'] as num?)?.toInt() ?? 0,
        seed: (json['seed'] as num?)?.toInt() ?? 0,
        executionMode: EvaluationExecutionMode.fromWire(
          json['executionMode'] as String?,
        ),
      );

  /// Position in the randomized execution order.
  final int ordinal;

  /// The task to run.
  final String taskId;

  /// The arm to run it under.
  final String armId;

  /// The cache stratum this trial belongs to.
  final CacheStratum stratum;

  /// Repetition index within (task, arm, stratum).
  final int repetition;

  /// The derived repeat seed handed to the backend.
  final int seed;

  /// Whether this trial is live or a replay.
  final EvaluationExecutionMode executionMode;

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'ordinal': ordinal,
    'taskId': taskId,
    'armId': armId,
    'stratum': stratum.wire,
    'repetition': repetition,
    'seed': seed,
    'executionMode': executionMode.wire,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EvaluationTrial &&
          ordinal == other.ordinal &&
          taskId == other.taskId &&
          armId == other.armId &&
          stratum == other.stratum &&
          repetition == other.repetition &&
          seed == other.seed &&
          executionMode == other.executionMode;

  @override
  int get hashCode => Object.hash(
    ordinal,
    taskId,
    armId,
    stratum,
    repetition,
    seed,
    executionMode,
  );
}

/// The reproducible campaign plan: corpus tasks × arms × strata × repetitions,
/// with a seeded, randomized execution order (HARNESS_RESEARCH §6: "Use paired
/// runs and repeated trials… Randomize execution order and account for
/// provider-cache carryover").
class EvaluationPlan {
  /// Creates an [EvaluationPlan].
  const EvaluationPlan({
    required this.id,
    this.seed = 1,
    this.arms = const [],
    this.strata = const [
      StratumSpec(stratum: CacheStratum.cold, repetitions: 1),
      StratumSpec(stratum: CacheStratum.warm, repetitions: 1),
    ],
    this.randomizedOrder = true,
    this.minPairs = 8,
    this.alpha = 0.05,
    this.nonInferiorityMargin = 0.05,
    this.maxCostRatio = 1.0,
    this.contextWindowTokens,
    this.caveats = const [],
    this.routePolicy,
    this.memoryExperiment,
    this.overlapExperiment,
    this.notes = '',
  });

  /// Parses from JSON.
  factory EvaluationPlan.fromJson(Map<String, dynamic> json) => EvaluationPlan(
    id: json['id'] as String? ?? '',
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
    minPairs: (json['minPairs'] as num?)?.toInt() ?? 8,
    alpha: (json['alpha'] as num?)?.toDouble() ?? 0.05,
    nonInferiorityMargin:
        (json['nonInferiorityMargin'] as num?)?.toDouble() ?? 0.05,
    maxCostRatio: (json['maxCostRatio'] as num?)?.toDouble() ?? 1.0,
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

  /// Whether to shuffle the execution order inside each stratum.
  final bool randomizedOrder;

  /// Minimum number of matched pairs required before a non-inferiority verdict
  /// is allowed to be anything other than inconclusive.
  final int minPairs;

  /// Significance level for the one-sided task-cluster quality bounds.
  final double alpha;

  /// Relative success-rate loss permitted while still calling a treatment
  /// non-inferior (e.g. `0.05` = may lose up to 5 percentage points).
  final double nonInferiorityMargin;

  /// The largest acceptable ratio of treatment cost to baseline cost for an
  /// adoption recommendation (`1.0` = no more expensive).
  final double maxCostRatio;

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

  /// Operator notes.
  final String notes;

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
    if (arms.length < 2) {
      problems.add('plan "$id" needs at least two arms to pair');
    }
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
    if (minPairs < 2) {
      problems.add('plan "$id" minPairs must be at least 2');
    }
    if (alpha <= 0 || alpha >= 1 || !alpha.isFinite) {
      problems.add('plan "$id" alpha must be between 0 and 1');
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
          (memory == null || memory.mode != arm.memoryPolicy)) {
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
    if (memory != null &&
        memory.enabled &&
        !arms.any((a) => a.memoryPolicy == memory.mode)) {
      problems.add(
        'memory experiment "${memory.id}" is opted in but no arm '
        'uses ${memory.mode.wire}',
      );
    }
    return problems;
  }

  /// The deterministic, randomized trial schedule for [tasks].
  ///
  /// Strata run in the canonical cold → warm → post-idle order (so cache
  /// carryover is monotone), but the trials *inside* a stratum are shuffled
  /// with the plan seed, which is what breaks any residual ordering bias
  /// between arms.
  List<EvaluationTrial> schedule(
    List<EvaluationTask> tasks, {
    EvaluationExecutionMode executionMode = EvaluationExecutionMode.live,
  }) {
    final ordered = <EvaluationTrial>[];
    var ordinal = 0;
    for (var s = 0; s < strata.length; s++) {
      final spec = strata[s];
      final bucket = <EvaluationTrial>[];
      for (final task in tasks) {
        for (final arm in arms) {
          for (var rep = 0; rep < spec.repetitions; rep++) {
            bucket.add(
              EvaluationTrial(
                ordinal: 0,
                taskId: task.id,
                armId: arm.id,
                stratum: spec.stratum,
                repetition: rep,
                seed: _deriveSeed(seed, task.id, arm.id, spec, rep),
                executionMode: executionMode,
              ),
            );
          }
        }
      }
      if (randomizedOrder) {
        bucket.shuffle(math.Random(_mix(seed ^ (s * 0x9e3779b1))));
      }
      for (final trial in bucket) {
        ordered.add(_withOrdinal(trial, ordinal++));
      }
    }
    return ordered;
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'id': id,
    'seed': seed,
    'arms': [for (final a in arms) a.toJson()],
    'strata': [for (final s in strata) s.toJson()],
    'randomizedOrder': randomizedOrder,
    'minPairs': minPairs,
    'alpha': alpha,
    'nonInferiorityMargin': nonInferiorityMargin,
    'maxCostRatio': maxCostRatio,
    if (contextWindowTokens != null) 'contextWindowTokens': contextWindowTokens,
    if (caveats.isNotEmpty) 'caveats': [for (final c in caveats) c.toJson()],
    if (routePolicy != null) 'routePolicy': routePolicy!.toJson(),
    if (memoryExperiment != null)
      'memoryExperiment': memoryExperiment!.toJson(),
    if (overlapExperiment != null)
      'overlapExperiment': overlapExperiment!.toJson(),
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
      seed: seed,
      arms: arms,
      strata: strata,
      randomizedOrder: randomizedOrder,
      minPairs: minPairs,
      alpha: alpha,
      nonInferiorityMargin: nonInferiorityMargin,
      maxCostRatio: maxCostRatio,
      contextWindowTokens: contextWindowTokens,
      caveats: merged,
      routePolicy: routePolicy,
      memoryExperiment: memoryExperiment,
      overlapExperiment: overlapExperiment,
      notes: notes,
    );
  }

  static EvaluationTrial _withOrdinal(EvaluationTrial trial, int ordinal) =>
      EvaluationTrial(
        ordinal: ordinal,
        taskId: trial.taskId,
        armId: trial.armId,
        stratum: trial.stratum,
        repetition: trial.repetition,
        seed: trial.seed,
        executionMode: trial.executionMode,
      );

  /// A per-trial seed derived from the campaign seed and the trial identity,
  /// so the seed is stable no matter what order the schedule is executed in.
  static int _deriveSeed(
    int seed,
    String taskId,
    String armId,
    StratumSpec spec,
    int repetition,
  ) {
    var h = _mix(seed);
    for (final unit in taskId.codeUnits) {
      h = _mix(h ^ unit);
    }
    for (final unit in armId.codeUnits) {
      h = _mix(h ^ (unit + 0x9e37));
    }
    h = _mix(h ^ spec.stratum.index + 0x85eb);
    return _mix(h ^ repetition) & 0x7fffffff;
  }

  /// A small deterministic integer mixer (the murmur3 finalizer).
  static int _mix(int value) {
    var h = value & 0xffffffff;
    h ^= h >> 16;
    h = (h * 0x85ebca6b) & 0xffffffff;
    h ^= h >> 13;
    h = (h * 0xc2b2ae35) & 0xffffffff;
    h ^= h >> 16;
    return h & 0x7fffffff;
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

bool _mapEq(Map<Object?, Object?> a, Map<Object?, Object?> b) {
  if (a.length != b.length) {
    return false;
  }
  for (final e in a.entries) {
    if (b[e.key] != e.value) {
      return false;
    }
  }
  return true;
}
