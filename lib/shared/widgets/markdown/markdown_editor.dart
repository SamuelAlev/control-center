import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/markdown/markdown_syntax_actions.dart';
import 'package:control_center/shared/widgets/markdown/markdown_toolbar.dart';
import 'package:control_center/shared/widgets/segmented_toggle.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The shared GitHub-style Write/Preview markdown editing surface: a
/// Write/Preview toggle, the [MarkdownToolbar], the editor field, and a live
/// preview — plus the Cmd/Ctrl + B/I/K formatting shortcuts. Editing operates
/// on raw markdown; Preview reuses the same renderer as the read view, so there
/// is no GFM round-trip loss.
///
/// This widget owns only the toggle state and the shared chrome. The host
/// supplies the write-mode field via [fieldBuilder] (e.g. a plain
/// `MarkdownTextField`, or pr_review's `MentionAutocompleteField`) and the
/// preview body via [previewBuilder]. Save/Cancel buttons, read/edit toggling,
/// template pickers, and any domain-specific persistence stay in the host.
class MarkdownEditor extends StatefulWidget {
  /// Creates a [MarkdownEditor].
  const MarkdownEditor({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.fieldBuilder,
    required this.previewBuilder,
  });

  /// The editor's text controller (shared with [fieldBuilder] and the toolbar).
  final TextEditingController controller;

  /// The editor's focus node (shared with [fieldBuilder] and the toolbar).
  final FocusNode focusNode;

  /// Builds the write-mode input field. Receives the same context; reads
  /// [controller]/[focusNode] from the host's closure.
  final WidgetBuilder fieldBuilder;

  /// Builds the preview-mode rendered markdown. Called lazily only while the
  /// Preview tab is active, so it reads the live [controller] text.
  final WidgetBuilder previewBuilder;

  @override
  State<MarkdownEditor> createState() => _MarkdownEditorState();
}

class _MarkdownEditorState extends State<MarkdownEditor> {
  bool _showPreview = false;

  void _applyFormat(TextEditingValue Function(TextEditingValue) transform) {
    widget.controller.value = transform(widget.controller.value);
    widget.focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyB, meta: true): () =>
            _applyFormat((v) => wrapSelection(v, '**', '**')),
        const SingleActivator(LogicalKeyboardKey.keyB, control: true): () =>
            _applyFormat((v) => wrapSelection(v, '**', '**')),
        const SingleActivator(LogicalKeyboardKey.keyI, meta: true): () =>
            _applyFormat((v) => wrapSelection(v, '_', '_')),
        const SingleActivator(LogicalKeyboardKey.keyI, control: true): () =>
            _applyFormat((v) => wrapSelection(v, '_', '_')),
        const SingleActivator(LogicalKeyboardKey.keyK, meta: true): () =>
            _applyFormat(insertLink),
        const SingleActivator(LogicalKeyboardKey.keyK, control: true): () =>
            _applyFormat(insertLink),
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: SegmentedToggle<bool>(
              value: _showPreview,
              onChanged: (v) => setState(() => _showPreview = v),
              segments: [
                (value: false, label: l10n.write),
                (value: true, label: l10n.preview),
              ],
            ),
          ),
          const SizedBox(height: 10),
          if (!_showPreview) ...[
            MarkdownToolbar(
              controller: widget.controller,
              focusNode: widget.focusNode,
            ),
            const SizedBox(height: 8),
            widget.fieldBuilder(context),
          ] else
            _PreviewBox(tokens: t, child: widget.previewBuilder(context)),
        ],
      ),
    );
  }
}

class _PreviewBox extends StatelessWidget {
  const _PreviewBox({required this.tokens, required this.child});

  final DesignSystemTokens tokens;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 120),
      decoration: BoxDecoration(
        color: tokens.panel,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: tokens.borderSecondary),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: child,
    );
  }
}
