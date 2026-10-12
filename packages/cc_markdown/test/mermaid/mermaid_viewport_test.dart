import 'package:cc_markdown/cc_markdown.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

const _style = CcMermaidStyle();

Widget _host({
  required String source,
  required CcMermaidViewportController controller,
  Size size = const Size(300, 220),
  CcMermaidStyle style = _style,
  TextDirection direction = TextDirection.ltr,
  void Function(String, String?)? onTapNode,
}) => Directionality(
  textDirection: direction,
  child: MediaQuery(
    data: const MediaQueryData(),
    child: Center(
      child: SizedBox.fromSize(
        size: size,
        child: CcMermaidView(
          source: source,
          style: style,
          interactive: true,
          controller: controller,
          onTapNode: onTapNode,
        ),
      ),
    ),
  ),
);

void _expectFits(CcMermaidViewportController controller, Size scene) {
  final rect = MatrixUtils.transformRect(controller.value, Offset.zero & scene);
  expect(rect.left, greaterThanOrEqualTo(-0.001));
  expect(rect.top, greaterThanOrEqualTo(-0.001));
  expect(rect.right, lessThanOrEqualTo(controller.viewportSize.width + 0.001));
  expect(
    rect.bottom,
    lessThanOrEqualTo(controller.viewportSize.height + 0.001),
  );
  expect(rect.center.dx, closeTo(controller.viewportSize.width / 2, 0.001));
  expect(rect.center.dy, closeTo(controller.viewportSize.height / 2, 0.001));
}

void main() {
  setUp(() {
    clearMermaidSceneCache();
    clearMermaidParseCache();
  });

  for (final direction in ['TD', 'LR']) {
    testWidgets('fits every node of a large $direction diagram, including RTL', (
      tester,
    ) async {
      final controller = CcMermaidViewportController();
      addTearDown(controller.dispose);
      final source =
          'flowchart $direction\n'
          '${List.generate(30, (i) => 'n$i[Step $i] --> n${i + 1}').join('\n')}';
      final scene = resolveMermaidRenderPlan(
        source: source,
        style: _style,
      ).scene!;
      await tester.pumpWidget(
        _host(
          source: source,
          controller: controller,
          direction: TextDirection.rtl,
        ),
      );
      await tester.pumpAndSettle();
      _expectFits(controller, scene.size);
      expect(find.byType(SingleChildScrollView), findsNothing);
      expect(controller.minScale, lessThan(0.5));

      // A drag must pan the whole scene, not an inner horizontal scroll view.
      final fitted = controller.value.clone();
      await tester.drag(find.byType(InteractiveViewer), const Offset(35, 25));
      await tester.pumpAndSettle();
      expect(controller.value, isNot(fitted));
      expect(controller.fit(), isTrue);
      await tester.pump();
      expect(controller.value, fitted);
      _expectFits(controller, scene.size);
    });
  }

  testWidgets(
    'resize and source changes refit, recoloring preserves pan/zoom',
    (tester) async {
      final controller = CcMermaidViewportController();
      addTearDown(controller.dispose);
      const source = 'flowchart TD\n A[Start] --> B[Finish]';
      await tester.pumpWidget(_host(source: source, controller: controller));
      await tester.pumpAndSettle();
      controller.value = Matrix4.identity()
        ..translateByDouble(25, 30, 0, 1)
        ..scaleByDouble(1.5, 1.5, 1.5, 1);
      final adjusted = controller.value.clone();
      final dark = _style.copyWith(
        nodeFill: const Color(0xff171614),
        label: _style.label.copyWith(color: const Color(0xffeeeeee)),
      );
      await tester.pumpWidget(
        _host(source: source, controller: controller, style: dark),
      );
      await tester.pumpAndSettle();
      expect(controller.value, adjusted);

      await tester.pumpWidget(
        _host(
          source: source,
          controller: controller,
          size: const Size(450, 120),
          style: dark,
        ),
      );
      await tester.pumpAndSettle();
      final scene = resolveMermaidRenderPlan(
        source: source,
        style: dark,
      ).scene!;
      _expectFits(controller, scene.size);
      expect(controller.value, isNot(adjusted));

      const changed = 'flowchart LR\n A[Start] --> B[Middle] --> C[Finish]';
      await tester.pumpWidget(_host(source: changed, controller: controller));
      await tester.pumpAndSettle();
      _expectFits(
        controller,
        resolveMermaidRenderPlan(source: changed, style: _style).scene!.size,
      );
    },
  );

  testWidgets('node taps follow the fitted and zoomed scene transform', (
    tester,
  ) async {
    final controller = CcMermaidViewportController();
    addTearDown(controller.dispose);
    const source =
        'flowchart TD\n A[Open] --> B[Other]\n'
        'click A "https://example.com"';
    final taps = <(String, String?)>[];
    await tester.pumpWidget(
      _host(
        source: source,
        controller: controller,
        onTapNode: (id, href) => taps.add((id, href)),
      ),
    );
    await tester.pumpAndSettle();
    final target = resolveMermaidRenderPlan(
      source: source,
      style: _style,
    ).scene!.hitTargets.single;
    final origin = tester.getTopLeft(find.byType(InteractiveViewer));
    await tester.tapAt(
      origin + MatrixUtils.transformPoint(controller.value, target.rect.center),
    );
    expect(taps, [('A', 'https://example.com')]);

    controller.value = Matrix4.identity()
      ..translateByDouble(
        150 - target.rect.center.dx * 2,
        110 - target.rect.center.dy * 2,
        0,
        1,
      )
      ..scaleByDouble(2, 2, 2, 1);
    await tester.pump();
    await tester.tapAt(origin + const Offset(150, 110));
    expect(taps, [('A', 'https://example.com'), ('A', 'https://example.com')]);
  });

  testWidgets(
    'replacing a controller detaches the old one and fits the new one',
    (tester) async {
      final first = CcMermaidViewportController();
      final second = CcMermaidViewportController();
      addTearDown(first.dispose);
      addTearDown(second.dispose);
      const source = 'flowchart TD\n A --> B';
      await tester.pumpWidget(_host(source: source, controller: first));
      await tester.pumpAndSettle();
      await tester.pumpWidget(_host(source: source, controller: second));
      await tester.pumpAndSettle();
      expect(first.fit(), isFalse);
      _expectFits(
        second,
        resolveMermaidRenderPlan(source: source, style: _style).scene!.size,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      expect(second.fit(), isFalse);
    },
  );
}
