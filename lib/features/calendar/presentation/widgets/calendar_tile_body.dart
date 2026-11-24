import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// The text of a timed event tile, fitted to the tile's own size.
///
/// A tile is as tall as its event is long, so the text has to follow the
/// height instead of the other way round: the title gets exactly the lines
/// that fit and ends in an ellipsis, rather than wrapping onto lines the tile
/// clips away. The time range sits under the title when there is a line for
/// it, and trails the title on the same line when there is not. A title is
/// never broken inside a word; the line that would break ends in an ellipsis
/// instead.
class CalendarTimedTileBody extends StatelessWidget {
  /// Creates a [CalendarTimedTileBody].
  const CalendarTimedTileBody({
    super.key,
    required this.title,
    required this.timeLabel,
    required this.titleColor,
    required this.timeColor,
    this.strikethrough = false,
  });

  /// The event title.
  final String title;

  /// The start–end range, or null when the tile shows no time.
  final String? timeLabel;

  /// The title color.
  final Color titleColor;

  /// The time range color.
  final Color timeColor;

  /// Whether the title is struck through (a cancelled event).
  final bool strikethrough;

  static const double _titleSize = 11;
  static const double _timeSize = 10;
  static const double _lineHeight = 1.2;
  static const double _horizontalPadding = 5;
  static const double _verticalPadding = 3;
  static const double _timeGap = 1;

  /// The most title lines an unbounded tile shows.
  static const int _unboundedLines = 3;

  @override
  Widget build(BuildContext context) {
    final titleStyle = TextStyle(
      fontSize: _titleSize,
      height: _lineHeight,
      fontWeight: FontWeight.w500,
      color: titleColor,
      decoration: strikethrough ? TextDecoration.lineThrough : null,
    );
    final timeStyle = TextStyle(
      fontSize: _timeSize,
      height: _lineHeight,
      fontWeight: FontWeight.w400,
      color: timeColor,
      decoration: TextDecoration.none,
    );
    // A forced strut keeps every line at the height the fit below assumes,
    // whatever an emoji or a fallback font would otherwise add to it.
    const strut = StrutStyle(
      fontSize: _titleSize,
      height: _lineHeight,
      forceStrutHeight: true,
    );
    final time = timeLabel;

    return LayoutBuilder(
      builder: (context, constraints) {
        final scaler = MediaQuery.textScalerOf(context);
        final titleLine = scaler.scale(_titleSize) * _lineHeight;
        final timeLine = scaler.scale(_timeSize) * _lineHeight + _timeGap;
        final height = constraints.maxHeight;
        final width = math.max(
          0.0,
          constraints.maxWidth - 2 * _horizontalPadding,
        );

        // A tile shorter than one padded line gives up padding before text.
        final verticalPadding = height.isFinite
            ? ((height - titleLine) / 2).clamp(0.0, _verticalPadding)
            : _verticalPadding;
        final inner = height - 2 * verticalPadding;
        // Half a pixel of slack: kalender's tile heights are fractional.
        final stacked =
            time != null &&
            (!height.isFinite || inner + 0.5 >= titleLine + timeLine);
        var lines = height.isFinite
            ? math.max(
                1,
                ((inner - (stacked ? timeLine : 0) + 0.5) / titleLine).floor(),
              )
            : _unboundedLines;
        if (lines > 1) {
          lines = _linesBeforeWordBreak(
            context,
            style: titleStyle,
            strut: strut,
            scaler: scaler,
            width: width,
            maxLines: lines,
          );
        }

        final Widget content;
        if (stacked) {
          content = Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: lines,
                overflow: TextOverflow.ellipsis,
                strutStyle: strut,
                style: titleStyle,
              ),
              Padding(
                padding: const EdgeInsets.only(top: _timeGap),
                child: Text(
                  time,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  style: timeStyle,
                ),
              ),
            ],
          );
        } else {
          content = Text.rich(
            TextSpan(
              children: [
                TextSpan(text: title, style: titleStyle),
                if (time != null) TextSpan(text: '  $time', style: timeStyle),
              ],
            ),
            maxLines: lines,
            overflow: TextOverflow.ellipsis,
            strutStyle: strut,
          );
        }

        // The content lays out at its natural height and the tile clips it, so
        // a tile too short for even one line never overflows.
        return ClipRect(
          child: OverflowBox(
            alignment: AlignmentDirectional.topStart,
            minHeight: 0,
            maxHeight: double.infinity,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: _horizontalPadding,
                vertical: verticalPadding,
              ),
              child: content,
            ),
          ),
        );
      },
    );
  }

  /// How many of [maxLines] the title can use before a line would end inside
  /// a word. A narrow tile otherwise wraps "Monthly" as "Month" / "ly".
  int _linesBeforeWordBreak(
    BuildContext context, {
    required TextStyle style,
    required StrutStyle strut,
    required TextScaler scaler,
    required double width,
    required int maxLines,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: title,
        style: DefaultTextStyle.of(context).style.merge(style),
      ),
      textDirection: Directionality.of(context),
      textScaler: scaler,
      locale: Localizations.maybeLocaleOf(context),
      strutStyle: strut,
      maxLines: maxLines,
    )..layout(maxWidth: width);
    try {
      final metrics = painter.computeLineMetrics();
      // The last laid-out line either ends the title or ends in the ellipsis.
      for (var i = 0; i < metrics.length - 1; i++) {
        final line = metrics[i];
        final onLine = painter.getPositionForOffset(
          Offset(0, line.baseline - line.ascent / 2),
        );
        final end = painter.getLineBoundary(onLine).end;
        if (end <= 0 || end >= title.length) {
          continue;
        }
        final word = painter.getWordBoundary(TextPosition(offset: end));
        if (word.start < end && end < word.end) {
          return i + 1;
        }
      }
      return maxLines;
    } finally {
      painter.dispose();
    }
  }
}
