import 'package:cc_domain/features/messaging/domain/services/stack_branch_names.dart';
import 'package:test/test.dart';

void main() {
  group('normalizeStackSlug', () {
    test('folds a short name into one path segment', () {
      expect(normalizeStackSlug(' UI '), 'ui');
      expect(normalizeStackSlug('api_migration'), 'api-migration');
      expect(normalizeStackSlug('Two  words'), 'two-words');
    });

    test('rejects a name that is not a single ref segment', () {
      expect(normalizeStackSlug(''), isNull);
      expect(normalizeStackSlug('../main'), isNull);
      expect(normalizeStackSlug('a..b'), isNull);
      expect(normalizeStackSlug('ends.'), isNull);
      expect(normalizeStackSlug('-leading'), 'leading');
    });
  });

  group('pullRequestHeadBranches', () {
    test('includes every stack layer, checked-out branch first', () {
      expect(
        pullRequestHeadBranches(
          checkedOut: 'space/abcd1234/ui',
          stackBranches: const [
            'space/abcd1234',
            'space/abcd1234/ui',
            'space/abcd1234/polish',
          ],
        ),
        [
          'space/abcd1234/ui',
          'space/abcd1234',
          'space/abcd1234/polish',
        ],
      );
    });

    test('groups a part under the bottom branch without a nested ref', () {
      expect(stackLayerBranch('space/abcd1234', 'ui'), 'space/abcd1234--ui');
      expect(
        stackLayerLabel('space/abcd1234--ui', bottom: 'space/abcd1234'),
        'ui',
      );
      expect(stackLayerLabel('space/abcd1234'), 'abcd1234');
    });

    test('a checkout with no stack is just that branch', () {
      expect(
        pullRequestHeadBranches(
          checkedOut: 'space/abcd1234',
          stackBranches: const [],
        ),
        ['space/abcd1234'],
      );
    });
  });
}
