import 'package:cc_gallery/main.dart';
import 'package:cc_gallery/main.directories.g.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widgetbook/widgetbook.dart';

void main() {
  testWidgets('cc_ui gallery boots without throwing', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const CcGalleryApp());
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.takeException(), isNull);
    expect(find.byType(CcGalleryApp), findsOneWidget);
  });

  // The Workbench only invokes the appBuilder once a use-case is *selected*
  // (otherwise it shows the home page), so booting alone never exercised the
  // preview path. This pumps the builder directly: the stock widgetbook
  // `widgetsAppBuilder` (a `WidgetsApp` with only `home:`) throws on build under
  // the current SDK; [ccAppBuilder] supplies a `pageRouteBuilder` and renders.
  testWidgets('ccAppBuilder renders a use-case preview without throwing',
      (tester) async {
    await tester.pumpWidget(
      Builder(
        builder: (context) => ccAppBuilder(
          context,
          const Center(child: Text('preview', textDirection: TextDirection.ltr)),
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
