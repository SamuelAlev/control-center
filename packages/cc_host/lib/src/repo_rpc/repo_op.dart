import 'package:cc_domain/cc_domain.dart';
import 'package:cc_host/src/policy/session_capability.dart';

/// The authoritative context handed to a [RepoOp] handler.
///
/// [workspaceId] is injected by the dispatcher from the session's binding —
/// never taken from client args — so a handler physically cannot act outside
/// the session's workspace. [args] has already had `workspace_id` overwritten
/// (workspace-scoped ops) or stripped (global ops).
class RepoOpContext {
  /// Creates a [RepoOpContext].
  const RepoOpContext({
    required this.args,
    required this.workspaceId,
    required this.deviceId,
  });

  /// Validated, workspace-injected arguments.
  final Map<String, dynamic> args;

  /// The authoritative workspace id (null only for global ops).
  final String? workspaceId;

  /// The paired device that issued the call (for auditing).
  final String deviceId;
}

/// A handler that executes one declared repository operation and returns its
/// typed `data` payload (serialized with the cc_domain DTOs).
typedef RepoOpHandler =
    Future<Map<String, dynamic>> Function(RepoOpContext ctx);

/// A single declared, versioned repository operation.
///
/// This is the closed allow-list entry the repo-RPC envelope routes to — there
/// is NO reflection onto repositories. Adding a remotely-reachable operation is
/// a deliberate act: declare a [RepoOp] with its [kind], required args, and
/// workspace scoping.
class RepoOp {
  /// Creates a [RepoOp].
  const RepoOp({
    required this.name,
    required this.kind,
    required this.handler,
    this.version = 1,
    this.requiredArgs = const [],
    this.workspaceScoped = true,
    this.requiredCapability,
  });

  /// Stable operation name, e.g. `tickets.assign`.
  final String name;

  /// Read / mutate / destructive — gates approval + rate limiting.
  final RepoOpKind kind;

  /// Op-level version, independent of the protocol version.
  final int version;

  /// Argument keys that must be present and non-null (lightweight validation;
  /// full JSON-schema validation via `SchemaValidatorPort` is a follow-up).
  final List<String> requiredArgs;

  /// When true, the dispatcher injects the session's bound `workspace_id` and
  /// rejects an unbound session. Set false ONLY for genuinely global ops
  /// (e.g. newsfeed) — the absence of scoping must be a declared decision.
  final bool workspaceScoped;

  /// When non-null, the calling session's [SessionCapability] must equal this
  /// or the dispatcher denies the op ([RpcErrorCodes.unauthorized]) before the
  /// handler runs. Null (default) = any authenticated session may call it. Set
  /// to [SessionCapability.fullClient] for privileged ops (e.g. `pairing.*`)
  /// that a companion phone must never reach.
  final SessionCapability? requiredCapability;

  /// Executes the operation.
  final RepoOpHandler handler;
}

/// A closed registry of [RepoOp]s. A `(name)` absent here is unreachable —
/// default-deny. Mirrors `McpToolRegistry.lookup`, generalized to repo-RPC.
class RepoOpRegistry {
  /// Creates a registry from [ops]. [catalogVersion] is advertised in the
  /// capability handshake so clients can detect a changed surface.
  RepoOpRegistry(List<RepoOp> ops, {this.catalogVersion = 1})
    : _ops = {for (final o in ops) o.name: o};

  final Map<String, RepoOp> _ops;

  /// The op-catalog version (advertised via `HostCapabilities`).
  final int catalogVersion;

  /// Looks up an op by name, or null if not registered (→ default-deny).
  RepoOp? lookup(String name) => _ops[name];

  /// Describes the catalog for `op/list` discovery + version negotiation.
  List<Map<String, dynamic>> describe() => _ops.values
      .map(
        (o) => {
          'op': o.name,
          'version': o.version,
          'kind': o.kind.name,
          'required_args': o.requiredArgs,
          'workspace_scoped': o.workspaceScoped,
        },
      )
      .toList();
}
