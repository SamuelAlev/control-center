import 'package:cc_harness/context.dart';
import 'package:cc_harness/provider.dart';
import 'package:test/test.dart';

void main() {
  group('TokenCalibration', () {
    test('reports 1.0 until enough samples exist', () {
      final c = TokenCalibration(minSamples: 3);
      c.observe(
        providerId: 'anthropic',
        modelId: 'm',
        estimatedTokens: 1000,
        observedPromptTokens: 2000,
      );
      expect(
        c.factorFor(providerId: 'anthropic', modelId: 'm'),
        1.0,
        reason: 'one sample is not enough to correct every estimate',
      );
    });

    test('converges on the observed/estimated ratio', () {
      final c = TokenCalibration(minSamples: 2);
      for (var i = 0; i < 4; i++) {
        c.observe(
          providerId: 'anthropic',
          modelId: 'm',
          estimatedTokens: 1000,
          observedPromptTokens: 1500,
        );
      }
      expect(c.factorFor(providerId: 'anthropic', modelId: 'm'), 1.5);
      expect(c.calibrate(2000, providerId: 'anthropic', modelId: 'm'), 3000);
      expect(c.isCalibrated, isTrue);
      expect(c.samplesFor(providerId: 'anthropic', modelId: 'm'), 4);
    });

    test('clamps a pathological sample', () {
      final c = TokenCalibration(minSamples: 1, maxFactor: 2.0);
      c.observe(
        providerId: 'p',
        modelId: 'm',
        estimatedTokens: 10,
        observedPromptTokens: 10000,
      );
      expect(c.factorFor(providerId: 'p', modelId: 'm'), 2.0);
    });

    test('falls back to the all-purpose bucket', () {
      final c = TokenCalibration(minSamples: 2);
      for (var i = 0; i < 2; i++) {
        c.observe(
          providerId: 'p',
          modelId: 'm',
          purpose: LlmCallPurpose.main,
          estimatedTokens: 100,
          observedPromptTokens: 200,
        );
      }
      // A compaction call with no samples of its own uses the main-turn ratio.
      expect(
        c.factorFor(
          providerId: 'p',
          modelId: 'm',
          purpose: LlmCallPurpose.compaction,
        ),
        2.0,
      );
    });

    test('ignores non-positive inputs', () {
      final c = TokenCalibration();
      c.observe(
        providerId: 'p',
        modelId: 'm',
        estimatedTokens: 0,
        observedPromptTokens: 100,
      );
      c.observe(
        providerId: 'p',
        modelId: 'm',
        estimatedTokens: 100,
        observedPromptTokens: 0,
      );
      expect(c.samplesFor(providerId: 'p', modelId: 'm'), 0);
      expect(c.isCalibrated, isFalse);
      c.reset();
    });
  });
}
