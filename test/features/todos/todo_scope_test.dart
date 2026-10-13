import 'dart:convert';

import 'package:cc_domain/cc_domain.dart' show JsonRpcRequest;
import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/mcp/domain/services/mcp_tool_registry.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/mcp_call_scope.dart';
import 'package:cc_domain/features/messaging/domain/entities/conversation.dart';
import 'package:cc_domain/features/messaging/domain/repositories/conversation_repository.dart';
import 'package:cc_domain/features/todos/domain/entities/todo_item.dart';
import 'package:cc_domain/features/todos/domain/repositories/todo_repository.dart';
import 'package:cc_harness/tools.dart';
import 'package:cc_infra/src/harness/mcp_tool_bridge.dart';
import 'package:cc_mcp/src/mcp_tool_dispatcher.dart';
import 'package:cc_mcp/src/tools/todo_read_tool.dart';
import 'package:cc_mcp/src/tools/todo_write_tool.dart';
import 'package:flutter_test/flutter_test.dart';

const _runScope = McpCallScope(
  workspaceId: 'workspace',
  conversationId: 'run',
  spaceId: 'space',
  agentId: 'agent',
);

class _Todos implements TodoRepository {
  final rows = <(String, String), List<TodoItem>>{};

  @override
  Future<List<TodoItem>> list(
    String workspaceId,
    String conversationId,
  ) async => rows[(workspaceId, conversationId)] ?? const [];

  @override
  Future<void> replaceAll(
    String workspaceId,
    String conversationId,
    List<TodoItem> items,
  ) async {
    rows[(workspaceId, conversationId)] = List.of(items);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Conversations implements ConversationRepository {
  @override
  Future<Conversation?> getById({
    required String workspaceId,
    required String conversationId,
  }) async {
    if (workspaceId != 'workspace' ||
        !{'run', 'other'}.contains(conversationId)) {
      return null;
    }
    return Conversation(
      id: conversationId,
      workspaceId: workspaceId,
      spaceId: 'space',
      title: conversationId,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  for (final transport in ['MCP', 'harness']) {
    group('$transport conversation-owned TODOs', () {
      late _Todos todos;
      late Map<String, McpTool> tools;

      setUp(() {
        todos = _Todos();
        final conversations = _Conversations();
        tools = {
          'todo_read': TodoReadTool(
            todoRepository: todos,
            conversationRepository: conversations,
          ),
          'todo_write': TodoWriteTool(
            todoRepository: todos,
            conversationRepository: conversations,
          ),
        };
        for (final id in ['run', 'other']) {
          todos.rows[('workspace', id)] = [
            TodoItem(
              id: '$id-item',
              workspaceId: 'workspace',
              conversationId: id,
              content: '$id task',
              createdAt: DateTime(2026),
              updatedAt: DateTime(2026),
            ),
          ];
        }
      });

      Future<({bool isError, String text})> call(
        String name,
        Map<String, dynamic> args, {
        McpCallScope? scope = _runScope,
      }) async {
        if (transport == 'harness') {
          final result = await McpToolBridge(tools[name]!).execute(
            args,
            HarnessToolContext(
              workingDirectory: '.',
              workspaceId: scope?.workspaceId,
              conversationId: scope?.conversationId,
              spaceId: scope?.spaceId,
              agentId: scope?.agentId,
            ),
          );
          return (isError: result.isError, text: result.content);
        }
        final dispatcher = McpToolDispatcher(
          registry: McpToolRegistry(tools.values.toList()),
        );
        final response = await dispatcher.handleScopedRequest(
          JsonRpcRequest(
            method: 'tools/call',
            id: 1,
            params: {'name': name, 'arguments': args},
          ),
          scope: scope,
        );
        final result = response['result'] as Map;
        return (
          isError: result['isError'] == true,
          text: (result['content'] as List)
              .map((c) => (c as Map)['text'])
              .join('\n'),
        );
      }

      test(
        'cannot redirect a read or replacement to another conversation',
        () async {
          final write = await call('todo_write', {
            'workspace_id': 'foreign-workspace',
            'conversation_id': 'other',
            'todos': [
              {'content': 'Current run task', 'status': 'in_progress'},
            ],
          });
          expect(write.isError, isFalse);
          expect((await todos.list('workspace', 'run')).map((t) => t.content), [
            'Current run task',
          ]);
          expect(
            (await todos.list('workspace', 'other')).map((t) => t.content),
            ['other task'],
          );
          expect(await todos.list('foreign-workspace', 'other'), isEmpty);

          final read = await call('todo_read', {
            'workspace_id': 'foreign-workspace',
            'conversation_id': 'other',
          });
          expect(read.isError, isFalse);
          final body = jsonDecode(read.text) as Map;
          expect(body['conversation_id'], 'run');
          expect((body['todos'] as List).map((t) => (t as Map)['content']), [
            'Current run task',
          ]);
        },
      );

      test('ignores a space ID supplied as the conversation ID', () async {
        final read = await call('todo_read', {
          'workspace_id': 'workspace',
          'conversation_id': 'space',
        });
        expect(read.isError, isFalse);
        final body = jsonDecode(read.text) as Map;
        expect(body['conversation_id'], 'run');
        expect((body['todos'] as List).map((t) => (t as Map)['content']), [
          'run task',
        ]);
      });

      test(
        'does not trust model IDs when session identity is missing',
        () async {
          for (final scope in <McpCallScope?>[
            null,
            const McpCallScope(workspaceId: 'workspace'),
            const McpCallScope(conversationId: 'run'),
          ]) {
            for (final name in tools.keys) {
              final result = await call(name, {
                'workspace_id': 'workspace',
                'conversation_id': 'other',
                if (name == 'todo_write')
                  'todos': [
                    {'content': 'Wrong task', 'status': 'pending'},
                  ],
              }, scope: scope);
              expect(result.isError, isTrue);
            }
          }
          expect((await todos.list('workspace', 'run')).map((t) => t.content), [
            'run task',
          ]);
          expect(
            (await todos.list('workspace', 'other')).map((t) => t.content),
            ['other task'],
          );
        },
      );
    });
  }
}
