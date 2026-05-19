import 'package:control_center/features/repos/data/mappers/repo_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mapper = RepoMapper();

  group('RepoMapper', () {
    test('creates const instance', () {
      expect(mapper, isNotNull);
    });

    test('toDomainList converts empty list', () {
      final result = mapper.toDomainList(const []);
      expect(result, isEmpty);
    });
  });
}
