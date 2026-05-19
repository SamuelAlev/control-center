// ignore_for_file: avoid_classes_with_only_static_members

import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';

/// The role of a handoff message.
enum HandoffRole {
  /// A user / human turn.
  user,

  /// An assistant / agent turn.
  assistant,

  /// A tool-result turn.
  tool,
}

/// A provider-neutral content block used when replaying a conversation across a
/// model/provider switch.
sealed class HandoffBlock {
  /// Const base constructor.
  const HandoffBlock();
}

/// Extended-thinking content with an optional provider signature.
class HandoffThinking extends HandoffBlock {
  /// Creates a [HandoffThinking].
  const HandoffThinking(this.text, {this.signature});

  /// The reasoning text.
  final String text;

  /// The opaque provider signature, if the source model emitted one.
  final String? signature;
}

/// Visible answer text.
class HandoffText extends HandoffBlock {
  /// Creates a [HandoffText].
  const HandoffText(this.text);

  /// The text.
  final String text;
}

/// A tool / function call.
class HandoffToolCall extends HandoffBlock {
  /// Creates a [HandoffToolCall].
  const HandoffToolCall({
    required this.id,
    required this.name,
    this.input = const {},
  });

  /// Pairing id.
  final String id;

  /// Tool name.
  final String name;

  /// Tool arguments.
  final Map<String, dynamic> input;
}

/// A tool result.
class HandoffToolResult extends HandoffBlock {
  /// Creates a [HandoffToolResult].
  const HandoffToolResult({
    required this.id,
    required this.output,
    this.isError = false,
  });

  /// Pairing id (matches the call).
  final String id;

  /// Result text.
  final String output;

  /// Whether the tool errored / was aborted.
  final bool isError;
}

/// An image attachment (preserved verbatim across handoff).
class HandoffImage extends HandoffBlock {
  /// Creates a [HandoffImage].
  const HandoffImage({required this.mimeType, required this.dataRef});

  /// MIME type.
  final String mimeType;

  /// An opaque reference to the image data (path / url / id).
  final String dataRef;
}

/// One message in a provider-neutral conversation replay.
class HandoffMessage {
  /// Creates a [HandoffMessage].
  const HandoffMessage({
    required this.role,
    required this.blocks,
    this.aborted = false,
  });

  /// The role.
  final HandoffRole role;

  /// Ordered content blocks.
  final List<HandoffBlock> blocks;

  /// Whether the turn ended abnormally (error / aborted) — its pending tool
  /// calls get synthetic "aborted" results.
  final bool aborted;
}

/// Transforms a conversation for a mid-session model/provider switch.
///
/// On a **cross-provider** switch the target can't reverify the source's
/// thinking signatures, so thinking blocks are demoted to plain
/// `<thinking>…</thinking>` text. Tool calls/results and images are preserved.
/// Pending tool calls left by aborted/error turns get synthetic results so the
/// target model sees a well-formed call/result pairing.
abstract final class MessageHandoff {
  /// Transforms [messages] for a handoff.
  ///
  /// When [crossProvider] is true thinking is demoted to text; otherwise signed
  /// thinking is preserved. [synthesizeMissingResults] (default true) injects
  /// synthetic results for unmatched tool calls.
  static List<HandoffMessage> transform(
    List<HandoffMessage> messages, {
    required bool crossProvider,
    bool synthesizeMissingResults = true,
  }) {
    // Pass 1: rewrite blocks (thinking demotion).
    final pass1 = <HandoffMessage>[];
    for (final msg in messages) {
      final blocks = <HandoffBlock>[];
      for (final b in msg.blocks) {
        if (b is HandoffThinking) {
          if (crossProvider) {
            // Demote to tagged text; drop the unverifiable signature.
            if (b.text.trim().isNotEmpty) {
              blocks.add(HandoffText('<thinking>\n${b.text}\n</thinking>'));
            }
          } else {
            blocks.add(b); // same provider → keep signed thinking
          }
        } else {
          blocks.add(b);
        }
      }
      pass1.add(
        HandoffMessage(role: msg.role, blocks: blocks, aborted: msg.aborted),
      );
    }

    if (!synthesizeMissingResults) {
      return pass1;
    }

    // Pass 2: ensure every tool call has a following result.
    final resultIds = <String>{};
    for (final msg in pass1) {
      for (final b in msg.blocks) {
        if (b is HandoffToolResult) {
          resultIds.add(b.id);
        }
      }
    }

    final out = <HandoffMessage>[];
    for (final msg in pass1) {
      out.add(msg);
      if (msg.role != HandoffRole.assistant) {
        continue;
      }
      final pending = <HandoffToolCall>[
        for (final b in msg.blocks)
          if (b is HandoffToolCall && !resultIds.contains(b.id)) b,
      ];
      if (pending.isEmpty) {
        continue;
      }
      final synthetic = <HandoffBlock>[
        for (final call in pending)
          HandoffToolResult(
            id: call.id,
            output: msg.aborted ? 'aborted' : 'No result provided',
            isError: true,
          ),
      ];
      for (final call in pending) {
        resultIds.add(call.id);
      }
      out.add(HandoffMessage(role: HandoffRole.tool, blocks: synthetic));
    }
    return out;
  }

  /// Maps an agent turn's [TranscriptSegment] list to a single assistant
  /// [HandoffMessage]. Reasoning → thinking, text → text, tools → call+result
  /// pairs (a running/interrupted tool marks the turn aborted).
  static HandoffMessage fromTranscript(List<TranscriptSegment> segments) {
    final blocks = <HandoffBlock>[];
    var aborted = false;
    for (final s in segments) {
      switch (s) {
        case ReasoningSegment(:final text):
          if (text.isNotEmpty) {
            blocks.add(HandoffThinking(text));
          }
        case TextSegment(:final text):
          if (text.isNotEmpty) {
            blocks.add(HandoffText(text));
          }
        case ToolSegment(
          :final toolName,
          :final toolCallId,
          :final inputs,
          :final outputs,
          :final status,
        ):
          final id = toolCallId.isEmpty ? toolName : toolCallId;
          blocks.add(
            HandoffToolCall(id: id, name: toolName, input: inputs ?? const {}),
          );
          if (status == ToolSegmentStatus.ok ||
              status == ToolSegmentStatus.error) {
            blocks.add(
              HandoffToolResult(
                id: id,
                output: outputs,
                isError: status == ToolSegmentStatus.error,
              ),
            );
          } else {
            aborted = true; // running / interrupted → no result yet
          }
        case ErrorSegment():
          aborted = true;
        case ViolationSegment():
          break;
      }
    }
    return HandoffMessage(
      role: HandoffRole.assistant,
      blocks: blocks,
      aborted: aborted,
    );
  }
}
