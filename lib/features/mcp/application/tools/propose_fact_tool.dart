import 'dart:convert';

import 'package:control_center/core/domain/entities/memory_fact.dart';
import 'package:control_center/core/domain/value_objects/agent_role.dart';
import 'package:control_center/core/utils/app_log.dart';
import 'package:control_center/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:control_center/features/memory/domain/repositories/memory_fact_repository.dart';
import 'package:control_center/features/memory/domain/usecases/resolve_or_create_domain_use_case.dart';
import 'package:uuid/uuid.dart';

/// MCP tool that stores a fact in shared workspace memory.
class ProposeFactTool extends McpTool {

  /// Creates a [ProposeFactTool].
  ProposeFactTool({
    required MemoryFactRepository repository,
    required ResolveOrCreateDomainUseCase resolveDomainUseCase,
  })  : _repository = repository,
        _resolveDomainUseCase = resolveDomainUseCase;

  final MemoryFactRepository _repository;
  final ResolveOrCreateDomainUseCase _resolveDomainUseCase;

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

    AppLog.d(
      'propose_fact',
      'resolving domain workspace=$workspaceId input="$domainInput" role=${agentRole.name}',
    );
    final domain = await _resolveDomainUseCase.execute(
      workspaceId: workspaceId,
      domainInput: domainInput,
      domainLabel: domainLabel,
      domainDescription: domainDescription,
      authorRole: agentRole,
    );
    AppLog.d('propose_fact', 'resolved domain → ${domain.name}');

    // De-duplicate: if an active fact with the same domain + topic + content
    // already exists, reuse it rather than accumulating near-identical rows
    // (the librarian re-proposes facts across re-index runs). `supersede_fact`
    // still handles genuine updates/replacements.
    final trimmedContent = content.trim();
    final activeForTopic = await _repository.getActiveByTopic(workspaceId, topic);
    for (final existing in activeForTopic) {
      if (existing.domain == domain.name &&
          existing.content.trim() == trimmedContent) {
        AppLog.d('propose_fact', 'duplicate of ${existing.id}; skipping insert');
        return CallResult.success(jsonEncode({
          'fact_id': existing.id,
          'domain': domain.name,
          'topic': topic,
          'status': 'duplicate',
        }));
      }
    }

    final now = DateTime.now();
    final fact = MemoryFact(
      id: const Uuid().v4(),
      workspaceId: workspaceId,
      domain: domain.name,
      topic: topic,
      content: content,
      confidence: confidence.clamp(0.0, 1.0),
      authoredByAgentId: agentId,
      authoredByRole: agentRole,
      createdAt: now,
      updatedAt: now,
    );

    AppLog.d('propose_fact', 'upserting fact ${fact.id} topic="$topic"');
    await _repository.upsert(fact);
    AppLog.d('propose_fact', 'upsert complete ${fact.id}');

    return CallResult.success(jsonEncode({
      'fact_id': fact.id,
      'domain': domain.name,
      'topic': topic,
      'status': 'proposed',
    }));
  }
}
