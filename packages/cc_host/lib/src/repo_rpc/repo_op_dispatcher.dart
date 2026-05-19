import 'dart:async';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/value_objects/repo_grant_level.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_domain/features/guardrails/domain/services/action_guard_service.dart';
import 'package:cc_host/src/errors/rpc_error_mapping.dart';
import 'package:cc_host/src/log/cc_host_log.dart';
import 'package:cc_host/src/policy/session_capability.dart';
import 'package:cc_host/src/repo_rpc/repo_op.dart';

/// Resolves the calling user's role in a workspace; null = not a member.
typedef WorkspaceRoleResolver =
    Future<WorkspaceRole?> Function(String workspaceId, String userId);

/// Resolves the calling user's grant level on one repo in a workspace.
/// Absence of a grant is [RepoGrantLevel.none].
typedef RepoGrantResolver =
    Future<RepoGrantLevel> Function(
      String workspaceId,
      String userId,
      String repoId,
    );

/// Appends one audit record for a successfully executed mutating op.
///
/// [ip] is the server's view of the client address for the session the call
/// arrived on (loopback for local sockets, the relay/tunnel endpoint for
/// relayed sessions, null when the transport has no observable peer — e.g.
/// the in-process host).
typedef UserActivityRecorder =
    Future<void> Function({
      required String workspaceId,
      required String userId,
      required String deviceId,
      required String action,
      String? targetType,
      String? targetId,
      String? ip,
    });

/// The workspace-scoped idempotency ledger (PRD 19 §3), consulted by the
/// dispatcher BEFORE a mutating handler runs so a retry never re-enters feature
/// code. Generalizes the ticketing write ledger to every `repo/call` mutation.
abstract interface class WriteLedgerPort {
  /// The stored result `data` for a prior `(workspaceId, key)` mutation, or
  /// null when this is the first application of that logical action.
  Future<Map<String, dynamic>?> find(String workspaceId, String key);

  /// Records a completed mutation's result `data`. Idempotent on
  /// `(workspaceId, key)` — a concurrent double-apply collapses to one row.
  Future<void> record({
    required String workspaceId,
    required String key,
    required String opName,
    required Map<String, dynamic> data,
  });
}

/// Routes the `repo/call` envelope to a declared [RepoOp].
///
/// This is the parity-gate surface for first-party clients (desktop-remote,
/// web) — typed `data` results, no double-wrapped `CallResult`. It enforces, in
/// order: op exists (else default-deny), version matches, **per-request
/// workspace** (a workspace-scoped op MUST carry `workspace_id` in its args; the
/// server holds no session workspace, so multiple clients on one server each
/// name their own), required-arg presence, session capability, **membership +
/// role** (the caller must be a member of the target workspace with a role at
/// least the op's floor), **per-repo grant** (code-bearing ops) and
/// destructive-op approval. Denials are loud ([RpcErrorCodes.unauthorized]),
/// never silent. Handler exceptions map to the stable `RpcErrorCodes` so
/// clients can react.
class RepoOpDispatcher {
  /// Creates a [RepoOpDispatcher].
  ///
  /// [confirm] is consulted for [RepoOpKind.destructive] ops; when null (no
  /// approver, e.g. headless) destructive ops are denied — never run unconfirmed.
  ///
  /// [resolveRole] resolves workspace membership for the role gate. When null
  /// (bare test dispatchers), the role gate is skipped — production wiring
  /// always supplies it.
  ///
  /// [resolveRepoGrant] resolves per-repo grants for ops declaring
  /// [RepoOp.repoAccess]; owners/admins pass implicitly. When null, grant-
  /// gated ops are denied for non-admin roles (fail closed).
  ///
  /// [recordActivity] appends the audit record for successful mutating ops.
  ///
  /// [mapException] classifies handler errors into stable [RpcErrorCodes]. The
  /// embedding app supplies it so the generic kernel can surface its domain
  /// exceptions (workspace-mismatch, not-found, conflict, …) to clients without
  /// `cc_host` knowing the app's exception hierarchy. Unmapped errors are logged
  /// locally and reported as a generic internal error.
  RepoOpDispatcher({
    required this.registry,
    this.confirm,
    this.mapException,
    this.resolveRole,
    this.resolveRepoGrant,
    this.recordActivity,
    this.writeLedger,
    this.actionGuard,
    this.workspaceExists,
  });

  /// The closed op allow-list.
  final RepoOpRegistry registry;

  /// The idempotency ledger (PRD 19 §3). When null, mutations are never
  /// deduplicated (bare test dispatchers); production always supplies it.
  final WriteLedgerPort? writeLedger;

  /// Approval callback for destructive ops; null = deny destructive.
  final Future<bool> Function(RepoOp op, Map<String, dynamic> args)? confirm;

  /// Maps a handler exception to a client-safe [RpcErrorMapping] (null = treat
  /// as a generic internal error).
  final RpcExceptionMapper? mapException;

  /// Membership/role lookup for the role gate.
  final WorkspaceRoleResolver? resolveRole;

  /// Per-repo grant lookup for [RepoOp.repoAccess]-declaring ops.
  final RepoGrantResolver? resolveRepoGrant;

  /// Audit sink for successful mutating ops.
  final UserActivityRecorder? recordActivity;

  /// The shared PRD 24 action-guardrail service — the SAME instance the MCP
  /// dispatcher uses. When set, a mutating op that declares [RepoOp.actionClasses]
  /// is resolved against the workspace policy and gated (allow / one confirmation
  /// / deny) before its handler runs. Null (bare test dispatchers) skips the gate.
  final ActionGuardService? actionGuard;

  /// Registry existence gate for workspace-scoped ops. Runs BEFORE [resolveRole]:
  /// the membership lookup opens the named workspace's database and opening
  /// CREATES the file, so an unregistered id must be refused first or a stale
  /// client-held id sprays empty ghost `workspace.db` files on every call.
  /// Null (bare test dispatchers) skips the gate.
  final WorkspaceExistsChecker? workspaceExists;

  /// Handles a `repo/call`. [params] is the request's `params`
  /// (`{op, opVersion?, args}`); a workspace-scoped op carries its target
  /// `workspace_id` inside `args` (the server is stateless — there is no session
  /// workspace). [deviceId] is the calling device, [userId] the authenticated
  /// user behind it and [sessionCapability] the calling session's privilege
  /// tier (enforced against [RepoOp.requiredCapability]). [remoteAddress] is
  /// the server's view of the client IP for the calling session (the IP
  /// literal; null when the transport exposes none) and flows into the audit
  /// record only — never into handler args.
  Future<Map<String, dynamic>> call({
    required dynamic id,
    required Map<String, dynamic> params,
    required String deviceId,
    required String userId,
    required SessionCapability sessionCapability,
    String? remoteAddress,
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

    // Existence gate — the id the client named must be a REGISTERED workspace
    // before anything opens its database (the role lookup below included):
    // opening creates the file, so an unknown id would materialise an empty
    // ghost `workspace.db` per request. Refused as not-found, which the client
    // retry policy treats as unrecoverable (no retry storm).
    if (workspaceId != null &&
        workspaceExists != null &&
        !await workspaceExists!(workspaceId)) {
      CcHostLog.warning(
        'Denying repo/call "$opName" for $userId@$deviceId — unknown '
        'workspace $workspaceId',
      );
      return _error(id, RpcErrorCodes.notFound, 'Workspace not found');
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

    // Role gate — the membership chokepoint. Every workspace-scoped op has a
    // role floor (explicit minRole or derived from kind), so a non-member is
    // refused outright and a viewer/guest is refused any mutation, loudly.
    WorkspaceRole? role;
    if (op.workspaceScoped && resolveRole != null) {
      role = await resolveRole!(workspaceId!, userId);
      if (role == null) {
        CcHostLog.warning(
          'Denying repo/call "$opName" for $userId@$deviceId — not a member '
          'of workspace $workspaceId',
        );
        return _error(
          id,
          RpcErrorCodes.unauthorized,
          'Not a member of this workspace',
        );
      }
      final floor = op.effectiveMinRole;
      if (!role.atLeast(floor)) {
        CcHostLog.warning(
          'Denying repo/call "$opName" for $userId@$deviceId — requires '
          '${floor.wireName}, member is ${role.wireName}',
        );
        return _error(
          id,
          RpcErrorCodes.unauthorized,
          'Operation requires the ${floor.wireName} role: $opName',
        );
      }
    }

    // Per-repo grant gate — workspace membership must never silently grant
    // code visibility. Ops that expose repo content declare `repoAccess`; the
    // caller needs that grant level on the named repo (owners/admins pass
    // implicitly).
    final repoAccess = op.repoAccess;
    if (repoAccess != null &&
        op.workspaceScoped &&
        role != null &&
        !role.isAdmin) {
      final repoId = args[op.repoArg];
      if (repoId is String && repoId.isNotEmpty) {
        final grant =
            await (resolveRepoGrant?.call(workspaceId!, userId, repoId) ??
                Future.value(RepoGrantLevel.none));
        if (!grant.atLeast(repoAccess)) {
          CcHostLog.warning(
            'Denying repo/call "$opName" for $userId@$deviceId — requires '
            '${repoAccess.wireName} on repo $repoId, grant is '
            '${grant.wireName}',
          );
          return _error(
            id,
            RpcErrorCodes.unauthorized,
            'No ${repoAccess.wireName} access to this repo',
          );
        }
      } else {
        // Fail closed: a repo-scoped op that arrives without a repo_id is a
        // code bug that would silently bypass the per-repo grant gate.
        // Deny loudly rather than let it through unchecked.
        CcHostLog.warning(
          'Denying repo-scoped op "$opName" for $userId@$deviceId — '
          'missing repo_id arg "${op.repoArg}"',
        );
        return _error(
          id,
          RpcErrorCodes.unauthorized,
          'This operation requires repository access but no repository was '
          'specified',
        );
      }
    }

    final ctx = RepoOpContext(
      args: args,
      workspaceId: workspaceId,
      deviceId: deviceId,
      userId: userId,
      role: role,
      remoteAddress: remoteAddress,
    );

    // Dry-run (PRD 19 §4): return the op's preview instead of applying it. No
    // approval, no ledger, no audit — nothing is committed. Ops that declare no
    // preview reject the dry-run honestly rather than silently applying.
    if (params['dry_run'] == true) {
      final preview = op.preview;
      if (preview == null) {
        return _error(
          id,
          RpcErrorCodes.validation,
          'Operation does not support dry-run: $opName',
        );
      }
      try {
        final result = await preview(ctx);
        return {
          'jsonrpc': '2.0',
          'id': id,
          'result': {'op': op.name, 'data': result.toJson(), 'dry_run': true},
        };
      } catch (e, st) {
        return _mapHandlerError(id, opName, e, st);
      }
    }

    // Idempotency dedupe (PRD 19 §3): a mutating call that carries a logical-
    // action key is checked against the ledger BEFORE the handler runs, so a
    // double-click / reconnect replay / offline flush collapses to one apply
    // and never re-enters feature code. The stored result envelope replays
    // byte-identically, flagged `deduplicated: true`.
    final rawKey = params['idempotency_key'];
    final ledger = writeLedger;
    final dedupe =
        op.kind != RepoOpKind.read &&
        ledger != null &&
        workspaceId != null &&
        rawKey is String &&
        rawKey.isNotEmpty;
    if (dedupe) {
      final existing = await ledger.find(workspaceId, rawKey);
      if (existing != null) {
        return {
          'jsonrpc': '2.0',
          'id': id,
          'result': {'op': op.name, 'data': existing, 'deduplicated': true},
        };
      }
    }

    // Unified action-guardrail effect net (PRD 24 §3) — the same resolver the
    // MCP dispatcher applies, now covering the operator's own repo-RPC clicks.
    // A mutating op that declares effect classes is resolved against the
    // workspace action policy: allow proceeds, prompt surfaces exactly one
    // confirmation (fail-closed when no approver), deny refuses with a terminal
    // reason. Reads and effect-free ops (empty actionClasses) skip it. Dry-run
    // and deduplicated replays returned above, so this never re-prompts them.
    // Repo-RPC callers are always human (agents act via MCP), so agentId is null
    // and only channel/workspace/preset scopes resolve.
    final guard = actionGuard;
    if (guard != null && op.actionClasses.isNotEmpty && workspaceId != null) {
      final channelArg = args['channel_id'] ?? args['conversation_id'];
      final verdict = await guard.check(
        workspaceId: workspaceId,
        classes: op.actionClasses,
        channelId: channelArg is String ? channelArg : null,
        actionSummary: op.name,
      );
      if (!verdict.allowed) {
        CcHostLog.warning(
          'Denying repo/call "$opName" for $userId@$deviceId — action policy: '
          '${verdict.reason}',
        );
        return _error(
          id,
          RpcErrorCodes.unauthorized,
          'Denied by action policy: ${verdict.reason}',
        );
      }
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
      final data = await op.handler(ctx);
      if (dedupe) {
        // Persist the applied result so the next replay of this logical action
        // dedupes. A failed record leaves the op applied (a later retry would
        // re-apply) — degradation, not corruption — so it never fails the call.
        try {
          await ledger.record(
            workspaceId: workspaceId,
            key: rawKey,
            opName: op.name,
            data: data,
          );
        } catch (e) {
          CcHostLog.warning('write-ledger record for ${op.name} failed: $e');
        }
      }
      if (op.kind != RepoOpKind.read && op.audited && workspaceId != null) {
        // Audit trail: who did what, where. Fire-and-forget so a slow audit
        // write never delays the response; failures are logged, not raised.
        final audit = recordActivity?.call(
          workspaceId: workspaceId,
          userId: userId,
          deviceId: deviceId,
          action: op.name,
          targetType: _targetTypeOf(op.name),
          targetId: _targetIdOf(args),
          ip: ctx.remoteAddress,
        );
        if (audit != null) {
          unawaited(
            audit.catchError((Object e) {
              CcHostLog.warning('audit append for ${op.name} failed: $e');
            }),
          );
        }
      }
      return {
        'jsonrpc': '2.0',
        'id': id,
        'result': {'op': op.name, 'data': data},
      };
    } catch (e, st) {
      return _mapHandlerError(id, opName, e, st);
    }
  }

  /// Maps a handler/preview exception to a client-safe error frame.
  Map<String, dynamic> _mapHandlerError(
    dynamic id,
    String opName,
    Object e,
    StackTrace st,
  ) {
    // Let the app classify its own domain exceptions into stable codes a
    // client can react to (e.g. roll back on a conflict).
    final mapped = mapException?.call(e);
    if (mapped != null) {
      return _error(id, mapped.code, mapped.message, data: mapped.data);
    }
    // Unmapped: never serialize raw exception text to the client (it can embed
    // paths / SQL / auth detail). Log locally with a short correlation id and
    // return the SAME id in the error data, so a user report ("diagnostic id
    // e…") can be grep'd straight to the server log line (FINDINGS §126).
    final diagnosticId = _nextDiagnosticId();
    CcHostLog.error('repo/call $opName threw [$diagnosticId]: $e', e, st);
    return _error(
      id,
      RpcErrorCodes.internalError,
      'Internal error',
      data: {'diagnostic_id': diagnosticId},
    );
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

  /// The audit target type is the op's feature prefix (`tickets.assign` →
  /// `tickets`).
  static String? _targetTypeOf(String opName) {
    final dot = opName.indexOf('.');
    return dot > 0 ? opName.substring(0, dot) : null;
  }

  /// Best-effort audit target id from conventional arg names. `path` and
  /// `name` trail the id forms deliberately: a real identifier wins, then a
  /// filesystem path (e.g. `repos.add`), then a display name (e.g.
  /// `messaging.createChannel`).
  static String? _targetIdOf(Map<String, dynamic> args) {
    for (final key in const [
      'id',
      'ticket_id',
      'channel_id',
      'conversation_id',
      'repo_id',
      'agent_id',
      'run_id',
      'message_id',
      'path',
      'name',
    ]) {
      final value = args[key];
      if (value is String && value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  /// Process-global counter so two errors in the same microsecond still get
  /// distinct diagnostic ids.
  static int _diagnosticSeq = 0;

  /// A short, greppable correlation id (base-36 microsecond stamp + counter),
  /// returned to the client and written into the server log for the same error.
  static String _nextDiagnosticId() {
    final stamp = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    return 'e$stamp${(_diagnosticSeq++).toRadixString(36)}';
  }

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
