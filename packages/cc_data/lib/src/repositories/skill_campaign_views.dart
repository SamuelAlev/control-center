import 'package:cc_domain/core/domain/value_objects/principal.dart';

/// Typed, presentation-safe snapshots supplied by `evals.*`.
///
/// The server owns validation, actor identity, execution and redaction. These
/// views preserve unknown measurements instead of turning them into zeroes.
class SkillCorpusView {
  /// Holds one corpus advertised by the evaluation service.
  const SkillCorpusView({
    required this.id,
    required this.name,
    required this.description,
    required this.taskCount,
    required this.tags,
  });

  /// Decodes the corpus metadata from an `evals.skillCorpora` response.
  factory SkillCorpusView.fromWire(Map<String, dynamic> w) => SkillCorpusView(
    id: w['id'] as String,
    name: w['name'] as String,
    description: w['description'] as String,
    taskCount: (w['taskCount'] as num).toInt(),
    tags: List<String>.unmodifiable((w['tags'] as List).cast<String>()),
  );

  /// Stable corpus identifier accepted by campaign requests.
  final String id;

  /// Display name of this corpus.
  final String name;

  /// Description of the tasks included in this corpus.
  final String description;

  /// Number of available evaluation tasks.
  final int taskCount;

  /// Search and grouping labels supplied by the service.
  final List<String> tags;
}

/// Availability and execution options for skill campaigns in a workspace.
class SkillCampaignCapabilities {
  /// Holds the advertised execution backends and availability reason.
  const SkillCampaignCapabilities({
    required this.available,
    required this.reason,
    required this.backends,
    this.unavailableBackends = const {},
    this.usageBudgetProviders = const [],
  });

  /// Decodes the capability metadata from an `evals.skillCorpora` response.
  factory SkillCampaignCapabilities.fromWire(Map<String, dynamic> w) =>
      SkillCampaignCapabilities(
        available: w['available'] as bool,
        reason: w['reason'] as String?,
        backends: List<String>.unmodifiable(
          (w['backends'] as List).cast<String>(),
        ),
        unavailableBackends: Map<String, String>.unmodifiable(
          (w['unavailableBackends'] as Map? ?? const {}).cast<String, String>(),
        ),
        usageBudgetProviders: List<String>.unmodifiable(
          (w['usageBudgetProviders'] as List? ?? const []).cast<String>(),
        ),
      );

  /// Whether the service can start skill campaigns in this workspace.
  final bool available;

  /// Why campaign execution is unavailable, if applicable.
  final String? reason;

  /// Backend identifiers offered for campaign execution.
  final List<String> backends;

  /// Backend identifiers mapped to their unavailability reasons.
  final Map<String, String> unavailableBackends;

  /// Providers supporting usage-based campaign budgets.
  final List<String> usageBudgetProviders;
}

/// Corpus catalog together with workspace-specific execution capabilities.
class SkillCorporaView {
  /// Holds the catalog and the capabilities returned with it.
  const SkillCorporaView({required this.corpora, required this.capabilities});

  /// Decodes the catalog and capabilities from `evals.skillCorpora`.
  factory SkillCorporaView.fromWire(Map<String, dynamic> w) => SkillCorporaView(
    corpora: List<SkillCorpusView>.unmodifiable(
      (w['corpora'] as List).map(
        (c) => SkillCorpusView.fromWire((c as Map).cast<String, dynamic>()),
      ),
    ),
    capabilities: SkillCampaignCapabilities.fromWire(
      (w['capabilities'] as Map).cast<String, dynamic>(),
    ),
  );

  /// Evaluation corpora available for campaign selection.
  final List<SkillCorpusView> corpora;

  /// Workspace-specific campaign execution capabilities.
  final SkillCampaignCapabilities capabilities;
}

/// Comparison strategy used when constructing paired campaign attempts.
enum SkillCampaignComparison {
  /// Compare no target skill against normal metadata-driven availability.
  absent,

  /// Compare the admitted previous revision against the candidate revision.
  previous,

  /// Inject the full candidate body diagnostically, bypassing normal routing.
  forced,

  /// Compare a pinned ambient inventory with and without the target skill.
  composition,
}

/// Execution lifecycle of a server-owned skill campaign.
enum SkillCampaignStatus {
  /// Admitted and waiting for the server to start the planned trials.
  queued,

  /// The server is executing the campaign's planned trials.
  running,

  /// Cancellation was requested and active execution is still stopping.
  cancelling,

  /// Cancellation finished; evidence from completed trials remains available.
  cancelled,

  /// Execution finished; the report declares whether coverage is complete.
  completed,

  /// Execution ended with a campaign-level failure, not just a failed trial.
  failed,

  /// Execution stopped unexpectedly and its evidence may be partial.
  interrupted,
}

/// Redacted campaign snapshot returned by the evaluation service.
class SkillCampaignView {
  /// Holds campaign identity, configuration, progress and results.
  const SkillCampaignView({
    required this.id,
    required this.workspaceId,
    required this.skillKey,
    required this.skillSlug,
    required this.skillHash,
    required this.corpusId,
    required this.providerId,
    required this.modelId,
    required this.configurationHash,
    required this.baselineHash,
    required this.repoId,
    required this.comparison,
    required this.status,
    required this.repetitions,
    required this.budgetMicros,
    required this.plannedAttempts,
    required this.completedAttempts,
    required this.spentMicros,
    required this.createdAt,
    required this.startedAt,
    required this.finishedAt,
    required this.actor,
    required this.triggeredBy,
    required this.staleReason,
    required this.error,
    required this.configuration,
    required this.report,
  });

  /// Decodes a campaign snapshot from the `evals.*` wire response.
  factory SkillCampaignView.fromWire(Map<String, dynamic> w) =>
      SkillCampaignView(
        id: w['id'] as String,
        workspaceId: w['workspaceId'] as String,
        skillKey: w['skillKey'] as String,
        skillSlug: w['skillSlug'] as String,
        skillHash: w['skillHash'] as String,
        corpusId: w['corpusId'] as String,
        providerId: w['providerId'] as String,
        modelId: w['modelId'] as String,
        configurationHash: w['configurationHash'] as String,
        baselineHash: w['baselineHash'] as String?,
        repoId: w['repoId'] as String?,
        comparison: SkillCampaignComparison.values.byName(
          w['comparison'] as String,
        ),
        status: SkillCampaignStatus.values.byName(w['status'] as String),
        repetitions: (w['repetitions'] as num).toInt(),
        budgetMicros: (w['budgetMicros'] as num).toInt(),
        plannedAttempts: (w['plannedAttempts'] as num).toInt(),
        completedAttempts: (w['completedAttempts'] as num).toInt(),
        spentMicros: (w['spentMicros'] as num?)?.toInt(),
        createdAt: DateTime.parse(w['createdAt'] as String),
        startedAt: DateTime.tryParse(w['startedAt'] as String? ?? ''),
        actor: Principal.parse(w['actor'] as String),
        finishedAt: DateTime.tryParse(w['finishedAt'] as String? ?? ''),
        triggeredBy: w['triggeredBy'] as String,
        staleReason: w['staleReason'] as String?,
        error: w['error'] as String?,
        configuration: Map<String, dynamic>.unmodifiable(
          (w['configuration'] as Map).cast<String, dynamic>(),
        ),
        report: w['report'] is Map
            ? Map<String, dynamic>.unmodifiable(
                (w['report'] as Map).cast<String, dynamic>(),
              )
            : null,
      );

  /// Server-assigned campaign identifier.
  final String id;

  /// Workspace owning this campaign.
  final String workspaceId;

  /// Stable skill identity used for grouping campaign history.
  final String skillKey;

  /// Skill slug selected when starting the campaign.
  final String skillSlug;

  /// Hash of the evaluated skill content.
  final String skillHash;

  /// Evaluation corpus identifier.
  final String corpusId;

  /// Model provider identifier used for campaign attempts.
  final String providerId;

  /// Model identifier used for campaign attempts.
  final String modelId;

  /// Hash of the effective campaign configuration.
  final String configurationHash;

  /// Hash of the comparison baseline, when one is selected.
  final String? baselineHash;

  /// Repository identifier associated with this skill, when present.
  final String? repoId;

  /// Baseline comparison strategy for this campaign.
  final SkillCampaignComparison comparison;

  /// Principal recorded as the initiating actor.
  final Principal actor;

  /// Current execution lifecycle state.
  final SkillCampaignStatus status;

  /// Repetitions requested per task and comparison arm.
  final int repetitions;

  /// Maximum authorized spend in micro-units.
  final int budgetMicros;

  /// Total number of attempts planned for the campaign.
  final int plannedAttempts;

  /// Number of attempts finished so far.
  final int completedAttempts;

  /// Metered spend in micro-units, if available.
  final int? spentMicros;

  /// Time the campaign was created.
  final DateTime createdAt;

  /// Time execution began, if it has begun.
  final DateTime? startedAt;

  /// Time execution ended, if it has ended.
  final DateTime? finishedAt;

  /// Origin that requested the campaign.
  final String triggeredBy;

  /// Reason the evaluated inputs became stale, if applicable.
  final String? staleReason;

  /// Redacted failure description, if execution failed.
  final String? error;

  /// Effective configuration supplied by the server.
  final Map<String, dynamic> configuration;

  /// Redacted aggregate report when results are available.
  final Map<String, dynamic>? report;

  /// Executor backend from the effective configuration.
  String get adapter => configuration['executor'] as String? ?? 'builtin';

  /// Whether the campaign has reached a terminal lifecycle state.
  bool get isTerminal => switch (status) {
    SkillCampaignStatus.cancelled ||
    SkillCampaignStatus.completed ||
    SkillCampaignStatus.failed ||
    SkillCampaignStatus.interrupted => true,
    _ => false,
  };
}

/// One task/arm/repetition result with server-redacted evidence.
class SkillAttemptView {
  /// Holds the attempt identity and its redacted evidence.
  const SkillAttemptView({
    required this.id,
    required this.workspaceId,
    required this.campaignId,
    required this.taskId,
    required this.armId,
    required this.repetition,
    required this.ordinal,
    required this.evidence,
    required this.createdAt,
  });

  /// Decodes an attempt from an `evals.*` wire response.
  factory SkillAttemptView.fromWire(Map<String, dynamic> w) => SkillAttemptView(
    id: w['id'] as String,
    workspaceId: w['workspaceId'] as String,
    campaignId: w['campaignId'] as String,
    taskId: w['taskId'] as String,
    armId: w['armId'] as String,
    repetition: (w['repetition'] as num).toInt(),
    ordinal: (w['ordinal'] as num).toInt(),
    evidence: Map<String, dynamic>.unmodifiable(
      (w['evidence'] as Map).cast<String, dynamic>(),
    ),
    createdAt: DateTime.parse(w['createdAt'] as String),
  );

  /// Server-assigned attempt identifier.
  final String id;

  /// Workspace that owns the attempt.
  final String workspaceId;

  /// Campaign containing the attempt.
  final String campaignId;

  /// Corpus task evaluated by the attempt.
  final String taskId;

  /// Comparison arm used for this attempt.
  final String armId;

  /// Repetition index within its task and arm.
  final int repetition;

  /// Campaign-wide attempt ordering index.
  final int ordinal;

  /// Redacted measurements and outcome supplied by the server.
  final Map<String, dynamic> evidence;

  /// Time this attempt was recorded.
  final DateTime createdAt;
}

/// Workspace opt-in and configuration for a specific skill's evaluations.
class SkillCampaignPolicyView {
  /// Holds the current policy and its last editor.
  const SkillCampaignPolicyView({
    required this.workspaceId,
    required this.skillKey,
    required this.enabled,
    required this.actor,
    required this.configuration,
    required this.updatedAt,
  });

  /// Decodes the policy snapshot from an `evals.*` wire response.
  factory SkillCampaignPolicyView.fromWire(Map<String, dynamic> w) =>
      SkillCampaignPolicyView(
        workspaceId: w['workspaceId'] as String,
        skillKey: w['skillKey'] as String,
        enabled: w['enabled'] as bool,
        actor: Principal.parse(w['actor'] as String),
        configuration: Map<String, dynamic>.unmodifiable(
          (w['configuration'] as Map).cast<String, dynamic>(),
        ),
        updatedAt: DateTime.parse(w['updatedAt'] as String),
      );

  /// Workspace owning this policy.
  final String workspaceId;

  /// Stable skill identity governed by this policy.
  final String skillKey;

  /// Whether automatic evaluation is enabled for the skill.
  final bool enabled;

  /// Principal that last changed this policy.
  final Principal actor;

  /// Effective evaluation settings stored for the skill.
  final Map<String, dynamic> configuration;

  /// Time this policy was last changed.
  final DateTime updatedAt;
}

/// Server-produced campaign export ready for download.
class SkillCampaignExport {
  /// Holds the suggested download name and export contents.
  const SkillCampaignExport({required this.filename, required this.content});

  /// Suggested name for the downloaded export file.
  final String filename;

  /// Complete serialized export supplied by the service.
  final String content;
}
