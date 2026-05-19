import 'dart:async';

import 'package:cc_ui/src/foundation/cc_motion.dart';
import 'package:flutter/widgets.dart';

/// Keeps the keyboard-highlighted row of a scrolling panel on screen.
///
/// Every cc_ui panel runs its list off an explicit highlight index rather than
/// focus traversal — focus cannot be in a search field and on a row at the same
/// time — which means nothing moves the viewport on its own. Without this the
/// highlight walks off into the scrolled-away part of the panel: the user
/// arrows past the fold, the list never moves, and `Enter` fires a row they
/// could not read.
///
/// Hold one per scrollable list, [resize] it to the rows actually rendered,
/// hang [keyAt] on each row and call [reveal] immediately after the highlight
/// moves. Pointer hover must NOT call [reveal] — scrolling the list under the
/// cursor would drag the next row out from under it.
class CcRowReveal {
  List<GlobalKey> _keys = const [];

  /// Sizes the key pool to [length] rows. Call it from `build` before laying
  /// the rows out; the keys are regenerated only when the row count changes,
  /// so a rebuild that keeps the same list keeps the same elements.
  void resize(int length) {
    if (_keys.length != length) {
      _keys = List<GlobalKey>.generate(length, (_) => GlobalKey());
    }
  }

  /// The key to hang on row [index] — via a [KeyedSubtree] when the row widget
  /// already carries a key of its own.
  GlobalKey keyAt(int index) => _keys[index];

  /// Scrolls row [index] into view after the current frame.
  ///
  /// [from] is the previously highlighted index and picks which edge the row
  /// is pinned to, so the list travels the minimum distance: stepping down
  /// pins the row to the bottom edge, stepping up to the top, and a row that
  /// is already on screen does not move the viewport at all. Wrapping around
  /// (last row → first) reads as a step *up* and scrolls back to the top
  /// instead of leaving the highlight off-screen. Pass a negative [from] — no
  /// previous highlight, e.g. a select opening on its already-chosen option —
  /// to centre the row instead.
  void reveal(int index, {int from = -1, Duration duration = CcMotion.fast}) {
    if (index < 0 || index >= _keys.length) {
      return;
    }
    final key = _keys[index];
    final policy = from < 0 || from == index
        ? ScrollPositionAlignmentPolicy.explicit
        : index > from
        ? ScrollPositionAlignmentPolicy.keepVisibleAtEnd
        : ScrollPositionAlignmentPolicy.keepVisibleAtStart;
    // The row of a panel that is opening this frame has no element yet, so the
    // scroll has to wait for one.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = key.currentContext;
      if (ctx == null || !ctx.mounted) {
        return;
      }
      unawaited(
        Scrollable.ensureVisible(
          ctx,
          alignment: policy == ScrollPositionAlignmentPolicy.explicit ? 0.5 : 0,
          alignmentPolicy: policy,
          duration: CcMotion.resolve(ctx, duration),
          curve: CcMotion.standard,
        ),
      );
    });
  }
}
