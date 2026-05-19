import 'package:cc_domain/core/domain/ports/sandbox_port.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_backend.dart';
import 'package:cc_infra/src/sandboxing/sandbox_backend_detector.dart';
import 'package:test/test.dart';

/// Exercises [SandboxBackendDetector] — the startup probe that asks each
/// backend to self-probe and recommends the best available one. Native wins
/// when available; falls back to `none`; and a throwing probe is recorded as
/// unavailable rather than crashing the detect loop.
void main() {
  group('SandboxBackendDetector.detect', () {
    test('recommends native when its probe reports available', () async {
      final det = SandboxBackendDetector([
        _FakeBackend(SandboxBackend.native, available: true),
        _FakeBackend(SandboxBackend.none, available: true),
      ]);
      final res = await det.detect();
      expect(res.recommendation, SandboxBackend.native);
      expect(res.capabilities[SandboxBackend.native]?.available, isTrue);
      expect(res.platform, isNotEmpty);
    });

    test('falls back to none when native is unavailable', () async {
      final det = SandboxBackendDetector([
        _FakeBackend(SandboxBackend.native, available: false),
      ]);
      final res = await det.detect();
      expect(res.recommendation, SandboxBackend.none);
    });

    test(
      'records a throwing probe as unavailable with the error note',
      () async {
        final det = SandboxBackendDetector([
          _ThrowingBackend(SandboxBackend.native),
        ]);
        final res = await det.detect();
        expect(res.recommendation, SandboxBackend.none);
        final cap = res.capabilities[SandboxBackend.native]!;
        expect(cap.available, isFalse);
        expect(cap.note, contains('Probe failed'));
      },
    );

    test('recommends none when no adapters are registered', () async {
      final res = await SandboxBackendDetector(const []).detect();
      expect(res.recommendation, SandboxBackend.none);
      expect(res.capabilities, isEmpty);
    });
  });
}

class _FakeBackend implements SandboxPort {
  _FakeBackend(this._backend, {required this.available});
  final SandboxBackend _backend;
  final bool available;

  @override
  SandboxBackend get backend => _backend;

  @override
  Future<SandboxBackendCapabilities> probe() async =>
      SandboxBackendCapabilities(backend: _backend, available: available);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ThrowingBackend implements SandboxPort {
  _ThrowingBackend(this._backend);
  final SandboxBackend _backend;

  @override
  SandboxBackend get backend => _backend;

  @override
  Future<SandboxBackendCapabilities> probe() async =>
      throw StateError('probe exploded');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
