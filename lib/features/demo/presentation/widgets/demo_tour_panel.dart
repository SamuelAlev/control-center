import 'package:cc_domain/features/messaging/domain/entities/space.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/demo_providers.dart';
import 'package:control_center/features/demo/demo_world.dart';
import 'package:control_center/features/demo/providers/demo_providers.dart';
import 'package:control_center/features/demo/providers/demo_repo_stars_provider.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/utils/open_url.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// One stop on the demo tour.
class _TourStop {
  const _TourStop({
    required this.title,
    required this.body,
    required this.icon,
    required this.route,
  });

  final String title;
  final String body;
  final IconData icon;
  final String route;
}

/// The seeded space the "Talk to an agent" stop opens, or null while the
/// workspace's spaces have not loaded (or nothing matched).
///
/// Prefers the seeded [kDemoAgentSpaceName] space; falls back to any other
/// space so the stop still lands on a conversation a visitor can type into.
Space? _agentSpace(List<Space> spaces) {
  for (final space in spaces) {
    if (space.name == kDemoAgentSpaceName && space.archivedAt == null) {
      return space;
    }
  }
  for (final space in spaces) {
    if (space.archivedAt == null) {
      return space;
    }
  }
  return null;
}

/// A dismissible panel pointing a visitor at the four surfaces worth seeing.
///
/// It is a plain list of destinations rather than a step-by-step coach mark,
/// and that is a deliberate limit: `cc_ui` has no tour/coach-mark component,
/// and a demo is not a good reason to add one to the design system — a
/// component that exists for one caller is a component nobody maintains.
/// Everything here is built from primitives the rest of the app already uses.
///
/// Every stop deep-links INTO the seeded world (a conversation, an open PR, a
/// ticket, the inbox) rather than the surface's list page: a visitor who is
/// handed the bare `/spaces` landing is handed an empty state asking them to
/// create a space — the exact opposite of what a furnished demo should do.
/// The space id is resolved at runtime because the seeder mints UUIDs.
///
/// Renders nothing against a real server, and nothing once dismissed.
class DemoTourPanel extends ConsumerWidget {
  /// Creates the tour panel for [workspaceId].
  const DemoTourPanel({
    required this.workspaceId,
    super.key,
    this.openUrl = openExternalUrl,
  });

  /// The workspace whose routes the stops link to.
  final String workspaceId;

  /// Hands a URL to the OS's default browser (a new tab on web). Injected so
  /// the widget test can observe the "Star on GitHub" button without loading
  /// the native URL opener, which does not exist under `flutter_tester`.
  final bool Function(String url) openUrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(isDemoServerProvider)) {
      return const SizedBox.shrink();
    }
    if (ref.watch(demoShellDismissalsProvider).contains(kDemoTourId)) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context);
    final t = context.ds;
    final stars = ref.watch(demoRepoStarsProvider).asData?.value;
    final spaces =
        ref.watch(workspaceSpacesProvider(workspaceId)).asData?.value ??
        const <Space>[];
    final agentSpace = _agentSpace(spaces);
    final stops = <_TourStop>[
      _TourStop(
        title: l10n.demoTourSpacesTitle,
        body: l10n.demoTourSpacesBody,
        icon: CcIcons.messageSquare,
        route: agentSpace != null
            ? spaceRoute(workspaceId, agentSpace.id)
            : spacesRoute(workspaceId),
      ),
      _TourStop(
        title: l10n.demoTourReviewTitle,
        body: l10n.demoTourReviewBody,
        icon: CcIcons.gitPullRequest,
        route: pullRequestDetailRoute(
          workspaceId,
          kDemoRepoFullName,
          kDemoReviewPrNumber,
        ),
      ),
      _TourStop(
        title: l10n.demoTourTicketsTitle,
        body: l10n.demoTourTicketsBody,
        icon: CcIcons.listTodo,
        route: ticketDetailRoute(workspaceId, kDemoTicketId),
      ),
      _TourStop(
        title: l10n.demoTourInboxTitle,
        body: l10n.demoTourInboxBody,
        icon: CcIcons.layoutDashboard,
        route: inboxRoute(workspaceId),
      ),
    ];

    return CcCard(
      // An ACCENT border, which is where this panel earns one: it is a
      // transient invitation layered over the app, not a permanent surface,
      // and the accent is what separates it from the panes behind it. The
      // shell's own chrome deliberately keeps the neutral hairline — an
      // accent line under the title bar reads as a persistent alert on every
      // screen rather than as a pointer to this card.
      tokens: CcCardTokens(
        bg: t.panel,
        border: t.accent,
        hoverBg: t.hover,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.demoTourTitle,
                        style: CcTypography.title.copyWith(
                          color: t.textPrimary,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        l10n.demoTourSubtitle,
                        style: CcTypography.caption.copyWith(
                          color: t.textSecondary,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                ),
                // The one link out of the demo: everything else in the panel
                // deep-links INTO the seeded world, but a visitor who likes
                // what they see needs somewhere real to take it. Secondary
                // keeps it in the panel's button vocabulary (the stops' "Open"
                // buttons); the star icon is what marks it as the product CTA.
                // The trailing count is the server's cached answer — absent
                // rather than "…" while it loads or on failure, because a
                // marketing number never earns a spinner or an error.
                const SizedBox(width: AppSpacing.xs),
                CcButton(
                  variant: CcButtonVariant.secondary,
                  icon: CcIcons.star,
                  onPressed: () => openUrl(kDemoProjectRepoUrl),
                  trailing: stars == null
                      ? null
                      : Text(
                          formatCompactCount(stars),
                          style: CcTypography.body.copyWith(
                            color: t.textSecondary,
                          ),
                        ),
                  child: Text(l10n.demoTourStarRepo),
                ),
                const SizedBox(width: AppSpacing.xs),
                CcButton(
                  variant: CcButtonVariant.ghost,
                  onPressed: () => ref
                      .read(demoShellDismissalsProvider.notifier)
                      .dismiss(kDemoTourId),
                  child: Text(l10n.demoTourSkip),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final stop in stops) ...[
              const CcDivider(),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xxs),
                      child: Icon(
                        stop.icon,
                        size: 16,
                        color: t.textSecondary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            stop.title,
                            style: CcTypography.body.copyWith(
                              color: t.textPrimary,
                              decoration: TextDecoration.none,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            stop.body,
                            style: CcTypography.caption.copyWith(
                              color: t.textSecondary,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    CcButton(
                      variant: CcButtonVariant.secondary,
                      onPressed: () => context.go(stop.route),
                      child: Text(l10n.demoTourOpen),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
