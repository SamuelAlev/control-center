import 'package:control_center/core/domain/entities/channel_message.dart';
import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_bubble/channel_bubble_shared.dart';
import 'package:control_center/features/orchestration/domain/entities/orchestration.dart';
import 'package:control_center/features/orchestration/domain/entities/orchestration_status.dart';
import 'package:control_center/features/orchestration/presentation/notifiers/orchestration_proposal_notifier.dart';
import 'package:control_center/features/orchestration/providers/orchestration_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Renders an orchestration's whole lifecycle as a single card. The message
/// metadata carries only the orchestration id; the bubble watches the row so
/// `proposed → executing → completed` re-renders live with zero feed churn.
class OrchestrationProposalBubble extends ConsumerWidget {
  /// Creates an [OrchestrationProposalBubble].
  const OrchestrationProposalBubble({super.key, required this.message});

  /// The orchestration-proposal channel message.
  final ChannelMessage message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = resolveTokens(context);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final orchestrationId = message.metadata?['orchestrationId'] as String?;
    final workspaceId = ref.watch(activeWorkspaceIdProvider);

    if (orchestrationId == null || workspaceId == null) {
      return const SizedBox.shrink();
    }

    final async = ref.watch(orchestrationProvider(
      (workspaceId: workspaceId, id: orchestrationId),
    ));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tokens.bgPrimary,
          borderRadius: BorderRadius.circular(bubbleRadius),
          border: Border.all(color: tokens.borderSecondary),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(bubbleRadius),
          child: async.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(14),
              child: Text(
                l10n.orchestrationUnavailable,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: tokens.textTertiary),
              ),
            ),
            data: (o) {
              if (o == null) {
                return Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text(
                    l10n.orchestrationUnavailable,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: tokens.textTertiary),
                  ),
                );
              }
              return _Card(
                orchestration: o,
                workspaceId: workspaceId,
                tokens: tokens,
                theme: theme,
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Card extends ConsumerWidget {
  const _Card({
    required this.orchestration,
    required this.workspaceId,
    required this.tokens,
    required this.theme,
  });

  final Orchestration orchestration;
  final String workspaceId;
  final DesignSystemTokens tokens;
  final ThemeData theme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final p = orchestration.proposal;
    final status = orchestration.status;
    final notifier =
        ref.watch(orchestrationProposalNotifierProvider.notifier);
    final busy = ref.watch(orchestrationProposalNotifierProvider).busyId ==
        orchestration.id;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header strip.
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: tokens.accentSoft,
            border:
                Border(bottom: BorderSide(color: tokens.borderSecondary)),
          ),
          child: Row(
            children: [
              Icon(_statusIcon(status), size: 14, color: tokens.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _statusLabel(status, l10n).toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: tokens.accent,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              Text(
                'rev ${orchestration.revision}',
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: tokens.textQuaternary),
              ),
            ],
          ),
        ),
        // Body.
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                p.goal,
                style: theme.textTheme.titleSmall
                    ?.copyWith(color: tokens.textPrimary),
              ),
              const SizedBox(height: 8),
              _metaRow(
                context,
                l10n.orchestrationRolesSummary(p.roles.length, p.hireCount),
              ),
              _metaRow(
                context,
                l10n.orchestrationSubTicketsSummary(p.subTickets.length),
              ),
              if (orchestration.estimatedCostCents != null)
                _metaRow(
                  context,
                  l10n.orchestrationEstimatedCost(
                    (orchestration.estimatedCostCents! / 100)
                        .toStringAsFixed(2),
                  ),
                ),
              if (status == OrchestrationStatus.executing ||
                  status == OrchestrationStatus.synthesizing)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: _SubTicketProgress(
                    workspaceId: workspaceId,
                    parentTicketId: orchestration.parentTicketId,
                  ),
                ),
              if (status == OrchestrationStatus.failed &&
                  orchestration.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    orchestration.errorMessage!,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: tokens.textErrorPrimary),
                  ),
                ),
            ],
          ),
        ),
        // Action bar (only while proposed).
        if (status == OrchestrationStatus.proposed)
          Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: tokens.borderSecondary)),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed: busy
                      ? null
                      : () => notifier.approve(
                            workspaceId: workspaceId,
                            orchestrationId: orchestration.id,
                          ),
                  icon: busy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.play_arrow, size: 18),
                  label: Text(l10n.orchestrationApprove),
                ),
                OutlinedButton.icon(
                  onPressed: busy
                      ? null
                      : () => notifier.cancel(
                            workspaceId: workspaceId,
                            orchestrationId: orchestration.id,
                          ),
                  icon: const Icon(Icons.close, size: 18),
                  label: Text(l10n.orchestrationReject),
                ),
              ],
            ),
          )
        else if (!status.isTerminal)
          Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: tokens.borderSecondary)),
            ),
            child: TextButton.icon(
              onPressed: busy
                  ? null
                  : () => notifier.cancel(
                        workspaceId: workspaceId,
                        orchestrationId: orchestration.id,
                      ),
              icon: const Icon(Icons.stop_circle_outlined, size: 18),
              label: Text(l10n.orchestrationCancel),
              style: TextButton.styleFrom(foregroundColor: tokens.textErrorPrimary),
            ),
          ),
      ],
    );
  }

  Widget _metaRow(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          text,
          style: theme.textTheme.bodySmall
              ?.copyWith(color: tokens.textSecondary),
        ),
      );

  IconData _statusIcon(OrchestrationStatus s) => switch (s) {
        OrchestrationStatus.proposed => Icons.account_tree_outlined,
        OrchestrationStatus.approved => Icons.check_circle_outline,
        OrchestrationStatus.executing => Icons.bolt,
        OrchestrationStatus.synthesizing => Icons.merge_type,
        OrchestrationStatus.completed => Icons.task_alt,
        OrchestrationStatus.failed => Icons.error_outline,
        OrchestrationStatus.cancelled => Icons.cancel_outlined,
      };

  String _statusLabel(OrchestrationStatus s, AppLocalizations l10n) =>
      switch (s) {
        OrchestrationStatus.proposed => l10n.orchestrationStatusProposed,
        OrchestrationStatus.approved => l10n.orchestrationStatusApproved,
        OrchestrationStatus.executing => l10n.orchestrationStatusExecuting,
        OrchestrationStatus.synthesizing =>
          l10n.orchestrationStatusSynthesizing,
        OrchestrationStatus.completed => l10n.orchestrationStatusCompleted,
        OrchestrationStatus.failed => l10n.orchestrationStatusFailed,
        OrchestrationStatus.cancelled => l10n.orchestrationStatusCancelled,
      };
}

/// Live sub-ticket progress for an executing orchestration, derived from the
/// parent ticket's children.
class _SubTicketProgress extends ConsumerWidget {
  const _SubTicketProgress({
    required this.workspaceId,
    required this.parentTicketId,
  });

  final String workspaceId;
  final String? parentTicketId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = resolveTokens(context);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final pid = parentTicketId;
    if (pid == null) {
      return const SizedBox.shrink();
    }
    final async = ref.watch(
      orchestrationChildTicketsProvider(
        (workspaceId: workspaceId, parentTicketId: pid),
      ),
    );
    return async.maybeWhen(
      orElse: () => const SizedBox.shrink(),
      data: (tickets) {
        if (tickets.isEmpty) {
          return const SizedBox.shrink();
        }
        final done = tickets.where((t) => t.status.isTerminal).length;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.orchestrationProgress(done, tickets.length),
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: tokens.textTertiary),
            ),
            const SizedBox(height: 4),
            for (final t in tickets)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Row(
                  children: [
                    Icon(
                      t.status.isSuccess
                          ? Icons.check_circle
                          : t.status.isFailure
                              ? Icons.error
                              : Icons.radio_button_unchecked,
                      size: 12,
                      color: t.status.isSuccess
                          ? tokens.accent
                          : t.status.isFailure
                              ? tokens.textErrorPrimary
                              : tokens.textQuaternary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        t.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: tokens.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
