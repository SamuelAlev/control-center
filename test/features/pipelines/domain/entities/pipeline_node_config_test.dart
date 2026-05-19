import 'package:control_center/features/pipelines/domain/entities/pipeline_node_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PipelineNodeConfig', () {
    test('empty constant has all defaults', timeout: const Timeout.factor(2), () {
      const config = PipelineNodeConfig.empty;
      expect(config.prompt, isNull);
      expect(config.script, isNull);
      expect(config.agentId, isNull);
      expect(config.inputKeys, isEmpty);
      expect(config.outputKey, isNull);
      expect(config.label, isNull);
      expect(config.outputSchema, isNull);
      expect(config.reducer, isNull);
      expect(config.retryPolicy, isNull);
      expect(config.continueOnFail, isFalse);
      expect(config.timeoutMs, isNull);
      expect(config.teamId, isNull);
      expect(config.dispatchMode, isNull);
      expect(config.extras, isEmpty);
    });

    test('fromJson parses all fields', timeout: const Timeout.factor(2), () {
      final json = {
        'prompt': 'Hello {{name}}',
        'script': 'echo hi',
        'agentId': 'agent-123',
        'inputKeys': ['name'],
        'outputKey': 'greeting',
        'label': 'Greeter',
        'outputSchema': {'type': 'string'},
        'reducer': 'append',
        'retryPolicy': {
          'maxAttempts': 3,
          'backoff': 'linear',
          'initialDelayMs': 500,
        },
        'continueOnFail': true,
        'timeoutMs': 30000,
        'teamId': 'team-1',
        'dispatchMode': 'allParallel',
        'extras': {'iterableKey': 'items'},
      };
      final config = PipelineNodeConfig.fromJson(json);
      expect(config.prompt, 'Hello {{name}}');
      expect(config.script, 'echo hi');
      expect(config.agentId, 'agent-123');
      expect(config.inputKeys, ['name']);
      expect(config.outputKey, 'greeting');
      expect(config.label, 'Greeter');
      expect(config.outputSchema, {'type': 'string'});
      expect(config.reducer, 'append');
      expect(config.retryPolicy, isNotNull);
      expect(config.retryPolicy!.maxAttempts, 3);
      expect(config.retryPolicy!.backoff, 'linear');
      expect(config.retryPolicy!.initialDelayMs, 500);
      expect(config.continueOnFail, isTrue);
      expect(config.timeoutMs, 30000);
      expect(config.teamId, 'team-1');
      expect(config.dispatchMode, 'allParallel');
      expect(config.extras, {'iterableKey': 'items'});
    });

    test('fromJson defaults missing fields', timeout: const Timeout.factor(2), () {
      final config = PipelineNodeConfig.fromJson({});
      expect(config.prompt, isNull);
      expect(config.inputKeys, isEmpty);
      expect(config.continueOnFail, isFalse);
      expect(config.retryPolicy, isNull);
      expect(config.extras, isEmpty);
    });

    test('toJson omits null/default fields', timeout: const Timeout.factor(2), () {
      const config = PipelineNodeConfig(prompt: 'hi');
      final json = config.toJson();
      expect(json.containsKey('prompt'), isTrue);
      expect(json.containsKey('script'), isFalse);
      expect(json.containsKey('inputKeys'), isFalse);
      expect(json.containsKey('continueOnFail'), isFalse);
      expect(json.containsKey('extras'), isFalse);
    });

    test('toJson round-trips', timeout: const Timeout.factor(2), () {
      const config = PipelineNodeConfig(
        prompt: 'p',
        inputKeys: ['a'],
        outputKey: 'o',
        continueOnFail: true,
        extras: {'x': 1},
      );
      final json = config.toJson();
      final restored = PipelineNodeConfig.fromJson(json);
      expect(restored, equals(config));
    });

    test('copyWith overrides specified fields', timeout: const Timeout.factor(2), () {
      const config = PipelineNodeConfig(prompt: 'old', outputKey: 'out');
      final copy = config.copyWith(prompt: 'new');
      expect(copy.prompt, 'new');
      expect(copy.outputKey, 'out');
    });

    group('toJson includes', () {
      test('outputSchema when set', timeout: const Timeout.factor(2), () {
        const config = PipelineNodeConfig(outputSchema: {'type': 'string'});
        final json = config.toJson();
        expect(json['outputSchema'], {'type': 'string'});
      });

      test('reducer when set', timeout: const Timeout.factor(2), () {
        const config = PipelineNodeConfig(reducer: 'append');
        final json = config.toJson();
        expect(json['reducer'], 'append');
      });

      test('retryPolicy when set', timeout: const Timeout.factor(2), () {
        const config = PipelineNodeConfig(
          retryPolicy: StepRetryPolicy(maxAttempts: 3, backoff: 'linear'),
        );
        final json = config.toJson();
        expect(json['retryPolicy'], isA<Map<String, dynamic>>());
        expect((json['retryPolicy'] as Map)['maxAttempts'], 3);
      });

      test('teamId when set', timeout: const Timeout.factor(2), () {
        const config = PipelineNodeConfig(teamId: 'team-42');
        final json = config.toJson();
        expect(json['teamId'], 'team-42');
      });

      test('dispatchMode when set', timeout: const Timeout.factor(2), () {
        const config = PipelineNodeConfig(dispatchMode: 'allParallel');
        final json = config.toJson();
        expect(json['dispatchMode'], 'allParallel');
      });
    });

    group('copyWith', () {
      test('overrides script', timeout: const Timeout.factor(2), () {
        const config = PipelineNodeConfig(script: 'echo old');
        final copy = config.copyWith(script: 'echo new');
        expect(copy.script, 'echo new');
      });

      test('overrides agentId', timeout: const Timeout.factor(2), () {
        const config = PipelineNodeConfig(agentId: 'agent-1');
        final copy = config.copyWith(agentId: 'agent-2');
        expect(copy.agentId, 'agent-2');
      });

      test('overrides outputSchema', timeout: const Timeout.factor(2), () {
        const config = PipelineNodeConfig(outputSchema: {'old': true});
        final copy = config.copyWith(outputSchema: {'new': true});
        expect(copy.outputSchema, {'new': true});
      });

      test('overrides reducer', timeout: const Timeout.factor(2), () {
        const config = PipelineNodeConfig(reducer: 'merge');
        final copy = config.copyWith(reducer: 'append');
        expect(copy.reducer, 'append');
      });

      test('overrides retryPolicy', timeout: const Timeout.factor(2), () {
        const config = PipelineNodeConfig(
          retryPolicy: StepRetryPolicy(maxAttempts: 2),
        );
        final copy = config.copyWith(
          retryPolicy: const StepRetryPolicy(maxAttempts: 5),
        );
        expect(copy.retryPolicy!.maxAttempts, 5);
      });

      test('overrides continueOnFail', timeout: const Timeout.factor(2), () {
        const config = PipelineNodeConfig(continueOnFail: false);
        final copy = config.copyWith(continueOnFail: true);
        expect(copy.continueOnFail, isTrue);
      });

      test('overrides timeoutMs', timeout: const Timeout.factor(2), () {
        const config = PipelineNodeConfig(timeoutMs: 10000);
        final copy = config.copyWith(timeoutMs: 30000);
        expect(copy.timeoutMs, 30000);
      });

      test('overrides teamId', timeout: const Timeout.factor(2), () {
        const config = PipelineNodeConfig(teamId: 'old-team');
        final copy = config.copyWith(teamId: 'new-team');
        expect(copy.teamId, 'new-team');
      });

      test('overrides dispatchMode', timeout: const Timeout.factor(2), () {
        const config = PipelineNodeConfig(dispatchMode: 'single');
        final copy = config.copyWith(dispatchMode: 'allParallel');
        expect(copy.dispatchMode, 'allParallel');
      });

      test('overrides extras', timeout: const Timeout.factor(2), () {
        const config = PipelineNodeConfig(extras: {'x': 1});
        final copy = config.copyWith(extras: {'y': 2});
        expect(copy.extras, {'y': 2});
      });

      test('preserves fields not overridden', timeout: const Timeout.factor(2), () {
        const config = PipelineNodeConfig(
          prompt: 'p',
          script: 's',
          agentId: 'a',
          inputKeys: ['in'],
          outputKey: 'out',
          label: 'L',
          outputSchema: {'type': 'int'},
          reducer: 'sum',
          retryPolicy: StepRetryPolicy(maxAttempts: 3),
          continueOnFail: true,
          timeoutMs: 5000,
          teamId: 't1',
          dispatchMode: 'parallel',
          extras: {'key': 'val'},
        );
        final copy = config.copyWith(prompt: 'new-p');
        expect(copy.prompt, 'new-p');
        expect(copy.script, 's');
        expect(copy.agentId, 'a');
        expect(copy.inputKeys, ['in']);
        expect(copy.outputKey, 'out');
        expect(copy.label, 'L');
        expect(copy.outputSchema, {'type': 'int'});
        expect(copy.reducer, 'sum');
        expect(copy.retryPolicy!.maxAttempts, 3);
        expect(copy.continueOnFail, isTrue);
        expect(copy.timeoutMs, 5000);
        expect(copy.teamId, 't1');
        expect(copy.dispatchMode, 'parallel');
        expect(copy.extras, {'key': 'val'});
      });
    });

    test('equality compares all fields including deep collections',
        timeout: const Timeout.factor(2), () {
      const a = PipelineNodeConfig(
        inputKeys: ['a', 'b'],
        extras: {'x': 1},
      );
      const b = PipelineNodeConfig(
        inputKeys: ['a', 'b'],
        extras: {'x': 1},
      );
      expect(a, equals(b));

      const c = PipelineNodeConfig(inputKeys: ['b', 'a']);
      expect(a, isNot(equals(c)));
    });
  });

  group('StepRetryPolicy', () {
    test('asserts maxAttempts >= 1', timeout: const Timeout.factor(2), () {
      expect(
        () => StepRetryPolicy(maxAttempts: 0),
        throwsA(isA<AssertionError>()),
      );
    });

    test('fromJson with defaults', timeout: const Timeout.factor(2), () {
      final policy = StepRetryPolicy.fromJson({});
      expect(policy.maxAttempts, 1);
      expect(policy.backoff, 'exponential');
      expect(policy.initialDelayMs, 1000);
    });

    test('fromJson parses all fields', timeout: const Timeout.factor(2), () {
      final policy = StepRetryPolicy.fromJson({
        'maxAttempts': 5,
        'backoff': 'linear',
        'initialDelayMs': 200,
      });
      expect(policy.maxAttempts, 5);
      expect(policy.backoff, 'linear');
      expect(policy.initialDelayMs, 200);
    });

    test('toJson round-trips', timeout: const Timeout.factor(2), () {
      const policy = StepRetryPolicy(
        maxAttempts: 3,
        backoff: 'linear',
        initialDelayMs: 500,
      );
      final json = policy.toJson();
      final restored = StepRetryPolicy.fromJson(json);
      expect(restored, equals(policy));
    });

    test('delayForAttempt with exponential backoff', timeout: const Timeout.factor(2), () {
      const policy = StepRetryPolicy(
        maxAttempts: 5,
        backoff: 'exponential',
        initialDelayMs: 1000,
      );
      // attempt 1: 1000 * 2^0 = 1000
      expect(policy.delayForAttempt(1), const Duration(milliseconds: 1000));
      // attempt 2: 1000 * 2^1 = 2000
      expect(policy.delayForAttempt(2), const Duration(milliseconds: 2000));
      // attempt 3: 1000 * 2^2 = 4000
      expect(policy.delayForAttempt(3), const Duration(milliseconds: 4000));
    });

    test('delayForAttempt with linear backoff', timeout: const Timeout.factor(2), () {
      const policy = StepRetryPolicy(
        maxAttempts: 3,
        backoff: 'linear',
        initialDelayMs: 500,
      );
      // attempt 1: 500 * 1 = 500
      expect(policy.delayForAttempt(1), const Duration(milliseconds: 500));
      // attempt 2: 500 * 2 = 1000
      expect(policy.delayForAttempt(2), const Duration(milliseconds: 1000));
    });

    test('equality', timeout: const Timeout.factor(2), () {
      const a = StepRetryPolicy();
      const b = StepRetryPolicy();
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));

      const c = StepRetryPolicy(maxAttempts: 5);
      expect(a, isNot(equals(c)));
    });
  });
}
