import 'dart:io';

import 'package:cc_domain/core/domain/ports/sandbox_port.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_backend.dart';
import 'package:cc_domain/features/sandboxing/domain/ports/sandbox_detector_port.dart';
import 'package:cc_domain/features/sandboxing/domain/sandbox_detection_result.dart';

/// Probes all known [SandboxPort] backends and recommends the best one for
/// the current host. Run once at app startup.
class SandboxBackendDetector implements SandboxDetectorPort {
  /// Creates a [SandboxBackendDetector] over the given pool of adapter
  /// instances. Each adapter is responsible for probing itself.
  SandboxBackendDetector(this._adapters);

  final List<SandboxPort> _adapters;

  /// Probes every adapter and returns the result.
  @override
  Future<SandboxDetectionResult> detect() async {
    final capabilities = <SandboxBackend, SandboxBackendCapabilities>{};
    for (final adapter in _adapters) {
      try {
        capabilities[adapter.backend] = await adapter.probe();
      } catch (e) {
        capabilities[adapter.backend] = SandboxBackendCapabilities(
          backend: adapter.backend,
          available: false,
          note: 'Probe failed: $e',
        );
      }
    }

    SandboxBackend pickFirstAvailable(List<SandboxBackend> order) {
      for (final b in order) {
        if (capabilities[b]?.available == true) {
          return b;
        }
      }
      return SandboxBackend.none;
    }

    // We ship two adapters now: the in-project native sandbox runtime
    // (`sandbox-exec` on macOS, `bubblewrap` on Linux/WSL2) and the opt-out
    // no-isolation path. Recommend native when available.
    final recommendation = pickFirstAvailable([
      SandboxBackend.native,
    ]);

    return SandboxDetectionResult(
      platform: _platformLabel(),
      recommendation: recommendation,
      capabilities: capabilities,
    );
  }

  static String _platformLabel() {
    if (Platform.isMacOS) {
      return 'macOS (${_arch()})';
    }
    if (Platform.isLinux) {
      return 'Linux (${_arch()})';
    }
    if (Platform.isWindows) {
      return 'Windows (${_arch()})';
    }
    return Platform.operatingSystem;
  }

  static String _arch() {
    // Process.version doesn't expose CPU arch directly. Inspect the locale
    // env var as a heuristic; otherwise fall back to operatingSystemVersion.
    final result = Platform.version;
    if (result.contains('arm64') || result.contains('aarch64')) {
      return 'aarch64';
    }
    if (result.contains('x86_64') || result.contains('amd64')) {
      return 'x86_64';
    }
    return 'unknown';
  }
}
