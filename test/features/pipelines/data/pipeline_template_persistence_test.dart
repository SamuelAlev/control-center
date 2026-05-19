import 'package:control_center/core/database/app_database.dart';
import 'package:control_center/features/pipelines/data/repositories/pipeline_template_repository_impl.dart';
import 'package:control_center/features/pipelines/domain/entities/step_kind.dart';
import 'package:control_center/features/pipelines/domain/templates/builtin_template_seeds.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late PipelineTemplateRepositoryImpl repo;

  setUp(() {
    db = createTestDatabase();
    repo = PipelineTemplateRepositoryImpl(db.pipelineTemplateDao);
  });

  tearDown(() => db.close());

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
      expect(loaded.steps.first.kind, StepKind.trigger,
          reason: '${seed.templateId} first step is not a trigger');
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
    expect(loaded!.inputs.map((i) => i.key), contains('repoFullName'));
  });
}
