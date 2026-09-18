import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/usecases/classify_pr_inbox_use_case.dart';
import 'package:cc_remote/app_icons.dart';
import 'package:cc_remote/format.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/widgets/workspace_avatar.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// The route a PR row opens. A PR number is unique only within a repo, so both
/// halves travel in the path.
String prRoute(String repoId, int number) => '/pr/$repoId/$number';

/// One pull request as a tappable card — the shared row for the PR queue and
/// the inbox, so a PR reads the same wherever it is surfaced.
///
/// Every signal is a shape or a word, never a colour alone: the lifecycle icon
/// distinguishes open / draft / merged / closed, CI carries its own glyph and
/// the review decision is spelled out. That is the accessibility floor the
/// product holds to, and on a phone in daylight it is also just legible.
class PrRow extends StatelessWidget {
  /// Creates a [PrRow] for [item].
  const PrRow({super.key, required this.item, this.showRepo = true});

  /// The PR and the repo it belongs to.
  final PrInboxItem item;

  /// Whether to print `owner/repo` in the meta line. Off inside a per-repo
  /// group, where the header already says it.
  final bool showRepo;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final pr = item.pr;
    final metaStyle = TextStyle(fontSize: 12, color: t.textTertiary);
    final ago = shortAgo(context, pr.updatedAt ?? pr.createdAt);
    final metaParts = <Widget>[];
    void addText(String value) {
      if (metaParts.isNotEmpty) {
        metaParts.add(Text('·', style: metaStyle));
      }
      metaParts.add(Text(value, style: metaStyle));
    }

    if (showRepo && pr.repoFullName.isNotEmpty) {
      addText(pr.repoFullName);
    }
    addText('#${pr.number}');
    if (pr.labels.isNotEmpty) {
      if (metaParts.isNotEmpty) {
        metaParts.add(Text('·', style: metaStyle));
      }
      for (final label in pr.labels) {
        metaParts.add(
          CcColorTag(
            label: label.name,
            color: label.color,
            tooltip: label.description.isEmpty ? null : label.description,
            compact: true,
          ),
        );
      }
    }
    if (pr.author?.login.isNotEmpty ?? false) {
      addText(pr.author!.login);
    }
    if (ago.isNotEmpty) {
      addText(ago);
    }

    return CcCard(
      interactive: true,
      semanticLabel: l10n.prSemanticLabel(pr.title, prLifecycleLabel(l10n, pr)),
      onPressed: () => context.push(prRoute(item.repo.id, pr.number)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              prLifecycleIcon(pr),
              size: 18,
              color: prLifecycleColor(t, pr),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pr.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.3,
                    fontWeight: FontWeight.w500,
                    color: t.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: metaParts,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (pr.isDraft)
                      CcBadge(
                        label: l10n.draft,
                        variant: CcBadgeVariant.neutral,
                      ),
                    ?_reviewBadge(l10n, pr),
                    ?_checksBadge(l10n, pr),
                    if (churn(pr.additions, pr.deletions).isNotEmpty)
                      Text(
                        churn(pr.additions, pr.deletions),
                        style: TextStyle(fontSize: 11, color: t.textTertiary),
                      ),
                    if (pr.commentsCount > 0)
                      _MetaChip(
                        icon: AppIcons.messageSquare,
                        label: '${pr.commentsCount}',
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (item.repo.hasForgeRemote)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 8, top: 2),
              child: RemoteAvatar(
                url: pr.author?.avatarUrl,
                fallbackLabel: pr.author?.login ?? '',
                size: 22,
              ),
            ),
        ],
      ),
    );
  }

  static Widget? _reviewBadge(AppLocalizations l10n, PullRequest pr) =>
      switch (pr.reviewDecision) {
        PrReviewDecision.approved => CcBadge(
          label: l10n.approved,
          variant: CcBadgeVariant.success,
        ),
        PrReviewDecision.changesRequested => CcBadge(
          label: l10n.changesRequested,
          variant: CcBadgeVariant.danger,
        ),
        PrReviewDecision.reviewRequired => CcBadge(
          label: l10n.reviewRequired,
          variant: CcBadgeVariant.info,
        ),
        PrReviewDecision.none => null,
      };

  static Widget? _checksBadge(AppLocalizations l10n, PullRequest pr) =>
      switch (pr.checksStatus) {
        PrChecksStatus.passing => CcBadge(
          label: l10n.checksPassing,
          variant: CcBadgeVariant.success,
        ),
        PrChecksStatus.failing => CcBadge(
          label: l10n.checksFailing,
          variant: CcBadgeVariant.danger,
        ),
        PrChecksStatus.pending => CcBadge(
          label: l10n.checksRunning,
          variant: CcBadgeVariant.warning,
        ),
        PrChecksStatus.none => null,
      };
}

/// The lifecycle glyph: draft, merged, closed or open.
IconData prLifecycleIcon(PullRequest pr) {
  if (pr.isMerged) {
    return AppIcons.gitMerge;
  }
  if (pr.isClosed) {
    return AppIcons.circleSlash;
  }
  return pr.isDraft ? AppIcons.gitPullRequestDraft : AppIcons.gitPullRequest;
}

/// The lifecycle colour. Paired with [prLifecycleIcon] and
/// [prLifecycleLabel] — colour is never the only carrier.
Color prLifecycleColor(DesignSystemTokens t, PullRequest pr) {
  if (pr.isMerged) {
    return t.accent;
  }
  if (pr.isClosed) {
    return t.textErrorPrimary;
  }
  return pr.isDraft ? t.fgTertiary : t.textSuccessPrimary;
}

/// The lifecycle word, for screen readers and the detail header.
String prLifecycleLabel(AppLocalizations l10n, PullRequest pr) {
  if (pr.isMerged) {
    return l10n.merged;
  }
  if (pr.isClosed) {
    return l10n.closed;
  }
  return pr.isDraft ? l10n.draft : l10n.open;
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: t.fgTertiary),
        const SizedBox(width: 3),
        Text(label, style: TextStyle(fontSize: 11, color: t.textTertiary)),
      ],
    );
  }
}
