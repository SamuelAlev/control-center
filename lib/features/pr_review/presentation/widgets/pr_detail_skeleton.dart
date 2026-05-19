import 'package:control_center/core/theme/app_radii.dart';
import 'package:control_center/core/theme/app_spacing.dart';
import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// Loading placeholders for the PR detail screen.
///
/// The product register calls for skeletons that mirror the real layout rather
/// than a spinner dropped in the middle of content: the page keeps its shape
/// and nothing jumps when data arrives. These are intentionally static (a
/// steady muted tone, no pulse) so they're reduced-motion-safe by default and
/// carry no animation cost while a large diff is still being cloned.

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
    final tokens = context.designSystem;
    final color = tokens?.bgQuaternary ?? context.theme.colors.muted;
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

/// Full-page skeleton mirroring the PR header (body + rail), the tab strip,
/// and the first diff rows, so the swap from loading to loaded doesn't reflow.
class PrDetailSkeleton extends StatelessWidget {
  /// Creates a [PrDetailSkeleton].
  const PrDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final border =
        context.designSystem?.borderSecondary ?? context.theme.colors.border;
    final isWide = MediaQuery.sizeOf(context).width >= 880;

    const bodyColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _Bar(width: 220, height: 18),
        SizedBox(height: AppSpacing.lg),
        _Bar(width: double.infinity),
        SizedBox(height: AppSpacing.sm),
        _Bar(width: double.infinity),
        SizedBox(height: AppSpacing.sm),
        _Bar(width: 280),
      ],
    );

    const rail = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _Bar(width: 90, height: 12),
        SizedBox(height: AppSpacing.md),
        _SkeletonUserRow(),
        SizedBox(height: AppSpacing.sm),
        _SkeletonUserRow(),
        SizedBox(height: AppSpacing.xl),
        _Bar(width: 90, height: 12),
        SizedBox(height: AppSpacing.md),
        _SkeletonUserRow(),
      ],
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isWide)
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: bodyColumn),
                SizedBox(width: AppSpacing.xxl),
                SizedBox(width: 240, child: rail),
              ],
            )
          else
            bodyColumn,
          const SizedBox(height: AppSpacing.xl),
          // Faux tab strip.
          const Row(
            children: [
              _Bar(width: 90, height: 14),
              SizedBox(width: AppSpacing.xl),
              _Bar(width: 70, height: 14),
              SizedBox(width: AppSpacing.xl),
              _Bar(width: 70, height: 14),
              SizedBox(width: AppSpacing.xl),
              _Bar(width: 80, height: 14),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Divider(height: 1, thickness: 1, color: border),
          const SizedBox(height: AppSpacing.lg),
          const PrDiffSkeleton(),
        ],
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
        context.designSystem?.borderSecondary ?? context.theme.colors.border;
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
            Divider(height: 1, thickness: 1, color: border),
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
