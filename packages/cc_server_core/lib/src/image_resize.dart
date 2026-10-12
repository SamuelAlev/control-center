import 'dart:isolate';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// [resizeRasterToWidth] on a worker isolate.
///
/// `package:image` is pure Dart, so decode → copyResize → encode is
/// single-threaded CPU measured in SECONDS for a 4000px JPEG. Run inline it
/// violated the server's own "nothing CPU-bound on the RPC isolate" invariant
/// on the media path: the first fetch of each unseen `(url, width)` — scrolling
/// a newsfeed, say — stalled every concurrent RPC for the duration.
///
/// Small images skip the hop entirely: below [_isolateThresholdBytes] the
/// isolate spawn plus two byte copies cost more than the resize itself.
///
/// [maxDecodedPixels] is forwarded to [resizeRasterToWidth], which bounds how
/// much a single request can make the decoder allocate.
Future<({Uint8List bytes, String mimeType})?> resizeRasterToWidthAsync(
  List<int> bytes,
  int maxWidth, {
  int maxDecodedPixels = _defaultMaxDecodedPixels,
}) {
  if (bytes.length < _isolateThresholdBytes) {
    return Future.value(
      resizeRasterToWidth(bytes, maxWidth, maxDecodedPixels: maxDecodedPixels),
    );
  }
  final input = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
  return Isolate.run(
    () => resizeRasterToWidth(
      input,
      maxWidth,
      maxDecodedPixels: maxDecodedPixels,
    ),
  );
}

/// Below this, resizing inline is cheaper than spawning an isolate for it.
const int _isolateThresholdBytes = 32 * 1024;

/// The default cap on pixels decoded from one proxied raster: 8192 x 8192.
///
/// `package:image`'s own default is 2^28 pixels (16384 x 16384, ~1 GiB as
/// RGBA), which is far more than a thumbnail needs and is reachable from a
/// small hostile file that merely *declares* those dimensions. Anything larger
/// than this cap is streamed through untouched instead of decoded here.
const int _defaultMaxDecodedPixels = 8192 * 8192;

/// Downscales a proxied raster image so the web thin client receives a small
/// thumbnail instead of a full-resolution original (a 1200px OG banner painted
/// into a 56px row, a 256px favicon into a 14px disc, …).
///
/// Decodes [bytes] and, when the image is wider than [maxWidth] device pixels,
/// returns an aspect-preserving re-encode at that width — PNG when the source
/// has alpha (favicons/logos), JPEG otherwise (opaque photos/banners). It never
/// upscales.
///
/// Returns null — so the proxy streams the originals through unchanged — when:
/// the bytes are not a decodable still raster (SVG, an unsupported codec), the
/// image is animated (GIF/APNG, which a still re-encode would flatten), it is
/// already no wider than [maxWidth] (a re-encode would only add loss/CPU), or
/// it declares more than [maxDecodedPixels] pixels (`package:image` rejects
/// those before allocating pixels, and the cap is what keeps a tiny hostile
/// file from making the server decode gigabytes).
({Uint8List bytes, String mimeType})? resizeRasterToWidth(
  List<int> bytes,
  int maxWidth, {
  int maxDecodedPixels = _defaultMaxDecodedPixels,
}) {
  try {
    final input = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
    final decoded = _decodeRaster(input, maxDecodedPixels);
    if (decoded == null || decoded.hasAnimation || decoded.width <= maxWidth) {
      return null;
    }
    final resized = img.copyResize(decoded, width: maxWidth);
    if (resized.hasAlpha) {
      return (bytes: img.encodePng(resized), mimeType: 'image/png');
    }
    return (bytes: img.encodeJpg(resized, quality: 82), mimeType: 'image/jpeg');
  } catch (_) {
    return null;
  }
}

/// Decodes [bytes] with an explicit decoder capped at [maxPixels].
///
/// [img.decodeImage] identifies the format the same way, but lets every decoder
/// fall back to the package-wide [img.Decoder.defaultMaxPixels] (2^28). Naming
/// the decoder here is what lets the tighter, explicit limit through. Returns
/// null for data in no known format.
img.Image? _decodeRaster(Uint8List bytes, int maxPixels) =>
    _decoderFor(img.findFormatForData(bytes), maxPixels)?.decode(bytes);

/// A decoder for [format] that refuses to decode more than [maxPixels] pixels,
/// mirroring `createDecoderForFormat`. GIF and WebP take the limit as a field
/// rather than a constructor argument.
img.Decoder? _decoderFor(img.ImageFormat format, int maxPixels) =>
    switch (format) {
      img.ImageFormat.bmp => img.BmpDecoder(maxPixels: maxPixels),
      img.ImageFormat.exr => img.ExrDecoder(maxPixels: maxPixels),
      img.ImageFormat.gif => img.GifDecoder()..maxPixels = maxPixels,
      img.ImageFormat.ico => img.IcoDecoder(maxPixels: maxPixels),
      img.ImageFormat.jpg => img.JpegDecoder(maxPixels: maxPixels),
      img.ImageFormat.png => img.PngDecoder(maxPixels: maxPixels),
      img.ImageFormat.pnm => img.PnmDecoder(maxPixels: maxPixels),
      img.ImageFormat.psd => img.PsdDecoder(maxPixels: maxPixels),
      img.ImageFormat.pvr => img.PvrDecoder(maxPixels: maxPixels),
      img.ImageFormat.tga => img.TgaDecoder(maxPixels: maxPixels),
      img.ImageFormat.tiff => img.TiffDecoder(maxPixels: maxPixels),
      img.ImageFormat.webp => img.WebPDecoder()..maxPixels = maxPixels,
      _ => null,
    };
