import 'package:control_center/core/domain/value_objects/sandbox_backend.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SandboxBackend', () {
    test('has exactly 2 values: native and none', () {
      expect(SandboxBackend.values, hasLength(2));
      expect(SandboxBackend.values, containsAll([SandboxBackend.native, SandboxBackend.none]));
    });

    test('label for native is "Native sandbox"', () {
      expect(SandboxBackend.native.label, 'Native sandbox');
    });

    test('label for none is "No isolation"', () {
      expect(SandboxBackend.none.label, 'No isolation');
    });

    test('fromName("native") returns native', () {
      expect(SandboxBackend.fromName('native'), SandboxBackend.native);
    });

    test('fromName("none") returns none', () {
      expect(SandboxBackend.fromName('none'), SandboxBackend.none);
    });

    test('fromName(null) returns none', () {
      expect(SandboxBackend.fromName(null), SandboxBackend.none);
    });

    test('fromName("docker") returns native (legacy migration)', () {
      expect(SandboxBackend.fromName('docker'), SandboxBackend.native);
    });

    test('fromName("unknown") returns none', () {
      expect(SandboxBackend.fromName('unknown'), SandboxBackend.none);
    });
  });
}
