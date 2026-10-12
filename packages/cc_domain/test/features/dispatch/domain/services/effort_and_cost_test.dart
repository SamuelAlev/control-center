import 'package:cc_harness/provider.dart';
import 'package:test/test.dart';

void main() {
  group('effort mapping', () {
    test('anthropic effort maps minimal→low and clamps to xhigh', () {
      expect(anthropicEffort(ReasoningEffort.minimal), 'low');
      expect(anthropicEffort(ReasoningEffort.low), 'low');
      expect(anthropicEffort(ReasoningEffort.medium), 'medium');
      expect(anthropicEffort(ReasoningEffort.high), 'high');
      expect(anthropicEffort(ReasoningEffort.xhigh), 'xhigh');
    });

    test('openai effort collapses xhigh→high', () {
      expect(openAiEffort(ReasoningEffort.minimal), 'minimal');
      expect(openAiEffort(ReasoningEffort.xhigh), 'high');
    });
  });
}
