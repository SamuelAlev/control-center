import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pr_review/presentation/screens/pull_request_detail/pr_tab_chip.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:material_ui/material_ui.dart';

/// The pinned Files-changed / Commits tab strip above the compose diff, styled
/// to match the PR detail page's tab strip.
class ComposeTabBar extends StatelessWidget {
  /// Creates a [ComposeTabBar].
  const ComposeTabBar({
    required this.controller,
    required this.filesCount,
    required this.commitsCount,
    super.key,
  });

  /// Drives the Files-changed / Commits selection.
  final TabController controller;

  /// Count shown on the Files-changed tab.
  final int filesCount;

  /// Count shown on the Commits tab.
  final int commitsCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    return TabBar(
      controller: controller,
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      dividerColor: Colors.transparent,
      indicatorColor: t.textPrimary,
      labelColor: t.textPrimary,
      unselectedLabelColor: t.textTertiary,
      tabs: [
        Tab(
          height: 40,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(AppIcons.fileText, size: 14),
              const SizedBox(width: 6),
              Text(l10n.filesChanged),
              const SizedBox(width: 6),
              CountBadge(count: filesCount),
            ],
          ),
        ),
        Tab(
          height: 40,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(AppIcons.gitCommit, size: 14),
              const SizedBox(width: 6),
              Text(l10n.commits),
              const SizedBox(width: 6),
              CountBadge(count: commitsCount),
            ],
          ),
        ),
      ],
    );
  }
}

/// Sliver delegate that pins [ComposeTabBar] below the form while the diff
/// scrolls. Mirrors the PR detail page's tab-strip header.
class ComposeTabBarDelegate extends SliverPersistentHeaderDelegate {
  /// Creates a [ComposeTabBarDelegate].
  ComposeTabBarDelegate({
    required this.height,
    required this.background,
    required this.borderColor,
    required this.child,
  });

  /// Fixed height of the pinned strip.
  final double height;

  /// Fill behind the strip.
  final Color background;

  /// Color of the strip's bottom border.
  final Color borderColor;

  /// The tab strip itself.
  final Widget child;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Material(
      color: background,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: borderColor)),
        ),
        child: SizedBox(
          height: height,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: child,
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(ComposeTabBarDelegate oldDelegate) {
    return oldDelegate.height != height ||
        oldDelegate.background != background ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.child != child;
  }
}

/// A centered, muted one-line hint in place of the compose diff.
class ComposeCenteredHint extends StatelessWidget {
  /// Creates a [ComposeCenteredHint].
  const ComposeCenteredHint({required this.message, super.key});

  /// The hint text.
  final String message;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13.5, color: t.textTertiary),
        ),
      ),
    );
  }
}
