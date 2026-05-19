import 'package:control_center/features/pipelines/domain/entities/step_result.dart';
import 'package:control_center/features/pipelines/domain/services/pipeline_body_registry.dart';
import 'package:control_center/features/pipelines/domain/services/pipeline_context.dart';
import 'package:flutter_test/flutter_test.dart';

/// A simple stub [StepBodyFn] that returns [StepResult.ok].
Future<StepResult> _stubBody(PipelineContext ctx) async {
  return StepResult.ok();
}

/// Another stub that returns a different result to distinguish overwrites.
Future<StepResult> _stubBodyAlt(PipelineContext ctx) async {
  return StepResult.ok(mutatedState: {'alt': true});
}

void main() {
  group('PipelineBodyRegistry', () {
    late PipelineBodyRegistry registry;

    setUp(() {
      registry = PipelineBodyRegistry();
    });

    /// Helper that creates a minimal [PipelineContext] for stub calls.
    PipelineContext ctx() => const PipelineContext(
          pipelineRunId: 'run-1',
          templateId: 'tpl-1',
          stepId: 'step-1',
          stepRunId: 'srun-1',
          workspaceId: 'ws-1',
          state: {},
        );

    // ---------------------------------------------------------------------------
    // registerBody + body
    // ---------------------------------------------------------------------------
    group('registerBody / body', () {
      test('returns the registered closure', () {
        registry.registerBody('step-a', _stubBody);
        expect(registry.body('step-a'), same(_stubBody));
      });

      test('throws StateError when key is not registered', () {
        expect(
          () => registry.body('nonexistent'),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              'Pipeline body "nonexistent" not registered',
            ),
          ),
        );
      });

      test('throws StateError for empty string key when never registered', () {
        expect(
          () => registry.body(''),
          throwsA(isA<StateError>()),
        );
      });
    });

    // ---------------------------------------------------------------------------
    // hasBody
    // ---------------------------------------------------------------------------
    group('hasBody', () {
      test('returns false for an unregistered key', () {
        expect(registry.hasBody('unregistered'), isFalse);
      });

      test('returns false for empty string key with no registration', () {
        expect(registry.hasBody(''), isFalse);
      });

      test('returns true after registration', () {
        registry.registerBody('step-a', _stubBody);
        expect(registry.hasBody('step-a'), isTrue);
      });

      test('returns true for empty string key when registered', () {
        registry.registerBody('', _stubBody);
        expect(registry.hasBody(''), isTrue);
      });
    });

    // ---------------------------------------------------------------------------
    // bodyKeys
    // ---------------------------------------------------------------------------
    group('bodyKeys', () {
      test('returns empty iterable for a fresh registry', () {
        expect(registry.bodyKeys, isEmpty);
      });

      test('lists a single registered key', () {
        registry.registerBody('step-a', _stubBody);
        expect(registry.bodyKeys, contains('step-a'));
        expect(registry.bodyKeys.length, 1);
      });

      test('lists all registered keys', () {
        registry.registerBody('step-a', _stubBody);
        registry.registerBody('step-b', _stubBody);
        expect(registry.bodyKeys, containsAll(['step-a', 'step-b']));
        expect(registry.bodyKeys.length, 2);
      });

      test('reflects overwrites (no duplicate keys)', () {
        registry.registerBody('step-a', _stubBody);
        registry.registerBody('step-a', _stubBodyAlt);
        expect(registry.bodyKeys, contains('step-a'));
        expect(registry.bodyKeys.length, 1);
      });
    });

    // ---------------------------------------------------------------------------
    // Multiple registrations
    // ---------------------------------------------------------------------------
    group('multiple registrations', () {
      test('each key retrieves its own closure', () {
        registry.registerBody('step-a', _stubBody);
        registry.registerBody('step-b', _stubBodyAlt);

        expect(registry.body('step-a'), same(_stubBody));
        expect(registry.body('step-b'), same(_stubBodyAlt));
      });

      test('hasBody returns true for all registered keys', () {
        registry.registerBody('step-a', _stubBody);
        registry.registerBody('step-b', _stubBodyAlt);
        registry.registerBody('step-c', _stubBody);

        expect(registry.hasBody('step-a'), isTrue);
        expect(registry.hasBody('step-b'), isTrue);
        expect(registry.hasBody('step-c'), isTrue);
      });

      test('all registered closures are callable with a context', () async {
        registry.registerBody('step-a', _stubBody);
        registry.registerBody('step-b', _stubBodyAlt);

        final resultA = await registry.body('step-a')(ctx());
        expect(resultA.isFailed, isFalse);
        expect(resultA.isTerminal, isFalse);

        final resultB = await registry.body('step-b')(ctx());
        expect(resultB.isFailed, isFalse);
        expect(resultB.mutatedState, {'alt': true});
      });
    });

    // ---------------------------------------------------------------------------
    // Overwriting
    // ---------------------------------------------------------------------------
    group('overwriting', () {
      test('replace closure retrieves the new one', () {
        registry.registerBody('step-a', _stubBody);
        registry.registerBody('step-a', _stubBodyAlt);

        expect(registry.body('step-a'), same(_stubBodyAlt));
        expect(registry.body('step-a'), isNot(same(_stubBody)));
      });

      test('hasBody stays true after overwrite', () {
        registry.registerBody('step-a', _stubBody);
        registry.registerBody('step-a', _stubBodyAlt);

        expect(registry.hasBody('step-a'), isTrue);
      });

      test('bodyKeys count does not increase on overwrite', () {
        registry.registerBody('step-a', _stubBody);
        expect(registry.bodyKeys.length, 1);

        registry.registerBody('step-a', _stubBodyAlt);
        expect(registry.bodyKeys.length, 1);
      });

      test('overwritten closure produces the new result', () async {
        registry.registerBody('step-a', _stubBody);
        registry.registerBody('step-a', _stubBodyAlt);

        final result = await registry.body('step-a')(ctx());
        expect(result.mutatedState, {'alt': true});
      });
    });
  });
}
