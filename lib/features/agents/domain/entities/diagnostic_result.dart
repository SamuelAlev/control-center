import 'package:collection/collection.dart';

class DiagnosticResult {
  const DiagnosticResult({
    required this.name,
    required this.status,
    this.message,
    this.canAutoRepair = false,
  });

  final String name;
  final DiagnosticStatus status;
  final String? message;
  final bool canAutoRepair;

  bool get isOk => status == DiagnosticStatus.ok;
  bool get isWarning => status == DiagnosticStatus.warning;
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

enum DiagnosticStatus {
  ok,
  warning,
  error,
}

class DoctorReport {
  const DoctorReport({required this.results});

  final List<DiagnosticResult> results;

  bool get allOk => results.every((r) => r.isOk);
  bool get hasErrors => results.any((r) => r.isError);
  bool get hasWarnings => results.any((r) => r.isWarning);
  int get errorCount => results.where((r) => r.isError).length;
  int get warningCount => results.where((r) => r.isWarning).length;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DoctorReport &&
          const DeepCollectionEquality().equals(results, other.results);

  @override
  int get hashCode => const DeepCollectionEquality().hash(results);
}
