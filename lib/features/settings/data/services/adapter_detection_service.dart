import 'dart:io';

import 'package:control_center/core/infrastructure/process/binary_resolver.dart';
import 'package:control_center/features/settings/domain/entities/adapter.dart';

/// Service that probes the local filesystem to detect whether an adapter CLI is installed.
class AdapterDetectionService {
  /// Creates a new [AdapterDetectionService].
  const AdapterDetectionService();

  /// Detect one.
  Future<DetectedAdapter> detectOne(Adapter adapter) async {
    try {
      final path = await resolveBinaryPath(adapter.cliName);
      if (path == null) {
        return DetectedAdapter(
          adapter: adapter,
          status: DetectionStatus.notFound,
        );
      }

      final versionResult = await Process.run(path, ['--version']);

      if (versionResult.exitCode == 0) {
        return DetectedAdapter(
          adapter: adapter,
          status: DetectionStatus.found,
          capabilities: capabilitiesForAdapter(adapter.id),
          version: (versionResult.stdout as String).trim(),
          path: path,
        );
      }

      final versionStderr = (versionResult.stderr as String).trim();
      if (versionStderr.isNotEmpty) {
        return DetectedAdapter(
          adapter: adapter,
          status: DetectionStatus.found,
          capabilities: capabilitiesForAdapter(adapter.id),
          version: versionStderr,
          path: path,
        );
      }

      return DetectedAdapter(
        adapter: adapter,
        status: DetectionStatus.found,
        path: path,
      );
    } catch (_) {
      return DetectedAdapter(
        adapter: adapter,
        status: DetectionStatus.notFound,
      );
    }
  }
}

