import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/core/domain/value_objects/repo_grant_level.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_harness/tools.dart';
import 'package:cc_host/src/policy/session_capability.dart';

/// The authoritative context handed to a [RepoOp] handler.
///
/// The server is stateless: every workspace-scoped call carries its own
/// `workspace_id` in [args], validated by the dispatcher before the handler
/// runs. Identity ([userId], [deviceId]) comes from the session's
/// authenticated device credential — never from client args — so a handler
/// can attribute and authorize by human without trusting the payload.
class RepoOpContext {
  /// Creates a [RepoOpContext].
  const RepoOpContext({
    required this.args,
    required this.workspaceId,
    required this.deviceId,
    required this.userId,
    this.role,
    this.remoteAddress,
  });

  /// Validated, workspace-injected arguments.
  final Map<String, dynamic> args;

  /// The authoritative workspace id (null only for global ops).
  final String? workspaceId;

  /// The paired device that issued the call (for auditing).
  final String deviceId;

  /// The authenticated user behind the device — the acting principal of
  /// every repo-RPC call. Handlers use this for authorship and attribution.
  final String userId;

  /// The caller's resolved role in [workspaceId] (null for global ops, where
  /// no membership applies).
  final WorkspaceRole? role;

  /// The server's view of the client IP (IP literal, never a hostname):
  /// loopback for local sockets, the relay/tunnel endpoint for relayed
  /// sessions and null when the transport exposes no peer address (the
  /// in-process host). Feeds the audit trail's `ip` column.
  final String? remoteAddress;

  /// The acting principal (repo-RPC callers are always humans; agents act
  /// through the MCP surface).
  Principal get principal => UserPrincipal(userId);
}

/// A handler that executes one declared repository operation and returns its
/// typed `data` payload (serialized with the cc_domain DTOs).
typedef RepoOpHandler =
    Future<Map<String, dynamic>> Function(RepoOpContext ctx);

/// Resolves whether [workspaceId] names a live (registered, not soft-deleted)
/// workspace.
///
/// Consulted at the `repo/call` + `sub/subscribe` chokepoints BEFORE any
/// workspace-scoped state is touched. Every downstream read — the membership
/// role lookup included — opens that workspace's own database and opening
/// CREATES the file, so an unregistered id (a stale client-held active
/// workspace, a typo, a probing peer) must be refused here or each request
/// materialises an empty ghost `workspace.db` on disk.
typedef WorkspaceExistsChecker = Future<bool> Function(String workspaceId);

/// Computes an [ActionPreview] for a high-impact op WITHOUT applying it
/// (PRD 19 §4 dry-run). Declared on ops whose effect the operator should see
/// before committing (files touched, cost, blast radius). Pure: it must not
/// mutate state.
typedef RepoOpPreview = Future<ActionPreview> Function(RepoOpContext ctx);

/// A single declared, versioned repository operation.
///
/// This is the closed allow-list entry the repo-RPC envelope routes to — there
/// is NO reflection onto repositories. Adding a remotely-reachable operation is
/// a deliberate act: declare a [RepoOp] with its [kind], required args and
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
    this.minRole,
    this.repoAccess,
    this.repoArg = 'repo_id',
    this.undoClass,
    this.preview,
    this.actionClasses = const {},
    this.audited = true,
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

  /// Explicit minimum workspace role required to call this op. Null (default)
  /// derives the floor from [kind] — [effectiveMinRole] — so *every* op is
  /// role-gated without annotation and a new op cannot bypass the gate
  /// silently. Set explicitly for ops whose kind understates their power
  /// (e.g. workspace settings mutations → [WorkspaceRole.admin]).
  final WorkspaceRole? minRole;

  /// When non-null, this op exposes code from one repo: the dispatcher reads
  /// the repo id from `args[repoArg]` and requires the caller's per-repo grant
  /// to be at least this level (owners/admins hold every grant implicitly).
  /// Null = the op exposes no repo content.
  final RepoGrantLevel? repoAccess;

  /// The argument key carrying the repo id for [repoAccess] checks.
  final String repoArg;

  /// The reversibility boundary this op declares (PRD 19 §5). Null (default)
  /// derives [UndoClass.irreversible] — [effectiveUndoClass] — the fail-safe
  /// so an op is never wrongly presented as undoable. Only [UndoClass.reversible]
  /// / [UndoClass.compensable] ops enter the ActionJournal; declaring one is a
  /// deliberate, ratchet-guarded act (see `undo_class_coverage_test.dart`).
  /// Ignored for [RepoOpKind.read] (reads never mutate).
  final UndoClass? undoClass;

  /// Optional dry-run preview: when present, a `repo/call` with `dry_run: true`
  /// returns this op's [ActionPreview] instead of applying it (PRD 19 §4).
  final RepoOpPreview? preview;

  /// The PRD 24 action-effect classes this op performs, as its honest
  /// worst-case (empty for reads and effect-free ops). The repo-op dispatcher
  /// resolves these against the workspace action policy through the shared
  /// `ActionGuardService` and gates the op (allow / one confirmation / deny)
  /// before the handler runs — the same effect net the MCP dispatcher applies.
  /// A new mutating op that omits its classes is caught by the ratchet in
  /// `repo_op_action_class_coverage_test.dart`.
  final Set<ActionClass> actionClasses;

  /// Whether a successful call appends to the per-user audit trail. Default
  /// true — accountability is the default for every mutation. Set false only
  /// for ops whose record would be noise, not accountability (e.g. the
  /// internal `cache.write` scratch store); declaring it is a deliberate act
  /// visible on the op itself.
  final bool audited;

  /// Executes the operation.
  final RepoOpHandler handler;

  /// The undo class actually enforced: [undoClass] when declared, otherwise
  /// [UndoClass.irreversible] (fail-safe — not undoable). Reads report
  /// irreversible too (they never enter the journal).
  UndoClass get effectiveUndoClass => undoClass ?? UndoClass.irreversible;

  /// Whether this op supports a dry-run preview (PRD 19 §4).
  bool get supportsPreview => preview != null;

  /// The role floor actually enforced: [minRole] when declared, otherwise
  /// derived from [kind] — reads are open to every member tier including
  /// guests (whose visibility is further narrowed by repo grants and secret
  /// exclusion), mutations need [WorkspaceRole.member], destructive ops need
  /// [WorkspaceRole.admin].
  WorkspaceRole get effectiveMinRole =>
      minRole ??
      switch (kind) {
        RepoOpKind.read => WorkspaceRole.guest,
        RepoOpKind.mutate => WorkspaceRole.member,
        RepoOpKind.destructive => WorkspaceRole.admin,
      };
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

  /// All declared ops (for coverage ratchets and diagnostics).
  Iterable<RepoOp> get ops => _ops.values;

  /// Looks up an op by name, or null if not registered (→ default-deny).
  RepoOp? lookup(String name) => _ops[name];

  /// Describes the catalog for `op/list` discovery + version negotiation.
  ///
  /// Memoized: the registry is immutable once built, so rebuilding ~600 maps
  /// per `op/list` call produced identical output every time.
  List<Map<String, dynamic>>? _described;

  /// Describes the catalog for `op/list` discovery + version negotiation.
  List<Map<String, dynamic>> describe() => _described ??= _describe();

  List<Map<String, dynamic>> _describe() => _ops.values
      .map(
        (o) => {
          'op': o.name,
          'version': o.version,
          'kind': o.kind.name,
          'required_args': o.requiredArgs,
          'workspace_scoped': o.workspaceScoped,
          'min_role': o.effectiveMinRole.wireName,
          'undo_class': o.effectiveUndoClass.name,
          'supports_preview': o.supportsPreview,
        },
      )
      .toList();
}
