import 'package:control_center/core/domain/notifications/notification_category.dart';
import 'package:control_center/core/notifications/notification_center.dart';
import 'package:control_center/core/theme/app_radii.dart';
import 'package:control_center/core/theme/app_spacing.dart';
import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/features/dashboard/presentation/screens/dashboard_screen/dashboard_shared.dart';
import 'package:control_center/features/dashboard/providers/dashboard_providers.dart';
import 'package:control_center/features/dashboard/providers/needs_provider.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/utils/relative_time.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The "Needs you now" panel — the operator's triage queue: awaiting reviews,
/// blocked agents, failed pipelines and stale PRs, each with a single next
/// action.
class DashboardNeedsPanel extends ConsumerWidget {
  /// Creates a [DashboardNeedsPanel].
  const DashboardNeedsPanel({super.key, required this.codeFont});

  /// User-selected code font.
  final String codeFont;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final ds = dashTokens(context);
    final needs = ref.watch(dashboardNeedsProvider);

    return DashboardPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          DashboardPanelHeader(
            title: l10n.needsYouNow,
            codeFont: codeFont,
            trailing: needs.isEmpty
                ? null
                : Text(
                    '${needs.length}',
                    style: dashMono(codeFont, size: 12, color: ds.muted),
                  ),
          ),
          if (needs.isEmpty)
            _CaughtUp(l10n: l10n)
          else
            for (var i = 0; i < needs.length; i++)
              _NeedRow(
                need: needs[i],
                last: i == needs.length - 1,
                l10n: l10n,
              ),
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
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.xl,
      ),
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
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.allCaughtUpSubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: ds.muted, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _NeedRow extends StatelessWidget {
  const _NeedRow({required this.need, required this.last, required this.l10n});

  final DashboardNeed need;
  final bool last;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final ds = dashTokens(context);
    final spec = _NeedSpec.of(need, ds, l10n);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        border: last
            ? null
            : Border(bottom: BorderSide(color: ds.borderPrimary)),
      ),
      child: Row(
        children: [
          _NeedIcon(
            icon: spec.icon,
            color: spec.color,
            background: spec.background,
            bordered: spec.bordered,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  spec.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: ds.fg,
                  ),
                ),
                if (spec.subtitle != null) ...[
                  const SizedBox(height: 1),
                  Text(
                    spec.subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: ds.muted),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          DashboardButton(
            label: spec.actionLabel,
            style: spec.go ? DashButtonStyle.accent : DashButtonStyle.line,
            small: true,
            onTap: () => GoRouter.of(context).go(spec.route),
          ),
        ],
      ),
    );
  }
}

/// Resolved presentation for a single need row.
class _NeedSpec {
  const _NeedSpec({
    required this.icon,
    required this.color,
    required this.background,
    required this.bordered,
    required this.title,
    required this.actionLabel,
    required this.route,
    required this.go,
    this.subtitle,
  });

  final IconData icon;
  final Color color;
  final Color background;
  final bool bordered;
  final String title;
  final String? subtitle;
  final String actionLabel;
  final String route;
  final bool go;

  static _NeedSpec of(
    DashboardNeed need,
    DesignSystemTokens ds,
    AppLocalizations l10n,
  ) {
    switch (need) {
      case ReviewsNeed():
        return _NeedSpec(
          icon: LucideIcons.gitPullRequestArrow,
          color: ds.accent,
          background: ds.accentSoft,
          bordered: false,
          title: l10n.reviewsAwaitingYou(need.count),
          subtitle:
              need.overTwoDays > 0 ? l10n.reviewsOverTwoDays(need.overTwoDays) : null,
          actionLabel: l10n.review,
          route: pullRequestsRoute,
          go: true,
        );
      case BlockedAgentNeed():
        return _NeedSpec(
          icon: LucideIcons.pause,
          color: Color.lerp(ds.warn, Colors.black, 0.28)!,
          background: ds.warnSoft,
          bordered: false,
          title: l10n.agentBlockedTitle(need.agentName),
          subtitle: l10n.agentBlockedSubtitle,
          actionLabel: l10n.resolve,
          route: agentsRoute,
          go: false,
        );
      case FailedPipelineNeed():
        return _NeedSpec(
          icon: LucideIcons.x,
          color: ds.danger,
          background: ds.dangerSoft,
          bordered: false,
          title: l10n.pipelineFailedTitle,
          subtitle: need.pipelineName,
          actionLabel: l10n.retry,
          route: pipelineRunRoute(need.runId),
          go: false,
        );
      case StalePrNeed():
        return _NeedSpec(
          icon: LucideIcons.clock,
          color: ds.muted,
          background: ds.canvas,
          bordered: true,
          title: l10n.prStaleTitle(need.prNumber),
          subtitle: l10n.prStaleSubtitle,
          actionLabel: l10n.triage,
          route: pullRequestsRoute,
          go: false,
        );
    }
  }
}

class _NeedIcon extends StatelessWidget {
  const _NeedIcon({
    required this.icon,
    required this.color,
    required this.background,
    required this.bordered,
  });

  final IconData icon;
  final Color color;
  final Color background;
  final bool bordered;

  @override
  Widget build(BuildContext context) {
    final ds = dashTokens(context);
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadii.brSm,
        border: bordered ? Border.all(color: ds.borderPrimary) : null,
      ),
      child: Icon(icon, size: 15, color: color),
    );
  }
}

/// The "Recent activity" panel — the in-app notification feed, restyled as a
/// dashboard panel.
class DashboardRecentActivity extends ConsumerWidget {
  /// Creates a [DashboardRecentActivity].
  const DashboardRecentActivity({super.key, required this.codeFont});

  /// User-selected code font.
  final String codeFont;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    // Workspace-scoped: only the active workspace's activity, never other
    // workspaces' (the title-bar bell keeps the global history).
    final entries = ref.watch(workspaceRecentActivityProvider);

    return DashboardPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          DashboardPanelHeader(title: l10n.recentActivityTitle, codeFont: codeFont),
          if (entries.isEmpty)
            _NoActivity(l10n: l10n)
          else
            for (var i = 0; i < entries.length && i < 6; i++)
              _ActivityRow(
                entry: entries[i],
                last: i == entries.length - 1 || i == 5,
                codeFont: codeFont,
              ),
        ],
      ),
    );
  }
}

class _NoActivity extends StatelessWidget {
  const _NoActivity({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final ds = dashTokens(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.xl,
      ),
      child: Column(
        children: [
          Icon(LucideIcons.activity, size: 22, color: ds.muted),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.noRecentActivity,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: ds.fg,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.noRecentActivitySubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: ds.muted, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatefulWidget {
  const _ActivityRow({
    required this.entry,
    required this.last,
    required this.codeFont,
  });

  final NotificationEntry entry;
  final bool last;
  final String codeFont;

  @override
  State<_ActivityRow> createState() => _ActivityRowState();
}

class _ActivityRowState extends State<_ActivityRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final ds = dashTokens(context);
    final n = widget.entry.notification;
    final done = n.category == NotificationCategory.agentRunCompleted ||
        n.category == NotificationCategory.prMerged;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => GoRouter.of(context).go(n.route),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: 11,
          ),
          decoration: BoxDecoration(
            color: _hover ? ds.hover : null,
            border: widget.last
                ? null
                : Border(bottom: BorderSide(color: ds.borderPrimary)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Icon(
                  _iconFor(n.category),
                  size: 15,
                  color: done ? ds.success : ds.muted,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      n.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: ds.fg),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      n.body,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: ds.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                formatRelativeTime(context, widget.entry.receivedAt),
                style: dashMono(widget.codeFont, size: 11, color: ds.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconFor(NotificationCategory category) => switch (category) {
        NotificationCategory.agentRunCompleted => LucideIcons.bot,
        NotificationCategory.pullRequestPublished => LucideIcons.gitPullRequest,
        NotificationCategory.prMerged => LucideIcons.gitMerge,
        NotificationCategory.newMessage => LucideIcons.messageSquare,
        NotificationCategory.externalPr => LucideIcons.gitPullRequestArrow,
        NotificationCategory.ticketAssigned => LucideIcons.ticket,
        NotificationCategory.ticketStatusChanged => LucideIcons.ticketCheck,
      };
}
