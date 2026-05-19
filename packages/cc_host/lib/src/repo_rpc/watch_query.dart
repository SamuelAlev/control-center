/// The context handed to a [WatchQuery] handler. [workspaceId] is authoritative
/// (from the session binding) — never from client args.
class WatchQueryContext {
  /// Creates a [WatchQueryContext].
  const WatchQueryContext({
    required this.args,
    required this.workspaceId,
    required this.deviceId,
  });

  /// Client-supplied filter args (never the workspace).
  final Map<String, dynamic> args;

  /// Authoritative workspace id (null only for global queries).
  final String? workspaceId;

  /// The subscribing device (for auditing).
  final String deviceId;
}

/// Produces the snapshot stream for one subscription. Each emission is a full
/// snapshot map (e.g. `{tickets: [...]}`) pushed to the client as `sub/snapshot`.
typedef WatchQueryHandler =
    Stream<Map<String, dynamic>> Function(WatchQueryContext ctx);

/// A declared, named reactive query — the read-only counterpart to `RepoOp`.
///
/// Backed by a repository `.watch*()` Drift stream on the server; the
/// `SubscriptionManager` proxies its emissions over the wire. Workspace-scoped
/// by default (the manager injects the session's workspace and rejects an
/// unbound session), matching the repo-RPC chokepoint.
class WatchQuery {
  /// Creates a [WatchQuery].
  const WatchQuery({
    required this.name,
    required this.handler,
    this.workspaceScoped = true,
  });

  /// Stable query name, e.g. `tickets.watchForWorkspace`.
  final String name;

  /// Whether the session's bound workspace is injected (and an unbound session
  /// rejected). False only for genuinely global streams (e.g. newsfeed).
  final bool workspaceScoped;

  /// Opens the snapshot stream.
  final WatchQueryHandler handler;
}

/// A closed registry of [WatchQuery]s. A name absent here is unreachable
/// (default-deny), exactly like `RepoOpRegistry`.
class WatchQueryRegistry {
  /// Creates a registry from [queries].
  WatchQueryRegistry(List<WatchQuery> queries)
    : _queries = {for (final q in queries) q.name: q};

  final Map<String, WatchQuery> _queries;

  /// Looks up a query by name, or null (→ default-deny).
  WatchQuery? lookup(String name) => _queries[name];

  /// The registered query names (for discovery).
  List<String> get names => _queries.keys.toList();
}
