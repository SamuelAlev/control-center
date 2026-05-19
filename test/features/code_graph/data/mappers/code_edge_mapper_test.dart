import 'package:cc_persistence/mappers/code_edge_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CodeEdgeMapper', () {
    test('creates const instance', timeout: const Timeout.factor(2), () {
      const mapper = CodeEdgeMapper();
      expect(mapper, isNotNull);
    });
  });
}
