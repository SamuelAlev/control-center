/// Top-level vision compactor: serialize → plan → render PNG frames.
///
/// [VisionCompactor] ties the pipeline together. Given new conversation entries
/// (and optionally a previous [VisionArchive] to extend), it serializes the
/// history to normalized bitmap text, plans a foveated frame layout, stamps the
/// pixel font onto a grayscale buffer per frame, and encodes each buffer to a
/// deterministic PNG. The result is a [VisionArchive] carrying the PNG frames,
/// the full source text, and a short human-readable summary. The whole pass is
/// local and deterministic — identical inputs always produce byte-identical
/// PNGs. Ported from oh-my-pi's `snapcompact.compact`.
library;

import 'dart:typed_data';

import 'package:cc_infra/src/messaging/vision/bitmap_font.dart';
import 'package:cc_infra/src/messaging/vision/png_encoder.dart';
import 'package:cc_infra/src/messaging/vision/vision_normalize.dart';
import 'package:cc_infra/src/messaging/vision/vision_plan.dart';
import 'package:cc_infra/src/messaging/vision/vision_serialize.dart';
import 'package:cc_infra/src/messaging/vision/vision_shapes.dart';

/// Default upper bound on archive frames carried per compaction.
const int maxFramesDefault = 8;

/// Separator inserted between previously archived source and newly serialized
/// history when extending an archive. Rendered as a hard line break.
const String _archiveSeparator = newlineGlyph;

/// Grayscale value for normal (black) glyph ink.
const int _inkBlack = 0x00;

/// Grayscale value for dimmed glyph ink (mid-gray, used inside dim spans).
const int _inkDim = 0x80;

/// Grayscale value for the frame background (white).
const int _background = 0xFF;

/// A developed vision archive: PNG frames plus the source they were rendered
/// from and a short summary describing the compaction.
class VisionArchive {
  /// Creates a [VisionArchive].
  const VisionArchive({
    required this.frames,
    required this.fullSourceText,
    required this.totalChars,
    required this.truncatedRegions,
    required this.summary,
  });

  /// Rendered PNG frames, ordered oldest → newest. Each element is the raw
  /// bytes of one grayscale PNG.
  final List<Uint8List> frames;

  /// The full normalized source text the frames were rendered from (oldest →
  /// newest), used to extend the archive on the next compaction.
  final String fullSourceText;

  /// Total characters of source represented by this archive.
  final int totalChars;

  /// How many middle regions were dropped to fit the frame budget.
  final int truncatedRegions;

  /// Short human-readable summary of the compaction.
  final String summary;
}

/// Renders discarded conversation history into deterministic bitmap PNG frames.
class VisionCompactor {
  /// Creates a [VisionCompactor].
  const VisionCompactor();

  /// Compacts [newEntries] (optionally extending [previous]) into a
  /// [VisionArchive] for the reader described by [shape].
  ///
  /// The new entries are serialized; if [previous] is non-null its source text
  /// is prepended (with a hard-break separator) so the archive ages coherently.
  /// The combined text is planned into at most [maxFrames] foveated frames and
  /// each slice is rendered to a PNG. Deterministic: the same arguments always
  /// produce byte-identical frames.
  VisionArchive compact({
    required List<VisionEntry> newEntries,
    required VisionShape shape,
    VisionArchive? previous,
    int maxFrames = maxFramesDefault,
  }) {
    final serialized = serializeEntries(newEntries);

    final String sourceText;
    if (previous != null && previous.fullSourceText.isNotEmpty) {
      sourceText = serialized.isEmpty
          ? previous.fullSourceText
          : '${previous.fullSourceText}$_archiveSeparator$serialized';
    } else {
      sourceText = serialized;
    }

    final plan = planArchive(
      sourceText: sourceText,
      shape: shape,
      maxFrames: maxFrames,
    );

    final frames = <Uint8List>[
      for (final slice in plan.slices) _renderSlice(slice, shape),
    ];

    final totalChars = sourceText.length;
    final summary = _buildSummary(
      totalChars: totalChars,
      frameCount: frames.length,
      truncatedRegions: plan.truncatedRegions,
    );

    return VisionArchive(
      frames: frames,
      fullSourceText: sourceText,
      totalChars: totalChars,
      truncatedRegions: plan.truncatedRegions,
      summary: summary,
    );
  }

  /// Renders one [slice] onto a grayscale frame buffer and encodes it to PNG.
  ///
  /// High-quality slices use the shape's native [VisionShape.cellWidth] /
  /// [VisionShape.cellHeight]; low-quality slices halve both (min 8px, the
  /// glyph size) to pack the dense middle. Glyphs are stamped left-to-right,
  /// wrapping at the column capacity and advancing a row at each [newlineGlyph]
  /// or wrap. Spans between [dimOn]/[dimOff] draw in mid-gray.
  Uint8List _renderSlice(VisionFrameSlice slice, VisionShape shape) {
    final size = shape.frameSize;
    final cellWidth = slice.highQuality
        ? shape.cellWidth
        : (shape.cellWidth ~/ 2).clamp(glyphWidth, shape.cellWidth);
    final cellHeight = slice.highQuality
        ? shape.cellHeight
        : (shape.cellHeight ~/ 2).clamp(glyphHeight, shape.cellHeight);
    final cols = size ~/ cellWidth;
    final rows = size ~/ cellHeight;

    final pixels = Uint8List(size * size)..fillRange(0, size * size, _background);

    var col = 0;
    var row = 0;
    var ink = _inkBlack;

    for (final rune in slice.text.runes) {
      final ch = String.fromCharCode(rune);
      if (ch == dimOn) {
        ink = _inkDim;
        continue;
      }
      if (ch == dimOff) {
        ink = _inkBlack;
        continue;
      }
      if (ch == newlineGlyph) {
        col = 0;
        row++;
        if (row >= rows) {
          break;
        }
        continue;
      }
      if (rune < firstPrintableAscii || rune > lastPrintableAscii) {
        // Normalization should have folded these out; skip defensively.
        continue;
      }
      if (col >= cols) {
        col = 0;
        row++;
        if (row >= rows) {
          break;
        }
      }
      _stampGlyph(
        pixels: pixels,
        size: size,
        originX: col * cellWidth,
        originY: row * cellHeight,
        codePoint: rune,
        ink: ink,
      );
      col++;
    }

    return encodeGrayscalePng(width: size, height: size, pixels: pixels);
  }

  /// Stamps the 8x8 glyph for [codePoint] into [pixels] at the cell origin
  /// ([originX], [originY]) using grayscale [ink].
  void _stampGlyph({
    required Uint8List pixels,
    required int size,
    required int originX,
    required int originY,
    required int codePoint,
    required int ink,
  }) {
    for (var gy = 0; gy < glyphHeight; gy++) {
      final py = originY + gy;
      if (py < 0 || py >= size) {
        continue;
      }
      final rowBase = py * size;
      for (var gx = 0; gx < glyphWidth; gx++) {
        if (!glyphPixel(codePoint, gx, gy)) {
          continue;
        }
        final px = originX + gx;
        if (px < 0 || px >= size) {
          continue;
        }
        pixels[rowBase + px] = ink;
      }
    }
  }

  /// Builds the short archive summary line.
  String _buildSummary({
    required int totalChars,
    required int frameCount,
    required int truncatedRegions,
  }) {
    final frameWord = frameCount == 1 ? 'frame' : 'frames';
    final base =
        '[Vision-compacted $totalChars chars of earlier history into '
        '$frameCount $frameWord]';
    if (truncatedRegions > 0) {
      final regionWord = truncatedRegions == 1 ? 'region' : 'regions';
      return '$base ($truncatedRegions $regionWord dropped)';
    }
    return base;
  }
}
