import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/features/mcp/domain/entities/mcp_server_definition.dart';
import 'package:cc_domain/features/mcp/domain/ports/mcp_client_control.dart';
import 'package:cc_domain/features/mcp/domain/repositories/mcp_server_definition_repository.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/capability_tier.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/mcp_server_draft.dart';
import 'package:cc_mcp/cc_mcp.dart';
import 'package:cc_mcp_client/cc_mcp_client.dart';
import 'package:cc_server_core/src/mcp_servers/mcp_server_secrets.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

/// Host-side implementation of [McpClientControl] (PRD 01): adapts the live
/// [McpClientService] (the external-MCP client subsystem) to the platform-
/// neutral control the `mcp.client.*` RPC ops expose.
///
/// One instance per host: these are the server owner's PERSONAL servers, the
/// ones discovered in their own tool configs plus the ones they added here
/// ([PersonalMcpServerRepository]); a hand-added server wins over a discovered
/// one of the same name. Workspace-configured servers are
/// `WorkspaceMcpServers`'. It owns the standing approval posture — persisted to
/// `mcp_client_config.json` under the host's data dir so it survives restarts —
/// and re-points the shared [McpToolDispatcher]'s tier gate whenever the
/// posture changes, so a single assignment governs every transport at once.
///
/// Authorization is interactive: it only succeeds on a host that can reach the
/// user's browser + a local loopback callback (the desktop in-process host).
/// A remote headless `cc_server` has no browser launcher, so `authorize`
/// surfaces a [StateError] the caller relays as "authorize on the host".
class ServerMcpClientControl implements McpClientControl {
  /// Creates a control over [_service], updating [_dispatcher]'s approval mode and
  /// persisting the posture under [dataDir].
  ///
  /// `homeDir` is where the owner's tool configs are discovered (null: none).
  ServerMcpClientControl({
    required this._service,
    required this._dispatcher,
    required String dataDir,
    required this._repository,
    required this._secrets,
    required this._homeDir,
    DateTime Function()? clock,
  }) : _file = File(p.join(dataDir, 'mcp_client_config.json')),
       _clock = clock ?? DateTime.now;

  final McpClientService _service;
  final McpToolDispatcher _dispatcher;
  final File _file;
  final PersonalMcpServerRepository _repository;
  final McpServerSecrets _secrets;
  final String? _homeDir;
  final DateTime Function() _clock;
  Future<void> _refreshing = Future<void>.value();

  /// Connects the owner's personal servers: discovered plus hand-added, the
  /// hand-added one winning a name clash. Returns how many there are.
  /// Refreshes run one after another.
  Future<int> refresh() {
    late int count;
    final run = _refreshing.catchError((_) {}).then((_) async {
      final byName = <String, McpServerConfig>{};
      final home = _homeDir;
      if (home != null && home.isNotEmpty) {
        for (final config in await _service.discover(homeDir: home)) {
          byName[config.name] = config;
        }
      }
      for (final definition in await _repository.list()) {
        byName[definition.name] = await _secrets.configFor(
          definition,
          source: McpExternalServerInfo.handAddedSource,
        );
      }
      count = byName.length;
      await _service.start(byName.values.toList());
    });
    _refreshing = run;
    return run.then((_) => count);
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
  Future<List<McpExternalServerInfo>> servers() async {
    final handAdded = {for (final d in await _repository.list()) d.name: d};
    return [
      for (final s in _service.serverStatuses)
        McpExternalServerInfo(
          definition: s.source == McpExternalServerInfo.handAddedSource
              ? handAdded[s.name]
              : null,
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

  @override
  Future<McpServerDefinition> saveServer(McpServerDraft draft) async {
    final id = draft.id;
    final previous = id == null ? null : await _repository.get(id);
    if (id != null && previous == null) {
      throw const McpServerNotFoundException();
    }
    final saved = draft.toDefinition(
      id: previous?.id ?? const Uuid().v4(),
      workspaceId: null,
      previous: previous,
      createdBy: null,
      // The owner's own server needs nobody's approval.
      hostApprovedBy: null,
      now: _clock(),
    );
    await _repository.save(saved);
    await _secrets.apply(saved: saved, previous: previous, draft: draft);
    await refresh();
    return saved;
  }

  @override
  Future<void> deleteServer(String id) async {
    if (!await _repository.delete(id)) {
      throw const McpServerNotFoundException();
    }
    await _secrets.deleteServer(null, id);
    await refresh();
  }
}
