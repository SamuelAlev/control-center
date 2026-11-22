import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode_limits.dart';
import 'package:cc_domain/src/errors/app_exceptions.dart';
import 'package:test/test.dart';

void main() {
  group('CodeModeLimits defaults and ceilings', () {
    test('match the plan table', () {
      final d = CodeModeLimits.defaults;
      expect(d.wallClockMs, 300000);
      expect(d.cpuMs, 30000);
      expect(d.heapBytes, 256 * 1024 * 1024);
      expect(d.maxNestedCalls, 500);
      expect(d.maxInFlightCalls, 8);
      expect(d.maxOutputTokens, 10000);
      expect(CodeModeLimits.wallClock.ceiling, 1500000);
      expect(CodeModeLimits.cpu.ceiling, 120000);
      expect(CodeModeLimits.heap.ceiling, 1024 * 1024 * 1024);
      expect(CodeModeLimits.nestedCalls.ceiling, 5000);
      expect(CodeModeLimits.inFlightCalls.ceiling, 32);
      expect(CodeModeLimits.outputTokens.ceiling, 50000);
      expect(CodeModeLimits.stackBytes, 512 * 1024);
      expect(CodeModeLimits.interpreterOutputBytes, 16 * 1024 * 1024);
      expect(CodeModeLimits.interpreterOutputItems, 100000);
      expect(CodeModeLimits.maxSourceBytes, 256 * 1024);
      expect(CodeModeLimits.maxStoreValueBytes, 256 * 1024);
      expect(CodeModeLimits.maxStoreTotalBytes, 1024 * 1024);
      expect(CodeModeLimits.maxQuestions, 10);
    });

    test('the constructor refuses out-of-range values', () {
      expect(() => CodeModeLimits(wallClockMs: 1500001), throwsArgumentError);
      expect(() => CodeModeLimits(maxInFlightCalls: 0), throwsArgumentError);
      expect(() => CodeModeLimits(maxOutputTokens: 99), throwsArgumentError);
    });

    test('server process cap is min(16, 2 x cores), at least one', () {
      expect(CodeModeLimits.defaultServerProcessCap(4), 8);
      expect(CodeModeLimits.defaultServerProcessCap(12), 16);
      expect(CodeModeLimits.defaultServerProcessCap(0), 1);
    });
  });

  group('withOverrides', () {
    test('a workspace may lower and raise up to the ceiling', () {
      final l = CodeModeLimits.defaults.withOverrides(
        wallClockMs: 1500000,
        maxNestedCalls: 10,
      );
      expect(l.wallClockMs, 1500000);
      expect(l.maxNestedCalls, 10);
      expect(l.cpuMs, CodeModeLimits.defaults.cpuMs);
    });

    test('past the ceiling or under the floor is a validation error', () {
      expect(
        () => CodeModeLimits.defaults.withOverrides(cpuMs: 120001),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => CodeModeLimits.defaults.withOverrides(heapBytes: 1),
        throwsA(isA<ValidationException>()),
      );
    });

    test('the JSON form round-trips and refuses unknown keys', () {
      final l = CodeModeLimits.defaults.withOverridesJson({
        'wall_clock_ms': 600000,
        'max_output_tokens': 20000.0,
      });
      expect(l.wallClockMs, 600000);
      expect(l.maxOutputTokens, 20000);
      expect(l.overridesToJson(), {
        'wall_clock_ms': 600000,
        'max_output_tokens': 20000,
      });
      expect(CodeModeLimits.defaults.withOverridesJson(l.overridesToJson()), l);
      expect(
        () => CodeModeLimits.defaults.withOverridesJson({'timeout': 5}),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => CodeModeLimits.defaults.withOverridesJson({'cpu_ms': 'x'}),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('clamp', () {
    test('the model may ask for less', () {
      final l = CodeModeLimits.defaults.clamp(
        timeoutMs: 5000,
        maxOutputTokens: 2000,
      );
      expect(l.wallClockMs, 5000);
      expect(l.maxOutputTokens, 2000);
    });

    test('never more than the workspace value', () {
      final l = CodeModeLimits.defaults.clamp(
        timeoutMs: 9999999,
        maxOutputTokens: 50000,
      );
      expect(l.wallClockMs, 300000);
      expect(l.maxOutputTokens, 10000);
      final raised = CodeModeLimits.defaults
          .withOverrides(wallClockMs: 1500000, maxOutputTokens: 50000)
          .clamp(timeoutMs: 1000000, maxOutputTokens: 40000);
      expect(raised.wallClockMs, 1000000);
      expect(raised.maxOutputTokens, 40000);
    });

    test('below the floor is raised; missing or non-positive is ignored', () {
      final l = CodeModeLimits.defaults.clamp(
        timeoutMs: 10,
        maxOutputTokens: 1,
      );
      expect(l.wallClockMs, CodeModeLimits.minTimeoutMs);
      expect(l.maxOutputTokens, CodeModeLimits.outputTokens.floor);
      expect(CodeModeLimits.defaults.clamp(), CodeModeLimits.defaults);
      expect(
        CodeModeLimits.defaults.clamp(timeoutMs: 0, maxOutputTokens: -5),
        CodeModeLimits.defaults,
      );
    });
  });

  test('toJson carries every limit and fromJson restores the adjustable', () {
    final l = CodeModeLimits(cpuMs: 60000);
    final json = l.toJson();
    expect(json['cpu_ms'], 60000);
    expect(json['stack_bytes'], CodeModeLimits.stackBytes);
    expect(json['max_questions'], 10);
    expect(json['max_store_total_bytes'], 1024 * 1024);
    expect(CodeModeLimits.fromJson(json), l);
    expect(CodeModeLimits.fromJson(json).hashCode, l.hashCode);
  });
}
