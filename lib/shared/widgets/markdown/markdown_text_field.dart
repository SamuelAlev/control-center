import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/material.dart';

/// A plain multiline markdown text field with the editor's panel styling.
///
/// Visually identical to the field inside `MentionAutocompleteField` (panel
/// background, hairline border, [FocusRing] focus indicator that doesn't shift
/// layout, no themed border in any state) but without the `@`/`#` autocomplete
/// overlay. Used wherever an editor wants the same look without GitHub-scoped
/// mentions (e.g. ticket descriptions).
class MarkdownTextField extends StatelessWidget {
  /// Creates a [MarkdownTextField].
  const MarkdownTextField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.hintText,
    this.minLines = 8,
    this.maxLines,
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

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return FocusRing(
      focusNode: focusNode,
      child: Container(
        decoration: BoxDecoration(
          color: t.panel,
          borderRadius: BorderRadius.circular(2),
          border: Border.all(color: t.borderSecondary),
        ),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: CcTextField(
          controller: controller,
          focusNode: focusNode,
          minLines: minLines,
          maxLines: maxLines,
          textStyle: CcTypography.body.copyWith(
            color: t.textPrimary,
            height: 1.5,
          ),
          hintText: hintText,
          chromeless: true,
        ),
      ),
    );
  }
}
