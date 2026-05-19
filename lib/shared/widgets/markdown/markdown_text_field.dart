import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/shared/widgets/focus_ring.dart';
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
    final theme = Theme.of(context);
    return FocusRing(
      focusNode: focusNode,
      child: Container(
        decoration: BoxDecoration(
          color: t.panel,
          borderRadius: BorderRadius.circular(2),
          border: Border.all(color: t.borderSecondary),
        ),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          minLines: minLines,
          maxLines: maxLines,
          cursorColor: t.fgBrandPrimary,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: t.textPrimary,
            height: 1.5,
          ),
          decoration: InputDecoration(
            isCollapsed: true,
            // No themed border in any state — the FocusRing draws the focus
            // indicator as an overlay so the box never changes size.
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            hintText: hintText,
            hintStyle: theme.textTheme.bodyMedium?.copyWith(
              color: t.textPlaceholder,
            ),
          ),
        ),
      ),
    );
  }
}
