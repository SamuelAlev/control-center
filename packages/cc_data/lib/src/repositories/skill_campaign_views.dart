import 'package:cc_domain/core/domain/value_objects/principal.dart';

/// Typed, presentation-safe snapshots supplied by `evals.*`.
///
/// The server owns validation, actor identity, execution and redaction. These
/// views preserve unknown measurements instead of turning them into zeroes.
class SkillCorpusView {
  const SkillCorpusView({
    required this.id,
    required this.name,
    required this.description,
    required this.taskCount,
    required this.tags,
  });
  factory SkillCorpusView.fromWire(Map<String, dynamic> w) => SkillCorpusView(
    id: w['id'] as String,
    name: w['name'] as String,
    description: w['description'] as String,
    taskCount: (w['taskCount'] as num).toInt(),
    tags: List<String>.unmodifiable((w['tags'] as List).cast<String>()),
  );
  final String id, name, description;
  final int taskCount;
  final List<String> tags;
}

class SkillCampaignCapabilities {
  const SkillCampaignCapabilities({
    required this.available,
    required this.reason,
    required this.backends,
    this.unavailableBackends = const {},
    this.usageBudgetProviders = const [],
  });
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
  final bool available;
  final String? reason;
  final List<String> backends;
  final Map<String, String> unavailableBackends;
  final List<String> usageBudgetProviders;
}

class SkillCorporaView {
  const SkillCorporaView({required this.corpora, required this.capabilities});
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
  final List<SkillCorpusView> corpora;
  final SkillCampaignCapabilities capabilities;
}

enum SkillCampaignComparison { absent, previous, forced, composition }

enum SkillCampaignStatus {
  queued,
  running,
  cancelling,
  cancelled,
  completed,
  failed,
  interrupted,
}

class SkillCampaignView {
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

  final String id,
      workspaceId,
      skillKey,
      skillSlug,
      skillHash,
      corpusId,
      providerId,
      modelId,
      configurationHash;
  final String? baselineHash, repoId;
  final SkillCampaignComparison comparison;
  final Principal actor;
  final SkillCampaignStatus status;
  final int repetitions, budgetMicros, plannedAttempts, completedAttempts;
  final int? spentMicros;
  final DateTime createdAt;
  final DateTime? startedAt, finishedAt;
  final String triggeredBy;
  final String? staleReason, error;
  final Map<String, dynamic> configuration;
  final Map<String, dynamic>? report;
  String get adapter => configuration['executor'] as String? ?? 'builtin';
  bool get isTerminal => switch (status) {
    SkillCampaignStatus.cancelled ||
    SkillCampaignStatus.completed ||
    SkillCampaignStatus.failed ||
    SkillCampaignStatus.interrupted => true,
    _ => false,
  };
}

class SkillAttemptView {
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
  final String id, workspaceId, campaignId, taskId, armId;
  final int repetition, ordinal;
  final Map<String, dynamic> evidence;
  final DateTime createdAt;
}

class SkillCampaignPolicyView {
  const SkillCampaignPolicyView({
    required this.workspaceId,
    required this.skillKey,
    required this.enabled,
    required this.actor,
    required this.configuration,
    required this.updatedAt,
  });
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
  final String workspaceId, skillKey;
  final bool enabled;
  final Principal actor;
  final Map<String, dynamic> configuration;
  final DateTime updatedAt;
}

class SkillCampaignExport {
  const SkillCampaignExport({required this.filename, required this.content});
  final String filename, content;
}
