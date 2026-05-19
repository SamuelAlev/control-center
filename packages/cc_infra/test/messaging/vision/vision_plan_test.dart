import 'package:cc_infra/src/messaging/vision/vision_plan.dart';
import 'package:cc_infra/src/messaging/vision/vision_shapes.dart';
import 'package:test/test.dart';

/// A small shape with a tiny frame so capacities are easy to reason about:
/// cols = 16/8 = 2, rows = 16/8 = 2, capHi = 4, capLo = 16.
const VisionShape _tinyShape = VisionShape(
  code: 'test',
  fontWidth: 8,
  fontHeight: 8,
  cellWidth: 8,
  cellHeight: 8,
  stopwordDim: false,
  columns: 1,
  frameSize: 16,
  frameTokenEstimate: 1,
  imageDetail: '',
);

void main() {
  group('planArchive', () {
    test('empty source yields no slices', () {
      final plan = planArchive(
        sourceText: '',
        shape: _tinyShape,
        maxFrames: 8,
      );
      expect(plan.slices, isEmpty);
      expect(plan.truncatedRegions, 0);
    });

    test('short input renders a single all-HQ tier', () {
      // capHi = 4; 6 chars across maxFrames=8 fits the HQ budget (8*4=32).
      final plan = planArchive(
        sourceText: 'abcdef',
        shape: _tinyShape,
        maxFrames: 8,
      );
      expect(plan.truncatedRegions, 0);
      expect(plan.slices.every((s) => s.highQuality), isTrue);
      // ceil(6 / 4) = 2 frames.
      expect(plan.slices.length, 2);
      expect(plan.slices[0].text, 'abcd');
      expect(plan.slices[1].text, 'ef');
      // Concatenation preserves the source.
      expect(plan.slices.map((s) => s.text).join(), 'abcdef');
    });

    test('foveates with HQ edges and an LQ middle when overflowing', () {
      // capHi=4, capLo=16. maxFrames=5 → edgeFrames=min(3,(5-1)~/2)=2.
      // edgeCap = 2*4 = 8. Need length > 5*4=20 to overflow the HQ tier.
      // Build 40 chars: head 8 HQ, tail 8 HQ, middle 24 (fits 1 LQ frame... no:
      // middleCap = (5 - 2*2)*16 = 16, so 24 > 16 → drop oldest 8.
      final source = List<String>.generate(40, (i) => '${i % 10}').join();
      final plan = planArchive(
        sourceText: source,
        shape: _tinyShape,
        maxFrames: 5,
      );

      // Head is the first 8 chars at HQ (2 frames of 4).
      final hqHead = plan.slices.where((s) => s.highQuality).toList();
      final lqMiddle = plan.slices.where((s) => !s.highQuality).toList();
      expect(hqHead.isNotEmpty, isTrue);
      expect(lqMiddle.isNotEmpty, isTrue);

      // Ordering is HQ head, then LQ middle, then HQ tail.
      final firstLq = plan.slices.indexWhere((s) => !s.highQuality);
      final lastLq = plan.slices.lastIndexWhere((s) => !s.highQuality);
      expect(plan.slices.sublist(0, firstLq).every((s) => s.highQuality),
          isTrue);
      expect(plan.slices.sublist(lastLq + 1).every((s) => s.highQuality),
          isTrue);

      // Head preserves the oldest chars; tail preserves the newest.
      expect(plan.slices.first.text, source.substring(0, 4));
      expect(plan.slices.last.text, source.substring(36));

      // The middle overflowed its 16-char budget, so a region was dropped.
      expect(plan.truncatedRegions, 1);
    });

    test('drops the OLDEST middle chars, keeping the newest', () {
      // Same geometry: head=first 8, tail=last 8, middle=chars[8..32) length 24.
      // middleCap=16 → keep newest 16 of the middle (chars[16..32)).
      final source = List<String>.generate(40, (i) => String.fromCharCode(
            'A'.codeUnitAt(0) + i,
          )).join();
      final plan = planArchive(
        sourceText: source,
        shape: _tinyShape,
        maxFrames: 5,
      );
      final middleText =
          plan.slices.where((s) => !s.highQuality).map((s) => s.text).join();
      // Kept middle = source[16..32) (newest 16 of the 24-char middle).
      expect(middleText, source.substring(16, 32));
    });

    test('edgeFrames is clamped to hqEdgeFrames', () {
      // maxFrames=20 → (20-1)~/2 = 9, clamped to hqEdgeFrames (3).
      // edgeCap = 3*4 = 12. Need length > 20*4 = 80 to overflow.
      final source = 'x' * 200;
      final plan = planArchive(
        sourceText: source,
        shape: _tinyShape,
        maxFrames: 20,
      );
      // 3 HQ frames at each edge = 6 HQ frames total.
      final hqCount = plan.slices.where((s) => s.highQuality).length;
      expect(hqCount, hqEdgeFrames * 2);
    });

    test('uses HQ tier when the middle fits without dropping', () {
      // maxFrames=5, edgeFrames=2, edgeCap=8, middleCap=16.
      // length=30: middle = chars[8..22) length 14 <= 16 → no drop.
      final source = 'y' * 30;
      final plan = planArchive(
        sourceText: source,
        shape: _tinyShape,
        maxFrames: 5,
      );
      expect(plan.truncatedRegions, 0);
      // Full source is preserved across all slices.
      final joined = plan.slices.map((s) => s.text).join();
      expect(joined, source);
    });

    test('all-HQ slices reconstruct the source exactly with a real shape', () {
      final shape = resolveShape('claude-3-5-sonnet');
      final source = 'hello world ' * 10;
      final plan = planArchive(
        sourceText: source,
        shape: shape,
        maxFrames: 8,
      );
      expect(plan.truncatedRegions, 0);
      expect(plan.slices.map((s) => s.text).join(), source);
      expect(plan.slices.every((s) => s.highQuality), isTrue);
    });
  });

  group('VisionFrameSlice equality', () {
    test('equal slices compare equal', () {
      expect(
        const VisionFrameSlice(text: 'a', highQuality: true),
        const VisionFrameSlice(text: 'a', highQuality: true),
      );
    });
  });
}
