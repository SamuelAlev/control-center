import 'package:control_center/core/theme/app_fonts.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// Matches a backtick-delimited inline-code run (`` `code` ``), capturing the
/// inner text. Empty backtick pairs (`` `` ``) are intentionally not matched
/// and stay literal, mirroring how markdown renders them.
final RegExp _inlineCodeRegex = RegExp(r'`([^`]+)`');

/// Whether [text] contains at least one backtick-delimited inline-code run.
bool hasInlineCode(String text) => _inlineCodeRegex.hasMatch(text);

/// Strips the backtick delimiters from [text], leaving the inner code content
/// inline. Used for plain-text surfaces (semantics labels, search, tooltips)
/// where the styled chip can't render but a literal backtick shouldn't leak.
String stripInlineCode(String text) =>
    text.replaceAllMapped(_inlineCodeRegex, (m) => m.group(1)!);

/// Builds the inline spans for [text], rendering backtick-delimited runs as
/// monospace code chips (matching the `InlineCodeBuilder` used in PR markdown
/// bodies) and the remaining text with [baseStyle].
///
/// When [text] has no inline code this returns a single plain [TextSpan], so it
/// is safe (and cheap) to route every title through it.
List<InlineSpan> buildInlineCodeSpans(
  BuildContext context,
  String text, {
  required TextStyle baseStyle,
}) {
  if (!hasInlineCode(text)) {
    return [TextSpan(text: text, style: baseStyle)];
  }

  final chipBg = context.theme.colors.secondary;
  // Keep the chip a touch smaller and at a tight line height so the padded
  // [WidgetSpan] never grows the surrounding line box in dense, single-line
  // rows (PR list, merge dialog, dashboard).
  final codeStyle = AppFonts.codeStyle(
    fontSize: (baseStyle.fontSize ?? 14) - 1,
    fontWeight: baseStyle.fontWeight,
    color: baseStyle.color,
    height: 1,
    letterSpacing: 0.2,
  );

  final spans = <InlineSpan>[];
  var cursor = 0;
  for (final match in _inlineCodeRegex.allMatches(text)) {
    if (match.start > cursor) {
      spans.add(
        TextSpan(text: text.substring(cursor, match.start), style: baseStyle),
      );
    }
    spans.add(
      WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: chipBg,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(match.group(1)!, style: codeStyle),
        ),
      ),
    );
    cursor = match.end;
  }
  if (cursor < text.length) {
    spans.add(TextSpan(text: text.substring(cursor), style: baseStyle));
  }
  return spans;
}

/// Renders a PR title with backtick-delimited runs shown as inline code chips,
/// matching the inline-code styling used in PR markdown bodies. A title with no
/// backticks renders exactly like a plain [Text].
///
/// Use [leading] for a styled prefix that should stay literal (e.g. the muted
/// `#123 ` PR-number prefix), so only the title text is parsed for code runs.
class PrTitleText extends StatelessWidget {
  /// Creates an inline-code-aware title.
  const PrTitleText(
    this.title, {
    super.key,
    this.style,
    this.leading,
    this.maxLines,
    this.overflow,
    this.textAlign,
    this.softWrap,
  });

  /// The raw title, possibly containing `inline code`.
  final String title;

  /// Base style for the non-code text. Falls back to the ambient
  /// [DefaultTextStyle] when null.
  final TextStyle? style;

  /// Optional spans rendered before the title (e.g. a muted `#123 ` prefix).
  /// These are not parsed for inline code.
  final List<InlineSpan>? leading;

  /// Forwarded to the underlying [Text.rich].
  final int? maxLines;

  /// Forwarded to the underlying [Text.rich]. Defaults to [TextOverflow.clip].
  final TextOverflow? overflow;

  /// Forwarded to the underlying [Text.rich]. Defaults to [TextAlign.start].
  final TextAlign? textAlign;

  /// Forwarded to the underlying [Text.rich].
  final bool? softWrap;

  @override
  Widget build(BuildContext context) {
    final base = style ?? DefaultTextStyle.of(context).style;
    return Text.rich(
      TextSpan(
        style: base,
        children: [
          ...?leading,
          ...buildInlineCodeSpans(context, title, baseStyle: base),
        ],
      ),
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.clip,
      textAlign: textAlign ?? TextAlign.start,
      softWrap: softWrap,
    );
  }
}
