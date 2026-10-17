import 'package:cc_domain/cc_domain.dart';
import 'package:cc_remote/app_icons.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/operation_scope.dart';
import 'package:cc_remote/plan_goal_providers.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

String planExecutionStatusLabel(AppLocalizations l10n, String status) =>
    switch (status) {
      'proposed' => l10n.mobilePlanProposed,
      'approved' => l10n.mobilePlanApproved,
      'executing' => l10n.mobilePlanExecuting,
      'synthesizing' => l10n.mobilePlanSynthesizing,
      'completed' => l10n.mobilePlanCompleted,
      'failed' => l10n.mobilePlanFailed,
      'cancelled' => l10n.mobilePlanCancelled,
      _ => status,
    };

/// Real run linkage and progress via the server's execution/step subscriptions.
class PhonePlanExecutionSummary extends ConsumerWidget {
  const PhonePlanExecutionSummary({
    super.key,
    required this.execution,
    required this.workspaceId,
    required this.conversationId,
  });

  final OrchestrationDto execution;
  final String workspaceId;
  final String conversationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final runId = execution.pipelineRunId;
    final steps = runId == null
        ? null
        : ref.watch(
            phonePlanStepsProvider((workspaceId: workspaceId, runId: runId)),
          );
    final numbers = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toLanguageTag(),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        CcBadge(
          label: planExecutionStatusLabel(l10n, execution.status),
          variant: execution.status == 'failed'
              ? CcBadgeVariant.danger
              : execution.status == 'completed'
              ? CcBadgeVariant.success
              : CcBadgeVariant.neutral,
        ),
        if (runId != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              l10n.mobilePlanRunId(runId),
              style: TextStyle(color: t.textSecondary),
            ),
          ),
        if (steps?.isLoading == true) const Center(child: CcSpinner(size: 20)),
        if (steps?.hasError == true)
          Text(steps!.error.toString(), style: TextStyle(color: t.danger)),
        if (steps?.value case final List<PipelineStepRunDto> rows) ...[
          const SizedBox(height: 8),
          Text(
            l10n.mobilePlanProgress(
              numbers.format(rows.where((r) => r.status == 'completed').length),
              numbers.format(rows.length),
            ),
            style: TextStyle(color: t.textSecondary),
          ),
          for (final row in rows.where(
            (r) => r.errorMessage?.isNotEmpty == true,
          ))
            Text(row.errorMessage!, style: TextStyle(color: t.danger)),
        ],
        if (execution.errorMessage?.isNotEmpty == true)
          Text(execution.errorMessage!, style: TextStyle(color: t.danger)),
        if (execution.spaceId != null) ...[
          const SizedBox(height: 12),
          CcButton(
            size: CcButtonSize.lg,
            variant: CcButtonVariant.secondary,
            icon: AppIcons.arrowRight,
            onPressed: () => context.push(
              remoteSpaceLocation(
                workspaceId: workspaceId,
                spaceId: execution.spaceId!,
                conversationId: conversationId,
              ),
            ),
            child: Text(l10n.mobilePlanOpenConversation),
          ),
        ],
      ],
    );
  }
}
