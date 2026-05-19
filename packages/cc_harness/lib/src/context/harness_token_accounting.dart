/// Token accounting for the built-in harness history.
///
/// Reuses the shared [TokenEstimator] heuristic (no provider tokenizer in the
/// pure domain layer) to size a [HarnessMessage] list against a model's context
/// window, so the loop knows when to compact.
library;

import 'dart:convert';

import 'package:cc_harness/src/context/token_estimator.dart';
import 'package:cc_harness/src/messages.dart';

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
    case HarnessToolUseBlock(:final name, :final input):
      return estimator.estimate('$name ${jsonEncode(input)}');
    case HarnessToolResultBlock(:final content):
      return estimator.estimate(content);
    case HarnessImageBlock():
      // Images are billed by the provider as a flat-ish token block; approximate
      // rather than counting the base64 length (which is not text tokens).
      return 1200;
  }
}

/// Estimated tokens carried by a single [message] (sum of its blocks + a small
/// per-message framing allowance).
int estimateHarnessMessage(
  HarnessMessage message, {
  TokenEstimator estimator = TokenEstimator.instance,
}) {
  var total = 4; // role + framing overhead
  for (final block in message.content) {
    total += estimateHarnessBlock(block, estimator: estimator);
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
