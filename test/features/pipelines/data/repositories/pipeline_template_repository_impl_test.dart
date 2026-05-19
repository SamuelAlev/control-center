import 'package:control_center/core/database/app_database.dart';
import 'package:control_center/core/database/daos/pipeline_template_dao.dart';
import 'package:control_center/features/pipelines/data/repositories/pipeline_template_repository_impl.dart';
import 'package:control_center/features/pipelines/domain/entities/pipeline_definition.dart';
import 'package:control_center/features/pipelines/domain/entities/pipeline_step_definition.dart';
import 'package:control_center/features/pipelines/domain/entities/step_kind.dart';
import 'package:control_center/features/pipelines/domain/entities/step_trigger.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_database.dart';

PipelineDefinition _makeDef({
  String id = 'tpl-1',
  String workspaceId = 'ws-1',
  String name = 'Test Pipeline',
  String? description = 'A test',
  bool builtIn = false,
}) {
  final steps = [
    PipelineStepDefinition(
      id: 'trigger',
      kind: StepKind.trigger,
      bodyKey: 'pipeline.trigger',
    ),
    PipelineStepDefinition(
      id: 'step1',
      kind: StepKind.listen,
      bodyKey: 'pipeline.promptAgent',
      triggers: [const StepTrigger(sourceStepIds: ['trigger'])],
    ),
  ];
  return PipelineDefinition(
    templateId: id,
    workspaceId: workspaceId,
    name: name,
    description: description,
    steps: steps,
    isBuiltIn: builtIn,
    isEnabled: true,
    version: 1,
  );
}

void main() {
  late AppDatabase db;
  late PipelineTemplateRepositoryImpl repo;
  late PipelineTemplateDao dao;

  setUp(() async {
    db = createTestDatabase();
    dao = PipelineTemplateDao(db);
    repo = PipelineTemplateRepositoryImpl(dao);
  });

  tearDown(() async {
    await db.close();
  });

  group('upsert', () {
    test('inserts a new template', () async {
      final def = _makeDef();
      await repo.upsert(def);

      final result = await repo.getById('ws-1', 'tpl-1');
      expect(result, isNotNull);
      expect(result!.name, 'Test Pipeline');
      expect(result.steps.length, 2);
    });

    test('updates an existing template increments version', () async {
      await repo.upsert(_makeDef());

      final updated = _makeDef(name: 'Updated Pipeline');
      await repo.upsert(updated);

      final result = await repo.getById('ws-1', 'tpl-1');
      expect(result!.name, 'Updated Pipeline');
      // Version should have incremented
      expect(result.version, 2);
    });

    test('built-in templates keep version 1', () async {
      final def = _makeDef(builtIn: true);
      await repo.upsert(def);

      // Upsert again — built-in stays at version 1
      await repo.upsert(_makeDef(id: 'tpl-1', workspaceId: 'ws-1', builtIn: true, name: 'New Name'));

      final result = await repo.getById('ws-1', 'tpl-1');
      expect(result!.version, 1);
    });

    test('throws validation error on invalid non-built-in template', () async {
      // A template with no trigger step is invalid
      final invalidDef = PipelineDefinition(
        templateId: 'bad-1',
        workspaceId: 'ws-1',
        name: 'Bad Pipeline',
        steps: [
          PipelineStepDefinition(
            id: 'step1',
            kind: StepKind.listen,
            bodyKey: 'pipeline.promptAgent',
            // No triggers, no trigger node — invalid
          ),
        ],
        isBuiltIn: false,
        isEnabled: true,
        version: 1,
      );

      expect(
        () => repo.upsert(invalidDef),
        throwsA(isA<Exception>()),
      );
    });

    test('built-in templates bypass validation', () async {
      final builtIn = PipelineDefinition(
        templateId: 'builtin-1',
        workspaceId: 'ws-1',
        name: 'Built-in',
        steps: [
          PipelineStepDefinition(
            id: 'step1',
            kind: StepKind.listen,
            bodyKey: 'pipeline.promptAgent',
          ),
        ],
        isBuiltIn: true,
        isEnabled: true,
        version: 1,
      );
      // Should not throw even though it lacks a trigger
      await repo.upsert(builtIn);
      final result = await repo.getById('ws-1', 'builtin-1');
      expect(result, isNotNull);
    });
  });

  group('getById', () {
    test('returns null for unknown template', () async {
      final result = await repo.getById('ws-1', 'nonexistent');
      expect(result, isNull);
    });

    test('scoped to workspace', () async {
      await repo.upsert(_makeDef(id: 't-1', workspaceId: 'ws-1'));
      final result = await repo.getById('ws-2', 't-1');
      expect(result, isNull);
    });
  });

  group('forWorkspace', () {
    test('returns templates scoped to workspace', () async {
      await repo.upsert(_makeDef(id: 'a', workspaceId: 'ws-1', name: 'Alpha'));
      await repo.upsert(_makeDef(id: 'b', workspaceId: 'ws-1', name: 'Beta'));
      await repo.upsert(_makeDef(id: 'c', workspaceId: 'ws-2', name: 'Gamma'));

      final ws1 = await repo.forWorkspace('ws-1');
      expect(ws1.length, 2);

      final ws2 = await repo.forWorkspace('ws-2');
      expect(ws2.length, 1);
    });

    test('returns empty for unused workspace', () async {
      final results = await repo.forWorkspace('empty');
      expect(results, isEmpty);
    });
  });

  group('deleteById', () {
    test('removes template', () async {
      await repo.upsert(_makeDef());
      await repo.deleteById('ws-1', 'tpl-1');

      final result = await repo.getById('ws-1', 'tpl-1');
      expect(result, isNull);
    });

    test('returns 0 for nonexistent template', () async {
      final count = await repo.deleteById('ws-1', 'nonexistent');
      expect(count, 0);
    });
  });

  group('watchForWorkspace', () {
    test('emits current templates', () async {
      await repo.upsert(_makeDef());

      final results = await repo.watchForWorkspace('ws-1').first;
      expect(results.length, 1);
    });
  });
}
