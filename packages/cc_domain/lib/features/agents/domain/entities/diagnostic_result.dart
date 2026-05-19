import 'package:collection/collection.dart';

/// Represents a single diagnostic check result from the system doctor.
class DiagnosticResult {
  /// Creates a diagnostic result with the given [name], [status],
  /// optional [message], and [canAutoRepair] flag.
  const DiagnosticResult({
    required this.name,
    required this.status,
    this.message,
    this.canAutoRepair = false,
  });

  /// Human-readable name of the diagnostic check.
  final String name;
  /// Current status of this diagnostic check.
  final DiagnosticStatus status;
  /// Optional diagnostic detail message, e.g. repair instructions.
  final String? message;
  /// Whether the system can automatically repair this issue.
  final bool canAutoRepair;

  /// Whether this check passed without issues.
  bool get isOk => status == DiagnosticStatus.ok;
  /// Whether this check produced a warning.
  bool get isWarning => status == DiagnosticStatus.warning;
  /// Whether this check produced a blocking error.
  bool get isError => status == DiagnosticStatus.error;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiagnosticResult &&
          name == other.name &&
          status == other.status &&
          message == other.message &&
          canAutoRepair == other.canAutoRepair;

  @override
  int get hashCode => Object.hash(name, status, message, canAutoRepair);
}

/// Severity level of a diagnostic check result.
enum DiagnosticStatus {
  /// The diagnostic check passed successfully.
  ok,
  /// The diagnostic check produced a non-blocking warning.
  warning,
  /// The diagnostic check produced a blocking error.
  error,
}

/// A collection of [DiagnosticResult] entries produced by the system doctor.
class DoctorReport {
  /// Creates a doctor report from a list of [results].
  const DoctorReport({required this.results});

  /// Individual diagnostic check results contained in this report.
  final List<DiagnosticResult> results;

  /// Whether every diagnostic check passed.
  bool get allOk => results.every((r) => r.isOk);
  /// Whether any diagnostic check produced an error.
  bool get hasErrors => results.any((r) => r.isError);
  /// Whether any diagnostic check produced a warning.
  bool get hasWarnings => results.any((r) => r.isWarning);
  /// Number of checks that produced an error.
  int get errorCount => results.where((r) => r.isError).length;
  /// Number of checks that produced a warning.
  int get warningCount => results.where((r) => r.isWarning).length;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DoctorReport &&
          const DeepCollectionEquality().equals(results, other.results);

  @override
  int get hashCode => const DeepCollectionEquality().hash(results);
}
