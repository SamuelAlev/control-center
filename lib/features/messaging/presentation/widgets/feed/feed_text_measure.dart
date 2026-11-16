import 'dart:math' as math;

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/shared/widgets/markdown/markdown_style.dart';
import 'package:flutter/widgets.dart';

part 'feed_text_blocks.dart';
part 'feed_text_parse.dart';

/// Source characters [FeedTextMeasurer.proseHeight] lays out precisely; the
/// rest of a longer message is extrapolated linearly by character count.
const int kFeedMeasureCharBudget = 20000;

/// Measures chat text without building widgets: the cheap half of the feed's
/// height model.
///
/// [proseHeight] estimates the rendered height of a chat markdown body by
/// splitting the source into blocks the way the chat renderer lays them out —
/// fenced code (mono, never wrapped, collapsed past 24 lines), ATX headings,
/// list items, blockquotes, tables and paragraphs — and laying out each
/// non-code block with one reused [TextPainter] at its effective width. The
/// spacing and chrome constants default to the regular chat register of
/// `appMarkdownStyle` and the shared code block; [FeedTextMeasurer.of] wires
/// the live styles.
///
/// The result is the markdown body only: bubble padding, sender header and
/// timestamp line are the caller's to add.
class FeedTextMeasurer {
  /// Creates a measurer laying text out with [bodyStyle] (paragraphs, lists,
  /// quotes) and [codeStyle] (fenced code lines), scaled by [textScaler].
  ///
  /// `headingStyles` and `headingPaddings` (top padding) are keyed by heading
  /// level; a missing style falls back to the body scaled like the chat h1–h3.
  FeedTextMeasurer({
    required this.textScaler,
    required this.bodyStyle,
    required this.codeStyle,
    this.textDirection = TextDirection.ltr,
    this._headingStyles = const {},
    this._headingPaddings = _defaultHeadingPadding,
    this.blockSpacing = 10,
    this.listItemGap = 4,
    this.listIndent = 28,
  });

  /// Resolves the styles the feed's chat bubbles render with: the regular
  /// `appMarkdownStyle` register (with [codeFontFamily], the user's code font,
  /// when the caller has it), the ambient text scaler and direction.
  factory FeedTextMeasurer.of(BuildContext context, {String? codeFontFamily}) {
    final md = appMarkdownStyle(context, codeFontFamily: codeFontFamily);
    return FeedTextMeasurer(
      textScaler: MediaQuery.maybeTextScalerOf(context) ?? TextScaler.noScaling,
      bodyStyle: md.paragraph ?? CcTypography.body,
      codeStyle:
          md.code ?? appCodeTextStyle(context, codeFontFamily: codeFontFamily),
      textDirection: Directionality.maybeOf(context) ?? TextDirection.ltr,
      headingStyles: {
        for (var level = 1; level <= 6; level++) level: ?md.headingStyle(level),
      },
      headingPaddings: {
        for (var level = 1; level <= 6; level++)
          if (md.headingPadding(level) case final padding?)
            level: padding.vertical,
      },
      blockSpacing: md.blockSpacing,
      listItemGap: md.listItemGap,
      listIndent: md.listIndent,
    );
  }

  /// Scales every laid-out font size (not the fixed chrome around blocks).
  final TextScaler textScaler;

  /// Style of paragraphs, list items, quotes and table cells.
  final TextStyle bodyStyle;

  /// Style of fenced code lines; only its line height is used.
  final TextStyle codeStyle;

  /// Direction text is laid out in.
  final TextDirection textDirection;

  /// Gap between top-level blocks, and between items of a loose list.
  final double blockSpacing;

  /// Gap between items of a tight list.
  final double listItemGap;

  /// Width of the list marker column; nested levels indent by it again.
  final double listIndent;

  final Map<int, TextStyle> _headingStyles;
  final Map<int, double> _headingPaddings;

  late final double _codeLineHeight = _preferredLineHeight(codeStyle);

  /// Estimated rendered height of [markdownSource] laid out [width] wide.
  ///
  /// Bounded work: the first [kFeedMeasureCharBudget] characters (rounded to
  /// whole blocks) are laid out, and a longer source is extrapolated linearly
  /// by character count. Returns 0 for an empty source.
  double proseHeight(String markdownSource, double width) {
    if (markdownSource.isEmpty) {
      return 0;
    }
    final parse = _parseBlocks(markdownSource, kFeedMeasureCharBudget);
    if (parse.blocks.isEmpty) {
      return 0;
    }
    final painter = TextPainter(
      textDirection: textDirection,
      textScaler: textScaler,
    );
    try {
      final height = _blocksHeight(parse.blocks, math.max(1, width), painter);
      if (parse.consumedChars >= markdownSource.length ||
          parse.consumedChars == 0) {
        return height;
      }
      return height * markdownSource.length / parse.consumedChars;
    } finally {
      painter.dispose();
    }
  }

  /// Height of [text] wrapped at [width] in [style] (the body style when
  /// null), optionally clamped to [maxLines]. Returns 0 for empty text.
  double plainTextHeight(
    String text,
    double width, {
    TextStyle? style,
    int? maxLines,
  }) {
    if (text.isEmpty) {
      return 0;
    }
    final painter = TextPainter(
      text: TextSpan(text: text, style: style ?? bodyStyle),
      textDirection: textDirection,
      textScaler: textScaler,
      maxLines: maxLines,
    );
    try {
      painter.layout(maxWidth: math.max(1, width));
      return painter.height;
    } finally {
      painter.dispose();
    }
  }

  double _preferredLineHeight(TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: ' ', style: style),
      textDirection: textDirection,
      textScaler: textScaler,
    );
    try {
      painter.layout();
      return painter.preferredLineHeight;
    } finally {
      painter.dispose();
    }
  }

  double _blocksHeight(List<_Block> blocks, double width, TextPainter painter) {
    var total = 0.0;
    for (var i = 0; i < blocks.length; i++) {
      if (i > 0) {
        total += blockSpacing;
      }
      total += _blockHeight(blocks[i], width, painter);
    }
    return total;
  }

  double _blockHeight(_Block block, double width, TextPainter painter) {
    switch (block) {
      case _Paragraph(:final text):
        return _layout(painter, _stripInline(text), bodyStyle, width);
      case _Heading(:final level, :final text):
        final style = _headingStyles[level] ?? _fallbackHeading(level);
        return (_headingPaddings[level] ?? 0) +
            _layout(painter, _stripInline(text), style, width);
      case _Code():
        return _codeHeight(block);
      case _Rule():
        return _ruleExtent;
      case _Quote(:final inner):
        return _blockquoteVerticalPadding +
            _blocksHeight(
              inner,
              math.max(1, width - _blockquoteInset),
              painter,
            );
      case _ListBlock(:final items, :final tight):
        var total = 0.0;
        for (var i = 0; i < items.length; i++) {
          if (i > 0) {
            total += tight ? listItemGap : blockSpacing;
          }
          final item = items[i];
          final itemWidth = math.max(
            1.0,
            width - listIndent * (item.depth + 1),
          );
          // A marker-only item still renders one line (the bullet).
          total += math.max(
            _layout(painter, ' ', bodyStyle, itemWidth),
            _layout(painter, _stripInline(item.text), bodyStyle, itemWidth),
          );
        }
        return total;
      case _Table(:final rows):
        var total = 0.0;
        for (final cells in rows) {
          final columns = math.max(1, cells.length);
          final cellWidth = math.max(
            1.0,
            width / columns - _tableCellHorizontalPadding,
          );
          var rowHeight = _layout(painter, ' ', bodyStyle, cellWidth);
          for (final cell in cells) {
            rowHeight = math.max(
              rowHeight,
              _layout(painter, _stripInline(cell), bodyStyle, cellWidth),
            );
          }
          total += rowHeight + _tableCellVerticalPadding;
        }
        return total;
    }
  }

  /// Mirrors `_SharedCodeBlock`: an oversized block (over 50KB) renders its
  /// first 300 lines plus a notice; otherwise a block over 24 lines collapses
  /// to 16 behind a "Show more" row. A labelled fence adds the header.
  double _codeHeight(_Code block) {
    var lines = block.lineCount;
    var extra = block.labeled ? _codeBlockHeaderExtent : 0.0;
    if (block.chars > kSharedCodeBlockMaxHighlightChars) {
      if (lines > kSharedCodeBlockMaxLines) {
        lines = kSharedCodeBlockMaxLines;
        extra += _codeBlockTruncationNoticeExtent;
      }
    } else if (lines > kSharedCodeBlockCollapseThreshold) {
      lines = kSharedCodeBlockCollapsedLines;
      extra += _codeBlockCollapseRowExtent;
    }
    return lines * _codeLineHeight + _codeBlockVerticalChrome + extra;
  }

  TextStyle _fallbackHeading(int level) {
    final size = bodyStyle.fontSize ?? 14;
    return bodyStyle.copyWith(
      fontSize: size * (_defaultHeadingScale[level] ?? 1),
      fontWeight: FontWeight.w600,
      height: 1.3,
    );
  }

  double _layout(
    TextPainter painter,
    String text,
    TextStyle style,
    double width,
  ) {
    painter
      ..text = TextSpan(text: text.isEmpty ? ' ' : text, style: style)
      ..layout(maxWidth: width);
    return painter.height;
  }
}
