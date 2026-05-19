import 'package:cc_domain/core/domain/value_objects/sandbox_backend.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SandboxBackend', () {
    test('has exactly 3 values: microvm, native and none', () {
      // The set is deliberately small and every addition is a deliberate act:
      // this enum is what the chat badge and the terminal badge report, so a
      // value that appears without a reviewed label is a claim about isolation
      // nobody checked.
      expect(SandboxBackend.values, hasLength(3));
      expect(
        SandboxBackend.values,
        containsAll([
          SandboxBackend.microvm,
          SandboxBackend.native,
          SandboxBackend.none,
        ]),
      );
    });

    test('only the microvm backend claims a kernel boundary', () {
      expect(SandboxBackend.microvm.isEnclosed, isTrue);
      expect(
        SandboxBackend.native.isEnclosed,
        isFalse,
        reason:
            'The native sandbox is namespace isolation. Claiming otherwise is '
            'exactly the overstatement this enum exists to prevent.',
      );
      expect(SandboxBackend.none.isEnclosed, isFalse);
    });

    test('label for microvm is "Enclosed VM"', () {
      expect(SandboxBackend.microvm.label, 'Enclosed VM');
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

    test('fromName("microvm") returns microvm', () {
      expect(SandboxBackend.fromName('microvm'), SandboxBackend.microvm);
    });

    test('fromName("unknown") returns none', () {
      // Unknown degrades to the WEAKEST option, never the strongest: a typo
      // must not be read as a request for a VM that then silently is not one.
      expect(SandboxBackend.fromName('unknown'), SandboxBackend.none);
    });
  });
}
