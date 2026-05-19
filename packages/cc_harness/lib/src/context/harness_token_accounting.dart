/// Token accounting for the built-in harness history.
///
/// Reuses the shared [TokenEstimator] heuristic (no provider tokenizer in the
/// pure domain layer) to size a [HarnessMessage] list against a model's context
/// window, so the loop knows when to compact.
library;

import 'package:cc_harness/src/context/token_estimator.dart';
import 'package:cc_harness/src/messages.dart';

/// Approximate tokens billed for one image. Providers charge a flat-ish block
/// per image, so this is a constant rather than a function of the base64
/// length (which is not text tokens and would overcount by ~10x).
const int kImageTokenCost = 1200;

/// Deprecated private alias kept for the existing call sites in this file.
const int _imageTokens = kImageTokenCost;

/// Per-message memo of the default-estimator token count.
///
/// Messages are immutable once appended, but [estimateHarnessHistory] is
/// re-run over the WHOLE history on every turn (before the compaction
/// threshold check), and a tool-use block re-`jsonEncode`s its whole argument
/// map each time. That is O(n²) over a session. An [Expando] keeps the memo
/// off the message type and lets a folded-away message be collected normally.
final Expando<int> _messageTokenMemo = Expando<int>('harnessMessageTokens');

/// Estimated tokens carried by a single content [block].
int estimateHarnessBlock(
  HarnessContentBlock block, {
  TokenEstimator estimator = TokenEstimator.instance,
}) {
  switch (block) {
    case HarnessTextBlock(:final text):
      return estimator.estimate(text);
    case HarnessThinkingBlock(:final thinking):
      return estimator.estimate(thinking);
    case HarnessToolUseBlock(:final name):
      // `block.encodedInput` is memoized on the block; re-serializing every
      // accumulated argument map on every turn is O(n²) over a run.
      return estimator.estimate('$name ${block.encodedInput}');
    case HarnessToolResultBlock(:final content, :final images):
      return estimator.estimate(content) + images.length * _imageTokens;
    case HarnessImageBlock():
      return _imageTokens;
  }
}

/// Estimated tokens carried by a single [message] (sum of its blocks + a small
/// per-message framing allowance).
int estimateHarnessMessage(
  HarnessMessage message, {
  TokenEstimator estimator = TokenEstimator.instance,
}) {
  // Only the shared singleton is memoized — a caller-supplied estimator would
  // produce a different number for the same message.
  final memoizable = identical(estimator, TokenEstimator.instance);
  if (memoizable) {
    final cached = _messageTokenMemo[message];
    if (cached != null) {
      return cached;
    }
  }
  var total = 4; // role + framing overhead
  for (final block in message.content) {
    total += estimateHarnessBlock(block, estimator: estimator);
  }
  if (memoizable) {
    _messageTokenMemo[message] = total;
  }
  return total;
}

/// Estimated tokens for the whole [history].
int estimateHarnessHistory(
  List<HarnessMessage> history, {
  TokenEstimator estimator = TokenEstimator.instance,
}) {
  var total = 0;
  for (final m in history) {
    total += estimateHarnessMessage(m, estimator: estimator);
  }
  return total;
}
