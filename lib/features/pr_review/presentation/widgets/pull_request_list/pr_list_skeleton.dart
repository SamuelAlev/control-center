import 'dart:math';

import 'package:control_center/core/theme/app_radii.dart';
import 'package:control_center/core/theme/app_spacing.dart';
import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// Loading placeholder for a pull-request group.
///
/// The product register calls for skeletons that mirror the real layout
/// rather than a spinner dropped in the middle of content: the page keeps its
/// shape, nothing jumps when data arrives, and the surface stays calm. This
/// mirrors `PrGroupCard` — one bordered, hairline-divided container of dense
/// rows — so the swap from loading to loaded never reflows. The placeholder
/// bars breathe in a slow pulse that reads as "instruments warming up".
/// Honours `prefers-reduced-motion` (via [MediaQueryData.disableAnimations]):
/// the bars stay visible, the pulse just stops.
class RepoSectionSkeleton extends StatelessWidget {
  /// Creates a [RepoSectionSkeleton] with [rows] placeholder rows.
  const RepoSectionSkeleton({super.key, this.rows = 3});

  /// Number of placeholder rows to render.
  final int rows;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem;
    final colors = context.theme.colors;
    final border = tokens?.borderSecondary ?? colors.border;
    return _Shimmer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tokens?.bgPrimary ?? colors.card,
          borderRadius: AppRadii.brLg,
          border: Border.all(color: border),
        ),
        child: ClipRRect(
          borderRadius: AppRadii.brLg,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < rows; i++) ...[
                if (i > 0) Divider(height: 1, thickness: 1, color: border),
                const _SkeletonRow(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A single dense skeleton row mirroring `PrListRow`: leading avatar, a title
/// and meta bar, and a trailing metric placeholder.
class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
      child: Row(
        children: [
          _Bar(width: 26, height: 26, radius: AppRadii.pill),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    _Bar(width: 15, height: 15),
                    SizedBox(width: AppSpacing.sm),
                    Expanded(child: _Bar(width: double.infinity, height: 13)),
                  ],
                ),
                SizedBox(height: 7),
                _Bar(width: 200, height: 10),
              ],
            ),
          ),
          SizedBox(width: AppSpacing.md),
          _Bar(width: 52, height: 12),
        ],
      ),
    );
  }
}

/// A single rounded placeholder bar. Its colour breathes between the shimmer
/// base and highlight, driven by the enclosing [_Shimmer] via [_ShimmerScope].
/// Only these bars depend on the animation, so the surrounding card chrome
/// (surface + border) stays static while the placeholders pulse.
class _Bar extends StatelessWidget {
  const _Bar({
    required this.width,
    required this.height,
    this.radius = AppRadii.xs,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final scope = _ShimmerScope.of(context);
    final wave = scope == null ? 0.5 : (sin(scope.t * 2 * pi) + 1) / 2;
    final color = scope == null
        ? null
        : Color.lerp(scope.base, scope.highlight, wave);
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color ?? const Color(0x33808080),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Inherited carrier for the current shimmer phase [t] and the resolved
/// [base]/[highlight] colours. Rebuilt every frame so descendant [_Bar]s
/// repaint, while non-dependent widgets (cards, gaps) are left untouched.
class _ShimmerScope extends InheritedWidget {
  const _ShimmerScope({
    required this.t,
    required this.base,
    required this.highlight,
    required super.child,
  });

  final double t;
  final Color base;
  final Color highlight;

  static _ShimmerScope? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_ShimmerScope>();

  @override
  bool updateShouldNotify(_ShimmerScope old) =>
      t != old.t || base != old.base || highlight != old.highlight;
}

/// Drives a calm, repeating pulse across its placeholder descendants. Honours
/// `prefers-reduced-motion` (`MediaQueryData.disableAnimations`): the bars
/// stay visible at a steady mid-tone, the pulse just stops.
class _Shimmer extends StatefulWidget {
  const _Shimmer({required this.child});

  final Widget child;

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  static const _period = Duration(milliseconds: 1400);
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _period,
  );

  bool _animating = false;

  void _syncMotion({required bool reduceMotion}) {
    if (reduceMotion) {
      if (_animating) {
        _controller
          ..stop()
          ..value = 0; // sin(0) → mid-tone
        _animating = false;
      }
      return;
    }
    if (!_animating) {
      _controller.repeat();
      _animating = true;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    _syncMotion(reduceMotion: reduceMotion);

    final tokens = context.designSystem;
    final colors = context.theme.colors;
    final base = tokens?.bgQuaternary ?? colors.muted;
    final highlight =
        Color.lerp(base, tokens?.bgPrimary ?? colors.background, 0.55) ?? base;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => _ShimmerScope(
        t: _controller.value,
        base: base,
        highlight: highlight,
        child: child!,
      ),
      child: widget.child,
    );
  }
}
