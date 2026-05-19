import 'package:control_center/features/sandboxing/domain/sandbox_detection_result.dart';

/// Port for detecting the sandbox environment.
abstract class SandboxDetectorPort {
  /// Detects the sandbox environment and returns the result.
  Future<SandboxDetectionResult> detect();
}
