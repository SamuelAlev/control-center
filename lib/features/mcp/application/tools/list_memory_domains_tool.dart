import 'dart:convert';

import 'package:control_center/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:control_center/features/memory/domain/repositories/memory_domain_repository.dart';
import 'package:control_center/features/memory/domain/repositories/memory_fact_repository.dart';
import 'package:control_center/features/memory/domain/repositories/memory_policy_repository.dart';

class ListMemoryDomainsTool extends McpTool {
  ListMemoryDomainsTool({
    required MemoryDomainRepository domainRepository,
    required MemoryFactRepository factRepository,
    required MemoryPolicyRepository policyRepository,
  })  : _domainRepository = domainRepository,
        _factRepository = factRepository,
        _policyRepository = policyRepository;

  final MemoryDomainRepository _domainRepository;
  final MemoryFactRepository _factRepository;
  final MemoryPolicyRepository _policyRepository;

  @override
  String get name => 'list_memory_domains';

  @override
  String get description =>
      'Lists all memory domains in the workspace with fact and policy counts. '
      'Call this before proposing facts or policies to discover existing domains.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'workspace_id': {'type': 'string', 'description': 'The workspace ID.'},
    },
    'required': ['workspace_id'],
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final workspaceId = arguments['workspace_id'];
    if (workspaceId is! String) {
      return CallResult.error('Missing workspace_id');
    }

    final domains = await _domainRepository.getByWorkspace(workspaceId);
    final facts = await _factRepository.getByWorkspace(workspaceId);
    final policies = await _policyRepository.getActiveByWorkspace(workspaceId);

    final result = domains.map((d) {
      final factCount = facts.where((f) => f.domain == d.name && !f.isSuperseded).length;
      final policyCount = policies.where((p) => p.domain == d.name).length;
      return {
        'name': d.name,
        'label': d.label,
        'description': d.description,
        'fact_count': factCount,
        'policy_count': policyCount,
      };
    }).toList();

    return CallResult.success(jsonEncode({'domains': result}));
  }
}
