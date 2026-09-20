import 'package:cc_domain/features/pr_review/domain/entities/github_profile_activity.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/user_profiles/presentation/widgets/github_profile_metrics_panel.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Identity, delivery metrics and PR table for a user or team profile.
///
/// The PR queue owns the [CustomScrollView]. This widget supplies the
/// identity card and metrics as the first sliver so the All / Open / Merged /
/// Closed control, repo rail and table header can pin while the rows scroll.
class ProfileDeliveryScaffold extends StatelessWidget {
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

  /// All-state PR browser. Reads [ProfileDeliveryLeading] and hosts the
  /// page [CustomScrollView] so the table chrome can pin.
  final Widget queue;

  @override
  Widget build(BuildContext context) {
    return ProfileDeliveryLeading(
      leading: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppSpacing.xl,
          AppSpacing.sm,
          AppSpacing.xl,
          AppSpacing.xl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            header,
            const SizedBox(height: AppSpacing.lg),
            GitHubProfileMetricsPanel(activity: activity),
          ],
        ),
      ),
      child: queue,
    );
  }
}

/// Paints the profile identity card and metrics as the first sliver of the
/// PR queue's [CustomScrollView].
class ProfileDeliveryLeading extends InheritedWidget {
  /// Creates the leading-content scope.
  const ProfileDeliveryLeading({
    super.key,
    required this.leading,
    required super.child,
  });

  /// Identity + metrics, already padded to the page gutter.
  final Widget leading;

  /// The leading content if this profile body is mounted, otherwise null
  /// (queue-only tests).
  static Widget? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<ProfileDeliveryLeading>()
        ?.leading;
  }

  @override
  bool updateShouldNotify(ProfileDeliveryLeading oldWidget) =>
      leading != oldWidget.leading;
}
