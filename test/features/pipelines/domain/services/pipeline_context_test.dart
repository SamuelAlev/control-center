import 'package:control_center/features/pipelines/domain/services/pipeline_context.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PipelineContext', () {
    // ---------------------------------------------------------------------------
    // Constructor
    // ---------------------------------------------------------------------------
    group('constructor', () {
      test('stores all fields', () {
        const ctx = PipelineContext(
          pipelineRunId: 'run-1',
          templateId: 'tpl-a',
          stepId: 'step-x',
          stepRunId: 'srun-1',
          workspaceId: 'ws-1',
          state: {'greeting': 'hello'},
          triggerPayload: {'issueId': 42},
          dryRun: true,
        );

        expect(ctx.pipelineRunId, 'run-1');
        expect(ctx.templateId, 'tpl-a');
        expect(ctx.stepId, 'step-x');
        expect(ctx.stepRunId, 'srun-1');
        expect(ctx.workspaceId, 'ws-1');
        expect(ctx.state, {'greeting': 'hello'});
        expect(ctx.triggerPayload, {'issueId': 42});
        expect(ctx.dryRun, isTrue);
      });

      test('dryRun defaults to false', () {
        const ctx = PipelineContext(
          pipelineRunId: 'run-1',
          templateId: 'tpl-a',
          stepId: 'step-x',
          stepRunId: 'srun-1',
          workspaceId: 'ws-1',
          state: {},
        );

        expect(ctx.dryRun, isFalse);
      });

      test('triggerPayload defaults to null', () {
        const ctx = PipelineContext(
          pipelineRunId: 'run-1',
          templateId: 'tpl-a',
          stepId: 'step-x',
          stepRunId: 'srun-1',
          workspaceId: 'ws-1',
          state: {},
        );

        expect(ctx.triggerPayload, isNull);
      });
    });

    // ---------------------------------------------------------------------------
    // requireString
    // ---------------------------------------------------------------------------
    group('requireString', () {
      test('returns value from state', () {
        const ctx = PipelineContext(
          pipelineRunId: 'run-1',
          templateId: 'tpl-a',
          stepId: 'step-x',
          stepRunId: 'srun-1',
          workspaceId: 'ws-1',
          state: {'branch': 'main'},
        );

        expect(ctx.requireString('branch'), 'main');
      });

      test('falls back to triggerPayload', () {
        const ctx = PipelineContext(
          pipelineRunId: 'run-1',
          templateId: 'tpl-a',
          stepId: 'step-x',
          stepRunId: 'srun-1',
          workspaceId: 'ws-1',
          state: {},
          triggerPayload: {'branch': 'develop'},
        );

        expect(ctx.requireString('branch'), 'develop');
      });

      test('state takes precedence over triggerPayload', () {
        const ctx = PipelineContext(
          pipelineRunId: 'run-1',
          templateId: 'tpl-a',
          stepId: 'step-x',
          stepRunId: 'srun-1',
          workspaceId: 'ws-1',
          state: {'branch': 'main'},
          triggerPayload: {'branch': 'develop'},
        );

        expect(ctx.requireString('branch'), 'main');
      });

      test('throws StateError for missing key', () {
        const ctx = PipelineContext(
          pipelineRunId: 'run-1',
          templateId: 'tpl-a',
          stepId: 'step-x',
          stepRunId: 'srun-1',
          workspaceId: 'ws-1',
          state: {},
        );

        expect(
          () => ctx.requireString('missing'),
          throwsA(isA<StateError>()),
        );
      });

      test('throws StateError for empty string', () {
        const ctx = PipelineContext(
          pipelineRunId: 'run-1',
          templateId: 'tpl-a',
          stepId: 'step-x',
          stepRunId: 'srun-1',
          workspaceId: 'ws-1',
          state: {'empty': ''},
        );

        expect(
          () => ctx.requireString('empty'),
          throwsA(isA<StateError>()),
        );
      });

      test('throws StateError for int value', () {
        const ctx = PipelineContext(
          pipelineRunId: 'run-1',
          templateId: 'tpl-a',
          stepId: 'step-x',
          stepRunId: 'srun-1',
          workspaceId: 'ws-1',
          state: {'notAString': 123},
        );

        expect(
          () => ctx.requireString('notAString'),
          throwsA(isA<StateError>()),
        );
      });

      test('throws StateError for bool value', () {
        const ctx = PipelineContext(
          pipelineRunId: 'run-1',
          templateId: 'tpl-a',
          stepId: 'step-x',
          stepRunId: 'srun-1',
          workspaceId: 'ws-1',
          state: {'flag': true},
        );

        expect(
          () => ctx.requireString('flag'),
          throwsA(isA<StateError>()),
        );
      });

      test('returns whitespace-only string (non-empty)', () {
        const ctx = PipelineContext(
          pipelineRunId: 'run-1',
          templateId: 'tpl-a',
          stepId: 'step-x',
          stepRunId: 'srun-1',
          workspaceId: 'ws-1',
          state: {'ws': '   '},
        );

        expect(ctx.requireString('ws'), '   ');
      });
    });

    // ---------------------------------------------------------------------------
    // requireInt
    // ---------------------------------------------------------------------------
    group('requireInt', () {
      test('returns value from state', () {
        const ctx = PipelineContext(
          pipelineRunId: 'run-1',
          templateId: 'tpl-a',
          stepId: 'step-x',
          stepRunId: 'srun-1',
          workspaceId: 'ws-1',
          state: {'count': 7},
        );

        expect(ctx.requireInt('count'), 7);
      });

      test('fallback to triggerPayload', () {
        const ctx = PipelineContext(
          pipelineRunId: 'run-1',
          templateId: 'tpl-a',
          stepId: 'step-x',
          stepRunId: 'srun-1',
          workspaceId: 'ws-1',
          state: {},
          triggerPayload: {'count': 99},
        );

        expect(ctx.requireInt('count'), 99);
      });

      test('throws StateError for missing key', () {
        const ctx = PipelineContext(
          pipelineRunId: 'run-1',
          templateId: 'tpl-a',
          stepId: 'step-x',
          stepRunId: 'srun-1',
          workspaceId: 'ws-1',
          state: {},
        );

        expect(
          () => ctx.requireInt('missing'),
          throwsA(isA<StateError>()),
        );
      });

      test('throws StateError for String value', () {
        const ctx = PipelineContext(
          pipelineRunId: 'run-1',
          templateId: 'tpl-a',
          stepId: 'step-x',
          stepRunId: 'srun-1',
          workspaceId: 'ws-1',
          state: {'notAnInt': 'hello'},
        );

        expect(
          () => ctx.requireInt('notAnInt'),
          throwsA(isA<StateError>()),
        );
      });

      test('throws StateError for double value', () {
        const ctx = PipelineContext(
          pipelineRunId: 'run-1',
          templateId: 'tpl-a',
          stepId: 'step-x',
          stepRunId: 'srun-1',
          workspaceId: 'ws-1',
          state: {'notAnInt': 3.14},
        );

        expect(
          () => ctx.requireInt('notAnInt'),
          throwsA(isA<StateError>()),
        );
      });
    });

    // ---------------------------------------------------------------------------
    // optional
    // ---------------------------------------------------------------------------
    group('optional', () {
      test('returns typed value from state', () {
        const ctx = PipelineContext(
          pipelineRunId: 'run-1',
          templateId: 'tpl-a',
          stepId: 'step-x',
          stepRunId: 'srun-1',
          workspaceId: 'ws-1',
          state: {'name': 'Alice'},
        );

        expect(ctx.optional<String>('name'), 'Alice');
      });

      test('returns typed value from triggerPayload', () {
        const ctx = PipelineContext(
          pipelineRunId: 'run-1',
          templateId: 'tpl-a',
          stepId: 'step-x',
          stepRunId: 'srun-1',
          workspaceId: 'ws-1',
          state: {},
          triggerPayload: {'name': 'Bob'},
        );

        expect(ctx.optional<String>('name'), 'Bob');
      });

      test('returns null for missing key', () {
        const ctx = PipelineContext(
          pipelineRunId: 'run-1',
          templateId: 'tpl-a',
          stepId: 'step-x',
          stepRunId: 'srun-1',
          workspaceId: 'ws-1',
          state: {},
        );

        expect(ctx.optional<String>('missing'), isNull);
      });

      test('throws StateError for wrong type cast', () {
        const ctx = PipelineContext(
          pipelineRunId: 'run-1',
          templateId: 'tpl-a',
          stepId: 'step-x',
          stepRunId: 'srun-1',
          workspaceId: 'ws-1',
          state: {'age': 42},
        );

        expect(
          () => ctx.optional<String>('age'),
          throwsA(isA<StateError>()),
        );
      });

      test('returns int from state with typed access', () {
        const ctx = PipelineContext(
          pipelineRunId: 'run-1',
          templateId: 'tpl-a',
          stepId: 'step-x',
          stepRunId: 'srun-1',
          workspaceId: 'ws-1',
          state: {'count': 10},
        );

        expect(ctx.optional<int>('count'), 10);
      });

      test('returns bool from state with typed access', () {
        const ctx = PipelineContext(
          pipelineRunId: 'run-1',
          templateId: 'tpl-a',
          stepId: 'step-x',
          stepRunId: 'srun-1',
          workspaceId: 'ws-1',
          state: {'active': true},
        );

        expect(ctx.optional<bool>('active'), isTrue);
      });

      test('state takes precedence over triggerPayload', () {
        const ctx = PipelineContext(
          pipelineRunId: 'run-1',
          templateId: 'tpl-a',
          stepId: 'step-x',
          stepRunId: 'srun-1',
          workspaceId: 'ws-1',
          state: {'name': 'State'},
          triggerPayload: {'name': 'Payload'},
        );

        expect(ctx.optional<String>('name'), 'State');
      });

      test('returns null when key present only in null triggerPayload is absent', () {
        const ctx = PipelineContext(
          pipelineRunId: 'run-1',
          templateId: 'tpl-a',
          stepId: 'step-x',
          stepRunId: 'srun-1',
          workspaceId: 'ws-1',
          state: {},
          triggerPayload: null,
        );

        expect(ctx.optional<String>('nonexistent'), isNull);
      });
    });

    // ---------------------------------------------------------------------------
    // optional<bool> — typed bool access
    // ---------------------------------------------------------------------------
    group('optional<bool>', () {
      test('returns true from state', () {
        const ctx = PipelineContext(
          pipelineRunId: 'run-1',
          templateId: 'tpl-a',
          stepId: 'step-x',
          stepRunId: 'srun-1',
          workspaceId: 'ws-1',
          state: {'enabled': true},
        );

        expect(ctx.optional<bool>('enabled'), isTrue);
      });

      test('returns false from state', () {
        const ctx = PipelineContext(
          pipelineRunId: 'run-1',
          templateId: 'tpl-a',
          stepId: 'step-x',
          stepRunId: 'srun-1',
          workspaceId: 'ws-1',
          state: {'enabled': false},
        );

        expect(ctx.optional<bool>('enabled'), isFalse);
      });

      test('falls back to triggerPayload', () {
        const ctx = PipelineContext(
          pipelineRunId: 'run-1',
          templateId: 'tpl-a',
          stepId: 'step-x',
          stepRunId: 'srun-1',
          workspaceId: 'ws-1',
          state: {},
          triggerPayload: {'enabled': true},
        );

        expect(ctx.optional<bool>('enabled'), isTrue);
      });

      test('state takes precedence over triggerPayload', () {
        const ctx = PipelineContext(
          pipelineRunId: 'run-1',
          templateId: 'tpl-a',
          stepId: 'step-x',
          stepRunId: 'srun-1',
          workspaceId: 'ws-1',
          state: {'enabled': false},
          triggerPayload: {'enabled': true},
        );

        expect(ctx.optional<bool>('enabled'), isFalse);
      });

      test('returns null for missing key (unlike require variants)', () {
        const ctx = PipelineContext(
          pipelineRunId: 'run-1',
          templateId: 'tpl-a',
          stepId: 'step-x',
          stepRunId: 'srun-1',
          workspaceId: 'ws-1',
          state: {},
        );

        expect(ctx.optional<bool>('missing'), isNull);
      });

      test('throws StateError for string value', () {
        const ctx = PipelineContext(
          pipelineRunId: 'run-1',
          templateId: 'tpl-a',
          stepId: 'step-x',
          stepRunId: 'srun-1',
          workspaceId: 'ws-1',
          state: {'notABool': 'yes'},
        );

        expect(
          () => ctx.optional<bool>('notABool'),
          throwsA(isA<StateError>()),
        );
      });

      test('throws StateError for int value', () {
        const ctx = PipelineContext(
          pipelineRunId: 'run-1',
          templateId: 'tpl-a',
          stepId: 'step-x',
          stepRunId: 'srun-1',
          workspaceId: 'ws-1',
          state: {'notABool': 1},
        );

        expect(
          () => ctx.optional<bool>('notABool'),
          throwsA(isA<StateError>()),
        );
      });

      test('returns null when value is explicitly null in state', () {
        const ctx = PipelineContext(
          pipelineRunId: 'run-1',
          templateId: 'tpl-a',
          stepId: 'step-x',
          stepRunId: 'srun-1',
          workspaceId: 'ws-1',
          state: {'key': null},
        );

        expect(ctx.optional<bool>('key'), isNull);
      });
    });

    // ---------------------------------------------------------------------------
    // optional<List> — typed list access
    // ---------------------------------------------------------------------------
    group('optional<List>', () {
      test('returns List from state', () {
        const ctx = PipelineContext(
          pipelineRunId: 'run-1',
          templateId: 'tpl-a',
          stepId: 'step-x',
          stepRunId: 'srun-1',
          workspaceId: 'ws-1',
          state: {'items': ['a', 'b']},
        );

        expect(ctx.optional<List>('items'), ['a', 'b']);
      });

      test('falls back to triggerPayload', () {
        const ctx = PipelineContext(
          pipelineRunId: 'run-1',
          templateId: 'tpl-a',
          stepId: 'step-x',
          stepRunId: 'srun-1',
          workspaceId: 'ws-1',
          state: {},
          triggerPayload: {'items': [1, 2, 3]},
        );

        expect(ctx.optional<List>('items'), [1, 2, 3]);
      });

      test('returns null for missing key', () {
        const ctx = PipelineContext(
          pipelineRunId: 'run-1',
          templateId: 'tpl-a',
          stepId: 'step-x',
          stepRunId: 'srun-1',
          workspaceId: 'ws-1',
          state: {},
        );

        expect(ctx.optional<List>('missing'), isNull);
      });

      test('throws StateError for non-List value (string)', () {
        const ctx = PipelineContext(
          pipelineRunId: 'run-1',
          templateId: 'tpl-a',
          stepId: 'step-x',
          stepRunId: 'srun-1',
          workspaceId: 'ws-1',
          state: {'items': 'not a list'},
        );

        expect(
          () => ctx.optional<List>('items'),
          throwsA(isA<StateError>()),
        );
      });

      test('returns empty list', () {
        const ctx = PipelineContext(
          pipelineRunId: 'run-1',
          templateId: 'tpl-a',
          stepId: 'step-x',
          stepRunId: 'srun-1',
          workspaceId: 'ws-1',
          state: {'items': <String>[]},
        );

        final result = ctx.optional<List>('items');
        expect(result, isNotNull);
        expect(result, isEmpty);
      });

      test('throws StateError for Map value', () {
        const ctx = PipelineContext(
          pipelineRunId: 'run-1',
          templateId: 'tpl-a',
          stepId: 'step-x',
          stepRunId: 'srun-1',
          workspaceId: 'ws-1',
          state: {'items': {'a': 1}},
        );

        expect(
          () => ctx.optional<List>('items'),
          throwsA(isA<StateError>()),
        );
      });
    });

    // ---------------------------------------------------------------------------
    // optional<Map> — typed map access
    // ---------------------------------------------------------------------------
    group('optional<Map>', () {
      test('returns Map from state', () {
        const ctx = PipelineContext(
          pipelineRunId: 'run-1',
          templateId: 'tpl-a',
          stepId: 'step-x',
          stepRunId: 'srun-1',
          workspaceId: 'ws-1',
          state: {'config': {'key': 'value'}},
        );

        final result = ctx.optional<Map>('config');
        expect(result, isNotNull);
        expect(result!['key'], 'value');
      });

      test('returns null for missing key', () {
        const ctx = PipelineContext(
          pipelineRunId: 'run-1',
          templateId: 'tpl-a',
          stepId: 'step-x',
          stepRunId: 'srun-1',
          workspaceId: 'ws-1',
          state: {},
        );

        expect(ctx.optional<Map>('missing'), isNull);
      });

      test('throws StateError for non-Map value (string)', () {
        const ctx = PipelineContext(
          pipelineRunId: 'run-1',
          templateId: 'tpl-a',
          stepId: 'step-x',
          stepRunId: 'srun-1',
          workspaceId: 'ws-1',
          state: {'config': 'not a map'},
        );

        expect(
          () => ctx.optional<Map>('config'),
          throwsA(isA<StateError>()),
        );
      });

      test('returns empty map', () {
        const ctx = PipelineContext(
          pipelineRunId: 'run-1',
          templateId: 'tpl-a',
          stepId: 'step-x',
          stepRunId: 'srun-1',
          workspaceId: 'ws-1',
          state: {'config': <String, dynamic>{}},
        );

        final result = ctx.optional<Map>('config');
        expect(result, isNotNull);
        expect(result, isEmpty);
      });

      test('throws StateError for List value', () {
        const ctx = PipelineContext(
          pipelineRunId: 'run-1',
          templateId: 'tpl-a',
          stepId: 'step-x',
          stepRunId: 'srun-1',
          workspaceId: 'ws-1',
          state: {'config': [1, 2, 3]},
        );

        expect(
          () => ctx.optional<Map>('config'),
          throwsA(isA<StateError>()),
        );
      });

      test('falls back to triggerPayload for map value', () {
        const ctx = PipelineContext(
          pipelineRunId: 'run-1',
          templateId: 'tpl-a',
          stepId: 'step-x',
          stepRunId: 'srun-1',
          workspaceId: 'ws-1',
          state: {},
          triggerPayload: {'config': {'from': 'payload'}},
        );

        final result = ctx.optional<Map>('config');
        expect(result, isNotNull);
        expect(result!['from'], 'payload');
      });
    });

    // ---------------------------------------------------------------------------
    // optional edge cases
    // ---------------------------------------------------------------------------
    group('optional edge cases', () {
      test('returns null when state and triggerPayload are both null', () {
        const ctx = PipelineContext(
          pipelineRunId: 'run-1',
          templateId: 'tpl-a',
          stepId: 'step-x',
          stepRunId: 'srun-1',
          workspaceId: 'ws-1',
          state: {},
          triggerPayload: null,
        );

        expect(ctx.optional<String>('missing'), isNull);
      });

      test('returns null when key exists but value is null', () {
        const ctx = PipelineContext(
          pipelineRunId: 'run-1',
          templateId: 'tpl-a',
          stepId: 'step-x',
          stepRunId: 'srun-1',
          workspaceId: 'ws-1',
          state: {'key': null},
        );

        expect(ctx.optional<String>('key'), isNull);
      });

      test('optional with List type returns typed list', () {
        const ctx = PipelineContext(
          pipelineRunId: 'run-1',
          templateId: 'tpl-a',
          stepId: 'step-x',
          stepRunId: 'srun-1',
          workspaceId: 'ws-1',
          state: {'items': <String>['x', 'y']},
        );

        expect(ctx.optional<List<String>>('items'), ['x', 'y']);
      });

      test('optional with Map type returns typed map', () {
        const ctx = PipelineContext(
          pipelineRunId: 'run-1',
          templateId: 'tpl-a',
          stepId: 'step-x',
          stepRunId: 'srun-1',
          workspaceId: 'ws-1',
          state: {'config': <String, int>{'a': 1}},
        );

        expect(ctx.optional<Map<String, int>>('config'), {'a': 1});
      });

      test('optional with double type', () {
        const ctx = PipelineContext(
          pipelineRunId: 'run-1',
          templateId: 'tpl-a',
          stepId: 'step-x',
          stepRunId: 'srun-1',
          workspaceId: 'ws-1',
          state: {'pi': 3.14},
        );

        expect(ctx.optional<double>('pi'), 3.14);
      });
    });

    // ---------------------------------------------------------------------------
    // field access
    // ---------------------------------------------------------------------------
    group('field access', () {
      test('workspaceId is accessible', () {
        const ctx = PipelineContext(
          pipelineRunId: 'run-1',
          templateId: 'tpl-a',
          stepId: 'step-x',
          stepRunId: 'srun-1',
          workspaceId: 'ws-1',
          state: {},
        );

        expect(ctx.workspaceId, 'ws-1');
      });

      test('templateId is accessible', () {
        const ctx = PipelineContext(
          pipelineRunId: 'run-1',
          templateId: 'tpl-a',
          stepId: 'step-x',
          stepRunId: 'srun-1',
          workspaceId: 'ws-1',
          state: {},
        );

        expect(ctx.templateId, 'tpl-a');
      });

      test('pipelineRunId is accessible', () {
        const ctx = PipelineContext(
          pipelineRunId: 'run-1',
          templateId: 'tpl-a',
          stepId: 'step-x',
          stepRunId: 'srun-1',
          workspaceId: 'ws-1',
          state: {},
        );

        expect(ctx.pipelineRunId, 'run-1');
      });

      test('stepRunId is accessible', () {
        const ctx = PipelineContext(
          pipelineRunId: 'run-1',
          templateId: 'tpl-a',
          stepId: 'step-x',
          stepRunId: 'srun-1',
          workspaceId: 'ws-1',
          state: {},
        );

        expect(ctx.stepRunId, 'srun-1');
      });
    });

    // ---------------------------------------------------------------------------
    // requireString — additional edge cases
    // ---------------------------------------------------------------------------
    group('requireString additional', () {
      test('throws StateError when falling back to triggerPayload with empty string', () {
        const ctx = PipelineContext(
          pipelineRunId: 'run-1',
          templateId: 'tpl-a',
          stepId: 'step-x',
          stepRunId: 'srun-1',
          workspaceId: 'ws-1',
          state: {},
          triggerPayload: {'key': ''},
        );

        expect(
          () => ctx.requireString('key'),
          throwsA(isA<StateError>()),
        );
      });

      test('throws StateError when falling back to triggerPayload with bool', () {
        const ctx = PipelineContext(
          pipelineRunId: 'run-1',
          templateId: 'tpl-a',
          stepId: 'step-x',
          stepRunId: 'srun-1',
          workspaceId: 'ws-1',
          state: {},
          triggerPayload: {'key': true},
        );

        expect(
          () => ctx.requireString('key'),
          throwsA(isA<StateError>()),
        );
      });

      test('throws StateError when value is explicitly null in state', () {
        const ctx = PipelineContext(
          pipelineRunId: 'run-1',
          templateId: 'tpl-a',
          stepId: 'step-x',
          stepRunId: 'srun-1',
          workspaceId: 'ws-1',
          state: {'key': null},
        );

        expect(
          () => ctx.requireString('key'),
          throwsA(isA<StateError>()),
        );
      });

      test('throws StateError when value is explicitly null in triggerPayload fallback', () {
        const ctx = PipelineContext(
          pipelineRunId: 'run-1',
          templateId: 'tpl-a',
          stepId: 'step-x',
          stepRunId: 'srun-1',
          workspaceId: 'ws-1',
          state: {},
          triggerPayload: {'key': null},
        );

        expect(
          () => ctx.requireString('key'),
          throwsA(isA<StateError>()),
        );
      });

      test('state takes precedence even when triggerPayload has valid string', () {
        const ctx = PipelineContext(
          pipelineRunId: 'run-1',
          templateId: 'tpl-a',
          stepId: 'step-x',
          stepRunId: 'srun-1',
          workspaceId: 'ws-1',
          state: {'key': 'from-state'},
          triggerPayload: {'key': 'from-payload'},
        );

        expect(ctx.requireString('key'), 'from-state');
      });
    });

    // ---------------------------------------------------------------------------
    // requireInt — additional edge cases
    // ---------------------------------------------------------------------------
    group('requireInt additional', () {
      test('state takes precedence over triggerPayload', () {
        const ctx = PipelineContext(
          pipelineRunId: 'run-1',
          templateId: 'tpl-a',
          stepId: 'step-x',
          stepRunId: 'srun-1',
          workspaceId: 'ws-1',
          state: {'count': 42},
          triggerPayload: {'count': 99},
        );

        expect(ctx.requireInt('count'), 42);
      });

      test('returns zero', () {
        const ctx = PipelineContext(
          pipelineRunId: 'run-1',
          templateId: 'tpl-a',
          stepId: 'step-x',
          stepRunId: 'srun-1',
          workspaceId: 'ws-1',
          state: {'count': 0},
        );

        expect(ctx.requireInt('count'), 0);
      });

      test('returns negative value', () {
        const ctx = PipelineContext(
          pipelineRunId: 'run-1',
          templateId: 'tpl-a',
          stepId: 'step-x',
          stepRunId: 'srun-1',
          workspaceId: 'ws-1',
          state: {'delta': -5},
        );

        expect(ctx.requireInt('delta'), -5);
      });

      test('throws StateError when falling back to triggerPayload with String', () {
        const ctx = PipelineContext(
          pipelineRunId: 'run-1',
          templateId: 'tpl-a',
          stepId: 'step-x',
          stepRunId: 'srun-1',
          workspaceId: 'ws-1',
          state: {},
          triggerPayload: {'count': 'not-int'},
        );

        expect(
          () => ctx.requireInt('count'),
          throwsA(isA<StateError>()),
        );
      });

      test('throws StateError when falling back to triggerPayload with bool', () {
        const ctx = PipelineContext(
          pipelineRunId: 'run-1',
          templateId: 'tpl-a',
          stepId: 'step-x',
          stepRunId: 'srun-1',
          workspaceId: 'ws-1',
          state: {},
          triggerPayload: {'count': false},
        );

        expect(
          () => ctx.requireInt('count'),
          throwsA(isA<StateError>()),
        );
      });

      test('throws StateError when value is explicitly null in state', () {
        const ctx = PipelineContext(
          pipelineRunId: 'run-1',
          templateId: 'tpl-a',
          stepId: 'step-x',
          stepRunId: 'srun-1',
          workspaceId: 'ws-1',
          state: {'count': null},
        );

        expect(
          () => ctx.requireInt('count'),
          throwsA(isA<StateError>()),
        );
      });
    });

    // ---------------------------------------------------------------------------
    // optional — additional edge cases
    // ---------------------------------------------------------------------------
    group('optional additional', () {
      test('throws StateError for wrong type from triggerPayload fallback', () {
        const ctx = PipelineContext(
          pipelineRunId: 'run-1',
          templateId: 'tpl-a',
          stepId: 'step-x',
          stepRunId: 'srun-1',
          workspaceId: 'ws-1',
          state: {},
          triggerPayload: {'name': 42},
        );

        expect(
          () => ctx.optional<String>('name'),
          throwsA(isA<StateError>()),
        );
      });

      test('returns int from triggerPayload when not in state', () {
        const ctx = PipelineContext(
          pipelineRunId: 'run-1',
          templateId: 'tpl-a',
          stepId: 'step-x',
          stepRunId: 'srun-1',
          workspaceId: 'ws-1',
          state: {},
          triggerPayload: {'count': 7},
        );

        expect(ctx.optional<int>('count'), 7);
      });

      test('returns double from triggerPayload when not in state', () {
        const ctx = PipelineContext(
          pipelineRunId: 'run-1',
          templateId: 'tpl-a',
          stepId: 'step-x',
          stepRunId: 'srun-1',
          workspaceId: 'ws-1',
          state: {},
          triggerPayload: {'pi': 3.14},
        );

        expect(ctx.optional<double>('pi'), 3.14);
      });

      test('returns null when key is explicitly null in both state and triggerPayload', () {
        const ctx = PipelineContext(
          pipelineRunId: 'run-1',
          templateId: 'tpl-a',
          stepId: 'step-x',
          stepRunId: 'srun-1',
          workspaceId: 'ws-1',
          state: {'key': null},
          triggerPayload: {'key': null},
        );

        expect(ctx.optional<String>('key'), isNull);
      });

      test('state wins and throws when state has wrong type even though triggerPayload has correct type', () {
        const ctx = PipelineContext(
          pipelineRunId: 'run-1',
          templateId: 'tpl-a',
          stepId: 'step-x',
          stepRunId: 'srun-1',
          workspaceId: 'ws-1',
          state: {'key': 42},
          triggerPayload: {'key': 'valid-string'},
        );

        expect(
          () => ctx.optional<String>('key'),
          throwsA(isA<StateError>()),
        );
      });
    });

    // ---------------------------------------------------------------------------
    // state map mutability
    // ---------------------------------------------------------------------------
    group('state map mutability', () {
      test('state is readable after construction', () {
        const ctx = PipelineContext(
          pipelineRunId: 'run-1',
          templateId: 'tpl-a',
          stepId: 'step-x',
          stepRunId: 'srun-1',
          workspaceId: 'ws-1',
          state: {'initial': 1},
        );

        expect(ctx.state['initial'], 1);
      });

      test('state can be mutated in place (step writes back to map)', () {
        // `Map.from` yields a genuinely-mutable map (and keeps the constructor
        // call non-const), so the state bag can be written back in place — a
        // const context would freeze it into an unmodifiable map.
        final ctx = PipelineContext(
          pipelineRunId: 'run-1',
          templateId: 'tpl-a',
          stepId: 'step-x',
          stepRunId: 'srun-1',
          workspaceId: 'ws-1',
          state: Map<String, dynamic>.from(const {'initial': 1}),
        );

        ctx.state['newKey'] = 'newValue';
        ctx.state['initial'] = 99;

        expect(ctx.state['newKey'], 'newValue');
        expect(ctx.state['initial'], 99);
        expect(ctx.state.length, 2);
      });

      test('mutated state is visible through accessors', () {
        // `Map.from` keeps the map mutable (and the constructor call non-const)
        // so the step can write back into the state bag.
        final ctx = PipelineContext(
          pipelineRunId: 'run-1',
          templateId: 'tpl-a',
          stepId: 'step-x',
          stepRunId: 'srun-1',
          workspaceId: 'ws-1',
          state: Map<String, dynamic>.from(const {}),
        );

        ctx.state['name'] = 'Alice';
        ctx.state['count'] = 42;

        expect(ctx.requireString('name'), 'Alice');
        expect(ctx.requireInt('count'), 42);
      });
    });
  });
}
