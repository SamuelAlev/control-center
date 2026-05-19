import 'package:cc_domain/core/domain/entities/review_space_association.dart';
import 'package:test/test.dart';

void main() {
  group('reviewSpaceName', () {
    test('names the space Review: PR #<id> - <title>', () {
      expect(
        reviewSpaceName(42, 'Fix the thing'),
        'Review: PR #42 - Fix the thing',
      );
    });

    test('drops the title clause when the title is blank', () {
      expect(reviewSpaceName(42, ''), 'Review: PR #42');
      expect(reviewSpaceName(42, '   '), 'Review: PR #42');
    });

    test('trims the title', () {
      expect(reviewSpaceName(7, '  spaced  '), 'Review: PR #7 - spaced');
    });

    test('truncates to the cap', () {
      final name = reviewSpaceName(1, 'x' * 200);
      expect(name.length, kReviewSpaceNameMaxLength);
      expect(name, startsWith('Review: PR #1 - '));
    });
  });
}
