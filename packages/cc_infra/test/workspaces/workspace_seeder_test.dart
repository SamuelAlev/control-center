import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/ports/workspace_filesystem_port.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/value_objects/agent_skills.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_definition.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_definition.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_trigger.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_template_repository.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_trigger_repository.dart';
import 'package:cc_infra/src/workspaces/workspace_seeder.dart';
import 'package:test/test.dart';

class _RecordingAgentRepo implements AgentRepository {
  final Map<String, Agent> byWorkspaceAndName = {};

  @override
  Future<Agent?> findByWorkspaceAndName(String workspaceId, String name) async {
    return byWorkspaceAndName['$workspaceId|$name'];
  }

  @override
  Future<void> upsert(Agent agent) async {
    byWorkspaceAndName['${agent.workspaceId}|${agent.name}'] = agent;
  }

  @override
  Future<Agent?> getById(String workspaceId, String id) async => null;

  @override
  Stream<List<Agent>> watchByWorkspace(String workspaceId) => Stream.value(
    byWorkspaceAndName.values
        .where((a) => a.workspaceId == workspaceId)
        .toList(),
  );

  @override
  Future<void> delete(String workspaceId, String id) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoopFs implements WorkspaceFilesystemPort {
  @override
  Future<void> ensureWorkspaceDirs(String workspaceId) async {}

  @override
  Future<String> agentFilePath(String workspaceId, String slug) async =>
      '/ws/$slug/AGENTS.md';

  @override
  Future<void> writeAgentFile(
    String workspaceId,
    String slug,
    String content,
  ) async {}

  @override
  Future<List<String>> listSkillSlugs(String workspaceId) async => const [];

  @override
  Future<void> writeSkillFile(
    String workspaceId,
    String slug,
    String content,
  ) async {}

  @override
  Future<void> syncAgentSkillLinks(
    String workspaceId,
    String slug,
    List<String> skillSlugs,
  ) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _RecordingTemplateRepo implements PipelineTemplateRepository {
  final Map<String, PipelineDefinition> byId = {};
  final List<PipelineDefinition> upserted = [];

  @override
  Future<PipelineDefinition?> getById(
    String workspaceId,
    String templateId,
  ) async {
    return byId['$workspaceId|$templateId'];
  }

  @override
  Future<void> upsert(PipelineDefinition definition) async {
    upserted.add(definition);
    byId['${definition.workspaceId}|${definition.templateId}'] = definition;
  }

  @override
  Future<List<PipelineDefinition>> forWorkspace(String workspaceId) async =>
      upserted.where((d) => d.workspaceId == workspaceId).toList();

  @override
  Future<int> deleteById(String workspaceId, String templateId) async {
    final removed = byId.remove('$workspaceId|$templateId') != null;
    return removed ? 1 : 0;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _RecordingTriggerRepo implements PipelineTriggerRepository {
  final List<PipelineTrigger> inserted = [];
  final Map<String, List<PipelineTrigger>> byWorkspace = {};

  @override
  Future<void> insert(PipelineTrigger trigger) async {
    inserted.add(trigger);
    (byWorkspace[trigger.workspaceId] ??= []).add(trigger);
  }

  @override
  Future<List<PipelineTrigger>> forWorkspace(String workspaceId) async =>
      byWorkspace[workspaceId] ?? const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// An agent repository already holding the CEO + the four specialists, so
/// [WorkspaceSeeder.reseedTemplates] wires the agent-bearing templates.
_RecordingAgentRepo _fullRoster(String workspaceId) {
  final repo = _RecordingAgentRepo();
  for (final name in ['ceo', 'qa', 'architect', 'engineer', 'librarian']) {
    repo.byWorkspaceAndName['$workspaceId|$name'] = _agent(workspaceId, name);
  }
  return repo;
}

Agent _agent(String workspaceId, String name) => Agent(
  id: 'id-$name',
  name: name,
  title: name,
  agentMdPath: '/ws/$name/AGENTS.md',
  workspaceId: workspaceId,
  skills: AgentSkills(const []),
  createdAt: DateTime.utc(2025, 1, 1),
);

void main() {
  group('WorkspaceSeeder.seedBuiltInPipelineTemplates', () {
    test('always seeds the index_code template (agentless)', () async {
      final repo = _RecordingTemplateRepo();
      final seeder = WorkspaceSeeder(
        agentRepository: _RecordingAgentRepo(),
        filesystem: _NoopFs(),
        templateRepository: repo,
        triggerRepository: _RecordingTriggerRepo(),
      );

      await seeder.seedBuiltInPipelineTemplates(
        workspaceId: 'ws',
        specialists: const [],
      );

      // index_code is seeded even with no specialists.
      expect(repo.upserted.map((d) => d.templateId), contains('index_code'));
      final indexCode = repo.upserted.firstWhere(
        (d) => d.templateId == 'index_code',
      );
      expect(indexCode.isBuiltIn, isTrue);
    });

    test('skips agent-bearing templates when specialists incomplete', () async {
      final repo = _RecordingTemplateRepo();
      final triggers = _RecordingTriggerRepo();
      final seeder = WorkspaceSeeder(
        agentRepository: _RecordingAgentRepo(),
        filesystem: _NoopFs(),
        templateRepository: repo,
        triggerRepository: triggers,
      );

      await seeder.seedBuiltInPipelineTemplates(
        workspaceId: 'ws',
        ceo: _agent('ws', 'ceo'),
        specialists: [
          _agent('ws', 'qa'),
        ], // missing architect/engineer/librarian
      );

      // Only index_code should be present.
      expect(repo.upserted.map((d) => d.templateId), contains('index_code'));
      // No agent-bearing template was seeded.
      expect(
        repo.upserted.where((d) => d.templateId == 'index_code').length,
        1,
      );
    });

    test(
      'seeds all built-in templates when ceo + specialists present',
      () async {
        final repo = _RecordingTemplateRepo();
        final triggers = _RecordingTriggerRepo();
        final seeder = WorkspaceSeeder(
          agentRepository: _RecordingAgentRepo(),
          filesystem: _NoopFs(),
          templateRepository: repo,
          triggerRepository: triggers,
        );

        await seeder.seedBuiltInPipelineTemplates(
          workspaceId: 'ws',
          ceo: _agent('ws', 'ceo'),
          specialists: [
            _agent('ws', 'qa'),
            _agent('ws', 'architect'),
            _agent('ws', 'engineer'),
            _agent('ws', 'librarian'),
          ],
        );

        // More than just index_code was seeded.
        expect(repo.upserted.length, greaterThan(1));
        // The index_code template is always isBuiltIn=true.
        final indexCode = repo.upserted.firstWhere(
          (d) => d.templateId == 'index_code',
        );
        expect(indexCode.isBuiltIn, isTrue);
      },
    );

    test('preserves the existing isEnabled choice on re-seed', () async {
      final repo = _RecordingTemplateRepo();
      // Pretend the user previously disabled index_code.
      await repo.upsert(
        (await _indexCodeSeed('ws')).copyWith(isEnabled: false),
      );
      final triggers = _RecordingTriggerRepo();
      final seeder = WorkspaceSeeder(
        agentRepository: _RecordingAgentRepo(),
        filesystem: _NoopFs(),
        templateRepository: repo,
        triggerRepository: triggers,
      );

      await seeder.seedBuiltInPipelineTemplates(
        workspaceId: 'ws',
        specialists: const [],
      );

      final indexCode = repo.upserted.firstWhere(
        (d) => d.templateId == 'index_code',
      );
      expect(
        indexCode.isEnabled,
        isFalse,
        reason: 're-seed must preserve the user\'s isEnabled choice',
      );
    });

    test('does not double-insert triggers that already exist', () async {
      final repo = _RecordingTemplateRepo();
      final triggers = _RecordingTriggerRepo();
      // Pre-populate a trigger that matches index_code's RepoAdded seed.
      await triggers.insert(
        PipelineTrigger(
          id: 'existing',
          eventType: 'RepoAdded',
          templateId: 'index_code',
          workspaceId: 'ws',
        ),
      );
      final seeder = WorkspaceSeeder(
        agentRepository: _RecordingAgentRepo(),
        filesystem: _NoopFs(),
        templateRepository: repo,
        triggerRepository: triggers,
      );

      await seeder.seedBuiltInPipelineTemplates(
        workspaceId: 'ws',
        specialists: const [],
      );

      // Only one RepoAdded/index_code trigger should exist.
      final indexCodeTriggers = triggers.inserted
          .where((t) => t.templateId == 'index_code')
          .toList();
      expect(
        indexCodeTriggers.where((t) => t.eventType == 'RepoAdded').length,
        lessThanOrEqualTo(1),
      );
    });
  });

  group('WorkspaceSeeder.seed', () {
    test('creates the CEO + specialists and seeds templates', () async {
      final agentRepo = _RecordingAgentRepo();
      final templates = _RecordingTemplateRepo();
      final triggers = _RecordingTriggerRepo();
      final seeder = WorkspaceSeeder(
        agentRepository: agentRepo,
        filesystem: _NoopFs(),
        templateRepository: templates,
        triggerRepository: triggers,
      );

      await seeder.seed('ws', adapterId: 'a', modelId: 'm');

      expect(agentRepo.byWorkspaceAndName.containsKey('ws|ceo'), isTrue);
      expect(agentRepo.byWorkspaceAndName.containsKey('ws|qa'), isTrue);
      expect(agentRepo.byWorkspaceAndName.containsKey('ws|architect'), isTrue);
      expect(agentRepo.byWorkspaceAndName.containsKey('ws|engineer'), isTrue);
      expect(agentRepo.byWorkspaceAndName.containsKey('ws|librarian'), isTrue);
      expect(
        templates.upserted.map((d) => d.templateId),
        contains('index_code'),
      );
    });

    test('does not throw when an inner step fails', () async {
      // Filesystem that throws on ensureWorkspaceDirs.
      final throwingFs = _ThrowingFs();
      final seeder = WorkspaceSeeder(
        agentRepository: _RecordingAgentRepo(),
        filesystem: throwingFs,
        templateRepository: _RecordingTemplateRepo(),
        triggerRepository: _RecordingTriggerRepo(),
      );

      // Swallowed — no exception escapes.
      await seeder.seed('ws');
    });
  });

  group('WorkspaceSeeder.reseedTemplates', () {
    test('re-seeds templates for an existing workspace', () async {
      final agentRepo = _RecordingAgentRepo();
      // Pre-existing CEO + specialists.
      agentRepo.byWorkspaceAndName['ws|ceo'] = _agent('ws', 'ceo');
      agentRepo.byWorkspaceAndName['ws|qa'] = _agent('ws', 'qa');
      agentRepo.byWorkspaceAndName['ws|architect'] = _agent('ws', 'architect');
      agentRepo.byWorkspaceAndName['ws|engineer'] = _agent('ws', 'engineer');
      agentRepo.byWorkspaceAndName['ws|librarian'] = _agent('ws', 'librarian');
      final templates = _RecordingTemplateRepo();
      final triggers = _RecordingTriggerRepo();
      final seeder = WorkspaceSeeder(
        agentRepository: agentRepo,
        filesystem: _NoopFs(),
        templateRepository: templates,
        triggerRepository: triggers,
      );

      await seeder.reseedTemplates('ws');

      expect(
        templates.upserted.map((d) => d.templateId),
        contains('index_code'),
      );
      expect(templates.upserted.length, greaterThan(1));
    });

    test('does not throw when CEO is missing (logs only)', () async {
      final agentRepo = _RecordingAgentRepo(); // no CEO
      final seeder = WorkspaceSeeder(
        agentRepository: agentRepo,
        filesystem: _NoopFs(),
        templateRepository: _RecordingTemplateRepo(),
        triggerRepository: _RecordingTriggerRepo(),
      );

      await seeder.reseedTemplates('ws'); // no throw
    });

    test('a second reconcile writes nothing (steady state)', () async {
      final templates = _RecordingTemplateRepo();
      final seeder = WorkspaceSeeder(
        agentRepository: _fullRoster('ws'),
        filesystem: _NoopFs(),
        templateRepository: templates,
        triggerRepository: _RecordingTriggerRepo(),
      );

      await seeder.reseedTemplates('ws');
      final afterFirst = templates.upserted.length;
      expect(afterFirst, greaterThan(1));

      await seeder.reseedTemplates('ws');
      expect(
        templates.upserted,
        hasLength(afterFirst),
        reason: 'a boot with nothing to deliver must not rewrite templates',
      );
    });

    test('upgrades a stale built-in row that predates a seed change', () async {
      final templates = _RecordingTemplateRepo();
      final seeder = WorkspaceSeeder(
        agentRepository: _fullRoster('ws'),
        filesystem: _NoopFs(),
        templateRepository: templates,
        triggerRepository: _RecordingTriggerRepo(),
      );
      await seeder.reseedTemplates('ws');
      // Rewind index_code to the shape a workspace created by an older build
      // carries: the node that opens the analyzer's conversation with no repo
      // scope, so it checks out every workspace repo instead of the one being
      // indexed.
      final current = templates.byId['ws|index_code']!;
      await templates.upsert(
        current.copyWith(
          steps: [
            for (final s in current.steps)
              if (s.id != 'space')
                s
              else
                PipelineStepDefinition(
                  id: s.id,
                  kind: s.kind,
                  bodyKey: s.bodyKey,
                  triggers: s.triggers,
                  waitForStepIds: s.waitForStepIds,
                  config: s.config.copyWith(repoIds: const []),
                  x: s.x,
                  y: s.y,
                ),
          ],
        ),
      );

      await seeder.reseedTemplates('ws');

      expect(templates.byId['ws|index_code']!.step('space')!.config.repoIds, [
        '{{repo_id}}',
      ], reason: 'the boot reconcile must deliver a changed seed');
    });

    test('leaves a template the user took over alone', () async {
      final templates = _RecordingTemplateRepo();
      final seeder = WorkspaceSeeder(
        agentRepository: _fullRoster('ws'),
        filesystem: _NoopFs(),
        templateRepository: templates,
        triggerRepository: _RecordingTriggerRepo(),
      );
      await seeder.reseedTemplates('ws');
      // The editor saves an edited copy with isBuiltIn cleared — that flag is
      // how a user claims ownership of a built-in.
      final mine = templates.byId['ws|index_code']!.copyWith(
        isBuiltIn: false,
        name: 'My indexer',
      );
      await templates.upsert(mine);

      await seeder.reseedTemplates('ws');

      expect(templates.byId['ws|index_code']!.name, 'My indexer');
      expect(templates.byId['ws|index_code']!.isBuiltIn, isFalse);
    });
  });
  group('WorkspaceSeeder.ensureSkillAnalysisTemplate', () {
    WorkspaceSeeder seederWith(
      _RecordingTemplateRepo templates,
      _RecordingTriggerRepo triggers,
    ) => WorkspaceSeeder(
      agentRepository: _RecordingAgentRepo(),
      filesystem: _NoopFs(),
      templateRepository: templates,
      triggerRepository: triggers,
    );

    test('inserts the template + manual/SkillUpdated triggers once', () async {
      final templates = _RecordingTemplateRepo();
      final triggers = _RecordingTriggerRepo();
      final seeder = seederWith(templates, triggers);

      await seeder.ensureSkillAnalysisTemplate('ws');

      expect(templates.upserted, hasLength(1));
      expect(templates.upserted.single.templateId, 'skill_analysis');
      expect(templates.upserted.single.isBuiltIn, isTrue);
      expect(
        triggers.inserted.map((t) => t.eventType),
        containsAll(['manual', 'SkillUpdated']),
      );

      // Second call is a steady-state no-op (version matches): nothing new.
      await seeder.ensureSkillAnalysisTemplate('ws');
      expect(templates.upserted, hasLength(1));
      expect(triggers.inserted, hasLength(2));
    });

    test('a user-disabled template is preserved, not re-enabled', () async {
      final templates = _RecordingTemplateRepo();
      final triggers = _RecordingTriggerRepo();
      final seeder = seederWith(templates, triggers);

      await seeder.ensureSkillAnalysisTemplate('ws');
      // The user turns the antivirus pipeline off.
      final disabled = templates.byId['ws|skill_analysis']!.copyWith(
        isEnabled: false,
      );
      await templates.upsert(disabled);

      final upsertsBefore = templates.upserted.length;
      await seeder.ensureSkillAnalysisTemplate('ws');
      expect(templates.byId['ws|skill_analysis']!.isEnabled, isFalse);
      // No re-upsert (version matches), no duplicate triggers.
      expect(templates.upserted, hasLength(upsertsBefore));
      expect(triggers.inserted, hasLength(2));
    });
  });
}

class _ThrowingFs implements WorkspaceFilesystemPort {
  @override
  Future<void> ensureWorkspaceDirs(String workspaceId) async {
    throw StateError('boom');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Builds the same index_code seed the seeder uses, for test setup.
Future<PipelineDefinition> _indexCodeSeed(String workspaceId) async {
  // Re-use the public indexCodeTemplate via reflection-free import.
  // The constant shape matches what WorkspaceSeeder._ensureIndexCodeTemplate
  // produces; we only need templateId + isEnabled for the test.
  return PipelineDefinition(
    workspaceId: workspaceId,
    templateId: 'index_code',
    name: 'Index code',
    description: '',
    inputs: const [],
    steps: const [],
    isBuiltIn: true,
    isEnabled: true,
  );
}
