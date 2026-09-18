import 'dart:math' as math;

import 'package:cc_domain/features/pr_review/domain/entities/github_profile_activity.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/user_profiles/presentation/widgets/github_profile_metrics_panel.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Identity, delivery metrics and PR table for a user or team profile.
///
/// The table keeps a floor height so a 2×2 metrics grid cannot collapse it
/// into a stub. When the viewport is shorter than that floor, the page
/// scrolls; the table's own list still scrolls inside the reserved pane.
class ProfileDeliveryScaffold extends StatefulWidget {
  /// Creates the shared profile body.
  const ProfileDeliveryScaffold({
    super.key,
    required this.header,
    required this.activity,
    required this.queue,
  });

  /// Profile identity card.
  final Widget header;

  /// Workspace-scoped delivery activity.
  final AsyncValue<GitHubProfileActivity> activity;

  /// All-state PR browser.
  final Widget queue;

  /// Shortest usable height for the PR table, including the state filter.
  static const double tableMinHeight = 320;

  @override
  State<ProfileDeliveryScaffold> createState() =>
      _ProfileDeliveryScaffoldState();
}

class _ProfileDeliveryScaffoldState extends State<ProfileDeliveryScaffold> {
  final GlobalKey _leadingKey = GlobalKey();
  double _leadingHeight = 0;

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _measureLeading();
      }
    });
    return LayoutBuilder(
      builder: (context, constraints) {
        final leftover = constraints.maxHeight - _leadingHeight;
        final queueHeight = _leadingHeight <= 0
            ? ProfileDeliveryScaffold.tableMinHeight
            : math.max(ProfileDeliveryScaffold.tableMinHeight, leftover);
        // Horizontal padding is on the content, not around this view.
        // Wrapping the scrollable would inset the thumb from the pane edge.
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              KeyedSubtree(
                key: _leadingKey,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    AppSpacing.sm,
                    AppSpacing.xl,
                    AppSpacing.xl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      widget.header,
                      const SizedBox(height: AppSpacing.lg),
                      GitHubProfileMetricsPanel(activity: widget.activity),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: SizedBox(height: queueHeight, child: widget.queue),
              ),
            ],
          ),
        );
      },
    );
  }

  void _measureLeading() {
    final box = _leadingKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) {
      return;
    }
    final next = box.size.height;
    if ((next - _leadingHeight).abs() <= 0.5) {
      return;
    }
    setState(() => _leadingHeight = next);
  }
}
