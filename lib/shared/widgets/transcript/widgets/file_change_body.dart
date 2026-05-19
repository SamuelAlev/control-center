import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/transcript/widgets/code_preview.dart';
import 'package:control_center/shared/widgets/transcript/widgets/inline_diff_view.dart';
import 'package:control_center/shared/widgets/transcript/widgets/split_diff_view.dart';
import 'package:flutter/widgets.dart';

/// The body of an Edit / MultiEdit tool cell: a "Modified" eyebrow over the diff
/// the agent applied, plus an affordance to pop the same diff full-size.
///
/// The transcript auto-expands these rows (see `toolBodyOpensByDefault`), so the
/// change is visible where it happened without a click — you read what the agent
/// did, not that it did something. Layout adapts to the width it is given:
/// side-by-side old|new past [kSplitDiffMinWidth], the unified single-column
/// diff below it (narrow feeds, phone, `cc_remote`).
class FileEditDiffBody extends StatelessWidget {
  /// Creates a [FileEditDiffBody].
  const FileEditDiffBody({
    super.key,
    required this.oldText,
    required this.newText,
    required this.codeFont,
    required this.tokens,
    this.languageId,
    this.filePath,
  });

  /// The replaced text.
  final String oldText;

  /// The replacement text.
  final String newText;

  /// Mono font family.
  final String codeFont;

  /// Design tokens for colors.
  final DesignSystemTokens tokens;

  /// `highlight.dart` language id, or null for plain text.
  final String? languageId;

  /// Path of the edited file, used as the full-size viewer's title.
  final String? filePath;

  void _open(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showCcDialog<void>(
      context: context,
      builder: (_) => CcDialog(
        title: filePath ?? l10n.openInDiffViewer,
        content: SizedBox(
          width: 820,
          height: 560,
          child: SplitDiffView(
            oldText: oldText,
            newText: newText,
            codeFont: codeFont,
            tokens: tokens,
            languageId: languageId,
            maxHeight: double.infinity,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FileChangeEyebrow(
          label: l10n.modified,
          tokens: tokens,
          action: _OpenInViewerButton(
            tokens: tokens,
            onPressed: () => _open(context),
          ),
        ),
        const SizedBox(height: 4),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= kSplitDiffMinWidth) {
              return SplitDiffView(
                oldText: oldText,
                newText: newText,
                codeFont: codeFont,
                tokens: tokens,
                languageId: languageId,
              );
            }
            return InlineDiffView(
              oldText: oldText,
              newText: newText,
              codeFont: codeFont,
              tokens: tokens,
              languageId: languageId,
            );
          },
        ),
      ],
    );
  }
}

/// The body of a Write tool cell: a "Created" / "Modified" eyebrow (when the
/// result says which) over the contents the agent wrote.
///
/// There is no diff to show — a Write carries only the new bytes, so the old
/// side is unavailable — which is why this stays a code preview rather than an
/// all-additions diff.
class FileWriteBody extends StatelessWidget {
  /// Creates a [FileWriteBody].
  const FileWriteBody({
    super.key,
    required this.contents,
    required this.codeFont,
    required this.tokens,
    this.outputs = '',
    this.languageId,
  });

  /// The written file contents.
  final String contents;

  /// Mono font family.
  final String codeFont;

  /// Design tokens for colors.
  final DesignSystemTokens tokens;

  /// The tool result, which is what reveals whether the file was created or
  /// overwritten.
  final String outputs;

  /// `highlight.dart` language id, or null for plain text.
  final String? languageId;

  @override
  Widget build(BuildContext context) {
    final label = writeStatusLabel(outputs, AppLocalizations.of(context));
    final preview = CodePreview(
      code: contents,
      codeFont: codeFont,
      tokens: tokens,
      languageId: languageId,
    );
    if (label == null) {
      return preview;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FileChangeEyebrow(label: label, tokens: tokens),
        const SizedBox(height: 4),
        preview,
      ],
    );
  }
}

/// Whether a Write created the file or overwrote an existing one, read off the
/// tool result ("File created successfully at: …" / "… has been updated").
/// Returns null when the result does not say — a guess here would be a claim
/// about the user's filesystem we cannot make.
String? writeStatusLabel(String outputs, AppLocalizations l10n) {
  final text = outputs.toLowerCase();
  if (text.contains('creat')) {
    return l10n.created;
  }
  if (text.contains('updat') || text.contains('overwrit')) {
    return l10n.modified;
  }
  return null;
}

/// The quiet status line above a file-change body ("Modified" / "Created"), with
/// an optional trailing action.
class FileChangeEyebrow extends StatelessWidget {
  /// Creates a [FileChangeEyebrow].
  const FileChangeEyebrow({
    super.key,
    required this.label,
    required this.tokens,
    this.action,
  });

  /// The status word.
  final String label;

  /// Design tokens for colors.
  final DesignSystemTokens tokens;

  /// Optional trailing action (e.g. "open in diff viewer").
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: CcTypography.caption.copyWith(color: tokens.textTertiary),
        ),
        const Spacer(),
        ?action,
      ],
    );
  }
}

class _OpenInViewerButton extends StatelessWidget {
  const _OpenInViewerButton({required this.tokens, required this.onPressed});

  final DesignSystemTokens tokens;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return CcTappable(
      onPressed: onPressed,
      semanticLabel: l10n.openInDiffViewer,
      borderRadius: AppRadii.brSm,
      builder: (context, states) {
        final hovered = states.contains(WidgetState.hovered);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                AppIcons.maximize2,
                size: 12,
                color: hovered ? tokens.fgSecondary : tokens.fgQuaternary,
              ),
              const SizedBox(width: 4),
              Text(
                l10n.openInDiffViewer,
                style: CcTypography.caption.copyWith(
                  color: hovered ? tokens.textSecondary : tokens.textQuaternary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
