import 'package:control_center/features/sandboxing/domain/sandbox_detection_result.dart';

abstract class SandboxDetectorPort {
  Future<SandboxDetectionResult> detect();
}
