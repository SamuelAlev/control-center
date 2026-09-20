import 'package:cc_domain/features/rigs/domain/value_objects/browser_defaults.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_browser_engine.dart';
import 'package:control_center/features/rigs/presentation/rig_boot_mark.dart';
import 'package:control_center/features/rigs/presentation/rig_tab_surfaces.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // The marks are xmlns-less inline-HTML SVG fragments shared with the
  // guest's new-tab page, so "flutter_svg can actually parse them" is a real
  // claim: a compile failure here would be a blank square on the boot screen.
  test('every engine mark compiles as SVG', () async {
    for (final engine in RigBrowserEngine.values) {
      final bytes = await SvgStringLoader(
        browserRigEngineMark(engine),
      ).loadBytes(null);
      expect(
        bytes.lengthInBytes,
        greaterThan(0),
        reason: '${engine.wire} mark must survive the vector compiler',
      );
    }
  });

  testWidgets('the boot mark renders and breathes', (tester) async {
    for (final engine in RigBrowserEngine.values) {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: BrowserEngineBootMark(engine: engine)),
        ),
      );
      // Let the breathing controller tick a few frames; an error would
      // surface as a FlutterError the tester rethrows.
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(SvgPicture), findsOneWidget);
      expect(tester.hasRunningAnimations, isTrue);
      expect(tester.takeException(), isNull);
    }
    // The repeating breath never settles; stop it so the test can end.
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('reduced motion holds the mark still', (tester) async {
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: BrowserEngineBootMark(engine: RigBrowserEngine.firefox),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 3));
    expect(find.byType(FadeTransition), findsNothing);
    expect(
      tester.hasRunningAnimations,
      isFalse,
      reason: 'Reduced motion means no pulse, not a slower one.',
    );
  });

  testWidgets('iOS and Android boot marks breathe their platform glyphs', (
    tester,
  ) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(child: RigBootMark(surface: RigTabSurfaces.ios)),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byIcon(AppIcons.appleLogo), findsOneWidget);
    expect(find.byType(FadeTransition), findsOneWidget);
    expect(tester.hasRunningAnimations, isTrue);

    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(child: RigBootMark(surface: RigTabSurfaces.mobile)),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byIcon(AppIcons.androidLogo), findsOneWidget);
    expect(find.byType(FadeTransition), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('reduced motion holds a platform mark still', (tester) async {
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: RigBootMark(surface: RigTabSurfaces.ios)),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 3));
    expect(find.byIcon(AppIcons.appleLogo), findsOneWidget);
    expect(find.byType(FadeTransition), findsNothing);
    expect(
      tester.hasRunningAnimations,
      isFalse,
      reason: 'Reduced motion means no pulse, not a slower one.',
    );
  });
}
