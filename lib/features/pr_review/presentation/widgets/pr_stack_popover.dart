import 'package:cc_domain/features/pr_review/domain/entities/pr_stack.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pull_request_list/pr_list_shared.dart';
import 'package:control_center/features/pr_review/providers/pr_list_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_stack_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The stack badge on the PR detail's metadata strip: a `layers` glyph plus
/// the stack size, opening a popover that lists the stack's pull requests
/// (top first, like GitHub's own stack view) and navigates to each.
///
/// Renders nothing while the stack lookup is in flight or when the PR isn't
/// part of a stack — an unstacked PR is the common case and gets no chrome.
class PrStackBadge extends ConsumerWidget {
  /// Creates a [PrStackBadge].
  const PrStackBadge({super.key, required this.pr, required this.prRef});

  /// The pull request whose stack membership is shown.
  final PullRequest pr;

  /// The PR's identity key (repo coords + number).
  final PrRef prRef;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stack = ref.watch(currentPrStackProvider(prRef)).value;
    if (stack == null || stack.pullRequests.length < 2) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final repo = ref.watch(prRepoRowProvider(prRef));

    return CcPopover(
      semanticLabel: l10n.stackedPullRequests,
      target: _BadgeChip(count: stack.pullRequests.length, tokens: tokens),
      // Navigation goes through the badge's own context (not the overlay's):
      // GoRouter and the workspace id resolve from the page and the popover
      // closes itself when the route swap unmounts the portal target.
      overlayBuilder: (panelContext, targetSize) => _StackPanel(
        stack: stack,
        currentPrNumber: pr.number,
        repoFullName: pr.repoFullName,
        onOpenPr: repo == null
            ? null
            : (number) => openPrInRepo(ref, context, repo, number),
      ),
    );
  }
}

/// The badge target: `layers` glyph + stack size in a hairline pill, matching
/// the meta strip's quiet chip vocabulary.
class _BadgeChip extends StatelessWidget {
  const _BadgeChip({required this.count, required this.tokens});

  final int count;
  final DesignSystemTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: tokens.panel,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: tokens.borderSoft),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(AppIcons.layers, size: 12, color: tokens.textSecondary),
          const SizedBox(width: AppSpacing.xs),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: tokens.textSecondary,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }
}

/// The popover panel: every PR of the stack, top first (the tip reads first,
/// matching how a stack is reviewed), the bottom entry carrying the `layers`
/// glyph and the rest a down-arrow ("sits on top of"). The current PR is
/// highlighted; merged/closed entries read muted with their state glyph so
/// status is never carried by color alone.
class _StackPanel extends ConsumerWidget {
  const _StackPanel({
    required this.stack,
    required this.currentPrNumber,
    required this.repoFullName,
    required this.onOpenPr,
  });

  final PrStack stack;
  final int currentPrNumber;
  final String repoFullName;

  /// Navigates to a stack entry's PR. Null when the detail's repo pin is
  /// unresolved — rows then render inert rather than navigating nowhere.
  final ValueChanged<int>? onOpenPr;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    // Titles/authors/diff stats enrich the minimal stack entries from the
    // open-PR snapshot (watched only while the popover is open). Entries the
    // snapshot doesn't hold (closed/merged PRs) fall back to `#number`.
    final openPrs =
        ref
            .watch(prsByRepoProvider)
            .value
            ?.repos
            .where((g) => g.repo.fullName == repoFullName)
            .firstOrNull
            ?.prs ??
        const <PullRequest>[];
    final byNumber = {for (final pr in openPrs) pr.number: pr};

    // Top first: the API order is bottom → top.
    final entries = stack.pullRequests.reversed.toList();

    return Container(
      width: 340,
      constraints: const BoxConstraints(maxHeight: 420),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Text(
              l10n.stackedPullRequests,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
                color: tokens.textTertiary,
                decoration: TextDecoration.none,
              ),
            ),
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                return _StackEntryRow(
                  entry: entry,
                  pr: byNumber[entry.number],
                  repoFullName: repoFullName,
                  isCurrent: entry.number == currentPrNumber,
                  isBottom: index == entries.length - 1,
                  tokens: tokens,
                  onOpenPr: onOpenPr,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StackEntryRow extends StatelessWidget {
  const _StackEntryRow({
    required this.entry,
    required this.pr,
    required this.repoFullName,
    required this.isCurrent,
    required this.isBottom,
    required this.tokens,
    required this.onOpenPr,
  });

  final PrStackEntry entry;

  /// The open-PR snapshot's enrichment for this entry, when present.
  final PullRequest? pr;
  final String repoFullName;
  final bool isCurrent;

  /// Whether this row is the stack's bottom PR (the one merging into the
  /// stack's base ref) — it carries the `layers` glyph.
  final bool isBottom;
  final DesignSystemTokens tokens;
  final ValueChanged<int>? onOpenPr;

  @override
  Widget build(BuildContext context) {
    final merged = entry.isMerged;
    final closed = entry.state == PrStackEntryState.closed && !merged;
    final muted = merged || closed;
    final titleColor = muted ? tokens.textTertiary : tokens.textPrimary;
    final repoName = repoFullName.split('/').last;

    final content = Container(
      color: isCurrent ? tokens.accentSoft : const Color(0x00000000),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              isBottom ? AppIcons.layers : AppIcons.arrowDown,
              size: 13,
              color: tokens.textTertiary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pr?.title ?? '#${entry.number}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w600,
                    color: titleColor,
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      merged
                          ? AppIcons.gitMerge
                          : closed
                          ? AppIcons.gitPullRequestClosed
                          : entry.isDraft
                          ? AppIcons.gitPullRequestDraft
                          : AppIcons.gitPullRequest,
                      size: 11,
                      color: tokens.textTertiary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Flexible(
                      child: Text(
                        '$repoName#${entry.number}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: tokens.textSecondary,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                    if (pr != null &&
                        (pr!.additions > 0 || pr!.deletions > 0)) ...[
                      Text(
                        '  ·  ',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: tokens.textTertiary,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      Text(
                        '+${pr!.additions}',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: tokens.textSuccessPrimary,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      Text(
                        ' −${pr!.deletions}',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: tokens.textErrorPrimary,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                    if (pr?.author != null && pr!.author!.login.isNotEmpty) ...[
                      Text(
                        '  ·  ${pr!.author!.login}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: tokens.textTertiary,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    final opener = onOpenPr;
    if (opener == null) {
      return content;
    }
    return CcTappable(
      onPressed: () => opener(entry.number),
      semanticLabel: pr?.title ?? '#${entry.number}',
      builder: (context, states) {
        final hovered =
            states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.focused);
        return ColoredBox(
          color: hovered && !isCurrent ? tokens.hover : const Color(0x00000000),
          child: content,
        );
      },
    );
  }
}
