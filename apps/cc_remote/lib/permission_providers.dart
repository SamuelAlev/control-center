import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/features/guardrails/domain/entities/action_policy_rule.dart';
import 'package:cc_remote/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final permissionRulesProvider =
    StreamProvider.family<List<ActionPolicyRule>, String>((
      ref,
      workspaceId,
    ) async* {
      final client = await ref.watch(rpcClientProvider.future);
      yield* RpcActionPolicyRepository(client).watchRules(workspaceId);
    });

/// Audit entries remain server decisions; never recompute their verdict locally.
class PermissionAuditEntry {
  const PermissionAuditEntry({
    required this.actor,
    required this.action,
    required this.decision,
    required this.occurredAt,
    this.onBehalfOf,
    this.prompted = false,
    this.surface,
    this.scope,
    this.permission,
    this.classes = const [],
  });

  factory PermissionAuditEntry.fromJson(Map<String, dynamic> data) =>
      PermissionAuditEntry(
        actor: data['actor_id'] as String? ?? '',
        onBehalfOf: data['on_behalf_of_user_id'] as String?,
        prompted: data['prompted'] == true,
        action: data['action_name'] as String? ?? '',
        decision: data['decision'] as String? ?? '',
        occurredAt: DateTime.parse(data['occurred_at'] as String),
        surface: data['surface'] as String?,
        scope: data['source_scope'] as String?,
        permission: data['permission'] as String?,
        classes: [
          for (final value in data['action_classes'] as List? ?? const [])
            value.toString(),
        ],
      );

  final String actor;
  final String? onBehalfOf;
  final bool prompted;
  final String action;
  final String decision;
  final DateTime occurredAt;
  final String? surface;
  final String? scope;
  final String? permission;
  final List<String> classes;
}

final permissionAuditProvider =
    StreamProvider.family<List<PermissionAuditEntry>, String>((
      ref,
      workspaceId,
    ) async* {
      final client = await ref.watch(rpcClientProvider.future);
      yield* client
          .subscribe('audit.watchRecent', {'workspace_id': workspaceId})
          .map((data) {
            final rows = data['decisions'];
            if (rows is! List) {
              throw const FormatException('Missing audit decisions');
            }
            return [
              for (final value in rows)
                PermissionAuditEntry.fromJson(
                  (value as Map).cast<String, dynamic>(),
                ),
            ];
          });
    });

class PermissionChainResult {
  const PermissionChainResult(
    this.intact,
    this.rowsChecked,
    this.brokenAtSeq,
    this.reason,
  );
  final bool intact;
  final int rowsChecked;
  final int? brokenAtSeq;
  final String? reason;
}

Future<PermissionChainResult> verifyPermissionChain(
  WidgetRef ref,
  String workspaceId,
) async {
  final client = await ref.read(rpcClientProvider.future);
  final result = await client.call('audit.verifyChain', {
    'workspace_id': workspaceId,
  });
  return PermissionChainResult(
    result['intact'] == true,
    (result['rows_checked'] as num).toInt(),
    (result['broken_at_seq'] as num?)?.toInt(),
    result['reason'] as String?,
  );
}
