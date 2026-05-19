import 'package:control_center/core/domain/entities/repo.dart';
import 'package:control_center/core/theme/app_radii.dart';
import 'package:control_center/core/theme/app_spacing.dart';
import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/features/pr_review/domain/entities/pr_user.dart';
import 'package:control_center/features/pr_review/domain/entities/pull_request.dart';
import 'package:control_center/features/pr_review/presentation/utils/decision_lane.dart';
import 'package:control_center/features/pr_review/providers/pr_filter_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_lane_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/widgets/github_user_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

class SelectedPrNumberNotifier extends Notifier<int?> {
  @override
  int? build() => null;

  void select(int? number) => state = number;
}

final selectedPrNumberProvider =
    NotifierProvider<SelectedPrNumberNotifier, int?>(
      SelectedPrNumberNotifier.new,
    );

// PR numbers are unique only *within* a repo, so a row's stable identity in the
// multi-repo queue is the (repoId, number) pair — keying by number alone makes
// two repos that each have, say, PR #1 collide on the same [GlobalKey].
typedef PrRowKeyGetter = GlobalKey Function(String repoId, int number);
typedef PrRowFocusGetter = FocusNode Function(String repoId, int number);
typedef OpenPrCallback =
    void Function(
      WidgetRef ref,
      BuildContext context,
      Repo? repo,
      int prNumber,
    );

void openPrInRepo(
  WidgetRef ref,
  BuildContext context,
  Repo? repo,
  int prNumber,
) {
  if (repo != null) {
    ref.read(activeRepoIdProvider.notifier).setActive(repo.id);
  }
  GoRouter.of(context).go(pullRequestDetailRoute(prNumber));
}

List<PullRequest> applyFilters(
  List<PullRequest> prs, {
  required PrListFilters filters,
  required String currentLogin,
}) {
  if (!filters.isActive) {
    return prs;
  }
  final me = currentLogin.toLowerCase();
  return prs.where((pr) {
    final hasReviewFilter =
        filters.awaitingReview || filters.createdByMe || filters.reviewedByMe;
    if (hasReviewFilter) {
      if (me.isEmpty) {
        return false;
      }
      bool passes = false;
      if (filters.awaitingReview) {
        final iAmReviewer = pr.requestedReviewers.any(
          (r) => r.login.toLowerCase() == me,
        );
        passes = passes || iAmReviewer;
      }
      if (filters.createdByMe) {
        final iAmAuthor = pr.author?.login.toLowerCase() == me;
        passes = passes || iAmAuthor;
      }
      if (filters.reviewedByMe) {
        passes = passes || pr.reviewedByMe;
      }
      if (!passes) {
        return false;
      }
    }
    if (filters.authors.isNotEmpty) {
      final author = pr.author?.login;
      if (author == null || !filters.authors.contains(author)) {
        return false;
      }
    }
    return true;
  }).toList();
}

/// Whether the operator ([currentLogin], lowercased) is a requested reviewer
/// on [pr] — the signal that lands a PR in [DecisionLane.review].
bool awaitingReviewFromMe(PullRequest pr, String currentLogin) {
  if (currentLogin.isEmpty) {
    return false;
  }
  return pr.requestedReviewers.any(
    (r) => r.login.toLowerCase() == currentLogin,
  );
}

/// Classifies [pr] into its [DecisionLane]s for the given operator.
Set<DecisionLane> lanesOfPr(PullRequest pr, String currentLogin) {
  return classifyDecisionLanes(
    pr,
    awaitingMe: awaitingReviewFromMe(pr, currentLogin),
  );
}

/// Orders [prs] for display per [sort]. `recent` preserves the incoming order
/// (already most-recently-updated first); `oldest` reverses it; `largest`
/// orders by total diff churn descending.
List<PullRequest> sortPrs(List<PullRequest> prs, PrListSort sort) {
  switch (sort) {
    case PrListSort.recent:
      return prs;
    case PrListSort.oldest:
      return prs.reversed.toList();
    case PrListSort.largest:
      final copy = List<PullRequest>.of(prs);
      copy.sort(
        (a, b) =>
            (b.additions + b.deletions).compareTo(a.additions + a.deletions),
      );
      return copy;
  }
}

/// The PRs of a repo that should be visible: capsule-filtered, then narrowed
/// to `lane` (when non-null), then ordered by `sort`.
List<PullRequest> visiblePrsFor(
  List<PullRequest> prs, {
  required PrListFilters filters,
  required String currentLogin,
  required DecisionLane? lane,
  required PrListSort sort,
}) {
  var result = applyFilters(prs, filters: filters, currentLogin: currentLogin);
  if (lane != null) {
    result =
        result.where((pr) => lanesOfPr(pr, currentLogin).contains(lane)).toList();
  }
  return sortPrs(result, sort);
}

Widget buildAvatar(PrUser? user, String fallbackName, {double size = 24}) {
  final login = user?.login ?? fallbackName;
  final avatarUrl = user?.avatarUrl;
  if (login.isEmpty && avatarUrl == null) {
    return GitHubUserAvatar(login: '?', size: size, showHoverCard: false);
  }
  return GitHubUserAvatar(login: login, avatarUrl: avatarUrl, size: size);
}

String truncateBody(String body, {int maxChars = 140}) {
  final stripped = body
      .replaceAll(RegExp(r'\r?\n'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (stripped.length <= maxChars) {
    return stripped;
  }

  return '${stripped.substring(0, maxChars)}…';
}

List<PrUser> collectAuthors(List<PullRequest> prs) {
  final map = <String, PrUser>{};
  for (final pr in prs) {
    final author = pr.author;
    if (author != null && author.login.isNotEmpty) {
      map.putIfAbsent(author.login, () => author);
    }
  }
  final list = map.values.toList();
  list.sort((a, b) => a.login.toLowerCase().compareTo(b.login.toLowerCase()));
  return list;
}

class EmptyConfigState extends StatelessWidget {
  const EmptyConfigState({
    super.key,
    required this.icon,
    required this.message,
    required this.hint,
    this.action,
  });

  final IconData icon;
  final String message;
  final String hint;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: colors.mutedForeground),
          const SizedBox(height: 16),
          Text(
            message,
            style: textTheme.titleMedium?.copyWith(color: colors.foreground),
          ),
          const SizedBox(height: 8),
          Text(
            hint,
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: colors.mutedForeground,
            ),
          ),
          if (action != null) ...[
            const SizedBox(height: 24),
            UnconstrainedBox(child: action!),
          ],
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  /// Section title with an optional trailing [CountPill].
  const SectionHeader({super.key, required this.title, this.countBadge});

  /// The section title.
  final String title;

  /// Optional count rendered as a [CountPill] beside the title.
  final String? countBadge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        if (countBadge != null) ...[AppSpacing.hGapSm, CountPill(countBadge!)],
      ],
    );
  }
}

/// A quiet, token-driven count chip (e.g. the PR count beside a section
/// heading or repo row). Uses the cool graphite surface tokens, not Material's
/// `secondaryContainer`, so it reads as instrument metadata rather than a
/// coloured badge. Digits are tabular so the pill width stays stable as counts
/// tick up.
class CountPill extends StatelessWidget {
  /// Creates a [CountPill] showing [label].
  const CountPill(this.label, {super.key});

  /// The count text (e.g. `12`, `3 / 12+`).
  final String label;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem;
    final colors = context.theme.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
      decoration: BoxDecoration(
        color: tokens?.bgSecondary ?? colors.muted,
        borderRadius: AppRadii.brSm,
        border: Border.all(color: tokens?.borderSecondary ?? colors.border),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: tokens?.textTertiary ?? colors.mutedForeground,
          fontWeight: FontWeight.w600,
          fontFeatures: const [FontFeature.tabularFigures()],
          height: 1.3,
        ),
      ),
    );
  }
}

/// A small amber "attention" badge for action-needed states (priority,
/// review requested). Mirrors the design system's sanctioned attention
/// treatment — Caution Amber text on an amber-tinted fill with a hairline
/// amber border — and always pairs colour with an [icon] + [label] so the
/// state survives grayscale and colour-blindness. Never red: red is reserved
/// for errors and destructive actions.
class AttentionBadge extends StatelessWidget {
  /// Creates an [AttentionBadge].
  const AttentionBadge({super.key, required this.icon, required this.label});

  /// Leading glyph (e.g. eye for review-requested, alert-triangle for
  /// priority).
  final IconData icon;

  /// Short, sentence-case label.
  final String label;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem;
    final fg = tokens?.textWarningPrimary ?? const Color(0xFFCA8504);
    final bg = tokens?.bgWarningPrimary ?? fg.withValues(alpha: 0.10);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadii.brSm,
        border: Border.all(color: fg.withValues(alpha: 0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: fg),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            overflow: TextOverflow.ellipsis,
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
