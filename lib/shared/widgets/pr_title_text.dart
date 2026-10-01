import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/theme/app_fonts.dart';
import 'package:control_center/shared/widgets/markdown/markdown_style.dart';
import 'package:flutter/widgets.dart';

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

/// Monospace style for a title's code run.
///
/// Weight stays at the regular cut, the same as a markdown body chip. A PR
/// title is semibold, and copying that weight onto the code face (one variable
/// file, no separate bold cut) synthesizes a heavy blob inside the chip. The
/// weight has to be set explicitly: a null weight on a child span inherits the
/// parent title's semibold.
TextStyle _titleCodeStyle(TextStyle base) {
  return AppFonts.codeStyle(
    fontSize: (base.fontSize ?? 14) - 1,
    fontWeight: CcTypography.regularWeight,
    color: base.color,
    height: 1,
    letterSpacing: 0.2,
  );
}

/// Inline-code chip for a title. Padding, radius and wash are the markdown
/// chip ([kInlineCodeChipPadding], [kInlineCodeChipRadius],
/// [inlineCodeChipColor]) so a backtick run in a title matches one in a body.
class _TitleCodeChip extends StatelessWidget {
  const _TitleCodeChip({
    required this.code,
    required this.style,
    this.ellipsize = false,
  });

  final String code;
  final TextStyle style;

  /// Ellipsize the glyphs when a parent has already capped the chip's width.
  /// An unconstrained chip stays one line and shrink-wraps, matching the
  /// markdown chip.
  final bool ellipsize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: kInlineCodeChipPadding,
      decoration: BoxDecoration(
        color: inlineCodeChipColor(context),
        borderRadius: BorderRadius.circular(kInlineCodeChipRadius),
      ),
      child: Text(
        code,
        style: style,
        softWrap: false,
        maxLines: 1,
        overflow: ellipsize ? TextOverflow.ellipsis : TextOverflow.clip,
      ),
    );
  }
}

/// A [WidgetSpan] whose plain text is the code (or truncated run) itself.
///
/// The default placeholder flattens to U+FFFC, so a title that reads
/// `remove clipboard dependency` would no longer match as that string.
class _PlainWidgetSpan extends WidgetSpan {
  const _PlainWidgetSpan({required this.plain, required super.child})
    : super(
        alignment: PlaceholderAlignment.baseline,
        baseline: TextBaseline.alphabetic,
      );

  final String plain;

  @override
  void computeToPlainText(
    StringBuffer buffer, {
    bool includeSemanticsLabels = true,
    bool includePlaceholders = true,
  }) {
    if (includePlaceholders) {
      buffer.write(plain);
    }
  }

  @override
  void computeSemanticsInformation(
    List<InlineSpanSemanticsInformation> collector,
  ) {
    collector.add(InlineSpanSemanticsInformation(plain));
  }
}

InlineSpan _chipSpan(
  BuildContext context, {
  required String code,
  required TextStyle style,
  double? maxWidth,
}) {
  final chip = _TitleCodeChip(
    code: code,
    style: style,
    ellipsize: maxWidth != null,
  );
  return _PlainWidgetSpan(
    plain: code,
    child: maxWidth == null ? chip : SizedBox(width: maxWidth, child: chip),
  );
}

/// Builds the inline spans for [text], rendering backtick-delimited runs as
/// monospace code chips (the same padding and wash as markdown inline code)
/// and the remaining text with [baseStyle].
///
/// When [text] has no inline code this returns a single plain [TextSpan], so it
/// is safe (and cheap) to route every title through it.
///
/// One-line ellipsis is not handled here. A [TextOverflow.ellipsis] paragraph
/// lays every inline child out with the line's full max width and drops any
/// placeholder past the truncation point, so [PrTitleText] measures the line
/// and caps the overflowing run itself.
List<InlineSpan> buildInlineCodeSpans(
  BuildContext context,
  String text, {
  required TextStyle baseStyle,
}) {
  if (!hasInlineCode(text)) {
    return [TextSpan(text: text, style: baseStyle)];
  }

  final codeStyle = _titleCodeStyle(baseStyle);
  final spans = <InlineSpan>[];
  var cursor = 0;
  for (final match in _inlineCodeRegex.allMatches(text)) {
    if (match.start > cursor) {
      spans.add(
        TextSpan(text: text.substring(cursor, match.start), style: baseStyle),
      );
    }
    spans.add(_chipSpan(context, code: match.group(1)!, style: codeStyle));
    cursor = match.end;
  }
  if (cursor < text.length) {
    spans.add(TextSpan(text: text.substring(cursor), style: baseStyle));
  }
  return spans;
}

/// Text-run wash used only when a leading span can't be measured. No padding
/// is possible on a paragraph background; the chip path is the real title.
List<InlineSpan> _backgroundCodeSpans(
  BuildContext context,
  String text,
  TextStyle baseStyle,
) {
  final codeStyle = _titleCodeStyle(
    baseStyle,
  ).copyWith(backgroundColor: inlineCodeChipColor(context));
  final spans = <InlineSpan>[];
  var cursor = 0;
  for (final match in _inlineCodeRegex.allMatches(text)) {
    if (match.start > cursor) {
      spans.add(
        TextSpan(text: text.substring(cursor, match.start), style: baseStyle),
      );
    }
    spans.add(TextSpan(text: match.group(1)!, style: codeStyle));
    cursor = match.end;
  }
  if (cursor < text.length) {
    spans.add(TextSpan(text: text.substring(cursor), style: baseStyle));
  }
  return spans;
}

class _TitleRun {
  const _TitleRun(this.text, this.style, {required this.isCode});

  final String text;
  final TextStyle style;
  final bool isCode;
}

/// Flattens [leading] into text runs. Returns null when a run isn't text,
/// which the ellipsis layout can't measure.
List<_TitleRun>? _leadingRuns(List<InlineSpan>? leading, TextStyle base) {
  if (leading == null) {
    return const [];
  }
  final runs = <_TitleRun>[];
  for (final span in leading) {
    if (!_appendSpan(span, base, runs)) {
      return null;
    }
  }
  return runs;
}

bool _appendSpan(InlineSpan span, TextStyle parent, List<_TitleRun> out) {
  if (span is! TextSpan) {
    return false;
  }
  final style = parent.merge(span.style);
  final text = span.text;
  if (text != null && text.isNotEmpty) {
    out.add(_TitleRun(text, style, isCode: false));
  }
  for (final child in span.children ?? const <InlineSpan>[]) {
    if (!_appendSpan(child, style, out)) {
      return false;
    }
  }
  return true;
}

void _appendTitleRuns(
  String title,
  TextStyle base,
  TextStyle codeStyle,
  List<_TitleRun> out,
) {
  var cursor = 0;
  for (final match in _inlineCodeRegex.allMatches(title)) {
    if (match.start > cursor) {
      out.add(
        _TitleRun(title.substring(cursor, match.start), base, isCode: false),
      );
    }
    out.add(_TitleRun(match.group(1)!, codeStyle, isCode: true));
    cursor = match.end;
  }
  if (cursor < title.length) {
    out.add(_TitleRun(title.substring(cursor), base, isCode: false));
  }
}

String _plainTitle(String title, List<InlineSpan>? leading) {
  final buffer = StringBuffer();
  if (leading != null) {
    for (final span in leading) {
      buffer.write(span.toPlainText(includePlaceholders: false));
    }
  }
  buffer.write(stripInlineCode(title));
  return buffer.toString();
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
    final align = textAlign ?? TextAlign.start;
    if (overflow == TextOverflow.ellipsis &&
        maxLines == 1 &&
        hasInlineCode(title)) {
      return _EllipsizedCodeTitle(
        title: title,
        base: base,
        leading: leading,
        textAlign: align,
      );
    }
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
      textAlign: align,
      softWrap: softWrap,
    );
  }
}

/// One-line ellipsis that keeps code runs as padded chips.
///
/// [TextOverflow.ellipsis] drops a [WidgetSpan] that lands on the cut and can
/// leave its width behind as dead space. This measures the runs and, when the
/// line overflows, gives the overflowing run only the room that's left so the
/// chip stays padded and the rest of the line can ellipsize inside it.
class _EllipsizedCodeTitle extends StatelessWidget {
  const _EllipsizedCodeTitle({
    required this.title,
    required this.base,
    required this.leading,
    required this.textAlign,
  });

  final String title;
  final TextStyle base;
  final List<InlineSpan>? leading;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final label = _plainTitle(title, leading);
    return LayoutBuilder(
      builder: (context, constraints) {
        final defaults = DefaultTextStyle.of(context).style;
        final effective = defaults.merge(base);
        final leadingRuns = _leadingRuns(leading, effective);
        if (leadingRuns == null || !constraints.maxWidth.isFinite) {
          // A leading run we can't measure can't be width-capped. Degrade
          // that case to a text-run background so ellipsis can't drop a
          // placeholder. An unbounded line doesn't truncate; the chip is fine.
          final spans = leadingRuns == null
              ? _backgroundCodeSpans(context, title, effective)
              : buildInlineCodeSpans(context, title, baseStyle: effective);
          return Text.rich(
            TextSpan(style: effective, children: [...?leading, ...spans]),
            maxLines: 1,
            overflow: leadingRuns == null
                ? TextOverflow.ellipsis
                : TextOverflow.clip,
            textAlign: textAlign,
            softWrap: false,
            semanticsLabel: label,
          );
        }

        final codeStyle = defaults.merge(_titleCodeStyle(effective));
        final runs = <_TitleRun>[...leadingRuns];
        _appendTitleRuns(title, effective, codeStyle, runs);

        final direction = Directionality.of(context);
        final scaler = MediaQuery.textScalerOf(context);
        final locale = Localizations.maybeLocaleOf(context);
        final heightBehavior = DefaultTextStyle.of(context).textHeightBehavior;

        double measure(String text, TextStyle style) {
          // `TextWidthBasis.parent` with an unbounded layout reports an
          // infinite width, which would treat every run as overflowing and
          // drop the rest of the title. Lay out against a wide finite cap and
          // read the run's own intrinsic width.
          final painter = TextPainter(
            text: TextSpan(text: text, style: style),
            textDirection: direction,
            textScaler: scaler,
            locale: locale,
            textHeightBehavior: heightBehavior,
            textWidthBasis: TextWidthBasis.longestLine,
            maxLines: 1,
          )..layout(maxWidth: 1000000);
          final width = painter.maxIntrinsicWidth;
          painter.dispose();
          return width;
        }

        double runWidth(_TitleRun run) {
          final textWidth = measure(run.text, run.style);
          if (!run.isCode) {
            return textWidth;
          }
          return textWidth + kInlineCodeChipPadding.horizontal;
        }

        final widths = [for (final run in runs) runWidth(run)];
        final total = widths.fold<double>(0, (sum, width) => sum + width);
        final maxWidth = constraints.maxWidth;
        final spans = <InlineSpan>[];

        if (total <= maxWidth) {
          for (final run in runs) {
            spans.add(_spanFor(context, run));
          }
        } else {
          var used = 0.0;
          for (var i = 0; i < runs.length; i++) {
            final room = maxWidth - used;
            if (widths[i] <= room) {
              spans.add(_spanFor(context, runs[i]));
              used += widths[i];
              continue;
            }
            if (room > 0) {
              spans.add(_spanFor(context, runs[i], maxWidth: room));
            }
            break;
          }
        }

        return Text.rich(
          TextSpan(style: effective, children: spans),
          maxLines: 1,
          // The runs already fit (or the last one is capped), so the paragraph
          // must not ellipsize on its own: that drops a placeholder on the cut.
          overflow: TextOverflow.clip,
          textAlign: textAlign,
          softWrap: false,
          textHeightBehavior: heightBehavior,
          semanticsLabel: label,
        );
      },
    );
  }

  InlineSpan _spanFor(BuildContext context, _TitleRun run, {double? maxWidth}) {
    if (!run.isCode) {
      if (maxWidth == null) {
        return TextSpan(text: run.text, style: run.style);
      }
      return _PlainWidgetSpan(
        plain: run.text,
        child: SizedBox(
          width: maxWidth,
          child: Text(
            run.text,
            style: run.style,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }
    return _chipSpan(
      context,
      code: run.text,
      style: run.style,
      maxWidth: maxWidth,
    );
  }
}
