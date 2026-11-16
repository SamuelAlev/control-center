import 'dart:async';

import 'package:cc_domain/features/mcp/domain/entities/mcp_server_definition.dart';
import 'package:cc_domain/features/mcp/domain/ports/workspace_mcp_server_control.dart';
import 'package:cc_domain/features/mcp/domain/repositories/mcp_server_definition_repository.dart';
import 'package:cc_domain/features/mcp/domain/services/mcp_tool_registry.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/mcp_server_draft.dart';
import 'package:cc_mcp_client/cc_mcp_client.dart';
import 'package:cc_server_core/src/mcp_servers/mcp_server_secrets.dart';
import 'package:uuid/uuid.dart';

/// Builds the client that connects one workspace's servers and publishes
/// their tools to [publishTools]. Injected so tests can watch what connects.
typedef WorkspaceMcpClientFactory =
    McpClientService Function(String workspaceId, McpToolSink publishTools);

/// The MCP servers each workspace configured, connected and bridged into
/// that workspace's layer of the tool registry, so every run in the
/// workspace gets their tools (the built-in harness directly, Claude Code
/// through the Control Center MCP endpoint).
///
/// Workspace admins write them; the server owner's approval
/// ([McpServerDefinition.hostApprovedBy], checked against the current owner
/// on every connect) is what lets a stdio server start at all, since it runs
/// on the host as the server's OS user, and what lets a remote server reach
/// a loopback or private address. Unapproved, a stdio server is never
/// started and a remote one connects only to public addresses. Any change
/// to how a server is launched or reached, by anyone but the owner, drops
/// the approval.
class WorkspaceMcpServers {
  /// Creates the service.
  WorkspaceMcpServers({
    required this._repository,
    required this._secrets,
    required this._registry,
    required String? serverOwnerUserId,
    required this._clientFactory,
    DateTime Function()? clock,
    String Function()? newId,
  }) : _owner = serverOwnerUserId,
       _clock = clock ?? DateTime.now,
       _newId = newId ?? const Uuid().v4;

  /// The `source` a workspace server's connection reports.
  static const String source = 'workspace';

  /// The longest connection error handed to a client.
  static const int maxErrorChars = 500;

  final WorkspaceMcpServerRepository _repository;
  final McpServerSecrets _secrets;
  final McpToolRegistry _registry;
  final String? _owner;
  final WorkspaceMcpClientFactory _clientFactory;
  final DateTime Function() _clock;
  final String Function() _newId;
  final Map<String, McpClientService> _clients = {};
  final Map<String, Future<void>> _syncs = {};
  bool _shutDown = false;

  /// Whether [userId] is the current server owner. No owner known: nobody.
  bool isServerOwner(String userId) =>
      _owner != null && _owner.isNotEmpty && userId == _owner;

  /// Connects every workspace in [workspaceIds]; one that fails is logged by
  /// the caller's sink and does not stop the others.
  Future<void> syncAll(
    Iterable<String> workspaceIds, {
    void Function(String workspaceId, Object error)? onError,
  }) async {
    for (final id in workspaceIds) {
      try {
        await sync(id);
      } on Object catch (e) {
        onError?.call(id, e);
      }
    }
  }

  /// Brings [workspaceId]'s connections in line with what is stored: a new
  /// or changed server (re)connects, a removed or unapproved one goes.
  /// Syncs of one workspace run one after another.
  Future<void> sync(String workspaceId) {
    final previous = _syncs[workspaceId] ?? Future<void>.value();
    final next = previous.catchError((_) {}).then((_) => _sync(workspaceId));
    _syncs[workspaceId] = next;
    return next;
  }

  Future<void> _sync(String workspaceId) async {
    if (_shutDown) {
      return;
    }
    final configs = <McpServerConfig>[];
    for (final definition in await _repository.list(workspaceId)) {
      final approved = definition.isHostApprovedBy(_owner);
      if (definition.runsOnHost && !approved) {
        continue;
      }
      configs.add(
        await _secrets.configFor(
          definition,
          source: source,
          publicOnly: definition.transport.isRemote && !approved,
        ),
      );
    }
    final existing = _clients[workspaceId];
    if (configs.isEmpty) {
      if (existing != null) {
        _clients.remove(workspaceId);
        await existing.shutdown();
      }
      return;
    }
    final client =
        existing ??
        (_clients[workspaceId] = _clientFactory(
          workspaceId,
          (tools) => _registry.setWorkspaceTools(workspaceId, tools),
        ));
    await client.start(configs);
  }

  /// The servers of [workspaceId] with their live state.
  Future<List<WorkspaceMcpServerEntry>> list(String workspaceId) async {
    final statuses = {
      for (final s
          in _clients[workspaceId]?.serverStatuses ??
              const <McpServerStatusSnapshot>[])
        s.name: s,
    };
    return [
      for (final definition in await _repository.list(workspaceId))
        _entry(definition, statuses[definition.name]),
    ];
  }

  WorkspaceMcpServerEntry _entry(
    McpServerDefinition definition,
    McpServerStatusSnapshot? status,
  ) {
    final approved = definition.isHostApprovedBy(_owner);
    final String lifecycle;
    if (!definition.enabled) {
      lifecycle = McpServerLifecycle.disabled.wire;
    } else if (definition.runsOnHost && !approved) {
      lifecycle = WorkspaceMcpServerEntry.awaitingApproval;
    } else {
      lifecycle = status?.lifecycle.wire ?? McpServerLifecycle.connecting.wire;
    }
    final error = status?.lastError;
    return WorkspaceMcpServerEntry(
      definition: definition,
      lifecycle: lifecycle,
      hostApproved: approved,
      toolCount: status?.toolCount ?? 0,
      lastError: error == null
          ? null
          : BridgedMcpTool.sanitizeExternalText(
              error,
              maxChars: maxErrorChars,
            ),
    );
  }

  Future<WorkspaceMcpServerEntry> _entryOf(String workspaceId, String id) async {
    final entries = await list(workspaceId);
    return entries.firstWhere(
      (e) => e.definition.id == id,
      orElse: () => throw const McpServerNotFoundException(),
    );
  }

  /// Adds or changes a server of [workspaceId] for [actorUserId] (a
  /// workspace admin, checked by the caller) and connects it.
  Future<WorkspaceMcpServerEntry> save({
    required String workspaceId,
    required McpServerDraft draft,
    required String actorUserId,
  }) async {
    final id = draft.id;
    final previous = id == null ? null : await _repository.get(workspaceId, id);
    if (id != null && previous == null) {
      throw const McpServerNotFoundException();
    }
    final String? approval;
    if (isServerOwner(actorUserId)) {
      // The owner saving it is the owner approving it as saved.
      approval = actorUserId;
    } else if (previous != null && !draft.changesLaunch(previous)) {
      approval = previous.hostApprovedBy;
    } else {
      approval = null;
    }
    final saved = draft.toDefinition(
      id: previous?.id ?? _newId(),
      workspaceId: workspaceId,
      previous: previous,
      createdBy: actorUserId,
      hostApprovedBy: approval,
      now: _clock(),
    );
    await _repository.save(saved);
    await _secrets.apply(saved: saved, previous: previous, draft: draft);
    await sync(workspaceId);
    return _entryOf(workspaceId, saved.id);
  }

  /// Removes server [id] of [workspaceId], its values and its connection.
  Future<void> delete({
    required String workspaceId,
    required String id,
  }) async {
    if (!await _repository.delete(workspaceId, id)) {
      throw const McpServerNotFoundException();
    }
    await _secrets.deleteServer(workspaceId, id);
    await sync(workspaceId);
  }

  /// Records [actorUserId]'s approval of server [id] as it stands. Only the
  /// current server owner can approve.
  Future<WorkspaceMcpServerEntry> approve({
    required String workspaceId,
    required String id,
    required String actorUserId,
  }) async {
    if (!isServerOwner(actorUserId)) {
      throw StateError('only the server owner approves host access');
    }
    final definition = await _repository.get(workspaceId, id);
    if (definition == null) {
      throw const McpServerNotFoundException();
    }
    await _repository.save(
      definition.copyWith(hostApprovedBy: actorUserId, updatedAt: _clock()),
    );
    await sync(workspaceId);
    return _entryOf(workspaceId, id);
  }

  /// Reconnects server [id] of [workspaceId], resetting its breaker.
  Future<void> reconnect({
    required String workspaceId,
    required String id,
  }) async {
    final definition = await _repository.get(workspaceId, id);
    if (definition == null) {
      throw const McpServerNotFoundException();
    }
    final client = _clients[workspaceId];
    if (client == null ||
        !client.serverStatuses.any((s) => s.name == definition.name)) {
      await sync(workspaceId);
      return;
    }
    await client.reconnect(definition.name, manual: true);
  }

  /// Drops everything kept for a deleted workspace: its connections, its
  /// tools and its stored values.
  Future<void> forgetWorkspace(String workspaceId) async {
    // A sync in flight could reconnect it after the shutdown below.
    await _syncs.remove(workspaceId)?.catchError((_) {});
    final client = _clients.remove(workspaceId);
    if (client != null) {
      await client.shutdown();
    }
    _registry.setWorkspaceTools(workspaceId, const []);
    await _secrets.deleteWorkspace(workspaceId);
  }

  /// Closes every connection (stdio children included).
  Future<void> shutdown() async {
    _shutDown = true;
    final clients = _clients.values.toList();
    _clients.clear();
    for (final client in clients) {
      await client.shutdown();
    }
  }
}
