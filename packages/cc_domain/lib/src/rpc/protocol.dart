/// Shared protocol vocabulary for the cc_rpc surface: stable error codes,
/// method names, operation classification, and the host-capability handshake.
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

  /// Session control: set the active workspace for the session.
  static const setWorkspace = 'session/set_workspace';
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
