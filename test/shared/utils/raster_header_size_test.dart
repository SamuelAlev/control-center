import 'dart:typed_data';

import 'package:control_center/shared/utils/raster_header_size.dart';
import 'package:flutter_test/flutter_test.dart';

Uint8List _bytes(List<int> values) => Uint8List.fromList(values);

List<int> _u16be(int v) => [(v >> 8) & 0xFF, v & 0xFF];

List<int> _u16le(int v) => [v & 0xFF, (v >> 8) & 0xFF];

List<int> _u24le(int v) => [v & 0xFF, (v >> 8) & 0xFF, (v >> 16) & 0xFF];

List<int> _u32be(int v) => [
  (v >> 24) & 0xFF,
  (v >> 16) & 0xFF,
  (v >> 8) & 0xFF,
  v & 0xFF,
];

List<int> _u32le(int v) => [
  v & 0xFF,
  (v >> 8) & 0xFF,
  (v >> 16) & 0xFF,
  (v >> 24) & 0xFF,
];

Uint8List _png(int width, int height) => _bytes([
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
  ..._u32be(13),
  0x49, 0x48, 0x44, 0x52, // IHDR
  ..._u32be(width),
  ..._u32be(height),
  0x08, 0x06, 0x00, 0x00, 0x00,
]);

Uint8List _gif(int width, int height) => _bytes([
  0x47, 0x49, 0x46, 0x38, 0x39, 0x61, // GIF89a
  ..._u16le(width),
  ..._u16le(height),
  0xF7, 0x00, 0x00,
]);

Uint8List _webpLossy(int width, int height) => _bytes([
  0x52, 0x49, 0x46, 0x46, // RIFF
  ..._u32le(30),
  0x57, 0x45, 0x42, 0x50, // WEBP
  0x56, 0x50, 0x38, 0x20, // 'VP8 '
  ..._u32le(10),
  0x00, 0x00, 0x00, // frame tag
  0x9D, 0x01, 0x2A, // sync code
  ..._u16le(width),
  ..._u16le(height),
]);

Uint8List _webpLossless(int width, int height) {
  final bits = (width - 1) | ((height - 1) << 14);
  return _bytes([
    0x52, 0x49, 0x46, 0x46,
    ..._u32le(30),
    0x57, 0x45, 0x42, 0x50,
    0x56, 0x50, 0x38, 0x4C, // VP8L
    ..._u32le(10),
    0x2F,
    ..._u32le(bits),
  ]);
}

Uint8List _webpExtended(int width, int height) => _bytes([
  0x52, 0x49, 0x46, 0x46,
  ..._u32le(30),
  0x57, 0x45, 0x42, 0x50,
  0x56, 0x50, 0x38, 0x58, // VP8X
  ..._u32le(10),
  0x10, 0x00, 0x00, 0x00, // flags
  ..._u24le(width - 1),
  ..._u24le(height - 1),
]);

Uint8List _bmp(int width, int height, {int headerSize = 40}) => _bytes([
  0x42, 0x4D, // BM
  ..._u32le(0), ..._u32le(0), ..._u32le(54),
  ..._u32le(headerSize),
  if (headerSize == 12) ..._u16le(width) else ..._u32le(width),
  if (headerSize == 12) ..._u16le(height) else ..._u32le(height),
  ..._u32le(0),
]);

/// [segments] are `(marker, payload)` pairs written before the SOF0, so a real
/// EXIF/ICC preamble can be simulated.
Uint8List _jpeg(
  int width,
  int height, {
  List<(int, List<int>)> segments = const [],
}) => _bytes([
  0xFF, 0xD8,
  for (final (marker, payload) in segments) ...[
    0xFF,
    marker,
    ..._u16be(payload.length + 2),
    ...payload,
  ],
  0xFF, 0xC0, // SOF0
  ..._u16be(17),
  0x08,
  ..._u16be(height),
  ..._u16be(width),
  0x03, 0x01, 0x22, 0x00, 0x02, 0x11, 0x01, 0x03, 0x11, 0x01,
]);

void main() {
  group('rasterPixelSizeFromHeader', () {
    test('reads PNG dimensions', () {
      expect(rasterPixelSizeFromHeader(_png(16, 16)), (width: 16, height: 16));
      expect(rasterPixelSizeFromHeader(_png(1920, 1080)), (
        width: 1920,
        height: 1080,
      ));
    });

    test('reads GIF dimensions', () {
      expect(rasterPixelSizeFromHeader(_gif(64, 48)), (width: 64, height: 48));
    });

    test('reads all three WebP chunk flavours', () {
      expect(rasterPixelSizeFromHeader(_webpLossy(320, 200)), (
        width: 320,
        height: 200,
      ));
      expect(rasterPixelSizeFromHeader(_webpLossless(320, 200)), (
        width: 320,
        height: 200,
      ));
      expect(rasterPixelSizeFromHeader(_webpExtended(4096, 2160)), (
        width: 4096,
        height: 2160,
      ));
    });

    test('reads BMP dimensions, including the 12-byte core header', () {
      expect(rasterPixelSizeFromHeader(_bmp(24, 24)), (width: 24, height: 24));
      expect(rasterPixelSizeFromHeader(_bmp(24, 24, headerSize: 12)), (
        width: 24,
        height: 24,
      ));
    });

    test('a top-down BMP (negative height) reports a positive size', () {
      expect(rasterPixelSizeFromHeader(_bmp(24, -24)), (width: 24, height: 24));
    });

    test('reads JPEG dimensions from the start-of-frame', () {
      expect(rasterPixelSizeFromHeader(_jpeg(800, 600)), (
        width: 800,
        height: 600,
      ));
    });

    test('skips JPEG metadata segments to reach the start-of-frame', () {
      final withPreamble = _jpeg(
        800,
        600,
        segments: [
          (0xE0, List.filled(14, 0x00)), // JFIF APP0
          (0xE1, List.filled(2000, 0x11)), // a fat EXIF APP1
          (0xE2, List.filled(600, 0x22)), // ICC APP2
          (0xC4, List.filled(30, 0x33)), // DHT shares the SOF marker range
        ],
      );
      expect(rasterPixelSizeFromHeader(withPreamble), (
        width: 800,
        height: 600,
      ));
    });

    test('returns null for non-raster and malformed bytes', () {
      expect(rasterPixelSizeFromHeader(_bytes([])), isNull);
      expect(
        rasterPixelSizeFromHeader(
          // '<svg xmlns=' — the SVG path sizes itself from the document.
          _bytes('<svg xmlns="http://www.w3.org/2000/svg" />'.codeUnits),
        ),
        isNull,
      );
      expect(
        rasterPixelSizeFromHeader(_bytes([0x00, 0x01, 0x02, 0x03])),
        isNull,
      );
      // Truncated PNG: signature present, IHDR cut off.
      expect(
        rasterPixelSizeFromHeader(_bytes(_png(16, 16).sublist(0, 18))),
        isNull,
      );
      // A zero-dimension header is not a usable intrinsic size.
      expect(rasterPixelSizeFromHeader(_png(0, 10)), isNull);
    });

    test('returns null for a JPEG whose scan starts with no frame header', () {
      final noSof = _bytes([
        0xFF,
        0xD8,
        0xFF,
        0xE0,
        ..._u16be(16),
        ...List.filled(14, 0),
        0xFF,
        0xDA,
        ..._u16be(12),
        ...List.filled(10, 0),
      ]);
      expect(rasterPixelSizeFromHeader(noSof), isNull);
    });
  });
}
