import 'package:cc_domain/core/domain/entities/channel_message.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';

/// Input to a conversation summarizer: the span of messages to fold, plus the
/// prior anchored summary to update (preserve still-true, drop stale, merge new).
class CompactionInput {
  /// Creates a [CompactionInput].
  const CompactionInput({
    required this.messages,
    this.previousSummary,
    this.selfAgentName = 'assistant',
  });

  /// The messages (ascending) being compacted.
  final List<ChannelMessage> messages;

  /// The prior anchored summary text, if this conversation was compacted before.
  final String? previousSummary;

  /// Display name used to label the agent's turns in the rendered history.
  final String selfAgentName;
}

/// Produces an anchored summary that stands in for a span of older messages.
///
/// Implementations may call an LLM (true abstraction + merge) or fall back to a
/// deterministic structural digest. Either way the result REPLACES the lossy
/// 120-char-excerpt compactor: tool noise and reasoning are dropped (the
/// reclaim), while user requests and agent decisions are preserved.
abstract interface class ConversationSummarizerPort {
  /// Returns the anchored summary text for [input].
  Future<String> summarize(CompactionInput input);
}

/// The system instruction for an LLM-backed summarizer (ported from kilocode's
/// `PROMPT_COMPACTION`). Pair it with [buildCompactionUserPrompt].
const String compactionSystemPrompt =
    'You are an anchored context-summarization assistant for coding sessions. '
    'Summarize only the conversation history you are given. The newest turns '
    'are kept verbatim outside your summary, so focus on the older context that '
    'still matters for continuing the work: decisions made, constraints '
    'discovered, files and APIs touched, open questions, and the current plan. '
    'Be concise and factual — no preamble, no restating these instructions.\n\n'
    'If the history includes a <previous-summary> block, treat it as the '
    'current anchored summary: preserve still-true details, remove stale '
    'details, and merge in the new facts. Output only the updated summary.';

/// Builds the user-turn prompt for an LLM summarizer: the serialized history,
/// with the prior summary wrapped in a `<previous-summary>` anchor when present.
String buildCompactionUserPrompt(CompactionInput input) {
  final buf = StringBuffer();
  if (input.previousSummary != null && input.previousSummary!.trim().isNotEmpty) {
    buf
      ..writeln('<previous-summary>')
      ..writeln(input.previousSummary!.trim())
      ..writeln('</previous-summary>')
      ..writeln()
      ..writeln(
        'Update the anchored summary above using the conversation history '
        'below. Preserve still-true details, remove stale details, merge in '
        'new facts.',
      )
      ..writeln();
  } else {
    buf
      ..writeln('Create an anchored summary from the conversation history below.')
      ..writeln();
  }
  buf
    ..writeln('<conversation-history>')
    ..writeln(serializeCompactionHistory(input.messages, input.selfAgentName))
    ..writeln('</conversation-history>');
  return buf.toString();
}

/// Renders a span of messages into a compact, summarizer-friendly transcript:
/// user messages verbatim, agent answer text plus a thin trail of tool actions,
/// with reasoning and fat tool outputs dropped.
String serializeCompactionHistory(
  List<ChannelMessage> messages,
  String selfAgentName,
) {
  final buf = StringBuffer();
  for (final m in messages) {
    if (m.isUser) {
      buf
        ..writeln('# User')
        ..writeln(m.content.trim())
        ..writeln();
      continue;
    }
    if (m.isAgentTurn) {
      final answer = _agentAnswerText(m);
      final actions = _toolActions(m);
      buf.writeln('# $selfAgentName');
      if (answer.isNotEmpty) {
        buf.writeln(answer);
      }
      if (actions.isNotEmpty) {
        buf.writeln('(actions: ${actions.join(', ')})');
      }
      buf.writeln();
      continue;
    }
    // Other content-bearing messages (plain text, etc.).
    if (m.content.trim().isNotEmpty && !m.isContextSummary) {
      buf
        ..writeln('# ${m.isUser ? 'User' : selfAgentName}')
        ..writeln(m.content.trim())
        ..writeln();
    }
  }
  return buf.toString().trim();
}

String _agentAnswerText(ChannelMessage m) {
  final segments = m.transcript;
  if (segments.isEmpty) {
    return m.content.trim();
  }
  final parts = <String>[];
  for (final s in segments) {
    if (s is TextSegment && s.text.trim().isNotEmpty) {
      parts.add(s.text.trim());
    }
  }
  return parts.isEmpty ? m.content.trim() : parts.join('\n\n');
}

List<String> _toolActions(ChannelMessage m) {
  final names = <String>[];
  for (final s in m.transcript) {
    if (s is ToolSegment) {
      final name = s.toolName;
      if (!names.contains(name)) {
        names.add(name);
      }
    }
  }
  // Cap the trail so it stays a summary, not a log.
  return names.take(12).toList();
}

/// A deterministic, LLM-free summarizer. It cannot truly abstract or merge, so
/// it carries the prior summary forward unchanged and appends a structured
/// digest of the newly-compacted turns (user requests + agent answers + a thin
/// action trail). Reclaim comes from dropping reasoning and fat tool outputs.
///
/// This is the default backend so compaction works out of the box; wire a
/// [ConversationSummarizerPort] backed by an LLM (or vision frames) to upgrade
/// to true anchored summaries.
class StructuralConversationSummarizer implements ConversationSummarizerPort {
  /// Creates a [StructuralConversationSummarizer].
  const StructuralConversationSummarizer();

  @override
  Future<String> summarize(CompactionInput input) async {
    final buf = StringBuffer('## Conversation summary (compacted)\n');

    final prev = input.previousSummary?.trim();
    if (prev != null && prev.isNotEmpty) {
      buf
        ..writeln()
        ..writeln('### Established context')
        ..writeln(_stripHeading(prev));
    }

    buf
      ..writeln()
      ..writeln('### Newly compacted');
    for (final m in input.messages) {
      if (m.isUser) {
        buf.writeln('- **User:** ${_oneLine(m.content)}');
      } else if (m.isAgentTurn) {
        final answer = _agentAnswerText(m);
        if (answer.isNotEmpty) {
          buf.writeln('- **${input.selfAgentName}:** ${_oneLine(answer)}');
        }
        final actions = _toolActions(m);
        if (actions.isNotEmpty) {
          buf.writeln('  - actions: ${actions.join(', ')}');
        }
      } else if (m.content.trim().isNotEmpty && !m.isContextSummary) {
        buf.writeln('- ${_oneLine(m.content)}');
      }
    }
    return buf.toString().trimRight();
  }

  String _oneLine(String text) {
    final collapsed = text.trim().replaceAll(RegExp(r'\s+'), ' ');
    const cap = 600;
    if (collapsed.length <= cap) {
      return collapsed;
    }
    return '${collapsed.substring(0, cap)}…';
  }

  String _stripHeading(String summary) {
    // Drop a leading "## ..." heading so nested summaries don't stack headings.
    final lines = summary.split('\n');
    if (lines.isNotEmpty && lines.first.trimLeft().startsWith('## ')) {
      return lines.skip(1).join('\n').trim();
    }
    return summary;
  }
}
