import 'package:control_center/core/domain/value_objects/code_symbol_kind.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CodeSymbolKind', () {
    test('all values have correct labels', () {
      expect(CodeSymbolKind.function.label, 'Function');
      expect(CodeSymbolKind.method.label, 'Method');
      expect(CodeSymbolKind.classKind.label, 'Class');
      expect(CodeSymbolKind.field.label, 'Field');
      expect(CodeSymbolKind.enumKind.label, 'Enum');
      expect(CodeSymbolKind.constructor.label, 'Constructor');
      expect(CodeSymbolKind.getter.label, 'Getter');
      expect(CodeSymbolKind.setter.label, 'Setter');
      expect(CodeSymbolKind.typedefKind.label, 'Typedef');
      expect(CodeSymbolKind.extension.label, 'Extension');
      expect(CodeSymbolKind.mixin.label, 'Mixin');
      expect(CodeSymbolKind.variable.label, 'Variable');
    });

    test('tryParse with exact name returns correct value', () {
      expect(CodeSymbolKind.tryParse('function'), CodeSymbolKind.function);
      expect(CodeSymbolKind.tryParse('method'), CodeSymbolKind.method);
      expect(CodeSymbolKind.tryParse('classKind'), CodeSymbolKind.classKind);
      expect(CodeSymbolKind.tryParse('field'), CodeSymbolKind.field);
      expect(CodeSymbolKind.tryParse('enumKind'), CodeSymbolKind.enumKind);
      expect(CodeSymbolKind.tryParse('constructor'), CodeSymbolKind.constructor);
      expect(CodeSymbolKind.tryParse('getter'), CodeSymbolKind.getter);
      expect(CodeSymbolKind.tryParse('setter'), CodeSymbolKind.setter);
      expect(CodeSymbolKind.tryParse('typedefKind'), CodeSymbolKind.typedefKind);
      expect(CodeSymbolKind.tryParse('extension'), CodeSymbolKind.extension);
      expect(CodeSymbolKind.tryParse('mixin'), CodeSymbolKind.mixin);
      expect(CodeSymbolKind.tryParse('variable'), CodeSymbolKind.variable);
    });

    test('tryParse is case-insensitive', () {
      expect(CodeSymbolKind.tryParse('FUNCTION'), CodeSymbolKind.function);
      expect(CodeSymbolKind.tryParse('Method'), CodeSymbolKind.method);
      expect(CodeSymbolKind.tryParse('CLASSKIND'), CodeSymbolKind.classKind);
      expect(CodeSymbolKind.tryParse('ENUMKIND'), CodeSymbolKind.enumKind);
      expect(CodeSymbolKind.tryParse('TypeDefKind'), CodeSymbolKind.typedefKind);
    });

    test('tryParse returns null for null', () {
      expect(CodeSymbolKind.tryParse(null), isNull);
    });

    test('tryParse returns null for unrecognized string', () {
      expect(CodeSymbolKind.tryParse('unknown'), isNull);
      expect(CodeSymbolKind.tryParse(''), isNull);
      expect(CodeSymbolKind.tryParse('not_a_kind'), isNull);
    });

    test('all values are distinct', () {
      expect(CodeSymbolKind.values.toSet().length, equals(CodeSymbolKind.values.length));
    });
  });
}
