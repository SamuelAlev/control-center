import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/material.dart';

/// A plain multiline markdown text field with the editor's panel styling.
///
/// Visually identical to the field inside `MentionAutocompleteField` (panel
/// background, hairline border, [FocusRing] focus indicator that doesn't shift
/// layout, no themed border in any state) but without the `@`/`#` autocomplete
/// overlay. Used wherever an editor wants the same look without GitHub-scoped
/// mentions (e.g. ticket descriptions). With [bare] the chrome is left to the
/// surrounding `MarkdownEditor` box and this renders only the padded text area.
class MarkdownTextField extends StatelessWidget {
  /// Creates a [MarkdownTextField].
  const MarkdownTextField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.hintText,
    this.minLines = 8,
    this.maxLines,
    this.bare = false,
  });

  /// The editor's text controller (shared with the toolbar/keyboard actions).
  final TextEditingController controller;

  /// The editor's focus node.
  final FocusNode focusNode;

  /// Placeholder shown when empty.
  final String hintText;

  /// Minimum visible lines.
  final int minLines;

  /// Maximum visible lines (null = grow unbounded).
  final int? maxLines;

  /// Renders only the padded text area: the fill, border and focus ring are
  /// the surrounding `MarkdownEditor` box's job. Standalone hosts (no editor
  /// around the field) keep the default self-drawn chrome.
  final bool bare;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final field = CcTextField(
      controller: controller,
      focusNode: focusNode,
      minLines: minLines,
      maxLines: maxLines,
      textStyle: CcTypography.body.copyWith(color: t.textPrimary, height: 1.5),
      hintText: hintText,
      chromeless: true,
    );
    if (bare) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: field,
      );
    }
    return FocusRing(
      focusNode: focusNode,
      child: Container(
        decoration: BoxDecoration(
          color: t.panel,
          borderRadius: BorderRadius.circular(2),
          border: Border.all(color: t.borderSecondary),
        ),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: field,
      ),
    );
  }
}
