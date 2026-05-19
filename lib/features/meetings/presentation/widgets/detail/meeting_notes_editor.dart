import 'package:control_center/shared/widgets/markdown/markdown_editor.dart';
import 'package:control_center/shared/widgets/markdown/markdown_list_continuation.dart';
import 'package:control_center/shared/widgets/markdown/markdown_text_field.dart';
import 'package:control_center/shared/widgets/markdown/styled_markdown_body.dart';
import 'package:flutter/material.dart';

/// The meeting notes editor (#12): the shared GitHub-style Write/Preview
/// markdown surface (formatting toolbar + live preview + Cmd/Ctrl+B/I/K) with
/// automatic list-continuation, used for both the live record-screen notes pane
/// and the detail screen's "Your notes".
///
/// Persistence stays with the host: edits — typed, toolbar-applied, or
/// list-continued — are reported through [onChanged] via a controller listener
/// (so toolbar edits persist too, unlike a bare `TextField.onChanged`).
class MeetingNotesEditor extends StatefulWidget {
  /// Creates a [MeetingNotesEditor].
  const MeetingNotesEditor({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.hintText,
    this.minLines = 8,
  });

  /// The notes text controller (owned by the host).
  final TextEditingController controller;

  /// Called with the full text whenever the notes change (host debounces/saves).
  final ValueChanged<String> onChanged;

  /// Placeholder shown when the notes are empty.
  final String hintText;

  /// Minimum visible lines of the editor field.
  final int minLines;

  @override
  State<MeetingNotesEditor> createState() => _MeetingNotesEditorState();
}

class _MeetingNotesEditorState extends State<MeetingNotesEditor> {
  final FocusNode _focus = FocusNode();
  late final VoidCallback _detachContinuation;
  late String _lastText;

  @override
  void initState() {
    super.initState();
    _lastText = widget.controller.text;
    _detachContinuation = attachListContinuation(widget.controller);
    widget.controller.addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    final text = widget.controller.text;
    if (text != _lastText) {
      _lastText = text;
      widget.onChanged(text);
      // Refresh the live preview when it is showing.
      setState(() {});
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _detachContinuation();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MarkdownEditor(
      controller: widget.controller,
      focusNode: _focus,
      fieldBuilder: (_) => MarkdownTextField(
        controller: widget.controller,
        focusNode: _focus,
        hintText: widget.hintText,
        minLines: widget.minLines,
      ),
      previewBuilder: (_) => StyledMarkdownBody(data: widget.controller.text),
    );
  }
}
