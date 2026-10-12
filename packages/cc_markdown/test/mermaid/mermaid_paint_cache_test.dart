import 'package:cc_markdown/cc_markdown.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// The paint/geometry split of the render-plan memo.
///
/// A stylesheet change that cannot move a primitive reuses the laid-out scene;
/// anything that changes what text measures, how much room a shape needs or the
/// host's text scale re-lays out. Reused geometry is always repainted through a
/// ruler built from the CURRENT styles, never the one it was measured with.
///
/// "Same metrics" is Flutter's own verdict (`TextStyle.compareTo`), so the
/// invalidation rows below include the fields Flutter groups with layout, even
/// where a human would call them paint.
///
/// Every invariant is stated in geometry identity, sizes and resolved text
/// styles, so none of it depends on the literal text of a diagram, on rendered
/// pixels, or on any hidden cache field.
void main() {
  const source = 'flowchart TD\n  A[Start] -->|yes| B[Finish]';

  /// The engine default: dark-on-light paint with 13px labels.
  const light = CcMermaidStyle();

  /// Same METRICS and same optional-style nullness as [light], different paint
  /// — what a dark theme builds.
  const dark = CcMermaidStyle(
    label: TextStyle(fontSize: 13, color: Color(0xFFE6EDF3)),
    mutedTextColor: Color(0xFF8B949E),
    nodeFill: Color(0xFF161B22),
    nodeBorder: Color(0xFF30363D),
    edgeColor: Color(0xFF8B949E),
    edgeLabelFill: Color(0xFF161B22),
    background: Color(0xFF0D1117),
    seriesPalette: [Color(0xFF58A6FF), Color(0xFF3FB950)],
  );

  CcMermaidRenderPlan planFor(CcMermaidStyle style, {TextScaler? textScaler}) =>
      resolveMermaidRenderPlan(
        source: source,
        style: style,
        textScaler: textScaler ?? TextScaler.noScaling,
      );

  List<CcMermaidTextPrim> textRuns(CcMermaidScene scene) =>
      scene.primitives.whereType<CcMermaidTextPrim>().toList();

  setUp(() {
    clearMermaidParseCache();
    clearMermaidSceneCache();
  });

  group('geometry identity', () {
    test('a paint-only recolor reuses the laid-out scene', () {
      final first = planFor(light);
      final recolored = planFor(dark);

      expect(first.reason, isNull);
      expect(recolored.reason, isNull);
      expect(identical(recolored.scene, first.scene), isTrue);
      expect(identical(recolored.diagram, first.diagram), isTrue);
      expect(recolored.scene!.size, first.scene!.size);
      expect(first.scene!.primitives, isNotEmpty);
    });

    test('reused text keeps its boxes, roles and alignment', () {
      final first = planFor(light);
      final recolored = planFor(dark);

      final before = textRuns(first.scene!);
      final after = textRuns(recolored.scene!);

      expect(before, isNotEmpty);
      expect(after.length, before.length);
      for (var i = 0; i < before.length; i++) {
        expect(after[i].rect, before[i].rect, reason: 'run $i');
        expect(after[i].role, before[i].role, reason: 'run $i');
        expect(after[i].align, before[i].align, reason: 'run $i');
      }
    });

    test('recolored text is measured and painted with the current styles', () {
      final first = planFor(light);
      final recolored = planFor(dark);

      // The ruler is the ONE place glyphs come from, so its resolved styles
      // are the colors text is painted in.
      expect(identical(recolored.ruler, first.ruler), isFalse);
      expect(recolored.ruler!.style, dark);
      expect(
        recolored.ruler!.styleFor(CcMermaidTextRole.label).color,
        dark.label.color,
      );
      expect(
        recolored.ruler!.styleFor(CcMermaidTextRole.legend).color,
        dark.resolvedLegend.color,
      );
      expect(
        recolored.ruler!.styleFor(CcMermaidTextRole.cluster).color,
        dark.resolvedClusterLabel.color,
      );
      expect(
        recolored.ruler!.styleFor(CcMermaidTextRole.edgeLabel).color,
        dark.resolvedEdgeLabel.color,
      );
      expect(
        recolored.ruler!.styleFor(CcMermaidTextRole.label).color,
        isNot(light.label.color),
      );

      // Reuse is only sound because the metrics did not move.
      expect(
        recolored.ruler!.measure('probe', CcMermaidTextRole.label),
        first.ruler!.measure('probe', CcMermaidTextRole.label),
      );
    });

    test('an explicit text style recolors without relaying out', () {
      const legendColor = Color(0xFF000000);
      const recoloredLegend = Color(0xFF8B949E);
      final styled = light.copyWith(
        legend: const TextStyle(fontSize: 11.5, color: legendColor),
      );
      final recolored = styled.copyWith(
        legend: const TextStyle(fontSize: 11.5, color: recoloredLegend),
      );

      final first = planFor(styled);
      final second = planFor(recolored);

      expect(identical(second.scene, first.scene), isTrue);
      expect(identical(second.ruler, first.ruler), isFalse);
      expect(
        first.ruler!.styleFor(CcMermaidTextRole.legend).color,
        legendColor,
      );
      expect(
        second.ruler!.styleFor(CcMermaidTextRole.legend).color,
        recoloredLegend,
      );
    });

    test('flipping paint back and forth keeps reusing one scene', () {
      final lightPlan = planFor(light);
      final darkPlan = planFor(dark);
      final lightAgain = planFor(light);
      final darkAgain = planFor(dark);

      expect(identical(lightAgain, lightPlan), isTrue);
      expect(identical(darkAgain, darkPlan), isTrue);
      expect(identical(darkPlan.scene, lightPlan.scene), isTrue);
      expect(identical(darkAgain.ruler, lightPlan.ruler), isFalse);
    });

    test('every paint-only stylesheet change reuses the geometry', () {
      final base = planFor(light);
      final paintOnly = <String, CcMermaidStyle>{
        'label color': light.copyWith(
          label: light.label.copyWith(color: const Color(0xFFE6EDF3)),
        ),
        'label decoration': light.copyWith(
          label: light.label.copyWith(
            decoration: TextDecoration.underline,
            decorationColor: const Color(0xFFFF0000),
            decorationStyle: TextDecorationStyle.dashed,
            decorationThickness: 2,
          ),
        ),
        'label background color': light.copyWith(
          label: light.label.copyWith(backgroundColor: const Color(0xFF00FF00)),
        ),
        'muted text': light.copyWith(mutedTextColor: const Color(0xFF8B949E)),
        'node paint': light.copyWith(
          nodeFill: const Color(0xFF161B22),
          nodeBorder: const Color(0xFF30363D),
        ),
        'accent': light.copyWith(accent: const Color(0xFFFF0000)),
        'cluster paint': light.copyWith(
          clusterFill: const Color(0x22000000),
          clusterBorder: const Color(0xFF000000),
        ),
        'note paint': light.copyWith(
          noteFill: const Color(0xFFFF0000),
          noteBorder: const Color(0xFF00FF00),
        ),
        'edge color': light.copyWith(edgeColor: const Color(0xFFFF00FF)),
        'edge label fill': light.copyWith(
          edgeLabelFill: const Color(0xFF000000),
        ),
        'activation fill': light.copyWith(
          activationFill: const Color(0x33000000),
        ),
        'frame paint': light.copyWith(
          frameFill: const Color(0x11000000),
          frameBorder: const Color(0xFF111111),
        ),
        'divider': light.copyWith(dividerColor: const Color(0xFF222222)),
        'background': light.copyWith(background: const Color(0xFF0D1117)),
        'series palette': light.copyWith(
          seriesPalette: const [Color(0xFF58A6FF), Color(0xFF3FB950)],
        ),
        'stroke widths': light.copyWith(
          edgeStrokeWidth: 4,
          thickStrokeWidth: 6,
        ),
        'dash pattern': light.copyWith(dashPattern: const [1, 1]),
        'arrow size': light.copyWith(arrowLength: 20, arrowWidth: 18),
        'view fit': light.copyWith(maxScale: 2, minScale: 0.2),
      };

      paintOnly.forEach((name, style) {
        expect(
          identical(planFor(style).scene, base.scene),
          isTrue,
          reason: name,
        );
      });
    });
  });

  group('geometry invalidation', () {
    test('a change to text or shape metrics re-lays out', () {
      final greenPaint = Paint()..color = const Color(0xFF00FF00);
      final base = planFor(light);
      final relayouts = <String, CcMermaidStyle>{
        'label size': light.copyWith(label: light.label.copyWith(fontSize: 15)),
        'label family': light.copyWith(
          label: light.label.copyWith(fontFamily: 'monospace'),
        ),
        'label fallback': light.copyWith(
          label: light.label.copyWith(fontFamilyFallback: const ['Menlo']),
        ),
        'label package': light.copyWith(
          label: light.label.copyWith(fontFamily: 'Mono', package: 'fonts'),
        ),
        'label weight': light.copyWith(
          label: light.label.copyWith(fontWeight: FontWeight.w700),
        ),
        'label style': light.copyWith(
          label: light.label.copyWith(fontStyle: FontStyle.italic),
        ),
        'label features': light.copyWith(
          label: light.label.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        'label variations': light.copyWith(
          label: light.label.copyWith(
            fontVariations: const [FontVariation('wght', 700)],
          ),
        ),
        'label letter spacing': light.copyWith(
          label: light.label.copyWith(letterSpacing: 2),
        ),
        'label word spacing': light.copyWith(
          label: light.label.copyWith(wordSpacing: 4),
        ),
        'label line height': light.copyWith(
          label: light.label.copyWith(height: 1.8),
        ),
        'label leading distribution': light.copyWith(
          label: light.label.copyWith(
            leadingDistribution: TextLeadingDistribution.even,
          ),
        ),
        'label locale': light.copyWith(
          label: light.label.copyWith(locale: const Locale('ar')),
        ),
        // Flutter's own comparison groups these with layout.
        'label shadows': light.copyWith(
          label: light.label.copyWith(
            shadows: const [Shadow(color: Color(0xFF000000), blurRadius: 2)],
          ),
        ),
        'label foreground': light.copyWith(
          label: TextStyle(fontSize: 13, foreground: greenPaint),
        ),
        // Declaring an optional style is a different geometry even when its
        // metrics match the implicit fallback.
        'explicit title': light.copyWith(
          title: const TextStyle(fontSize: 20, color: Color(0xFF000000)),
        ),
        'explicit edge label': light.copyWith(
          edgeLabel: const TextStyle(fontSize: 16, color: Color(0xFF000000)),
        ),
        'node padding': light.copyWith(nodePadding: const EdgeInsets.all(20)),
        'node spacing': light.copyWith(nodeSpacing: 48),
        'rank spacing': light.copyWith(rankSpacing: 80),
        'cluster padding': light.copyWith(clusterPadding: 32),
        'canvas padding': light.copyWith(
          canvasPadding: const EdgeInsets.all(24),
        ),
        'corner radius': light.copyWith(cornerRadius: 14),
        'edge corner radius': light.copyWith(edgeCornerRadius: 20),
        'line spacing': light.copyWith(lineSpacing: 9),
      };

      relayouts.forEach((name, style) {
        expect(
          identical(planFor(style).scene, base.scene),
          isFalse,
          reason: name,
        );
      });
    });

    test('an implicit style is not assumed equal to a resolved one', () {
      final implicit = planFor(light);
      // `resolvedNote` has exactly the metrics the implicit fallback resolves
      // to, so only a hand-written resolution table could call these equal.
      final explicit = planFor(light.copyWith(note: light.resolvedNote));

      expect(identical(explicit.scene, implicit.scene), isFalse);
    });

    test('a metric change inside an explicit text style re-lays out', () {
      final styled = light.copyWith(
        note: const TextStyle(fontSize: 12, color: Color(0xFF000000)),
      );
      final base = planFor(styled);
      final bigger = styled.copyWith(
        note: const TextStyle(fontSize: 16, color: Color(0xFF000000)),
      );

      expect(identical(planFor(bigger).scene, base.scene), isFalse);
    });

    test('metric changes move the geometry, not just the cache key', () {
      final base = planFor(light);

      final bigger = planFor(
        light.copyWith(label: light.label.copyWith(fontSize: 20)),
      );
      expect(bigger.scene!.size.width, greaterThan(base.scene!.size.width));

      final padded = planFor(
        light.copyWith(nodePadding: const EdgeInsets.all(24)),
      );
      expect(padded.scene!.size.height, greaterThan(base.scene!.size.height));
      expect(padded.scene!.size.width, greaterThan(base.scene!.size.width));
    });

    test('a text scale change re-lays out and measures bigger', () {
      final base = planFor(light);
      final scaled = planFor(light, textScaler: const TextScaler.linear(2));

      expect(identical(scaled.scene, base.scene), isFalse);
      expect(scaled.scene!.size.width, greaterThan(base.scene!.size.width));
    });
  });

  group('memo bounds', () {
    test('identical input still resolves to one plan object', () {
      final first = planFor(light);
      final second = planFor(light);
      expect(identical(first, second), isTrue);

      final darkFirst = planFor(dark);
      final darkSecond = planFor(dark);
      expect(identical(darkFirst, darkSecond), isTrue);

      // A different style is a different plan over the same geometry.
      expect(identical(first, darkFirst), isFalse);
      expect(identical(first.scene, darkFirst.scene), isTrue);
    });

    test('paint churn never evicts the geometry it reuses', () {
      final first = planFor(light);

      for (var i = 0; i < 32; i++) {
        final variant = light.copyWith(
          label: light.label.copyWith(color: Color(0xFF000000 | i)),
        );
        expect(
          identical(planFor(variant).scene, first.scene),
          isTrue,
          reason: 'paint variant $i',
        );
      }

      // 32 distinct paint styles later, the single geometry entry is still the
      // one the default style resolves to.
      expect(identical(planFor(light).scene, first.scene), isTrue);
    });

    test('the memos stay bounded: old plans and scenes are evicted', () {
      final first = planFor(light);

      for (var i = 0; i < 64; i++) {
        resolveMermaidRenderPlan(
          source: 'flowchart LR\n  N$i --> M$i',
          style: light,
        );
      }

      // The first source is gone from BOTH memos: a paint-only variant can no
      // longer reuse its geometry...
      expect(identical(planFor(dark).scene, first.scene), isFalse);
      // ...and the original style re-lays out instead of handing back the old
      // plan.
      expect(identical(planFor(light), first), isFalse);

      // Recently resolved sources still share one geometry across paint styles.
      final recentLight = resolveMermaidRenderPlan(
        source: 'flowchart LR\n  N63 --> M63',
        style: light,
      );
      final recentDark = resolveMermaidRenderPlan(
        source: 'flowchart LR\n  N63 --> M63',
        style: dark,
      );
      expect(identical(recentDark.scene, recentLight.scene), isTrue);
    });
  });
}
