import 'package:cc_server_core/src/image_resize.dart';
import 'package:image/image.dart' as img;
import 'package:test/test.dart';

// PNG / JPEG file signatures.
const _pngMagic = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];
const _jpegMagic = [0xFF, 0xD8, 0xFF];

void main() {
  test('downscales an opaque banner wider than the cap to a JPEG', () {
    // A 1200px-wide opaque "banner" like an article OG image.
    final source = img.encodeJpg(img.Image(width: 1200, height: 630));

    final out = resizeRasterToWidth(source, 340);

    expect(out, isNotNull);
    expect(out!.mimeType, 'image/jpeg');
    expect(out.bytes.sublist(0, 3), _jpegMagic);
    final decoded = img.decodeJpg(out.bytes)!;
    expect(decoded.width, 340);
    expect(decoded.height, lessThan(630), reason: 'aspect ratio preserved');
    expect(out.bytes.length, lessThan(source.length));
  });

  test('keeps alpha by re-encoding a transparent icon as PNG', () {
    // A 512px favicon/logo with an alpha channel.
    final source = img.encodePng(
      img.Image(width: 512, height: 512, numChannels: 4),
    );

    final out = resizeRasterToWidth(source, 64);

    expect(out, isNotNull);
    expect(out!.mimeType, 'image/png');
    expect(out.bytes.sublist(0, 8), _pngMagic);
    expect(img.decodePng(out.bytes)!.width, 64);
  });

  test('returns null when the source is already no wider than the cap', () {
    final small = img.encodePng(img.Image(width: 48, height: 48));
    expect(resizeRasterToWidth(small, 64), isNull);
    // Exactly at the cap: still a no-op (no lossy re-encode for nothing).
    final exact = img.encodePng(img.Image(width: 64, height: 64));
    expect(resizeRasterToWidth(exact, 64), isNull);
  });

  test('returns null for animated images so the proxy streams them through', () {
    final animated = img.Image(width: 400, height: 400)
      ..addFrame(img.Image(width: 400, height: 400));
    final gif = img.encodeGif(animated);
    expect(img.decodeGif(gif)!.hasAnimation, isTrue, reason: 'sanity');

    expect(resizeRasterToWidth(gif, 100), isNull);
  });

  test('returns null for undecodable bytes without throwing', () {
    expect(resizeRasterToWidth([1, 2, 3, 4, 5], 64), isNull);
    expect(resizeRasterToWidth(const [], 64), isNull);
  });
}
