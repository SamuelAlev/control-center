import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// The scroll offset that brings [tab] fully into view inside the strip
/// scrolled by [position], or null when it already is (or cannot be measured).
///
/// VS Code's reveal rule: scroll by the least amount that shows the whole tab.
/// A tab cut off at the leading edge aligns to the leading edge; one cut off
/// at the trailing edge aligns to the trailing edge; a tab wider than the
/// viewport shows its start, where the label begins. Offsets come from the
/// viewport itself, so the rule holds in RTL without mirroring anything here.
///
/// [toEnd] is for the strip's last tab: when it has to scroll toward the
/// trailing edge anyway, it goes all the way so whatever follows the tabs in
/// the scroller (the `[+]` menu) comes into view with it.
double? editorTabRevealOffset(
  ScrollPosition position,
  RenderObject tab, {
  bool toEnd = false,
}) {
  final viewport = RenderAbstractViewport.maybeOf(tab);
  if (viewport == null || !tab.attached) {
    return null;
  }
  final leading = viewport.getOffsetToReveal(tab, 0).offset;
  final trailing = viewport.getOffsetToReveal(tab, 1).offset;
  final current = position.pixels;
  double target;
  if (current > leading) {
    target = leading;
  } else if (current < trailing) {
    // Narrower than the viewport: trailing < leading, align the trailing
    // edge. Wider: showing the start beats showing the end.
    target = math.min(trailing, leading);
    if (toEnd) {
      target = math.min(position.maxScrollExtent, leading);
    }
  } else {
    return null;
  }
  target = target.clamp(position.minScrollExtent, position.maxScrollExtent);
  return (target - current).abs() < 0.5 ? null : target;
}
