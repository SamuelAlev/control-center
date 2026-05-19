import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/markdown/markdown_editor.dart';
import 'package:control_center/shared/widgets/markdown/markdown_text_field.dart';
import 'package:control_center/shared/widgets/markdown/styled_markdown_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Editable markdown field that toggles between a rendered read view and the
/// shared GitHub-style Write/Preview [MarkdownEditor].
///
/// Read mode renders the markdown with the same [StyledMarkdownBody] look used
/// across PR descriptions and chat (so headings, code chips, and task lists
/// match), with a hover-revealed edit pencil. Edit mode shows the markdown
/// toolbar + a live Preview tab, and commits via [onSave] on Save (or
/// Cmd/Ctrl+Enter); Esc cancels (confirming first if there are unsaved edits).
///
/// Tickets are vendor-agnostic, so this intentionally omits the GitHub
/// `@`/`#` mention autocomplete the PR editor layers on — everything else
/// matches.
class MarkdownEditableField extends StatefulWidget {
  /// Creates an editable markdown field with initial [text], placeholder [hint], and [onSave] callback.
  const MarkdownEditableField({
    super.key,
    required this.text,
    required this.hint,
    required this.onSave,
  });

  /// Current markdown content shown by the field.
  final String text;

  /// Placeholder text shown when the field is empty.
  final String hint;

  /// Callback invoked when the edited markdown is committed.
  final ValueChanged<String> onSave;

  @override
  State<MarkdownEditableField> createState() => _MarkdownEditableFieldState();
}

class _MarkdownEditableFieldState extends State<MarkdownEditableField> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _editing = false;
  bool _hovered = false;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startEdit() {
    setState(() {
      _controller.text = widget.text;
      _controller.selection = TextSelection.collapsed(
        offset: _controller.text.length,
      );
      _editing = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  void _save() {
    if (_controller.text != widget.text) {
      widget.onSave(_controller.text);
    }
    if (mounted) {
      setState(() => _editing = false);
    }
  }

  Future<void> _cancel() async {
    if (_controller.text == widget.text) {
      setState(() => _editing = false);
      return;
    }
    final l10n = AppLocalizations.of(context);
    final discard = await showCcDialog<bool>(
      context: context,
      builder: (ctx) => CcDialog(
        title: l10n.discardChangesConfirm,
        content: const SizedBox.shrink(),
        actions: [
          CcButton(
            onPressed: () => Navigator.pop(ctx, false),
            variant: CcButtonVariant.ghost,
            child: Text(l10n.cancel),
          ),
          CcButton(
            onPressed: () => Navigator.pop(ctx, true),
            variant: CcButtonVariant.destructive,
            child: Text(l10n.discard),
          ),
        ],
      ),
    );
    if (discard == true && mounted) {
      setState(() => _editing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_editing) {
      return _buildEdit(context);
    }
    if (widget.text.trim().isEmpty) {
      return _buildEmptyAffordance(context);
    }
    return _buildRead(context);
  }

  Widget _buildEmptyAffordance(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Align(
      alignment: Alignment.centerLeft,
      child: CcTappable(
        onPressed: _startEdit,
        builder: (context, states) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(AppIcons.pencil, size: 13, color: t.textBrandPrimary),
              const SizedBox(width: 6),
              Text(
                widget.hint,
                style: TextStyle(fontSize: 14, color: t.textPlaceholder),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRead(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return MouseRegion(
      cursor: SystemMouseCursors.text,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 28),
            child: StyledMarkdownBody(data: widget.text),
          ),
          if (_hovered)
            Positioned(
              top: 0,
              right: 0,
              child: CcTooltip(
                message: AppLocalizations.of(context).editDescription,
                child: CcTappable(
                  onPressed: _startEdit,
                  builder: (context, states) => Container(
                    decoration: BoxDecoration(
                      color: t.bgPrimary,
                      borderRadius: BorderRadius.circular(2),
                      border: Border.all(color: t.borderSecondary),
                    ),
                    padding: const EdgeInsets.all(5),
                    child: Icon(
                      AppIcons.pencil,
                      size: 14,
                      color: t.fgQuaternary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEdit(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter, meta: true): _save,
        const SingleActivator(LogicalKeyboardKey.enter, control: true): _save,
        const SingleActivator(LogicalKeyboardKey.escape): _cancel,
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          MarkdownEditor(
            controller: _controller,
            focusNode: _focusNode,
            fieldBuilder: (context) => MarkdownTextField(
              controller: _controller,
              focusNode: _focusNode,
              hintText: widget.hint,
              minLines: 6,
            ),
            previewBuilder: (context) =>
                StyledMarkdownBody(data: _controller.text),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CcButton(
                onPressed: _cancel,
                variant: CcButtonVariant.secondary,
                size: CcButtonSize.sm,
                child: Text(l10n.cancel),
              ),
              const SizedBox(width: 8),
              CcButton(
                onPressed: _save,
                size: CcButtonSize.sm,
                child: Text(l10n.save),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
