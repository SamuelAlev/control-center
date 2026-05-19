import 'package:cc_domain/features/pipelines/domain/entities/pipeline_definition.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_input.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_definition.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_kind.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_trigger.dart';
import 'package:test/test.dart';

/// Round-trip and equality coverage for [PipelineDefinition] — the declarative
/// graph that gets exported/imported across workspaces, so its `toJson` /
/// `fromJson` and `==`/`copyWith` must be stable.
PipelineStepDefinition _step({
  required String id,
  StepKind kind = StepKind.listen,
  String bodyKey = 'pipeline.bashScript',
  List<StepTrigger> triggers = const [],
}) => PipelineStepDefinition(
  id: id,
  kind: kind,
  bodyKey: bodyKey,
  triggers: triggers,
);

void main() {
  group('PipelineDefinition construction', () {
    test('applies the documented defaults', () {
      final def = PipelineDefinition(
        templateId: 't1',
        workspaceId: 'ws-1',
        name: 'Demo',
        steps: const [],
      );
      expect(def.description, isNull);
      expect(def.inputs, isEmpty);
      expect(def.isBuiltIn, isFalse);
      expect(def.isEnabled, isTrue);
      expect(def.version, 1);
    });

    test('exportSchema is the documented envelope version', () {
      expect(PipelineDefinition.exportSchema, 1);
    });
  });

  group('PipelineDefinition.toJson / fromJson', () {
    final def = PipelineDefinition(
      templateId: 't1',
      workspaceId: 'ws-1',
      name: 'Demo',
      description: 'a demo',
      isBuiltIn: true,
      isEnabled: false,
      version: 4,
      inputs: [
        PipelineInput(key: 'repo_full_name', label: 'Repo', required: true),
      ],
      steps: [
        _step(
          id: 'trigger',
          kind: StepKind.trigger,
          bodyKey: 'pipeline.trigger',
        ),
        _step(
          id: 'setup',
          triggers: const [
            StepTrigger(sourceStepIds: ['trigger']),
          ],
        ),
        _step(
          id: 'setup\$terminal',
          kind: StepKind.terminal,
          bodyKey: '_terminal_setup',
          triggers: const [
            StepTrigger(sourceStepIds: ['setup']),
          ],
        ),
      ],
    );

    test('toJson carries the export envelope', () {
      final json = def.toJson();
      expect(json['export_schema'], PipelineDefinition.exportSchema);
      expect(json['template_id'], 't1');
      expect(json['workspace_id'], 'ws-1');
      expect(json['name'], 'Demo');
      expect(json['description'], 'a demo');
      expect(json['is_enabled'], isFalse);
      expect(json['version'], 4);
      expect((json['steps'] as List).length, 3);
      expect((json['inputs'] as List).length, 1);
    });

    test('fromJson round-trips without overrides (same workspace)', () {
      final rebuilt = PipelineDefinition.fromJson(def.toJson());
      expect(rebuilt.templateId, 't1');
      expect(rebuilt.workspaceId, 'ws-1');
      expect(rebuilt.name, 'Demo');
      expect(rebuilt.description, 'a demo');
      expect(rebuilt.version, 4);
      expect(rebuilt.isEnabled, isFalse);
      // isBuiltIn is always cleared on import.
      expect(rebuilt.isBuiltIn, isFalse);
      expect(rebuilt.steps.length, 3);
      expect(rebuilt.inputs.single.key, 'repo_full_name');
    });

    test('fromJson honors templateId / workspaceId overrides', () {
      final rebuilt = PipelineDefinition.fromJson(
        def.toJson(),
        templateId: 'imported',
        workspaceId: 'ws-2',
      );
      expect(rebuilt.templateId, 'imported');
      expect(rebuilt.workspaceId, 'ws-2');
    });

    test('fromJson tolerates a missing description and null steps/inputs', () {
      final rebuilt = PipelineDefinition.fromJson({
        'template_id': 't2',
        'workspace_id': 'ws-1',
        'name': 'No frills',
        // description omitted, steps/inputs omitted, is_enabled omitted
      });
      expect(rebuilt.description, isNull);
      expect(rebuilt.steps, isEmpty);
      expect(rebuilt.inputs, isEmpty);
      expect(rebuilt.isEnabled, isTrue);
      expect(rebuilt.version, 1);
    });

    test('toJson omits description when null', () {
      final json = PipelineDefinition(
        templateId: 't1',
        workspaceId: 'ws-1',
        name: 'No desc',
        steps: const [],
      ).toJson();
      expect(json.containsKey('description'), isFalse);
    });

    test('fromJson filters non-Map entries in steps/inputs', () {
      final rebuilt = PipelineDefinition.fromJson({
        'template_id': 't1',
        'workspace_id': 'ws-1',
        'name': 'Junk',
        'steps': [
          'not-a-map',
          {'id': 's1', 'kind': 'listen', 'body_key': 'b'},
        ],
        'inputs': ['also-not-a-map'],
      });
      expect(rebuilt.steps, hasLength(1));
      expect(rebuilt.steps.single.id, 's1');
      expect(rebuilt.inputs, isEmpty);
    });
  });

  group('PipelineDefinition lookups', () {
    final def = PipelineDefinition(
      templateId: 't1',
      workspaceId: 'ws-1',
      name: 'Demo',
      steps: [
        _step(
          id: 'trigger',
          kind: StepKind.trigger,
          bodyKey: 'pipeline.trigger',
        ),
        _step(
          id: 'setup',
          triggers: const [
            StepTrigger(sourceStepIds: ['trigger']),
          ],
        ),
        _step(
          id: 'a',
          triggers: const [
            StepTrigger(sourceStepIds: ['setup']),
          ],
        ),
        _step(
          id: 'b',
          triggers: const [
            StepTrigger(sourceStepIds: ['setup']),
          ],
        ),
        _step(
          id: 'a\$terminal',
          kind: StepKind.terminal,
          bodyKey: '_terminal_a',
          triggers: const [
            StepTrigger(sourceStepIds: ['a']),
          ],
        ),
      ],
    );

    test('step(id) returns the matching step or null', () {
      expect(def.step('setup')?.id, 'setup');
      expect(def.step('missing'), isNull);
    });

    test('entryStep returns the trigger', () {
      expect(def.entryStep.kind, StepKind.trigger);
    });

    test('entryStep throws when there is no trigger step', () {
      final noTrigger = PipelineDefinition(
        templateId: 't1',
        workspaceId: 'ws-1',
        name: 'No trigger',
        steps: [_step(id: 'setup')],
      );
      expect(() => noTrigger.entryStep, throwsStateError);
    });

    test('listenersOf returns every step that listens to a source', () {
      expect(def.listenersOf('setup').map((s) => s.id).toSet(), {'a', 'b'});
      expect(def.listenersOf('a').map((s) => s.id).toList(), ['a\$terminal']);
      expect(def.listenersOf('unknown'), isEmpty);
    });
  });

  group('PipelineDefinition copyWith', () {
    final base = PipelineDefinition(
      templateId: 't1',
      workspaceId: 'ws-1',
      name: 'Demo',
      description: 'desc',
      isBuiltIn: true,
      isEnabled: true,
      version: 1,
      steps: [
        _step(
          id: 'trigger',
          kind: StepKind.trigger,
          bodyKey: 'pipeline.trigger',
        ),
      ],
    );

    test('a single-field copy preserves every other field', () {
      final next = base.copyWith(isEnabled: false);
      expect(next.isEnabled, isFalse);
      // Preserved.
      expect(next.templateId, 't1');
      expect(next.workspaceId, 'ws-1');
      expect(next.name, 'Demo');
      expect(next.description, 'desc');
      expect(next.isBuiltIn, isTrue);
      expect(next.version, 1);
      expect(next.steps.single.id, 'trigger');
    });

    test('overrides every copyWith parameter', () {
      final next = base.copyWith(
        name: 'Renamed',
        description: 'new desc',
        steps: [
          _step(
            id: 'trigger2',
            kind: StepKind.trigger,
            bodyKey: 'pipeline.trigger',
          ),
        ],
        inputs: [PipelineInput(key: 'k')],
        isBuiltIn: false,
        isEnabled: false,
        version: 9,
      );
      expect(next.name, 'Renamed');
      expect(next.description, 'new desc');
      expect(next.steps.single.id, 'trigger2');
      expect(next.inputs.single.key, 'k');
      expect(next.isBuiltIn, isFalse);
      expect(next.isEnabled, isFalse);
      expect(next.version, 9);
      // templateId/workspaceId are immutable through copyWith.
      expect(next.templateId, 't1');
      expect(next.workspaceId, 'ws-1');
    });

    test('a no-op copy is equal to the original', () {
      expect(base.copyWith(), base);
    });
  });

  group('PipelineDefinition == / hashCode', () {
    final a = PipelineDefinition(
      templateId: 't1',
      workspaceId: 'ws-1',
      name: 'Demo',
      steps: [
        _step(
          id: 'trigger',
          kind: StepKind.trigger,
          bodyKey: 'pipeline.trigger',
        ),
      ],
    );
    final b = PipelineDefinition(
      templateId: 't1',
      workspaceId: 'ws-1',
      name: 'Demo',
      steps: [
        _step(
          id: 'trigger',
          kind: StepKind.trigger,
          bodyKey: 'pipeline.trigger',
        ),
      ],
    );

    test('equal definitions match', () {
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('a different isEnabled makes them unequal', () {
      expect(a == b.copyWith(isEnabled: false), isFalse);
    });

    test('a different steps list makes them unequal', () {
      expect(
        a ==
            b.copyWith(
              steps: [
                _step(
                  id: 'other',
                  kind: StepKind.trigger,
                  bodyKey: 'pipeline.trigger',
                ),
              ],
            ),
        isFalse,
      );
    });

    test('is not equal to an unrelated type', () {
      expect(a == Object(), isFalse);
    });
  });
}
