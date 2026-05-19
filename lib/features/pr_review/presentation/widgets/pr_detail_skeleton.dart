import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
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
///
/// Public because the same tone has to serve the per-section skeletons the PR
/// sidebar and description render once the page is showing seeded chrome — a
/// second, slightly-different grey would read as a different kind of state.
class PrSkeletonBar extends StatelessWidget {
  /// Creates a [PrSkeletonBar].
  const PrSkeletonBar({
    super.key,
    required this.width,
    this.height = 12,
    this.radius = AppRadii.xs,
  });

  /// Bar width in logical pixels.
  final double width;

  /// Bar height in logical pixels.
  final double height;

  /// Corner radius.
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
            Expanded(child: PrSkeletonBar(width: double.infinity, height: 20)),
            SizedBox(width: AppSpacing.xl),
            PrSkeletonBar(width: 84, height: 28),
            SizedBox(width: AppSpacing.sm),
            PrSkeletonBar(width: 84, height: 28),
          ],
        ),
        SizedBox(height: AppSpacing.md),
        // Meta strip (state capsule, author, branches).
        Row(
          children: [
            PrSkeletonBar(width: 64, height: 20, radius: AppRadii.pill),
            SizedBox(width: AppSpacing.md),
            PrSkeletonBar(width: 120),
            SizedBox(width: AppSpacing.md),
            PrSkeletonBar(width: 180),
          ],
        ),
        SizedBox(height: AppSpacing.xl),
        // Description.
        PrSkeletonBar(width: double.infinity),
        SizedBox(height: AppSpacing.sm),
        PrSkeletonBar(width: double.infinity),
        SizedBox(height: AppSpacing.sm),
        PrSkeletonBar(width: 280),
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
        PrSkeletonBar(width: 90),
        SizedBox(height: AppSpacing.md),
        PrSkeletonUserRow(),
        PrSkeletonUserRow(),
        SizedBox(height: AppSpacing.xl),
        PrSkeletonBar(width: 90),
        SizedBox(height: AppSpacing.md),
        PrSkeletonUserRow(),
        SizedBox(height: AppSpacing.xl),
        PrSkeletonBar(width: 90),
        SizedBox(height: AppSpacing.md),
        PrSkeletonUserRow(),
        PrSkeletonUserRow(),
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
                PrSkeletonBar(width: 28, height: 24),
                SizedBox(width: AppSpacing.sm),
                PrSkeletonBar(width: 160, height: 24),
                Spacer(),
                PrSkeletonBar(width: 90),
                SizedBox(width: AppSpacing.md),
                PrSkeletonBar(width: 28, height: 24),
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
            const PrSkeletonBar(width: 140, height: 16),
            const SizedBox(height: AppSpacing.lg),
            for (var i = 0; i < rows; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Row(
                  children: [
                    const PrSkeletonBar(width: 16, height: 16),
                    const SizedBox(width: AppSpacing.sm),
                    PrSkeletonBar(width: widths[i % widths.length]),
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
                  PrSkeletonBar(width: 16, height: 16, radius: AppRadii.xs),
                  SizedBox(width: AppSpacing.sm),
                  PrSkeletonBar(width: 220, height: 14),
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
                      child: PrSkeletonBar(width: widths[i % widths.length]),
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

/// An avatar-plus-name row placeholder, the shape every people rail uses.
class PrSkeletonUserRow extends StatelessWidget {
  /// Creates a [PrSkeletonUserRow].
  const PrSkeletonUserRow({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          PrSkeletonBar(width: 24, height: 24, radius: AppRadii.pill),
          SizedBox(width: AppSpacing.sm),
          PrSkeletonBar(width: 120, height: 12),
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
          PrSkeletonUserRow(),
          SizedBox(height: AppSpacing.xs),
          PrSkeletonBar(width: double.infinity),
          SizedBox(height: AppSpacing.sm),
          PrSkeletonBar(width: 240),
        ],
      ),
    );
  }
}

/// Description placeholder for a PR page rendering off the list-row seed.
///
/// The list query carries every field except `body`/`body_html`, so a seeded
/// page knows the title, author and branches but not one word of the
/// description. An empty body there means "not fetched", which is
/// indistinguishable from "this PR has no description" — and rendering the
/// latter's placeholder would state something false and then reflow a screenful
/// of markdown into its place.
class PrDescriptionSkeleton extends StatelessWidget {
  /// Creates a [PrDescriptionSkeleton].
  const PrDescriptionSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    // Bars carry no text, so without this the description is simply absent to a
    // screen reader — worse than the placeholder it replaced, which at least
    // said something. The rest of the subtree is decorative.
    return Semantics(
      label: AppLocalizations.of(context).loadingEllipsis,
      container: true,
      child: const ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            PrSkeletonBar(width: double.infinity),
            SizedBox(height: AppSpacing.sm),
            PrSkeletonBar(width: double.infinity),
            SizedBox(height: AppSpacing.sm),
            PrSkeletonBar(width: 280),
          ],
        ),
      ),
    );
  }
}

/// A section-sized placeholder for one Overview-sidebar rail.
///
/// Distinguishes "still loading" from "there are none". The rail used to render
/// "No reviewers assigned", "No checks have run yet" and "No files changed"
/// while those streams were still in flight — three confident statements about
/// a PR nobody had finished reading yet, each replaced moments later by the
/// opposite. Absence is a claim; make it only once it is known.
class PrSidebarSectionSkeleton extends StatelessWidget {
  /// Creates a [PrSidebarSectionSkeleton] with [rows] placeholder rows.
  const PrSidebarSectionSkeleton({
    super.key,
    this.rows = 2,
    this.people = true,
  });

  /// How many placeholder rows to show.
  final int rows;

  /// Whether the rows carry an avatar (people rails) or are plain bars.
  final bool people;

  @override
  Widget build(BuildContext context) {
    // Deterministic, irregular widths so the rows read as file names.
    const widths = <double>[168, 132, 196, 148];
    final body = people
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < rows; i++) const PrSkeletonUserRow(),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < rows; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: PrSkeletonBar(width: widths[i % widths.length]),
                ),
            ],
          );
    // The rail it replaces used to read out "No reviewers assigned". Bars say
    // nothing at all, so the section would go silent rather than merely become
    // uncertain; its own heading supplies the noun.
    return Semantics(
      label: AppLocalizations.of(context).loadingEllipsis,
      container: true,
      child: ExcludeSemantics(child: body),
    );
  }
}
