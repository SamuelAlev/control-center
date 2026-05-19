import 'dart:typed_data';

import 'package:cc_infra/src/messaging/vision/png_encoder.dart';
import 'package:test/test.dart';

/// Reads a big-endian uint32 from [bytes] at [offset].
int _be32(Uint8List bytes, int offset) =>
    (bytes[offset] << 24) |
    (bytes[offset + 1] << 16) |
    (bytes[offset + 2] << 8) |
    bytes[offset + 3];

/// Walks the PNG chunk stream, returning a map of chunk type → payload (first
/// occurrence) plus verifying each chunk's CRC-32 along the way.
Map<String, Uint8List> _parseChunks(Uint8List png) {
  final chunks = <String, Uint8List>{};
  var offset = 8; // skip signature
  while (offset + 8 <= png.length) {
    final length = _be32(png, offset);
    final type = String.fromCharCodes(png.sublist(offset + 4, offset + 8));
    final dataStart = offset + 8;
    final data = png.sublist(dataStart, dataStart + length);
    final storedCrc = _be32(png, dataStart + length);
    final crcInput = png.sublist(offset + 4, dataStart + length);
    expect(
      crc32(crcInput),
      storedCrc,
      reason: 'CRC mismatch for chunk $type',
    );
    chunks.putIfAbsent(type, () => data);
    offset = dataStart + length + 4;
    if (type == 'IEND') {
      break;
    }
  }
  return chunks;
}

void main() {
  group('encodeGrayscalePng', () {
    test('output starts with the 8-byte PNG signature', () {
      final png = encodeGrayscalePng(
        width: 2,
        height: 2,
        pixels: Uint8List.fromList(<int>[0, 255, 255, 0]),
      );
      expect(png.sublist(0, 8), pngSignature);
    });

    test('contains IHDR, IDAT, and IEND chunks with valid CRCs', () {
      final png = encodeGrayscalePng(
        width: 3,
        height: 4,
        pixels: Uint8List(12)..fillRange(0, 12, 128),
      );
      final chunks = _parseChunks(png);
      expect(chunks.containsKey('IHDR'), isTrue);
      expect(chunks.containsKey('IDAT'), isTrue);
      expect(chunks.containsKey('IEND'), isTrue);
    });

    test('IHDR encodes the declared width and height', () {
      const w = 17;
      const h = 23;
      final png = encodeGrayscalePng(
        width: w,
        height: h,
        pixels: Uint8List(w * h),
      );
      final ihdr = _parseChunks(png)['IHDR']!;
      expect(_be32(ihdr, 0), w);
      expect(_be32(ihdr, 4), h);
      expect(ihdr[8], 8); // bit depth
      expect(ihdr[9], 0); // grayscale color type
    });

    test('IEND chunk is empty', () {
      final png = encodeGrayscalePng(
        width: 1,
        height: 1,
        pixels: Uint8List.fromList(<int>[42]),
      );
      expect(_parseChunks(png)['IEND'], isEmpty);
    });

    test('is deterministic: identical pixels produce identical bytes', () {
      final pixels = Uint8List.fromList(
        List<int>.generate(64 * 64, (i) => i % 256),
      );
      final a = encodeGrayscalePng(width: 64, height: 64, pixels: pixels);
      final b = encodeGrayscalePng(
        width: 64,
        height: 64,
        pixels: Uint8List.fromList(pixels),
      );
      expect(a, b);
    });

    test('handles a large frame across multiple stored DEFLATE blocks', () {
      // 256x256 = 65536 samples + 256 filter bytes > 65535, forcing two blocks.
      const size = 256;
      final pixels = Uint8List(size * size)..fillRange(0, size * size, 200);
      final png = encodeGrayscalePng(
        width: size,
        height: size,
        pixels: pixels,
      );
      final chunks = _parseChunks(png);
      final ihdr = chunks['IHDR']!;
      expect(_be32(ihdr, 0), size);
      expect(_be32(ihdr, 4), size);
    });

    test('rejects a pixel buffer that disagrees with dimensions', () {
      expect(
        () => encodeGrayscalePng(
          width: 2,
          height: 2,
          pixels: Uint8List(3),
        ),
        throwsArgumentError,
      );
    });

    test('rejects non-positive dimensions', () {
      expect(
        () => encodeGrayscalePng(width: 0, height: 1, pixels: Uint8List(0)),
        throwsArgumentError,
      );
    });
  });

  group('crc32', () {
    test('matches the known IEEE check value for "123456789"', () {
      // The canonical CRC-32 check vector.
      final data = Uint8List.fromList('123456789'.codeUnits);
      expect(crc32(data), 0xCBF43926);
    });
  });
}
