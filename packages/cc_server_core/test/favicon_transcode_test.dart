import 'package:cc_server_core/src/favicon_transcode.dart';
import 'package:image/image.dart' as img;
import 'package:test/test.dart';

// PNG file signature (89 50 4E 47 0D 0A 1A 0A).
const _pngMagic = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];

void main() {
  test('transcodes ICO bytes to a PNG the web client can decode', () {
    final ico = img.encodeIco(img.Image(width: 16, height: 16));

    final png = transcodeIcoToPng(ico);

    expect(png, isNotNull);
    expect(png!.length, greaterThan(8));
    expect(png.sublist(0, 8), _pngMagic);
  });

  test('a multi-size ICO transcodes to a STILL PNG (not an animated APNG)', () {
    // A real favicon bundles several sizes. decodeIco() would surface them as
    // animation frames and encodePng would emit an APNG that visibly cycles —
    // the transcode must instead pick one frame and produce a still PNG.
    final multiSize = img.Image(width: 16, height: 16)
      ..addFrame(img.Image(width: 32, height: 32))
      ..addFrame(img.Image(width: 48, height: 48));
    final ico = img.encodeIco(multiSize);
    expect(multiSize.numFrames, 3, reason: 'sanity: built a 3-size ICO');

    final png = transcodeIcoToPng(ico);

    expect(png, isNotNull);
    expect(png!.sublist(0, 8), _pngMagic);
    final reDecoded = img.decodePng(png);
    expect(reDecoded, isNotNull);
    expect(reDecoded!.hasAnimation, isFalse, reason: 'must be a still PNG');
    expect(reDecoded.numFrames, 1);
    // A real, non-empty frame was chosen (the largest available).
    expect(reDecoded.width, greaterThanOrEqualTo(16));
  });

  test('returns null for non-ICO bytes so the proxy passes them through', () {
    // A real PNG (already decodable) — not ICO, so no transcode is attempted.
    final alreadyPng = img.encodePng(img.Image(width: 8, height: 8));
    expect(transcodeIcoToPng(alreadyPng), isNull);

    // Garbage bytes must not throw; they degrade to a pass-through (null).
    expect(transcodeIcoToPng([1, 2, 3, 4, 5]), isNull);
    expect(transcodeIcoToPng(const []), isNull);
  });
}
