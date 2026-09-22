import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';

/// One line of a side-channel prompt, or null when [message] has no text.
///
/// `/handoff` and `/btw` share this so the character budget and the prompt
/// agree on which rows count. An agent turn with an empty [Message.content]
/// contributes its transcript (tool calls included, tool output left out).
String? sideChannelLine(Message message) {
  final body = _body(message);
  if (body.isEmpty) {
    return null;
  }
  final who = message.isUser
      ? 'User'
      : message.isAgentTurn
      ? (message.metadata?['agentName'] as String? ?? 'Agent')
      : 'System';
  return '$who: $body';
}

String _body(Message message) {
  if (message.isAgentTurn && message.content.trim().isEmpty) {
    return _transcriptText(message);
  }
  return message.content.trim();
}

/// Readable text of an agent turn whose content is empty because its
/// substance lives in transcript segments.
String _transcriptText(Message message) {
  final parts = <String>[];
  for (final segment in message.transcript) {
    switch (segment) {
      case TextSegment(:final text):
        parts.add(text.trim());
      case ToolSegment(:final toolName, :final inputs):
        // The tool call is the useful signal for a handoff ("it edited
        // auth.dart"); the output is bulk and usually stale.
        final target = inputs?['path'] ?? inputs?['file_path'] ?? '';
        parts.add('[$toolName${target == '' ? '' : ' $target'}]');
      case ErrorSegment(:final message):
        parts.add('[error: $message]');
      case ReasoningSegment():
      case ViolationSegment():
        break;
    }
  }
  return parts.where((part) => part.isNotEmpty).join('\n');
}
