import 'package:cc_domain/features/dispatch/domain/entities/agent_process_event.dart';

/// Type of transcript block.
enum TranscriptBlockType {
  /// A regular message block.
  message,
  /// A thinking/reasoning block.
  thinking,
  /// A single tool operation.
  tool,
  /// Grouped error messages.
  stderrGroup,
  /// Grouped tool operations.
  toolGroup,
  /// Grouped command executions.
  commandGroup,
  /// Grouped system messages.
  systemGroup,
  /// A generic event.
  event,
}

/// A grouped block of transcript events.
class TranscriptBlock {
  /// Creates a [TranscriptBlock].
  const TranscriptBlock({
    required this.type,
    required this.events,
    this.summary,
  });

  /// The type of this block.
  final TranscriptBlockType type;
  /// The events in this block.
  final List<AgentProcessEvent> events;
  /// A human-readable summary of the block.
  final String? summary;

  /// Number of events in this block.
  int get eventCount => events.length;

  /// Content of the first event, or empty.
  String get firstContent =>
      events.isNotEmpty ? events.first.content : '';

  /// Whether this block represents a group (threshold met).
  bool get isGroup => type == TranscriptBlockType.stderrGroup ||
      type == TranscriptBlockType.toolGroup ||
      type == TranscriptBlockType.commandGroup;
}

/// Groups raw agent process events into [TranscriptBlock]s.
class TranscriptGrouper {
  TranscriptGrouper._();
  static const int _groupThreshold = 2;

  /// Groups [events] into structured transcript blocks.
  static List<TranscriptBlock> group(List<AgentProcessEvent> events) {
    if (events.isEmpty) {
      return [];
    }

    final blocks = <TranscriptBlock>[];
    var i = 0;

    while (i < events.length) {
      final event = events[i];

      if (event.type == AgentProcessEventType.thinking) {
        final group = <AgentProcessEvent>[];
        while (i < events.length &&
            events[i].type == AgentProcessEventType.thinking) {
          group.add(events[i]);
          i++;
        }
        blocks.add(TranscriptBlock(
          type: TranscriptBlockType.thinking,
          events: group,
          summary: 'Thought for ${group.length} entries',
        ));
        continue;
      }

      if (event.type == AgentProcessEventType.error) {
        final group = <AgentProcessEvent>[];
        while (i < events.length &&
            events[i].type == AgentProcessEventType.error) {
          group.add(events[i]);
          i++;
        }
        if (group.length >= _groupThreshold) {
          blocks.add(TranscriptBlock(
            type: TranscriptBlockType.stderrGroup,
            events: group,
            summary: '${group.length} error messages',
          ));
        } else {
          for (final e in group) {
            blocks.add(TranscriptBlock(
              type: TranscriptBlockType.stderrGroup,
              events: [e],
            ));
          }
        }
        continue;
      }

      if (event.type == AgentProcessEventType.toolCall ||
          event.type == AgentProcessEventType.toolResult) {
        final group = <AgentProcessEvent>[];
        while (i < events.length &&
            (events[i].type == AgentProcessEventType.toolCall ||
                events[i].type == AgentProcessEventType.toolResult)) {
          group.add(events[i]);
          i++;
        }
        if (group.length >= _groupThreshold) {
          blocks.add(TranscriptBlock(
            type: TranscriptBlockType.toolGroup,
            events: group,
            summary: '${group.length} tool operations',
          ));
        } else {
          for (final e in group) {
            blocks.add(TranscriptBlock(
              type: TranscriptBlockType.tool,
              events: [e],
            ));
          }
        }
        continue;
      }

      if (event.type == AgentProcessEventType.debug) {
        final group = <AgentProcessEvent>[];
        while (i < events.length &&
            events[i].type == AgentProcessEventType.debug) {
          group.add(events[i]);
          i++;
        }
        if (group.length >= _groupThreshold) {
          blocks.add(TranscriptBlock(
            type: TranscriptBlockType.systemGroup,
            events: group,
            summary: '${group.length} system messages',
          ));
        } else {
          for (final e in group) {
            blocks.add(TranscriptBlock(
              type: TranscriptBlockType.systemGroup,
              events: [e],
            ));
          }
        }
        continue;
      }

      blocks.add(TranscriptBlock(
        type: TranscriptBlockType.message,
        events: [event],
      ));
      i++;
    }

    return blocks;
  }
}
