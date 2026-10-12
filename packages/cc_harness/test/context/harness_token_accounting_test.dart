import 'package:cc_harness/context.dart';
import 'package:cc_harness/messages.dart';
import 'package:test/test.dart';

void main() {
  HarnessMessage withImage(String id) => HarnessMessage.toolResults([
    HarnessToolResultBlock(
      toolUseId: id,
      content: 'frame',
      images: const [HarnessImageBlock(data: 'AA', mediaType: 'image/png')],
    ),
  ]);

  group('countHarnessImages', () {
    test('counts tool-result and top-level images', () {
      final h = <HarnessMessage>[
        HarnessMessage.user('look'),
        withImage('a'),
        const HarnessMessage(
          role: HarnessRole.user,
          content: [HarnessImageBlock(data: 'BB', mediaType: 'image/png')],
        ),
      ];
      expect(countHarnessImages(h), 2);
    });

    test('is zero for a text history', () {
      expect(countHarnessImages([HarnessMessage.user('hi')]), 0);
    });
  });

  group('checkHarnessContextFit', () {
    test('reports token and image ceilings independently', () {
      final h = <HarnessMessage>[
        HarnessMessage.user('x' * 400),
        withImage('a'),
      ];
      final fit = checkHarnessContextFit(
        h,
        contextWindow: 100000,
        imageLimit: 1,
      );
      expect(fit.fitsImages, isTrue);
      expect(fit.fitsTokens, isTrue);
      expect(fit.fits, isTrue);
      expect(fit.images, 1);

      final over = checkHarnessContextFit(h, contextWindow: 10, imageLimit: 0);
      expect(over.fitsTokens, isFalse);
      expect(over.fitsImages, isFalse);
      expect(over.fits, isFalse);
      expect(over.headroomTokens, lessThan(0));
    });

    test('unknown ceilings never block', () {
      final h = <HarnessMessage>[HarnessMessage.user('x' * 400)];
      final fit = checkHarnessContextFit(h);
      expect(fit.fits, isTrue);
    });
  });

  group('calibratedHarnessTokens', () {
    test('is a no-op without a calibration or identity', () {
      expect(calibratedHarnessTokens(1000), 1000);
      expect(
        calibratedHarnessTokens(
          1000,
          calibration: TokenCalibration(),
          providerId: null,
          modelId: 'm',
        ),
        1000,
      );
    });

    test('scales the estimate once calibrated', () {
      final c = TokenCalibration(minSamples: 1);
      c.observe(
        providerId: 'p',
        modelId: 'm',
        estimatedTokens: 1000,
        observedPromptTokens: 2000,
      );
      expect(
        calibratedHarnessTokens(
          1000,
          calibration: c,
          providerId: 'p',
          modelId: 'm',
        ),
        2000,
      );
    });
  });
}
