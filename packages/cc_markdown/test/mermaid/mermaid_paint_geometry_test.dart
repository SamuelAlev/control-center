import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cc_markdown/cc_markdown.dart';
import 'package:cc_markdown/src/mermaid/render/mermaid_painter.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Retained, scene-space paint geometry in `CcMermaidScenePainter`.
///
/// Layout hands the painter the same scene instance for as long as the diagram's
/// GEOMETRY holds: a recolor, a rescale and a rebuilt widget all reuse it and
/// build a new painter around it. That makes paint the place work repeats —
/// tracing every outline, rounding every polyline and walking every path's
/// metrics for dashes, frame after frame.
///
/// These tests pin down both halves of retention. Skipping work is invisible in
/// a raster (a reused path strokes the same pixels as a fresh one), so the
/// builder counts say the work was skipped; and comparing a warm paint against a
/// COLD layout says the thing that was skipped still produced the answer a cold
/// layout produces — current colors, current dashes. A cache that skipped work
/// and drew last paint's appearance would be worse than no cache at all, which
/// is why every reuse assertion here is paired with a rendered one.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const source = 'flowchart TD\n  A(Start) -.-> B{Choose}\n  B --> C[Finish]';

  /// The engine default: dark-on-light paint, no canvas background.
  const light = CcMermaidStyle();

  /// Same METRICS as [light] — so the plan memo reuses one scene for both —
  /// with different colors on every role a flowchart uses.
  const dark = CcMermaidStyle(
    label: TextStyle(fontSize: 13, color: Color(0xFFE6EDF3)),
    mutedTextColor: Color(0xFF8B949E),
    nodeFill: Color(0xFF161B22),
    nodeBorder: Color(0xFF30363D),
    edgeColor: Color(0xFF8B949E),
    edgeLabelFill: Color(0xFF161B22),
    background: Color(0xFF0D1117),
  );

  setUp(() {
    clearMermaidParseCache();
    clearMermaidSceneCache();
    clearMermaidPaintGeometryCache();
  });

  CcMermaidRenderPlan planFor(CcMermaidStyle style) =>
      resolveMermaidRenderPlan(source: source, style: style);

  CcMermaidScenePainter painterFor(
    CcMermaidRenderPlan plan,
    CcMermaidStyle style, {
    double scale = 1,
  }) => CcMermaidScenePainter(
    scene: plan.scene!,
    style: style,
    ruler: plan.ruler!,
    scale: scale,
  );

  /// The scene's own size, integral so it can be an image.
  Size canvasSize(CcMermaidScene scene) =>
      Size(scene.size.width.ceilToDouble(), scene.size.height.ceilToDouble());

  /// Paints [painter] offscreen and returns its raw pixels.
  ///
  /// Pixels, not command counts: "is the retained geometry still drawing the
  /// right thing" is a question only a raster can answer.
  Future<Uint8List> raster(CcMermaidScenePainter painter, Size size) async {
    final recorder = ui.PictureRecorder();
    painter.paint(Canvas(recorder), size);
    final picture = recorder.endRecording();
    final image = await picture.toImage(
      size.width.round(),
      size.height.round(),
    );
    final bytes = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    image.dispose();
    picture.dispose();
    return bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes);
  }

  /// Whether anything at all was drawn (nothing here is a blank comparison).
  bool hasInk(Uint8List rgba) {
    for (var i = 3; i < rgba.length; i += 4) {
      if (rgba[i] != 0) {
        return true;
      }
    }
    return false;
  }

  List<CcMermaidShapePrim> traceableShapes(CcMermaidScene scene) => scene
      .primitives
      .whereType<CcMermaidShapePrim>()
      .where((shape) => shape.shape != CcMermaidNodeShape.endPoint)
      .toList();

  List<CcMermaidPathPrim> drawablePaths(CcMermaidScene scene) => scene
      .primitives
      .whereType<CcMermaidPathPrim>()
      .where((path) => path.points.length >= 2)
      .toList();

  test(
    'a repeated paint traces each shape and polyline exactly once',
    () async {
      final plan = planFor(light);
      final scene = plan.scene!;
      final size = canvasSize(scene);

      expect(mermaidPaintPathBuilds(scene), 0, reason: 'nothing painted yet');
      expect(mermaidPaintDashBuilds(scene), 0);

      await raster(painterFor(plan, light), size);

      // Every traceable primitive, traced once — no shape traced twice, none
      // missed.
      expect(
        mermaidPaintPathBuilds(scene),
        traceableShapes(scene).length + drawablePaths(scene).length,
      );
      final dotted = drawablePaths(
        scene,
      ).where((path) => path.stroke == CcMermaidEdgeStroke.dotted).length;
      expect(dotted, greaterThan(0), reason: 'the fixture needs a dotted edge');
      expect(mermaidPaintDashBuilds(scene), dotted);

      // Same painter, second paint: the geometry is already here.
      final paths = mermaidPaintPathBuilds(scene);
      final dashes = mermaidPaintDashBuilds(scene);
      await raster(painterFor(plan, light), size);
      await raster(painterFor(plan, light, scale: 1.5), size * 1.5);
      expect(mermaidPaintPathBuilds(scene), paths);
      expect(mermaidPaintDashBuilds(scene), dashes);
    },
  );

  test('a rebuilt painter at another scale traces nothing new', () async {
    final plan = planFor(light);
    final scene = plan.scene!;
    final size = canvasSize(scene);

    final unscaled = await raster(painterFor(plan, light), size);
    final paths = mermaidPaintPathBuilds(scene);

    // What a zoom does: the same scene, a new painter, a bigger canvas. Retained
    // geometry is in SCENE space, so the transform costs it nothing.
    final zoomed = await raster(painterFor(plan, light, scale: 2), size * 2);
    expect(mermaidPaintPathBuilds(scene), paths);
    expect(
      listEquals(unscaled, zoomed),
      isFalse,
      reason: 'the zoom is visible',
    );

    // It is a real re-rasterization, not a magnified picture: a cold layout at
    // the same scale draws the identical pixels.
    clearMermaidSceneCache();
    final cold = planFor(light);
    expect(identical(cold.scene, scene), isFalse);
    expect(cold.scene!.size, scene.size);
    final coldZoomed = await raster(
      painterFor(cold, light, scale: 2),
      canvasSize(cold.scene!) * 2,
    );
    expect(listEquals(zoomed, coldZoomed), isTrue);
  });

  test(
    'a recolored scene reuses its geometry and paints current colors',
    () async {
      final warm = planFor(light);
      final recolored = planFor(dark);
      // The whole point: paint-only style changes share one scene instance.
      expect(identical(recolored.scene, warm.scene), isTrue);

      final scene = warm.scene!;
      final size = canvasSize(scene);
      final darkBytes = await raster(painterFor(recolored, dark), size);
      expect(hasInk(darkBytes), isTrue);
      expect(
        mermaidPaintPathBuilds(scene),
        traceableShapes(scene).length + drawablePaths(scene).length,
        reason: 'recoloring must not re-trace what did not move',
      );

      // The reused geometry, painted with the CURRENT stylesheet, matches a
      // cold layout of that stylesheet exactly — the colors are not retained.
      clearMermaidSceneCache();
      final cold = planFor(dark);
      expect(identical(cold.scene, scene), isFalse);
      expect(cold.scene!.size, scene.size);
      final coldBytes = await raster(
        painterFor(cold, dark),
        canvasSize(cold.scene!),
      );
      expect(listEquals(darkBytes, coldBytes), isTrue);

      final lightBytes = await raster(painterFor(warm, light), size);
      expect(listEquals(lightBytes, darkBytes), isFalse);
    },
  );

  test('a dash pattern change re-cuts the dashes and repaints them', () async {
    final plan = planFor(light);
    final scene = plan.scene!;
    final size = canvasSize(scene);
    final beforeDashes = await raster(painterFor(plan, light), size);

    final paths = mermaidPaintPathBuilds(scene);
    final dotted = drawablePaths(
      scene,
    ).where((path) => path.stroke == CcMermaidEdgeStroke.dotted).length;
    expect(dotted, greaterThan(0));
    expect(mermaidPaintDashBuilds(scene), dotted);

    // A dash pattern decorates a stroke; it moves nothing, so layout is not
    // repeated and the SAME scene reaches the painter with a new pattern.
    const sparser = [1.0, 6.0];
    final redashedStyle = light.copyWith(dashPattern: sparser);
    final redashed = planFor(redashedStyle);
    expect(identical(redashed.scene, scene), isTrue);
    expect(sparser, isNot(equals(light.dashPattern)));

    final afterDashes = await raster(painterFor(redashed, redashedStyle), size);
    expect(
      mermaidPaintPathBuilds(scene),
      paths,
      reason: 'the same paths are still the right ones',
    );
    expect(
      mermaidPaintDashBuilds(scene),
      dotted * 2,
      reason: 'the dashes are cut for the new pattern, once',
    );
    expect(
      listEquals(beforeDashes, afterDashes),
      isFalse,
      reason: 'the new pattern is visible',
    );

    // Painting again with the new pattern reuses the segments it just cut.
    await raster(painterFor(redashed, redashedStyle), size);
    expect(mermaidPaintDashBuilds(scene), dotted * 2);

    // And those segments draw what a cold layout draws for that pattern.
    clearMermaidSceneCache();
    final cold = planFor(redashedStyle);
    expect(identical(cold.scene, scene), isFalse);
    final coldBytes = await raster(
      painterFor(cold, redashedStyle),
      canvasSize(cold.scene!),
    );
    expect(listEquals(afterDashes, coldBytes), isTrue);
  });

  test('a corner radius change re-traces the outlines', () async {
    final plan = planFor(light);
    final scene = plan.scene!;
    final size = canvasSize(scene);
    final square = await raster(painterFor(plan, light), size);
    final paths = mermaidPaintPathBuilds(scene);

    // The painter reads the radius from the STYLESHEET, so a scene that reaches
    // it with a different one must not keep outlines traced for the old radius.
    final roundedStyle = light.copyWith(cornerRadius: 14);
    final rounded = await raster(painterFor(plan, roundedStyle), size);
    expect(
      mermaidPaintPathBuilds(scene),
      greaterThan(paths),
      reason: 'a rounding is a different outline',
    );
    expect(
      listEquals(square, rounded),
      isFalse,
      reason: 'the rounder corners are visible (the fixture has a round rect)',
    );

    // Re-traced once for the new radius, then kept.
    final retraced = mermaidPaintPathBuilds(scene);
    await raster(painterFor(plan, roundedStyle), size);
    expect(mermaidPaintPathBuilds(scene), retraced);
  });

  test('retained geometry stays bounded, so old scenes are dropped', () async {
    final plan = planFor(light);
    final scene = plan.scene!;
    await raster(painterFor(plan, light), canvasSize(scene));
    expect(mermaidPaintPathBuilds(scene), greaterThan(0));

    // More distinct scenes than the retention window holds.
    for (var i = 0; i < 12; i++) {
      final other = resolveMermaidRenderPlan(
        source: 'flowchart LR\n  N$i(One) --> M$i(Two)',
        style: light,
      );
      await raster(painterFor(other, light), canvasSize(other.scene!));
    }

    // The first scene aged out rather than being pinned for the session; a
    // later paint traces again instead of drawing geometry nobody kept.
    expect(mermaidPaintPathBuilds(scene), 0);
    expect(mermaidPaintDashBuilds(scene), 0);
    await raster(painterFor(plan, light), canvasSize(scene));
    expect(mermaidPaintPathBuilds(scene), greaterThan(0));
  });

  test('dashed outlines follow a changed corner radius', () async {
    const scene = CcMermaidScene(
      size: Size(140, 80),
      primitives: [
        CcMermaidShapePrim(
          rect: Rect.fromLTWH(10, 10, 120, 60),
          shape: CcMermaidNodeShape.roundRect,
          role: CcMermaidPaintRole.node,
          dashed: true,
          filled: false,
        ),
      ],
    );
    final ruler = planFor(light).ruler!;
    Future<Uint8List> paint(CcMermaidStyle style) => raster(
      CcMermaidScenePainter(scene: scene, style: style, ruler: ruler),
      scene.size,
    );
    final before = await paint(light);
    final roundedStyle = light.copyWith(cornerRadius: 24);
    final warm = await paint(roundedStyle);
    clearMermaidPaintGeometryCache();
    final cold = await paint(roundedStyle);
    expect(listEquals(before, warm), isFalse);
    expect(listEquals(warm, cold), isTrue);
  });
}
