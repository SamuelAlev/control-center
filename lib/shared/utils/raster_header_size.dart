import 'dart:typed_data';

/// Reads a raster image's pixel dimensions out of its header bytes, without
/// decoding a frame. Returns null when [bytes] is not one of the recognised
/// still formats (SVG text, AVIF/HEIF, a truncated download, …).
///
/// This exists because `ui.ImageDescriptor` cannot answer the question on the
/// web: `ImageDescriptor.encoded` succeeds there but `width`/`height` throw
/// `UnsupportedError`, so an intrinsic-size probe built on it silently returns
/// nothing and every un-hinted markdown badge degrades to the full column
/// width (a 16px SonarQube check painted blurry at 500px). Parsing the header
/// ourselves keeps the answer identical on desktop and web.
///
/// EXIF orientation is deliberately ignored — Flutter's own decoders report
/// pre-orientation dimensions, and matching them keeps layout consistent with
/// the frame that actually gets painted.
({int width, int height})? rasterPixelSizeFromHeader(Uint8List bytes) {
  return _png(bytes) ??
      _gif(bytes) ??
      _webp(bytes) ??
      _bmp(bytes) ??
      _jpeg(bytes);
}

({int width, int height})? _ok(int width, int height) =>
    width > 0 && height > 0 ? (width: width, height: height) : null;

int _u16be(Uint8List b, int i) => (b[i] << 8) | b[i + 1];

int _u16le(Uint8List b, int i) => b[i] | (b[i + 1] << 8);

int _u24le(Uint8List b, int i) => b[i] | (b[i + 1] << 8) | (b[i + 2] << 16);

int _u32be(Uint8List b, int i) =>
    (b[i] << 24) | (b[i + 1] << 16) | (b[i + 2] << 8) | b[i + 3];

int _u32le(Uint8List b, int i) =>
    b[i] | (b[i + 1] << 8) | (b[i + 2] << 16) | (b[i + 3] << 24);

bool _matches(Uint8List b, int offset, List<int> signature) {
  if (b.length < offset + signature.length) {
    return false;
  }
  for (var i = 0; i < signature.length; i++) {
    if (b[offset + i] != signature[i]) {
      return false;
    }
  }
  return true;
}

/// PNG (and APNG, which shares the header): the `IHDR` chunk is mandated to be
/// first, so width/height sit at fixed offsets.
({int width, int height})? _png(Uint8List b) {
  const signature = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];
  if (!_matches(b, 0, signature) || b.length < 24) {
    return null;
  }
  if (!_matches(b, 12, const [0x49, 0x48, 0x44, 0x52])) {
    return null;
  }
  return _ok(_u32be(b, 16), _u32be(b, 20));
}

/// GIF87a/GIF89a: the logical screen descriptor follows the 6-byte signature.
({int width, int height})? _gif(Uint8List b) {
  if (!_matches(b, 0, const [0x47, 0x49, 0x46, 0x38]) || b.length < 10) {
    return null;
  }
  return _ok(_u16le(b, 6), _u16le(b, 8));
}

/// WebP: `RIFF....WEBP` then one of three chunk flavours — `VP8 ` (lossy),
/// `VP8L` (lossless) or `VP8X` (extended, which is what animated files use).
({int width, int height})? _webp(Uint8List b) {
  if (!_matches(b, 0, const [0x52, 0x49, 0x46, 0x46]) ||
      !_matches(b, 8, const [0x57, 0x45, 0x42, 0x50])) {
    return null;
  }
  if (_matches(b, 12, const [0x56, 0x50, 0x38, 0x20])) {
    // Lossy: 3-byte frame tag, 3-byte sync code, then 14-bit dimensions.
    if (b.length < 30 || !_matches(b, 23, const [0x9D, 0x01, 0x2A])) {
      return null;
    }
    return _ok(_u16le(b, 26) & 0x3FFF, _u16le(b, 28) & 0x3FFF);
  }
  if (_matches(b, 12, const [0x56, 0x50, 0x38, 0x4C])) {
    // Lossless: 0x2F signature, then two 14-bit minus-one fields.
    if (b.length < 25 || b[20] != 0x2F) {
      return null;
    }
    final bits = _u32le(b, 21);
    return _ok((bits & 0x3FFF) + 1, ((bits >> 14) & 0x3FFF) + 1);
  }
  if (_matches(b, 12, const [0x56, 0x50, 0x38, 0x58])) {
    // Extended: 4-byte flags, then two 24-bit minus-one canvas fields.
    if (b.length < 30) {
      return null;
    }
    return _ok(_u24le(b, 24) + 1, _u24le(b, 27) + 1);
  }
  return null;
}

/// BMP: the DIB header size discriminates the ancient 16-bit `BITMAPCOREHEADER`
/// from every later 32-bit variant. A negative height means top-down rows.
({int width, int height})? _bmp(Uint8List b) {
  if (!_matches(b, 0, const [0x42, 0x4D]) || b.length < 26) {
    return null;
  }
  final headerSize = _u32le(b, 14);
  if (headerSize == 12) {
    return _ok(_u16le(b, 18), _u16le(b, 20));
  }
  final width = _u32le(b, 18).toSigned(32);
  final height = _u32le(b, 22).toSigned(32);
  return _ok(width.abs(), height.abs());
}

/// JPEG: walk the marker segments to the first start-of-frame, which is the
/// only place the dimensions live (they can sit behind arbitrarily large EXIF
/// or ICC segments).
({int width, int height})? _jpeg(Uint8List b) {
  if (!_matches(b, 0, const [0xFF, 0xD8])) {
    return null;
  }
  var pos = 2;
  while (pos + 1 < b.length) {
    if (b[pos] != 0xFF) {
      return null;
    }
    final marker = b[pos + 1];
    pos += 2;
    // Fill bytes: any number of 0xFF may precede a marker code.
    if (marker == 0xFF) {
      pos -= 1;
      continue;
    }
    // Standalone markers (TEM, RST0-7, SOI, EOI) carry no length field.
    if (marker == 0x01 || (marker >= 0xD0 && marker <= 0xD9)) {
      continue;
    }
    if (pos + 1 >= b.length) {
      return null;
    }
    final segmentLength = _u16be(b, pos);
    if (segmentLength < 2) {
      return null;
    }
    // SOF0-SOF15, minus the three markers that share the range but are not
    // frame headers: DHT (0xC4), JPG (0xC8) and DAC (0xCC).
    final isStartOfFrame =
        marker >= 0xC0 &&
        marker <= 0xCF &&
        marker != 0xC4 &&
        marker != 0xC8 &&
        marker != 0xCC;
    if (isStartOfFrame) {
      if (pos + 6 >= b.length) {
        return null;
      }
      return _ok(_u16be(b, pos + 5), _u16be(b, pos + 3));
    }
    // Start of scan: pixel data begins, so there is no frame header to find.
    if (marker == 0xDA) {
      return null;
    }
    pos += segmentLength;
  }
  return null;
}
