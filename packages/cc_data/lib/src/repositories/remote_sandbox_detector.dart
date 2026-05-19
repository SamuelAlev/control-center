import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/ports/sandbox_port.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_backend.dart';
import 'package:cc_domain/features/sandboxing/domain/ports/sandbox_detector_port.dart';
import 'package:cc_domain/features/sandboxing/domain/sandbox_detection_result.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// A [SandboxDetectorPort] backed by the RPC client — the thin-client data path.
///
/// The sandbox runs on the SERVER's machine, so what backends are available
/// (and which one is recommended) is a property of the HOST, not the browser /
/// desktop client. A thin/web client therefore asks the connected `cc_server`
/// to run its own `SandboxBackendDetector` over the `sandbox.detect` op and
/// decodes the resulting [SandboxDetectionResult] — it never probes its own
/// (on web: impossible) platform via `dart:io`.
///
/// A host that wires no detector leaves the op absent (default-deny →
/// `opUnknown`); the client degrades to a safe "no isolation only" result so
/// the settings page still renders and lets the user opt into "No isolation"
/// rather than surfacing a hard error.
class RemoteSandboxDetector implements SandboxDetectorPort {
  /// Creates a [RemoteSandboxDetector] over [_client].
  RemoteSandboxDetector(this._client);

  final RemoteRpcClient _client;

  @override
  Future<SandboxDetectionResult> detect() async {
    try {
      final data = await _client.call('sandbox.detect', const {});
      return _fromWire(data);
    } on RemoteRpcException catch (e) {
      if (e.code == RpcErrorCodes.opUnknown) {
        return const SandboxDetectionResult(
          platform: '',
          recommendation: SandboxBackend.none,
          capabilities: {
            SandboxBackend.none: SandboxBackendCapabilities(
              backend: SandboxBackend.none,
              available: true,
            ),
          },
        );
      }
      rethrow;
    }
  }

  static SandboxDetectionResult _fromWire(Map<String, dynamic> data) {
    final caps = <SandboxBackend, SandboxBackendCapabilities>{};
    for (final entry in (data['capabilities'] as List?) ?? const []) {
      if (entry is! Map) {
        continue;
      }
      final w = entry.cast<String, dynamic>();
      final backend = SandboxBackend.fromName(w['backend'] as String?);
      caps[backend] = SandboxBackendCapabilities(
        backend: backend,
        available: w['available'] as bool? ?? false,
        requiresInstall: w['requires_install'] as bool? ?? false,
        installHint: w['install_hint'] as String?,
        note: w['note'] as String?,
      );
    }
    return SandboxDetectionResult(
      platform: data['platform'] as String? ?? '',
      recommendation: SandboxBackend.fromName(data['recommendation'] as String?),
      capabilities: caps,
    );
  }
}
