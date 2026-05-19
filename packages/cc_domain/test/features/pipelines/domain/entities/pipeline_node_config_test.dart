import 'package:cc_domain/features/pipelines/domain/entities/pipeline_node_config.dart';
import 'package:test/test.dart';

/// Exercises [PipelineNodeConfig] and [StepRetryPolicy] JSON round-trips,
/// copyWith preservation and the retry-delay computation.
void main() {
  group('PipelineNodeConfig JSON round-trip', () {
    test('fromJson reads every field', () {
      final c = PipelineNodeConfig.fromJson({
        'prompt': 'do {{x}}',
        'script': 'run.sh',
        'agentId': 'a-1',
        'inputKeys': ['x'],
        'repoIds': ['r-1', '{{repo_id}}'],
        'outputKey': 'out',
        'label': 'Step',
        'outputSchema': {'type': 'object'},
        'reducer': 'concat',
        'retryPolicy': {'maxAttempts': 3, 'backoff': 'linear'},
        'continueOnFail': true,
        'timeoutMs': 5000,
        'teamId': 't-1',
        'dispatchMode': 'parallel',
        'extras': {'k': 'v'},
      });
      expect(c.prompt, 'do {{x}}');
      expect(c.agentId, 'a-1');
      expect(c.inputKeys, ['x']);
      expect(c.repoIds, ['r-1', '{{repo_id}}']);
      expect(c.outputKey, 'out');
      expect(c.label, 'Step');
      expect(c.reducer, 'concat');
      expect(c.retryPolicy?.maxAttempts, 3);
      expect(c.continueOnFail, isTrue);
      expect(c.timeoutMs, 5000);
      expect(c.teamId, 't-1');
      expect(c.dispatchMode, 'parallel');
      expect(c.extras['k'], 'v');
    });

    test('fromJson defaults continueOnFail to false and extras to empty', () {
      final c = PipelineNodeConfig.fromJson({});
      expect(c.continueOnFail, isFalse);
      expect(c.extras, isEmpty);
      expect(c.inputKeys, isEmpty);
      expect(c.repoIds, isEmpty);
      expect(c.retryPolicy, isNull);
    });

    test('toJson round-trips through fromJson', () {
      const original = PipelineNodeConfig(
        prompt: 'p',
        agentId: 'a',
        inputKeys: ['x', 'y'],
        repoIds: ['r-1'],
        outputKey: 'o',
        retryPolicy: StepRetryPolicy(maxAttempts: 4),
        extras: {'k': 'v'},
      );
      final roundTripped = PipelineNodeConfig.fromJson(original.toJson());
      expect(roundTripped.prompt, 'p');
      expect(roundTripped.agentId, 'a');
      expect(roundTripped.inputKeys, ['x', 'y']);
      expect(roundTripped.repoIds, ['r-1']);
      expect(roundTripped.outputKey, 'o');
      expect(roundTripped.retryPolicy?.maxAttempts, 4);
      expect(roundTripped.extras['k'], 'v');
    });

    test('empty constant has nulls and empty collections', () {
      const c = PipelineNodeConfig.empty;
      expect(c.prompt, isNull);
      expect(c.inputKeys, isEmpty);
      expect(c.extras, isEmpty);
    });
  });

  group('PipelineNodeConfig copyWith', () {
    test('changes a field and preserves the rest', () {
      const base = PipelineNodeConfig(
        prompt: 'p',
        agentId: 'a',
        outputKey: 'o',
      );
      final next = base.copyWith(prompt: 'new');
      expect(next.prompt, 'new');
      expect(next.agentId, 'a');
      expect(next.outputKey, 'o');
    });
  });

  group('StepRetryPolicy', () {
    test('asserts maxAttempts >= 1', () {
      expect(
        () => StepRetryPolicy(maxAttempts: 0),
        throwsA(isA<AssertionError>()),
      );
    });

    test('fromJson defaults', () {
      final p = StepRetryPolicy.fromJson({});
      expect(p.maxAttempts, 1);
      expect(p.backoff, 'exponential');
      expect(p.initialDelayMs, 1000);
    });

    test('delayForAttempt grows exponentially', () {
      const p = StepRetryPolicy(
        maxAttempts: 3,
        backoff: 'exponential',
        initialDelayMs: 1000,
      );
      // attempt 1: 1000 * 2^0 = 1000; attempt 2: 1000 * 2^1 = 2000; etc.
      expect(p.delayForAttempt(1).inMilliseconds, 1000);
      expect(p.delayForAttempt(2).inMilliseconds, 2000);
      expect(p.delayForAttempt(3).inMilliseconds, 4000);
    });

    test('delayForAttempt grows linearly', () {
      const p = StepRetryPolicy(backoff: 'linear', initialDelayMs: 500);
      expect(p.delayForAttempt(1).inMilliseconds, 500);
      expect(p.delayForAttempt(2).inMilliseconds, 1000);
      expect(p.delayForAttempt(3).inMilliseconds, 1500);
    });

    test('equality and hashCode', () {
      expect(
        const StepRetryPolicy(maxAttempts: 2),
        const StepRetryPolicy(maxAttempts: 2),
      );
      expect(
        const StepRetryPolicy(maxAttempts: 2).hashCode,
        const StepRetryPolicy(maxAttempts: 2).hashCode,
      );
    });
  });
}
