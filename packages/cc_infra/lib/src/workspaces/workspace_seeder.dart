import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_trigger.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_template_repository.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_trigger_repository.dart';
import 'package:cc_domain/features/pipelines/domain/templates/builtin_template_seeds.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:cc_infra/src/ports/workspace_filesystem_port.dart';
import 'package:cc_infra/src/workspaces/create_ceo_agent.dart';
import 'package:cc_infra/src/workspaces/create_specialist_agents.dart';
import 'package:uuid/uuid.dart';

/// Seeds a workspace's default bootstrap: the CEO + specialist agents and the
/// built-in pipeline templates (wiring per-node `agentId` config to the seeded
/// specialists) and their triggers.
///
/// This is the SERVER's workspace bootstrap — it owns the database and the
/// on-disk agent/skill files directly, so it runs where `cc_server` creates a
/// workspace (reacting to `WorkspaceCreated`), not on the thin client. Every
/// step is idempotent (agents return existing rows by slug; templates upsert,
/// preserving the user's enabled choice), so a re-seed never duplicates.
class WorkspaceSeeder {
  /// Creates a [WorkspaceSeeder] over the workspace-scoped write surfaces.
  const WorkspaceSeeder({
    required AgentRepository agentRepository,
    required WorkspaceFilesystemPort filesystem,
    required PipelineTemplateRepository templateRepository,
    required PipelineTriggerRepository triggerRepository,
  })  : _agentRepository = agentRepository,
        _filesystem = filesystem,
        _templateRepository = templateRepository,
        _triggerRepository = triggerRepository;

  final AgentRepository _agentRepository;
  final WorkspaceFilesystemPort _filesystem;
  final PipelineTemplateRepository _templateRepository;
  final PipelineTriggerRepository _triggerRepository;

  /// Seeds the CEO + specialist agents and the built-in pipeline templates for a
  /// freshly created [workspaceId]. [adapterId]/[modelId] are stamped on the
  /// created agents when supplied (the inference backend); null leaves them
  /// unset for the user to configure. Failures are logged, never thrown — a new
  /// workspace must not be left half-seeded with an unhandled error.
  Future<void> seed(
    String workspaceId, {
    String? adapterId,
    String? modelId,
  }) async {
    try {
      final ceo = await CreateCeoAgentUseCase(
        agentRepository: _agentRepository,
        filesystemService: _filesystem,
      ).execute(workspaceId, adapterId: adapterId, modelId: modelId);
      final specialists = await CreateSpecialistAgentsUseCase(
        agentRepository: _agentRepository,
        filesystemService: _filesystem,
      ).execute(
        workspaceId,
        ceoAgentId: ceo.id,
        adapterId: adapterId,
        modelId: modelId,
      );
      await seedBuiltInPipelineTemplates(
        workspaceId: workspaceId,
        ceo: ceo,
        specialists: specialists,
      );
    } on Object catch (e, st) {
      CcInfraLog.error(
        'WorkspaceSeeder: failed to seed workspace $workspaceId',
        e,
        st,
      );
    }
  }

  /// Re-seeds the built-in pipeline templates for an EXISTING [workspaceId]
  /// (e.g. on launch, so templates added in newer versions appear). Looks up the
  /// workspace's existing CEO/specialists to wire the agent-bearing templates.
  Future<void> reseedTemplates(String workspaceId) async {
    try {
      final ceo = await _agentRepository.findByWorkspaceAndName(
        workspaceId,
        'ceo',
      );
      final specialists =
          await _agentRepository.watchByWorkspace(workspaceId).first;
      await seedBuiltInPipelineTemplates(
        workspaceId: workspaceId,
        ceo: ceo,
        specialists: specialists,
      );
    } on Object catch (e, st) {
      CcInfraLog.error(
        'WorkspaceSeeder: failed to re-seed templates for workspace '
        '$workspaceId',
        e,
        st,
      );
    }
  }

  /// Seeds the built-in pipeline templates for a workspace, wiring per-node
  /// `agentId` config to the supplied specialist agents. The agentless
  /// `index_code` template is always ensured; the agent-bearing templates are
  /// skipped when the specialists aren't all available.
  Future<void> seedBuiltInPipelineTemplates({
    required String workspaceId,
    Agent? ceo,
    List<Agent> specialists = const [],
  }) async {
    // The code indexer is agentless — always ensure it, even for workspaces
    // whose specialist agents aren't available.
    await _ensureIndexCodeTemplate(workspaceId);

    Agent? bySlug(String slug) {
      for (final a in specialists) {
        if (a.name == slug) {
          return a;
        }
      }
      return null;
    }

    final qa = bySlug('qa');
    final architect = bySlug('architect');
    final engineer = bySlug('engineer');
    final librarian = bySlug('librarian');
    if (ceo == null ||
        qa == null ||
        architect == null ||
        engineer == null ||
        librarian == null) {
      // Specialists weren't fully created — skip the agent-based templates (the
      // agentless index_code template above is still seeded).
      return;
    }

    final ids = BuiltInAgentIds(
      qa: qa.id,
      architect: architect.id,
      engineer: engineer.id,
      librarian: librarian.id,
      ceo: ceo.id,
    );
    // Reconcile each template's built-in trigger rows. Existing rows are left
    // untouched so the user's enable/filter choices survive a re-seed.
    final existingTriggerKeys =
        (await _triggerRepository.forWorkspace(workspaceId))
            .map((t) => '${t.templateId}|${t.eventType}')
            .toSet();

    for (final seed in builtInTemplateSeeds(
      workspaceId: workspaceId,
      agentIds: ids,
    )) {
      // Preserve the user's isEnabled choice across re-seeds; copyWith keeps the
      // declared inputs (and steps) so manual-run forms survive a re-seed.
      final existing = await _templateRepository.getById(
        workspaceId,
        seed.templateId,
      );
      final enabled = existing?.isEnabled ?? seed.isEnabled;
      await _templateRepository.upsert(seed.copyWith(isEnabled: enabled));
      await _seedBuiltInTriggers(
        workspaceId: workspaceId,
        templateId: seed.templateId,
        existingKeys: existingTriggerKeys,
      );
    }
  }

  /// Inserts any missing built-in trigger rows for [templateId]. Records
  /// inserted `templateId|eventType` keys in [existingKeys] so a single seed
  /// pass never double-inserts, and so existing rows (with the user's
  /// enable/filter choices) are preserved.
  Future<void> _seedBuiltInTriggers({
    required String workspaceId,
    required String templateId,
    required Set<String> existingKeys,
  }) async {
    final specs = builtInTriggerSeeds()[templateId];
    if (specs == null) {
      return;
    }
    for (final spec in specs) {
      final key = '$templateId|${spec.eventType}';
      if (existingKeys.contains(key)) {
        continue;
      }
      await _triggerRepository.insert(
        PipelineTrigger(
          id: const Uuid().v4(),
          eventType: spec.eventType,
          templateId: templateId,
          workspaceId: workspaceId,
          enabled: spec.enabled,
          cronExpression: spec.cronExpression,
          match: spec.match,
        ),
      );
      existingKeys.add(key);
    }
  }

  /// Ensures the agentless `index_code` template + its `RepoAdded` trigger exist
  /// for [workspaceId] (idempotent; preserves the user's enabled choice).
  Future<void> _ensureIndexCodeTemplate(String workspaceId) async {
    final seed = indexCodeTemplate(workspaceId);
    final existing = await _templateRepository.getById(
      workspaceId,
      seed.templateId,
    );
    await _templateRepository.upsert(
      seed.copyWith(
        isBuiltIn: true,
        isEnabled: existing?.isEnabled ?? seed.isEnabled,
      ),
    );

    final existingKeys = (await _triggerRepository.forWorkspace(workspaceId))
        .map((t) => '${t.templateId}|${t.eventType}')
        .toSet();
    await _seedBuiltInTriggers(
      workspaceId: workspaceId,
      templateId: 'index_code',
      existingKeys: existingKeys,
    );
  }
}
