import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode.dart';
import 'package:test/test.dart';

void main() {
  group('CodeRunnerAvailability', () {
    test('round-trips through JSON', () {
      const available = CodeRunnerAvailability.available();
      const unavailable = CodeRunnerAvailability.unavailable('seccomp failed');
      expect(CodeRunnerAvailability.fromJson(available.toJson()), available);
      expect(
        CodeRunnerAvailability.fromJson(unavailable.toJson()),
        unavailable,
      );
      expect(available.isAvailable, isTrue);
      expect(unavailable.isAvailable, isFalse);
    });

    test('anything but an explicit available reads as unavailable', () {
      expect(
        CodeRunnerAvailability.fromJson(const {'available': 'yes'}),
        const CodeRunnerUnavailable('unknown'),
      );
      expect(CodeRunnerAvailability.fromJson(const {}).isAvailable, isFalse);
    });
  });
}
