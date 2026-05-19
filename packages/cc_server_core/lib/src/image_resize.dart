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
Future<({Uint8List bytes, String mimeType})?> resizeRasterToWidthAsync(
  List<int> bytes,
  int maxWidth,
) {
  if (bytes.length < _isolateThresholdBytes) {
    return Future.value(resizeRasterToWidth(bytes, maxWidth));
  }
  final input = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
  return Isolate.run(() => resizeRasterToWidth(input, maxWidth));
}

/// Below this, resizing inline is cheaper than spawning an isolate for it.
const int _isolateThresholdBytes = 32 * 1024;

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
/// image is animated (GIF/APNG, which a still re-encode would flatten), or it is
/// already no wider than [maxWidth] (a re-encode would only add loss/CPU).
({Uint8List bytes, String mimeType})? resizeRasterToWidth(
  List<int> bytes,
  int maxWidth,
) {
  try {
    final input = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
    final decoded = img.decodeImage(input);
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
