import 'package:control_center/features/pr_review/presentation/utils/diff_palette.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';

/// Inline "suggest a change" composer: the original line(s) are shown read-only
/// with deletion styling above an editable replacement field with addition
/// styling, plus an optional comment and post/cancel actions — mirroring the
/// GitHub/Pierre suggestion flow (original row + editable replacement row).
class SuggestionComposer extends StatefulWidget {
  /// Creates a suggestion composer.
  const SuggestionComposer({
    super.key,
    required this.originalCode,
    required this.baseStyle,
    required this.onSubmit,
    required this.onCancel,
  });

  /// The original code being replaced (shown read-only as a deletion row).
  final String originalCode;

  /// Monospace base style shared with the diff body.
  final TextStyle baseStyle;

  /// Called with `(suggestedCode, comment)` when the suggestion is posted.
  final void Function(String suggested, String comment) onSubmit;

  /// Called on cancel or Escape.
  final VoidCallback onCancel;

  @override
  State<SuggestionComposer> createState() => _SuggestionComposerState();
}

class _SuggestionComposerState extends State<SuggestionComposer> {
  late final TextEditingController _code =
      TextEditingController(text: widget.originalCode);
  final TextEditingController _comment = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final palette = DiffPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final codeStyle = widget.baseStyle.copyWith(fontSize: 12.5, height: 1.5);
    return Focus(
      canRequestFocus: false,
      onKeyEvent: (_, e) {
        if (e is KeyDownEvent && e.logicalKey == LogicalKeyboardKey.escape) {
          widget.onCancel();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        decoration: BoxDecoration(
          color: theme.colors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: theme.colors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Original line(s) — read-only, deletion styling.
            Container(
              color: palette.deletionBg,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: SelectionContainer.disabled(
                child: Text(widget.originalCode, style: codeStyle),
              ),
            ),
            // Editable replacement — addition styling.
            Container(
              color: palette.additionBg,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: SelectionContainer.disabled(
                child: TextField(
                  controller: _code,
                  autofocus: true,
                  minLines: 1,
                  maxLines: 12,
                  style: codeStyle,
                  decoration: const InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const FDivider(),
            // Optional comment + actions.
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: SelectionContainer.disabled(
                      child: TextField(
                        controller: _comment,
                        minLines: 1,
                        maxLines: 3,
                        style: Theme.of(context).textTheme.bodyMedium,
                        decoration: InputDecoration(
                          isCollapsed: true,
                          border: InputBorder.none,
                          hintText: l10n.leaveACommentEllipsis,
                          hintStyle:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: theme.colors.mutedForeground,
                                  ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  FButton(
                    onPress: widget.onCancel,
                    variant: FButtonVariant.outline,
                    mainAxisSize: MainAxisSize.min,
                    child: Text(l10n.cancel),
                  ),
                  const SizedBox(width: 6),
                  FButton(
                    onPress: () => widget.onSubmit(_code.text, _comment.text),
                    mainAxisSize: MainAxisSize.min,
                    child: Text(l10n.suggestAChange),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
