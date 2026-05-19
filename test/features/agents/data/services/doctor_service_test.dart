import 'package:cc_domain/core/domain/ports/sandbox_port.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_backend.dart';
import 'package:cc_domain/features/agents/domain/entities/diagnostic_result.dart';
import 'package:cc_domain/features/sandboxing/domain/ports/sandbox_detector_port.dart';
import 'package:cc_domain/features/sandboxing/domain/sandbox_detection_result.dart';
import 'package:cc_infra/src/detection/doctor_service.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class FakeSandboxDetectorPort implements SandboxDetectorPort {
  FakeSandboxDetectorPort(this._result);

  SandboxDetectionResult _result;

  void setResult(SandboxDetectionResult r) => _result = r;

  @override
  Future<SandboxDetectionResult> detect() async => _result;
}

/// A fake that always throws during [detect], simulating catastrophic failure.
class ThrowingSandboxDetectorPort implements SandboxDetectorPort {

  ThrowingSandboxDetectorPort(this.error);
  final Object error;

  @override
  Future<SandboxDetectionResult> detect() async => throw error;
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Returns a fake [SandboxDetectionResult] with all backends available.
SandboxDetectionResult _detectionResultWith({
  required SandboxBackend recommendation,
  bool nativeAvailable = true,
}) {
  final capabilities = <SandboxBackend, SandboxBackendCapabilities>{
    SandboxBackend.native: SandboxBackendCapabilities(
      backend: SandboxBackend.native,
      available: nativeAvailable,
    ),
    SandboxBackend.none: const SandboxBackendCapabilities(
      backend: SandboxBackend.none,
      available: true,
    ),
  };
  return SandboxDetectionResult(
    platform: 'test',
    recommendation: recommendation,
    capabilities: capabilities,
  );
}

// ---------------------------------------------------------------------------
void main() {
  group('runDiagnostics', () {
    group('sandbox backend check', () {
      test('returns ok when native backend is available', () async {
        final fake = FakeSandboxDetectorPort(_detectionResultWith(
          recommendation: SandboxBackend.native,
        ));
        final service = DoctorService(sandboxDetector: fake);

        final report = await service.runDiagnostics();

        final sandboxResult = report.results.firstWhere(
          (r) => r.name == 'Sandbox backend',
        );
        expect(sandboxResult.status, DiagnosticStatus.ok);
        expect(sandboxResult.isOk, isTrue);
        expect(sandboxResult.message, contains('native'));
      });

      test('returns warning when no backend is available', () async {
        final fake = FakeSandboxDetectorPort(_detectionResultWith(
          recommendation: SandboxBackend.none,
          nativeAvailable: false,
        ));
        final service = DoctorService(sandboxDetector: fake);

        final report = await service.runDiagnostics();

        final sandboxResult = report.results.firstWhere(
          (r) => r.name == 'Sandbox backend',
        );
        expect(sandboxResult.status, DiagnosticStatus.warning);
        expect(sandboxResult.isWarning, isTrue);
        expect(sandboxResult.message,
            'No sandbox backend available. Agents run unsandboxed.');
      });

      test('returns error when detection throws', () async {
        final fake = ThrowingSandboxDetectorPort(Exception('Sandbox probe failed'));
        final service = DoctorService(sandboxDetector: fake);

        final report = await service.runDiagnostics();

        final sandboxResult = report.results.firstWhere(
          (r) => r.name == 'Sandbox backend',
        );
        expect(sandboxResult.status, DiagnosticStatus.error);
        expect(sandboxResult.isError, isTrue);
        expect(sandboxResult.message, contains('Sandbox probe failed'));
      });
    });

    group('report aggregation', () {
      test('produces exactly five diagnostic results', () async {
        final fake = FakeSandboxDetectorPort(_detectionResultWith(
          recommendation: SandboxBackend.native,
        ));
        final service = DoctorService(sandboxDetector: fake);

        final report = await service.runDiagnostics();

        expect(report.results, hasLength(5));
      });

      test('every result has a non-empty name', () async {
        final fake = FakeSandboxDetectorPort(_detectionResultWith(
          recommendation: SandboxBackend.native,
        ));
        final service = DoctorService(sandboxDetector: fake);

        final report = await service.runDiagnostics();

        for (final result in report.results) {
          expect(result.name, isNotEmpty);
        }
      });

      test('all result names are distinct', () async {
        final fake = FakeSandboxDetectorPort(_detectionResultWith(
          recommendation: SandboxBackend.native,
        ));
        final service = DoctorService(sandboxDetector: fake);

        final report = await service.runDiagnostics();

        final names = report.results.map((r) => r.name).toSet();
        expect(names.length, report.results.length);
      });
    });

    group('error handling', () {
      test('detection failure does not prevent other checks from running',
          () async {
        final fake = ThrowingSandboxDetectorPort(Exception('Boom'));
        final service = DoctorService(sandboxDetector: fake);

        final report = await service.runDiagnostics();

        // The sandbox check should be the only one with that name.
        expect(report.results.where((r) => r.name == 'Sandbox backend'),
            hasLength(1));
        // The report still has 5 results — other checks ran.
        expect(report.results, hasLength(5));
        // At least one result is an error (the sandbox one).
        expect(report.hasErrors, isTrue);
      });
    });
  });

  group('DoctorReport', () {
    test('allOk returns true when all results are ok', () {
      final results = [
        const DiagnosticResult(
          name: 'check a',
          status: DiagnosticStatus.ok,
        ),
        const DiagnosticResult(
          name: 'check b',
          status: DiagnosticStatus.ok,
        ),
        const DiagnosticResult(
          name: 'check c',
          status: DiagnosticStatus.ok,
        ),
      ];
      final report = DoctorReport(results: results);
      expect(report.allOk, isTrue);
      expect(report.hasErrors, isFalse);
      expect(report.hasWarnings, isFalse);
      expect(report.errorCount, 0);
      expect(report.warningCount, 0);
    });

    test('hasErrors and hasWarnings with mixed results', () {
      final results = [
        const DiagnosticResult(
          name: 'check a',
          status: DiagnosticStatus.ok,
        ),
        const DiagnosticResult(
          name: 'check b',
          status: DiagnosticStatus.warning,
        ),
        const DiagnosticResult(
          name: 'check c',
          status: DiagnosticStatus.error,
        ),
      ];
      final report = DoctorReport(results: results);
      expect(report.allOk, isFalse);
      expect(report.hasErrors, isTrue);
      expect(report.hasWarnings, isTrue);
      expect(report.errorCount, 1);
      expect(report.warningCount, 1);
    });

    test('empty report has no errors or warnings', () {
      const report = DoctorReport(results: []);
      expect(report.allOk, isTrue);
      expect(report.hasErrors, isFalse);
      expect(report.hasWarnings, isFalse);
    });
  });

  group('DiagnosticResult', () {
    test('isOk, isWarning, isError reflect status', () {
      const okResult = DiagnosticResult(
        name: 'test',
        status: DiagnosticStatus.ok,
      );
      expect(okResult.isOk, isTrue);
      expect(okResult.isWarning, isFalse);
      expect(okResult.isError, isFalse);

      const warningResult = DiagnosticResult(
        name: 'test',
        status: DiagnosticStatus.warning,
      );
      expect(warningResult.isOk, isFalse);
      expect(warningResult.isWarning, isTrue);
      expect(warningResult.isError, isFalse);

      const errorResult = DiagnosticResult(
        name: 'test',
        status: DiagnosticStatus.error,
      );
      expect(errorResult.isOk, isFalse);
      expect(errorResult.isWarning, isFalse);
      expect(errorResult.isError, isTrue);
    });

    test('equality and hashCode', () {
      const a = DiagnosticResult(
        name: 'check',
        status: DiagnosticStatus.ok,
        message: 'detail',
        canAutoRepair: true,
      );
      const b = DiagnosticResult(
        name: 'check',
        status: DiagnosticStatus.ok,
        message: 'detail',
        canAutoRepair: true,
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));

      const different = DiagnosticResult(
        name: 'check',
        status: DiagnosticStatus.warning,
        message: 'detail',
        canAutoRepair: true,
      );
      expect(a, isNot(equals(different)));
    });

    test('canAutoRepair defaults to false', () {
      const result = DiagnosticResult(
        name: 'test',
        status: DiagnosticStatus.ok,
      );
      expect(result.canAutoRepair, isFalse);
    });
  });

  group('sandbox backend - multiple backends', () {
    test('reports OK when at least one backend is available', () async {
      const result = SandboxDetectionResult(
        platform: 'test',
        recommendation: SandboxBackend.native,
        capabilities: {
          SandboxBackend.native: SandboxBackendCapabilities(
            backend: SandboxBackend.native,
            available: true,
          ),
          SandboxBackend.none: SandboxBackendCapabilities(
            backend: SandboxBackend.none,
            available: true,
          ),
        },
      );
      final fake = FakeSandboxDetectorPort(result);
      final service = DoctorService(sandboxDetector: fake);

      final report = await service.runDiagnostics();

      final sandboxResult = report.results.firstWhere(
        (r) => r.name == 'Sandbox backend',
      );
      expect(sandboxResult.status, DiagnosticStatus.ok);
      expect(sandboxResult.isOk, isTrue);
      expect(sandboxResult.message, contains('backend(s)'));
    });
  });
}
