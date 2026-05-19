import 'dart:ui' as ui;

import 'package:cc_ui/src/primitives/image_fade.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Decoding is real async work, so it has to happen outside a testWidgets
  // body's fake-async zone. Two sizes so a repaint can be told apart.
  late ui.Image frameA;
  late ui.Image frameB;

  setUpAll(() async {
    frameA = await createTestImage(width: 1, height: 1);
    frameB = await createTestImage(width: 2, height: 2);
  });

  group('ImageFade', () {
    testWidgets('fades a single-frame image in over the placeholder', (
      tester,
    ) async {
      final provider = _ManualImageProvider();
      await _pump(tester, provider);

      expect(_opacity(tester), 0);

      provider.emit(frameA);
      await tester.pump();
      expect(_opacity(tester), 0);

      await tester.pump(const Duration(milliseconds: 150));
      expect(_opacity(tester), closeTo(0.5, 0.01));

      await tester.pump(const Duration(milliseconds: 150));
      expect(_opacity(tester), 1);
    });

    // The bug this guards: an animated image (GIF/APNG/animated WebP) pushes a
    // new frame every few tens of milliseconds. Restarting the fade on each one
    // pinned opacity near zero for as long as the animation ran, so the frames
    // played but the colours rendered washed out.
    testWidgets(
      'does not restart the fade on later frames of an animated image',
      (tester) async {
        final provider = _ManualImageProvider();
        await _pump(tester, provider);

        // Frames at a typical GIF interval, spanning more than the 300ms fade.
        for (var i = 0; i < 12; i++) {
          provider.emit(frameA);
          await tester.pump(const Duration(milliseconds: 30));
        }

        // The fade must have finished even though the stream is still
        // delivering. Restarting per frame capped it at ~0.1 forever.
        expect(_opacity(tester), 1);

        // And it stays there for the rest of the animation.
        for (var i = 0; i < 5; i++) {
          provider.emit(frameA);
          await tester.pump(const Duration(milliseconds: 30));
          expect(_opacity(tester), 1);
        }
      },
    );

    testWidgets('repaints each frame of an animated image', (tester) async {
      final provider = _ManualImageProvider();
      await _pump(tester, provider);

      provider.emit(frameA);
      await tester.pump();
      expect(_painted(tester)?.width, frameA.width);

      provider.emit(frameB);
      await tester.pump();
      expect(_painted(tester)?.width, frameB.width);
    });

    testWidgets('fades the error builder in when the image fails', (
      tester,
    ) async {
      final provider = _ManualImageProvider();
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ImageFade(
            image: provider,
            placeholder: const ColoredBox(color: Color(0xFF000000)),
            errorBuilder: (_, _) => const Text('failed'),
          ),
        ),
      );

      provider.fail('boom');
      await tester.pumpAndSettle();

      expect(find.text('failed'), findsOneWidget);
    });
  });
}

Future<void> _pump(WidgetTester tester, ImageProvider<Object> provider) {
  return tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: ImageFade(
        image: provider,
        placeholder: const ColoredBox(color: Color(0xFF000000)),
      ),
    ),
  );
}

/// The opacity the loaded frame currently paints at, or 0 while none is loaded.
double _opacity(WidgetTester tester) {
  final images = tester.widgetList<RawImage>(find.byType(RawImage));
  if (images.isEmpty) return 0;
  return images.last.opacity?.value ?? 1;
}

ui.Image? _painted(WidgetTester tester) =>
    tester.widgetList<RawImage>(find.byType(RawImage)).last.image;

/// An [ImageProvider] whose stream the test drives, so a multi-frame (animated)
/// image can be emitted one frame at a time.
class _ManualImageProvider extends ImageProvider<_ManualImageProvider> {
  final _completer = _ManualImageStreamCompleter();

  void emit(ui.Image image) => _completer.emit(image);

  void fail(Object error) => _completer.fail(error);

  @override
  Future<_ManualImageProvider> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture<_ManualImageProvider>(this);

  @override
  ImageStreamCompleter loadImage(
    _ManualImageProvider key,
    ImageDecoderCallback decode,
  ) => _completer;
}

class _ManualImageStreamCompleter extends ImageStreamCompleter {
  /// Clones like a real multi-frame completer does, so the caller's master
  /// handle survives the superseded frame being released.
  void emit(ui.Image image) => setImage(ImageInfo(image: image.clone()));

  void fail(Object error) => reportError(exception: error);
}
