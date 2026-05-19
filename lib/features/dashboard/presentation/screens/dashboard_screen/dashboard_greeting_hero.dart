import 'package:control_center/core/theme/app_radii.dart';
import 'package:control_center/core/theme/app_shadows.dart';
import 'package:control_center/core/theme/app_spacing.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/dashboard/presentation/screens/dashboard_screen/dashboard_shared.dart';
import 'package:control_center/features/dashboard/providers/dashboard_priority_reviews_provider.dart';
import 'package:control_center/features/github_status/presentation/widgets/github_status_indicator.dart';
import 'package:control_center/features/ticketing/presentation/widgets/new_ticket_dialog.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/providers/last_checked_provider.dart';
import 'package:control_center/shared/widgets/refresh_control.dart';
import 'package:control_center/shared/widgets/shader_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Asset path for the dark-mode golden-hour cloudscape shader.
const String _dashboardShaderDark =
    'assets/shaders/dashboard_background_dark.frag';

/// Asset path for the light-mode golden-hour cloudscape shader.
const String _dashboardShaderLight =
    'assets/shaders/dashboard_background_light.frag';

/// Opacity of the animated cloudscape over the panel canvas. Kept below 1 so
/// the warm canvas reads through and the greeting stays high-contrast; tuned
/// to keep the day-to-day surface quiet while the shapes still breathe.
const double _shaderVeil = 0.6;

/// The greeting hero — the dashboard's one earned brand moment. A warm panel
/// with a golden-hour cloudscape, the personal greeting, a live fleet pill and
/// the promoted "New ticket" action. The panel breathes via a slow cloudscape
/// shader; `prefers-reduced-motion` renders it frozen (speed 0) so the shapes
/// stay but the motion stops.
class DashboardGreetingHero extends ConsumerWidget {
  /// Creates a [DashboardGreetingHero].
  const DashboardGreetingHero({super.key, required this.codeFont});

  /// User-selected code font for the eyebrow.
  final String codeFont;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final ds = dashTokens(context);

    // Stamp the dashboard's freshness on each successful priority-reviews fetch
    // (initial load and post-refresh) so the hero can report "Checked {time}".
    ref.listen(dashboardPriorityReviewsProvider, (_, next) {
      if (next is AsyncData && !next.isLoading) {
        ref.read(lastCheckedProvider.notifier).stamp('dashboard');
      }
    });
    final lastChecked = ref.watch(
      lastCheckedProvider.select((m) => m['dashboard']),
    );

    final workspace = ref.watch(activeWorkspaceProvider);
    final user = ref.watch(githubUserProvider).asData?.value;
    final fullName = user?.name ?? '';
    final userName = fullName.isNotEmpty ? fullName : (user?.login ?? '');
    final greeting = userName.isNotEmpty
        ? l10n.dashboardGreetingNamed(userName)
        : l10n.dashboardGreeting;

    final dateLabel = DateFormat.MMMEd(
      Localizations.localeOf(context).toLanguageTag(),
    ).format(DateTime.now());

    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final shaderAsset = Theme.of(context).brightness == Brightness.dark
        ? _dashboardShaderDark
        : _dashboardShaderLight;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: ds.canvas,
        borderRadius: AppRadii.brLg,
        border: Border.all(color: ds.borderPrimary),
        boxShadow: AppShadows.soft,
        gradient: RadialGradient(
          center: const Alignment(0.7, -1.1),
          radius: 1.1,
          colors: [
            ds.surface.withValues(alpha: 0.65),
            ds.canvas.withValues(alpha: 0),
          ],
        ),
      ),
      child: ClipRRect(
        borderRadius: AppRadii.brLg,
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                // The cloudscape shader breathes the panel. Under
                // prefers-reduced-motion it renders frozen (speed 0) — the
                // shapes stay, the motion stops; no static-horizon fallback.
                child: Opacity(
                  opacity: _shaderVeil,
                  child: ShaderBackground(
                    shaderAsset: shaderAsset,
                    animate: !reduceMotion,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xxl,
                AppSpacing.xxl,
                AppSpacing.xxl,
                AppSpacing.xl,
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final titleSize =
                      (constraints.maxWidth * 0.072).clamp(38.0, 60.0);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          if (workspace != null)
                            DashboardEyebrow(
                              l10n.workspaceEyebrow(workspace.name),
                              codeFont: codeFont,
                            ),
                          const SizedBox(width: AppSpacing.md),
                          DashboardEyebrow(
                            dateLabel,
                            codeFont: codeFont,
                            color: ds.muted.withValues(alpha: 0.7),
                          ),
                          const Spacer(),
                          RefreshControl(
                            lastChecked: lastChecked,
                            tooltip: l10n.refresh,
                            onRefresh: () => ref.invalidate(
                              dashboardPriorityReviewsProvider,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        greeting,
                        style: TextStyle(
                          fontSize: titleSize,
                          height: 1.0,
                          letterSpacing: -0.025 * titleSize,
                          fontWeight: FontWeight.w500,
                          color: ds.fg,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 460),
                        child: Text(
                          l10n.dashboardSubtitle,
                          style: TextStyle(
                            fontSize: 18,
                            height: 1.4,
                            color: ds.muted,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      const _HeroFoot(),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The GitHub status indicator plus the New-ticket action.
class _HeroFoot extends ConsumerWidget {
  const _HeroFoot();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    final actions = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        DashboardButton(
          label: l10n.newTicket,
          style: DashButtonStyle.dark,
          icon: LucideIcons.plus,
          // ignore: discarded_futures
          onTap: () => showNewTicketDialog(context),
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 520) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const GitHubStatusButton(),
              const SizedBox(height: AppSpacing.md),
              actions,
            ],
          );
        }
        return Row(
          children: [const GitHubStatusButton(), const Spacer(), actions],
        );
      },
    );
  }
}

