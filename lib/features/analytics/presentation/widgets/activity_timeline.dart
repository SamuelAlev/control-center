import 'package:control_center/core/domain/entities/agent_run_log.dart';
import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:flutter/material.dart';

/// A scrollable list of the most recent agent runs showing completion
/// status and relative timestamps.
class ActivityTimeline extends StatelessWidget {
/// Constructs the timeline widget with a list of [AgentRunLog] entries.
  const ActivityTimeline({super.key, required this.runs});

/// The agent runs to display; only the 10 most recent are shown.
  final List<AgentRunLog> runs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = DesignSystemTokens.of(context);
    final recent = runs.take(10).toList();

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: recent.length,
      itemBuilder: (context, index) {
        final run = recent[index];
        return ListTile(
          dense: true,
          leading: Icon(
            run.isCompleted ? Icons.check_circle : Icons.error,
            color: run.isCompleted
                ? (tokens?.fgSuccessPrimary ?? theme.colorScheme.primary)
                : (tokens?.fgErrorPrimary ?? theme.colorScheme.error),
            size: 16,
          ),
          title: Text(run.agentId, style: theme.textTheme.bodySmall),
          subtitle: Text(
            _formatTime(run.startedAt),
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 12,
              height: 1.4,
            ),
          ),
        );
      },
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    }
    return '${diff.inDays}d ago';
  }
}
