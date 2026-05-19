import 'dart:async';
import 'dart:convert';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_host/src/log/cc_host_log.dart';
import 'package:cc_host/src/policy/remote_tool_policy.dart';
import 'package:cc_host/src/policy/session_capability.dart';
import 'package:cc_host/src/repo_rpc/repo_op.dart';
import 'package:cc_host/src/repo_rpc/repo_op_dispatcher.dart';
import 'package:cc_host/src/repo_rpc/subscription_manager.dart';
import 'package:cc_host/src/repo_rpc/watch_query.dart';
import 'package:cc_host/src/session/remote_rate_limiter.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// A minimal workspace summary the session resolves for `session/list_workspaces`.
typedef RemoteWorkspaceSummary = ({String id, String name});

/// Resolves the workspaces [userId] may see (membership-scoped: a user's
/// picker lists only workspaces they belong to).
typedef RemoteWorkspaceResolver =
    Future<List<RemoteWorkspaceSummary>> Function(String userId);

/// One live RPC session for a single connected phone.
///
/// Pumps inbound JSON-RPC frames from [channel] through the **shared**
/// [dispatcher] (the same one the MCP HTTP server uses) and sends each
/// response back. The server is stateless: every workspace-scoped request
/// carries its own `workspace_id` in args and the MCP tools / repo ops
/// validate ownership themselves — there is no per-session workspace binding,
/// so multiple clients on one server never share a "current workspace".
/// Workspace discovery (`session/list_workspaces`) is handled locally; it never
/// reaches the tool registry.
class RemoteRpcSession {
  /// Creates a [RemoteRpcSession].
  RemoteRpcSession({
    required this.deviceId,
    required this.userId,
    required this.channel,
    required this.dispatcher,
    required this.workspaceResolver,
    required this.capability,
    this.repoOps,
    this.watchQueries,
    this.workspaceExists,
    this.resolveRole,
    this.remoteAddress,
    RemoteRateLimiter? rateLimiter,
    RemoteRateLimiter? requestLimiter,
    this.maxConcurrentRequests = 16,
  }) : rateLimiter = rateLimiter ?? RemoteRateLimiter(),
       requestLimiter =
           requestLimiter ??
           RemoteRateLimiter(
             maxCallsPerWindow: 900,
             maxMutationsPerWindow: 900,
           );

  /// Flood guard for EVERY inbound method, not just `tools/call`.
  ///
  /// `repo/call`, `initialize`, `tools/list`, `op/list` and
  /// `session/list_workspaces` were previously unthrottled, so an
  /// authenticated client could drive the dispatcher (and the database, via
  /// `session/list_workspaces`) at line rate. Deliberately generous — a real
  /// desktop session bursts dozens of ops when a view opens — but bounded.
  final RemoteRateLimiter requestLimiter;

  /// Cap on requests being handled CONCURRENTLY on this session.
  ///
  /// The inbound listener ignores each handler's future, so without this a
  /// client can have unbounded work in flight (each holding a DB query, an
  /// isolate hop, and its own memory) no matter what the per-minute budget
  /// says.
  final int maxConcurrentRequests;

  int _inFlight = 0;

  /// The paired-device id this session serves.
  final String deviceId;

  /// The authenticated user behind the device credential — the principal
  /// every op on this session is attributed to and authorized as.
  final String userId;

  /// The privilege tier of this session, derived from the paired device's
  /// platform. Gates `repo/call` ops that declare a `requiredCapability` — a
  /// [SessionCapability.phone] cannot reach `fullClient`-only ops.
  final SessionCapability capability;

  /// The framed-JSON transport to the phone.
  final RemoteRpcChannelPort channel;

  /// The shared dispatcher (one instance app-wide), behind the transport-
  /// agnostic [RpcDispatcher] seam.
  final RpcDispatcher dispatcher;

  /// Resolves the workspaces the phone can switch between.
  final RemoteWorkspaceResolver workspaceResolver;

  /// Optional repo-RPC dispatcher. When provided, the session serves the
  /// `repo/call` + `op/list` surface (the parity gate for full clients); each
  /// scoped op carries its own `workspace_id` in args. Null for the
  /// curated-tools-only thin client.
  final RepoOpDispatcher? repoOps;

  /// Optional reactive watch-query registry. When provided, the session serves
  /// the `sub/subscribe` + `sub/unsubscribe` surface, proxying repository
  /// `.watch()` streams. Null for the curated-tools-only thin client.
  final WatchQueryRegistry? watchQueries;

  /// Registry existence gate forwarded to the [SubscriptionManager]: a
  /// workspace-scoped subscription naming an unregistered workspace is
  /// refused before its handler opens (and thereby CREATES) that workspace's
  /// database file.
  final WorkspaceExistsChecker? workspaceExists;

  /// Membership gate: resolves the session user's role in a workspace (null =
  /// not a member). Consulted by `tools/call` (a tool argument naming a
  /// `workspace_id` the user does not belong to is refused here — the MCP
  /// tools themselves validate the argument's PRESENCE but have no notion of
  /// the calling human) and forwarded to the [SubscriptionManager], whose
  /// workspace-scoped queries otherwise stream any named workspace to any
  /// authenticated session. Null (bare test sessions) skips both gates;
  /// production wiring always supplies it.
  final WorkspaceRoleResolver? resolveRole;

  /// The server's view of the client IP for this session (IP literal, never a
  /// hostname): loopback for local sockets, the relay/tunnel endpoint for
  /// relayed sessions and null when the transport exposes no peer address
  /// (the in-process host). Threaded into `repo/call` audit records only.
  final String? remoteAddress;

  /// Per-session rate limiter for `tools/call` (flood / abuse guard).
  final RemoteRateLimiter rateLimiter;

  StreamSubscription<Map<String, dynamic>>? _sub;
  SubscriptionManager? _subscriptions;

  /// Lazily-built subscription manager (only when [watchQueries] is wired).
  SubscriptionManager? get _subs {
    final queries = watchQueries;
    if (queries == null) {
      return null;
    }
    return _subscriptions ??= SubscriptionManager(
      registry: queries,
      send: (frame) => unawaited(_send(frame)),
      deviceId: deviceId,
      userId: userId,
      workspaceExists: workspaceExists,
      resolveRole: resolveRole,
      // Watch-stream failures get the same domain-exception → RPC-code
      // classification as repo/call errors, so an unrecoverable rejection
      // (workspace mismatch, not found) reaches the client's retry policy as
      // itself rather than as a retryable generic internal error.
      mapException: repoOps?.mapException,
    );
  }

  /// Begins consuming inbound frames. Idempotent.
  Future<void> start() async {
    await _sub?.cancel();
    _sub = channel.incoming.listen(_onFrame);
  }

  Future<void> _onFrame(Map<String, dynamic> frame) async {
    final JsonRpcRequest request;
    try {
      request = JsonRpcRequest.fromJson(frame);
    } catch (e) {
      CcHostLog.warning('Dropping non-JSON-RPC frame: $e');
      return;
    }

    // Bound in-flight work and the overall request rate BEFORE dispatching.
    // Notifications (no id) are exempt from the concurrency cap's response
    // path but still consume budget.
    if (_inFlight >= maxConcurrentRequests) {
      CcHostLog.warning(
        'Session $deviceId: $_inFlight requests already in flight — '
        'refusing ${request.method}',
      );
      if (request.id != null) {
        await _send(
          _error(
            request.id,
            RpcErrorCodes.rateLimited,
            'Too many concurrent requests — retry shortly',
          ),
        );
      }
      return;
    }
    if (!requestLimiter.tryAcquire(mutating: false)) {
      CcHostLog.warning(
        'Rate-limiting ${request.method} for $deviceId (request budget)',
      );
      if (request.id != null) {
        await _send(
          _error(
            request.id,
            RpcErrorCodes.rateLimited,
            'Rate limit exceeded — slow down',
          ),
        );
      }
      return;
    }

    _inFlight++;
    Map<String, dynamic> response;
    try {
      switch (request.method) {
        case 'initialize':
          response = await _initialize(request);
        case 'session/list_workspaces':
          response = await _listWorkspaces(request);
        case 'tools/list':
          response = await _toolsList(request);
        case 'tools/call':
          response = await _toolsCall(request);
        case RpcMethods.repoCall:
          response = await _repoCall(request);
        case RpcMethods.opList:
          response = _opList(request);
        case RpcMethods.subscribe:
          response = _subscribe(request);
        case RpcMethods.unsubscribe:
          response = _unsubscribe(request);
        default:
          // initialize, notifications/*, etc.
          response = await dispatcher.handleRequest(request);
      }
    } catch (e, st) {
      // Never serialize raw exception text to the untrusted phone — Dart
      // exceptions routinely embed absolute worktree/repo paths, SQL fragments,
      // and auth/network detail, which is an internal-error oracle. Log the full
      // detail locally; return a generic message over the wire.
      CcHostLog.error('Session $deviceId handler error: $e', e, st);
      response = _error(request.id, -32603, 'Internal error');
    } finally {
      _inFlight--;
    }

    // Only requests (those carrying an id) get a response; notifications don't.
    if (request.id != null) {
      await _send(response);
    }
  }

  /// Handles `tools/list` for a remote phone: returns only the tools the
  /// [RemoteToolPolicy] allow-list permits. The phone is a lower-privilege
  /// principal than a local agent and must not even *see* the full surface.
  Future<Map<String, dynamic>> _toolsList(JsonRpcRequest request) async {
    final full = await dispatcher.handleRequest(request);
    final result = full['result'];
    if (result is! Map<String, dynamic>) {
      return full;
    }
    final tools = result['tools'];
    if (tools is! List) {
      return full;
    }
    final filtered = tools.where((t) {
      final name = t is Map ? t['name'] : null;
      return name is String && RemoteToolPolicy.isAllowed(name);
    }).toList();
    return _result(request.id, {'tools': filtered});
  }

  Future<Map<String, dynamic>> _toolsCall(JsonRpcRequest request) async {
    final toolName = request.params['name'];

    // Default-deny allow-list. A phone may only invoke the curated read/observe
    // + intentional-write surface — never the LLM-spending, process-driving,
    // GitHub-posting, or org-mutating tools the local MCP surface also exposes.
    if (toolName is! String || !RemoteToolPolicy.isAllowed(toolName)) {
      CcHostLog.warning(
        'Denying remote tools/call "$toolName" for $deviceId '
        '(not on the remote allow-list)',
      );
      return _error(
        request.id,
        -32601,
        'Tool not available over remote control',
      );
    }

    // Per-session rate limit (abuse / flood guard on the untrusted channel).
    final mutating = RemoteToolPolicy.isMutating(toolName);
    if (!rateLimiter.tryAcquire(mutating: mutating)) {
      CcHostLog.warning(
        'Rate-limiting remote tools/call "$toolName" for $deviceId',
      );
      return _error(request.id, -32005, 'Rate limit exceeded — slow down');
    }

    // Stateless: the workspace_id the client put in `arguments` is forwarded
    // unchanged — there is no session binding. The MCP tools require + validate
    // workspace_id themselves (per AGENTS.md), but they have NO notion of the
    // calling human, so membership is enforced HERE: a tool call naming a
    // workspace the session user does not belong to is refused before it
    // reaches the dispatcher (this is what stops a paired non-member from
    // reading channels or posting messages into another workspace).
    final roleResolver = resolveRole;
    if (roleResolver != null) {
      final arguments = request.params['arguments'];
      final ws = arguments is Map ? arguments['workspace_id'] : null;
      if (ws is String &&
          ws.isNotEmpty &&
          await roleResolver(ws, userId) == null) {
        CcHostLog.warning(
          'Denying remote tools/call "$toolName" for $userId@$deviceId — '
          'not a member of workspace $ws',
        );
        return _error(
          request.id,
          RpcErrorCodes.unauthorized,
          'Not a member of this workspace',
        );
      }
    }
    return dispatcher.handleRequest(request);
  }

  /// Handles `initialize` by delegating to the dispatcher, then advertising
  /// the server's build identity (version + git sha, the stale-binary /
  /// compatibility signal — the client warns on an older server but never
  /// hard-blocks on it; only the protocol range may refuse) and the repo-RPC
  /// catalog + subscription support in `capabilities` so a full client can
  /// negotiate the parity surface (version handshake). The thin client
  /// (no [repoOps]) still sees the build identity.
  Future<Map<String, dynamic>> _initialize(JsonRpcRequest request) async {
    // Protocol negotiation, actually performed. The client sends the range it
    // speaks; if it does not intersect ours, say so with the supported range
    // instead of proceeding on a version neither side agreed to.
    final proto = request.params['protocol'];
    int? agreed;
    if (proto is Map) {
      final clientMin = (proto['min'] as num?)?.toInt() ?? RepoRpcProtocol.min;
      final clientMax = (proto['max'] as num?)?.toInt() ?? RepoRpcProtocol.max;
      final high = clientMax < RepoRpcProtocol.max
          ? clientMax
          : RepoRpcProtocol.max;
      final low = clientMin > RepoRpcProtocol.min
          ? clientMin
          : RepoRpcProtocol.min;
      if (high < low) {
        CcHostLog.warning(
          'Session $deviceId: no common repo-RPC protocol version '
          '(client $clientMin..$clientMax, server '
          '${RepoRpcProtocol.min}..${RepoRpcProtocol.max})',
        );
        return _error(
          request.id,
          RpcErrorCodes.opVersionUnsupported,
          'No common protocol version',
          data: {
            'supported_versions': [
              for (var v = RepoRpcProtocol.min; v <= RepoRpcProtocol.max; v++) v,
            ],
          },
        );
      }
      agreed = high;
    }
    final base = await dispatcher.handleRequest(request);
    final result = base['result'];
    if (result is! Map<String, dynamic>) {
      return base;
    }
    // Copy into a fresh growable Map<String, dynamic> — NOT `.cast()`. A
    // `Map.cast()` view casts written values back to the *source* value type,
    // and the dispatcher's capabilities literal (`{'tools': {'listChanged':
    // false}}`) infers as `Map<String, Map<String, bool>>`. Writing the
    // `repoRpc` map (`{'catalogVersion': <int>}`) into a cast view would do
    // `value as Map<String, bool>` and throw at runtime.
    final rawCaps = result['capabilities'];
    final caps = rawCaps is Map
        ? Map<String, dynamic>.from(rawCaps)
        : <String, dynamic>{};
    caps['serverVersion'] = BuildInfo.buildVersion;
    caps['protocol'] = {
      'min': RepoRpcProtocol.min,
      'max': RepoRpcProtocol.max,
      'agreed': ?agreed,
    };
    caps['gitSha'] = BuildInfo.buildGitSha;
    final ops = repoOps;
    if (ops != null) {
      caps['repoRpc'] = {'catalogVersion': ops.registry.catalogVersion};
      // Reactive subscriptions: available (snapshot only) when a watch-query
      // registry is wired into this session, so a client can negotiate `sub/*`
      // instead of falling back to polling `repo/call` reads. Delta encoding is
      // not implemented — each emission is a full snapshot.
      caps['subscriptions'] = {
        'snapshot': watchQueries != null,
        // Delta mode (PRD 16 §6) rides the `sync.watch` query; a host without
        // it (bare test catalogs) honestly advertises snapshot-only.
        'delta': watchQueries?.lookup('sync.watch') != null,
      };
    }
    result['capabilities'] = caps;
    return base;
  }

  /// Handles `repo/call` — the declared repository-operation surface. A
  /// workspace-scoped op carries its target `workspace_id` in args (stateless;
  /// no session binding). Unavailable (method-not-found) when no [repoOps] wired.
  Future<Map<String, dynamic>> _repoCall(JsonRpcRequest request) async {
    final ops = repoOps;
    if (ops == null) {
      return _error(request.id, -32601, 'repo/call not available');
    }
    return ops.call(
      id: request.id,
      params: request.params,
      deviceId: deviceId,
      userId: userId,
      sessionCapability: capability,
      remoteAddress: remoteAddress,
    );
  }

  /// Handles `op/list` — the repo-op catalog for discovery + version checks.
  Map<String, dynamic> _opList(JsonRpcRequest request) {
    final ops = repoOps;
    if (ops == null) {
      return _error(request.id, -32601, 'op/list not available');
    }
    return ops.list(request.id);
  }

  /// Handles `sub/subscribe` — opens a reactive subscription scoped to the
  /// `workspace_id` carried in the subscribe args (stateless; no session binding).
  Map<String, dynamic> _subscribe(JsonRpcRequest request) {
    final subs = _subs;
    if (subs == null) {
      return _error(request.id, -32601, 'sub/subscribe not available');
    }
    return subs.subscribe(id: request.id, params: request.params);
  }

  /// Handles `sub/unsubscribe`.
  Map<String, dynamic> _unsubscribe(JsonRpcRequest request) {
    final subs = _subs;
    if (subs == null) {
      return _error(request.id, -32601, 'sub/unsubscribe not available');
    }
    return subs.unsubscribe(id: request.id, params: request.params);
  }

  Future<Map<String, dynamic>> _listWorkspaces(JsonRpcRequest request) async {
    final workspaces = await workspaceResolver(userId);
    final list = workspaces.map((w) => {'id': w.id, 'name': w.name}).toList();
    return _result(request.id, {'workspaces': list, 'count': list.length});
  }

  Future<void> _send(Map<String, dynamic> frame) async {
    if (!channel.isOpen) {
      return;
    }
    try {
      await channel.send(frame);
    } catch (e) {
      CcHostLog.warning('Failed to send to $deviceId: $e');
    }
  }

  Map<String, dynamic> _result(dynamic id, Map<String, dynamic> result) => {
    'jsonrpc': '2.0',
    'id': id,
    'result': result,
  };

  Map<String, dynamic> _error(
    dynamic id,
    int code,
    String message, {
    Map<String, dynamic>? data,
  }) => {
    'jsonrpc': '2.0',
    'id': id,
    'error': {
      'code': code,
      'message': message,
      'data': ?data,
    },
  };

  /// Tears down every live subscription this session holds into
  /// [workspaceId]. Called when the user's membership is revoked: the
  /// `repo/call` role gate resolves per call (revocation is live there), but
  /// an attached watch stream would otherwise keep pushing the workspace's
  /// data until the client unsubscribed or the socket died.
  void dropWorkspaceSubscriptions(String workspaceId) {
    _subscriptions?.dropWorkspace(workspaceId);
  }

  /// Tears down the session and closes the channel.
  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
    await _subscriptions?.dispose();
    await channel.close();
  }
}

/// Encodes a [Map] frame to a JSON string for transports that need it.
String encodeFrame(Map<String, dynamic> frame) => jsonEncode(frame);
