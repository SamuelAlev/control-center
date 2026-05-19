import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// A modal dialog with a single text field — used to rename a meeting and to
/// add or edit a decision. Manages its own controller, disables Save while the
/// field is blank, calls [onSubmit] with the trimmed value, and pops itself.
class MeetingTextFieldDialog extends StatefulWidget {
  /// Creates a [MeetingTextFieldDialog].
  const MeetingTextFieldDialog({
    super.key,
    required this.title,
    required this.label,
    required this.hint,
    required this.submitLabel,
    required this.onSubmit,
    this.initialValue = '',
    this.multiline = false,
  });

  /// The dialog heading.
  final String title;

  /// The field label.
  final String label;

  /// The field placeholder.
  final String hint;

  /// The confirm-button label.
  final String submitLabel;

  /// Called with the trimmed value when the user confirms.
  final void Function(String value) onSubmit;

  /// The value the field starts with (empty when adding).
  final String initialValue;

  /// Whether the field is multi-line (decisions) or single-line (title).
  final bool multiline;

  @override
  State<MeetingTextFieldDialog> createState() => _MeetingTextFieldDialogState();
}

class _MeetingTextFieldDialogState extends State<MeetingTextFieldDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue)
      ..addListener(_onChanged);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onChanged)
      ..dispose();
    super.dispose();
  }

  void _onChanged() => setState(() {});

  void _submit() {
    final value = _controller.text.trim();
    if (value.isEmpty) {
      return;
    }
    widget.onSubmit(value);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final canSubmit = _controller.text.trim().isNotEmpty;
    return CcDialog(
      title: widget.title,
      maxWidth: 460,
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.label),
            const SizedBox(height: 6),
            if (widget.multiline)
              CcTextArea(
                controller: _controller,
                hintText: widget.hint,
                autofocus: true,
                minLines: 3,
              )
            else
              CcTextField(
                controller: _controller,
                hintText: widget.hint,
                autofocus: true,
                onSubmitted: (_) => _submit(),
              ),
          ],
        ),
      ),
      actions: [
        CcButton(
          variant: CcButtonVariant.secondary,
          size: CcButtonSize.sm,
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        CcButton(
          size: CcButtonSize.sm,
          onPressed: canSubmit ? _submit : null,
          child: Text(widget.submitLabel),
        ),
      ],
    );
  }
}

/// A modal dialog for adding or editing a meeting action item: a multi-line
/// content field plus an optional single-line owner. Calls [onSubmit] with the
/// trimmed content and the trimmed owner (null when blank), and pops itself.
class MeetingActionItemDialog extends StatefulWidget {
  /// Creates a [MeetingActionItemDialog].
  const MeetingActionItemDialog({
    super.key,
    required this.title,
    required this.submitLabel,
    required this.onSubmit,
    this.initialContent = '',
    this.initialOwner,
  });

  /// The dialog heading.
  final String title;

  /// The confirm-button label.
  final String submitLabel;

  /// Called with the trimmed content + owner (null when blank) on confirm.
  final void Function(String content, String? owner) onSubmit;

  /// The content the field starts with (empty when adding).
  final String initialContent;

  /// The owner the field starts with, if any.
  final String? initialOwner;

  @override
  State<MeetingActionItemDialog> createState() =>
      _MeetingActionItemDialogState();
}

class _MeetingActionItemDialogState extends State<MeetingActionItemDialog> {
  late final TextEditingController _content;
  late final TextEditingController _owner;

  @override
  void initState() {
    super.initState();
    _content = TextEditingController(text: widget.initialContent)
      ..addListener(_onChanged);
    _owner = TextEditingController(text: widget.initialOwner ?? '');
  }

  @override
  void dispose() {
    _content
      ..removeListener(_onChanged)
      ..dispose();
    _owner.dispose();
    super.dispose();
  }

  void _onChanged() => setState(() {});

  void _submit() {
    final content = _content.text.trim();
    if (content.isEmpty) {
      return;
    }
    final owner = _owner.text.trim();
    widget.onSubmit(content, owner.isEmpty ? null : owner);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final canSubmit = _content.text.trim().isNotEmpty;
    return CcDialog(
      title: widget.title,
      maxWidth: 460,
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.meetingActionItemContentLabel),
            const SizedBox(height: 6),
            CcTextArea(
              controller: _content,
              hintText: l10n.meetingActionItemContentHint,
              autofocus: true,
              minLines: 2,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(l10n.meetingActionItemOwnerLabel),
            const SizedBox(height: 6),
            CcTextField(
              controller: _owner,
              hintText: l10n.meetingActionItemOwnerHint,
              onSubmitted: (_) => _submit(),
            ),
          ],
        ),
      ),
      actions: [
        CcButton(
          variant: CcButtonVariant.secondary,
          size: CcButtonSize.sm,
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        CcButton(
          size: CcButtonSize.sm,
          onPressed: canSubmit ? _submit : null,
          child: Text(widget.submitLabel),
        ),
      ],
    );
  }
}
