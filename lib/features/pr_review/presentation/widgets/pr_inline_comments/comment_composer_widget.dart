import 'package:control_center/core/theme/app_shadows.dart';
import 'package:control_center/core/theme/design_system_palette.dart';
import 'package:control_center/l10n/app_localizations.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Conventional comment prefixes (conventionalcomments.org).
const _conventionalPrefixes = [
  (prefix: 'nit: ', description: 'Minor nit — non-blocking'),
  (prefix: 'suggestion: ', description: 'Suggestion — non-blocking'),
  (prefix: 'issue: ', description: 'Issue — should be addressed'),
  (prefix: 'question: ', description: 'Question — needs clarification'),
  (prefix: 'praise: ', description: 'Praise — positive feedback'),
  (prefix: 'thought: ', description: 'Thought — exploratory, non-blocking'),
];

/// Pr comment composer.
class PrCommentComposer extends StatefulWidget {
  /// PrCommentComposer({.
  const PrCommentComposer({
    super.key,
    required this.onSubmit,
    required this.onCancel,
    this.placeholder = 'Leave a comment…',
    this.autofocus = true,
    this.initialText,
  });

  /// Called with the comment body when the user submits.
  final void Function(String body) onSubmit;
  /// Called when the user cancels or presses Escape.
  final VoidCallback onCancel;
  /// Hint text shown in the empty composer.
  final String placeholder;
  /// Whether the composer should grab focus on open.
  final bool autofocus;
  /// String?.
  final String? initialText;

  @override
  State<PrCommentComposer> createState() => _PrCommentComposerState();
}

class _PrCommentComposerState extends State<PrCommentComposer> {
  final _focus = FocusNode();
  late final _ctrl = TextEditingController(text: widget.initialText ?? '');
  OverlayEntry? _slashMenu;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onTextChanged);
    _closeSlashMenu();
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final text = _ctrl.text;
    if (text == '/') {
      _showSlashMenu();
    } else if (_slashMenu != null && !text.startsWith('/')) {
      _closeSlashMenu();
    }
  }

  void _showSlashMenu() {
    _closeSlashMenu();
    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) {
      return;
    }
    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    _slashMenu = OverlayEntry(
      builder: (_) => Positioned(
        left: position.dx,
        top: position.dy - (_conventionalPrefixes.length * 40.0) - 8,
        width: size.width,
        child: Material(
          elevation: 4,
          shadowColor: const Color(0x1F7F6315),
          borderRadius: BorderRadius.circular(2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _conventionalPrefixes.map((p) {
              return ListTile(
                dense: true,
                title: Text(p.prefix,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(p.description,
                    style: const TextStyle(fontSize: 11)),
                onTap: () {
                  _ctrl.text = p.prefix;
                  _ctrl.selection = TextSelection.fromPosition(
                    TextPosition(offset: p.prefix.length),
                  );
                  _closeSlashMenu();
                  _focus.requestFocus();
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
    overlay.insert(_slashMenu!);
  }

  void _closeSlashMenu() {
    _slashMenu?.remove();
    _slashMenu = null;
  }

  void _submit() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) {
      return;
    }
    _closeSlashMenu();
    widget.onSubmit(text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: theme.colors.background,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: theme.colors.border),
        boxShadow: AppShadows.soft,
      ),
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      child: Focus(
        canRequestFocus: false,
        onKeyEvent: (_, e) {
          if (e is KeyDownEvent && e.logicalKey == LogicalKeyboardKey.escape) {
            widget.onCancel();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: SelectionContainer.disabled(
                child: TextField(
                  controller: _ctrl,
                  focusNode: _focus,
                  autofocus: widget.autofocus,
                  minLines: 1,
                  maxLines: 4,
                  style: Theme.of(context).textTheme.bodyMedium,
                  decoration: InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText: widget.placeholder,
                    hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: theme.colors.mutedForeground,
                    ),
                  ),
                  onSubmitted: (_) => _submit(),
                ),
              ),
            ),
            const SizedBox(width: 6),
            _SendButton(onPressed: _submit),
          ],
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FTooltip(
      tipBuilder: (_, _) => Text(AppLocalizations.of(context).send),

      child: FButton.icon(
        onPress: onPressed,
        variant: FButtonVariant.primary,
        child: const Icon(LucideIcons.arrowUp, size: 16),
      ),
    );
  }
}

/// Pr selection toolbar.
class PrSelectionToolbar extends StatelessWidget {
  /// Creates a [PrSelectionToolbar].
  const PrSelectionToolbar({
    super.key,
    required this.onComment,
    required this.onSuggest,
    required this.onReact,
  });

  /// Called when the user taps the comment action.
  final VoidCallback onComment;
  /// Called when the user taps the suggest action.
  final VoidCallback onSuggest;
  /// Called when the user taps the react action.
  final VoidCallback onReact;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: const BoxDecoration(
          color: DesignSystemPalette.gray900,
          borderRadius: BorderRadius.all(Radius.circular(999)),
          boxShadow: AppShadows.golden,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ToolbarIcon(
              icon: LucideIcons.messageSquare,
              tooltip: AppLocalizations.of(context).addAComment,

              onPressed: onComment,
            ),
            _ToolbarIcon(
              icon: LucideIcons.diff,
              tooltip: AppLocalizations.of(context).addASuggestion,

              onPressed: onSuggest,
            ),
            _ToolbarIcon(
              icon: LucideIcons.smile,
              tooltip: AppLocalizations.of(context).addAReaction,
              onPressed: onReact,
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolbarIcon extends StatelessWidget {
  const _ToolbarIcon({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 16, color: Colors.white),
      visualDensity: VisualDensity.compact,
      tooltip: tooltip,
      onPressed: onPressed,
    );
  }
}
