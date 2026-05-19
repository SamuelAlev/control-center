import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/markdown/markdown_syntax_actions.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Formatting toolbar for the markdown body editor. Each button rewrites the
/// [controller]'s value via the pure transforms in `markdown_syntax_actions`,
/// then restores focus to the editor so typing continues uninterrupted.
class MarkdownToolbar extends StatelessWidget {
  /// Creates a [MarkdownToolbar].
  const MarkdownToolbar({
    super.key,
    required this.controller,
    required this.focusNode,
  });

  /// The editor's text controller.
  final TextEditingController controller;

  /// The editor's focus node (re-focused after each action).
  final FocusNode focusNode;

  void _apply(TextEditingValue Function(TextEditingValue) transform) {
    controller.value = transform(controller.value);
    focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        _ToolbarButton(
          icon: LucideIcons.bold,
          tooltip: l10n.markdownBold,
          onPressed: () => _apply((v) => wrapSelection(v, '**', '**')),
        ),
        _ToolbarButton(
          icon: LucideIcons.italic,
          tooltip: l10n.markdownItalic,
          onPressed: () => _apply((v) => wrapSelection(v, '_', '_')),
        ),
        _ToolbarButton(
          icon: LucideIcons.heading,
          tooltip: l10n.markdownHeading,
          onPressed: () => _apply((v) => toggleLinePrefix(v, '## ')),
        ),
        _ToolbarButton(
          icon: LucideIcons.list,
          tooltip: l10n.markdownBulletList,
          onPressed: () => _apply((v) => toggleLinePrefix(v, '- ')),
        ),
        _ToolbarButton(
          icon: LucideIcons.listChecks,
          tooltip: l10n.markdownChecklist,
          onPressed: () => _apply((v) => toggleLinePrefix(v, '- [ ] ')),
        ),
        _ToolbarButton(
          icon: LucideIcons.code,
          tooltip: l10n.markdownCode,
          onPressed: () => _apply((v) => wrapSelection(v, '`', '`')),
        ),
        _ToolbarButton(
          icon: LucideIcons.link,
          tooltip: l10n.markdownLink,
          onPressed: () => _apply(insertLink),
        ),
        _ToolbarButton(
          icon: LucideIcons.quote,
          tooltip: l10n.markdownQuote,
          onPressed: () => _apply((v) => toggleLinePrefix(v, '> ')),
        ),
      ],
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CcIconButton(
      variant: CcButtonVariant.secondary,
      size: CcButtonSize.sm,
      onPressed: onPressed,
      icon: icon,
      tooltip: tooltip,
    );
  }
}
