import 'package:cc_domain/core/domain/ports/sandbox_port.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_backend.dart';
import 'package:cc_domain/features/sandboxing/domain/ports/sandbox_detector_port.dart';
import 'package:cc_domain/features/sandboxing/domain/sandbox_detection_result.dart';
import 'package:cc_infra/src/detection/doctor_service.dart';
import 'package:test/test.dart';

/// Exercises [DoctorService] — the startup diagnostic runner. The sandbox
/// detector is injected so the sandbox-backend check is deterministic; the
/// remaining checks (db, CLI tools, disk, network) run against the host and
/// are asserted structurally (each produces a named, non-throwing result).
void main() {
  group('DoctorService.runDiagnostics — report structure', () {
    test('always returns exactly five named checks', () async {
      final svc = DoctorService(
        sandboxDetector: _FakeDetector(available: true),
      );
      final report = await svc.runDiagnostics();
      expect(report.results, hasLength(5));
      expect(report.results.map((r) => r.name), [
        'Sandbox backend',
        'Database',
        'CLI Tools',
        'Disk space',
        'Network',
      ]);
    });

    test('no check throws — every result has a status', () async {
      final svc = DoctorService(
        sandboxDetector: _FakeDetector(available: false),
      );
      final report = await svc.runDiagnostics();
      for (final r in report.results) {
        expect(r.status, isNotNull);
        expect(r.name, isNotEmpty);
      }
    });
  });

  group('DoctorService.runDiagnostics — sandbox backend check', () {
    test('ok when a non-none backend is available', () async {
      final svc = DoctorService(
        sandboxDetector: _FakeDetector(available: true),
      );
      final report = await svc.runDiagnostics();
      final sb = report.results.firstWhere((r) => r.name == 'Sandbox backend');
      expect(sb.isOk, isTrue);
      expect(sb.message, contains('native'));
    });

    test('warning when only the none backend is available', () async {
      final svc = DoctorService(
        sandboxDetector: _FakeDetector(available: false),
      );
      final report = await svc.runDiagnostics();
      final sb = report.results.firstWhere((r) => r.name == 'Sandbox backend');
      expect(sb.isWarning, isTrue);
      expect(sb.message, contains('unsandboxed'));
    });

    test('error when the detector itself throws', () async {
      final svc = DoctorService(sandboxDetector: _ThrowingDetector());
      final report = await svc.runDiagnostics();
      final sb = report.results.firstWhere((r) => r.name == 'Sandbox backend');
      expect(sb.isError, isTrue);
      expect(sb.message, contains('Detection failed'));
    });
  });

  group('DoctorService.runDiagnostics — other checks', () {
    test('CLI tools reflects whether git/pi resolve', () async {
      final svc = DoctorService(
        sandboxDetector: _FakeDetector(available: true),
      );
      final report = await svc.runDiagnostics();
      final cli = report.results.firstWhere((r) => r.name == 'CLI Tools');
      // git is present on the test host; pi may not be. Either ok or warning.
      expect(cli.isOk || cli.isWarning, isTrue);
    });

    test('disk + network never report a blocking error', () async {
      final svc = DoctorService(
        sandboxDetector: _FakeDetector(available: true),
      );
      final report = await svc.runDiagnostics();
      final disk = report.results.firstWhere((r) => r.name == 'Disk space');
      final net = report.results.firstWhere((r) => r.name == 'Network');
      expect(disk.isError, isFalse);
      expect(net.isError, isFalse);
    });
  });
}

class _FakeDetector implements SandboxDetectorPort {
  _FakeDetector({required this.available});
  final bool available;

  @override
  Future<SandboxDetectionResult> detect() async => SandboxDetectionResult(
    platform: 'test',
    recommendation: available ? SandboxBackend.native : SandboxBackend.none,
    capabilities: {
      if (available)
        SandboxBackend.native: const SandboxBackendCapabilities(
          backend: SandboxBackend.native,
          available: true,
        ),
      SandboxBackend.none: const SandboxBackendCapabilities(
        backend: SandboxBackend.none,
        available: true,
      ),
    },
  );
}

class _ThrowingDetector implements SandboxDetectorPort {
  @override
  Future<SandboxDetectionResult> detect() async =>
      throw StateError('detector down');
}
