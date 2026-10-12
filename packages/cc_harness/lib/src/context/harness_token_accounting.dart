/// Token accounting for the built-in harness history.
///
/// Reuses the shared [TokenEstimator] heuristic (no provider tokenizer in the
/// pure domain layer) to size a [HarnessMessage] list against a model's context
/// window, so the loop knows when to compact.
library;

import 'package:cc_harness/src/context/token_calibration.dart';
import 'package:cc_harness/src/context/token_estimator.dart';
import 'package:cc_harness/src/messages.dart';
import 'package:cc_harness/src/provider/llm_provider_port.dart';

/// Approximate tokens billed for one image. Providers charge a flat-ish block
/// per image, so this is a constant rather than a function of the base64
/// length (which is not text tokens and would overcount by ~10x).
const int kImageTokenCost = 1200;

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
      return estimator.estimate(content) + images.length * kImageTokenCost;
    case HarnessImageBlock():
      return kImageTokenCost;
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

/// The number of image blocks [history] carries, counting both tool-result
/// images and user/tool-attached images.
///
/// Providers reject a request past a hard per-request image ceiling, so this is
/// the count that has to be budgeted — not the token estimate, which prices an
/// image as a flat block and cannot see a 400 coming.
int countHarnessImages(List<HarnessMessage> history) {
  var total = 0;
  for (final m in history) {
    for (final b in m.content) {
      if (b is HarnessToolResultBlock) {
        total += b.images.length;
      } else if (b is HarnessImageBlock) {
        total += 1;
      }
    }
  }
  return total;
}

/// Applies a [TokenCalibration] correction to an estimate, when one is wired.
///
/// Returns [estimatedTokens] unchanged when [calibration] is null, the provider
/// or model is unknown, or the bucket does not yet have enough observations.
int calibratedHarnessTokens(
  int estimatedTokens, {
  TokenCalibration? calibration,
  String? providerId,
  String? modelId,
  LlmCallPurpose purpose = LlmCallPurpose.main,
}) {
  if (calibration == null ||
      providerId == null ||
      providerId.isEmpty ||
      modelId == null ||
      modelId.isEmpty) {
    return estimatedTokens;
  }
  return calibration.calibrate(
    estimatedTokens,
    providerId: providerId,
    modelId: modelId,
    purpose: purpose,
  );
}

/// Whether a history fits the provider's token and image ceilings.
class HarnessContextFit {
  /// Creates a fit report.
  const HarnessContextFit({
    required this.historyTokens,
    required this.overheadTokens,
    required this.images,
    this.contextWindow,
    this.imageLimit,
  });

  /// Estimated tokens in the messages.
  final int historyTokens;

  /// Tokens reserved for system prompt + tool schemas + output.
  final int overheadTokens;

  /// Image blocks the messages carry.
  final int images;

  /// The model's context window, or null when unknown.
  final int? contextWindow;

  /// The provider's per-request image ceiling, or null when unknown.
  final int? imageLimit;

  /// Total estimated prompt tokens.
  int get totalTokens => historyTokens + overheadTokens;

  /// Whether the token estimate fits under [contextWindow]. True when unknown.
  bool get fitsTokens => contextWindow == null || totalTokens < contextWindow!;

  /// Whether the image count fits under [imageLimit]. True when unknown.
  bool get fitsImages => imageLimit == null || images <= imageLimit!;

  /// Whether both ceilings are respected.
  bool get fits => fitsTokens && fitsImages;

  /// Tokens left under the window (negative when over).
  int get headroomTokens =>
      contextWindow == null ? 0 : contextWindow! - totalTokens;
}

/// Sizes [history] against the provider's token and image ceilings.
HarnessContextFit checkHarnessContextFit(
  List<HarnessMessage> history, {
  int? contextWindow,
  int overheadTokens = 0,
  int? imageLimit,
  TokenEstimator estimator = TokenEstimator.instance,
}) => HarnessContextFit(
  historyTokens: estimateHarnessHistory(history, estimator: estimator),
  overheadTokens: overheadTokens,
  images: countHarnessImages(history),
  contextWindow: contextWindow,
  imageLimit: imageLimit,
);
