import 'package:control_center/core/domain/value_objects/memory_permission.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MemoryPermission', () {
    test('all values have correct labels', () {
      expect(MemoryPermission.none.label, 'none');
      expect(MemoryPermission.read.label, 'read');
      expect(MemoryPermission.write.label, 'write');
    });

    test('tryParse with exact label returns correct value', () {
      expect(MemoryPermission.tryParse('none'), MemoryPermission.none);
      expect(MemoryPermission.tryParse('read'), MemoryPermission.read);
      expect(MemoryPermission.tryParse('write'), MemoryPermission.write);
    });

    test('tryParse is case-insensitive', () {
      expect(MemoryPermission.tryParse('None'), MemoryPermission.none);
      expect(MemoryPermission.tryParse('READ'), MemoryPermission.read);
      expect(MemoryPermission.tryParse('WrItE'), MemoryPermission.write);
    });

    test('tryParse returns null for null', () {
      expect(MemoryPermission.tryParse(null), isNull);
    });

    test('tryParse returns null for unrecognized string', () {
      expect(MemoryPermission.tryParse(''), isNull);
      expect(MemoryPermission.tryParse('admin'), isNull);
      expect(MemoryPermission.tryParse('readwrite'), isNull);
    });

    test('all values are distinct', () {
      final values = MemoryPermission.values.toSet();
      expect(values.length, 3);
      expect(values, containsAll(<MemoryPermission>[
        MemoryPermission.none,
        MemoryPermission.read,
        MemoryPermission.write,
      ]));
    });
  });
}
