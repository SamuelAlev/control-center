import 'package:control_center/core/domain/ports/sandbox_port.dart';
import 'package:control_center/core/domain/value_objects/sandbox_backend.dart';

class SandboxDetectionResult {
  const SandboxDetectionResult({
    required this.platform,
    required this.recommendation,
    required this.capabilities,
  });

  final String platform;
  final SandboxBackend recommendation;
  final Map<SandboxBackend, SandboxBackendCapabilities> capabilities;
}
