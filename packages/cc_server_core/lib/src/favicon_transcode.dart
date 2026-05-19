import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Transcodes ICO [bytes] to a static PNG so a web client whose renderer
/// (CanvasKit) cannot decode ICO can still paint the newsfeed source favicon.
///
/// Decodes ONLY the largest frame. An `.ico` bundles several sizes
/// (16/32/48/…), and the general [img.decodeIco] returns every size as an
/// animation frame — which [img.encodePng] then emits as an *animated* PNG, so
/// the favicon visibly cycles through its sizes. [img.IcoDecoder.decodeImageLargest]
/// returns one frame, giving a still PNG.
///
/// Returns null when [bytes] are not a decodable ICO — the proxy then passes
/// the original bytes through unchanged (some hosts serve a renderable PNG/GIF
/// from a `.ico` URL, which the client can decode directly).
Uint8List? transcodeIcoToPng(List<int> bytes) {
  try {
    final decoded = img.IcoDecoder().decodeImageLargest(
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
