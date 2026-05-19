import 'package:control_center/core/domain/ports/sandbox_port.dart';
import 'package:control_center/core/domain/value_objects/sandbox_backend.dart';

/// Stores the result of sandbox environment detection, including the platform,
/// the recommended backend, and available backend capabilities.
class SandboxDetectionResult {
  /// Creates a [SandboxDetectionResult] with the detected platform, backend
  /// recommendation, and available capabilities for each backend.
  const SandboxDetectionResult({
    required this.platform,
    required this.recommendation,
    required this.capabilities,
  });

  /// The detected platform name (e.g., "linux", "macos", "windows").
  final String platform;

  /// The recommended [SandboxBackend] for this environment.
  final SandboxBackend recommendation;

  /// The available capabilities for each supported [SandboxBackend].
  final Map<SandboxBackend, SandboxBackendCapabilities> capabilities;
}
