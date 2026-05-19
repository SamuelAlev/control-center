/// Shared protocol vocabulary for the cc_rpc surface: stable error codes,
/// method names, operation classification and the host-capability handshake.
///
/// Pure Dart — imported by the desktop dispatcher, the headless `cc_server`,
/// and the web/mobile clients alike, so all sides agree on the wire byte-for-
/// byte. This sits alongside the JSON-RPC envelope types (`JsonRpcRequest`).
library;

/// Stable JSON-RPC error codes for the repo-RPC + subscription surface.
///
/// The `-330xx` range is mapped 1:1 from the app's `AppException` hierarchy on
/// the server and parsed by clients for typed handling (e.g. surfacing an
/// optimistic-lock conflict for a rollback).
abstract final class RpcErrorCodes {
  /// Method not found (reserved JSON-RPC).
  static const methodNotFound = -32601;

  /// Invalid params (reserved JSON-RPC).
  static const invalidParams = -32602;

  /// Internal error (reserved JSON-RPC).
  static const internalError = -32603;

  /// Rate limited (app-specific).
  static const rateLimited = -32005;

  /// Entity not found (`NotFoundException`).
  static const notFound = -33001;

  /// Caller is not authorized (`AuthException`).
  static const unauthorized = -33002;

  /// Cross-workspace access denied (`WorkspaceMismatchException`).
  static const workspaceMismatch = -33003;

  /// Optimistic-lock conflict (`ConcurrencyConflictException`); `data` carries
  /// `current_version`.
  static const conflict = -33004;

  /// Argument-schema validation failed (checked before the handler runs).
  static const validation = -33005;

  /// Operation name is not in the registry.
  static const opUnknown = -33006;

  /// Operation version unsupported; `data.supported_versions` lists options.
  static const opVersionUnsupported = -33007;

  /// No workspace is bound to the session for a workspace-scoped operation.
  static const noWorkspaceBound = -33008;

  /// Subscription limit exceeded for this session.
  static const tooManySubscriptions = -33011;
}

/// The repo-RPC wire-protocol versions this build speaks.
///
/// `initialize` carries the client's `{'protocol': {'min': …, 'max': …}}` and
/// the server answers with the highest version both sides support, echoed as
/// `capabilities.protocol.agreed`. Negotiation used to be advertised and never
/// read on EITHER side — the range was sent, ignored, and no version was ever
/// agreed, which is worse than not claiming to negotiate at all.
abstract final class RepoRpcProtocol {
  /// Oldest version this build can speak.
  static const int min = 1;

  /// Newest version this build can speak.
  static const int max = 2;
}

/// JSON-RPC method names for the cc_rpc surface (beyond the MCP `tools/*`).
abstract final class RpcMethods {
  /// `repo/call` — invoke a declared repository operation.
  static const repoCall = 'repo/call';

  /// `op/list` — list available repo operations (discovery / versioning).
  static const opList = 'op/list';

  /// `sub/subscribe` — open a reactive subscription to a watch query.
  static const subscribe = 'sub/subscribe';

  /// `sub/unsubscribe` — close a subscription.
  static const unsubscribe = 'sub/unsubscribe';

  /// `sub/snapshot` — full snapshot for a subscription (initial + per-change).
  static const subSnapshot = 'sub/snapshot';

  /// `sub/update` — delta patch (reserved; negotiated capability).
  static const subUpdate = 'sub/update';

  /// `sub/error` — a subscription failed or was invalidated server-side.
  static const subError = 'sub/error';

  /// Session control: list the workspaces the client may switch between.
  static const listWorkspaces = 'session/list_workspaces';

  // NOTE: there is deliberately NO `session/set_workspace`. A server-held
  // "current workspace" per session was rejected: every workspace-scoped op
  // carries its own `workspace_id` argument, which is what lets several
  // clients (and several windows) work in different workspaces against one
  // server without a shared mutable binding. The constant existed with no
  // handler and no caller; see `RepoOpDispatcher`'s arg gate.
}

/// Classification of a repo operation; gates confirmation + rate limiting.
enum RepoOpKind {
  /// Pure read; rate-limited only.
  read,

  /// Local write (no external effect); authenticated + audited.
  mutate,

  /// Irreversible / external-effect; must route through approval to run.
  destructive,
}

/// The reversibility boundary a mutating op declares (PRD 19 §5). This is the
/// containment that keeps "universal undo" from being an unbounded promise:
/// only [reversible] and [compensable] ops ever enter the ActionJournal's undo
/// stack; [irreversible] ops (external side effects) get preview/confirm
/// instead and are never undoable.
///
/// The default (see `RepoOp.effectiveUndoClass`) is [irreversible] — the
/// fail-safe: an op is never wrongly presented as undoable. A reversible or
/// compensable op is a deliberate, ratchet-guarded declaration.
enum UndoClass {
  /// A registered inverse exists — undo re-applies the prior state (ticket /
  /// message / plan / todo edits, agent file edits via snapshot). Enters the
  /// undo stack.
  reversible,

  /// No true inverse, but a named compensating action reverses the intent
  /// (e.g. close-the-created-ticket). Enters the undo stack.
  compensable,

  /// External side effects (publishing a review to GitHub, vendor ticket sync,
  /// sending off-box). Gets preview/confirm per §4 and is NEVER in the undo
  /// stack.
  irreversible;

  /// Whether an op of this class may appear in the undo stack.
  bool get isUndoable => this != UndoClass.irreversible;

  /// Parses a wire name; unknown/absent → [irreversible] (fail-safe).
  static UndoClass fromWire(String? name) => switch (name) {
    'reversible' => UndoClass.reversible,
    'compensable' => UndoClass.compensable,
    _ => UndoClass.irreversible,
  };
}

/// What a connected server can do, returned in the `initialize` handshake so a
/// client can gate its UI (hide features the host cannot back). Pure data.
class HostCapabilities {
  /// Creates a [HostCapabilities].
  const HostCapabilities({
    required this.os,
    this.sandboxBackends = const [],
    this.audioCapture = false,
    this.embeddings = false,
    this.git = false,
    this.pty = false,
    this.codeGraph = false,
    this.repoRpcCatalogVersion = 0,
    this.subscriptions = false,
    this.maxSubscriptionsPerSession = 0,
  });

  /// Deserializes from the `environment` block of an `initialize` result.
  factory HostCapabilities.fromJson(Map<String, dynamic> json) {
    return HostCapabilities(
      os: json['os'] as String? ?? 'unknown',
      sandboxBackends:
          (json['sandbox_backends'] as List?)?.cast<String>() ?? const [],
      audioCapture: json['audio_capture'] as bool? ?? false,
      embeddings: json['embeddings'] as bool? ?? false,
      git: json['git'] as bool? ?? false,
      pty: json['pty'] as bool? ?? false,
      codeGraph: json['code_graph'] as bool? ?? false,
      repoRpcCatalogVersion: json['repo_rpc_catalog_version'] as int? ?? 0,
      subscriptions: json['subscriptions'] as bool? ?? false,
      maxSubscriptionsPerSession:
          json['max_subscriptions_per_session'] as int? ?? 0,
    );
  }

  /// Host OS: `macos` | `linux` | `windows`.
  final String os;

  /// Available sandbox backends (e.g. `seatbelt`, `bwrap`, `none`).
  final List<String> sandboxBackends;

  /// Whether system-audio capture (meetings) is available.
  final bool audioCapture;

  /// Whether local embeddings are available.
  final bool embeddings;

  /// Whether git operations are available.
  final bool git;

  /// Whether an interactive PTY is available.
  final bool pty;

  /// Whether the code graph is available.
  final bool codeGraph;

  /// Repo-RPC op catalog version (`0` = repo-RPC unavailable).
  final int repoRpcCatalogVersion;

  /// Whether reactive subscriptions are available.
  final bool subscriptions;

  /// Max concurrent subscriptions per session (`0` = unset).
  final int maxSubscriptionsPerSession;

  /// Serializes to the `environment` block of an `initialize` result.
  Map<String, dynamic> toJson() => {
    'os': os,
    'sandbox_backends': sandboxBackends,
    'audio_capture': audioCapture,
    'embeddings': embeddings,
    'git': git,
    'pty': pty,
    'code_graph': codeGraph,
    'repo_rpc_catalog_version': repoRpcCatalogVersion,
    'subscriptions': subscriptions,
    'max_subscriptions_per_session': maxSubscriptionsPerSession,
  };
}
