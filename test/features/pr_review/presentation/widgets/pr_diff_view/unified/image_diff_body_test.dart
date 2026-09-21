import 'dart:ui' as ui;

import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/image_diff_resolution.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view/unified/image_diff_body.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../../helpers/test_wrap.dart';

void main() {
  const comparison = ImageDiffResolution(
    baseRef: 'blob:sha256:aa',
    headRef: 'blob:sha256:bb',
    overlayRef: 'blob:sha256:cc',
    mediaType: 'image/png',
    changedPercent: 12.5,
    isIdentical: false,
  );

  const noOverlay = ImageDiffResolution(
    baseRef: 'blob:sha256:aa',
    headRef: 'blob:sha256:bb',
    mediaType: 'image/png',
    changedPercent: 100,
    isIdentical: false,
  );

  testWidgets('shows deleted/added labels for a modified raster', (
    tester,
  ) async {
    await tester.pumpWidget(
      testWrap(
        const ImageDiffBody(
          path: 'shot.png',
          status: PrFileStatus.modified,
          workspaceId: 'ws',
          baseRef: 'base',
          headRef: 'head',
          cached: comparison,
        ),
      ),
    );
    await tester.pump();
    expect(find.byKey(const Key('image-diff-body')), findsOneWidget);
    expect(find.text('Deleted'), findsOneWidget);
    expect(find.text('Added'), findsOneWidget);
    expect(find.text('2-up'), findsOneWidget);
    expect(find.text('Swipe'), findsOneWidget);
    expect(find.text('Difference'), findsOneWidget);
    // Compact GitHub-style chrome, not a 360px well around missing pictures.
    expect(
      tester.getSize(find.byKey(const Key('image-diff-body'))).height,
      lessThan(280),
    );
  });

  testWidgets('hides difference mode when there is no overlay ref', (
    tester,
  ) async {
    await tester.pumpWidget(
      testWrap(
        const ImageDiffBody(
          path: 'shot.png',
          status: PrFileStatus.modified,
          workspaceId: 'ws',
          baseRef: 'base',
          headRef: 'head',
          cached: noOverlay,
        ),
      ),
    );
    await tester.pump();
    expect(find.text('2-up'), findsOneWidget);
    expect(find.text('Swipe'), findsOneWidget);
    expect(find.text('Difference'), findsNothing);
  });

  testWidgets('swipe mode paints the divider below the labels', (tester) async {
    await tester.pumpWidget(
      testWrap(
        const SizedBox(
          width: 800,
          height: 600,
          child: ImageDiffBody(
            path: 'shot.png',
            status: PrFileStatus.modified,
            workspaceId: 'ws',
            baseRef: 'base',
            headRef: 'head',
            cached: comparison,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('Swipe'));
    await tester.pump();
    expect(find.byKey(const Key('image-diff-swipe-divider')), findsOneWidget);
    expect(find.text('Deleted'), findsOneWidget);
    expect(find.text('Added'), findsOneWidget);
    final deleted = tester.getRect(find.text('Deleted'));
    final added = tester.getRect(find.text('Added'));
    final divider = tester.getRect(
      find.byKey(const Key('image-diff-swipe-divider')),
    );
    expect(deleted.bottom, lessThanOrEqualTo(divider.top));
    expect(added.bottom, lessThanOrEqualTo(divider.top));
    expect(deleted.left, lessThan(added.left));
  });

  testWidgets('difference mode shows the overlay and percent caption', (
    tester,
  ) async {
    await tester.pumpWidget(
      testWrap(
        const ImageDiffBody(
          path: 'shot.png',
          status: PrFileStatus.modified,
          workspaceId: 'ws',
          baseRef: 'base',
          headRef: 'head',
          cached: comparison,
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('Difference'));
    await tester.pump();
    expect(find.byKey(const Key('image-diff-overlay')), findsOneWidget);
    expect(find.text('12.5% changed'), findsOneWidget);
  });

  testWidgets('SVG hides the overlay control even when overlay_ref is set', (
    tester,
  ) async {
    await tester.pumpWidget(
      testWrap(
        const ImageDiffBody(
          path: 'icon.svg',
          status: PrFileStatus.modified,
          workspaceId: 'ws',
          baseRef: 'base',
          headRef: 'head',
          cached: comparison,
          isSvg: true,
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Difference'), findsNothing);
  });

  testWidgets('checker matches GitHub viewscreen bg.gif', (tester) async {
    const key = Key('checker-tile');
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topLeft,
          child: RepaintBoundary(
            key: key,
            child: SizedBox(
              width: 10,
              height: 10,
              child: CustomPaint(
                painter: ImageDiffCheckerPainter(),
                child: SizedBox.expand(),
              ),
            ),
          ),
        ),
      ),
    );

    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(key),
    );
    final pixels = await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1);
      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      image.dispose();
      return data!.buffer.asUint8List();
    });

    Color at(int x, int y) {
      final i = (y * 10 + x) * 4;
      return Color.fromARGB(
        pixels![i + 3],
        pixels[i],
        pixels[i + 1],
        pixels[i + 2],
      );
    }

    // 5px squares, top-left gray (#e5e5e5), alternating with white.
    const gray = Color(0xFFE5E5E5);
    const white = Color(0xFFFFFFFF);
    expect(at(0, 0), gray);
    expect(at(4, 4), gray);
    expect(at(5, 0), white);
    expect(at(9, 4), white);
    expect(at(0, 5), white);
    expect(at(4, 9), white);
    expect(at(5, 5), gray);
    expect(at(9, 9), gray);
  });

  testWidgets('checker does not paint past the frame', (tester) async {
    const key = Key('checker-bounds');
    const blue = Color(0xFF0000FF);
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topLeft,
          child: RepaintBoundary(
            key: key,
            child: ColoredBox(
              color: blue,
              child: SizedBox(
                width: 40,
                height: 40,
                child: Align(
                  alignment: Alignment.topLeft,
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CustomPaint(
                      painter: ImageDiffCheckerPainter(),
                      child: SizedBox.expand(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(key),
    );
    final pixels = await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1);
      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      image.dispose();
      return data!.buffer.asUint8List();
    });

    Color at(int x, int y) {
      final i = (y * 40 + x) * 4;
      return Color.fromARGB(
        pixels![i + 3],
        pixels[i],
        pixels[i + 1],
        pixels[i + 2],
      );
    }

    // 24 is not a multiple of the 5px cell. The last cell used to spill.
    for (final p in const [(26, 4), (4, 26), (30, 30), (24, 12), (12, 24)]) {
      expect(at(p.$1, p.$2), blue, reason: 'leaked at $p');
    }
    expect(at(0, 0), isNot(blue));
  });
}
