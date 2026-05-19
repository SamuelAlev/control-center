import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_host/src/repo_rpc/repo_op.dart' show ServerAuthority;

/// The context handed to a [WatchQuery] handler. Identity ([userId],
/// [deviceId]) comes from the session's authenticated device credential —
/// never from client args.
class WatchQueryContext {
  /// Creates a [WatchQueryContext].
  const WatchQueryContext({
    required this.args,
    required this.workspaceId,
    required this.deviceId,
    required this.userId,
  });

  /// Client-supplied filter args (never the workspace).
  final Map<String, dynamic> args;

  /// Authoritative workspace id (null only for global queries).
  final String? workspaceId;

  /// The subscribing device (for auditing).
  final String deviceId;

  /// The authenticated user behind the subscription (user-scoped streams —
  /// preferences, own devices — key off this, never off client args).
  final String userId;
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
    this.minRole,
    this.serverAuthority = ServerAuthority.none,
  });

  /// Stable query name, e.g. `tickets.watchForWorkspace`.
  final String name;

  /// Whether the session's bound workspace is injected (and an unbound session
  /// rejected). False only for genuinely global streams (e.g. newsfeed).
  final bool workspaceScoped;

  /// Explicit minimum workspace role required to open this stream. Null
  /// (default) = [WorkspaceRole.guest] via [effectiveMinRole] — membership
  /// alone. Declare a higher floor on streams whose SNAPSHOTS expose
  /// governance state (the invite roster, the audit trail, policy and grant
  /// assignments): a watch is a read the read-op role gate never sees, so
  /// without this field the entire reactive lane was membership-only and
  /// streamed the workspace's audit trail to a guest.
  final WorkspaceRole? minRole;

  /// The role floor actually enforced by the subscription gate.
  WorkspaceRole get effectiveMinRole => minRole ?? WorkspaceRole.guest;

  /// The server-level authority this stream requires — the watch-lane twin of
  /// `RepoOp.serverAuthority`, for UNSCOPED queries whose snapshots expose
  /// install-wide state (`server_settings.watch`). [minRole] cannot express
  /// this: the role gate only runs for workspace-scoped queries.
  final ServerAuthority serverAuthority;

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

  /// The registered queries themselves, so a caller can rebuild a narrowed
  /// registry (the demo lockdown filters this lane the same way it filters
  /// ops).
  List<WatchQuery> get queries => _queries.values.toList();
}
