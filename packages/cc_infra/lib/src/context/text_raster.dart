import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cc_infra/src/context/glyph_font.dart';

/// One rendered page of text.
class RasterFrame {
  /// Creates a [RasterFrame].
  const RasterFrame({
    required this.pngBytes,
    required this.width,
    required this.height,
    required this.lines,
  });

  /// The encoded PNG.
  final Uint8List pngBytes;

  /// Pixel width.
  final int width;

  /// Pixel height.
  final int height;

  /// How many text lines it carries.
  final int lines;

  /// Base64, ready for a provider image block.
  String get base64Data => base64Encode(pngBytes);
}

/// Renders text onto dense pages of pixel glyphs.
///
/// **Why anyone would do this.** A vision model bills an image at a flat or
/// area-proportional rate that has nothing to do with how many characters are
/// in it. Twelve thousand characters of discarded conversation cost twelve
/// thousand characters' worth of text tokens; the same characters rendered onto
/// one page cost one image. Below a certain density that trade is a loss — the
/// point of a 5x9 cell is to be well past it.
///
/// **No model call, no key, no network.** That is what makes this the one
/// compaction strategy that is safe during overflow RECOVERY: a summarizing
/// compactor has to call the model to shrink the context, and the call it makes
/// is the one that just overflowed.
class TextRasterizer {
  /// Creates a [TextRasterizer].
  const TextRasterizer({
    this.columns = 300,
    this.rows = 200,
    this.scale = 1,
  });

  /// Characters per line.
  final int columns;

  /// Lines per page.
  final int rows;

  /// Integer pixel scale.
  ///
  /// One is legible to a model and illegible to a person; larger costs
  /// proportionally more area on the providers that bill by area and nothing
  /// on the ones that bill flat.
  final int scale;

  /// Page width in pixels.
  int get pageWidth => columns * kGlyphWidth * scale;

  /// Renders [text] into as many pages as it needs.
  List<RasterFrame> render(String text) {
    final lines = wrap(normalizeForRaster(text), columns);
    // Blank-only input renders nothing rather than a blank page: `''.split`
    // yields one empty line, and a page of nothing still costs a full image.
    while (lines.isNotEmpty && lines.last.trim().isEmpty) {
      lines.removeLast();
    }
    if (lines.isEmpty) {
      return const [];
    }
    final frames = <RasterFrame>[];
    for (var start = 0; start < lines.length; start += rows) {
      final page = lines.sublist(
        start,
        start + rows > lines.length ? lines.length : start + rows,
      );
      frames.add(_renderPage(page));
    }
    return frames;
  }

  RasterFrame _renderPage(List<String> lines) {
    // The page is exactly as tall as the lines it holds. A fixed-height page
    // pads the tail with blank rows, and on an area-billed provider those blank
    // rows are paid for at the same rate as text.
    final width = pageWidth;
    final height = lines.length * kGlyphHeight * scale;
    // 1 byte per pixel, 0 = ink, 255 = paper. Grayscale rather than 1-bit:
    // the PNG is deflated either way and a byte-per-pixel bitmap of mostly
    // identical bytes compresses to about the same size, while being far
    // simpler to get right.
    final pixels = Uint8List(width * height)..fillRange(0, width * height, 255);

    for (var row = 0; row < lines.length; row++) {
      final line = lines[row];
      for (var col = 0; col < line.length && col < columns; col++) {
        final code = line.codeUnitAt(col);
        final index = code - kGlyphFirst;
        if (index < 0 || index >= kGlyphColumns.length) {
          continue;
        }
        final glyph = kGlyphColumns[index];
        for (var gx = 0; gx < kGlyphWidth; gx++) {
          final bits = glyph[gx];
          if (bits == 0) {
            continue;
          }
          for (var gy = 0; gy < kGlyphHeight; gy++) {
            if (bits & (1 << gy) == 0) {
              continue;
            }
            final px = (col * kGlyphWidth + gx) * scale;
            final py = (row * kGlyphHeight + gy) * scale;
            for (var sy = 0; sy < scale; sy++) {
              final offset = (py + sy) * width + px;
              for (var sx = 0; sx < scale; sx++) {
                pixels[offset + sx] = 0;
              }
            }
          }
        }
      }
    }

    return RasterFrame(
      pngBytes: encodeGrayscalePng(pixels, width, height),
      width: width,
      height: height,
      lines: lines.length,
    );
  }

  /// Hard-wraps [text] at [width] columns, keeping its own line breaks.
  static List<String> wrap(String text, int width) {
    final out = <String>[];
    for (final line in text.split('\n')) {
      if (line.isEmpty) {
        out.add('');
        continue;
      }
      for (var i = 0; i < line.length; i += width) {
        out.add(line.substring(i, i + width > line.length ? line.length : i + width));
      }
    }
    return out;
  }
}

/// Folds text down to what the 5x9 ASCII font can actually draw.
///
/// **Every substitution here is a character that would otherwise render as a
/// blank.** A missing glyph is not a cosmetic problem: a run of invisible
/// characters is a hole in the text the model is reading back, and it cannot
/// tell a hole from a space. So box drawing becomes ASCII rules, smart quotes
/// become dumb ones, an em dash becomes a hyphen, and anything still
/// unrenderable becomes `?` — visible, and honest about being lossy.
String normalizeForRaster(String text) {
  final buffer = StringBuffer();
  // ANSI escapes first: a terminal transcript is full of them and they are
  // pure noise once the colour is gone.
  final stripped = text.replaceAll(RegExp(r'\x1B\[[0-9;?]*[ -/]*[@-~]'), '');
  for (final rune in stripped.runes) {
    final mapped = _fold[rune];
    if (mapped != null) {
      buffer.write(mapped);
      continue;
    }
    if (rune == 0x0A || rune == 0x09) {
      buffer.writeCharCode(rune == 0x09 ? 0x20 : rune);
      continue;
    }
    if (rune >= kGlyphFirst && rune <= kGlyphLast) {
      buffer.writeCharCode(rune);
      continue;
    }
    // Decorative and invisible characters are DROPPED rather than replaced:
    // a page of `?` where the emoji were is worse than the emoji being gone.
    if (_isDroppable(rune)) {
      continue;
    }
    buffer.write('?');
  }
  return buffer.toString();
}

bool _isDroppable(int rune) =>
    // Emoji and pictographs.
    (rune >= 0x1F300 && rune <= 0x1FAFF) ||
    (rune >= 0x2600 && rune <= 0x27BF) ||
    // Variation selectors, zero-width joiners and friends.
    (rune >= 0xFE00 && rune <= 0xFE0F) ||
    rune == 0x200B ||
    rune == 0x200D ||
    rune == 0xFEFF;

const Map<int, String> _fold = {
  0x2018: "'", 0x2019: "'", 0x201A: "'", 0x201B: "'",
  0x201C: '"', 0x201D: '"', 0x201E: '"',
  0x2013: '-', 0x2014: '-', 0x2015: '-', 0x2212: '-',
  0x2026: '...', 0x00A0: ' ', 0x2022: '*', 0x00B7: '.',
  0x2192: '->', 0x2190: '<-', 0x2194: '<->', 0x21D2: '=>',
  0x2264: '<=', 0x2265: '>=', 0x2260: '!=', 0x00D7: 'x',
  0x2713: 'v', 0x2717: 'x', 0x2705: 'v', 0x274C: 'x',
  // Box drawing — common in tool output, and every one of them is otherwise
  // an invisible hole in a table.
  0x2500: '-', 0x2501: '-', 0x2502: '|', 0x2503: '|',
  0x250C: '+', 0x2510: '+', 0x2514: '+', 0x2518: '+',
  0x251C: '+', 0x2524: '+', 0x252C: '+', 0x2534: '+', 0x253C: '+',
  0x2550: '=', 0x2551: '|', 0x2588: '#', 0x2591: '.', 0x2592: '.',
  0x2593: '#', 0x25CF: '*', 0x25CB: 'o', 0x25A0: '#', 0x25A1: '[',
};

/// Encodes an 8-bit grayscale bitmap as a PNG.
///
/// **Hand-rolled rather than a package.** A PNG is a fixed header, one
/// zlib-deflated block of scanlines and a CRC per chunk — and `dart:io` already
/// ships the deflater. An image package would pull an encoder for two dozen
/// formats to write the one we need, in a server binary where every dependency
/// is also a platform to build it on.
Uint8List encodeGrayscalePng(Uint8List pixels, int width, int height) {
  final out = BytesBuilder();
  out.add(const [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);

  final ihdr = BytesBuilder()
    ..add(_u32(width))
    ..add(_u32(height))
    ..add(const [
      8, // bit depth
      0, // colour type: grayscale
      0, // compression: deflate
      0, // filter: adaptive
      0, // interlace: none
    ]);
  out.add(_chunk('IHDR', ihdr.takeBytes()));

  // Every scanline carries filter byte 0 (None). Filtering exists to help the
  // deflater find structure in photographic data; text on a flat background is
  // already long runs of one value, which deflate handles better than any
  // filter would.
  final raw = Uint8List((width + 1) * height);
  for (var y = 0; y < height; y++) {
    final dst = y * (width + 1);
    raw[dst] = 0;
    raw.setRange(dst + 1, dst + 1 + width, pixels, y * width);
  }
  out.add(_chunk('IDAT', Uint8List.fromList(ZLibEncoder().convert(raw))));
  out.add(_chunk('IEND', Uint8List(0)));
  return out.takeBytes();
}

Uint8List _chunk(String type, Uint8List data) {
  final body = BytesBuilder()
    ..add(ascii.encode(type))
    ..add(data);
  final bytes = body.takeBytes();
  return Uint8List.fromList([
    ..._u32(data.length),
    ...bytes,
    ..._u32(_crc32(bytes)),
  ]);
}

List<int> _u32(int value) => [
  (value >> 24) & 0xFF,
  (value >> 16) & 0xFF,
  (value >> 8) & 0xFF,
  value & 0xFF,
];

final Uint32List _crcTable = _buildCrcTable();

Uint32List _buildCrcTable() {
  final table = Uint32List(256);
  for (var n = 0; n < 256; n++) {
    var c = n;
    for (var k = 0; k < 8; k++) {
      c = (c & 1) != 0 ? 0xEDB88320 ^ (c >> 1) : c >> 1;
    }
    table[n] = c;
  }
  return table;
}

int _crc32(Uint8List bytes) {
  var crc = 0xFFFFFFFF;
  for (final byte in bytes) {
    crc = _crcTable[(crc ^ byte) & 0xFF] ^ (crc >> 8);
  }
  return (crc ^ 0xFFFFFFFF) & 0xFFFFFFFF;
}
