import 'package:cc_rpc/cc_rpc.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One authorization decision as the audit surface renders it.
///
/// A thin view of the server's `guard_decisions` row: the client never
/// re-derives a verdict, it displays the one the server recorded.
class AuditDecisionView {
  /// Creates an [AuditDecisionView].
  const AuditDecisionView({
    required this.id,
    required this.seq,
    required this.occurredAt,
    required this.actorType,
    required this.actorId,
    required this.surface,
    required this.actionName,
    required this.decision,
    this.onBehalfOfUserId,
    this.permission,
    this.sourceScope,
    this.actionClasses = const [],
    this.prompted = false,
    this.entryHash = '',
    this.kind = 'decision',
  });

  /// Decodes one wire entry.
  factory AuditDecisionView.fromJson(Map<String, dynamic> json) =>
      AuditDecisionView(
        id: json['id'] as String? ?? '',
        seq: (json['seq'] as num?)?.toInt() ?? 0,
        occurredAt:
            DateTime.tryParse(json['occurred_at'] as String? ?? '')?.toLocal() ??
            DateTime.now(),
        actorType: json['actor_type'] as String? ?? 'user',
        actorId: json['actor_id'] as String? ?? '',
        onBehalfOfUserId: json['on_behalf_of_user_id'] as String?,
        surface: json['surface'] as String? ?? '',
        actionName: json['action_name'] as String? ?? '',
        permission: json['permission'] as String?,
        sourceScope: json['source_scope'] as String?,
        decision: json['decision'] as String? ?? 'allow',
        actionClasses: [
          for (final c in (json['action_classes'] as List? ?? const []))
            c.toString(),
        ],
        prompted: json['prompted'] == true,
        entryHash: json['entry_hash'] as String? ?? '',
        kind: json['kind'] as String? ?? 'decision',
      );

  /// Row id.
  final String id;

  /// Position in the workspace's hash chain.
  final int seq;

  /// When the decision was made (local time).
  final DateTime occurredAt;

  /// `user` | `agent` | `system`.
  final String actorType;

  /// The acting principal.
  final String actorId;

  /// The human an agent acted for.
  final String? onBehalfOfUserId;

  /// Which chokepoint decided.
  final String surface;

  /// The op/tool that was gated.
  final String actionName;

  /// The derived permission, for human-lane rows.
  final String? permission;

  /// Which scope decided.
  final String? sourceScope;

  /// `allow` | `prompt` | `deny`.
  final String decision;

  /// The effect classes involved.
  final List<String> actionClasses;

  /// Whether a human was asked.
  final bool prompted;

  /// This row's chain hash.
  final String entryHash;

  /// `decision` or `checkpoint`.
  final String kind;

  /// Whether this row records a refusal.
  bool get isDeny => decision == 'deny';
}

/// The active workspace's recent authorization decisions (live).
final auditDecisionsProvider = StreamProvider<List<AuditDecisionView>>((ref) {
  final workspaceId = ref.watch(activeWorkspaceIdProvider);
  if (workspaceId == null) {
    return Stream.value(const []);
  }
  return ref
      .watch(rpcClientProvider)
      .subscribe('audit.watchRecent', {'workspace_id': workspaceId})
      .map((data) {
        final raw = data['decisions'];
        return [
          for (final e in raw is List ? raw : const [])
            if (e is Map) AuditDecisionView.fromJson(e.cast<String, dynamic>()),
        ];
      });
});

/// The result of asking the server to re-derive its own chain hashes.
class ChainVerificationView {
  /// Creates a [ChainVerificationView].
  const ChainVerificationView({
    required this.rowsChecked,
    required this.intact,
    this.brokenAtSeq,
    this.reason,
  });

  /// How many rows were verified.
  final int rowsChecked;

  /// Whether every link held.
  final bool intact;

  /// The first sequence whose link failed.
  final int? brokenAtSeq;

  /// Why it failed.
  final String? reason;
}

/// Re-verifies the workspace's audit chain end to end.
Future<ChainVerificationView> verifyAuditChain(
  RemoteRpcClient client, {
  required String workspaceId,
}) async {
  final data = await client.call('audit.verifyChain', {
    'workspace_id': workspaceId,
  });
  return ChainVerificationView(
    rowsChecked: (data['rows_checked'] as num?)?.toInt() ?? 0,
    intact: data['intact'] == true,
    brokenAtSeq: (data['broken_at_seq'] as num?)?.toInt(),
    reason: data['reason'] as String?,
  );
}

/// Applies a named policy template to the workspace.
Future<int> applyPolicyTemplate(
  RemoteRpcClient client, {
  required String workspaceId,
  required String template,
}) async {
  final data = await client.call('action_policy.applyTemplate', {
    'workspace_id': workspaceId,
    'template': template,
  });
  return (data['applied'] as num?)?.toInt() ?? 0;
}

/// Exports the workspace's guardrail posture as portable JSON.
Future<List<dynamic>> exportPolicy(
  RemoteRpcClient client, {
  required String workspaceId,
}) async {
  final data = await client.call('action_policy.export', {
    'workspace_id': workspaceId,
  });
  final policy = data['policy'];
  return policy is List ? policy : const [];
}

/// Imports a previously exported posture into the workspace.
Future<int> importPolicy(
  RemoteRpcClient client, {
  required String workspaceId,
  required List<dynamic> policy,
}) async {
  final data = await client.call('action_policy.import', {
    'workspace_id': workspaceId,
    'policy': policy,
  });
  return (data['imported'] as num?)?.toInt() ?? 0;
}

/// A custom (subtractive) workspace role as the client renders it.
class CustomRoleView {
  /// Creates a [CustomRoleView].
  const CustomRoleView({
    required this.id,
    required this.name,
    required this.basePreset,
    required this.wire,
    this.deniedPermissions = const [],
  });

  /// Decodes one wire entry.
  factory CustomRoleView.fromJson(Map<String, dynamic> json) => CustomRoleView(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    basePreset: json['base_preset'] as String? ?? 'guest',
    wire: json['wire'] as String? ?? '',
    deniedPermissions: [
      for (final p in (json['denied_permissions'] as List? ?? const []))
        p.toString(),
    ],
  );

  /// Row id.
  final String id;

  /// Display name.
  final String name;

  /// The preset this role restricts.
  final String basePreset;

  /// The value stored on a membership (`custom:<id>`).
  final String wire;

  /// The permissions removed from the base preset.
  final List<String> deniedPermissions;
}

/// The active workspace's custom roles (live).
///
/// Empty when the install has no custom-role entitlement or the op is absent,
/// so the members picker simply shows the built-in presets.
final workspaceCustomRolesProvider = StreamProvider<List<CustomRoleView>>((
  ref,
) {
  final workspaceId = ref.watch(activeWorkspaceIdProvider);
  if (workspaceId == null) {
    return Stream.value(const []);
  }
  return ref
      .watch(rpcClientProvider)
      .subscribe('roles.watchForWorkspace', {'workspace_id': workspaceId})
      .map((data) {
        final raw = data['roles'];
        return [
          for (final e in raw is List ? raw : const [])
            if (e is Map) CustomRoleView.fromJson(e.cast<String, dynamic>()),
        ];
      })
      .handleError((Object _) {})
      .cast<List<CustomRoleView>>();
});

/// Assigns a custom role (`custom:<id>`) to a member.
Future<void> assignCustomRole(
  RemoteRpcClient client, {
  required String workspaceId,
  required String userId,
  required String roleWire,
}) => client.call('roles.assign', {
  'workspace_id': workspaceId,
  'user_id': userId,
  'role': roleWire,
});
