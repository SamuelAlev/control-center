import 'dart:convert';

import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/messaging/domain/repositories/conversation_repository.dart';
import 'package:cc_domain/features/todos/domain/entities/todo_item.dart';
import 'package:cc_domain/features/todos/domain/repositories/todo_repository.dart';

/// Reads back the persisted task checklist for a conversation — the read half
/// of `todo_write`.
///
/// The list is persisted per `(workspace_id, conversation_id)`. An agent uses
/// this to recover its plan after a context reset or when resuming work, since
/// `todo_write` replaces the whole list and returns only a rendered summary.
class TodoReadTool extends McpTool {
  /// Creates a [TodoReadTool].
  TodoReadTool({
    required TodoRepository todoRepository,
    required ConversationRepository conversationRepository,
  }) : _todos = todoRepository,
       _conversations = conversationRepository;

  final TodoRepository _todos;
  final ConversationRepository _conversations;

  @override
  String get name => 'todo_read';

  @override
  Set<String> get forcedScopeKeys => const {'conversation_id'};

  @override
  Set<String> get requiredScopeKeys => const {
    'workspace_id',
    'conversation_id',
  };

  @override
  String get description =>
      'Read the persisted task checklist for this conversation (the '
      'read-back half of `todo_write`). Returns the ordered list of '
      '{id, content, status} items, where status is one of pending, '
      'in_progress, completed. Use it to recover your plan after a context '
      'reset or when resuming work. workspace_id and conversation_id come '
      'from the session; do not guess or pass them. Supplied IDs are ignored.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'workspace_id': {
        'type': 'string',
        'description': 'The workspace the conversation belongs to.',
      },
      'conversation_id': {
        'type': 'string',
        'description': 'Filled from the session; supplied values are ignored.',
      },
    },
    'required': <String>[],
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final workspaceId = arguments['workspace_id'];
    if (workspaceId is! String || workspaceId.isEmpty) {
      return CallResult.error('Missing or invalid argument: workspace_id');
    }
    final conversationId = arguments['conversation_id'];
    if (conversationId is! String || conversationId.isEmpty) {
      return CallResult.error(
        'Missing or invalid argument: conversation_id (expected string)',
      );
    }

    // Workspace isolation (hard invariant): the conversation MUST belong to
    // the caller's workspace. A bare conversation_id is not proof of ownership.
    final conversation = await _conversations.getById(
      workspaceId: workspaceId,
      conversationId: conversationId,
    );
    if (conversation == null) {
      return CallResult.error('Conversation not found in this workspace.');
    }

    final items = await _todos.list(workspaceId, conversationId);
    final done = items.where((t) => t.status.isDone).length;
    return CallResult.success(
      jsonEncode({
        'conversation_id': conversationId,
        'total': items.length,
        'completed': done,
        'todos': [for (final item in items) _todoToJson(item)],
      }),
    );
  }

  Map<String, dynamic> _todoToJson(TodoItem item) => {
    'id': item.id,
    'content': item.content,
    'status': item.status.storage,
    'position': item.position,
  };
}
