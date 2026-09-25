import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Test hook for the trailing-advance measurement. Null in production.
///
/// Widget tests draw with the Ahem font, whose advance is the em square, so
/// the real measurement reports no surplus there. Tests that need to see the
/// split set this and clear it when they finish.
@visibleForTesting
double? Function(TextStyle style, TextScaler scaler)? debugEmojiTrailingGap;

final _gapCache = <String, double>{};

/// Drops the measured trailing-gap cache. For tests only.
@visibleForTesting
void debugResetEmojiAdvanceCache() => _gapCache.clear();

/// Splits [text] so an emoji's surplus advance is reclaimed only when the
/// following glyph would otherwise touch it.
///
/// On macOS and iOS, Apple Color Emoji has a wider advance than its em square.
/// Negative letter spacing can pull adjacent glyphs into that surplus. Before
/// whitespace, however, the advance is part of the visible gap: reclaiming it
/// (sometimes once per code point in a variation-selector sequence) makes a
/// heading like "🖼️ Screenshots" run together. Preserve it there. A trailing
/// emoji still loses the surplus for alignment in centered cells.
///
/// A font whose advance is already the em measures no surplus and the text
/// stays one span. Windows and Linux are left alone.
List<TextSpan> textSpansTighteningEmoji(
  String text, {
  required TextStyle style,
  required TextScaler textScaler,
}) {
  if (text.isEmpty || !_containsEmoji(text)) {
    return [TextSpan(text: text)];
  }
  final gap = emojiTrailingGap(style, textScaler);
  if (gap == null) {
    return [TextSpan(text: text)];
  }
  final spacing = TextStyle(letterSpacing: -gap);
  final spans = <TextSpan>[];
  final buf = StringBuffer();
  var tightened = false;
  void flush() {
    if (buf.isEmpty) {
      return;
    }
    spans.add(
      TextSpan(text: buf.toString(), style: tightened ? spacing : null),
    );
    buf.clear();
  }

  final clusters = text.characters.iterator;
  clusters.moveNext();
  var cluster = clusters.current;
  while (true) {
    final hasNext = clusters.moveNext();
    final next = hasNext ? clusters.current : null;
    final tighten =
        _emojiCluster(cluster) && (next == null || next.trim().isNotEmpty);
    if (buf.isNotEmpty && tighten != tightened) {
      flush();
    }
    tightened = tighten;
    buf.write(cluster);
    if (!hasNext) {
      break;
    }
    cluster = next!;
  }
  flush();
  return spans;
}

/// How many pixels of empty advance follow a color emoji at [style]'s size,
/// or null when there is nothing worth reclaiming.
@visibleForTesting
double? emojiTrailingGap(TextStyle style, TextScaler textScaler) {
  final override = debugEmojiTrailingGap;
  if (override != null) {
    final gap = override(style, textScaler);
    if (gap == null || gap < 0.5) {
      return null;
    }
    return gap;
  }
  final size = style.fontSize;
  if (size == null || size <= 0 || !_appleColorEmoji) {
    return null;
  }
  final key =
      '${style.fontFamily}\u0000${style.fontFamilyFallback?.join('\u0001')}\u0000'
      '${style.fontWeight}\u0000$size\u0000$textScaler';
  final cached = _gapCache[key];
  if (cached != null) {
    return cached == 0 ? null : cached;
  }
  final painter = TextPainter(
    text: TextSpan(
      text: '😁',
      style: style.copyWith(letterSpacing: 0, wordSpacing: 0),
    ),
    textDirection: TextDirection.ltr,
    textScaler: textScaler,
  )..layout();
  final advance = painter.width;
  painter.dispose();
  // Letter spacing is not scaled with the font, so the surplus has to be in
  // the already-scaled pixel size the glyph will actually occupy.
  final gap = advance - textScaler.scale(size);
  final stored = gap >= 0.5 ? gap : 0.0;
  _gapCache[key] = stored;
  return stored == 0 ? null : stored;
}

/// Apple Color Emoji is the font with the surplus advance. Other emoji
/// fonts (and the test font) are left alone.
bool get _appleColorEmoji => switch (defaultTargetPlatform) {
  TargetPlatform.iOS || TargetPlatform.macOS => true,
  _ => false,
};

/// A grapheme drawn from the color-emoji font: a supplementary-plane
/// pictograph, or a sequence forced into emoji presentation (keycaps,
/// U+FE0F). BMP dingbats such as check marks stay in the text font — those
/// advances are already tight, and pulling the next glyph in would overlap.
bool _containsEmoji(String text) {
  for (final rune in text.runes) {
    if (_emojiRune(rune)) {
      return true;
    }
  }
  return false;
}

bool _emojiCluster(String cluster) {
  for (final rune in cluster.runes) {
    if (_emojiRune(rune)) {
      return true;
    }
  }
  return false;
}

bool _emojiRune(int rune) =>
    rune == 0xFE0F || rune == 0x20E3 || (rune >= 0x1F000 && rune <= 0x1FAFF);
