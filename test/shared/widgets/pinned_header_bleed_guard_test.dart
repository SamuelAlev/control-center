import 'dart:ui' as ui;

import 'package:control_center/shared/widgets/pinned_header_bleed_guard.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// The fractional offset that reproduces the bleed. A pinned header is placed
/// in LOGICAL pixels and any fractional height above the scroll view (the
/// inbox hero's `18 * 1.4` subtitle line, say) puts its top edge mid-device-
/// pixel. The viewport's clip is [Clip.hardEdge] so it snaps to whole pixels
/// and admits that row; the header's own antialiased background covers only
/// part of it. A quarter pixel leaves a quarter of the topmost row showing the
/// content scrolling beneath — in the app, the tips of the row's glyphs.
const double _fractionalOffset = 0.25;

/// The scrolling body's colour. Saturated blue so a bleed is unmistakable:
/// neither the header (white) nor the guard (the design system's canvas, a
/// warm near-neutral) is ever blue-dominant.
const Color _bodyColor = Color(0xFF0000FF);

/// How far the blue channel must exceed the red one for a pixel to count as
/// the body bleeding through.
const int _bleedThreshold = 16;

/// Identifies the header's own box (as opposed to the guard's strip).
const Key headerBoxKey = ValueKey('header-box');

class _HeaderDelegate extends SliverPersistentHeaderDelegate {
  const _HeaderDelegate({required this.guarded});

  /// Whether the header's box is wrapped in a [PinnedHeaderBleedGuard].
  final bool guarded;

  static const double _extent = 24;

  @override
  double get minExtent => _extent;

  @override
  double get maxExtent => _extent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    const box = SizedBox(
      key: headerBoxKey,
      height: _extent,
      child: ColoredBox(color: Color(0xFFFFFFFF)),
    );
    return guarded ? const PinnedHeaderBleedGuard(child: box) : box;
  }

  @override
  bool shouldRebuild(_HeaderDelegate old) => old.guarded != guarded;
}

void main() {
  const boundaryKey = ValueKey('capture');

  Widget harness({required bool guarded}) => Directionality(
    textDirection: TextDirection.ltr,
    child: Align(
      // Top-left so the capture boundary itself lands on a whole pixel and the
      // only fractional offset in play is the one under test.
      alignment: Alignment.topLeft,
      child: RepaintBoundary(
        key: boundaryKey,
        child: SizedBox(
          width: 120,
          height: 240,
          child: Padding(
            padding: const EdgeInsets.only(top: _fractionalOffset),
            child: CustomScrollView(
              slivers: [
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _HeaderDelegate(guarded: guarded),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(
                    height: 2000,
                    child: ColoredBox(color: _bodyColor),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  /// Scrolls the body under the pinned header, then reports how far the blue
  /// channel leads the red one in the brightest offending pixel of the
  /// header's own rows.
  Future<int> bleedAcrossHeader(
    WidgetTester tester, {
    required bool guarded,
  }) async {
    await tester.pumpWidget(harness(guarded: guarded));
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -200));
    await tester.pumpAndSettle();

    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(boundaryKey),
    );
    final pixels = await tester.runAsync(() async {
      final image = await boundary.toImage();
      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      image.dispose();
      return data!.buffer.asUint8List();
    });

    // Only the header's own rows: below them the body legitimately shows.
    const width = 120;
    var worst = 0;
    for (var y = 0; y < _HeaderDelegate._extent.floor(); y++) {
      for (var x = 0; x < width; x++) {
        final i = (y * width + x) * 4;
        final lead = pixels![i + 2] - pixels[i];
        if (lead > worst) {
          worst = lead;
        }
      }
    }
    return worst;
  }

  testWidgets('an unguarded pinned header leaks the row scrolling beneath', (
    tester,
  ) async {
    // The control: without the guard the fractional top edge is exactly the
    // regression that keeps resurfacing in the inbox. If this ever stops
    // failing the test below has become vacuous.
    expect(
      await bleedAcrossHeader(tester, guarded: false),
      greaterThan(_bleedThreshold),
    );
  });

  testWidgets('the guard covers the partial pixel above a pinned header', (
    tester,
  ) async {
    expect(
      await bleedAcrossHeader(tester, guarded: true),
      lessThanOrEqualTo(_bleedThreshold),
    );
  });

  testWidgets('the guard leaves the header box its full cross-axis extent', (
    tester,
  ) async {
    // A persistent header lays its child out with a LOOSE main axis, so a
    // default (loose) stack would collapse the box onto its content instead of
    // letting it span the viewport — the card frame would simply vanish.
    await tester.pumpWidget(harness(guarded: true));
    expect(tester.getSize(find.byKey(headerBoxKey)).width, 120);
  });
}
