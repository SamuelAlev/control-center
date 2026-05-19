import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';

/// Per-tab loading placeholders for the PR detail workbench.
///
/// The product register calls for skeletons that mirror the real layout rather
/// than a spinner dropped in the middle of content: each tab keeps its shape
/// and nothing jumps when data arrives. While the PR itself is loading, the
/// detail screen renders the real tab chrome with these as the tab bodies
/// ([PrOverviewSkeleton] for Overview, [PrDiffTabSkeleton] for Diff,
/// [PrPanelSkeleton] for the rest). These are intentionally static (a steady
/// muted tone, no pulse) so they're reduced-motion-safe by default and carry
/// no animation cost while a large diff is still being cloned.

/// A single rounded placeholder bar at the muted skeleton tone.
class _Bar extends StatelessWidget {
  const _Bar({
    required this.width,
    this.height = 12,
    this.radius = AppRadii.xs,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final color = tokens.bgQuaternary;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Overview-tab skeleton: the title + actions row, the meta strip, description
/// bars and timeline entries beside the sidebar rail (wide layouts only),
/// mirroring `PrOverviewTab`'s two-pane shape.
class PrOverviewSkeleton extends StatelessWidget {
  /// Creates a [PrOverviewSkeleton].
  const PrOverviewSkeleton({super.key});

  /// Mirrors `PrOverviewTab`'s sidebar width / stacking breakpoint.
  static const double _sidebarWidth = 300;
  static const double _wideBreakpoint = 880;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();

    const main = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Title + actions.
        Row(
          children: [
            Expanded(child: _Bar(width: double.infinity, height: 20)),
            SizedBox(width: AppSpacing.xl),
            _Bar(width: 84, height: 28),
            SizedBox(width: AppSpacing.sm),
            _Bar(width: 84, height: 28),
          ],
        ),
        SizedBox(height: AppSpacing.md),
        // Meta strip (state capsule, author, branches).
        Row(
          children: [
            _Bar(width: 64, height: 20, radius: AppRadii.pill),
            SizedBox(width: AppSpacing.md),
            _Bar(width: 120),
            SizedBox(width: AppSpacing.md),
            _Bar(width: 180),
          ],
        ),
        SizedBox(height: AppSpacing.xl),
        // Description.
        _Bar(width: double.infinity),
        SizedBox(height: AppSpacing.sm),
        _Bar(width: double.infinity),
        SizedBox(height: AppSpacing.sm),
        _Bar(width: 280),
        SizedBox(height: AppSpacing.xxl),
        // Timeline.
        _SkeletonTimelineEntry(),
        _SkeletonTimelineEntry(),
        _SkeletonTimelineEntry(),
      ],
    );

    const rail = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _Bar(width: 90),
        SizedBox(height: AppSpacing.md),
        _SkeletonUserRow(),
        _SkeletonUserRow(),
        SizedBox(height: AppSpacing.xl),
        _Bar(width: 90),
        SizedBox(height: AppSpacing.md),
        _SkeletonUserRow(),
        SizedBox(height: AppSpacing.xl),
        _Bar(width: 90),
        SizedBox(height: AppSpacing.md),
        _SkeletonUserRow(),
        _SkeletonUserRow(),
      ],
    );

    return ColoredBox(
      color: t.bgPrimary,
      child: LayoutBuilder(
        builder: (context, constraints) {
          const scrollableMain = SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: main,
          );
          if (constraints.maxWidth < _wideBreakpoint) {
            return scrollableMain;
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Expanded(child: scrollableMain),
              ColoredBox(
                color: t.bgSecondary,
                child: const SizedBox(
                  width: _sidebarWidth,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 24),
                    child: rail,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Diff-tab skeleton: the toolbar row (tree toggle, commit range, stats,
/// settings) over the diff-area placeholder, mirroring `PrDiffTab`.
class PrDiffTabSkeleton extends StatelessWidget {
  /// Creates a [PrDiffTabSkeleton].
  const PrDiffTabSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return ColoredBox(
      color: t.bgPrimary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                _Bar(width: 28, height: 24),
                SizedBox(width: AppSpacing.sm),
                _Bar(width: 160, height: 24),
                Spacer(),
                _Bar(width: 90),
                SizedBox(width: AppSpacing.md),
                _Bar(width: 28, height: 24),
              ],
            ),
          ),
          CcDivider(color: t.borderSecondary),
          const Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: PrDiffSkeleton(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Generic panel skeleton for the remaining PR tabs (source control, chat,
/// actions, review): a heading bar over icon + text list rows.
class PrPanelSkeleton extends StatelessWidget {
  /// Creates a [PrPanelSkeleton] with [rows] list-row placeholders.
  const PrPanelSkeleton({super.key, this.rows = 6});

  /// Number of placeholder list rows to render.
  final int rows;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    // Deterministic, irregular widths so the rows read as content, not a grid.
    const widths = <double>[220, 320, 180, 260, 300, 200];
    return ColoredBox(
      color: t.bgPrimary,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Bar(width: 140, height: 16),
            const SizedBox(height: AppSpacing.lg),
            for (var i = 0; i < rows; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Row(
                  children: [
                    const _Bar(width: 16, height: 16),
                    const SizedBox(width: AppSpacing.sm),
                    _Bar(width: widths[i % widths.length]),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Diff-area-only skeleton: a file header card followed by line-row
/// placeholders. Used while the local clone / diff is still loading but the
/// PR header is already on screen.
class PrDiffSkeleton extends StatelessWidget {
  /// Creates a [PrDiffSkeleton] with [rows] line placeholders.
  const PrDiffSkeleton({super.key, this.rows = 8});

  /// Number of placeholder diff lines to render.
  final int rows;

  @override
  Widget build(BuildContext context) {
    final border =
        (context.designSystem ?? DesignSystemTokens.light()).borderSecondary;
    // Deterministic, irregular widths so the rows read as code, not a table.
    const widths = <double>[320, 240, 380, 180, 300, 220, 360, 200, 280, 160];
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: border),
        borderRadius: AppRadii.brLg,
      ),
      child: ClipRRect(
        borderRadius: AppRadii.brLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // File header.
            const Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              child: Row(
                children: [
                  _Bar(width: 16, height: 16, radius: AppRadii.xs),
                  SizedBox(width: AppSpacing.sm),
                  _Bar(width: 220, height: 14),
                ],
              ),
            ),
            CcDivider(color: border),
            // Code lines.
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < rows; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: 5,
                      ),
                      child: _Bar(width: widths[i % widths.length]),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonUserRow extends StatelessWidget {
  const _SkeletonUserRow();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          _Bar(width: 24, height: 24, radius: AppRadii.pill),
          SizedBox(width: AppSpacing.sm),
          _Bar(width: 120, height: 12),
        ],
      ),
    );
  }
}

/// A timeline entry placeholder: an author row over two body bars.
class _SkeletonTimelineEntry extends StatelessWidget {
  const _SkeletonTimelineEntry();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _SkeletonUserRow(),
          SizedBox(height: AppSpacing.xs),
          _Bar(width: double.infinity),
          SizedBox(height: AppSpacing.sm),
          _Bar(width: 240),
        ],
      ),
    );
  }
}
