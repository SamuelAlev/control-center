import 'package:cc_domain/features/dispatch/domain/budget/model_fallback.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolveModelFallbackChain', () {
    test('returns the candidates that follow the selected model in order', () {
      expect(
        resolveModelFallbackChain(
          candidates: const ['a', 'b', 'c'],
          selectedModel: 'a',
          authFallbackUsed: false,
        ),
        const ['b', 'c'],
      );
    });

    test('returns only the tail when selected is in the middle', () {
      expect(
        resolveModelFallbackChain(
          candidates: const ['a', 'b', 'c'],
          selectedModel: 'b',
          authFallbackUsed: false,
        ),
        const ['c'],
      );
    });

    test('returns empty when selected is the last candidate', () {
      expect(
        resolveModelFallbackChain(
          candidates: const ['a', 'b', 'c'],
          selectedModel: 'c',
          authFallbackUsed: false,
        ),
        isEmpty,
      );
    });

    test('returns empty when selectedModel is null', () {
      expect(
        resolveModelFallbackChain(
          candidates: const ['a', 'b', 'c'],
          selectedModel: null,
          authFallbackUsed: false,
        ),
        isEmpty,
      );
    });

    test('returns empty when an auth fallback was already used', () {
      expect(
        resolveModelFallbackChain(
          candidates: const ['a', 'b', 'c'],
          selectedModel: 'a',
          authFallbackUsed: true,
        ),
        isEmpty,
      );
    });

    test('returns empty when there is only one candidate', () {
      expect(
        resolveModelFallbackChain(
          candidates: const ['a'],
          selectedModel: 'a',
          authFallbackUsed: false,
        ),
        isEmpty,
      );
    });

    test('returns empty when there are no candidates', () {
      expect(
        resolveModelFallbackChain(
          candidates: const [],
          selectedModel: 'a',
          authFallbackUsed: false,
        ),
        isEmpty,
      );
    });

    test('returns empty when selected model is not in candidates', () {
      expect(
        resolveModelFallbackChain(
          candidates: const ['a', 'b', 'c'],
          selectedModel: 'z',
          authFallbackUsed: false,
        ),
        isEmpty,
      );
    });

    test('result is unmodifiable', () {
      final chain = resolveModelFallbackChain(
        candidates: const ['a', 'b', 'c'],
        selectedModel: 'a',
        authFallbackUsed: false,
      );
      expect(() => chain.add('d'), throwsUnsupportedError);
    });
  });

  group('ModelFallbackPlan', () {
    test('resolve mirrors resolveModelFallbackChain', () {
      final plan = ModelFallbackPlan.resolve(
        candidates: const ['a', 'b', 'c'],
        selectedModel: 'a',
        authFallbackUsed: false,
      );
      expect(plan.selected, 'a');
      expect(plan.fallbacks, const ['b', 'c']);
      expect(plan.hasFallback, isTrue);
    });

    test('hasFallback is false when no fallback resolves', () {
      final plan = ModelFallbackPlan.resolve(
        candidates: const ['a'],
        selectedModel: 'a',
        authFallbackUsed: false,
      );
      expect(plan.fallbacks, isEmpty);
      expect(plan.hasFallback, isFalse);
    });

    test('equality is by value', () {
      const a = ModelFallbackPlan(selected: 'a', fallbacks: ['b', 'c']);
      const b = ModelFallbackPlan(selected: 'a', fallbacks: ['b', 'c']);
      const c = ModelFallbackPlan(selected: 'a', fallbacks: ['b']);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });
  });
}
