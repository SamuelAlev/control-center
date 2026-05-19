import 'package:control_center/core/domain/ports/sandbox_port.dart';
import 'package:control_center/core/domain/value_objects/sandbox_backend.dart';
import 'package:control_center/features/sandboxing/data/services/sandbox_backend_detector.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fake [SandboxPort] that returns a canned [probe] result.
class _FakeSandboxPort implements SandboxPort {
  _FakeSandboxPort(this._backend, this._capabilities);

  final SandboxBackend _backend;
  final SandboxBackendCapabilities _capabilities;

  @override
  SandboxBackend get backend => _backend;

  @override
  Future<SandboxBackendCapabilities> probe() async => _capabilities;

  // Unused — required by the interface.
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// [SandboxPort] whose [probe] always throws.
class _ThrowingSandboxPort implements SandboxPort {
  _ThrowingSandboxPort(this._backend, [this._error = 'probe exploded']);

  final SandboxBackend _backend;
  final Object _error;

  @override
  SandboxBackend get backend => _backend;

  @override
  Future<SandboxBackendCapabilities> probe() async {
    throw _error;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  group('SandboxBackendDetector', () {
    test('recommends native when native probe succeeds', () async {
      final detector = SandboxBackendDetector([
        _FakeSandboxPort(
          SandboxBackend.native,
          const SandboxBackendCapabilities(
            backend: SandboxBackend.native,
            available: true,
          ),
        ),
      ]);

      final result = await detector.detect();

      expect(result.recommendation, SandboxBackend.native);
      expect(
        result.capabilities[SandboxBackend.native]!.available,
        isTrue,
      );
    }, timeout: const Timeout.factor(2));

    test('falls back to none when native is unavailable', () async {
      final detector = SandboxBackendDetector([
        _FakeSandboxPort(
          SandboxBackend.native,
          const SandboxBackendCapabilities(
            backend: SandboxBackend.native,
            available: false,
            note: 'Not installed',
          ),
        ),
      ]);

      final result = await detector.detect();

      expect(result.recommendation, SandboxBackend.none);
      expect(
        result.capabilities[SandboxBackend.native]!.available,
        isFalse,
      );
    }, timeout: const Timeout.factor(2));

    test('falls back to none when adapter list is empty', () async {
      final detector = SandboxBackendDetector([]);

      final result = await detector.detect();

      expect(result.recommendation, SandboxBackend.none);
      expect(result.capabilities, isEmpty);
    }, timeout: const Timeout.factor(2));

    test('records probe failure as unavailable with note', () async {
      final detector = SandboxBackendDetector([
        _ThrowingSandboxPort(SandboxBackend.native, 'something broke'),
      ]);

      final result = await detector.detect();

      expect(result.recommendation, SandboxBackend.none);
      final caps = result.capabilities[SandboxBackend.native]!;
      expect(caps.available, isFalse);
      expect(caps.note, contains('Probe failed'));
      expect(caps.note, contains('something broke'));
    }, timeout: const Timeout.factor(2));

    test('platform label is non-empty', () async {
      final detector = SandboxBackendDetector([]);
      final result = await detector.detect();

      expect(result.platform, isNotEmpty);
    }, timeout: const Timeout.factor(2));

    test('returns capabilities map keyed by backend', () async {
      final detector = SandboxBackendDetector([
        _FakeSandboxPort(
          SandboxBackend.native,
          const SandboxBackendCapabilities(
            backend: SandboxBackend.native,
            available: true,
          ),
        ),
      ]);

      final result = await detector.detect();

      expect(result.capabilities.keys, {SandboxBackend.native});
    }, timeout: const Timeout.factor(2));

    test('multiple adapters: picks first available in priority order',
        () async {
      // Even if a second adapter (not in the priority list) is available,
      // only native is considered.
      final detector = SandboxBackendDetector([
        _FakeSandboxPort(
          SandboxBackend.native,
          const SandboxBackendCapabilities(
            backend: SandboxBackend.native,
            available: true,
          ),
        ),
      ]);

      final result = await detector.detect();

      expect(result.recommendation, SandboxBackend.native);
    }, timeout: const Timeout.factor(2));

    test('platform label contains known platform name', () async {
      final detector = SandboxBackendDetector([]);
      final result = await detector.detect();

      expect(
        result.platform,
        anyOf(contains('macOS'), contains('Linux'), contains('Windows')),
      );
    }, timeout: const Timeout.factor(2));

    test('platform label includes architecture detection', () async {
      final detector = SandboxBackendDetector([]);
      final result = await detector.detect();

      // _platformLabel() produces e.g. "macOS (aarch64)" or "Linux (x86_64)".
      expect(result.platform, contains(RegExp(r'\([^)]+\)')));
    }, timeout: const Timeout.factor(2));

    test(
        'multiple adapters: native throws but another available '
        '— still picks native from priority', () async {
      final detector = SandboxBackendDetector([
        _ThrowingSandboxPort(SandboxBackend.native, 'first adapter failed'),
        _FakeSandboxPort(
          SandboxBackend.native,
          const SandboxBackendCapabilities(
            backend: SandboxBackend.native,
            available: true,
          ),
        ),
      ]);

      final result = await detector.detect();

      // First adapter threw, second succeeded — native is available.
      expect(result.recommendation, SandboxBackend.native);
      expect(
        result.capabilities[SandboxBackend.native]!.available,
        isTrue,
      );
    }, timeout: const Timeout.factor(2));

    test(
        'multiple adapters: native throws and no adapter provides '
        'availability — falls back to none', () async {
      final detector = SandboxBackendDetector([
        _ThrowingSandboxPort(SandboxBackend.native, 'first adapter failed'),
        _FakeSandboxPort(
          SandboxBackend.native,
          const SandboxBackendCapabilities(
            backend: SandboxBackend.native,
            available: false,
            note: 'Not installed',
          ),
        ),
      ]);

      final result = await detector.detect();

      expect(result.recommendation, SandboxBackend.none);
      expect(
        result.capabilities[SandboxBackend.native]!.available,
        isFalse,
      );
    }, timeout: const Timeout.factor(2));

    test('throwing adapter with non-String error captures exception text',
        () async {
      final detector = SandboxBackendDetector([
        _ThrowingSandboxPort(SandboxBackend.native, Exception('unexpected')),
      ]);

      final result = await detector.detect();

      final caps = result.capabilities[SandboxBackend.native]!;
      expect(caps.available, isFalse);
      expect(caps.note, contains('Probe failed'));
      expect(caps.note, contains('unexpected'));
    }, timeout: const Timeout.factor(2));

    test('detector with only throwing adapters still returns none', () async {
      final detector = SandboxBackendDetector([
        _ThrowingSandboxPort(SandboxBackend.native, 'boom'),
      ]);

      final result = await detector.detect();

      expect(result.recommendation, SandboxBackend.none);
      expect(result.capabilities, isNotEmpty);
    }, timeout: const Timeout.factor(2));
  });
}
