import 'package:control_center/core/theme/app_spacing.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/features/dashboard/presentation/screens/dashboard_screen/dashboard_fleet_rail.dart';
import 'package:control_center/features/dashboard/presentation/screens/dashboard_screen/dashboard_greeting_hero.dart';
import 'package:control_center/features/dashboard/presentation/screens/dashboard_screen/dashboard_pipelines_panel.dart';
import 'package:control_center/features/dashboard/presentation/screens/dashboard_screen/dashboard_priority_reviews.dart';
import 'package:control_center/features/dashboard/presentation/screens/dashboard_screen/dashboard_side_panels.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/shared/widgets/page_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The operator's cockpit. A greeting hero (the one earned brand moment), the
/// live fleet rail, a two-column work grid (priority reviews + the "needs you"
/// / recent-activity rail), and the pipelines DAG — every surface reporting
/// real agent, review and pipeline state.
class DashboardScreen extends ConsumerWidget {
  /// Creates a new [DashboardScreen].
  const DashboardScreen({super.key});

  /// Below this content width the work grid stacks to a single column.
  static const double _twoColumnBreakpoint = 720;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Keep the CEO-agent seeding listener alive while the dashboard is shown.
    ref.watch(ceoAgentSeedProvider);

    final codeFont = ref.watch(codeFontFamilyProvider);

    return PageWrapper(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.xl,
          AppSpacing.xl,
          72,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1080),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DashboardGreetingHero(codeFont: codeFont),
                const SizedBox(height: AppSpacing.xxl),
                DashboardFleetRail(codeFont: codeFont),
                const SizedBox(height: AppSpacing.xxl),
                _WorkGrid(codeFont: codeFont),
                const SizedBox(height: AppSpacing.xxl),
                DashboardPipelinesPanel(codeFont: codeFont),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The two-column work grid: priority reviews (left, ~1.85fr) and the right rail
/// stacking "Needs you now" over "Recent activity". Collapses to one column on
/// narrow widths.
class _WorkGrid extends StatelessWidget {
  const _WorkGrid({required this.codeFont});

  final String codeFont;

  @override
  Widget build(BuildContext context) {
    final reviews = DashboardPriorityReviews(codeFont: codeFont);
    final rail = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        DashboardNeedsPanel(codeFont: codeFont),
        const SizedBox(height: AppSpacing.xl),
        DashboardRecentActivity(codeFont: codeFont),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < DashboardScreen._twoColumnBreakpoint) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              reviews,
              const SizedBox(height: AppSpacing.xl),
              rail,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 37, child: reviews),
            const SizedBox(width: AppSpacing.xl),
            Expanded(flex: 20, child: rail),
          ],
        );
      },
    );
  }
}
