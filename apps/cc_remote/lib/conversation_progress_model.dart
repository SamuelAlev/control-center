import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/dispatch/domain/context/context_inspection.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/conversation_token_totals.dart';

/// A provider reading is distinct from a transcript/prompt estimate. A missing
/// window is unknown, never a 0-token capacity or a 0% reading.
({int? usedTokens, int? windowTokens, bool measured}) progressContextReading(
  ConversationTokenTotals? totals,
  ContextInspection? inspection,
  int? configuredWindow,
) {
  final reportedWindow = totals?.reportedWindowTokens;
  final serverWindow = inspection?.windowTokens;
  final window = reportedWindow != null && reportedWindow > 0
      ? reportedWindow
      : serverWindow != null && serverWindow > 0
      ? serverWindow
      : configuredWindow != null && configuredWindow > 0
      ? configuredWindow
      : null;
  final reported = totals?.reportedContextTokens;
  int? estimate;
  if (inspection != null) {
    // Claude Code's inspection already contains the capped history block.
    // Adding the stored transcript here would count a *different* history twice.
    final serverHistory =
        inspection.runner == ContextRunner.claudeCode &&
        inspection.segmentFor(ContextSegmentKind.conversation) != null;
    if (serverHistory) {
      estimate = inspection.persistentTokens;
    } else if (totals != null) {
      estimate = inspection.persistentTokens + totals.tokens;
    }
  }
  return (
    usedTokens: reported ?? estimate,
    windowTokens: window,
    measured: reported != null,
  );
}

/// Parent/child run order, retaining orphaned and cyclic records as roots.
List<(AgentRunLogDto, int)> progressRunTree(List<AgentRunLogDto> runs) {
  final byId = {for (final run in runs) run.id: run};
  final children = <String, List<AgentRunLogDto>>{};
  final roots = <AgentRunLogDto>[];
  for (final run in runs) {
    if (run.parentRunId == null ||
        run.parentRunId == run.id ||
        !byId.containsKey(run.parentRunId)) {
      roots.add(run);
    } else {
      children.putIfAbsent(run.parentRunId!, () => []).add(run);
    }
  }
  final result = <(AgentRunLogDto, int)>[];
  final seen = <String>{};
  void visit(AgentRunLogDto run, int depth) {
    if (!seen.add(run.id)) return;
    result.add((run, depth));
    for (final child in children[run.id] ?? const <AgentRunLogDto>[]) {
      visit(child, depth + 1);
    }
  }

  for (final run in roots) {
    visit(run, 0);
  }
  for (final run in runs) {
    visit(run, 0);
  }
  return result;
}
