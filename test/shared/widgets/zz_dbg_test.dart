import 'dart:ui' as ui;
import 'package:control_center/shared/widgets/pinned_header_bleed_guard.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class _D extends SliverPersistentHeaderDelegate {
  const _D({required this.guarded});
  final bool guarded;
  @override double get minExtent => 24;
  @override double get maxExtent => 24;
  @override
  Widget build(BuildContext c, double s, bool o) {
    const box = SizedBox(height: 24, child: ColoredBox(color: Color(0xFFFFFFFF)));
    return guarded ? const PinnedHeaderBleedGuard(child: box) : box;
  }
  @override bool shouldRebuild(_D old) => old.guarded != guarded;
}

void main() {
  const bk = ValueKey('capture');
  Widget harness({required bool guarded}) => Directionality(
    textDirection: TextDirection.ltr,
    child: Align(alignment: Alignment.topLeft,
      child: RepaintBoundary(key: bk, child: SizedBox(width: 120, height: 240,
        child: Padding(padding: const EdgeInsets.only(top: 0.25),
          child: CustomScrollView(slivers: [
            SliverPersistentHeader(pinned: true, delegate: _D(guarded: guarded)),
            const SliverToBoxAdapter(child: SizedBox(height: 2000, child: ColoredBox(color: Color(0xFF0000FF)))),
          ]))))));

  for (final g in [false, true]) {
    testWidgets('dump guarded=$g', (tester) async {
      await tester.pumpWidget(harness(guarded: g));
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -200));
      await tester.pumpAndSettle();
      final b = tester.renderObject<RenderRepaintBoundary>(find.byKey(bk));
      final px = await tester.runAsync(() async {
        final img = await b.toImage();
        final d = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
        img.dispose();
        return d!.buffer.asUint8List();
      });
      for (var y = 0; y < 30; y++) {
        final i = (y * 120 + 60) * 4;
        // ignore: avoid_print
        print('guarded=$g y=$y rgba=${px![i]},${px[i+1]},${px[i+2]},${px[i+3]}');
      }
    });
  }
}
