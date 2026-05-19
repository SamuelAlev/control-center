import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/domain/entities/repo.dart';
import 'package:control_center/core/errors/app_exceptions.dart';
import 'package:control_center/features/dashboard/presentation/screens/dashboard_screen/dashboard_shared.dart';
import 'package:control_center/features/dashboard/providers/dashboard_priority_reviews_provider.dart';
import 'package:control_center/features/pr_review/domain/entities/enriched_pull_request.dart';
import 'package:control_center/features/pr_review/domain/entities/pull_request.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pull_request_list/pr_list_shared.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/utils/relative_time.dart';
import 'package:control_center/shared/widgets/pr_title_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The "Priority reviews" panel — the PRs that genuinely need the operator:
/// open, requesting their review, waiting more than a day. Grouped by repo,
/// with an info affordance explaining the priority rule.
class DashboardPriorityReviews extends ConsumerWidget {
  /// Creates a [DashboardPriorityReviews].
  const DashboardPriorityReviews({super.key, required this.codeFont});

  /// User-selected code font.
  final String codeFont;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final data = ref.watch(dashboardPriorityReviewsProvider);

    return DashboardPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          DashboardPanelHeader(
            title: l10n.priorityReviews,
            codeFont: codeFont,
            titleAdornment: _InfoDot(tooltip: l10n.priorityReviewsTooltip),
            count: data.maybeWhen(
              data: (reviews) =>
                  reviews.isEmpty ? null : '${reviews.length}',
              orElse: () => null,
            ),
            trailing: DashboardLinkArrow(
              label: l10n.allPullRequests,
              onTap: () => GoRouter.of(context).go(pullRequestsRoute),
            ),
          ),
          data.when(
            loading: () => const SizedBox(
              height: 120,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (error, _) =>
                _ErrorChild(l10n: l10n, detail: _describeError(error)),
            data: (reviews) => _Groups(
              reviews: reviews,
              codeFont: codeFont,
              l10n: l10n,
            ),
          ),
        ],
      ),
    );
  }
}

/// Groups priority reviews by repository, preserving first-seen order.
class _Groups extends StatelessWidget {
  const _Groups({
    required this.reviews,
    required this.codeFont,
    required this.l10n,
  });

  final List<PriorityReview> reviews;
  final String codeFont;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    if (reviews.isEmpty) {
      return _CaughtUp(l10n: l10n);
    }

    final order = <String>[];
    final byRepo = <String, (Repo, List<PullRequest>)>{};
    for (final r in reviews) {
      final entry = byRepo.putIfAbsent(r.repo.id, () {
        order.add(r.repo.id);
        return (r.repo, <PullRequest>[]);
      });
      entry.$2.add(r.pr);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final id in order)
          Builder(
            builder: (context) {
              final (repo, prs) = byRepo[id]!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _RepoHead(repo: repo, count: prs.length, codeFont: codeFont),
                  for (final pr in prs)
                    _PrRow(pr: pr, repo: repo, codeFont: codeFont, l10n: l10n),
                ],
              );
            },
          ),
      ],
    );
  }
}

/// A small info dot with a tooltip explaining the priority rule.
class _InfoDot extends StatelessWidget {
  const _InfoDot({required this.tooltip});

  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final ds = dashTokens(context);
    return CcTooltip(
      message: tooltip,
      maxWidth: 260,
      child: MouseRegion(
        cursor: SystemMouseCursors.help,
        child: Icon(LucideIcons.info, size: 14, color: ds.muted),
      ),
    );
  }
}

/// A concise, single-line description of why the panel failed, shown under the
/// localized headline so the cause is visible instead of a detail-free "failed
/// to load". The full GitHub response body (e.g. the secondary-rate-limit text
/// on an over-expensive query) is logged by the network layer, not crammed here.
String? _describeError(Object error) {
  if (error is NetworkException) {
    final status = error.statusCode;
    return '${status != null ? '$status · ' : ''}${error.message}';
  }
  if (error is AppException) {
    return error.message;
  }
  return error.toString();
}

class _ErrorChild extends StatelessWidget {
  const _ErrorChild({required this.l10n, this.detail});

  final AppLocalizations l10n;

  /// Concise cause (status + message), shown muted under the headline.
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final ds = dashTokens(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(LucideIcons.circleAlert, size: 16, color: ds.danger),
              const SizedBox(width: AppSpacing.sm),
              Text(
                l10n.failedToLoad,
                style: TextStyle(fontSize: 13, color: ds.muted),
              ),
            ],
          ),
          if (detail != null && detail!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Padding(
              padding: const EdgeInsets.only(left: 16 + AppSpacing.sm),
              child: Text(
                detail!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: ds.muted, height: 1.3),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CaughtUp extends StatelessWidget {
  const _CaughtUp({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final ds = dashTokens(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Column(
        children: [
          Icon(LucideIcons.circleCheck, size: 22, color: ds.success),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.allCaughtUp,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: ds.fg,
            ),
          ),
        ],
      ),
    );
  }
}

class _RepoHead extends StatelessWidget {
  const _RepoHead({
    required this.repo,
    required this.count,
    required this.codeFont,
  });

  final Repo repo;
  final int count;
  final String codeFont;

  @override
  Widget build(BuildContext context) {
    final ds = dashTokens(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: ds.rail,
        border: Border(
          left: BorderSide(color: ds.borderPrimary),
          right: BorderSide(color: ds.borderPrimary),
          bottom: BorderSide(color: ds.borderPrimary),
        ),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.folderGit2, size: 13, color: ds.muted),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: RichText(
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                style: dashMono(codeFont, size: 12, color: ds.muted),
                children: [
                  TextSpan(text: '${repo.githubOwner}/'),
                  TextSpan(
                    text: repo.githubRepoName,
                    style: dashMono(codeFont, size: 12, color: ds.fg),
                  ),
                ],
              ),
            ),
          ),
          Text('$count', style: dashMono(codeFont, size: 12, color: ds.muted)),
        ],
      ),
    );
  }
}

class _PrRow extends ConsumerStatefulWidget {
  const _PrRow({
    required this.pr,
    required this.repo,
    required this.codeFont,
    required this.l10n,
  });

  final PullRequest pr;

  /// The repository this PR belongs to. Threaded through so the tap handler
  /// activates the correct repo before navigating — the priority-reviews panel
  /// spans repos, so opening by PR number alone would resolve against whatever
  /// repo happens to be active and open the wrong PR.
  final Repo repo;
  final String codeFont;
  final AppLocalizations l10n;

  @override
  ConsumerState<_PrRow> createState() => _PrRowState();
}

class _PrRowState extends ConsumerState<_PrRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final ds = dashTokens(context);
    final pr = widget.pr;
    final l10n = widget.l10n;
    final age = formatRelativeTime(context, pr.updatedAt ?? pr.createdAt);
    final hasDiff = pr.additions > 0 || pr.deletions > 0;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => openPrInRepo(ref, context, widget.repo, pr.number),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: _hover ? ds.hover : null,
                border: Border(bottom: BorderSide(color: ds.borderPrimary)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(
                      pr.isDraft
                          ? LucideIcons.gitPullRequestDraft
                          : LucideIcons.gitPullRequest,
                      size: 16,
                      color: ds.muted,
                    ),
                  ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title row: title + badge (left) | diff stats (right)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Flexible(
                                child: PrTitleText(
                                  pr.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 14,
                                    height: 1.35,
                                    color: ds.fg,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Padding(
                                padding: const EdgeInsets.only(top: 1),
                                child: pr.isDraft
                                    ? _Badge(
                                        label: l10n.draftBadge,
                                        color: ds.muted,
                                        background: ds.hoverStrong,
                                        codeFont: widget.codeFont,
                                      )
                                    : _Badge(
                                        label: l10n.reviewRequestedBadge,
                                        color: Color.lerp(
                                          ds.warn,
                                          Colors.black,
                                          0.3,
                                        )!,
                                        background: ds.warnSoft,
                                        codeFont: widget.codeFont,
                                      ),
                              ),
                            ],
                          ),
                        ),
                        if (hasDiff) ...[
                          const SizedBox(width: AppSpacing.md),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '+${pr.additions}',
                                style: dashMono(
                                  widget.codeFont,
                                  size: 12,
                                  color: ds.success,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '−${pr.deletions}',
                                style: dashMono(
                                  widget.codeFont,
                                  size: 12,
                                  color: ds.danger,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Metadata row: number + branch + age (left) | comments (right)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          '#${pr.number}',
                          style: dashMono(
                            widget.codeFont,
                            size: 11,
                            color: ds.muted,
                          ),
                        ),
                        if (pr.headRef.isNotEmpty) ...[
                          const SizedBox(width: AppSpacing.sm),
                          Container(
                            constraints: const BoxConstraints(maxWidth: 240),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: ds.canvas,
                              borderRadius: AppRadii.brSm,
                              border: Border.all(color: ds.borderPrimary),
                            ),
                            child: Text(
                              pr.headRef,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: dashMono(
                                widget.codeFont,
                                size: 11,
                                color: ds.fg,
                              ),
                            ),
                          ),
                        ],
                        if (age.isNotEmpty) ...[
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            age,
                            style: dashMono(
                              widget.codeFont,
                              size: 11,
                              color: ds.muted,
                            ),
                          ),
                        ],
                        const Spacer(),
                        if (pr.commentsCount > 0)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Icon(
                                  LucideIcons.messageSquare,
                                  size: 11,
                                  color: ds.muted,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${pr.commentsCount}',
                                style: dashMono(
                                  widget.codeFont,
                                  size: 11,
                                  color: ds.muted,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.color,
    required this.background,
    required this.codeFont,
  });

  final String label;
  final Color color;
  final Color background;
  final String codeFont;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadii.brSm,
      ),
      child: Text(
        label.toUpperCase(),
        style: dashMono(codeFont, size: 10, color: color, letterSpacing: 0.4),
      ),
    );
  }
}
