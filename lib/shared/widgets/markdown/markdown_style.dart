import 'package:control_center/core/theme/app_fonts.dart';
import 'package:control_center/core/theme/app_radii.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/utils/syntax_palette.dart';
import 'package:control_center/shared/widgets/markdown/code_highlighter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:markdown/markdown.dart' as md;

/// Shared [FCheckbox] task-list checkbox builder for read-only markdown
/// rendering (PR descriptions, review comments, chat messages, tickets).
///
/// Wraps the [FCheckbox] in a [FittedBox] so it renders proportionally
/// within the markdown list's constrained bullet slot regardless of the
/// platform's default checkbox size.
MarkdownCheckboxBuilder markdownCheckboxBuilder(BuildContext context) =>
    (bool value) => SizedBox(
      height: 22,
      child: FittedBox(
        fit: BoxFit.contain,
        child: FCheckbox(value: value, enabled: false, onChange: null),
      ),
    );

/// Returns the shared GitHub-style [MarkdownStyleSheet] used for PR
/// descriptions, review comments, chat messages, and ticket descriptions.
///
/// Tuned to match the look in `.draft/screens/Screenshot 2026-05-14 at 17.52.52`:
/// generous heading hierarchy with underline rules under h1/h2, soft inline
/// `code` chips, a quiet code-block background, and breathing room between
/// list items and paragraphs.
MarkdownStyleSheet githubMarkdownStyleSheet(
  BuildContext context, {
  bool compact = false,
  String? codeFontFamily,
}) {
  final theme = Theme.of(context);
  final fTheme = context.theme;
  final base = MarkdownStyleSheet.fromTheme(theme);

  final fg = fTheme.colors.foreground;
  final muted = fTheme.colors.mutedForeground;
  final divider = fTheme.colors.border;
  // Inline code: full-opacity secondary so the chip reads as a distinct pill
  // against body text. Code blocks reuse this color.
  final codeBg = fTheme.colors.secondary;
  const link = Color(0xFF1F75FE);

  final bodyFontSize = compact ? 13.5 : 14.5;

  return base.copyWith(
    p: theme.textTheme.bodyMedium?.copyWith(
      fontSize: bodyFontSize,
      height: 1.6,
      color: fg,
    ),
    pPadding: EdgeInsets.only(bottom: compact ? 6 : 10),
    h1: theme.textTheme.headlineSmall?.copyWith(
      fontSize: compact ? 22 : 26,
      fontWeight: FontWeight.w700,
      color: fg,
      height: 1.25,
    ),
    h1Padding: EdgeInsets.only(top: compact ? 12 : 20, bottom: 4),
    h1Align: WrapAlignment.start,
    h2: theme.textTheme.titleLarge?.copyWith(
      fontSize: compact ? 18 : 20,
      fontWeight: FontWeight.w600,
      color: fg,
      height: 1.3,
    ),
    h2Padding: EdgeInsets.only(top: compact ? 12 : 18, bottom: 4),
    h3: theme.textTheme.titleMedium?.copyWith(
      fontSize: compact ? 15 : 16,
      fontWeight: FontWeight.w600,
      color: fg,
      height: 1.35,
    ),
    h3Padding: EdgeInsets.only(top: compact ? 10 : 14, bottom: 2),
    h4: theme.textTheme.titleSmall?.copyWith(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: fg,
    ),
    h4Padding: const EdgeInsets.only(top: 12, bottom: 2),
    h5: theme.textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w600,
      color: fg,
    ),
    h6: theme.textTheme.bodySmall?.copyWith(
      fontWeight: FontWeight.w600,
      color: muted,
    ),
    a: const TextStyle(color: link, decoration: TextDecoration.none),
    // Inline `code` chip: background is applied via [InlineCodeBuilder]'s
    // Container wrapper so it doesn't paint over the SelectionArea highlight.
    // Default to the app's mono font (JetBrains Mono) rather than the generic
    // platform `monospace`; honour the user's selected code font when one is
    // threaded in. `codeStyleDynamic` loads it via google_fonts.
    code: AppFonts.codeStyleDynamic(
      codeFontFamily ?? 'JetBrains Mono',
      fontSize: bodyFontSize - 1,
      color: fg,
    ).copyWith(letterSpacing: 0.2, fontWeight: FontWeight.w500),
    codeblockDecoration: BoxDecoration(
      color: codeBg,
      borderRadius: AppRadii.brLg,
      border: Border.all(color: divider),
    ),
    codeblockPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    blockquote: theme.textTheme.bodyMedium?.copyWith(
      fontSize: bodyFontSize,
      height: 1.6,
      color: muted,
      fontStyle: FontStyle.italic,
    ),
    blockquoteDecoration: BoxDecoration(
      border: Border(left: BorderSide(color: divider, width: 3)),
    ),
    blockquotePadding: const EdgeInsets.only(left: 12, top: 2, bottom: 2),
    listIndent: 30,
    listBullet: theme.textTheme.bodyMedium?.copyWith(
      fontSize: bodyFontSize,
      height: 1.6,
      color: fg,
    ),
    listBulletPadding: const EdgeInsets.only(right: 6),
    horizontalRuleDecoration: BoxDecoration(
      border: Border(top: BorderSide(color: divider)),
    ),
    tableHead: theme.textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w700,
      color: fg,
    ),
    tableBody: theme.textTheme.bodyMedium?.copyWith(
      fontSize: bodyFontSize,
      color: fg,
    ),
    tableBorder: TableBorder.all(color: divider, width: 0.5),
    tableHeadAlign: TextAlign.left,
    tableCellsPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    // `flutter_markdown_plus` builds tables with this as `defaultColumnWidth`.
    // `IntrinsicColumnWidth` would call `getMaxIntrinsicWidth` on every cell,
    // which throws if a cell contains a `LayoutBuilder` — and our image and
    // video markdown renderers in `github_markdown_body.dart` both use one to
    // cap their width against the parent constraints. PR descriptions with a
    // markdown table around an image (e.g. SamuelAlev/control-center#14414) hit that
    // path and bring the whole render frame down. `FlexColumnWidth` doesn't
    // query intrinsics, so cells with `LayoutBuilder` are safe.
    tableColumnWidth: const FlexColumnWidth(),
    em: TextStyle(fontStyle: FontStyle.italic, color: fg),
    strong: TextStyle(fontWeight: FontWeight.w700, color: fg),
  );
}

/// Custom builder for inline `code` elements that renders the code chip using a
/// [Container] background instead of [TextStyle.backgroundColor].
///
/// `TextStyle.backgroundColor` is painted by the paragraph renderer *on top*
/// of the selection highlight, making selected inline code appear unselected.
/// Moving the background to a [Container] keeps the chip look while letting the
/// [SelectionArea] highlight shine through.
///
/// The chip is wrapped in a [WidgetSpan] inside a [Text.rich] rather than
/// returned as a bare [Container]. flutter_markdown_plus assembles each
/// paragraph's inline content into a `Wrap`, and only merges adjacent *text*
/// widgets into a single `RichText` (see `MarkdownBuilder._mergeInlineChildren`).
/// A builder that returns a bare widget becomes a standalone `Wrap` child,
/// which splits the text run: the text *following* the chip is then measured
/// and wrapped as one atomic block, so it jumps to the next line whenever it
/// doesn't fully fit in the space left after the chip — even with room to
/// spare. Returning a [Text.rich] makes the builder count as "text", so the
/// chip's [WidgetSpan] is merged into the surrounding run and the text after
/// it wraps naturally, character by character.
class InlineCodeBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final text = element.textContent;
    if (text.isEmpty) {
      return null;
    }

    final codeStyle = preferredStyle ?? const TextStyle();
    final codeBg = context.theme.colors.secondary;

    return Text.rich(
      TextSpan(
        children: [
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: codeBg,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(text, style: codeStyle),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom builder for `pre` (fenced code block) elements that renders a
/// language label, a copy button which places the code on the clipboard
/// wrapped in triple backticks, and language-aware syntax highlighting
/// (via `highlight.dart` + the shared [syntaxPaletteFor] palette).
///
/// The code is set in the app's mono font (JetBrains Mono by default); pass
/// [codeFontFamily] to honour the user's selected code font
/// (`codeFontFamilyProvider`).
class CodeBlockBuilder extends MarkdownElementBuilder {
  /// Creates a [CodeBlockBuilder].
  CodeBlockBuilder({this.codeFontFamily});

  /// The mono font family to render the code in. Falls back to JetBrains Mono
  /// when null (see [githubMarkdownStyleSheet]).
  final String? codeFontFamily;

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    String? language;
    for (final child in element.children ?? const <md.Node>[]) {
      if (child is md.Element && child.tag == 'code') {
        final cls = child.attributes['class'] ?? '';
        if (cls.startsWith('language-')) {
          language = cls.substring(9);
        }
      }
    }

    final code = element.textContent.replaceAll(RegExp(r'\n$'), '');
    if (code.isEmpty) {
      return null;
    }

    final fTheme = context.theme;
    final codeStyle = githubMarkdownStyleSheet(
      context,
      codeFontFamily: codeFontFamily,
    ).code;

    final spans = highlightCodeSpans(
      code: code,
      languageId: resolveHighlightLanguage(language),
      palette: syntaxPaletteFor(Theme.of(context).brightness),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: fTheme.colors.border)),
          ),
          child: Row(
            children: [
              if (language != null)
                Text(
                  language,
                  style: TextStyle(
                    color: fTheme.colors.mutedForeground,
                    fontSize: 12,
                  ),
                ),
              const Spacer(),
              _CopyCodeButton(code: code, language: language),
            ],
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Text.rich(TextSpan(style: codeStyle, children: spans)),
        ),
      ],
    );
  }
}

class _CopyCodeButton extends StatefulWidget {
  const _CopyCodeButton({required this.code, this.language});

  final String code;
  final String? language;

  @override
  State<_CopyCodeButton> createState() => _CopyCodeButtonState();
}

class _CopyCodeButtonState extends State<_CopyCodeButton> {
  bool _copied = false;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        _copied ? LucideIcons.check : LucideIcons.copy,
        size: 14,
        color: context.theme.colors.mutedForeground,
      ),
      visualDensity: VisualDensity.compact,
      tooltip: _copied
          ? AppLocalizations.of(context).copied
          : AppLocalizations.of(context).copy,
      onPressed: () {
        final lang = widget.language;
        final wrapped = lang != null
            ? '```$lang\n${widget.code}\n```'
            : '```\n${widget.code}\n```';
        Clipboard.setData(ClipboardData(text: wrapped));
        setState(() => _copied = true);
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() => _copied = false);
          }
        });
      },
    );
  }
}
