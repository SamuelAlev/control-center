import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_user.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pr_review/providers/pr_filter_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/github_user_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// The pure filter predicates moved to the providers layer (so provider code
// like the inbox pipeline can use them without importing presentation);
// re-exported here for the many presentation-side importers.
export 'package:control_center/features/pr_review/providers/pr_filter_providers.dart'
    show
        applyFilters,
        isQuickToReview,
        prMatchesStatus,
        prPassesFilters,
        prRepoNameOf,
        prRepoOwnerOf;

/// Navigates to the detail view for [prNumber] in [repo].
///
/// The repo is part of the detail URL (PR numbers are per-repo), so it is
/// required — without it there is no unambiguous PR to open and the call is a
/// no-op. The active repo is also pinned so repo-scoped chrome outside the PR
/// surface follows the PR being viewed.
void openPrInRepo(
  WidgetRef ref,
  BuildContext context,
  Repo? repo,
  int prNumber,
) {
  if (repo == null) {
    return;
  }
  ref.read(activeRepoIdProvider.notifier).setActive(repo.id);
  GoRouter.of(context).go(
    pullRequestDetailRoute(
      context.currentWorkspaceId!,
      repo.fullName,
      prNumber,
    ),
  );
}

/// The localized label of a status facet — shared by the filter menu's
/// status submenu and any status-grouped section headers.
String prStatusFilterLabel(AppLocalizations l10n, PrStatusFilter status) =>
    switch (status) {
      PrStatusFilter.draft => l10n.prStatusDraft,
      PrStatusFilter.open => l10n.prStatusOpen,
      PrStatusFilter.inReview => l10n.prStatusInReview,
      PrStatusFilter.changesRequested => l10n.prStatusChangesRequested,
      PrStatusFilter.approved => l10n.prStatusApproved,
      PrStatusFilter.merged => l10n.prStatusMerged,
      PrStatusFilter.closed => l10n.prStatusClosed,
    };

/// The glyph of a status facet, paired with [prStatusFilterLabel] so status
/// is never carried by color alone.
IconData prStatusFilterIcon(PrStatusFilter status) => switch (status) {
  PrStatusFilter.draft => AppIcons.gitPullRequestDraft,
  PrStatusFilter.open => AppIcons.gitPullRequest,
  PrStatusFilter.inReview => AppIcons.eye,
  PrStatusFilter.changesRequested => AppIcons.circleSlash,
  PrStatusFilter.approved => AppIcons.circleCheck,
  PrStatusFilter.merged => AppIcons.gitMerge,
  PrStatusFilter.closed => AppIcons.gitPullRequestClosed,
};

/// Builds an avatar widget for a [PrUser], falling back to `fallbackName`.
Widget buildAvatar(PrUser? user, String fallbackName, {double size = 24}) {
  final login = user?.login ?? fallbackName;
  final avatarUrl = user?.avatarUrl;
  if (login.isEmpty && avatarUrl == null) {
    return GitHubUserAvatar(login: '?', size: size, showHoverCard: false);
  }
  return GitHubUserAvatar(login: login, avatarUrl: avatarUrl, size: size);
}

/// Collects unique authors from a list of pull requests, sorted by login.
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

/// Collects unique requested reviewers from a list of pull requests, sorted
/// by login — the option population for the reviewer filter.
List<PrUser> collectReviewers(List<PullRequest> prs) {
  final map = <String, PrUser>{};
  for (final pr in prs) {
    for (final reviewer in pr.requestedReviewers) {
      if (reviewer.login.isNotEmpty) {
        map.putIfAbsent(reviewer.login.toLowerCase(), () => reviewer);
      }
    }
  }
  final list = map.values.toList();
  list.sort((a, b) => a.login.toLowerCase().compareTo(b.login.toLowerCase()));
  return list;
}

/// Empty-state placeholder shown when no config is present.
class EmptyConfigState extends StatelessWidget {
  /// Creates an [EmptyConfigState].
  const EmptyConfigState({
    super.key,
    required this.icon,
    required this.message,
    required this.hint,
    this.action,
  });

  /// Icon shown above the message.
  final IconData icon;

  /// Primary message text.
  final String message;

  /// Hint text shown below the message.
  final String hint;

  /// Optional action widget below the hint.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: tokens.textTertiary),
          const SizedBox(height: 16),
          Text(
            message,
            style: CcTypography.title.copyWith(color: tokens.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            hint,
            textAlign: TextAlign.center,
            style: CcTypography.body.copyWith(color: tokens.textTertiary),
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
