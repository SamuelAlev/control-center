import 'dart:io';

import 'package:control_center/core/utils/app_log.dart';

/// Detection status of a CLI adapter.
enum DetectionStatus {
  /// Binary found on PATH and auth check passed.
  ready,
  /// Binary found but auth check failed.
  notAuthenticated,
  /// Binary not found on PATH.
  notInstalled,
  /// Detection has not been run yet.
  unknown,
}

/// Result of probing a single adapter.
class AdapterDetectionResult {
  /// Creates an adapter detection result.
  const AdapterDetectionResult({
    required this.cliName,
    required this.status,
    this.binaryPath,
    this.configDir,
    this.authError,
    this.detectedAt,
  });

  /// CLI name (e.g. 'pi', 'claude').
  final String cliName;

  /// Current detection status.
  final DetectionStatus status;

  /// Resolved binary path, if found.
  final String? binaryPath;

  /// Config directory path, if applicable.
  final String? configDir;

  /// Auth error message, if status is [DetectionStatus.notAuthenticated].
  final String? authError;

  /// When this result was computed.
  final DateTime? detectedAt;
}

/// Known adapter definitions for detection.
class _AdapterDef {
  const _AdapterDef({
    required this.cliName,
    this.configDirs = const [],
    this.authProbeArgs = const [],
    this.authSuccessPattern,
  });

  final String cliName;

  /// Candidate config directories to probe (existence check).
  final List<String> configDirs;

  /// Arguments to run for a cheap auth check. Empty = skip auth probe.
  final List<String> authProbeArgs;

  /// If the auth probe stdout contains this pattern, auth is valid.
  final String? authSuccessPattern;
}

/// Scans for installed CLI agent binaries and checks their auth state.
///
/// Results are cached for [cacheTtl]. Call [detect] to refresh or
/// [getCached] to return the last result without re-probing.
class AgentDetectionService {
  /// Creates an agent detection service.
  AgentDetectionService({this.cacheTtl = const Duration(hours: 24)});

  /// How long cached detection results are considered fresh.
  final Duration cacheTtl;

  static const _adapters = [
    _AdapterDef(cliName: 'pi'),
    _AdapterDef(
      cliName: 'claude',
      configDirs: [
        '~/.claude',
      ],
      authProbeArgs: ['--version'],
      authSuccessPattern: null,
    ),
  ];

  final Map<String, AdapterDetectionResult> _cache = {};

  /// Runs detection for all known adapters. Returns results keyed by CLI name.
  Future<Map<String, AdapterDetectionResult>> detect() async {
    final results = <String, AdapterDetectionResult>{};
    for (final adapter in _adapters) {
      results[adapter.cliName] = await _detectOne(adapter);
    }
    _cache.clear();
    _cache.addAll(results);
    return results;
  }

  /// Returns cached results. Calls [detect] if cache is empty or expired.
  Future<Map<String, AdapterDetectionResult>> getCached() async {
    if (_cache.isEmpty || _isExpired) {
      return detect();
    }
    return Map.unmodifiable(_cache);
  }

  bool get _isExpired {
    if (_cache.isEmpty) {
      return true;
    }
    final oldest = _cache.values
        .map((r) => r.detectedAt)
        .whereType<DateTime>()
        .reduce((a, b) => a.isBefore(b) ? a : b);
    return DateTime.now().difference(oldest) > cacheTtl;
  }

  Future<AdapterDetectionResult> _detectOne(_AdapterDef adapter) async {
    final now = DateTime.now();

    // 1. Check binary on PATH.
    final binaryPath = await _which(adapter.cliName);
    if (binaryPath == null) {
      return AdapterDetectionResult(
        cliName: adapter.cliName,
        status: DetectionStatus.notInstalled,
        detectedAt: now,
      );
    }

    // 2. Check config dirs.
    String? configDir;
    for (final candidate in adapter.configDirs) {
      final expanded = _expandHome(candidate);
      if (Directory(expanded).existsSync()) {
        configDir = expanded;
        break;
      }
    }

    // 3. Auth probe.
    if (adapter.authProbeArgs.isNotEmpty) {
      try {
        final result = await Process.run(
          adapter.cliName,
          adapter.authProbeArgs,
          runInShell: true,
        );
        final stdout = (result.stdout as String).toLowerCase();
        if (result.exitCode == 0) {
          if (adapter.authSuccessPattern == null ||
              stdout.contains(adapter.authSuccessPattern!.toLowerCase())) {
            return AdapterDetectionResult(
              cliName: adapter.cliName,
              status: DetectionStatus.ready,
              binaryPath: binaryPath,
              configDir: configDir,
              detectedAt: now,
            );
          }
        }
        return AdapterDetectionResult(
          cliName: adapter.cliName,
          status: DetectionStatus.notAuthenticated,
          binaryPath: binaryPath,
          configDir: configDir,
          authError: 'Auth probe exited with code ${result.exitCode}',
          detectedAt: now,
        );
      } catch (e) {
        AppLog.w('AgentDetection', 'Auth probe failed for ${adapter.cliName}: $e');
        return AdapterDetectionResult(
          cliName: adapter.cliName,
          status: DetectionStatus.notAuthenticated,
          binaryPath: binaryPath,
          configDir: configDir,
          authError: e.toString(),
          detectedAt: now,
        );
      }
    }

    // No auth probe needed — binary found is enough.
    return AdapterDetectionResult(
      cliName: adapter.cliName,
      status: DetectionStatus.ready,
      binaryPath: binaryPath,
      configDir: configDir,
      detectedAt: now,
    );
  }

  /// Resolves the full path of [binary] using `which`, or null if not found.
  static Future<String?> _which(String binary) async {
    try {
      final result = await Process.run(
        'which',
        [binary],
        runInShell: true,
      );
      if (result.exitCode == 0) {
        final path = (result.stdout as String).trim();
        return path.isEmpty ? null : path;
      }
    } catch (_) {
      // which not available or binary not found.
    }
    return null;
  }

  static String _expandHome(String path) {
    if (path.startsWith('~/')) {
      return '${Platform.environment['HOME'] ?? '.'}${path.substring(1)}';
    }
    return path;
  }
}
