import 'package:cc_domain/core/domain/entities/review_channel_association.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pr_review/presentation/widgets/ask_ai_review_button.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_context_rail.dart';
import 'package:control_center/features/pr_review/presentation/widgets/review_accordion_list.dart';
import 'package:control_center/features/pr_review/presentation/widgets/review_verdict_banner.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// AI review tab for the PR detail view.
class PrAiReviewTab extends ConsumerWidget {
  /// Creates a [PrAiReviewTab].
  const PrAiReviewTab({super.key, required this.pr});

  /// The pull request being reviewed.
  final PullRequest pr;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncAssoc = ref.watch(reviewChannelForPrProvider(pr.nodeId));
    return asyncAssoc.when(
      loading: () => const Center(child: CcSpinner()),
      error: (e, _) => Center(
        child: Text(AppLocalizations.of(context).failedWithError('$e')),
      ),
      data: (assoc) {
        if (assoc == null) {
          return _IntroCta(pr: pr);
        }
        return _ReviewBody(association: assoc, pr: pr);
      },
    );
  }
}

class _IntroCta extends StatelessWidget {
  const _IntroCta({required this.pr});

  final PullRequest pr;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem!;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.sparkles, size: 48, color: tokens.textTertiary),
            const SizedBox(height: 16),
            Text(l10n.aiReview, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Start an AI-powered review of this pull request.\n'
              'Agents will analyze the diff, add findings, and reach consensus.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: tokens.textTertiary),
            ),
            const SizedBox(height: 24),
            AskAiReviewButton(pr: pr),
          ],
        ),
      ),
    );
  }
}

class _ReviewBody extends ConsumerWidget {
  const _ReviewBody({required this.association, required this.pr});

  final ReviewChannelAssociation association;
  final PullRequest pr;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(prReviewRepositoryProvider);
    final fetcher = pr.headSha.isEmpty
        ? null
        : (String path) => repo
              .watchFileContent(path, pr.headSha)
              .first
              .timeout(const Duration(seconds: 15));

    return SizedBox(
      height: MediaQuery.of(context).size.height - 240,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _StatusBar(association: association),
                ReviewVerdictBanner(channelId: association.channelId),
                Expanded(
                  child: ReviewAccordionList(
                    channelId: association.channelId,
                    fetchFileContent: fetcher,
                    pr: pr,
                  ),
                ),
              ],
            ),
          ),
          PrContextRail(prNumber: pr.number),
        ],
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar({required this.association});

  final ReviewChannelAssociation association;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem!;
    final label = switch (association.status) {
      ReviewChannelStatus.requested => AppLocalizations.of(context).requested,
      ReviewChannelStatus.inProgress => AppLocalizations.of(
        context,
      ).reviewersActive,
      ReviewChannelStatus.awaitingApproval => AppLocalizations.of(
        context,
      ).awaitingYourApproval,
      ReviewChannelStatus.completed => AppLocalizations.of(context).published,
    };
    final showPublish =
        association.status == ReviewChannelStatus.awaitingApproval;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: tokens.borderSecondary)),
      ),
      child: Row(
        children: [
          Icon(AppIcons.sparkles, size: 14, color: tokens.fgBrandPrimary),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: tokens.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          const Spacer(),
          if (showPublish)
            CcButton(
              size: CcButtonSize.sm,
              onPressed: () {
                CcToastScope.of(context).show(
                  'GitHub publish is not yet wired \u2014 coming soon.',
                  variant: CcToastVariant.neutral,
                );
              },
              icon: AppIcons.send,
              child: Text(AppLocalizations.of(context).publishToGithub),
            ),
        ],
      ),
    );
  }
}
