import 'dart:math';

import 'package:control_center/core/theme/app_radii.dart';
import 'package:control_center/core/theme/app_spacing.dart';
import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/features/newsfeed/providers/newsfeed_providers.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// Loading placeholder for the newsfeed.
///
/// The product register calls for skeletons that mirror the real layout rather
/// than a spinner dropped in the middle of content: the page keeps its shape
/// and nothing jumps when articles arrive. Mirrors the active
/// [NewsfeedLayout] — digest rows or magazine cards — so the swap from loading
/// to loaded never reflows. The bars breathe in a slow pulse that honours
/// `prefers-reduced-motion` ([MediaQueryData.disableAnimations]): the bars stay
/// visible, the pulse just stops.
class NewsfeedSkeleton extends StatelessWidget {
  /// Creates a [NewsfeedSkeleton] for the given [layout].
  const NewsfeedSkeleton({super.key, required this.layout});

  /// Which layout to mirror.
  final NewsfeedLayout layout;

  @override
  Widget build(BuildContext context) {
    return _Shimmer(
      child: layout == NewsfeedLayout.grid
          ? const _GridSkeleton()
          : const _ListSkeleton(),
    );
  }
}

class _ListSkeleton extends StatelessWidget {
  const _ListSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xs,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      itemCount: 9,
      itemBuilder: (context, _) => const _RowSkeleton(),
    );
  }
}

class _RowSkeleton extends StatelessWidget {
  const _RowSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm + 2,
      ),
      child: Row(
        children: [
          _Bar(width: 56, height: 40, radius: AppRadii.sm),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _Bar(width: double.infinity, height: 13),
                SizedBox(height: 8),
                _Bar(width: 160, height: 10),
              ],
            ),
          ),
          SizedBox(width: AppSpacing.md),
          _Bar(width: 16, height: 16, radius: AppRadii.sm),
        ],
      ),
    );
  }
}

class _GridSkeleton extends StatelessWidget {
  const _GridSkeleton();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.xs,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 340,
        mainAxisSpacing: AppSpacing.lg,
        crossAxisSpacing: AppSpacing.lg,
        childAspectRatio: 0.9,
      ),
      itemCount: 9,
      itemBuilder: (context, _) => const _CardSkeleton(),
    );
  }
}

class _CardSkeleton extends StatelessWidget {
  const _CardSkeleton();

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem;
    final colors = FTheme.of(context).colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens?.bgPrimary ?? colors.card,
        borderRadius: AppRadii.brLg,
        border: Border.all(color: tokens?.borderSecondary ?? colors.border),
      ),
      child: const ClipRRect(
        borderRadius: AppRadii.brLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: _Bar(width: double.infinity, height: double.infinity),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md,
                11,
                AppSpacing.md,
                AppSpacing.sm + 2,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Bar(width: double.infinity, height: 13),
                  SizedBox(height: 8),
                  _Bar(width: 140, height: 13),
                  SizedBox(height: 14),
                  _Bar(width: 90, height: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single rounded placeholder bar whose colour breathes between the shimmer
/// base and highlight, driven by the enclosing [_Shimmer] via [_ShimmerScope].
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
    final tokens = context.designSystem;
    final scope = _ShimmerScope.of(context);
    final wave = scope == null ? 0.5 : (sin(scope.t * 2 * pi) + 1) / 2;
    final color = scope == null
        ? null
        : Color.lerp(scope.base, scope.highlight, wave);
    return Container(
      width: width.isFinite ? width : null,
      height: height.isFinite ? height : null,
      decoration: BoxDecoration(
        color: color ?? tokens?.bgQuaternary ?? const Color(0x33F2F0E9),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Inherited carrier for the current shimmer phase [t] and resolved colours.
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
/// `prefers-reduced-motion`: the bars stay visible at a steady mid-tone, the
/// pulse just stops.
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
          ..value = 0;
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
    final colors = FTheme.of(context).colors;
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
