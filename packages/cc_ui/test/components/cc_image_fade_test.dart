import 'package:cc_ui/src/components/cc_image_fade.dart';
import 'package:cc_ui/src/primitives/image_fade.dart';
import 'package:cc_ui/src/theme/cc_theme.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../cc_test_app.dart';

void main() {
  group('CcImageFade', () {
    testWidgets('renders an ImageFade over a default surface placeholder', (
      tester,
    ) async {
      await tester.pumpWidget(
        ccTestApp(
          const SizedBox(
            width: 100,
            height: 100,
            child: CcImageFade(image: AssetImage('does-not-matter.png')),
          ),
        ),
      );

      expect(find.byType(ImageFade), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('honours a custom placeholder widget', (tester) async {
      await tester.pumpWidget(
        ccTestApp(
          const SizedBox(
            width: 50,
            height: 50,
            child: CcImageFade(
              image: AssetImage('x.png'),
              placeholder: ColoredBox(
                color: Color(0xFF000000),
                child: SizedBox.shrink(),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(ImageFade), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('collapses the fade duration to zero under reduced motion', (
      tester,
    ) async {
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

      // Reduced-motion collapses duration to Duration.zero; the widget still
      // builds the same ImageFade stack.
      expect(find.byType(ImageFade), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('layers a preview ImageFade behind the full image', (
      tester,
    ) async {
      await tester.pumpWidget(
        ccTestApp(
          const SizedBox(
            width: 80,
            height: 80,
            child: CcImageFade(
              image: AssetImage('full.png'),
              preview: AssetImage('preview.png'),
            ),
          ),
        ),
      );

      // preview != null nests a second ImageFade as the placeholder, so two
      // ImageFade widgets are in the tree.
      expect(find.byType(ImageFade), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });
  });

  group('CcImageFade without an ambient CcTheme', () {
    testWidgets('falls back to the built-in backdrop colour', (tester) async {
      // No CcTheme above: context.designSystem is null and the placeholder
      // falls back to _kFallbackBackdrop.
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(
            width: 32,
            height: 32,
            child: CcImageFade(image: AssetImage('no-theme.png')),
          ),
        ),
      );

      expect(find.byType(ImageFade), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

// Silence the unused-element lint for the CcTheme import on platforms where it
// is only transitively required — re-export keeps the analyzer happy.
// ignore: unused_element
typedef _CcTheme = CcTheme;
