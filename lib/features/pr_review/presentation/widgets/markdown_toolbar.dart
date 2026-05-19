import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/features/pr_review/presentation/widgets/markdown_syntax_actions.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
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
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    return Wrap(
      spacing: 2,
      children: [
        _ToolbarButton(
          icon: LucideIcons.bold,
          tooltip: l10n.markdownBold,
          tokens: t,
          onPressed: () => _apply((v) => wrapSelection(v, '**', '**')),
        ),
        _ToolbarButton(
          icon: LucideIcons.italic,
          tooltip: l10n.markdownItalic,
          tokens: t,
          onPressed: () => _apply((v) => wrapSelection(v, '_', '_')),
        ),
        _ToolbarButton(
          icon: LucideIcons.heading,
          tooltip: l10n.markdownHeading,
          tokens: t,
          onPressed: () => _apply((v) => toggleLinePrefix(v, '## ')),
        ),
        _ToolbarButton(
          icon: LucideIcons.list,
          tooltip: l10n.markdownBulletList,
          tokens: t,
          onPressed: () => _apply((v) => toggleLinePrefix(v, '- ')),
        ),
        _ToolbarButton(
          icon: LucideIcons.listChecks,
          tooltip: l10n.markdownChecklist,
          tokens: t,
          onPressed: () => _apply((v) => toggleLinePrefix(v, '- [ ] ')),
        ),
        _ToolbarButton(
          icon: LucideIcons.code,
          tooltip: l10n.markdownCode,
          tokens: t,
          onPressed: () => _apply((v) => wrapSelection(v, '`', '`')),
        ),
        _ToolbarButton(
          icon: LucideIcons.link,
          tooltip: l10n.markdownLink,
          tokens: t,
          onPressed: () => _apply(insertLink),
        ),
        _ToolbarButton(
          icon: LucideIcons.quote,
          tooltip: l10n.markdownQuote,
          tokens: t,
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
    required this.tokens,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final DesignSystemTokens tokens;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FTooltip(
      tipBuilder: (_, _) => Text(tooltip),
      child: FTappable(
        onPress: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 16, color: tokens.fgSecondary),
        ),
      ),
    );
  }
}
