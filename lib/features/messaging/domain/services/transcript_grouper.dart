import 'package:control_center/features/dispatch/domain/entities/agent_process_event.dart';

enum TranscriptBlockType {
  message,
  thinking,
  tool,
  stderrGroup,
  toolGroup,
  commandGroup,
  systemGroup,
  event,
}

class TranscriptBlock {
  const TranscriptBlock({
    required this.type,
    required this.events,
    this.summary,
  });

  final TranscriptBlockType type;
  final List<AgentProcessEvent> events;
  final String? summary;

  int get eventCount => events.length;

  String get firstContent =>
      events.isNotEmpty ? events.first.content : '';

  bool get isGroup => type == TranscriptBlockType.stderrGroup ||
      type == TranscriptBlockType.toolGroup ||
      type == TranscriptBlockType.commandGroup;
}

class TranscriptGrouper {
  TranscriptGrouper._();
  static const int _groupThreshold = 2;

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
