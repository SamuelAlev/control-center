import 'dart:convert';

import 'package:cc_domain/core/domain/value_objects/agent_role.dart';
import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/memory/domain/usecases/record_memory_fact_use_case.dart';
import 'package:cc_domain/features/memory/domain/value_objects/memory_veracity.dart';
import 'package:cc_mcp/src/log/cc_mcp_log.dart';

/// MCP tool that stores a fact in shared workspace memory.
class ProposeFactTool extends McpTool {

  /// Creates a [ProposeFactTool].
  ProposeFactTool({
    required RecordMemoryFactUseCase recordFact,
  }) : _recordFact = recordFact;

  final RecordMemoryFactUseCase _recordFact;

  @override
  String get name => 'propose_fact';

  @override
  String get description =>
      'Stores a fact in shared workspace memory. NOT a triple store — '
      'facts here are short markdown observations grouped by domain.\n\n'
      'Shape: `domain` (kebab-case category slug), `topic` (a few-word '
      'headline), `content` (the body, markdown).\n\n'
      'Example call:\n'
      '  { "workspace_id": "ws_123",\n'
      '    "domain": "auth-flow",\n'
      '    "topic": "session token TTL",\n'
      '    "content": "Sessions expire after 30 days idle; '
      'refresh tokens rotate on each use." }\n\n'
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
            '"api-design", "deployment", "team-process". Call '
            'list_memory_domains first to reuse an existing one.',
      },
      'domain_label': {
        'type': 'string',
        'description':
            'Human-readable label for a *new* domain (e.g. "Auth Flow"). '
            'Ignored when the domain already exists.',
      },
      'domain_description': {
        'type': 'string',
        'description':
            'One-line description for a *new* domain. Ignored when the '
            'domain already exists.',
      },
      'topic': {
        'type': 'string',
        'description':
            'A few-word headline for this fact (NOT a predicate). '
            'Example: "session token TTL", "ci pipeline owner".',
      },
      'content': {
        'type': 'string',
        'description':
            'The fact body in markdown — one or two sentences stating '
            'the observation. NOT a value to pair with topic; '
            'topic+content together form a self-contained note.',
      },
      'confidence': {
        'type': 'number',
        'description': 'Confidence in this fact, 0–1 (default 1.0).',
      },
      'veracity': {
        'type': 'string',
        'enum': ['stated', 'inferred', 'tool', 'imported', 'unknown'],
        'description':
            'Provenance of this fact (default "stated"). Drives Bayesian '
            'confidence weighting: "stated" (user-asserted) outranks "tool" '
            '(tool-observed) on a conflict tie.',
      },
      'agent_id': {
        'type': 'string',
        'description': 'Id of the agent proposing this fact.',
      },
      'agent_role': {
        'type': 'string',
        'description':
            'Role of the proposing agent (e.g. "coder", "reviewer", '
            '"security"). Determines write permissions when the domain '
            'is created.',
      },
    },
    'required': ['workspace_id', 'domain', 'topic', 'content'],
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final workspaceId = arguments['workspace_id'];
    final domainInput = arguments['domain'];
    final topic = arguments['topic'];
    final content = arguments['content'];
    if (workspaceId is! String) {
      return CallResult.error('Missing workspace_id');
    }
    if (domainInput is! String || domainInput.isEmpty) {
      return CallResult.error(
        'Missing domain. Pick a short kebab-case slug that categorizes this fact '
        '(e.g. "api-design", "auth-flow"). Call list_memory_domains to see existing domains.',
      );
    }
    if (topic is! String) {
      return CallResult.error('Missing topic');
    }
    if (content is! String) {
      return CallResult.error('Missing content');
    }

    final confidence = (arguments['confidence'] as num?)?.toDouble() ?? 1.0;
    final agentId = arguments['agent_id'] as String?;
    final agentRole = AgentRole.tryParse(arguments['agent_role'] as String?) ?? AgentRole.general;
    final domainLabel = arguments['domain_label'] as String?;
    final domainDescription = arguments['domain_description'] as String?;
    final veracity = MemoryVeracity.parse(arguments['veracity'] as String?);

    CcMcpLog.d(
      'propose_fact',
      'recording workspace=$workspaceId domain="$domainInput" role=${agentRole.name}',
    );
    // Delegate to the shared writer: domain resolution + dedup (Bayesian
    // re-mention) + typed classification + conflict supersession + episodic
    // linking all happen identically here and in the harvest paths.
    final result = await _recordFact.record(
      workspaceId: workspaceId,
      domain: domainInput,
      topic: topic,
      content: content,
      confidence: confidence,
      authoredByAgentId: agentId,
      authorRole: agentRole,
      domainLabel: domainLabel,
      domainDescription: domainDescription,
      veracity: veracity,
    );
    if (result == null) {
      return CallResult.error('Content is empty.');
    }
    final status = switch (result.outcome) {
      RecordOutcome.created => 'proposed',
      RecordOutcome.deduplicated => 'duplicate',
      RecordOutcome.supersededByConflict => 'superseded_by_conflict',
    };
    CcMcpLog.d('propose_fact', 'recorded ${result.fact.id} status=$status');

    return CallResult.success(jsonEncode({
      'fact_id': result.fact.id,
      'domain': result.fact.domain,
      'topic': topic,
      'memory_type': result.fact.memoryType.wireName,
      'status': status,
      if (result.conflictsDetected > 0)
        'conflicts_resolved': result.conflictsDetected,
    }));
  }
}
