import 'package:cc_domain/features/code_mode/domain/value_objects/code_execution_status.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/code_mode/presentation/code_mode_copy.dart';
import 'package:control_center/features/code_mode/presentation/screens/code_executions_screen.dart';
import 'package:control_center/features/code_mode/presentation/widgets/code_execution_row.dart';
import 'package:control_center/features/code_mode/providers/code_executions_list_provider.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/utils/failure_message.dart';
import 'package:control_center/shared/widgets/transcript/widgets/script_body.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The executions [filter] selects, newest first, read a page at a time as
/// the reader scrolls to the end.
///
/// The filter lives in the URL: changing the outcomes, or dropping the run or
/// conversation scope, navigates, so each list is a location Back returns to.
class CodeExecutionsList extends ConsumerWidget {
  /// Creates the list for [filter].
  const CodeExecutionsList({super.key, required this.filter});

  /// What the list shows.
  final CodeExecutionsFilter filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final list = ref.watch(codeExecutionsListProvider(filter));
    final Widget body;
    if (list.value case final state?) {
      body = state.items.isEmpty
          ? Center(
              child: CcEmptyState(
                icon: AppIcons.scrollText,
                message: filter.statuses.isEmpty && !filter.isScoped
                    ? l10n.codeExecutionsEmpty
                    : l10n.codeExecutionsEmptyFiltered,
              ),
            )
          : _Rows(filter: filter, state: state);
    } else if (list.hasError) {
      body = Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: CcAlert(
          title: failureMessage(l10n, list.error!),
          variant: CcAlertVariant.danger,
        ),
      );
    } else {
      body = const Center(child: CcSpinner());
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.xl,
            0,
            AppSpacing.xl,
            AppSpacing.md,
          ),
          child: _Toolbar(filter: filter),
        ),
        Expanded(child: body),
      ],
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({required this.filter});

  final CodeExecutionsFilter filter;

  void _go(BuildContext context, CodeExecutionsFilter next) =>
      context.go(codeExecutionsLocationOf(next));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final scope = filter.runId != null
        ? l10n.codeExecutionsScopeRun
        : filter.conversationId != null
        ? l10n.codeExecutionsScopeConversation
        : filter.agentId != null
        ? l10n.codeExecutionsScopeAgent
        : null;
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 240,
          child: CcMultiSelect<CodeExecutionStatus>(
            semanticLabel: l10n.codeExecutionsStatusFilter,
            hintText: l10n.codeExecutionsAllOutcomes,
            countLabel: l10n.codeExecutionsOutcomeCount,
            values: filter.statuses,
            options: [
              for (final s in kRecordedCodeExecutionStatuses)
                CcSelectOption(
                  value: s,
                  label: scriptStateLabel(l10n, scriptRunStateOf(s)),
                ),
            ],
            onChanged: (next) => _go(
              context,
              CodeExecutionsFilter(
                workspaceId: filter.workspaceId,
                runId: filter.runId,
                conversationId: filter.conversationId,
                agentId: filter.agentId,
                statuses: next,
              ),
            ),
          ),
        ),
        if (scope != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(AppIcons.listFilter, size: 14, color: t.textTertiary),
              const SizedBox(width: AppSpacing.xs),
              Text(
                scope,
                style: CcTypography.bodySm.copyWith(color: t.textSecondary),
              ),
              const SizedBox(width: AppSpacing.sm),
              CcButton(
                variant: CcButtonVariant.ghost,
                size: CcButtonSize.sm,
                onPressed: () => _go(
                  context,
                  CodeExecutionsFilter(
                    workspaceId: filter.workspaceId,
                    statuses: filter.statuses,
                  ),
                ),
                child: Text(l10n.codeExecutionsShowAll),
              ),
            ],
          ),
      ],
    );
  }
}

/// The loaded rows, then one footer row that reads the next page when it
/// comes into view (or says why it could not).
class _Rows extends ConsumerWidget {
  const _Rows({required this.filter, required this.state});

  final CodeExecutionsFilter filter;
  final CodeExecutionsListState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final notifier = ref.read(codeExecutionsListProvider(filter).notifier);
    final query = GoRouterState.of(context).uri.queryParameters;
    final footer = state.hasMore || state.moreError != null;
    return ListView.builder(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.xl,
        0,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      itemCount: state.items.length + (footer ? 1 : 0),
      itemBuilder: (context, i) {
        if (i < state.items.length) {
          return CodeExecutionRow(
            workspaceId: filter.workspaceId,
            execution: state.items[i],
            first: i == 0,
            query: query,
          );
        }
        final error = state.moreError;
        if (error != null) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    failureMessage(l10n, error),
                    style: CcTypography.caption.copyWith(
                      color: context.designSystem?.textErrorPrimary,
                    ),
                  ),
                ),
                CcButton(
                  variant: CcButtonVariant.secondary,
                  size: CcButtonSize.sm,
                  onPressed: notifier.loadMore,
                  child: Text(l10n.retry),
                ),
              ],
            ),
          );
        }
        // Reaching the footer is the request for more.
        if (!state.loadingMore) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => notifier.loadMore(),
          );
        }
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: Center(child: CcSpinner()),
        );
      },
    );
  }
}
