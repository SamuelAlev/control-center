import 'package:control_center/features/rigs/presentation/rig_panel.dart';
import 'package:flutter_test/flutter_test.dart';

// Raising the guest's device scale multiplies the frame's PIXELS — 2x is four
// times as many — so the quality asked for has to come down with it or the
// watch lane simply costs four times as much, including for a phone on the
// relay. The trade works because the viewer downsamples the frame back to its
// panel, and averaging 4 source pixels into 1 filters out exactly the block
// noise JPEG adds.
void main() {
  group('rigStreamQualityFor', () {
    test('1x is unchanged, so nothing regresses on a non-Retina display', () {
      expect(rigStreamQualityFor(1), 70);
    });

    test('2x drops quality to absorb the extra pixels', () {
      expect(rigStreamQualityFor(2), 45);
    });

    test('a fractional ratio lands between the two', () {
      final q = rigStreamQualityFor(1.5);
      expect(q, lessThan(70));
      expect(q, greaterThan(45));
    });

    test('never goes below 45, whatever the ratio claims', () {
      // The floor is the point where downsampling stops hiding the artifacts
      // and the frame just looks bad. A viewer reporting an absurd ratio must
      // not be able to drive the lane there.
      expect(rigStreamQualityFor(4), 45);
      expect(rigStreamQualityFor(100), 45);
    });

    test('a ratio below 1 cannot raise quality above the default', () {
      expect(rigStreamQualityFor(0.5), 70);
    });
  });
}
