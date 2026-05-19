import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cc_harness/messages.dart';
import 'package:cc_infra/src/context/glyph_font.dart';
import 'package:cc_infra/src/context/snapcompact.dart';
import 'package:cc_infra/src/context/text_raster.dart';
import 'package:test/test.dart';

/// Decodes an 8-bit grayscale PNG back to pixels.
///
/// Written here rather than pulled in: the encoder is the thing under test, and
/// checking it against a decoder we also wrote would only prove the two agree.
/// This one goes through `dart:io`'s inflater and reads the real chunk
/// structure, so a malformed header or a wrong CRC shows up as a failure rather
/// than as a picture nothing can open.
({int width, int height, Uint8List pixels}) decodePng(Uint8List bytes) {
  expect(
    bytes.sublist(0, 8),
    [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A],
    reason: 'PNG signature',
  );
  var offset = 8;
  var width = 0;
  var height = 0;
  final idat = BytesBuilder();
  while (offset < bytes.length) {
    final length =
        (bytes[offset] << 24) |
        (bytes[offset + 1] << 16) |
        (bytes[offset + 2] << 8) |
        bytes[offset + 3];
    final type = ascii.decode(bytes.sublist(offset + 4, offset + 8));
    final data = bytes.sublist(offset + 8, offset + 8 + length);
    if (type == 'IHDR') {
      width = (data[0] << 24) | (data[1] << 16) | (data[2] << 8) | data[3];
      height = (data[4] << 24) | (data[5] << 16) | (data[6] << 8) | data[7];
      expect(data[8], 8, reason: 'bit depth');
      expect(data[9], 0, reason: 'grayscale colour type');
    } else if (type == 'IDAT') {
      idat.add(data);
    } else if (type == 'IEND') {
      break;
    }
    offset += 12 + length;
  }
  final raw = Uint8List.fromList(
    ZLibDecoder().convert(idat.takeBytes()),
  );
  final pixels = Uint8List(width * height);
  for (var y = 0; y < height; y++) {
    final src = y * (width + 1);
    expect(raw[src], 0, reason: 'filter byte is None');
    pixels.setRange(y * width, y * width + width, raw, src + 1);
  }
  return (width: width, height: height, pixels: pixels);
}

/// Reads back a rendered page as text, by matching each cell against the font.
///
/// This is the property that actually matters and the only one worth a test:
/// that a model looking at the page can recover the characters. A test that
/// only checked "a PNG came out" would pass on a blank one.
String readBack(RasterFrame frame, {int columns = 300}) {
  final decoded = decodePng(frame.pngBytes);
  final rows = decoded.height ~/ kGlyphHeight;
  final buffer = StringBuffer();
  for (var row = 0; row < rows; row++) {
    for (var col = 0; col < columns; col++) {
      final cols = <int>[];
      for (var gx = 0; gx < kGlyphWidth; gx++) {
        var bits = 0;
        for (var gy = 0; gy < kGlyphHeight; gy++) {
          final x = col * kGlyphWidth + gx;
          final y = row * kGlyphHeight + gy;
          if (x >= decoded.width || y >= decoded.height) {
            continue;
          }
          if (decoded.pixels[y * decoded.width + x] == 0) {
            bits |= 1 << gy;
          }
        }
        cols.add(bits);
      }
      final index = kGlyphColumns.indexWhere((g) => _sameGlyph(g, cols));
      buffer.writeCharCode(index < 0 ? 0x3F : kGlyphFirst + index);
    }
    buffer.writeln();
  }
  return buffer.toString();
}

bool _sameGlyph(List<int> a, List<int> b) {
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}

HarnessMessage user(String text) => HarnessMessage.user(text);
HarnessMessage assistant(String text) => HarnessMessage.assistant(text);

void main() {
  group('normalizeForRaster', () {
    test('folds characters the font cannot draw', () {
      // A missing glyph is a HOLE in the text the model reads back, and it
      // cannot tell a hole from a space.
      expect(normalizeForRaster('“smart” — quotes'), '"smart" - quotes');
      expect(normalizeForRaster('a → b'), 'a -> b');
      expect(normalizeForRaster('┌──┐'), '+--+');
      expect(normalizeForRaster('x ≤ y ≠ z'), 'x <= y != z');
    });

    test('strips ANSI escapes', () {
      expect(
        normalizeForRaster('\x1B[31mred\x1B[0m text'),
        'red text',
      );
    });

    test('drops decorative characters rather than filling with question marks',
        () {
      expect(normalizeForRaster('done 🎉 now'), 'done  now');
    });

    test('keeps newlines and turns tabs into spaces', () {
      expect(normalizeForRaster('a\tb\nc'), 'a b\nc');
    });

    test('an unrenderable letter becomes a visible placeholder', () {
      // Visible and honest about being lossy, rather than silently absent.
      expect(normalizeForRaster('日本'), '??');
    });
  });

  group('rasterizer', () {
    test('produces a decodable PNG whose text reads back', () {
      const source = 'The quick brown fox jumps over the lazy dog.\n'
          'ALL CAPS 0123456789 !@#\$%^&*()';
      final frames = const TextRasterizer(columns: 60, rows: 20).render(source);
      expect(frames, hasLength(1));

      final text = readBack(frames.single, columns: 60);
      expect(text, contains('The quick brown fox jumps over the lazy dog.'));
      expect(text, contains(r'ALL CAPS 0123456789 !@#$%^&*()'));
    });

    test('the page is exactly as tall as the lines it holds', () {
      // A fixed-height page pads with blank rows, and on an area-billed
      // provider those rows cost the same as text.
      final frames = const TextRasterizer(columns: 40, rows: 50).render('a\nb');
      expect(frames.single.lines, 2);
      expect(frames.single.height, 2 * kGlyphHeight);
    });

    test('wraps long lines rather than clipping them', () {
      final frames = const TextRasterizer(columns: 10, rows: 50)
          .render('x' * 25);
      expect(frames.single.lines, 3);
      expect(readBack(frames.single, columns: 10).replaceAll('\n', ''),
          'x' * 25 + '     ');
    });

    test('paginates past the row cap', () {
      final frames = const TextRasterizer(columns: 20, rows: 5)
          .render(List.generate(12, (i) => 'line $i').join('\n'));
      expect(frames, hasLength(3));
      expect(frames.last.lines, 2);
    });

    test('empty input produces no pages', () {
      expect(const TextRasterizer().render(''), isEmpty);
    });

    test('is dense enough to be worth doing', () {
      // The whole premise: a page has to hold far more characters than an
      // image costs in tokens, or this loses to just sending the text.
      const shape = TextRasterizer(columns: 300, rows: 200);
      expect(shape.columns * shape.rows, greaterThan(50000));
      expect(shape.pageWidth, lessThanOrEqualTo(1568));
    });
  });

  group('snapFrameShapeFor', () {
    test('gives Gemini the widest page, because its billing is flat', () {
      final shape = snapFrameShapeFor('google/gemini-3-pro');
      expect(shape.billing, ImageBillingModel.flat);
      expect(shape.columns, greaterThan(snapFrameShapeFor('gpt-5').columns));
    });

    test('keeps downscaling processors under their threshold', () {
      final shape = snapFrameShapeFor('moonshot/kimi-k2');
      expect(shape.billing, ImageBillingModel.downscaling);
      expect(shape.pixelWidth, lessThan(1792));
    });

    test('an unknown model gets the conservative area shape', () {
      // Guessing generously on an area-billed provider spends real money.
      final shape = snapFrameShapeFor('some-new-model');
      expect(shape.billing, ImageBillingModel.area);
    });

    test('a null model id does not throw', () {
      expect(snapFrameShapeFor(null).billing, ImageBillingModel.area);
    });
  });

  group('Snapcompactor', () {
    List<HarnessMessage> history(int count) => [
      for (var i = 0; i < count; i++)
        i.isEven ? user('turn $i asks something') : assistant('turn $i answers'),
    ];

    test('keeps the head and tail verbatim and images the middle', () {
      final compactor = Snapcompactor(shape: snapFrameShapeFor('gpt-5'));
      final result = compactor.compact(history(30));

      expect(result.didCompact, isTrue);
      expect(result.messages, hasLength(2 + 1 + 6));
      expect(result.messages.first.textContent, contains('turn 0'));
      expect(result.messages.last.textContent, contains('turn 29'));
      expect(
        result.messages[2].content.whereType<HarnessImageBlock>(),
        isNotEmpty,
      );
    });

    test('does nothing to a short history', () {
      // A picture has a fixed cost floor; folding three short turns into one
      // costs more than the turns did.
      final compactor = Snapcompactor(shape: snapFrameShapeFor('gpt-5'));
      final short = history(8);
      final result = compactor.compact(short);
      expect(result.didCompact, isFalse);
      expect(result.messages, same(short));
    });

    test('the folded text is recoverable from the rendered page', () {
      const compactor = Snapcompactor(
        shape: SnapFrameShape(
          columns: 80,
          rows: 100,
          scale: 1,
          billing: ImageBillingModel.area,
        ),
      );
      final result = compactor.compact(history(30));
      final image = result.messages[2].content
          .whereType<HarnessImageBlock>()
          .first;
      final frame = RasterFrame(
        pngBytes: base64Decode(image.data),
        width: 0,
        height: 0,
        lines: 0,
      );
      final text = readBack(frame, columns: 80);
      expect(text, contains('turn 10 asks something'));
      expect(text, contains('turn 15 answers'));
    });

    test('re-renders from the retained SOURCE, never from the last pixels', () {
      // Imaging an image degrades the glyphs one generation per pass until
      // nothing can read them.
      final compactor = Snapcompactor(shape: snapFrameShapeFor('gpt-5'));
      final first = compactor.compact(history(30));
      expect(first.retainedSource, contains('turn 10'));

      final second = compactor.compact(
        [...first.messages, ...history(20)],
        retainedSource: first.retainedSource,
      );
      expect(
        second.retainedSource,
        contains('turn 10'),
        reason: 'the first pass\'s text survives into the second pass',
      );
    });

    test('the marker tells the model what it is looking at', () {
      final result = Snapcompactor(
        shape: snapFrameShapeFor('gpt-5'),
      ).compact(history(30));
      final marker = result.messages[2].content.whereType<HarnessTextBlock>()
          .first;
      expect(marker.text, contains('earlier messages'));
      expect(marker.text, contains('drawn rather than typed'));
    });

    test('the imaged block is a user turn, to keep the cache prefix', () {
      final result = Snapcompactor(
        shape: snapFrameShapeFor('gpt-5'),
      ).compact(history(30));
      expect(result.messages[2].role, HarnessRole.user);
    });
  });

  group('renderMessagesAsText', () {
    test('keeps tool calls and results, which are most of the bulk', () {
      final text = renderMessagesAsText([
        const HarnessMessage(
          role: HarnessRole.assistant,
          content: [
            HarnessToolUseBlock(
              id: 't1',
              name: 'read',
              input: {'path': 'lib/a.dart'},
            ),
          ],
        ),
        HarnessMessage.toolResults([
          const HarnessToolResultBlock(
            toolUseId: 't1',
            content: 'class A {}',
          ),
        ]),
      ]);
      expect(text, contains('[call read]'));
      expect(text, contains('lib/a.dart'));
      expect(text, contains('class A {}'));
    });

    test('drops reasoning, which nobody re-reads', () {
      final text = renderMessagesAsText([
        const HarnessMessage(
          role: HarnessRole.assistant,
          content: [
            HarnessThinkingBlock('private deliberation'),
            HarnessTextBlock('the answer'),
          ],
        ),
      ]);
      expect(text, isNot(contains('private deliberation')));
      expect(text, contains('the answer'));
    });
  });
}
