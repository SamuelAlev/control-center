import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/features/mcp/domain/ports/mcp_client_control.dart';
import 'package:cc_mcp/cc_mcp.dart';
import 'package:cc_mcp_client/cc_mcp_client.dart';
import 'package:path/path.dart' as p;

/// Host-side implementation of [McpClientControl] (PRD 01): adapts the live
/// [McpClientService] (the external-MCP client subsystem) to the platform-
/// neutral control the `mcp.client.*` RPC ops expose.
///
/// One instance per host (the external servers are a process-wide concern, not
/// workspace data). It owns the standing approval posture — persisted to
/// `mcp_client_config.json` under the host's data dir so it survives restarts —
/// and re-points the shared [McpToolDispatcher]'s tier gate whenever the
/// posture changes, so a single assignment governs every transport at once.
///
/// Authorization is interactive: it only succeeds on a host that can reach the
/// user's browser + a local loopback callback (the desktop in-process host).
/// A remote headless `cc_server` has no browser launcher, so `authorize`
/// surfaces a [StateError] the caller relays as "authorize on the host".
class ServerMcpClientControl implements McpClientControl {
  /// Creates a control over [service], updating [dispatcher]'s approval mode and
  /// persisting the posture under [dataDir].
  ServerMcpClientControl({
    required McpClientService service,
    required McpToolDispatcher dispatcher,
    required String dataDir,
  }) : _service = service,
       _dispatcher = dispatcher,
       _file = File(p.join(dataDir, 'mcp_client_config.json'));

  final McpClientService _service;
  final McpToolDispatcher _dispatcher;
  final File _file;

  ApprovalMode _mode = ApprovalMode.alwaysAsk;
  bool _loaded = false;

  /// Loads the persisted approval posture and applies it to the dispatcher.
  /// Call once at boot so the gate reflects the user's stored preference.
  Future<void> init() => _ensureLoaded();

  Future<void> _ensureLoaded() async {
    if (_loaded) {
      return;
    }
    _loaded = true;
    if (!_file.existsSync()) {
      return;
    }
    try {
      final decoded = jsonDecode(await _file.readAsString());
      if (decoded is Map) {
        _mode = ApprovalMode.fromWire(decoded['approval_mode'] as String?);
      }
    } on Object {
      // Corrupt config — keep the safe default (always-ask).
    }
    _dispatcher.approvalMode = _mode;
  }

  Future<void> _persist() async {
    await _file.parent.create(recursive: true);
    final tmp = File('${_file.path}.tmp');
    await tmp.writeAsString(jsonEncode({'approval_mode': _mode.wire}));
    await tmp.rename(_file.path);
  }

  @override
  Future<List<McpExternalServerInfo>> servers() async {
    return [
      for (final s in _service.serverStatuses)
        McpExternalServerInfo(
          name: s.name,
          transport: s.transport,
          lifecycle: s.lifecycle.wire,
          auth: s.auth,
          toolCount: s.toolCount,
          resourceCount: s.resourceCount,
          promptCount: s.promptCount,
          source: s.source,
          lastError: s.lastError,
        ),
    ];
  }

  @override
  Future<ApprovalMode> approvalMode() async {
    await _ensureLoaded();
    return _mode;
  }

  @override
  Future<void> setApprovalMode(ApprovalMode mode) async {
    await _ensureLoaded();
    _mode = mode;
    _dispatcher.approvalMode = mode;
    await _persist();
  }

  @override
  Future<void> authorize(String serverName) =>
      _service.authorizeByName(serverName);

  @override
  Future<void> reconnect(String serverName) =>
      _service.reconnect(serverName, manual: true);
}
