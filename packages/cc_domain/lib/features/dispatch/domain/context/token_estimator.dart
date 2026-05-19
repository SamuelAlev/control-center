import 'package:cc_domain/core/domain/entities/channel_message.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';

/// Heuristic token estimation for context-window accounting.
///
/// CC does not have a provider-side tokenizer in the pure domain layer, so we
/// approximate. The widely-used rule of thumb for English+code is ~4 characters
/// per token; code and JSON skew a little denser, so we bias slightly toward
/// over-counting (which is the safe direction for a budget: it triggers
/// compaction a touch early rather than overflowing the real window).
///
/// Estimates are intentionally cheap and deterministic — no I/O, no model call.
/// When an adapter reports real usage via `RunCost`, prefer that for the live
/// meter and use these estimates only to plan ahead (deciding what to keep
/// verbatim, where to cut, how much a prune would reclaim).
class TokenEstimator {
  /// Creates a [TokenEstimator] with the given [charsPerToken] divisor.
  const TokenEstimator({this.charsPerToken = 3.8});

  /// Average characters per token. Lower = more tokens per char (denser).
  final double charsPerToken;

  /// A shared default instance.
  static const TokenEstimator instance = TokenEstimator();

  /// Estimated token count for an arbitrary [text]. Always `>= 0`.
  int estimate(String text) {
    if (text.isEmpty) {
      return 0;
    }
    return (text.length / charsPerToken).ceil();
  }

  /// Estimated tokens carried by a single transcript [segment], counting its
  /// rendered text (answer, reasoning, tool inputs + outputs, error prose).
  int estimateSegment(TranscriptSegment segment) {
    switch (segment) {
      case TextSegment(:final text):
        return estimate(text);
      case ReasoningSegment(:final text):
        return estimate(text);
      case ToolSegment(:final toolName, :final inputs, :final outputs):
        final buf = StringBuffer(toolName);
        if (inputs != null) {
          buf.write(inputs.toString());
        }
        buf.write(outputs);
        return estimate(buf.toString());
      case ErrorSegment(:final message):
        return estimate(message);
      case ViolationSegment(:final message):
        return estimate(message);
    }
  }

  /// Estimated tokens for a whole [message]. For agent turns this sums the
  /// transcript segments; for everything else it counts the rendered content.
  int estimateMessage(ChannelMessage message) {
    if (message.isAgentTurn) {
      final segments = message.transcript;
      if (segments.isNotEmpty) {
        var total = 0;
        for (final s in segments) {
          total += estimateSegment(s);
        }
        return total;
      }
    }
    return estimate(message.content);
  }

  /// Sum of [estimateMessage] across [messages].
  int estimateMessages(Iterable<ChannelMessage> messages) {
    var total = 0;
    for (final m in messages) {
      total += estimateMessage(m);
    }
    return total;
  }

  /// Converts a character budget (CC's `Agent.contextSize`, measured in
  /// characters) into an estimated token window for the same content.
  int windowTokensFromChars(int chars) => (chars / charsPerToken).floor();
}
