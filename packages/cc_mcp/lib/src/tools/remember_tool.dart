import 'dart:convert';

import 'package:cc_domain/core/domain/entities/working_memory_item.dart';
import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/memory/domain/repositories/working_memory_item_repository.dart';
import 'package:cc_domain/features/memory/domain/usecases/extract_memory_use_case.dart';
import 'package:cc_domain/features/memory/domain/value_objects/memory_type.dart';
import 'package:cc_domain/features/memory/domain/value_objects/memory_veracity.dart';
import 'package:uuid/uuid.dart';

/// MCP tool that writes an item to the agent's hot working-memory tier. A
/// consolidation pass later rolls consolidatable items into durable facts.
///
/// With `extract: true`, the content is also passively mined for facts /
/// preferences / instructions, which are recorded immediately as durable facts.
class RememberTool extends McpTool {
  /// Creates a [RememberTool].
  RememberTool({
    required WorkingMemoryItemRepository workingMemory,
    ExtractMemoryUseCase? extractMemory,
  })  : _working = workingMemory,
        _extractMemory = extractMemory;

  final WorkingMemoryItemRepository _working;
  final ExtractMemoryUseCase? _extractMemory;

  static const _uuid = Uuid();

  @override
  String get name => 'remember';

  @override
  String get description =>
      'Adds a note to your hot working memory for the current session. '
      'Bounded (TTL + count): a later consolidation pass rolls durable items '
      '(facts, decisions, learnings, preferences) into long-term memory and '
      'evicts the rest. Set "extract": true to also mine the text for facts, '
      'preferences, and instructions and store them durably right away.';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'workspace_id': {'type': 'string', 'description': 'The workspace ID.'},
          'agent_id': {'type': 'string', 'description': 'Your agent ID.'},
          'content': {'type': 'string', 'description': 'The note to remember.'},
          'memory_type': {
            'type': 'string',
            'description':
                'Type of memory (e.g. "observation", "decision", "learning", '
                '"preference"). Default "observation".',
          },
          'session_id': {
            'type': 'string',
            'description': 'Optional session/run id to group items.',
          },
          'importance': {
            'type': 'number',
            'description': 'Importance 0–1 (default 0.5); higher survives '
                'eviction longer.',
          },
          'ttl_hours': {
            'type': 'number',
            'description': 'Optional time-to-live in hours before eviction.',
          },
          'extract': {
            'type': 'boolean',
            'description':
                'When true, also extract durable facts from the content now.',
          },
        },
        'required': ['workspace_id', 'agent_id', 'content'],
      };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final workspaceId = arguments['workspace_id'];
    final agentId = arguments['agent_id'];
    final content = arguments['content'];
    if (workspaceId is! String) {
      return CallResult.error('Missing or invalid argument: workspace_id');
    }
    if (agentId is! String) {
      return CallResult.error('Missing or invalid argument: agent_id');
    }
    if (content is! String || content.trim().isEmpty) {
      return CallResult.error('Missing or invalid argument: content');
    }

    final type = MemoryType.parse(arguments['memory_type'] as String?);
    final importance = (arguments['importance'] as num?)?.toDouble() ?? 0.5;
    final sessionId = arguments['session_id'] as String?;
    final ttlHours = (arguments['ttl_hours'] as num?)?.toDouble();
    final now = DateTime.now();
    final id = _uuid.v4();

    await _working.add(
      WorkingMemoryItem(
        id: id,
        workspaceId: workspaceId,
        agentId: agentId,
        content: content,
        sessionId: sessionId,
        memoryType: type,
        veracity: MemoryVeracity.inferred,
        importance: importance.clamp(0.0, 1.0),
        createdAt: now,
        expiresAt:
            ttlHours == null ? null : now.add(Duration(minutes: (ttlHours * 60).round())),
      ),
    );

    var extracted = 0;
    if (arguments['extract'] == true && _extractMemory != null) {
      extracted = await _extractMemory.extractAndRecord(
        workspaceId: workspaceId,
        text: content,
        authoredByAgentId: agentId,
      );
    }

    return CallResult.success(jsonEncode({
      'item_id': id,
      'memory_type': type.wireName,
      'status': 'remembered',
      if (extracted > 0) 'facts_extracted': extracted,
    }));
  }
}