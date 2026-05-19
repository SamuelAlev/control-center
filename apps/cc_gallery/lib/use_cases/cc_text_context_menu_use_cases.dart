import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

/// Use-cases for [CcTextContextMenu] — the drawn right-click menu cc_ui fields
/// fall back to when the host cannot present the operating system's own.
///
/// This entry is INTERACTIVE, the same way `CcMenu`'s is: the menu has no
/// standalone constructor to preview, because it renders from a live
/// `EditableTextState` (it reads the caret anchors and the actions currently
/// available off the field). So the way to look at it is to right-click a real
/// field, which is exactly how a user meets it.
///
/// The catalogue runner is one of the hosts that gets the fallback. Every
/// cc_ui field routes right-click through `ccTextContextMenuBuilder`, which
/// asks the host for its real menu first — on macOS that is a method channel
/// the main app's runner implements and this app does not, so the request
/// misses and the drawn menu is what appears here. On Windows and Linux it is
/// what appears everywhere.
///
/// [CcTextContextMenuLabels] carries the entry titles (`Cut` / `Copy` /
/// `Paste` / `Select all`, English by default). They are the FALLBACK menu's
/// vocabulary only — a host presenting the real OS menu supplies its own,
/// already localised.

const _path = '[Components]/Navigation & Overlays';

/// Right-click either field to raise the menu.
///
/// The single-line field starts with a selection's worth of text so `Cut` and
/// `Copy` are live; the text area shows that the same menu serves a multi-line
/// field. Which entries appear is decided by the field's own state, so a
/// read-only or empty field raises a shorter menu.
@widgetbook.UseCase(
  name: 'Right-click a field',
  type: CcTextContextMenu,
  path: _path,
)
Widget ccTextContextMenuUseCase(BuildContext context) {
  return const Center(child: _TextContextMenuDemo());
}

/// Owns the controllers so they are disposed when the use case is swapped out.
class _TextContextMenuDemo extends StatefulWidget {
  const _TextContextMenuDemo();

  @override
  State<_TextContextMenuDemo> createState() => _TextContextMenuDemoState();
}

class _TextContextMenuDemoState extends State<_TextContextMenuDemo> {
  late final TextEditingController _area = TextEditingController(
    text:
        'Right-click anywhere in this text to raise the menu.\n\n'
        'The same CcTextContextMenu serves single-line fields, text areas '
        'and the panel search field.',
  );

  @override
  void dispose() {
    _area.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 420,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const CcTextField(
            label: 'Workspace name',
            initialValue: 'Control Center',
          ),
          const SizedBox(height: 20),
          CcTextArea(label: 'Notes', controller: _area, minLines: 4),
        ],
      ),
    );
  }
}
