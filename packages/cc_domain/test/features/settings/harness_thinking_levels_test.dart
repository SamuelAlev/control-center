import 'package:cc_domain/features/model_routing/domain/entities/model_info.dart';
import 'package:cc_domain/features/settings/domain/services/harness_thinking_levels.dart';
import 'package:cc_harness/provider.dart' show ReasoningEffort;
import 'package:test/test.dart';

ModelInfo _model({ThinkingConfig? thinking}) => ModelInfo(
  id: 'glm-5.3',
  providerId: 'zhipuai',
  name: 'GLM 5.3',
  thinking: thinking,
);

void main() {
  group('harnessThinkingLevels', () {
    test('a catalog miss offers the full harness scale, defaulting to medium', () {
      final result = harnessThinkingLevels(null);

      // The run keeps thinking on and passes the effort through unclamped, so
      // hiding the picker here is what left the built-in adapter looking as if
      // it had no effort knob.
      expect(
        result.levels?.map((l) => l.id),
        ['minimal', 'low', 'medium', 'high', 'xhigh'],
      );
      expect(result.defaultLevel, 'medium');
    });

    test('a known reasoning model offers exactly the efforts it accepts', () {
      final result = harnessThinkingLevels(
        _model(
          thinking: const ThinkingConfig(
            efforts: [ReasoningEffort.high, ReasoningEffort.xhigh],
            defaultLevel: ReasoningEffort.high,
          ),
        ),
      );

      expect(result.levels?.map((l) => l.id), ['high', 'xhigh']);
      expect(result.defaultLevel, 'high');
    });

    test('a known non-reasoning model offers no levels at all', () {
      final result = harnessThinkingLevels(_model());

      expect(result.levels, isNull);
      expect(result.defaultLevel, isNull);
    });

    test('an empty effort list is treated as non-reasoning, not as a crash', () {
      final result = harnessThinkingLevels(
        _model(thinking: const ThinkingConfig()),
      );

      expect(result.levels, isNull);
      expect(result.defaultLevel, isNull);
    });

    test('a declared default is honoured; otherwise the first effort wins', () {
      // `ThinkingConfig.resolve(null)` falls back to `efforts.first` the same
      // way, so the pre-filled level matches what the run actually uses.
      final result = harnessThinkingLevels(
        _model(
          thinking: const ThinkingConfig(
            efforts: [ReasoningEffort.low, ReasoningEffort.high],
          ),
        ),
      );

      expect(result.defaultLevel, 'low');
    });

    test('every offered level round-trips through ReasoningEffort.fromId', () {
      // The dispatch path parses the stored id back with `fromId`; a label-ish
      // or renamed id would silently fall back to medium.
      for (final level in harnessEffortLevels) {
        expect(
          ReasoningEffort.fromId(level.id),
          isNotNull,
          reason: '${level.id} must survive the dispatch round-trip',
        );
      }
    });
  });
}
