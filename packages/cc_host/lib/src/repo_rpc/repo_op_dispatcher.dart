import 'dart:async';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/entities/role_definition.dart';
import 'package:cc_domain/core/domain/services/permission_resolver.dart';
import 'package:cc_domain/core/domain/value_objects/permission.dart';
import 'package:cc_domain/core/domain/value_objects/repo_grant_level.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_storage_state.dart';
import 'package:cc_domain/features/guardrails/domain/services/action_guard_service.dart';
import 'package:cc_host/src/errors/rpc_error_mapping.dart';
import 'package:cc_host/src/log/cc_host_log.dart';
import 'package:cc_host/src/policy/session_capability.dart';
import 'package:cc_host/src/repo_rpc/audit_details.dart';
import 'package:cc_host/src/repo_rpc/repo_op.dart';

/// Resolves the calling user's role in a workspace; null = not a member.
typedef WorkspaceRoleResolver =
    Future<WorkspaceRole?> Function(String workspaceId, String userId);

/// Resolves the calling user's full role DEFINITION in a workspace — the
/// preset, or a workspace-defined custom role that subtracts permissions from
/// one. Null = not a member.
///
/// Optional: when unwired the dispatcher builds a preset definition from
/// [WorkspaceRoleResolver], which is exactly the pre-custom-role behavior.
typedef WorkspaceRoleDefinitionResolver =
    Future<RoleDefinition?> Function(String workspaceId, String userId);

/// Resolves whether the calling user is the recorded server owner (the
/// install's operator) — the [ServerAuthority.serverOwner] gate.
typedef ServerOwnerResolver = Future<bool> Function(String userId);

/// Appends one human-lane authorization decision to the tamper-evident audit
/// spine.
///
/// Distinct from [UserActivityRecorder], which records SUCCESSFUL mutations
/// for the product's activity timeline. This records the authorization
/// verdict itself — refusals included — which is the half an incident review
/// needs and the activity log has never had. The two share a
/// [correlationId] so one call can be read across both.
typedef GuardDecisionRecorder =
    void Function({
      required String workspaceId,
      required String userId,
      required String deviceId,
      required String opName,
      required String permission,
      required bool allowed,
      required String sourceScope,
      String? reason,
      String? ip,
      String? correlationId,
      List<String> actionClasses,
    });

/// Resolves the calling user's grant level on one repo in a workspace.
/// Absence of a grant is [RepoGrantLevel.none].
typedef RepoGrantResolver =
    Future<RepoGrantLevel> Function(
      String workspaceId,
      String userId,
      String repoId,
    );

/// Refuses [userId] the code of [repoId] in [workspaceId] unless their own
/// forge sign-in can read that repository, by throwing the app's refusal
/// (mapped through [RpcExceptionMapper] like a handler's). Completes when they
/// may read it.
typedef RepoForgeReadGate =
    Future<void> Function(String workspaceId, String userId, String repoId);

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
      Map<String, Object?>? details,
    });

/// Appends one record of an install-wide mutating op call: who, which op,
/// which argument NAMES (never values) and how it ended (`ok`, `denied` by a
/// gate, or `failed` in the handler). The workspace trail
/// ([UserActivityRecorder]) cannot hold these calls: they belong to no
/// workspace.
typedef ServerAuditRecorder =
    Future<void> Function({
      required String userId,
      required String deviceId,
      required String op,
      required List<String> argNames,
      required String outcome,
      String? ip,
    });

/// The workspace-scoped idempotency ledger (PRD 19 §3), consulted by the
/// dispatcher BEFORE a mutating handler runs so a retry never re-enters feature
/// code. Generalizes the ticketing write ledger to every `repo/call` mutation.
///
/// A key is claimed before the handler runs and completed after it returns,
/// so two concurrent calls with one key never both run the handler.
abstract interface class WriteLedgerPort {
  /// Claims `(workspaceId, key)` for a call about to run [opName]. Answers
  /// [LedgerClaimed] when this call owns the key and must run the handler,
  /// [LedgerReplay] with the stored result when the key already completed, and
  /// [LedgerInProgress] when another call holds the claim.
  Future<WriteLedgerClaim> claim({
    required String workspaceId,
    required String key,
    required String opName,
  });

  /// Stores the result `data` of the call that claimed `(workspaceId, key)`.
  /// Returns false when the claim no longer exists to complete.
  Future<bool> complete({
    required String workspaceId,
    required String key,
    required Map<String, dynamic> data,
  });

  /// Releases an unfinished claim so a retry can run the handler: the handler
  /// failed, or the call was refused before it ran.
  Future<void> release({required String workspaceId, required String key});
}

/// The answer to [WriteLedgerPort.claim].
sealed class WriteLedgerClaim {
  const WriteLedgerClaim();
}

/// This call owns the key: run the handler, then complete or release it.
final class LedgerClaimed extends WriteLedgerClaim {
  /// Creates a [LedgerClaimed].
  const LedgerClaimed();
}

/// The key already completed: replay [data] instead of applying again.
final class LedgerReplay extends WriteLedgerClaim {
  /// Creates a [LedgerReplay] of [data].
  const LedgerReplay(this.data);

  /// The result `data` the first application returned.
  final Map<String, dynamic> data;
}

/// Another call holds the key and has not finished.
final class LedgerInProgress extends WriteLedgerClaim {
  /// Creates a [LedgerInProgress].
  const LedgerInProgress();
}

/// The `data.kind` refusing a call whose idempotency key is held by another
/// call still running.
const idempotencyInProgressKind = 'idempotency.in_progress';

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
  /// [confirm] is consulted for [RepoOpKind.destructive] ops; when null (no approver, e.g.
  /// headless) destructive ops are denied — never run unconfirmed.
  /// [resolveRole] resolves workspace membership for the role gate.
  /// When null, grant- gated ops are denied for non-admin roles (fail closed).
  /// The embedding app supplies it so the generic kernel can surface its domain exceptions
  /// (workspace-mismatch, not-found, conflict, …) to clients without `cc_host` knowing the
  /// app's exception hierarchy.
  RepoOpDispatcher({
    required this.registry,
    this.confirm,
    this.mapException,
    this.resolveRole,
    this.resolveRepoGrant,
    this.requireForgeRead,
    this.recordActivity,
    this.recordServerAudit,
    this.writeLedger,
    this.actionGuard,
    this.workspaceExists,
    this.resolveServerOwner,
    this.resolveRoleDefinition,
    this.recordGuardDecision,
    this.describeError,
    this.isWorkspaceReadOnly,
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

  /// A log-safe one-line description of an error, for every log line this
  /// dispatcher writes about a failure. The embedding app supplies one that
  /// knows its storage errors (whose own text carries the statement's bound
  /// values: message bodies, tokens). Null logs only the error's type.
  final String Function(Object error)? describeError;

  /// Membership/role lookup for the role gate.
  final WorkspaceRoleResolver? resolveRole;

  /// Full role-definition lookup (presets + custom roles). When null, the
  /// dispatcher derives a preset definition from [resolveRole] — identical
  /// behavior, which is what makes custom roles an additive change.
  final WorkspaceRoleDefinitionResolver? resolveRoleDefinition;

  /// The one human-side decision point. Pure and stateless; the dispatcher
  /// hands it a principal built from the resolved role + the grants for the
  /// repos this op actually exposes.
  static const PermissionResolver _permissions = PermissionResolver();

  /// Per-repo grant lookup for [RepoOp.repoAccess]-declaring ops.
  final RepoGrantResolver? resolveRepoGrant;

  /// The forge half of the per-repo gates: every repo a code-bearing op
  /// exposes must also be one the caller's own forge sign-in can read. Unlike
  /// the grant, admins are not exempt; the gate itself decides who is (the
  /// server owner) and which repos have no forge to ask. Null (bare test
  /// dispatchers) skips it.
  final RepoForgeReadGate? requireForgeRead;

  /// Audit sink for successful mutating ops.
  final UserActivityRecorder? recordActivity;

  /// Audit sink for install-wide mutating ops ([serverAudited]): every call
  /// that passed op lookup and argument validation, refusals included.
  final ServerAuditRecorder? recordServerAudit;

  /// Whether calls of [op] go to [recordServerAudit]: a mutating op no
  /// workspace owns that has not opted out of the trail ([RepoOp.audited]).
  static bool serverAudited(RepoOp op) =>
      !op.workspaceScoped && op.kind != RepoOpKind.read && op.audited;

  /// Audit sink for authorization VERDICTS (refusals included). Null in bare
  /// test dispatchers; production always supplies it.
  final GuardDecisionRecorder? recordGuardDecision;

  /// The shared PRD 24 action-guardrail service — the SAME instance the MCP
  /// dispatcher uses. When set, a mutating op that declares [RepoOp.actionClasses]
  /// is resolved against the workspace policy and refused when it resolves to
  /// `deny`, before its handler runs. A `prompt` proceeds: the caller is the
  /// operator, and their click is the confirmation (see the gate below). Null
  /// (bare test dispatchers) skips the gate.
  final ActionGuardService? actionGuard;

  /// Registry existence gate for workspace-scoped ops. Runs BEFORE [resolveRole]:
  /// the membership lookup opens the named workspace's database and opening
  /// CREATES the file, so an unregistered id must be refused first or a stale
  /// client-held id sprays empty ghost `workspace.db` files on every call.
  /// Null (bare test dispatchers) skips the gate.
  final WorkspaceExistsChecker? workspaceExists;

  /// Whether a workspace's database is read-only (its integrity check
  /// failed). A mutating workspace op on such a workspace is refused with
  /// [workspaceReadOnlyKind] before its handler runs, so the handler never
  /// half-applies a change whose first write SQLite then refuses, and the
  /// client can say "this workspace needs restoring". Reads still run. Null
  /// (bare test dispatchers) skips the gate.
  final bool Function(String workspaceId)? isWorkspaceReadOnly;

  /// The [ServerAuthority.serverOwner] gate. Unlike [resolveRole], a missing
  /// resolver does NOT skip the check: an op that declared server authority is
  /// refused when nobody can vouch for the caller (fail closed), never served
  /// ungated because an install has no recorded owner.
  final ServerOwnerResolver? resolveServerOwner;

  /// Handles a `repo/call`. [params] is the request's `params`
  /// (`{op, opVersion?, args}`); a workspace-scoped op carries its target
  /// `workspace_id` inside `args` (the server is stateless — there is no session
  /// workspace). [deviceId] is the calling device, [userId] the authenticated
  /// user behind it and [sessionCapability] the calling session's privilege
  /// tier (enforced against [RepoOp.requiredCapability]). [remoteAddress] is
  /// the server's view of the client IP for the calling session (the IP
  /// literal; null when the transport exposes none) and flows into the audit
  /// record only — never into handler args.
  /// [isCancelled] skips an abandoned read after admission gates finish;
  /// mutations are never interrupted by client navigation.
  Future<Map<String, dynamic>> call({
    required dynamic id,
    required Map<String, dynamic> params,
    required String deviceId,
    required String userId,
    required SessionCapability sessionCapability,
    String? remoteAddress,
    bool Function()? isCancelled,
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

    final response = await _admitAndRun(
      id: id,
      params: params,
      op: op,
      args: args,
      workspaceId: workspaceId,
      deviceId: deviceId,
      userId: userId,
      sessionCapability: sessionCapability,
      remoteAddress: remoteAddress,
      isCancelled: isCancelled,
    );
    if (serverAudited(op) && params['dry_run'] != true) {
      _auditServerCall(
        op: op,
        args: args,
        response: response,
        userId: userId,
        deviceId: deviceId,
        ip: remoteAddress,
      );
    }
    return response;
  }

  /// Runs the admission gates and then the handler of an op whose lookup,
  /// version and arguments [call] has already checked.
  Future<Map<String, dynamic>> _admitAndRun({
    required dynamic id,
    required Map<String, dynamic> params,
    required RepoOp op,
    required Map<String, dynamic> args,
    required String? workspaceId,
    required String deviceId,
    required String userId,
    required SessionCapability sessionCapability,
    required String? remoteAddress,
    required bool Function()? isCancelled,
  }) async {
    final opName = op.name;

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

    // Server-authority gate — the only server-owner check; no handler repeats
    // it. Runs for every op that declares authority
    // (scoped or not) and FAILS CLOSED when no resolver is wired: an op that
    // said "owner only" must never run ungated because a catalog was built
    // without identity wiring.
    if (op.serverAuthority != ServerAuthority.none) {
      final ownerResolver = resolveServerOwner;
      final isOwner = ownerResolver == null
          ? false
          : await ownerResolver(userId);
      if (!isOwner) {
        CcHostLog.warning(
          'Denying repo/call "$opName" for $userId@$deviceId — requires '
          'server ${op.serverAuthority.name}',
        );
        _auditDecision(
          workspaceId: workspaceId,
          userId: userId,
          deviceId: deviceId,
          op: op,
          allowed: false,
          sourceScope: 'server_authority',
          reason: 'Requires the server owner',
          ip: remoteAddress,
        );
        return _error(
          id,
          RpcErrorCodes.unauthorized,
          'Only the server owner may call this operation: $opName',
          // Named, so a client can say "ask this server's operator" instead
          // of reporting a failure.
          data: const {'kind': 'server_owner_required'},
        );
      }
    }

    // Role gate — the membership chokepoint, now expressed as ONE permission
    // decision (`can(principal, op.permission)`) rather than an inline role
    // comparison. The answers are identical for every built-in preset —
    // `permission_parity_test.dart` pins that for every op × role — so this
    // is a seam, not a behavior change: a custom role that subtracts a
    // permission, and later an org-scoped role, are changes inside the
    // resolver instead of a sweep of hundreds of call sites.
    WorkspaceRole? role;
    RoleDefinition? roleDefinition;
    if (op.workspaceScoped &&
        (resolveRole != null || resolveRoleDefinition != null)) {
      final definitionResolver = resolveRoleDefinition;
      if (definitionResolver != null) {
        roleDefinition = await definitionResolver(workspaceId!, userId);
        role = roleDefinition?.basePreset;
      } else {
        role = await resolveRole!(workspaceId!, userId);
        roleDefinition = role == null ? null : RoleDefinition.preset(role);
      }
      final verdict = _permissions.can(
        PermissionPrincipal(userId: userId, role: roleDefinition),
        op.permission,
      );
      if (!verdict.allowed) {
        CcHostLog.warning(
          'Denying repo/call "$opName" for $userId@$deviceId — '
          '${verdict.reason} (needs ${op.permission.wire}; member is '
          '${roleDefinition?.name ?? "not a member"})',
        );
        _auditDecision(
          workspaceId: workspaceId,
          userId: userId,
          deviceId: deviceId,
          op: op,
          allowed: false,
          sourceScope: verdict.source.name,
          reason: verdict.reason,
          ip: remoteAddress,
        );
        return _error(
          id,
          RpcErrorCodes.unauthorized,
          verdict.source == PermissionSource.membership
              ? 'Not a member of this workspace'
              : 'Operation requires the ${op.effectiveMinRole.wireName} '
                    'role: $opName',
        );
      }
    }

    // Storage gate — after the role gate, whose membership lookup is the
    // query that runs a freshly opened file's integrity check, so a damaged
    // file is known here.
    if (workspaceId != null &&
        op.kind != RepoOpKind.read &&
        (isWorkspaceReadOnly?.call(workspaceId) ?? false)) {
      CcHostLog.warning(
        'Refusing repo/call "$opName" for $userId@$deviceId — workspace '
        '$workspaceId is read-only',
      );
      return _error(
        id,
        RpcErrorCodes.internalError,
        'This workspace is read-only: its database failed an integrity check',
        data: const {'kind': workspaceReadOnlyKind},
      );
    }

    // Per-repo grant gate — workspace membership must never silently grant
    // code visibility. Ops that expose repo content declare `repoAccess`; the
    // caller needs that grant level on the named repo (owners/admins pass
    // implicitly) and, admins included, a forge sign-in that can read it.
    // An op that derives its repos ([RepoOp.repoAccessVia]) is gated below.
    final repoAccess = op.repoAccess;
    if (repoAccess != null &&
        op.repoAccessVia == null &&
        op.workspaceScoped &&
        role != null) {
      final repoId = args[op.repoArg];
      if (repoId is String && repoId.isNotEmpty) {
        if (!role.isAdmin) {
          final verdict = await _checkRepoGrant(
            workspaceId: workspaceId!,
            userId: userId,
            roleDefinition: roleDefinition,
            permission: op.permission,
            repoId: repoId,
            level: repoAccess,
          );
          if (!verdict.allowed) {
            CcHostLog.warning(
              'Denying repo/call "$opName" for $userId@$deviceId — '
              '${verdict.reason} (repo $repoId)',
            );
            _auditDecision(
              workspaceId: workspaceId,
              userId: userId,
              deviceId: deviceId,
              op: op,
              allowed: false,
              sourceScope: verdict.source.name,
              reason: '${verdict.reason} (repo $repoId)',
              ip: remoteAddress,
            );
            return _error(
              id,
              RpcErrorCodes.unauthorized,
              'No ${repoAccess.wireName} access to this repo',
              data: repoGrantRequiredData(repoAccess),
            );
          }
        }
        final refused = await _refuseWithoutForgeRead(
          id: id,
          op: op,
          workspaceId: workspaceId!,
          userId: userId,
          deviceId: deviceId,
          repoId: repoId,
          ip: remoteAddress,
        );
        if (refused != null) {
          return refused;
        }
      } else if (!role.isAdmin) {
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

    // Multi-repo grant gate — ops whose repo set is derived, not named by one
    // argument (a space terminal, a code-server tab, an agent dispatch). The
    // caller needs the declared grant level on EVERY repo the op exposes;
    // owners/admins pass implicitly, exactly like the single-repo gate above,
    // and every caller's forge sign-in must read each of them.
    // An empty resolution (a space with no repos) exposes nothing and passes.
    final accessVia = op.repoAccessVia;
    if (accessVia != null && op.workspaceScoped && role != null) {
      final level = op.repoAccess!;
      final List<String> exposedRepos;
      try {
        exposedRepos = await accessVia(ctx);
      } catch (e, st) {
        return _mapHandlerError(id, opName, e, st);
      }
      for (final repoId in exposedRepos) {
        if (!role.isAdmin) {
          final verdict = await _checkRepoGrant(
            workspaceId: workspaceId!,
            userId: userId,
            roleDefinition: roleDefinition,
            permission: op.permission,
            repoId: repoId,
            level: level,
          );
          if (!verdict.allowed) {
            CcHostLog.warning(
              'Denying repo/call "$opName" for $userId@$deviceId — '
              '${verdict.reason} (repo $repoId)',
            );
            _auditDecision(
              workspaceId: workspaceId,
              userId: userId,
              deviceId: deviceId,
              op: op,
              allowed: false,
              sourceScope: verdict.source.name,
              reason: '${verdict.reason} (repo $repoId)',
              ip: remoteAddress,
            );
            return _error(
              id,
              RpcErrorCodes.unauthorized,
              'No ${level.wireName} access to a repository this operation '
              'exposes',
              data: repoGrantRequiredData(level),
            );
          }
        }
        final refused = await _refuseWithoutForgeRead(
          id: id,
          op: op,
          workspaceId: workspaceId!,
          userId: userId,
          deviceId: deviceId,
          repoId: repoId,
          ip: remoteAddress,
        );
        if (refused != null) {
          return refused;
        }
      }
    }

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
    // action key claims it in the ledger BEFORE anything else runs, so a
    // double-click / reconnect replay / offline flush collapses to one apply
    // and never re-enters feature code. A completed key replays its stored
    // result byte-identically, flagged `deduplicated: true`; a key another call
    // still holds is refused rather than run a second time alongside it.
    final rawKey = params['idempotency_key'];
    final ledger = writeLedger;
    final dedupe =
        op.kind != RepoOpKind.read &&
        ledger != null &&
        workspaceId != null &&
        rawKey is String &&
        rawKey.isNotEmpty;
    if (!dedupe) {
      return _guardAndRun(
        id: id,
        op: op,
        ctx: ctx,
        args: args,
        workspaceId: workspaceId,
        userId: userId,
        deviceId: deviceId,
        remoteAddress: remoteAddress,
        isCancelled: isCancelled,
      );
    }
    final WriteLedgerClaim claim;
    try {
      claim = await ledger.claim(
        workspaceId: workspaceId,
        key: rawKey,
        opName: op.name,
      );
    } catch (e, st) {
      return _mapHandlerError(id, opName, e, st);
    }
    switch (claim) {
      case LedgerReplay(:final data):
        return {
          'jsonrpc': '2.0',
          'id': id,
          'result': {'op': op.name, 'data': data, 'deduplicated': true},
        };
      case LedgerInProgress():
        return _error(
          id,
          RpcErrorCodes.conflict,
          'This action is already running',
          data: const {'kind': idempotencyInProgressKind},
        );
      case LedgerClaimed():
        break;
    }
    // This call owns the key. Every way out releases it except a completed
    // apply, so a refusal or a failed handler leaves the key free to retry.
    var completed = false;
    try {
      return await _guardAndRun(
        id: id,
        op: op,
        ctx: ctx,
        args: args,
        workspaceId: workspaceId,
        userId: userId,
        deviceId: deviceId,
        remoteAddress: remoteAddress,
        isCancelled: isCancelled,
        onApplied: (data) async {
          try {
            completed = await ledger.complete(
              workspaceId: workspaceId,
              key: rawKey,
              data: data,
            );
          } catch (e) {
            // The op is applied; a failed record only means a later retry
            // re-applies (degradation, not corruption), so it never fails the
            // call. The claim is released below for that retry.
            CcHostLog.warning(
              'write-ledger complete for ${op.name} failed: ${_describe(e)}',
            );
          }
        },
      );
    } finally {
      if (!completed) {
        try {
          await ledger.release(workspaceId: workspaceId, key: rawKey);
        } catch (e) {
          CcHostLog.warning(
            'write-ledger release for ${op.name} failed: ${_describe(e)}',
          );
        }
      }
    }
  }

  /// Runs the action-policy and approval gates, then the handler, then the
  /// audit trail. [onApplied] sees the handler's result before the answer is
  /// built (the idempotency ledger completes its claim there).
  Future<Map<String, dynamic>> _guardAndRun({
    required dynamic id,
    required RepoOp op,
    required RepoOpContext ctx,
    required Map<String, dynamic> args,
    required String? workspaceId,
    required String userId,
    required String deviceId,
    required String? remoteAddress,
    required bool Function()? isCancelled,
    Future<void> Function(Map<String, dynamic> data)? onApplied,
  }) async {
    final opName = op.name;

    // Unified action-guardrail effect net (PRD 24 §3) — the same resolver the
    // MCP dispatcher applies, now covering the operator's own repo-RPC clicks.
    // A mutating op that declares effect classes is resolved against the
    // workspace action policy: allow proceeds and deny refuses with a terminal
    // reason. Reads and effect-free ops (empty actionClasses) skip it. Dry-run
    // and deduplicated replays return before this, so it never re-checks them.
    //
    // Repo-RPC callers are always HUMAN (agents act via MCP), so agentId is null
    // and only space/workspace/preset scopes resolve — and `operatorInitiated`
    // is set. That is what makes `prompt` proceed here: the whole taxonomy
    // governs AGENT-initiated effects, and a confirmation for a repo/call would
    // pop on the very operator who just pressed "create pull request" (the
    // pending-confirmation registry has no notion of a second approver — it
    // broadcasts to whoever is connected, which includes them). `deny` is NOT
    // waived: a rule that forbids an effect forbids it however it was started.
    final guard = actionGuard;
    if (guard != null && op.actionClasses.isNotEmpty && workspaceId != null) {
      final spaceArg = args['space_id'] ?? args['conversation_id'];
      final verdict = await guard.check(
        workspaceId: workspaceId,
        classes: op.actionClasses,
        spaceId: spaceArg is String ? spaceArg : null,
        actionSummary: op.name,
        operatorInitiated: true,
      );
      if (!verdict.allowed) {
        CcHostLog.warning(
          'Denying repo/call "$opName" for $userId@$deviceId — action policy: '
          '${verdict.reason}',
        );
        // The guard service audits its own verdict on the agent lane; this
        // row records the HUMAN whose click was refused.
        _auditDecision(
          workspaceId: workspaceId,
          userId: userId,
          deviceId: deviceId,
          op: op,
          allowed: false,
          sourceScope: verdict.source ?? 'action_policy',
          reason: verdict.reason,
          ip: remoteAddress,
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

    if (op.kind == RepoOpKind.read && isCancelled?.call() == true) {
      return _error(id, RpcErrorCodes.requestCancelled, 'Request cancelled');
    }

    try {
      final data = await op.handler(ctx);
      await onApplied?.call(data);
      if (op.kind != RepoOpKind.read &&
          op.audited &&
          workspaceId != null &&
          (op.auditWhen == null || op.auditWhen!(args, data))) {
        // Two trails, one call. `user_activity` is the product's timeline of
        // what a person did; `guard_decisions` is the tamper-evident record
        // of the authorization verdict behind it. They share a correlation id
        // so an investigation can read one call across both.
        final correlationId = _nextDiagnosticId();
        _auditDecision(
          workspaceId: workspaceId,
          userId: userId,
          deviceId: deviceId,
          op: op,
          allowed: true,
          sourceScope: 'role',
          ip: ctx.remoteAddress,
          correlationId: correlationId,
        );
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
          details: auditDetailsOf(args: args, result: data),
        );
        if (audit != null) {
          unawaited(
            audit.then<void>(
              (_) {},
              onError: (Object e) {
                CcHostLog.warning(
                  'audit append for ${op.name} failed: ${_describe(e)}',
                );
              },
            ),
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

  /// Records one [serverAudited] call through [recordServerAudit], fire and
  /// forget: a slow or failed write never changes or delays the answer. The
  /// outcome is read off the answer itself, so every return path is covered:
  /// a result is `ok`, an authorization refusal `denied`, anything else
  /// `failed`.
  void _auditServerCall({
    required RepoOp op,
    required Map<String, dynamic> args,
    required Map<String, dynamic> response,
    required String userId,
    required String deviceId,
    required String? ip,
  }) {
    final error = response['error'];
    final outcome = error is! Map
        ? 'ok'
        : error['code'] == RpcErrorCodes.unauthorized
        ? 'denied'
        : 'failed';
    final write = recordServerAudit?.call(
      userId: userId,
      deviceId: deviceId,
      op: op.name,
      argNames: args.keys.toList(),
      outcome: outcome,
      ip: ip,
    );
    if (write != null) {
      unawaited(
        write.then<void>(
          (_) {},
          onError: (Object e) {
            CcHostLog.warning(
              'server audit append for ${op.name} failed: ${_describe(e)}',
            );
          },
        ),
      );
    }
  }

  /// Emits one authorization row into the audit spine (best effort: a failed
  /// audit must never change a verdict).
  void _auditDecision({
    required String? workspaceId,
    required String userId,
    required String deviceId,
    required RepoOp op,
    required bool allowed,
    required String sourceScope,
    String? reason,
    String? ip,
    String? correlationId,
  }) {
    final sink = recordGuardDecision;
    if (sink == null || workspaceId == null) {
      return;
    }
    sink(
      workspaceId: workspaceId,
      userId: userId,
      deviceId: deviceId,
      opName: op.name,
      permission: op.permission.wire,
      allowed: allowed,
      sourceScope: sourceScope,
      reason: reason,
      ip: ip,
      correlationId: correlationId,
      actionClasses: [for (final c in op.actionClasses) c.wire],
    );
  }

  /// The error frame refusing [op] when [requireForgeRead] refuses [userId]
  /// the code of [repoId], audited like a grant refusal; null when it passes.
  Future<Map<String, dynamic>?> _refuseWithoutForgeRead({
    required dynamic id,
    required RepoOp op,
    required String workspaceId,
    required String userId,
    required String deviceId,
    required String repoId,
    required String? ip,
  }) async {
    final gate = requireForgeRead;
    if (gate == null) {
      return null;
    }
    try {
      await gate(workspaceId, userId, repoId);
      return null;
    } catch (e, st) {
      CcHostLog.warning(
        'Denying repo/call "${op.name}" for $userId@$deviceId — their forge '
        'sign-in cannot read repo $repoId (${e.runtimeType})',
      );
      _auditDecision(
        workspaceId: workspaceId,
        userId: userId,
        deviceId: deviceId,
        op: op,
        allowed: false,
        sourceScope: 'forge',
        reason: 'Forge sign-in cannot read the repository (repo $repoId)',
        ip: ip,
      );
      return _mapHandlerError(id, op.name, e, st);
    }
  }

  /// Resolves ONE repo's grant and answers it through the permission
  /// resolver, so the repo gate and the role gate share a decision point (and
  /// a single definition of "admins hold every grant implicitly").
  ///
  /// Grants are fetched per repo rather than as a map up front: an op exposes
  /// at most a handful, and loading a member's whole grant set on every call
  /// would be a read the old gate never paid for.
  Future<PermissionVerdict> _checkRepoGrant({
    required String workspaceId,
    required String userId,
    required RoleDefinition? roleDefinition,
    required Permission permission,
    required String repoId,
    required RepoGrantLevel level,
  }) async {
    final grant =
        await (resolveRepoGrant?.call(workspaceId, userId, repoId) ??
            Future.value(RepoGrantLevel.none));
    return _permissions.can(
      PermissionPrincipal(
        userId: userId,
        role: roleDefinition,
        repoGrants: {repoId: grant},
      ),
      permission,
      resource: ResourceRef.repo(repoId, level: level),
    );
  }

  /// The log-safe rendering of [e] ([describeError], else its type).
  String _describe(Object e) =>
      describeError?.call(e) ?? e.runtimeType.toString();

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
    // The error object itself is not handed to the log: its text may carry
    // bound statement values; [_describe] is the only rendering logged.
    final diagnosticId = _nextDiagnosticId();
    CcHostLog.error(
      'repo/call $opName threw [$diagnosticId]: ${_describe(e)}',
      null,
      st,
    );
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

  /// Best-effort audit target id from conventional arg names. More-specific
  /// entity ids win (`rig_id`, `session_id`, `key`) so a destroy names the
  /// machine rather than falling through to a space; `path` and `name` trail
  /// the id forms: a real identifier, then a filesystem path, then a display
  /// name. The space a thing lived in rides on `details`, not here.
  static String? _targetIdOf(Map<String, dynamic> args) {
    for (final key in const [
      'id',
      'ticket_id',
      'rig_id',
      'session_id',
      'key',
      'image_id',
      'feed_id',
      'article_id',
      'meeting_id',
      'event_id',
      'pr_id',
      'plan_id',
      'template_id',
      'trigger_id',
      'goal_id',
      'project_id',
      'team_id',
      'member_id',
      'skill_id',
      'fact_id',
      'space_id',
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
