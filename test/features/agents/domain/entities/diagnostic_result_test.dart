import 'package:cc_domain/features/agents/domain/entities/diagnostic_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DiagnosticResult', () {
    test('isOk is true for ok status', timeout: const Timeout.factor(2), () {
      const result = DiagnosticResult(
        name: 'check',
        status: DiagnosticStatus.ok,
      );
      expect(result.isOk, isTrue);
      expect(result.isWarning, isFalse);
      expect(result.isError, isFalse);
    });

    test('isWarning is true for warning status', timeout: const Timeout.factor(2), () {
      const result = DiagnosticResult(
        name: 'check',
        status: DiagnosticStatus.warning,
        message: 'deprecated',
      );
      expect(result.isOk, isFalse);
      expect(result.isWarning, isTrue);
      expect(result.isError, isFalse);
    });

    test('isError is true for error status', timeout: const Timeout.factor(2), () {
      const result = DiagnosticResult(
        name: 'check',
        status: DiagnosticStatus.error,
        message: 'missing config',
        canAutoRepair: true,
      );
      expect(result.isOk, isFalse);
      expect(result.isWarning, isFalse);
      expect(result.isError, isTrue);
      expect(result.canAutoRepair, isTrue);
    });

    test('canAutoRepair defaults to false', timeout: const Timeout.factor(2), () {
      const result = DiagnosticResult(
        name: 'check',
        status: DiagnosticStatus.error,
      );
      expect(result.canAutoRepair, isFalse);
    });

    test('equality includes all fields', timeout: const Timeout.factor(2), () {
      const a = DiagnosticResult(
        name: 'check',
        status: DiagnosticStatus.warning,
        message: 'msg',
        canAutoRepair: true,
      );
      const b = DiagnosticResult(
        name: 'check',
        status: DiagnosticStatus.warning,
        message: 'msg',
        canAutoRepair: true,
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('inequality when fields differ', timeout: const Timeout.factor(2), () {
      const a = DiagnosticResult(
        name: 'check',
        status: DiagnosticStatus.ok,
      );
      const b = DiagnosticResult(
        name: 'check',
        status: DiagnosticStatus.error,
      );
      expect(a, isNot(equals(b)));
    });
  });

  group('DoctorReport', () {
    test('allOk is true when every result is ok', timeout: const Timeout.factor(2), () {
      const report = DoctorReport(results: [
        DiagnosticResult(name: 'a', status: DiagnosticStatus.ok),
        DiagnosticResult(name: 'b', status: DiagnosticStatus.ok),
      ]);
      expect(report.allOk, isTrue);
      expect(report.hasErrors, isFalse);
      expect(report.hasWarnings, isFalse);
    });

    test('allOk is false when any result is not ok', timeout: const Timeout.factor(2), () {
      const report = DoctorReport(results: [
        DiagnosticResult(name: 'a', status: DiagnosticStatus.ok),
        DiagnosticResult(name: 'b', status: DiagnosticStatus.warning),
      ]);
      expect(report.allOk, isFalse);
    });

    test('hasErrors counts error results', timeout: const Timeout.factor(2), () {
      const report = DoctorReport(results: [
        DiagnosticResult(name: 'a', status: DiagnosticStatus.ok),
        DiagnosticResult(name: 'b', status: DiagnosticStatus.error),
        DiagnosticResult(name: 'c', status: DiagnosticStatus.error),
      ]);
      expect(report.hasErrors, isTrue);
      expect(report.errorCount, 2);
    });

    test('hasWarnings counts warning results', timeout: const Timeout.factor(2), () {
      const report = DoctorReport(results: [
        DiagnosticResult(name: 'a', status: DiagnosticStatus.warning),
        DiagnosticResult(name: 'b', status: DiagnosticStatus.warning),
        DiagnosticResult(name: 'c', status: DiagnosticStatus.ok),
      ]);
      expect(report.hasWarnings, isTrue);
      expect(report.warningCount, 2);
    });

    test('empty report is allOk and has no errors/warnings',
        timeout: const Timeout.factor(2), () {
      const report = DoctorReport(results: []);
      expect(report.allOk, isTrue);
      expect(report.hasErrors, isFalse);
      expect(report.hasWarnings, isFalse);
      expect(report.errorCount, 0);
      expect(report.warningCount, 0);
    });

    test('equality uses deep collection equality', timeout: const Timeout.factor(2), () {
      const a = DoctorReport(results: [
        DiagnosticResult(name: 'x', status: DiagnosticStatus.ok),
      ]);
      const b = DoctorReport(results: [
        DiagnosticResult(name: 'x', status: DiagnosticStatus.ok),
      ]);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('inequality when results differ', timeout: const Timeout.factor(2), () {
      const a = DoctorReport(results: [
        DiagnosticResult(name: 'x', status: DiagnosticStatus.ok),
      ]);
      const b = DoctorReport(results: [
        DiagnosticResult(name: 'x', status: DiagnosticStatus.error),
      ]);
      expect(a, isNot(equals(b)));
    });
  });
}
