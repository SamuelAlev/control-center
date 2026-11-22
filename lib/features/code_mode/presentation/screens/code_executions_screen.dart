import 'package:cc_domain/features/code_mode/domain/value_objects/code_execution_status.dart';
import 'package:control_center/features/code_mode/presentation/widgets/code_execution_detail.dart';
import 'package:control_center/features/code_mode/presentation/widgets/code_executions_list.dart';
import 'package:control_center/features/code_mode/providers/code_executions_list_provider.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/widgets/page_wrapper.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Observability → Code executions: every script a workspace's runs ran,
/// newest first, and one record at a time.
///
/// The list and a record are sibling routes sharing one page, so this screen
/// updates in place when a record opens: the list stays mounted underneath
/// (its filters live in the URL, its loaded pages in its provider, its scroll
/// position in its own state) and Back returns to it exactly as it was.
class CodeExecutionsScreen extends StatelessWidget {
  /// Creates the screen, showing the record [executionId] when given.
  const CodeExecutionsScreen({super.key, this.executionId});

  /// The open record's id, decoded whole from the route, or null for the
  /// list.
  final String? executionId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final workspaceId = context.currentWorkspaceId;
    if (workspaceId == null) {
      return const SizedBox.shrink();
    }
    final filter = codeExecutionsFilterOf(
      workspaceId,
      GoRouterState.of(context).uri,
    );
    final id = executionId;
    return PageWrapper(
      title: l10n.codeExecutionsTitle,
      subtitle: l10n.codeExecutionsSubtitle,
      child: IndexedStack(
        index: id == null ? 0 : 1,
        sizing: StackFit.expand,
        children: [
          CodeExecutionsList(filter: filter),
          if (id == null)
            const SizedBox.shrink()
          else
            CodeExecutionDetailView(
              key: ValueKey(id),
              workspaceId: workspaceId,
              executionId: id,
              listFilter: filter,
            ),
        ],
      ),
    );
  }
}

/// The list filter a code executions location names: the run, conversation
/// or agent it is scoped to and the outcomes it shows.
CodeExecutionsFilter codeExecutionsFilterOf(String workspaceId, Uri uri) {
  final query = uri.queryParameters;
  String? read(String key) {
    final value = query[key];
    return value == null || value.isEmpty ? null : value;
  }

  return CodeExecutionsFilter(
    workspaceId: workspaceId,
    runId: read(codeExecutionsRunParam),
    conversationId: read(codeExecutionsConversationParam),
    agentId: read(codeExecutionsAgentParam),
    // An outcome the server never records (an old link naming `refused`) is
    // dropped rather than sent, so the list still reads.
    statuses: {
      for (final wire in (read(codeExecutionsStatusParam) ?? '').split(','))
        if (CodeExecutionStatus.tryParse(wire) case final status?
            when kRecordedCodeExecutionStatuses.contains(status))
          status,
    },
  );
}

/// The location of the list [filter] describes.
String codeExecutionsLocationOf(CodeExecutionsFilter filter) =>
    codeExecutionsRoute(
      filter.workspaceId,
      runId: filter.runId,
      conversationId: filter.conversationId,
      agentId: filter.agentId,
      statuses: [
        for (final s in kRecordedCodeExecutionStatuses)
          if (filter.statuses.contains(s)) s.wire,
      ],
    );
