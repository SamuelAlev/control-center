/// Pure-Dart 8-bit grayscale PNG encoder for the vision compaction renderer.
///
/// This deliberately avoids any compression library. It emits a spec-legal PNG
/// with the IDAT zlib stream built from **uncompressed (stored) DEFLATE
/// blocks**, so no Huffman/LZ77 coding is needed — only CRC-32 (per chunk) and
/// Adler-32 (the zlib trailer), both implemented here. The output is fully
/// deterministic: identical pixels always produce identical bytes.
///
/// The PNG is color type 0 (grayscale), 8 bits per sample, with each scanline
/// prefixed by filter byte `0x00` (no filtering) as required by the format.
library;

import 'dart:typed_data';

/// The 8-byte PNG file signature that opens every PNG stream.
const List<int> pngSignature = <int>[137, 80, 78, 71, 13, 10, 26, 10];

/// Encodes a [width]x[height] 8-bit grayscale image into PNG bytes.
///
/// [pixels] must contain exactly `width * height` samples in row-major order
/// (each value `0`–`255`, `0` = black, `255` = white); higher bytes are masked
/// to 8 bits. Throws [ArgumentError] when the buffer length disagrees with the
/// declared dimensions or a dimension is not positive.
Uint8List encodeGrayscalePng({
  required int width,
  required int height,
  required Uint8List pixels,
}) {
  if (width <= 0 || height <= 0) {
    throw ArgumentError('PNG dimensions must be positive: ${width}x$height');
  }
  if (pixels.length != width * height) {
    throw ArgumentError(
      'pixels length ${pixels.length} != width*height ${width * height}',
    );
  }

  final out = BytesBuilder(copy: false);
  out.add(pngSignature);

  // IHDR: width, height, bit depth 8, color type 0 (grayscale), default
  // compression/filter/interlace.
  final ihdr = Uint8List(13);
  final ihdrView = ByteData.view(ihdr.buffer);
  ihdrView.setUint32(0, width);
  ihdrView.setUint32(4, height);
  ihdr[8] = 8; // bit depth
  ihdr[9] = 0; // color type: grayscale
  ihdr[10] = 0; // compression: deflate
  ihdr[11] = 0; // filter: adaptive (only filter 0 used per scanline)
  ihdr[12] = 0; // interlace: none
  _writeChunk(out, 'IHDR', ihdr);

  // Raw image data: one filter byte (0x00) per scanline, then the row samples.
  final raw = Uint8List(height * (width + 1));
  var dst = 0;
  var src = 0;
  for (var y = 0; y < height; y++) {
    raw[dst++] = 0; // filter type 0 (None)
    for (var x = 0; x < width; x++) {
      raw[dst++] = pixels[src++] & 0xFF;
    }
  }

  _writeChunk(out, 'IDAT', _zlibStored(raw));
  _writeChunk(out, 'IEND', Uint8List(0));
  return out.toBytes();
}

/// Wraps [data] in a zlib stream using only stored (uncompressed) DEFLATE
/// blocks.
///
/// The zlib header is `0x78 0x01` (32K window, no preset dictionary, fastest
/// level), followed by stored blocks each capped at 65535 bytes, then the
/// big-endian Adler-32 checksum of [data].
Uint8List _zlibStored(Uint8List data) {
  final out = BytesBuilder(copy: false);
  out.addByte(0x78); // CMF: deflate, 32K window
  out.addByte(0x01); // FLG: no dict, fastest, valid check bits

  const maxBlock = 0xFFFF;
  var offset = 0;
  if (data.isEmpty) {
    // A single empty final stored block keeps the stream well-formed.
    out.add(<int>[0x01, 0x00, 0x00, 0xFF, 0xFF]);
  } else {
    while (offset < data.length) {
      final remaining = data.length - offset;
      final blockLen = remaining > maxBlock ? maxBlock : remaining;
      final isFinal = offset + blockLen >= data.length;
      out.addByte(isFinal ? 0x01 : 0x00); // BFINAL bit, BTYPE 00 (stored)
      out.addByte(blockLen & 0xFF);
      out.addByte((blockLen >> 8) & 0xFF);
      final nlen = blockLen ^ 0xFFFF;
      out.addByte(nlen & 0xFF);
      out.addByte((nlen >> 8) & 0xFF);
      out.add(data.sublist(offset, offset + blockLen));
      offset += blockLen;
    }
  }

  final adler = _adler32(data);
  out.addByte((adler >> 24) & 0xFF);
  out.addByte((adler >> 16) & 0xFF);
  out.addByte((adler >> 8) & 0xFF);
  out.addByte(adler & 0xFF);
  return out.toBytes();
}

/// Writes one PNG chunk: 4-byte big-endian length, 4-byte type tag, payload,
/// then the 4-byte big-endian CRC-32 over (type + payload).
void _writeChunk(BytesBuilder out, String type, Uint8List data) {
  final lengthBytes = Uint8List(4);
  ByteData.view(lengthBytes.buffer).setUint32(0, data.length);
  out.add(lengthBytes);

  final typeBytes = Uint8List.fromList(type.codeUnits);
  out.add(typeBytes);
  out.add(data);

  final crcInput = Uint8List(typeBytes.length + data.length)
    ..setRange(0, typeBytes.length, typeBytes)
    ..setRange(typeBytes.length, typeBytes.length + data.length, data);
  final crc = crc32(crcInput);
  final crcBytes = Uint8List(4);
  ByteData.view(crcBytes.buffer).setUint32(0, crc);
  out.add(crcBytes);
}

/// Lazily-built CRC-32 lookup table (IEEE 802.3 polynomial, reflected).
final List<int> _crcTable = _buildCrcTable();

List<int> _buildCrcTable() {
  final table = List<int>.filled(256, 0);
  for (var n = 0; n < 256; n++) {
    var c = n;
    for (var k = 0; k < 8; k++) {
      if ((c & 1) != 0) {
        c = 0xEDB88320 ^ (c >> 1);
      } else {
        c = c >> 1;
      }
    }
    table[n] = c;
  }
  return table;
}

/// Computes the CRC-32 (PNG/zlib variant) of [data].
int crc32(Uint8List data) {
  var c = 0xFFFFFFFF;
  for (final b in data) {
    c = _crcTable[(c ^ b) & 0xFF] ^ (c >> 8);
  }
  return (c ^ 0xFFFFFFFF) & 0xFFFFFFFF;
}

/// Computes the Adler-32 checksum of [data] (used in the zlib trailer).
int _adler32(Uint8List data) {
  const modAdler = 65521;
  var a = 1;
  var b = 0;
  for (final byte in data) {
    a = (a + byte) % modAdler;
    b = (b + a) % modAdler;
  }
  return ((b << 16) | a) & 0xFFFFFFFF;
}
