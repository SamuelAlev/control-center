import 'package:cc_ui/src/foundation/cc_native_text_menu.dart';
import 'package:flutter/widgets.dart';

/// The pointer-gesture wiring every cc_ui text field uses.
///
/// Identical to [TextSelectionGestureDetectorBuilder] — tap to place the
/// caret, click-drag to select, double-click for a word — except for the
/// right-click, which it hands to the operating system.
///
/// The base class ends a secondary tap with `editableText.showToolbar()`, i.e.
/// a menu Flutter draws. A drawn menu is never the real one: wrong metrics,
/// wrong highlight, wrong appearance under Increase Contrast, no OS
/// localisation, no Services or dictation entries — and, since cc_ui builds on
/// `flutter/widgets.dart` only, nowhere to inherit a text style from either
/// (the root overlay's ambient `DefaultTextStyle` is `WidgetsApp`'s 48px
/// double-yellow-underline error fallback). So on a host that can present its
/// own, [CcNativeTextMenu] does, and the drawn menu is only the fallback for
/// hosts that cannot.
class CcTextSelectionGestureDetectorBuilder
    extends TextSelectionGestureDetectorBuilder {
  /// Creates a [CcTextSelectionGestureDetectorBuilder].
  CcTextSelectionGestureDetectorBuilder({required super.delegate});

  @override
  void onSecondaryTap() {
    if (!delegate.selectionEnabled || !CcNativeTextMenu.isAvailable) {
      // Web included: there the OS menu is the browser's own, which the engine
      // shows precisely BECAUSE `showToolbar()` declines while the browser
      // context menu is enabled (see CcBrowserTextMenu).
      super.onSecondaryTap();
      return;
    }
    // Right-clicking off the current selection selects the word under the
    // pointer, the way every macOS text field does. Mirrors the base class's
    // Apple branch, which cannot be reused (its state is private).
    if (!_tapWasOnSelection || !renderEditable.hasFocus) {
      renderEditable.selectWord(cause: SelectionChangedCause.tap);
    }
    unawaitedShow();
  }

  /// Pops the host menu and applies whatever the user chose.
  ///
  /// Named rather than inlined so the future is deliberately un-awaited:
  /// `onSecondaryTap` is a gesture callback, and the menu runs its own tracking
  /// loop for as long as the user leaves it open.
  @protected
  void unawaitedShow() {
    final anchor = renderEditable.lastSecondaryTapDownPosition;
    if (anchor == null) {
      return;
    }
    final state = editableText;
    final actions = ccTextMenuActionsFor(state);
    if (actions.isEmpty) {
      return;
    }
    CcNativeTextMenu.show(position: anchor, actions: actions).then((result) {
      if (!result.shown) {
        // The host turned out to have no bridge after all; draw our own so the
        // right-click is never simply dead.
        state.showToolbar();
        return;
      }
      final action = result.action;
      if (action != null) {
        performCcTextMenuAction(state, action);
      }
    });
  }

  /// Whether the secondary tap landed inside the existing selection — the
  /// signal macOS uses to decide between keeping the selection and selecting
  /// the word under the pointer.
  bool get _tapWasOnSelection {
    final position = renderEditable.lastSecondaryTapDownPosition;
    final selection = renderEditable.selection;
    if (position == null || selection == null) {
      return false;
    }
    final offset = renderEditable.getPositionForPoint(position).offset;
    return selection.start <= offset && selection.end >= offset;
  }
}
