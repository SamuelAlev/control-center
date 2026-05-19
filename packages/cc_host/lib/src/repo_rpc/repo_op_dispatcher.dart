import 'package:cc_domain/cc_domain.dart';
import 'package:cc_host/src/errors/rpc_error_mapping.dart';
import 'package:cc_host/src/log/cc_host_log.dart';
import 'package:cc_host/src/policy/session_capability.dart';
import 'package:cc_host/src/repo_rpc/repo_op.dart';

/// Routes the `repo/call` envelope to a declared [RepoOp].
///
/// This is the parity-gate surface for first-party clients (desktop-remote,
/// web) — typed `data` results, no double-wrapped `CallResult`. It enforces, in
/// order: op exists (else default-deny), version matches, **per-request
/// workspace** (a workspace-scoped op MUST carry `workspace_id` in its args; the
/// server holds no session workspace, so multiple clients on one server each
/// name their own), required-arg presence, and destructive-op approval. Handler
/// exceptions map to the stable `RpcErrorCodes` so clients can react.
class RepoOpDispatcher {
  /// Creates a [RepoOpDispatcher].
  ///
  /// [confirm] is consulted for [RepoOpKind.destructive] ops; when null (no
  /// approver, e.g. headless) destructive ops are denied — never run unconfirmed.
  ///
  /// [mapException] classifies handler errors into stable [RpcErrorCodes]. The
  /// embedding app supplies it so the generic kernel can surface its domain
  /// exceptions (workspace-mismatch, not-found, conflict, …) to clients without
  /// `cc_host` knowing the app's exception hierarchy. Unmapped errors are logged
  /// locally and reported as a generic internal error.
  RepoOpDispatcher({required this.registry, this.confirm, this.mapException});

  /// The closed op allow-list.
  final RepoOpRegistry registry;

  /// Approval callback for destructive ops; null = deny destructive.
  final Future<bool> Function(RepoOp op, Map<String, dynamic> args)? confirm;

  /// Maps a handler exception to a client-safe [RpcErrorMapping] (null = treat
  /// as a generic internal error).
  final RpcExceptionMapper? mapException;

  /// Handles a `repo/call`. [params] is the request's `params`
  /// (`{op, opVersion?, args}`); a workspace-scoped op carries its target
  /// `workspace_id` inside `args` (the server is stateless — there is no session
  /// workspace). [deviceId] is the calling device; [sessionCapability] the
  /// calling session's privilege tier (enforced against
  /// [RepoOp.requiredCapability]).
  Future<Map<String, dynamic>> call({
    required dynamic id,
    required Map<String, dynamic> params,
    required String deviceId,
    required SessionCapability sessionCapability,
  }) async {
    final opName = params['op'];
    if (opName is! String || opName.isEmpty) {
      return _error(id, RpcErrorCodes.invalidParams, 'Missing op name');
    }
    final op = registry.lookup(opName);
    if (op == null) {
      return _error(id, RpcErrorCodes.opUnknown, 'Unknown op: $opName');
    }
    final reqVersion = params['opVersion'];
    if (reqVersion is int && reqVersion != op.version) {
      return _error(
        id,
        RpcErrorCodes.opVersionUnsupported,
        'Op $opName version $reqVersion is unsupported',
        data: {
          'supported_versions': [op.version],
        },
      );
    }

    final rawArgs = params['args'];
    final args = rawArgs is Map
        ? Map<String, dynamic>.from(rawArgs)
        : <String, dynamic>{};

    // Per-request workspace scoping — the chokepoint. The server is stateless:
    // a workspace-scoped op MUST carry its target `workspace_id` in args (the
    // client supplies it per-call), so multiple clients on one server never
    // share a server-held "current workspace". Unscoped ops (the documented
    // cross-workspace exemptions) leave args untouched — any `workspace_id`
    // they carry is just a selector over global rows, never a scoped gate.
    String? workspaceId;
    if (op.workspaceScoped) {
      final ws = args['workspace_id'];
      if (ws is! String || ws.isEmpty) {
        return _error(
          id,
          RpcErrorCodes.validation,
          'Missing required argument: workspace_id',
        );
      }
      workspaceId = ws;
    }

    for (final key in op.requiredArgs) {
      if (!args.containsKey(key) || args[key] == null) {
        return _error(
          id,
          RpcErrorCodes.validation,
          'Missing required argument: $key',
        );
      }
    }

    // Privilege gate — a phone session must never reach a `fullClient`-only op
    // (e.g. `pairing.*`), even though it authenticated. Fail closed before the
    // handler runs. Null requiredCapability = any authenticated session.
    final required = op.requiredCapability;
    if (required != null && sessionCapability != required) {
      CcHostLog.warning(
        'Denying repo/call "$opName" for $deviceId — requires '
        '${required.name}, session is ${sessionCapability.name}',
      );
      return _error(
        id,
        RpcErrorCodes.unauthorized,
        'Operation not permitted for this client: $opName',
      );
    }

    if (op.kind == RepoOpKind.destructive) {
      final approved = await (confirm?.call(op, args) ?? Future.value(false));
      if (!approved) {
        return _error(
          id,
          RpcErrorCodes.unauthorized,
          'Operation requires approval: $opName',
        );
      }
    }

    try {
      final data = await op.handler(
        RepoOpContext(
          args: args,
          workspaceId: workspaceId,
          deviceId: deviceId,
        ),
      );
      return {
        'jsonrpc': '2.0',
        'id': id,
        'result': {'op': op.name, 'data': data},
      };
    } catch (e, st) {
      // Let the app classify its own domain exceptions into stable codes a
      // client can react to (e.g. roll back on a conflict).
      final mapped = mapException?.call(e);
      if (mapped != null) {
        return _error(id, mapped.code, mapped.message, data: mapped.data);
      }
      // Unmapped: never serialize raw exception text to the client (it can embed
      // paths / SQL / auth detail). Log locally; return a generic message.
      CcHostLog.error('repo/call $opName threw: $e', e, st);
      return _error(id, RpcErrorCodes.internalError, 'Internal error');
    }
  }

  /// Handles `op/list` — the catalog for discovery + version negotiation.
  Map<String, dynamic> list(dynamic id) => {
    'jsonrpc': '2.0',
    'id': id,
    'result': {
      'catalog_version': registry.catalogVersion,
      'ops': registry.describe(),
    },
  };

  Map<String, dynamic> _error(
    dynamic id,
    int code,
    String message, {
    Object? data,
  }) => {
    'jsonrpc': '2.0',
    'id': id,
    'error': {'code': code, 'message': message, 'data': ?data},
  };
}
