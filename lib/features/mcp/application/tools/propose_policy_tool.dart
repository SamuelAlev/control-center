import 'dart:convert';

import 'package:control_center/core/domain/services/memory_access_policy.dart';
import 'package:control_center/core/domain/value_objects/agent_role.dart';
import 'package:control_center/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:control_center/features/memory/domain/usecases/promote_facts_to_policy_use_case.dart';
import 'package:control_center/features/memory/domain/usecases/resolve_or_create_domain_use_case.dart';

class ProposePolicyTool extends McpTool {
  ProposePolicyTool({
    required PromoteFactsToPolicyUseCase useCase,
    required ResolveOrCreateDomainUseCase resolveDomainUseCase,
  })  : _useCase = useCase,
        _resolveDomainUseCase = resolveDomainUseCase;

  final PromoteFactsToPolicyUseCase _useCase;
  final ResolveOrCreateDomainUseCase _resolveDomainUseCase;

  @override
  String get name => 'propose_policy';

  @override
  String get description =>
      'Stores a policy (a normative rule) in shared workspace memory. '
      'Requires write permission on the domain.\n\n'
      'Shape: `domain` (kebab-case category slug), `rule` (the markdown '
      'statement of the policy itself).\n\n'
      'Example call:\n'
      '  { "workspace_id": "ws_123",\n'
      '    "domain": "auth-flow",\n'
      '    "rule": "All session tokens MUST be rotated on each refresh; '
      'never reuse a refresh token.",\n'
      '    "source_fact_ids": ["fact_abc", "fact_def"] }\n\n'
      'Always call `list_memory_domains` first to reuse an existing '
      'domain. Only invent a new domain when nothing fits.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'workspace_id': {'type': 'string', 'description': 'The workspace ID.'},
      'domain': {
        'type': 'string',
        'description':
            'REQUIRED. Kebab-case category slug, e.g. "auth-flow", '
            '"api-design", "deployment". Call list_memory_domains first '
            'to reuse an existing one.',
      },
      'domain_label': {
        'type': 'string',
        'description':
            'Human-readable label for a *new* domain. Ignored when the '
            'domain already exists.',
      },
      'domain_description': {
        'type': 'string',
        'description':
            'One-line description for a *new* domain. Ignored when the '
            'domain already exists.',
      },
      'rule': {
        'type': 'string',
        'description':
            'The policy rule in markdown — a normative statement '
            '("teams MUST/SHOULD/MUST NOT…"). NOT a subject/object pair; '
            'rule is the full sentence on its own.',
      },
      'source_fact_ids': {
        'type': 'array',
        'items': {'type': 'string'},
        'description':
            'IDs of facts (from propose_fact) that support this policy. '
            'Optional but recommended for traceability.',
      },
      'agent_role': {
        'type': 'string',
        'description':
            'Role of the proposing agent. Determines whether you have '
            'write permission on the domain.',
      },
    },
    'required': ['workspace_id', 'domain', 'rule'],
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final workspaceId = arguments['workspace_id'];
    final domainInput = arguments['domain'];
    final rule = arguments['rule'];
    if (workspaceId is! String) {
      return CallResult.error('Missing workspace_id');
    }
    if (domainInput is! String || domainInput.isEmpty) {
      return CallResult.error(
        'Missing domain. Pick a short kebab-case slug for the policy area '
        '(e.g. "api-design", "auth-flow"). Call list_memory_domains to see existing domains.',
      );
    }
    if (rule is! String) {
      return CallResult.error('Missing rule');
    }

    final sourceFactIds = (arguments['source_fact_ids'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    final agentRole =
        AgentRole.tryParse(arguments['agent_role'] as String?) ?? AgentRole.general;
    final domainLabel = arguments['domain_label'] as String?;
    final domainDescription = arguments['domain_description'] as String?;

    try {
      final domain = await _resolveDomainUseCase.execute(
        workspaceId: workspaceId,
        domainInput: domainInput,
        domainLabel: domainLabel,
        domainDescription: domainDescription,
        authorRole: agentRole,
      );

      final policy = await _useCase.execute(
        workspaceId: workspaceId,
        domain: domain.name,
        rule: rule,
        sourceFactIds: sourceFactIds,
        authorRole: agentRole,
      );

      if (policy == null) {
        return CallResult.error('Failed to create policy');
      }

      return CallResult.success(jsonEncode({
        'policy_id': policy.id,
        'domain': domain.name,
        'status': 'created',
      }));
    } on InsufficientMemoryPermission catch (e) {
      return CallResult.error(
        'InsufficientMemoryPermission: ${e.agentRole.name} cannot write to ${e.domain}',
      );
    }
  }
}
