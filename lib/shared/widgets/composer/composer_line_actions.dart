import 'package:flutter/foundation.dart' show ValueGetter, kIsWeb;
import 'package:flutter/widgets.dart';

/// Overrides for the field's "to line break" caret intents (⌘←/⌘→ on macOS,
/// Home/End elsewhere, and their Shift selection variants) so they stop at
/// the start or end of the LOGICAL line — the text between two typed
/// newlines — instead of the visual line a soft wrap produces.
///
/// The composer already treats a wrapped sentence as one line: ↑ recalls
/// history anywhere before the first typed newline (`ComposerHistory.up`).
/// The framework's default jumps to the wrap point, so ⌘← on the second row
/// of a wrapped sentence landed mid-sentence, as if a newline were there.
///
/// Placed above the field: EditableText registers these intents as
/// overridable, so an ancestor `Actions` replaces them, for both the
/// shortcut path and the macOS selector path (`moveToLeftEndOfLine:`).
Map<Type, Action<Intent>> composerLogicalLineActions(
  ValueGetter<TextEditingController> controller,
) => {
  ExtendSelectionToLineBreakIntent:
      _LogicalLineAction<ExtendSelectionToLineBreakIntent>(controller),
  ExpandSelectionToLineBreakIntent:
      _LogicalLineAction<ExpandSelectionToLineBreakIntent>(
        controller,
        isExpand: true,
      ),
};

/// Start of the logical line holding [offset]: just past the previous typed
/// newline, or the start of the text.
int logicalLineStart(String text, int offset) {
  final at = offset.clamp(0, text.length);
  if (at == 0) {
    return 0;
  }
  return text.lastIndexOf('\n', at - 1) + 1;
}

/// End of the logical line holding [offset]: the next typed newline, or the
/// end of the text.
int logicalLineEnd(String text, int offset) {
  final at = offset.clamp(0, text.length);
  final newline = text.indexOf('\n', at);
  return newline == -1 ? text.length : newline;
}

/// Mirrors the framework's line-break selection update (collapse, extend,
/// expand, collapse-at-reversal) with logical-line targets, then applies the
/// result through [UpdateSelectionIntent] so the field still reveals the
/// caret and reports a keyboard selection change.
class _LogicalLineAction<T extends DirectionalCaretMovementIntent>
    extends ContextAction<T> {
  _LogicalLineAction(this.controller, {this.isExpand = false});

  final ValueGetter<TextEditingController> controller;
  final bool isExpand;

  // The framework disables caret moves on the web while an IME composes.
  @override
  bool get isActionEnabled => !(kIsWeb && controller().value.composing.isValid);

  @override
  Object? invoke(T intent, [BuildContext? context]) {
    final value = controller().value;
    final selection = value.selection;
    if (!selection.isValid || context == null) {
      return null;
    }
    final text = value.text;
    // Expanding always grows the selection: when the far end is the base,
    // the move starts from there.
    final fromBase =
        isExpand &&
        (intent.forward
            ? selection.baseOffset > selection.extentOffset
            : selection.baseOffset < selection.extentOffset);
    final from = fromBase ? selection.baseOffset : selection.extentOffset;
    final target = TextPosition(
      offset: intent.forward
          ? logicalLineEnd(text, from)
          : logicalLineStart(text, from),
    );
    final moved =
        intent.collapseSelection ||
            (!isExpand && target.offset == selection.baseOffset)
        ? TextSelection.fromPosition(target)
        : isExpand
        ? selection.expandTo(target, selection.isCollapsed)
        : selection.extendTo(target);
    final reversed =
        (selection.baseOffset - selection.extentOffset) *
            (selection.baseOffset - moved.extentOffset) <
        0;
    final next = intent.collapseAtReversal && reversed
        ? TextSelection.fromPosition(selection.base)
        : moved;
    return Actions.invoke(
      context,
      UpdateSelectionIntent(value, next, SelectionChangedCause.keyboard),
    );
  }
}
