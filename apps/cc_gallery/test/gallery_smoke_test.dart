import 'package:cc_gallery/main.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widgetbook/widgetbook.dart' show Story;

void main() {
  // Widgetbook 4 runs its app through `runWidgetbook` and keeps the app widget
  // internal, so this renders a story the way the workbench does: through the
  // gallery config's app builder and every addon.
  //
  // Skipped on an upstream defect in accessibility_tools (still present in
  // 3.0.0), which the gallery mounts as its `Accessibility` BuilderAddon.
  // `_AccessibilityToolsState._checker` is a `late` field whose initializer
  // reads `Theme.of(context)` and under a test binding `build()` returns the
  // child early and never touches it — so `dispose()` is what first forces the
  // lazy initialization, looking up an inherited widget mid-unmount, which
  // Flutter asserts against ("Looking up a deactivated widget's ancestor is
  // unsafe"). It therefore fires only in widget tests and only at teardown:
  // every assertion in the body below passes first. Un-skip once upstream
  // initializes that field from `didChangeDependencies` instead.
  testWidgets(
    'the Welcome story renders through the gallery config',
    (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final welcome = galleryConfig.components
          .firstWhere((component) => component.name == 'Welcome')
          .stories
          .single;
      await tester.pumpWidget(
        Builder(
          builder: (context) => welcome.buildWithConfig(context, galleryConfig),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
    },
    // accessibility_tools 3.0.0 reads Theme.of(context) during dispose().
    skip: true,
  );

  // A bare `WidgetsApp` with only `home:` throws on build under the current
  // SDK; [ccAppBuilder] supplies a `pageRouteBuilder` (plus the material_ui
  // localizations and the legacy Material bridge) and renders.
  testWidgets('ccAppBuilder renders a story preview without throwing', (
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
    // Flattens the generated components to every catalogued story.
    List<Story> allStories() => [
      for (final component in galleryConfig.components) ...component.stories,
    ];

    test('exposes the full docs + component + foundation catalogue', () {
      final topLevel = galleryConfig.components
          .map((component) => component.path.split(RegExp(r'[/\\]')).first)
          .toSet();
      expect(
        topLevel,
        containsAll(<String>{'[Docs]', '[Components]', '[Foundations]'}),
      );

      // Guards against a generator regression silently emptying the tree and
      // documents the expected breadth of the design-system gallery.
      expect(
        allStories().length,
        greaterThanOrEqualTo(120),
        reason: 'expected the full cc_ui catalogue (~190 stories)',
      );
    });

    // A builder is a required, non-null Story field, so the type system
    // already guarantees one; reading it through the widened `Story` type
    // would also trip the function-typed field's covariance check.
    test('every story has a name', () {
      for (final story in allStories()) {
        expect(story.name, isNotEmpty);
      }
    });

    test('the Docs category leads, with Welcome first', () {
      expect(galleryConfig.components.first.name, 'Welcome');
      expect(galleryConfig.components.first.path, '[Docs]');
    });
  });
}
