import 'dart:math';

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
    final decoded = img.decodePng(out.bytes)!;
    expect(decoded.width, 64);
    expect(decoded.getPixel(0, 0).a, 0);
  });

  test('resizes in EXIF display orientation without losing rotation', () {
    final source = img.Image(width: 120, height: 60);
    for (var y = 0; y < source.height; y++) {
      for (var x = 0; x < source.width; x++) {
        source.setPixelRgb(x, y, x < 60 ? 255 : 0, 0, x < 60 ? 0 : 255);
      }
    }
    source.exif.imageIfd.orientation = 6;
    final out = resizeRasterToWidth(img.encodeJpg(source), 30)!;
    final decoded = img.decodeJpg(out.bytes)!;
    expect((decoded.width, decoded.height), (30, 60));
    final top = decoded.getPixel(15, 5);
    final bottom = decoded.getPixel(15, 55);
    expect(top.r, greaterThan(top.b));
    expect(bottom.b, greaterThan(bottom.r));
  });

  test('returns null when the source is already no wider than the cap', () {
    final small = img.encodePng(img.Image(width: 48, height: 48));
    expect(resizeRasterToWidth(small, 64), isNull);
    // Exactly at the cap: still a no-op (no lossy re-encode for nothing).
    final exact = img.encodePng(img.Image(width: 64, height: 64));
    expect(resizeRasterToWidth(exact, 64), isNull);
  });

  test(
    'returns null for animated images so the proxy streams them through',
    () {
      final animated = img.Image(width: 400, height: 400)
        ..addFrame(img.Image(width: 400, height: 400));
      final gif = img.encodeGif(animated);
      expect(img.decodeGif(gif)!.hasAnimation, isTrue, reason: 'sanity');

      expect(resizeRasterToWidth(gif, 100), isNull);
    },
  );

  test('returns null for undecodable bytes without throwing', () {
    expect(resizeRasterToWidth([1, 2, 3, 4, 5], 64), isNull);
    expect(resizeRasterToWidth(const [], 64), isNull);
  });

  test('refuses to decode past an explicit pixel budget', () {
    final source = img.encodePng(img.Image(width: 1200, height: 630));

    // 1200 x 630 = 756,000 pixels. At the budget the resize still happens;
    // one pixel over, the image counts as undecodable and is streamed through
    // untouched rather than allocated for.
    expect(
      resizeRasterToWidth(source, 340, maxDecodedPixels: 1200 * 630),
      isNotNull,
    );
    expect(
      resizeRasterToWidth(source, 340, maxDecodedPixels: 1200 * 630 - 1),
      isNull,
    );
  });

  test('enforces the budget on the worker-isolate path too', () async {
    // Incompressible pixels, so the encoded PNG is big enough to take the
    // isolate hop (whose threshold is on compressed input bytes).
    final noise = img.Image(width: 256, height: 256);
    final random = Random(7);
    for (var y = 0; y < noise.height; y++) {
      for (var x = 0; x < noise.width; x++) {
        noise.setPixelRgb(
          x,
          y,
          random.nextInt(256),
          random.nextInt(256),
          random.nextInt(256),
        );
      }
    }
    final source = img.encodePng(noise);
    expect(
      source.length,
      greaterThan(32 * 1024),
      reason: 'sanity: this input must cross the isolate threshold',
    );

    const pixels = 256 * 256;
    expect(
      await resizeRasterToWidthAsync(source, 64, maxDecodedPixels: pixels - 1),
      isNull,
    );
    final resized = await resizeRasterToWidthAsync(source, 64);
    expect(resized, isNotNull);
    expect(resized!.mimeType, 'image/jpeg');
    expect(img.decodeJpg(resized.bytes)!.width, 64);
  });

  test('keeps BMP, WebP and still GIF resizing', () {
    final bmp = img.encodeBmp(img.Image(width: 120, height: 60));
    final webp = img.encodeWebP(img.Image(width: 120, height: 60));
    final gif = img.encodeGif(img.Image(width: 120, height: 60));

    for (final (name, source) in [('bmp', bmp), ('webp', webp), ('gif', gif)]) {
      expect(
        resizeRasterToWidth(source, 40),
        isNotNull,
        reason: '$name still resizes',
      );
    }
  });
}
