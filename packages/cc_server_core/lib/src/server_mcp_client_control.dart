import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/features/mcp/domain/ports/mcp_client_control.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/capability_tier.dart';
import 'package:cc_mcp/cc_mcp.dart';
import 'package:path/path.dart' as p;

/// Host-side implementation of [McpClientControl]: the standing approval
/// posture for tools bridged from external MCP servers.
///
/// One instance per host. The posture is persisted to
/// `mcp_client_config.json` under the host's data dir so it survives
/// restarts, and re-points the shared [McpToolDispatcher]'s tier gate whenever
/// it changes, so a single assignment governs every transport at once. The
/// servers themselves are `WorkspaceMcpServers'`.
class ServerMcpClientControl implements McpClientControl {
  /// Creates a control updating [_dispatcher]'s approval mode and persisting
  /// the posture under [dataDir].
  ServerMcpClientControl({
    required this._dispatcher,
    required String dataDir,
  }) : _file = File(p.join(dataDir, 'mcp_client_config.json')),
       _dataDir = dataDir;

  final McpToolDispatcher _dispatcher;
  final File _file;
  final String _dataDir;

  /// What the releases before per-member servers kept in the data dir for
  /// the server owner's personal servers: their definitions, their sign-ins
  /// and their cached tool lists.
  static const List<String> legacyPersonalFiles = [
    'mcp_personal_servers.json',
    'mcp_oauth_tokens.json',
    'mcp_tool_cache.json',
  ];

  /// Deletes [legacyPersonalFiles]. Nothing reads them any more.
  Future<void> deleteLegacyPersonalFiles() async {
    for (final name in legacyPersonalFiles) {
      final file = File(p.join(_dataDir, name));
      if (file.existsSync()) {
        await file.delete();
      }
    }
  }

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
}
