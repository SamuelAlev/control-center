import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Strips selection-overlay artifact lines from copied text: lines consisting
/// solely of spaces/non-breaking spaces (the invisible selectable overlays
/// some widgets place over non-text content).
String filterOverlayLines(String text) {
  return text
      .split('\n')
      .where((line) => !RegExp(r'^[  ]+$').hasMatch(line))
      .join('\n');
}

/// Schedules a post-frame clipboard rewrite through [filterOverlayLines] —
/// call after a copy action has run so artifacts never reach the paste.
void scheduleClipboardFilter() {
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text != null) {
      final filtered = filterOverlayLines(text);
      if (filtered != text) {
        await Clipboard.setData(ClipboardData(text: filtered));
      }
    }
  });
}

/// Detects Cmd/Ctrl+C inside its subtree and runs the clipboard filter after
/// the default copy action.
class CcSelectionCopyFilter extends StatelessWidget {
  /// Creates a [CcSelectionCopyFilter] around [child].
  const CcSelectionCopyFilter({required this.child, super.key});

  /// The selectable subtree.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.keyC &&
            (HardwareKeyboard.instance.isMetaPressed ||
                HardwareKeyboard.instance.isControlPressed)) {
          scheduleClipboardFilter();
        }
        return KeyEventResult.ignored;
      },
      child: child,
    );
  }
}
