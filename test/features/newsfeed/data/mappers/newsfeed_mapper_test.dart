import 'package:control_center/features/newsfeed/data/mappers/newsfeed_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NewsfeedMapper', () {
    test('creates const instance', timeout: const Timeout.factor(2), () {
      const mapper = NewsfeedMapper();
      expect(mapper, isNotNull);
    });

    test('feedsToDomain converts empty list', timeout: const Timeout.factor(2), () {
      const mapper = NewsfeedMapper();
      final result = mapper.feedsToDomain([]);
      expect(result, isEmpty);
    });

    test('articlesToDomain converts empty list', timeout: const Timeout.factor(2), () {
      const mapper = NewsfeedMapper();
      final result = mapper.articlesToDomain([]);
      expect(result, isEmpty);
    });
  });
}
