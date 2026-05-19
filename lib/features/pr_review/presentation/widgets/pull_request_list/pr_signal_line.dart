import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/domain/entities/repo.dart';
import 'package:control_center/features/pr_review/domain/entities/pull_request.dart';
import 'package:control_center/features/pr_review/presentation/utils/relative_time.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pull_request_list/age_text.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pull_request_list/pr_list_shared.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The dense metadata line under a PR title: `#number · repo · branch → base ·
/// age`. Each segment renders only when it carries information.
class PrMetaLine extends StatelessWidget {
  /// Creates a [PrMetaLine].
  const PrMetaLine({
    super.key,
    required this.pr,
    required this.repo,
    required this.showRepo,
  });

  /// The pull request.
  final PullRequest pr;

  /// The owning repo (shown when [showRepo] is true).
  final Repo repo;

  /// Whether to include the repo full name.
  final bool showRepo;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final muted = tokens.muted;
    final style = Theme.of(
      context,
    ).textTheme.labelSmall?.copyWith(color: muted);
    final hasBranch = pr.headRef.isNotEmpty && pr.baseRef.isNotEmpty;

    return Row(
      children: [
        Text(
          '#${pr.number}',
          style: style?.copyWith(fontWeight: FontWeight.w500),
        ),
        if (showRepo) ...[
          _Dot(style: style),
          Flexible(
            child: Text(
              repo.fullName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: style,
            ),
          ),
        ],
        if (hasBranch) ...[
          _Dot(style: style),
          Flexible(
            child: Text(
              '${pr.headRef} → ${pr.baseRef}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: style?.copyWith(
                fontFamily: 'JetBrains Mono',
                color: tokens.textTertiary,
              ),
            ),
          ),
        ],
        _Dot(style: style),
        AgeText(
          ageText: AppLocalizations.of(
            context,
          ).updatedAgo(formatRelative(pr.updatedAt ?? pr.createdAt)),
          date: pr.updatedAt ?? pr.createdAt,
          neutral: muted,
          style: style,
        ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.style});

  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Text('·', style: style),
    );
  }
}

/// The agent-native signal line: who authored the PR, the rolled-up checks
/// state, the diff size, and the conversation count. Each chip renders only
/// when it carries real information, so an un-enriched PR shows fewer chips
/// rather than empty slots.
class PrSignalLine extends StatelessWidget {
  /// Creates a [PrSignalLine].
  const PrSignalLine({super.key, required this.pr, required this.currentLogin});

  /// The pull request.
  final PullRequest pr;

  /// The current operator's lowercased login (drives the "you" attribution).
  final String currentLogin;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[
      _WhoChip(pr: pr, currentLogin: currentLogin),
      if (pr.checksStatus != PrChecksStatus.none)
        PrChecksPill(status: pr.checksStatus),
      if (pr.additions > 0 || pr.deletions > 0)
        _DiffStat(additions: pr.additions, deletions: pr.deletions),
      if (pr.commentsCount > 0) _CommentsChip(count: pr.commentsCount),
    ];

    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: chips,
    );
  }
}

class _WhoChip extends StatelessWidget {
  const _WhoChip({required this.pr, required this.currentLogin});

  final PullRequest pr;
  final String currentLogin;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final login = pr.author?.login ?? '';
    final isMe = login.isNotEmpty && login.toLowerCase() == currentLogin;
    final muted = tokens.muted;
    final l10n = AppLocalizations.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        buildAvatar(pr.author, login, size: 18),
        const SizedBox(width: 6),
        Text(
          '${l10n.byAuthorPrefix} ',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: muted),
        ),
        Text(
          isMe ? l10n.youLabel : (login.isEmpty ? '—' : login),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: tokens.textPrimary,
            fontFamily: 'JetBrains Mono',
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// A small colour-coded pill summarising the PR's rolled-up CI/check status.
/// Pairs an icon with a label so the state survives grayscale.
class PrChecksPill extends StatelessWidget {
  /// Creates a [PrChecksPill].
  const PrChecksPill({super.key, required this.status});

  /// The rolled-up checks status.
  final PrChecksStatus status;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final (IconData icon, Color fg, Color bg, String label) = switch (status) {
      PrChecksStatus.passing => (
        LucideIcons.check,
        tokens.success,
        tokens.successSoft,
        l10n.checksPassing,
      ),
      PrChecksStatus.failing => (
        LucideIcons.x,
        tokens.danger,
        tokens.dangerSoft,
        l10n.checksFailing,
      ),
      PrChecksStatus.pending => (
        LucideIcons.clock,
        tokens.warn,
        tokens.warnSoft,
        l10n.checksRunning,
      ),
      PrChecksStatus.none => (
        LucideIcons.minus,
        tokens.muted,
        Colors.transparent,
        '',
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: fg,
              fontWeight: FontWeight.w600,
              fontFamily: 'JetBrains Mono',
            ),
          ),
        ],
      ),
    );
  }
}

class _DiffStat extends StatelessWidget {
  const _DiffStat({required this.additions, required this.deletions});

  final int additions;
  final int deletions;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final add = tokens.success;
    final del = tokens.danger;
    final base = Theme.of(context).textTheme.labelSmall?.copyWith(
      fontFamily: 'JetBrains Mono',
      fontFeatures: const [FontFeature.tabularFigures()],
      fontWeight: FontWeight.w500,
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (additions > 0)
          Text('+$additions', style: base?.copyWith(color: add)),
        if (additions > 0 && deletions > 0) const SizedBox(width: 4),
        if (deletions > 0)
          Text('−$deletions', style: base?.copyWith(color: del)),
      ],
    );
  }
}

class _CommentsChip extends StatelessWidget {
  const _CommentsChip({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final muted = tokens.muted;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(LucideIcons.messageSquare, size: 13, color: muted),
        const SizedBox(width: AppSpacing.xs),
        Text(
          '$count',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: muted,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

/// A quiet neutral "Draft" badge shown beside a draft PR's title.
class PrDraftBadge extends StatelessWidget {
  /// Creates a [PrDraftBadge].
  const PrDraftBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final fg = tokens.textTertiary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: tokens.bgSecondary,
        borderRadius: AppRadii.brSm,
        border: Border.all(color: tokens.borderSecondary),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.gitPullRequestDraft, size: 11, color: fg),
          const SizedBox(width: AppSpacing.xs),
          Text(
            AppLocalizations.of(context).draft,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: fg,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
