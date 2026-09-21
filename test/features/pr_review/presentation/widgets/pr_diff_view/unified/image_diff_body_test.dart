import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/image_diff_resolution.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view/unified/image_diff_body.dart';
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
}
