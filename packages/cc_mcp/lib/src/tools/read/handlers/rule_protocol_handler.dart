import 'dart:convert';

import 'package:cc_domain/core/domain/entities/memory_policy.dart' show MemoryPolicy;
import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_policy_repository.dart';
import 'package:cc_mcp/src/tools/read/internal_url.dart';
import 'package:cc_mcp/src/tools/read/internal_url_router.dart';

/// Handles `rule://<name>` URLs by reading the matching
/// [MemoryPolicy.rule] from the database.
class RuleProtocolHandler {
  /// Creates a [RuleProtocolHandler].
  RuleProtocolHandler({required MemoryPolicyRepository policies})
    : _policies = policies;

  final MemoryPolicyRepository _policies;

  /// Resolves [url] by looking up the policy by domain.
  Future<CallResult> handle(RuleUrl url, ReadContext context) async {
    final workspaceId = context.workspaceId;
    if (workspaceId == null) {
      return CallResult.error(
        'rule:// requires a workspace_id context',
      );
    }

    final name = url.name;
    final matches = await _policies.getActiveByWorkspace(
      workspaceId,
      domain: name,
    );

    if (matches.isEmpty) {
      return CallResult.error(
        'Rule not found: $name in workspace $workspaceId',
      );
    }

    final rules = matches.map((p) => {
      'id': p.id,
      'domain': p.domain,
      'rule': p.rule,
      'active': p.active,
      'required_role': p.requiredRole?.name,
    }).toList();

    return CallResult.success(
      jsonEncode({'rules': rules, 'count': rules.length}),
    );
  }
}
