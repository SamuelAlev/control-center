import 'package:control_center/core/domain/entities/agent.dart';
import 'package:control_center/features/dashboard/domain/entities/dashboard_status.dart';

/// Agent process matcher.
class AgentProcessMatcher {
  /// Match.
  List<ActiveProcessInfo> match({
    required List<ActiveProcessInfo> processes,
    required List<Agent> agents,
  }) {
    if (processes.isEmpty || agents.isEmpty) {
      return processes;
    }

    final agentNamesLower = <String, Agent>{};
    for (final agent in agents) {
      agentNamesLower[agent.name.toLowerCase()] = agent;
    }
    final agentSlugs = agents.map((a) => a.agentMdPath.toLowerCase()).toList();

    final matched = <ActiveProcessInfo>[];
    for (final proc in processes) {
      final commandLower = proc.command.toLowerCase();
      ActiveProcessInfo best = proc;

      for (final entry in agentNamesLower.entries) {
        if (commandLower.contains(entry.key)) {
          best = ActiveProcessInfo(
            agentName: entry.value.name,
            workspaceName: proc.workspaceName,
            pid: proc.pid,
            command: proc.command,
            startTime: proc.startTime,
          );
          break;
        }
      }

      if (best.agentName == proc.agentName) {
        for (final slug in agentSlugs) {
          final slugLast = slug.split('/').last;
          if (slugLast.isNotEmpty && commandLower.contains(slugLast)) {
            final matching = agents.firstWhere(
              (a) => a.agentMdPath.toLowerCase() == slug,
            );
            best = ActiveProcessInfo(
              agentName: matching.name,
              workspaceName: proc.workspaceName,
              pid: proc.pid,
              command: proc.command,
              startTime: proc.startTime,
            );
            break;
          }
        }
      }

      matched.add(best);
    }

    return matched;
  }
}

