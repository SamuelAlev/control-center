import 'package:cc_ui/src/components/cc_image_fade.dart';
import 'package:cc_ui/src/foundation/cc_motion.dart';
import 'package:cc_ui/src/primitives/image_fade.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../cc_test_app.dart';

void main() {
  group('CcImageFade', () {
    testWidgets('keeps a short fade under reduced motion', (tester) async {
      await tester.pumpWidget(
        ccTestApp(
          const MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: SizedBox(
              width: 40,
              height: 40,
              child: CcImageFade(
                image: AssetImage('y.png'),
                duration: Duration(milliseconds: 600),
              ),
            ),
          ),
        ),
      );

      // Travel drops out; the opacity fade stays so the image still appears.
      final fade = tester.widget<ImageFade>(find.byType(ImageFade).first);
      expect(fade.duration, CcMotion.fade);
      expect(find.byType(ImageFade), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });
}
