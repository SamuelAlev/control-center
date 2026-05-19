import 'package:cc_domain/features/governance/domain/value_objects/artifact_block.dart';
import 'package:cc_markdown/cc_markdown.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/artifacts/presentation/widgets/artifact_view.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/markdown/markdown_image.dart';
import 'package:control_center/shared/widgets/markdown/styled_markdown_body.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every markdown register must draw its images through [MarkdownImage].
///
/// The regression this pins: only the GitHub surface passed an `imageBuilder`,
/// so chat answers, ticket descriptions, meeting notes and artifacts fell
/// through to the engine's bare `Image.network` — no media proxy, no
/// aspect-correct box, no SVG handling and no way to see the picture bigger.
/// The wiring is a per-call-site named argument, so nothing but a test notices
/// when a new surface forgets it.
Widget _app(Widget child) {
  return ProviderScope(
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: CcTheme(
        data: CcThemeData.light(),
        child: Scaffold(
          body: SizedBox(
            width: 700,
            child: SingleChildScrollView(child: child),
          ),
        ),
      ),
    ),
  );
}

const _body = '![a screenshot](https://example.test/shot.png)';

void main() {
  setUp(CcMarkdownCache.clearCache);

  testWidgets('StyledMarkdownBody draws images through MarkdownImage', (
    tester,
  ) async {
    await tester.pumpWidget(_app(const StyledMarkdownBody(data: _body)));
    await tester.pump();

    expect(find.byType(MarkdownImage), findsOneWidget);
    // The fallback the wiring replaces. Its presence would mean the engine
    // never reached our builder.
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('an artifact markdown block draws images through MarkdownImage', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(const ArtifactBlockView(block: ArtifactMarkdownBlock(text: _body))),
    );
    await tester.pump();

    expect(find.byType(MarkdownImage), findsOneWidget);
  });

  group('isExpandableMarkdownImage', () {
    // The regression: the affordance was gated on the LAYOUT BRANCH ("is this
    // image narrower than the column?"), and the raster path calls that branch
    // the badge path. Most PR screenshots land in it — anything narrower than
    // the column, plus every portrait one the 600px height cap scales down —
    // so they rendered with no expand and the selection I-beam over them.
    test('a status badge is not content', () {
      expect(isExpandableMarkdownImage(width: 88, height: 20), isFalse);
      expect(isExpandableMarkdownImage(width: 18, height: 18), isFalse);
    });

    test('a screenshot narrower than the column IS content', () {
      expect(isExpandableMarkdownImage(width: 600, height: 400), isTrue);
    });

    test('a portrait screenshot the height cap shrank IS content', () {
      // 1000x2000 in a 700px column: the cap scales both axes to 300x600.
      expect(isExpandableMarkdownImage(width: 300, height: 600), isTrue);
    });

    test('a column-filling illustration IS content', () {
      expect(isExpandableMarkdownImage(width: 800, height: 294), isTrue);
    });

    test('an unknown height falls back to the width alone', () {
      expect(isExpandableMarkdownImage(width: 700), isTrue);
      expect(isExpandableMarkdownImage(width: 40), isFalse);
    });
  });

  testWidgets('the expand tap survives the selectable text region', (
    tester,
  ) async {
    // Images are inline `WidgetSpan`s inside a selection region, and a
    // selection region owns a tap recognizer of its own. If it won the arena
    // the affordance would look live everywhere and do nothing — the one
    // failure mode a hover chip cannot reveal.
    await tester.pumpWidget(
      _app(
        CcMarkdown(
          data: _body,
          selectable: true,
          imageBuilder: (url, alt, title) => CcExpandableImage(
            labels: const CcImageViewerLabels(
              expand: 'Expand',
              zoomIn: 'Zoom in',
              zoomOut: 'Zoom out',
              resetZoom: 'Reset zoom',
              close: 'Close',
            ),
            viewerBuilder: (_) => const Text('full size'),
            child: const SizedBox(width: 120, height: 80),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final target = tester.getCenter(find.byType(CcExpandableImage));

    // The other half of the same bug report: a `SelectionArea` installs an
    // I-beam over its whole subtree, so an image that is NOT wrapped reads as
    // prose to the pointer. The wrap has to win that, or the affordance is
    // invisible on a mouse.
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await mouse.moveTo(target);
    await tester.pumpAndSettle();
    expect(
      RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
      SystemMouseCursors.zoomIn,
    );

    await tester.tapAt(target);
    await tester.pumpAndSettle();

    expect(find.text('full size'), findsOneWidget);
  });

  group('appMarkdownImageBuilder', () {
    test('is a stable identity — the streaming block memo keys on it', () {
      // Two reads must be the SAME object: `CcStreamingMarkdown` compares
      // callbacks with `identical`, so a per-build closure would re-render
      // every settled block on every delta of a live answer.
      expect(identical(appMarkdownImageBuilder, appMarkdownImageBuilder), true);
    });

    test('a relative path degrades to its alt text, never a doomed fetch', () {
      final widget = appMarkdownImageBuilder('./local.png', 'a diagram', null);
      expect(widget, isA<Text>());
      expect((widget as Text).data, 'a diagram');
    });

    test('an absolute URL becomes a MarkdownImage', () {
      final widget = appMarkdownImageBuilder(
        'https://example.test/x.png',
        'alt',
        null,
      );
      expect(widget, isA<MarkdownImage>());
      expect((widget as MarkdownImage).uri.host, 'example.test');
    });
  });
}
