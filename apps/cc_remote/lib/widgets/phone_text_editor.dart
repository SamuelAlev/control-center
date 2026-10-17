import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';

Future<String?> showPhoneTextEditor(
  BuildContext context, {
  required String title,
  required String label,
  String initialText = '',
  bool multiline = false,
}) => showCcDialog<String>(
  context: context,
  builder: (_) => _TextEditor(
    title: title,
    label: label,
    initialText: initialText,
    multiline: multiline,
  ),
);

class _TextEditor extends StatefulWidget {
  const _TextEditor({
    required this.title,
    required this.label,
    required this.initialText,
    required this.multiline,
  });
  final String title;
  final String label;
  final String initialText;
  final bool multiline;
  @override
  State<_TextEditor> createState() => _TextEditorState();
}

class _TextEditorState extends State<_TextEditor> {
  late final _controller = TextEditingController(text: widget.initialText);
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return CcDialog(
      title: widget.title,
      content: CcTextField(
        controller: _controller,
        label: widget.label,
        autofocus: true,
        minLines: 1,
        maxLines: widget.multiline ? 8 : 1,
        onChanged: (_) => setState(() {}),
      ),
      actions: [
        CcButton(
          size: CcButtonSize.lg,
          variant: CcButtonVariant.secondary,
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        CcButton(
          size: CcButtonSize.lg,
          onPressed: _controller.text.trim().isEmpty
              ? null
              : () => Navigator.pop(context, _controller.text.trim()),
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
