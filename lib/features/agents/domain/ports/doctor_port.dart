import 'package:control_center/features/agents/domain/entities/diagnostic_result.dart';

abstract class DoctorPort {
  Future<DoctorReport> runDiagnostics();
}
