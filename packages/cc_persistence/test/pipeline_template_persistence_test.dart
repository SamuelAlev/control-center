import 'package:cc_domain/features/pipelines/domain/entities/step_kind.dart';
import 'package:cc_domain/features/pipelines/domain/templates/builtin_template_seeds.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:test/test.dart';

import 'helpers/test_database.dart';

void main() {
  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;
  late PipelineTemplateRepositoryImpl repo;

  setUp(() {
    global = createTestGlobalDatabase();
    dbs = createTestWorkspaceDatabases(global: global);
    repo = PipelineTemplateRepositoryImpl(dbs);
  });

  tearDown(() async {
    await dbs.closeAll();
    await global.close();
  });

  const ids = BuiltInAgentIds(
    qa: 'qa',
    architect: 'arch',
    engineer: 'eng',
    librarian: 'lib',
    ceo: 'ceo',
  );

  test('built-in template inputs survive a persistence round-trip', () async {
    final seeds = builtInTemplateSeeds(workspaceId: 'w', agentIds: ids);
    for (final seed in seeds) {
      await repo.upsert(seed);
      final loaded = await repo.getById('w', seed.templateId);
      expect(loaded, isNotNull, reason: '${seed.templateId} not persisted');
      expect(
        loaded!.inputs.map((i) => i.key).toList(),
        seed.inputs.map((i) => i.key).toList(),
        reason: '${seed.templateId} lost its declared inputs on round-trip',
      );
      // The entry node is always the trigger and survives persistence.
      expect(
        loaded.steps.first.kind,
        StepKind.trigger,
        reason: '${seed.templateId} first step is not a trigger',
      );
    }
  });

  test('re-upsert (reseed) refreshes inputs on an existing row', () async {
    final seeds = builtInTemplateSeeds(workspaceId: 'w', agentIds: ids);
    final depAudit = seeds.firstWhere((s) => s.templateId == 'dep_audit');
    // Simulate a stale row that predates declared inputs.
    await repo.upsert(depAudit.copyWith(inputs: const []));
    expect((await repo.getById('w', 'dep_audit'))!.inputs, isEmpty);
    // Reseed (preserving enabled, as the bootstrap does) restores inputs.
    await repo.upsert(depAudit.copyWith(isEnabled: false));
    final loaded = await repo.getById('w', 'dep_audit');
    expect(loaded!.inputs.map((i) => i.key), contains('repo_full_name'));
  });

  test('the run-concurrency cap survives a round-trip and can be cleared', () async {
    final seed = builtInTemplateSeeds(
      workspaceId: 'w',
      agentIds: ids,
    ).firstWhere((s) => s.templateId == 'index_code');
    expect(seed.maxParallelRuns, 1, reason: 'index_code ships capped at 1');

    await repo.upsert(seed);
    expect((await repo.getById('w', 'index_code'))!.maxParallelRuns, 1);

    // Clearing the cap must actually write NULL, not keep the stored value:
    // `copyWith` treats an omitted cap as "unchanged", so the explicit null is
    // the only way a user goes back to unlimited.
    await repo.upsert(seed.copyWith(maxParallelRuns: null));
    expect((await repo.getById('w', 'index_code'))!.maxParallelRuns, isNull);
  });

  test('every built-in seed is value-identical after a round-trip', () async {
    // The boot reconcile (`WorkspaceSeeder.reseedTemplates`) decides whether to
    // write by comparing the seed with the installed row, so a seed that does
    // not read back equal would be rewritten on every single launch — churning
    // `updatedAt` and pushing a sync-feed row to every client for a template
    // that never changed. Authoring a graph the mapper cannot represent
    // exactly (e.g. several unconditional triggers on one step, which load
    // regroups into one) is what breaks this.
    final seeds = [
      ...builtInTemplateSeeds(workspaceId: 'w', agentIds: ids),
      skillAnalysisTemplate('w'),
    ];
    for (final seed in seeds) {
      final builtIn = seed.copyWith(isBuiltIn: true);
      await repo.upsert(builtIn);
      expect(
        await repo.getById('w', seed.templateId),
        builtIn,
        reason:
            '${seed.templateId} does not survive persistence by value, so the '
            'boot reconcile would rewrite it on every launch',
      );
    }
  });
}
