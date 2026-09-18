import 'package:cc_ui/src/theme/cc_theme.dart';
import 'package:flutter/widgets.dart';

/// Motion tokens — three enter speeds, a faster exit for each, and one fade
/// kept under reduced motion.
///
/// Pattern: hover and small toggles use [fast]; dropdowns, tabs and short travel use [moderate];
/// dialogs and drawers use [slow]. Exits run on the matching `*Exit` token,
/// one tier quicker, so a close never drags. No bounce, no elastic — the
/// curves commit quickly and settle (DESIGN.md).
///
/// Reduced motion drops **travel** (translate, scale, size) and keeps a short
/// **opacity** fade so presence still reports. Call [resolve] / [resolveTravel]
/// for movement, [resolveFade] for opacity-only.
abstract final class CcMotion {
  const CcMotion._();

  /// No animation.
  static const Duration instant = Duration.zero;

  /// 80ms — hover washes, fades, focus rings, small toggles.
  static const Duration fast = Duration(milliseconds: 80);

  /// 160ms — dropdowns, tabs, switch thumb, short panel travel.
  static const Duration moderate = Duration(milliseconds: 160);

  /// Backward-compatible alias of [moderate].
  static const Duration normal = moderate;

  /// 240ms — dialogs, drawers, large chrome.
  static const Duration slow = Duration(milliseconds: 240);

  /// 60ms — [fast] exit.
  static const Duration fastExit = Duration(milliseconds: 60);

  /// 120ms — [moderate] exit.
  static const Duration moderateExit = Duration(milliseconds: 120);

  /// 160ms — [slow] exit.
  static const Duration slowExit = Duration(milliseconds: 160);

  /// Opacity fade kept when motion is reduced (position/scale drop out).
  static const Duration fade = Duration(milliseconds: 80);

  /// Standard easing for washes and small transitions
  /// (cubic-bezier(0.2, 0, 0.38, 0.9)): quick to commit, gentle to settle.
  static const Curve standard = Cubic(0.2, 0, 0.38, 0.9);

  /// Emphasized easing for larger movement — overlays entering, drawers
  /// (cubic-bezier(0, 0, 0.38, 0.9)).
  static const Curve emphasized = Cubic(0, 0, 0.38, 0.9);

  /// The exit token that pairs with [enter].
  static Duration exitFor(Duration enter) {
    if (enter <= fast) {
      return fastExit;
    }
    if (enter <= moderate) {
      return moderateExit;
    }
    if (enter <= slow) {
      return slowExit;
    }
    return Duration(milliseconds: enter.inMilliseconds * 2 ~/ 3);
  }

  /// Whether travel should be suppressed — true if the nearest [CcTheme] sets
  /// `reducedMotion`, or the platform requests disabled animations.
  static bool reduced(BuildContext context) {
    final themeReduced = CcTheme.maybeOf(context)?.reducedMotion ?? false;
    final mediaReduced =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return themeReduced || mediaReduced;
  }

  /// Travel (translate, scale, size): [duration], or [Duration.zero] when
  /// reduced. Color/opacity-only animations should use [resolveFade].
  static Duration resolve(BuildContext context, Duration duration) =>
      reduced(context) ? Duration.zero : duration;

  /// Alias of [resolve] for call sites that want the travel intent named.
  static Duration resolveTravel(BuildContext context, Duration duration) =>
      resolve(context, duration);

  /// Opacity (and color washes): [duration], or [fade] when reduced so
  /// presence still reports.
  static Duration resolveFade(BuildContext context, Duration duration) =>
      reduced(context) ? fade : duration;
}
