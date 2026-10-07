import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_harness/context.dart';

/// Character count of [segments], measured the way the live transcript folder
/// counts a turn (text + reasoning + tool name/inputs/outputs + error prose).
///
/// Anything that rewrites a stored transcript (pruning) must re-stamp
/// `metadata['transcriptChars']` with this, or the stored count — which the
/// meter and the list wire read instead of the segments — keeps describing
/// output that is no longer there.
int transcriptCharCount(Iterable<TranscriptSegment> segments) {
  var total = 0;
  for (final segment in segments) {
    total += switch (segment) {
      TextSegment(:final text) => text.length,
      ReasoningSegment(:final text) => text.length,
      ToolSegment(:final toolName, :final inputs, :final outputs) =>
        toolName.length + (inputs?.toString().length ?? 0) + outputs.length,
      ErrorSegment(:final message) => message.length,
      ViolationSegment(:final message) => message.length,
    };
  }
  return total;
}

/// Conversation-shaped token estimation over the kernel's [TokenEstimator].
///
/// The estimator itself moved into `cc_harness` (PRD 26.1) and is text-level
/// only; these helpers keep the `Message` / [TranscriptSegment]
/// accounting host-side, where those entities live.
extension ConversationTokenEstimate on TokenEstimator {
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
  ///
  /// List-wire agent turns ship WITHOUT their segments (`segments_elided`) but
  /// carry the server-counted `metadata['transcriptChars']`, so the estimate
  /// stays accurate on a thin client without pulling the transcript.
  int estimateMessage(Message message) {
    if (message.isAgentTurn) {
      final segments = message.transcript;
      if (segments.isNotEmpty) {
        var total = 0;
        for (final s in segments) {
          total += estimateSegment(s);
        }
        return total;
      }
      final chars = message.metadata?['transcriptChars'];
      if (chars is num && chars > 0) {
        return estimateChars(chars.toInt());
      }
    }
    return estimate(message.content);
  }

  /// Sum of [estimateMessage] across [messages].
  int estimateMessages(Iterable<Message> messages) {
    var total = 0;
    for (final m in messages) {
      total += estimateMessage(m);
    }
    return total;
  }
}
