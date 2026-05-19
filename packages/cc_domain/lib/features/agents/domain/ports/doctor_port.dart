import 'package:cc_domain/features/agents/domain/entities/diagnostic_result.dart';

/// Port for running system diagnostics and producing a [DoctorReport].
abstract class DoctorPort {
  /// Runs all registered diagnostic checks and returns a compiled report.
  Future<DoctorReport> runDiagnostics();
}
