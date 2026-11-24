import 'dart:async';

import 'package:cc_domain/cc_domain.dart'
    show AuthException, ServerOwnerRequiredException;
import 'package:cc_domain/features/mcp/domain/entities/mcp_server_definition.dart';
import 'package:cc_domain/features/mcp/domain/ports/workspace_mcp_server_control.dart';
import 'package:cc_domain/features/mcp/domain/repositories/mcp_server_definition_repository.dart';
import 'package:cc_domain/features/mcp/domain/services/mcp_tool_registry.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/mcp_server_draft.dart';
import 'package:cc_mcp_client/cc_mcp_client.dart';
import 'package:cc_server_core/src/mcp_servers/mcp_server_authorizations.dart';
import 'package:cc_server_core/src/mcp_servers/mcp_server_secrets.dart';
import 'package:uuid/uuid.dart';

/// Builds the client that connects one audience's servers (a workspace's, or
/// with [userId] one member's own in it), publishes their tools to
/// [publishTools] and keeps their sign-ins in [tokenStore]. Injected so tests
/// can watch what connects.
typedef WorkspaceMcpClientFactory =
    McpClientService Function(
      String workspaceId,
      String? userId,
      McpToolSink publishTools,
      McpOAuthTokenStore tokenStore,
    );

/// The MCP servers configured in each workspace, connected and bridged into
/// the tool registry: the workspace's own into that workspace's layer, so
/// every run in the workspace gets their tools, and each member's own into
/// that member's layer, so only the runs that member starts there do (the
/// built-in harness directly, Claude Code through the Control Center MCP
/// endpoint).
///
/// Workspace admins write the workspace's servers and every member their
/// own. The server owner's approval ([McpServerDefinition.hostApprovedBy],
/// checked against the current owner on every connect) is what lets a stdio
/// server start at all, since it runs on the host as the server's OS user,
/// and what lets a remote server reach a loopback or private address.
/// Unapproved, a stdio server is never started and a remote one connects
/// only to public addresses. Any change to how a workspace server is
/// launched or reached, by anyone but the owner, drops the approval. A
/// member's own server is approved only by being the owner's: nobody else
/// can add a stdio one.
///
/// A server that asks for a browser sign-in gets one through
/// [beginAuthorization] and [completeAuthorization]; the sign-in is kept per
/// audience, so a member's never serves the workspace's connection.
class WorkspaceMcpServers {
  /// Creates the service.
  WorkspaceMcpServers({
    required this._repository,
    required this._secrets,
    required this._registry,
    required String? serverOwnerUserId,
    required this._clientFactory,
    McpServerAuthorizations? authorizations,
    DateTime Function()? clock,
    String Function()? newId,
  }) : _owner = serverOwnerUserId,
       _clock = clock ?? DateTime.now,
       _newId = newId ?? const Uuid().v4,
       authorizations = authorizations ?? McpServerAuthorizations(clock: clock);

  /// The `source` a workspace server's connection reports.
  static const String source = 'workspace';

  /// The `source` a member's own server's connection reports.
  static const String personalSource = 'personal';

  /// The longest connection error handed to a client.
  static const int maxErrorChars = 500;

  final WorkspaceMcpServerRepository _repository;
  final McpServerSecrets _secrets;
  final McpToolRegistry _registry;
  final String? _owner;
  final WorkspaceMcpClientFactory _clientFactory;
  final DateTime Function() _clock;
  final String Function() _newId;
  final Map<(String, String?), McpClientService> _clients = {};
  final Map<String, Future<void>> _syncs = {};

  /// The browser sign-ins in flight; the HTTP callback reports to it.
  final McpServerAuthorizations authorizations;
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
    final byUser = <String?, List<McpServerConfig>>{};
    for (final definition in await _repository.list(workspaceId)) {
      final approved = definition.isHostApprovedBy(_owner);
      if (definition.runsOnHost && !approved) {
        continue;
      }
      (byUser[definition.userId] ??= []).add(
        await _secrets.configFor(
          definition,
          source: definition.isPersonal ? personalSource : source,
          publicOnly: definition.transport.isRemote && !approved,
        ),
      );
    }
    final audiences = {
      for (final key in _clients.keys)
        if (key.$1 == workspaceId) key.$2,
      ...byUser.keys,
    };
    for (final userId in audiences) {
      final key = (workspaceId, userId);
      final configs = byUser[userId] ?? const <McpServerConfig>[];
      final existing = _clients[key];
      if (configs.isEmpty) {
        if (existing != null) {
          _clients.remove(key);
          await existing.shutdown();
        }
        continue;
      }
      final client =
          existing ??
          (_clients[key] = _clientFactory(
            workspaceId,
            userId,
            userId == null
                ? (tools) => _registry.setWorkspaceTools(workspaceId, tools)
                : (tools) =>
                      _registry.setPersonalTools(workspaceId, userId, tools),
            _secrets.tokenStore(workspaceId, userId),
          ));
      await client.start(configs);
    }
  }

  /// The servers of [scope] in [workspaceId] with their live state: the
  /// workspace's, or [actorUserId]'s own.
  Future<List<WorkspaceMcpServerEntry>> list(
    String workspaceId,
    McpServerScope scope, {
    required String actorUserId,
  }) async {
    final userId = _userOf(scope, actorUserId);
    final statuses = {
      for (final s
          in _clients[(workspaceId, userId)]?.serverStatuses ??
              const <McpServerStatusSnapshot>[])
        s.name: s,
    };
    return [
      for (final definition in await _repository.list(workspaceId))
        if (definition.userId == userId)
          _entry(definition, statuses[definition.name]),
    ];
  }

  static String? _userOf(McpServerScope scope, String actorUserId) =>
      switch (scope) {
        McpServerScope.workspace => null,
        McpServerScope.personal => actorUserId,
      };

  /// Server [id] of [workspaceId] when it is in [scope] for [actorUserId];
  /// another member's own server is as absent as an unknown one.
  Future<McpServerDefinition> _owned(
    String workspaceId,
    McpServerScope scope,
    String actorUserId,
    String id,
  ) async {
    final definition = await _repository.get(workspaceId, id);
    if (definition == null ||
        definition.userId != _userOf(scope, actorUserId)) {
      throw const McpServerNotFoundException();
    }
    return definition;
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
          : BridgedMcpTool.sanitizeExternalText(error, maxChars: maxErrorChars),
    );
  }

  Future<WorkspaceMcpServerEntry> _entryOf(
    McpServerDefinition definition,
  ) async {
    final status = _clients[(definition.workspaceId, definition.userId)]
        ?.serverStatuses
        .where((s) => s.name == definition.name)
        .firstOrNull;
    return _entry(definition, status);
  }

  /// Adds or changes a server of [scope] in [workspaceId] for [actorUserId]
  /// (for the workspace's, an admin, checked by the caller) and connects it.
  ///
  /// A member's own stdio server would run on the host as the server's OS
  /// user with nobody to approve it, so only the server owner adds one
  /// ([ServerOwnerRequiredException]).
  Future<WorkspaceMcpServerEntry> save({
    required String workspaceId,
    required McpServerScope scope,
    required McpServerDraft draft,
    required String actorUserId,
  }) async {
    final id = draft.id;
    final previous = id == null
        ? null
        : await _owned(workspaceId, scope, actorUserId, id);
    final owner = isServerOwner(actorUserId);
    if (scope == McpServerScope.personal &&
        !owner &&
        draft.transport == McpServerTransport.stdio) {
      throw const ServerOwnerRequiredException(
        'Only the server owner can add a server that runs a command on the '
        'host.',
      );
    }
    final String? approval;
    if (owner) {
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
      userId: _userOf(scope, actorUserId),
      previous: previous,
      createdBy: actorUserId,
      hostApprovedBy: approval,
      now: _clock(),
    );
    await _repository.save(saved);
    await _secrets.apply(saved: saved, previous: previous, draft: draft);
    if (previous != null && previous.url != saved.url) {
      await _forgetSignIn(previous);
    }
    await sync(workspaceId);
    return _entryOf(saved);
  }

  /// Removes server [id] of [scope] in [workspaceId]: its values, its
  /// sign-in and its connection.
  Future<void> delete({
    required String workspaceId,
    required McpServerScope scope,
    required String id,
    required String actorUserId,
  }) async {
    final definition = await _owned(workspaceId, scope, actorUserId, id);
    await _repository.delete(workspaceId, id);
    await _secrets.deleteServer(definition);
    await _forgetSignIn(definition);
    await sync(workspaceId);
  }

  /// Drops [definition]'s sign-in and the attempts on it, unless another
  /// server of the same audience is reached at the same origin and shares it.
  Future<void> _forgetSignIn(McpServerDefinition definition) async {
    authorizations.forgetServer(definition.workspaceId, definition.id);
    final url = definition.url;
    if (url == null) {
      return;
    }
    final key = McpOAuthProvider.oauthServerKey(url);
    for (final other in await _repository.list(definition.workspaceId)) {
      final otherUrl = other.url;
      if (other.id != definition.id &&
          other.userId == definition.userId &&
          otherUrl != null &&
          McpOAuthProvider.oauthServerKey(otherUrl) == key) {
        return;
      }
    }
    await _secrets
        .tokenStore(definition.workspaceId, definition.userId)
        .delete(key);
  }

  /// Records [actorUserId]'s approval of the workspace's server [id] as it
  /// stands. Only the current server owner can approve.
  Future<WorkspaceMcpServerEntry> approve({
    required String workspaceId,
    required String id,
    required String actorUserId,
  }) async {
    if (!isServerOwner(actorUserId)) {
      throw StateError('only the server owner approves host access');
    }
    final definition = await _owned(
      workspaceId,
      McpServerScope.workspace,
      actorUserId,
      id,
    );
    final approved = definition.copyWith(
      hostApprovedBy: actorUserId,
      updatedAt: _clock(),
    );
    await _repository.save(approved);
    await sync(workspaceId);
    return _entryOf(approved);
  }

  /// Reconnects server [id] of [scope] in [workspaceId], resetting its
  /// breaker.
  Future<void> reconnect({
    required String workspaceId,
    required McpServerScope scope,
    required String id,
    required String actorUserId,
  }) async {
    final definition = await _owned(workspaceId, scope, actorUserId, id);
    final client = _clients[(workspaceId, definition.userId)];
    if (client == null ||
        !client.serverStatuses.any((s) => s.name == definition.name)) {
      await sync(workspaceId);
      return;
    }
    await client.reconnect(definition.name, manual: true);
  }

  /// Starts a browser sign-in to server [id] of [scope] for [actorUserId].
  /// [origin] is this server's advertised HTTP origin, where the browser
  /// comes back. Throws [AuthException] when the server cannot be signed in
  /// to.
  Future<McpServerAuthorization> beginAuthorization({
    required String workspaceId,
    required McpServerScope scope,
    required String id,
    required String actorUserId,
    required String origin,
  }) async {
    final definition = await _owned(workspaceId, scope, actorUserId, id);
    final url = definition.url;
    final provider = _clients[(workspaceId, definition.userId)]
        ?.oauthProviderFor(definition.name);
    if (url == null || !definition.enabled || provider == null) {
      throw const AuthException('This server takes no browser sign-in.');
    }
    final attempt = await authorizations.begin(
      workspaceId: workspaceId,
      userId: actorUserId,
      scope: scope,
      serverId: id,
      serverUrl: url,
      provider: provider,
      origin: origin,
      httpsOnly: !definition.isHostApprovedBy(_owner),
    );
    return attempt.view;
  }

  /// Finishes [attemptId] with the confirmation [code] the browser showed,
  /// for the person who began it: exchanges the provider's code, stores the
  /// sign-in for the server's audience and reconnects it.
  ///
  /// A wrong code is not an exception: the attempt comes back
  /// [McpServerAuthorizationStatus.wrongCode], or failed once the codes ran
  /// out. An unknown attempt, someone else's, or one of another [scope] is
  /// [McpServerNotFoundException].
  Future<McpServerAuthorization> completeAuthorization({
    required String workspaceId,
    required McpServerScope scope,
    required String attemptId,
    required String code,
    required String actorUserId,
  }) async {
    final attempt = authorizations.lookup(
      attemptId: attemptId,
      workspaceId: workspaceId,
      userId: actorUserId,
    );
    if (attempt == null || attempt.scope != scope) {
      throw const McpServerNotFoundException();
    }
    if (attempt.status == McpServerAuthorizationStatus.done ||
        attempt.status == McpServerAuthorizationStatus.failed ||
        !_completing.add(attemptId)) {
      return attempt.view;
    }
    try {
      if (!authorizations.confirm(attempt, code)) {
        return attempt.view;
      }
      // The server may have been removed or pointed elsewhere meanwhile.
      final definition = await _owned(
        workspaceId,
        scope,
        actorUserId,
        attempt.serverId,
      );
      if (definition.url != attempt.serverUrl) {
        attempt.status = McpServerAuthorizationStatus.failed;
        return attempt.view;
      }
      try {
        await attempt.provider.complete(attempt.pending, attempt.providerCode);
      } on OAuthException {
        attempt.status = McpServerAuthorizationStatus.failed;
        return attempt.view;
      }
      attempt.status = McpServerAuthorizationStatus.done;
      await _clients[(workspaceId, definition.userId)]?.reconnect(
        definition.name,
        manual: true,
      );
      return attempt.view;
    } finally {
      _completing.remove(attemptId);
    }
  }

  final Set<String> _completing = {};

  /// Drops everything kept for a deleted workspace: its connections, its
  /// tools and its stored values.
  Future<void> forgetWorkspace(String workspaceId) async {
    // A sync in flight could reconnect it after the shutdown below.
    await _syncs.remove(workspaceId)?.catchError((_) {});
    for (final key
        in _clients.keys.where((k) => k.$1 == workspaceId).toList()) {
      await _clients.remove(key)?.shutdown();
    }
    _registry
      ..setWorkspaceTools(workspaceId, const [])
      ..dropPersonalTools(workspaceId);
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
