import 'package:cc_domain/core/domain/value_objects/code_edge_kind.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CodeEdgeKind', () {
    test('all values have correct labels', () {
      expect(CodeEdgeKind.calls.label, 'Calls');
      expect(CodeEdgeKind.imports.label, 'Imports');
      expect(CodeEdgeKind.extendsType.label, 'Extends');
      expect(CodeEdgeKind.implementsType.label, 'Implements');
      expect(CodeEdgeKind.mixesIn.label, 'Mixes in');
      expect(CodeEdgeKind.references.label, 'References');
    });

    test('tryParse with exact name returns correct value', () {
      expect(CodeEdgeKind.tryParse('calls'), CodeEdgeKind.calls);
      expect(CodeEdgeKind.tryParse('imports'), CodeEdgeKind.imports);
      expect(CodeEdgeKind.tryParse('extendsType'), CodeEdgeKind.extendsType);
      expect(CodeEdgeKind.tryParse('implementsType'), CodeEdgeKind.implementsType);
      expect(CodeEdgeKind.tryParse('mixesIn'), CodeEdgeKind.mixesIn);
      expect(CodeEdgeKind.tryParse('references'), CodeEdgeKind.references);
    });

    test('tryParse is case-insensitive', () {
      expect(CodeEdgeKind.tryParse('CALLS'), CodeEdgeKind.calls);
      expect(CodeEdgeKind.tryParse('Imports'), CodeEdgeKind.imports);
      expect(CodeEdgeKind.tryParse('EXTENDSTYPE'), CodeEdgeKind.extendsType);
      expect(CodeEdgeKind.tryParse('implementsType'), CodeEdgeKind.implementsType);
      expect(CodeEdgeKind.tryParse('MIXESIN'), CodeEdgeKind.mixesIn);
      expect(CodeEdgeKind.tryParse('ReFeReNcEs'), CodeEdgeKind.references);
    });

    test('tryParse returns null for null', () {
      expect(CodeEdgeKind.tryParse(null), isNull);
    });

    test('tryParse returns null for unrecognized string', () {
      expect(CodeEdgeKind.tryParse('unknown'), isNull);
      expect(CodeEdgeKind.tryParse(''), isNull);
      expect(CodeEdgeKind.tryParse('calls '), isNull);
    });

    test('all values are distinct', () {
      const values = CodeEdgeKind.values;
      expect(values.toSet().length, values.length);
    });
  });
}
