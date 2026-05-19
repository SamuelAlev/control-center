import 'package:cc_domain/core/domain/entities/review_channel_association.dart' show ReviewChannelAssociation;
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Pull Requests panel: shows the pull request linked to the active
/// conversation (via its review-channel association), not the full repo queue.
///
/// Resolves the conversation's PR through [channelPrDetailProvider] — which
/// looks up the [ReviewChannelAssociation] for the channel (prNumber +
/// repoFullName) and fetches the [PullRequest]. When the conversation has no
/// linked PR, shows an empty state.
class PrsPanel extends ConsumerWidget {
  /// Creates a [PrsPanel].
  const PrsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final channelId = ref.watch(selectedChannelIdProvider);

    if (channelId == null) {
      return CcEmptyState(
        icon: AppIcons.gitPullRequest,
        message: l10n.selectConversation,
      );
    }

    final prAsync = ref.watch(channelPrDetailProvider(channelId));

    return prAsync.when(
      loading: () => const Center(child: CcSpinner()),
      error: (_, _) => CcEmptyState(
        icon: AppIcons.gitPullRequest,
        message: l10n.ideNoConversationPr,
      ),
      data: (pr) {
        if (pr == null) {
          return CcEmptyState(
            icon: AppIcons.gitPullRequest,
            message: l10n.ideNoConversationPr,
          );
        }
        return SingleChildScrollView(
          child: _ConversationPrCard(pr: pr),
        );
      },
    );
  }
}

/// Compact card for the single PR linked to the conversation.
class _ConversationPrCard extends ConsumerWidget {
  const _ConversationPrCard({required this.pr});

  final PullRequest pr;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final workspaceId = ref.watch(activeWorkspaceIdProvider);

    return CcTappable(
      onPressed: workspaceId == null
          ? null
          : () => context.push(
                pullRequestDetailRoute(workspaceId, pr.repoFullName, pr.number),
              ),
      builder: (context, states) {
        final hovered = states.contains(WidgetState.hovered);
        return Container(
          margin: const EdgeInsets.fromLTRB(8, 10, 8, 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: hovered ? t.hover : t.bgPrimary,
            borderRadius: AppRadii.brMd,
            border: Border.all(color: t.borderSecondary),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(_stateIcon(pr), size: 18, color: _stateColor(pr, t)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '#${pr.number}  ${pr.title}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: t.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${pr.repoFullName}  ·  ${pr.headRef} → ${pr.baseRef}',
                      style: TextStyle(
                        fontSize: 11,
                        color: t.textTertiary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _stateIcon(PullRequest pr) {
    if (pr.isDraft) {
      return AppIcons.gitPullRequestDraft;
    }
    if (pr.state == PrState.closed) {
      return AppIcons.gitPullRequestClosed;
    }
    return AppIcons.gitPullRequest;
  }

  Color _stateColor(PullRequest pr, DesignSystemTokens t) {
    if (pr.state == PrState.closed) {
      return t.textErrorPrimary;
    }
    if (pr.isDraft) {
      return t.textTertiary;
    }
    return t.textSuccessPrimary;
  }
}
