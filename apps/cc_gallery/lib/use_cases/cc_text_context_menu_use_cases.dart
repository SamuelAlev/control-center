import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

/// Interactive use-cases for [CcTextContextMenu] (drawn OS-menu fallback).
///
/// Menu needs a live `EditableTextState`; right-click a field to preview.
/// Gallery has no macOS method-channel menu, so the drawn fallback appears.
/// [CcTextContextMenuLabels] titles are fallback-only; a real OS menu brings
/// its own localised vocabulary.

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
