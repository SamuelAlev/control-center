import 'package:cc_harness/provider.dart';
import 'package:test/test.dart';

void main() {
  group('LlmUsage', () {
    test('operator + sums every count', () {
      const a = LlmUsage(
        inputTokens: 1,
        outputTokens: 2,
        cacheReadTokens: 3,
        cacheWriteTokens: 4,
        thoughtTokens: 5,
      );
      const b = LlmUsage(
        inputTokens: 10,
        outputTokens: 20,
        cacheReadTokens: 30,
        cacheWriteTokens: 40,
        thoughtTokens: 50,
      );
      final sum = a + b;
      expect(sum.inputTokens, 11);
      expect(sum.outputTokens, 22);
      expect(sum.cacheReadTokens, 33);
      expect(sum.cacheWriteTokens, 44);
      expect(sum.thoughtTokens, 55);
    });

    test('+ with zero left operand returns the right operand counts', () {
      final sum =
          const LlmUsage() + const LlmUsage(inputTokens: 7, outputTokens: 8);
      expect(sum.inputTokens, 7);
      expect(sum.outputTokens, 8);
    });
  });

  group('LlmStopReason', () {
    test('fromWire maps Anthropic + OpenAI spellings', () {
      expect(LlmStopReason.fromWire('end_turn'), LlmStopReason.endTurn);
      expect(LlmStopReason.fromWire('stop'), LlmStopReason.endTurn);
      expect(LlmStopReason.fromWire('tool_use'), LlmStopReason.toolUse);
      expect(LlmStopReason.fromWire('tool_calls'), LlmStopReason.toolUse);
      expect(LlmStopReason.fromWire('max_tokens'), LlmStopReason.maxTokens);
      expect(LlmStopReason.fromWire('length'), LlmStopReason.maxTokens);
      expect(
        LlmStopReason.fromWire('stop_sequence'),
        LlmStopReason.stopSequence,
      );
    });

    test('fromWire defaults null/unrecognized to unknown', () {
      expect(LlmStopReason.fromWire(null), LlmStopReason.unknown);
      expect(LlmStopReason.fromWire('weird'), LlmStopReason.unknown);
    });
  });

  group('LlmCallPurpose', () {
    test('every purpose has a stable wire spelling', () {
      expect(LlmCallPurpose.main.wire, 'main');
      expect(LlmCallPurpose.compaction.wire, 'compaction');
      expect(LlmCallPurpose.advisor.wire, 'advisor');
      expect(LlmCallPurpose.sideRequest.wire, 'side_request');
      expect(LlmCallPurpose.subagent.wire, 'subagent');
      for (final purpose in LlmCallPurpose.values) {
        expect(LlmCallPurpose.fromWire(purpose.wire), purpose);
      }
    });
  });
}
