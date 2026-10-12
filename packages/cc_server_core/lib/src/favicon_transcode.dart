import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// The default cap on pixels decoded from one ICO: 4096 x 4096.
///
/// `package:image`'s own default (2^28, ~1 GiB RGBA) is effectively unbounded
/// for an icon, which is at most a few hundred pixels across every size it
/// bundles. Decoding happens on the server's media path, so a favicon that
/// declares more is refused rather than allocated for.
const int _defaultMaxDecodedPixels = 4096 * 4096;

/// Transcodes ICO [bytes] to a static PNG so a web client whose renderer
/// (CanvasKit) cannot decode ICO can still paint the newsfeed source favicon.
///
/// Decodes ONLY the largest frame. An `.ico` bundles several sizes
/// (16/32/48/…) and the general [img.decodeIco] returns every size as an
/// animation frame — which [img.encodePng] then emits as an *animated* PNG, so
/// the favicon visibly cycles through its sizes. [img.IcoDecoder.decodeImageLargest]
/// returns one frame, giving a still PNG.
///
/// Returns null when [bytes] are not a decodable ICO — the proxy then passes
/// the original bytes through unchanged (some hosts serve a renderable PNG/GIF
/// from a `.ico` URL, which the client can decode directly).
///
/// [maxDecodedPixels] caps the pixels of the frame this decodes (the largest
/// bundled size). A real favicon is a few hundred pixels at most, so the cap
/// only ever refuses a malformed or hostile icon — which is then passed
/// through, not decoded.
Uint8List? transcodeIcoToPng(
  List<int> bytes, {
  int maxDecodedPixels = _defaultMaxDecodedPixels,
}) {
  try {
    final decoded = img.IcoDecoder(maxPixels: maxDecodedPixels)
        .decodeImageLargest(
          bytes is Uint8List ? bytes : Uint8List.fromList(bytes),
        );
    if (decoded == null) {
      return null;
    }
    // Belt-and-suspenders: strip any residual animation so encodePng emits a
    // single still frame, never an APNG.
    final still = decoded.hasAnimation
        ? img.Image.from(decoded, noAnimation: true)
        : decoded;
    return img.encodePng(still);
  } catch (_) {
    return null;
  }
}
