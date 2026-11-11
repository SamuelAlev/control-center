import 'dart:io';

import 'package:cc_domain/cc_domain.dart' show ValidationException;
import 'package:cc_domain/features/settings/domain/entities/adapter.dart';
import 'package:cc_infra/cc_infra.dart';

/// Service that probes the local filesystem to detect whether an adapter CLI is installed.
///
/// What runs is decided here, never by the caller: an adapter is looked up by
/// id in the adapter registry and only the binary the registry names is
/// resolved and asked for `--version`. A client sends an adapter over the
/// wire, and a `cliName` it chose would otherwise be a program the host runs.
class AdapterDetectionService {
  /// Creates a new [AdapterDetectionService] over `registry` (the predefined
  /// adapters when null).
  const AdapterDetectionService({
    this._registry,
    this._resolve = resolveBinaryPath,
    Future<ProcessResult> Function(String executable, List<String> args) run =
        _run,
  }) : _runProcess = run;

  final List<Adapter>? _registry;
  final Future<String?> Function(String binary) _resolve;
  final Future<ProcessResult> Function(String executable, List<String> args)
  _runProcess;

  static Future<ProcessResult> _run(String executable, List<String> args) =>
      ChildProcess.run(executable, args);

  /// The registry adapter with [id], or null when the registry names none.
  Adapter? _registered(String id) {
    for (final adapter in _registry ?? predefinedAdapters) {
      if (adapter.id == id) {
        return adapter;
      }
    }
    return null;
  }

  /// Detect one.
  ///
  /// Throws a [ValidationException] (code `unknown_adapter`) for an id the
  /// registry does not name, before anything is resolved or started.
  Future<DetectedAdapter> detectOne(Adapter requested) async {
    final adapter = _registered(requested.id);
    if (adapter == null) {
      throw ValidationException(
        'Unknown adapter "${requested.id}": only registered adapters are '
        'detected.',
        code: 'unknown_adapter',
      );
    }
    // The built-in harness has no external binary — it is always available.
    if (adapter.transport == AdapterTransport.harness) {
      return DetectedAdapter(
        adapter: adapter,
        status: DetectionStatus.found,
        capabilities: capabilitiesForAdapter(adapter.id),
        version: 'built-in',
      );
    }
    try {
      final path = await _resolve(adapter.cliName);
      if (path == null) {
        return DetectedAdapter(
          adapter: adapter,
          status: DetectionStatus.notFound,
        );
      }

      final versionResult = await _runProcess(path, ['--version']);

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
