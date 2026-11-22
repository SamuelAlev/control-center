import 'package:cc_infra/src/sandboxing/claude_stream_json.dart';
import 'package:test/test.dart';

ClaudeCallUsage _call(
  String id, {
  int input = 0,
  int read = 0,
  int write = 0,
  int output = 0,
  String? model,
  bool subagent = false,
}) => ClaudeCallUsage(
  messageId: id,
  inputTokens: input,
  cacheReadTokens: read,
  cacheWriteTokens: write,
  outputTokens: output,
  callStarted: false,
  model: model,
  subagent: subagent,
);

/// One micro-dollar per prompt token and ten per output token, for a priced
/// model; none for `unpriced`.
int? _price(ClaudeCallUsage c) => c.model == 'unpriced'
    ? null
    : c.inputTokens +
          c.cacheReadTokens +
          c.cacheWriteTokens +
          10 * c.outputTokens;

void main() {
  group('ClaudeUnreportedUsage', () {
    test('repeated reports of one call count it once, at its largest', () {
      final pending = ClaudeUnreportedUsage();
      // message_start, then an `assistant` line with a partial output count,
      // then message_delta with the final one, then a stale partial again.
      expect(pending.record(_call('m1', read: 100, output: 1), _price), true);
      expect(pending.record(_call('m1', read: 100, output: 8), _price), true);
      expect(pending.record(_call('m1', read: 100, output: 245), _price), true);
      expect(pending.record(_call('m1', read: 100, output: 8), _price), false);

      expect(pending.calls, 1);
      expect(pending.cacheReadTokens, 100);
      expect(pending.outputTokens, 245);
      expect(pending.pricedMicros, 100 + 2450);
    });

    test('distinct calls add up, each priced alone', () {
      final pending = ClaudeUnreportedUsage()
        ..record(_call('m1', input: 2, write: 300, output: 10), _price)
        ..record(_call('s1', read: 50, output: 4, subagent: true), _price);
      expect(pending.calls, 2);
      expect(pending.inputTokens, 2);
      expect(pending.cacheReadTokens, 50);
      expect(pending.cacheWriteTokens, 300);
      expect(pending.outputTokens, 14);
      expect(pending.pricedMicros, (302 + 100) + (50 + 40));
      expect(pending.hasUnpriced, false);
    });

    test('a call with no known price keeps its tokens, not a cost', () {
      final pending = ClaudeUnreportedUsage()
        ..record(_call('m1', read: 10, model: 'unpriced'), _price);
      expect(pending.cacheReadTokens, 10);
      expect(pending.pricedMicros, 0);
      expect(pending.hasUnpriced, true);
    });

    test('a reported cost keeps the tokens and drops only the estimate', () {
      final pending = ClaudeUnreportedUsage()
        ..record(_call('m1', read: 100, output: 5), _price)
        ..dropEstimates();
      expect(pending.cacheReadTokens, 100);
      expect(pending.outputTokens, 5);
      expect(pending.pricedMicros, 0);
      // A later report of the same call grows its tokens, still unpriced.
      expect(pending.record(_call('m1', read: 100, output: 9), _price), true);
      expect(pending.outputTokens, 9);
      expect(pending.pricedMicros, 0);
      // A call that starts afterwards is estimated as usual.
      pending.record(_call('m2', read: 7), _price);
      expect(pending.pricedMicros, 7);
    });

    test('settled calls are cleared and a late report of one is ignored', () {
      final pending = ClaudeUnreportedUsage()
        ..record(_call('m1', read: 100, output: 5), _price)
        ..settle();
      expect(pending.isEmpty, true);
      expect(pending.pricedMicros, 0);
      expect(pending.record(_call('m1', read: 100, output: 9), _price), false);
      expect(pending.isEmpty, true);
      expect(pending.record(_call('m2', read: 7), _price), true);
      expect(pending.cacheReadTokens, 7);
    });
  });

  test('ClaudeDispatchTotals.addUnreported folds tokens and estimate in', () {
    final pending = ClaudeUnreportedUsage()
      ..record(_call('m1', input: 1, read: 20, write: 3, output: 4), _price)
      ..record(_call('m2', read: 5, model: 'unpriced'), _price);
    final totals = ClaudeDispatchTotals()..addUnreported(pending);
    expect(totals.hasTokenData, true);
    expect(totals.inputTokens, 1);
    expect(totals.cacheReadTokens, 25);
    expect(totals.cacheWriteTokens, 3);
    expect(totals.outputTokens, 4);
    expect(totals.costMicros, 24 + 40);
    expect(totals.costUnavailable, true, reason: 'one call had no price');
  });
}
