import 'package:cc_persistence/mappers/code_symbol_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CodeSymbolMapper', () {
    test('creates const instance', timeout: const Timeout.factor(2), () {
      const mapper = CodeSymbolMapper();
      expect(mapper, isNotNull);
    });
  });
}
