import 'dart:io';

import 'package:control_center/core/domain/value_objects/sandbox_backend.dart';
import 'package:control_center/core/infrastructure/process/binary_resolver.dart';
import 'package:control_center/features/agents/domain/entities/diagnostic_result.dart';
import 'package:control_center/features/agents/domain/ports/doctor_port.dart';
import 'package:control_center/features/sandboxing/domain/ports/sandbox_detector_port.dart';

/// Runs diagnostic checks on the sandbox backend, database, CLI tools,
/// disk space, and network connectivity.
class DoctorService implements DoctorPort {
  /// Creates a [DoctorService] with the given [SandboxDetectorPort].
  DoctorService({required this.sandboxDetector});

  /// Detector used to discover the available sandbox backend.
  final SandboxDetectorPort sandboxDetector;

  @override
  Future<DoctorReport> runDiagnostics() async {
    final results = <DiagnosticResult>[];

    results.add(await _checkSandboxBackend());
    results.add(await _checkDatabaseAccess());
    results.add(await _checkCliTools());
    results.add(await _checkDiskSpace());
    results.add(await _checkNetworkConnectivity());

    return DoctorReport(results: results);
  }

  Future<DiagnosticResult> _checkSandboxBackend() async {
    try {
      final detection = await sandboxDetector.detect();
      final available = detection.capabilities.values
          .where((c) => c.available && c.backend != SandboxBackend.none)
          .toList();
      if (available.isEmpty) {
        return const DiagnosticResult(
          name: 'Sandbox backend',
          status: DiagnosticStatus.warning,
          message: 'No sandbox backend available. Agents run unsandboxed.',
        );
      }
      return DiagnosticResult(
        name: 'Sandbox backend',
        status: DiagnosticStatus.ok,
        message:
            '${detection.recommendation.name} available (${available.length} backend(s))',
      );
    } catch (e) {
      return DiagnosticResult(
        name: 'Sandbox backend',
        status: DiagnosticStatus.error,
        message: 'Detection failed: $e',
      );
    }
  }

  Future<DiagnosticResult> _checkDatabaseAccess() async {
    try {
      final dbPath = await _defaultDbPath();
      final file = File(dbPath);
      if (!file.existsSync()) {
        return const DiagnosticResult(
          name: 'Database',
          status: DiagnosticStatus.error,
          message:
              'Database file not found. Will be created on first launch.',
          canAutoRepair: true,
        );
      }
      return DiagnosticResult(
        name: 'Database',
        status: DiagnosticStatus.ok,
        message: 'Database accessible (${_formatBytes(await file.length())})',
      );
    } catch (e) {
      return DiagnosticResult(
        name: 'Database',
        status: DiagnosticStatus.error,
        message: 'Cannot access database: $e',
      );
    }
  }

  Future<DiagnosticResult> _checkCliTools() async {
    final missing = <String>[];
    for (final tool in ['git', 'pi']) {
      final resolved = await resolveBinaryPath(tool);
      if (resolved == null) {
        missing.add(tool);
      }
    }
    if (missing.isEmpty) {
      return const DiagnosticResult(
        name: 'CLI Tools',
        status: DiagnosticStatus.ok,
        message: 'git, pi found',
      );
    }
    return DiagnosticResult(
      name: 'CLI Tools',
      status: DiagnosticStatus.warning,
      message: 'Missing: ${missing.join(', ')}',
    );
  }

  Future<DiagnosticResult> _checkDiskSpace() async {
    try {
      final result = await Process.run('df', ['-h', '-k', '/']);
      final output = result.stdout.toString();
      final lines = output.split('\n');
      if (lines.length >= 2) {
        final parts = lines[1].split(RegExp(r'\s+'));
        if (parts.length >= 5) {
          final available = parts[3];
          final percent = parts[4];
          return DiagnosticResult(
            name: 'Disk space',
            status: DiagnosticStatus.ok,
            message: '$available available ($percent used)',
          );
        }
      }
      return const DiagnosticResult(
        name: 'Disk space',
        status: DiagnosticStatus.warning,
        message: 'Could not determine disk space',
      );
    } catch (e) {
      return DiagnosticResult(
        name: 'Disk space',
        status: DiagnosticStatus.warning,
        message: 'Check failed: $e',
      );
    }
  }

  Future<DiagnosticResult> _checkNetworkConnectivity() async {
    try {
      final socket = await Socket.connect('api.github.com', 443,
          timeout: const Duration(seconds: 5));
      socket.destroy();
      return const DiagnosticResult(
        name: 'Network',
        status: DiagnosticStatus.ok,
        message: 'GitHub API reachable',
      );
    } catch (e) {
      return DiagnosticResult(
        name: 'Network',
        status: DiagnosticStatus.warning,
        message: 'GitHub API unreachable: $e',
      );
    }
  }

  Future<String> _defaultDbPath() async {
    final home = Platform.environment['HOME'] ?? '/tmp';
    return '$home/Library/Application Support/dev.control-center.app/control_center.db';
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
