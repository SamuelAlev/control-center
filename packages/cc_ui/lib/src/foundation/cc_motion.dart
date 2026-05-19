import 'package:cc_ui/src/theme/cc_theme.dart';
import 'package:flutter/widgets.dart';

/// Motion tokens — the small set of durations and curves the design system uses
/// for hover washes, overlay transitions, and chrome animation.
///
/// Per DESIGN.md every animated element must have a reduced-motion path; call
/// [resolve] to collapse a duration to zero when the ambient [CcTheme] (or
/// `MediaQuery.disableAnimations`) requests it.
abstract final class CcMotion {
  const CcMotion._();

  /// No animation.
  static const Duration instant = Duration.zero;

  /// 120ms — hover/press color washes.
  static const Duration fast = Duration(milliseconds: 120);

  /// 180ms — dropdown/popover/tooltip open.
  static const Duration normal = Duration(milliseconds: 180);

  /// 240ms — sidebar collapse, drawer, larger chrome.
  static const Duration slow = Duration(milliseconds: 240);

  /// Standard easing for washes and small transitions.
  static const Curve standard = Curves.easeOut;

  /// Emphasized easing for larger movement.
  static const Curve emphasized = Curves.easeOutCubic;

  /// Whether motion should be suppressed for [context] — true if the nearest
  /// [CcTheme] sets `reducedMotion`, or the platform requests disabled
  /// animations.
  static bool reduced(BuildContext context) {
    final themeReduced = CcTheme.maybeOf(context)?.reducedMotion ?? false;
    final mediaReduced =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return themeReduced || mediaReduced;
  }

  /// Returns [duration], or [Duration.zero] when motion is reduced for
  /// [context].
  static Duration resolve(BuildContext context, Duration duration) =>
      reduced(context) ? Duration.zero : duration;
}
