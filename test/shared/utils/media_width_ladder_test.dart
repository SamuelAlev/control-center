import 'package:control_center/shared/utils/media_width_ladder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('bucketMediaWidth', () {
    test('returns the exact rung when already on the ladder', () {
      expect(bucketMediaWidth(48), 48);
      expect(bucketMediaWidth(256), 256);
      expect(bucketMediaWidth(2048), 2048);
    });

    test('rounds UP to the next rung, never down', () {
      expect(bucketMediaWidth(1), 32);
      expect(bucketMediaWidth(28), 32);
      expect(bucketMediaWidth(49), 64);
      expect(bucketMediaWidth(340), 384);
      expect(bucketMediaWidth(1500), 1536);
    });

    test('caps at max, above the ladder or not', () {
      expect(bucketMediaWidth(4000), 2048);
      expect(bucketMediaWidth(3000, max: 460), 460);
      // GitHub avatars: the first rung past 384 overshoots 460 → the cap.
      expect(bucketMediaWidth(400, max: 460), 460);
      expect(bucketMediaWidth(300, max: 460), 384);
    });
  });
}
