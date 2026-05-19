import 'package:cc_gallery/main.dart';
import 'package:cc_gallery/main.directories.g.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widgetbook/widgetbook.dart';

void main() {
  // Skipped on an upstream defect in accessibility_tools 2.8.0 (the newest
  // release), which the gallery mounts as its `Accessibility` BuilderAddon.
  // `_AccessibilityToolsState._checker` is a `late` field whose initializer
  // reads `Theme.of(context)`, and under a test binding `build()` returns the
  // child early and never touches it — so `dispose()` is what first forces the
  // lazy initialization, looking up an inherited widget mid-unmount, which
  // Flutter asserts against ("Looking up a deactivated widget's ancestor is
  // unsafe"). It therefore fires only in widget tests, and only at teardown:
  // every assertion in the body below passes first. Un-skip once upstream
  // initializes that field from `didChangeDependencies` instead.
  testWidgets(
    'cc_ui gallery boots without throwing',
    (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const CcGalleryApp());
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      expect(find.byType(CcGalleryApp), findsOneWidget);
    },
    // accessibility_tools 2.8.0 reads Theme.of(context) during dispose().
    skip: true,
  );

  // The Workbench only invokes the appBuilder once a use-case is *selected*
  // (otherwise it shows the home page), so booting alone never exercised the
  // preview path. This pumps the builder directly: the stock widgetbook
  // `widgetsAppBuilder` (a `WidgetsApp` with only `home:`) throws on build under
  // the current SDK; [ccAppBuilder] supplies a `pageRouteBuilder` and renders.
  testWidgets('ccAppBuilder renders a use-case preview without throwing', (
    tester,
  ) async {
    await tester.pumpWidget(
      Builder(
        builder: (context) => ccAppBuilder(
          context,
          const Center(
            child: Text('preview', textDirection: TextDirection.ltr),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('preview'), findsOneWidget);
  });

  group('generated catalogue', () {
    // Flattens the generated [directories] tree to every catalogued use-case.
    List<WidgetbookUseCase> allUseCases() => directories
        .expand((node) => node.leaves)
        .whereType<WidgetbookUseCase>()
        .toList();

    test('exposes the full component + foundation catalogue', () {
      final topLevel = directories.map((n) => n.name).toSet();
      expect(topLevel, containsAll(<String>{'Components', 'Foundations'}));

      // Guards against a generator regression silently emptying the tree, and
      // documents the expected breadth of the design-system gallery.
      final useCases = allUseCases();
      expect(
        useCases.length,
        greaterThanOrEqualTo(120),
        reason: 'expected the full cc_ui catalogue (~130 use-cases)',
      );
    });

    test('every use-case has a name and a builder', () {
      for (final useCase in allUseCases()) {
        expect(useCase.name, isNotEmpty);
        expect(useCase.builder, isNotNull);
      }
    });
  });
}
