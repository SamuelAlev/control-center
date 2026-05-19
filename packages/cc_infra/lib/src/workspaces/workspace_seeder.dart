import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_definition.dart';
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
  }) : _agentRepository = agentRepository,
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
      final specialists =
          await CreateSpecialistAgentsUseCase(
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

  /// Reconciles the built-in pipeline templates into an EXISTING [workspaceId]
  /// — the launch path, so a seed that CHANGED in a newer version reaches
  /// workspaces created before it (a template added in a newer version has no
  /// other delivery path either). Looks up the workspace's existing
  /// CEO/specialists to wire the agent-bearing templates.
  ///
  /// Safe to run on every boot: [_upsertBuiltIn] skips a template the user took
  /// over and writes nothing when the installed row already matches the seed.
  Future<void> reseedTemplates(String workspaceId) async {
    try {
      final ceo = await _agentRepository.findByWorkspaceAndName(
        workspaceId,
        'ceo',
      );
      final specialists = await _agentRepository
          .watchByWorkspace(workspaceId)
          .first;
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
  /// `skill_analysis` and `index_code` templates are always ensured; the
  /// agent-bearing templates are skipped when the specialists aren't all
  /// available.
  Future<void> seedBuiltInPipelineTemplates({
    required String workspaceId,
    Agent? ceo,
    List<Agent> specialists = const [],
  }) async {
    // The skills-antivirus pipeline is agentless — always ensure it, even for
    // workspaces whose specialist agents aren't available.
    await ensureSkillAnalysisTemplate(workspaceId);

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
      // Specialists weren't fully created — skip the agent-based templates, but
      // still seed the code indexer: it is agentless in this form.
      //
      // With the specialists present the indexer is seeded by the loop below
      // instead, in its richer librarian-bearing form. Seeding both forms in
      // one pass would rewrite the template on every boot and briefly strip
      // its `analyze` node, so exactly one of the two paths runs.
      await _ensureIndexCodeTemplate(workspaceId);
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
    final existingTriggerKeys = (await _triggerRepository.forWorkspace(
      workspaceId,
    )).map((t) => '${t.templateId}|${t.eventType}').toSet();

    for (final seed in builtInTemplateSeeds(
      workspaceId: workspaceId,
      agentIds: ids,
    )) {
      await _upsertBuiltIn(seed);
      await _seedBuiltInTriggers(
        workspaceId: workspaceId,
        templateId: seed.templateId,
        existingKeys: existingTriggerKeys,
      );
    }
  }

  /// Installs a built-in [seed], leaving alone what belongs to the user.
  ///
  /// Two guards, both load-bearing now that this runs on every boot and not
  /// only at workspace creation:
  ///
  /// * A row whose `isBuiltIn` is false was **taken over by the user** — the
  ///   editor clears that flag when it saves an edited copy precisely so the
  ///   bootstrap cannot overwrite the change. Skip it entirely.
  /// * An untouched row that already equals the seed is left alone, so a boot
  ///   in steady state performs no writes at all (no `updatedAt` churn, no
  ///   sync-feed rows for every client). [PipelineDefinition]'s `==`
  ///   deliberately ignores `version`, which is what makes the comparison
  ///   answer "is this the same template?" rather than "was it rewritten?".
  ///
  /// An upgrade write preserves the user's `isEnabled` choice; `copyWith` keeps
  /// the seed's declared inputs and steps, so manual-run forms survive it.
  Future<void> _upsertBuiltIn(PipelineDefinition seed) async {
    final existing = await _templateRepository.getById(
      seed.workspaceId,
      seed.templateId,
    );
    if (existing != null && !existing.isBuiltIn) {
      return;
    }
    final next = seed.copyWith(
      isBuiltIn: true,
      isEnabled: existing?.isEnabled ?? seed.isEnabled,
    );
    if (existing == next) {
      return;
    }
    await _templateRepository.upsert(next);
  }

  /// Inserts any missing built-in trigger rows for [templateId]. Records
  /// inserted `templateId|eventType` keys in [existingKeys] so a single seed
  /// pass never double-inserts and so existing rows (with the user's
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
    final existing = await _triggerRepository.forWorkspace(workspaceId);
    for (final spec in specs) {
      final key = '$templateId|${spec.eventType}';
      if (existingKeys.contains(key)) {
        // One repair, deliberately narrow: the repository-cleanup sweep shipped
        // as an opt-in weekly schedule, so on every existing workspace the row
        // sits DISABLED and the garbage collection never runs — worktree rows,
        // their code-graph partitions and their CoW copies just accumulate
        // (117 rows on a real host). It was never a user choice, so a seed that
        // now ships it enabled repairs the row rather than leaving it dead.
        // Scoped to this one template + schedule trigger; every other trigger's
        // enable/disable state is still the user's.
        if (templateId == 'pr_merged_cleanup' &&
            spec.eventType == PipelineTrigger.scheduleEventType &&
            spec.enabled) {
          final row = existing
              .where(
                (t) =>
                    t.templateId == templateId &&
                    t.eventType == PipelineTrigger.scheduleEventType,
              )
              .firstOrNull;
          if (row != null && !row.enabled) {
            await _triggerRepository.update(row.copyWith(enabled: true));
          }
        }
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
    await _upsertBuiltIn(indexCodeTemplate(workspaceId));

    final existingKeys = (await _triggerRepository.forWorkspace(
      workspaceId,
    )).map((t) => '${t.templateId}|${t.eventType}').toSet();
    await _seedBuiltInTriggers(
      workspaceId: workspaceId,
      templateId: 'index_code',
      existingKeys: existingKeys,
    );
  }

  /// Ensures the agentless `skill_analysis` template (the skills antivirus as
  /// a pipeline) + its manual/`SkillUpdated` triggers exist for [workspaceId].
  ///
  /// PUBLIC (unlike [_ensureIndexCodeTemplate]) so a caller holding no agents
  /// can install it on its own. Read-only in steady state and never clobbers a
  /// user-owned copy — see [_upsertBuiltIn].
  Future<void> ensureSkillAnalysisTemplate(String workspaceId) async {
    final seed = skillAnalysisTemplate(workspaceId);
    await _upsertBuiltIn(seed);

    final existingKeys = (await _triggerRepository.forWorkspace(
      workspaceId,
    )).map((t) => '${t.templateId}|${t.eventType}').toSet();
    await _seedBuiltInTriggers(
      workspaceId: workspaceId,
      templateId: seed.templateId,
      existingKeys: existingKeys,
    );
  }
}
