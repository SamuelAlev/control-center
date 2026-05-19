import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/todos/domain/entities/todo_item.dart';
import 'package:cc_domain/features/todos/domain/repositories/todo_repository.dart';
import 'package:cc_domain/features/todos/domain/value_objects/todo_status.dart';

/// Records or updates the persisted task checklist for a conversation.
///
/// This is the single agent-facing todo surface: it is reached both by the
/// built-in harness (bridged into the loop, with `conversation_id` injected
/// from the run context) and by external adapters (Claude CLI / Pi) over MCP.
/// The list is persisted per `(workspace_id, conversation_id)` and rendered in
/// the app's General pane. The model always passes the FULL list (create +
/// update in one shot), matching the historical ephemeral tool contract.
///
/// **Identity is preserved across calls.** A full-list write is reconciled
/// against the stored list rather than blindly re-minting rows: an incoming
/// item is matched to an existing one by `id` when supplied, else by identical
/// `content` and keeps that row's id and `createdAt`. Without this, every
/// write deleted and re-inserted the whole list — ids churned, `createdAt`
/// reset, the ids handed out by `todo_read` went stale immediately and the
/// General pane re-created every row on each call. Only genuinely new items get
/// a fresh id.
///
/// The result payload also reports checklist *hygiene* back to the model (no
/// item in_progress while work remains, several items in_progress at once,
/// items silently dropped by a short re-send). The observed failure mode was an
/// agent that only ever appended items and never transitioned them, which makes
/// the list useless to the user; the write's own output is the cheapest place to
/// correct that, since it is read on every call.
class TodoWriteTool extends McpTool {
  /// Creates a [TodoWriteTool].
  TodoWriteTool({
    required TodoRepository todoRepository,
    required MessagingRepository messagingRepository,
  }) : _todos = todoRepository,
       _messaging = messagingRepository;

  final TodoRepository _todos;
  final MessagingRepository _messaging;

  static const _statuses = {'pending', 'in_progress', 'completed'};

  @override
  String get name => 'todo_write';

  @override
  String get description =>
      'Record AND update the task checklist for this conversation. Pass the '
      'FULL list every call as `todos` (items are {content, status}, plus an '
      'optional {id}); status is one of pending, in_progress, completed.\n'
      'The list is only useful if its state tracks reality, so:\n'
      '1. Before you start an item, call this again with that item '
      'in_progress. Exactly one item is in_progress at a time.\n'
      '2. The moment an item is finished, call this again with it completed. '
      'Do not save up completions for the end of the run.\n'
      '3. Re-send every item you still intend to do, unchanged ones included. '
      'An item you omit is removed from the list.\n'
      '4. Keep `content` identical between calls for items that have not '
      'changed — that is how an item keeps its identity and its place. Pass '
      'the `id` from `todo_read` when you want to be explicit.\n'
      'Appending new items without ever transitioning the old ones is the one '
      'way to use this tool wrong. The list is persisted per conversation and '
      'shown to the user live.';

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
        'description': 'The conversation (channel) whose task list to write.',
      },
      'todos': {
        'type': 'array',
        'description':
            'The COMPLETE checklist, in display order. Replaces the stored '
            'list; items absent from it are removed.',
        'items': {
          'type': 'object',
          'properties': {
            'content': {'type': 'string'},
            'status': {
              'type': 'string',
              'enum': ['pending', 'in_progress', 'completed'],
            },
            'id': {
              'type': 'string',
              'description':
                  'Optional. The existing item this entry updates, as '
                  'returned by `todo_read`. Omit for a new item; omit and '
                  'keep `content` identical to update an existing one.',
            },
          },
          'required': ['content', 'status'],
        },
      },
    },
    'required': ['workspace_id', 'conversation_id', 'todos'],
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
    final raw = arguments['todos'];
    if (raw is! List) {
      return CallResult.error('Missing or invalid argument: todos');
    }

    // Workspace isolation (hard invariant): the conversation MUST belong to the
    // caller's workspace. A bare conversation_id is not proof of ownership.
    final channels = await _messaging
        .watchChannelsByWorkspace(workspaceId)
        .first;
    if (!channels.any((c) => c.id == conversationId)) {
      return CallResult.error('Conversation belongs to a different workspace.');
    }

    // Reconcile against the stored list so unchanged items keep their identity
    // (id + createdAt) instead of being deleted and re-inserted under a new id.
    final existing = await _todos.list(workspaceId, conversationId);
    final byId = {for (final e in existing) e.id: e};
    final byContent = <String, List<TodoItem>>{};
    for (final e in existing) {
      (byContent[e.content] ??= <TodoItem>[]).add(e);
    }
    final claimed = <String>{};

    /// Claims the stored row this incoming entry updates: by [id] when the model
    /// supplied one, else the first not-yet-claimed row with identical content.
    /// Null when the entry is genuinely new.
    TodoItem? claim(String? id, String content) {
      if (id != null && id.isNotEmpty) {
        final hit = byId[id];
        if (hit != null && claimed.add(hit.id)) {
          return hit;
        }
      }
      for (final candidate in byContent[content] ?? const <TodoItem>[]) {
        if (claimed.add(candidate.id)) {
          return candidate;
        }
      }
      return null;
    }

    final now = DateTime.now();
    final items = <TodoItem>[];
    final usedIds = <String>{};
    for (var i = 0; i < raw.length; i++) {
      final item = raw[i];
      if (item is! Map) {
        return CallResult.error('Each todo must be an object.');
      }
      final content = item['content'];
      final status = item['status'];
      final id = item['id'];
      if (content is! String || content.trim().isEmpty) {
        return CallResult.error('Each todo needs a non-empty content.');
      }
      if (status is! String || !_statuses.contains(status)) {
        return CallResult.error(
          'Invalid status "$status"; use pending, in_progress, or completed.',
        );
      }
      final trimmed = content.trim();
      final prior = claim(id is String ? id : null, trimmed);
      // A minted id must not collide with a preserved one (two calls inside the
      // same microsecond would otherwise reuse the same key).
      var fresh = '${now.microsecondsSinceEpoch}-$i';
      for (var n = 1; usedIds.contains(fresh) || byId.containsKey(fresh); n++) {
        fresh = '${now.microsecondsSinceEpoch}-$i-$n';
      }
      final resolvedId = prior?.id ?? fresh;
      usedIds.add(resolvedId);
      items.add(
        TodoItem(
          id: resolvedId,
          workspaceId: workspaceId,
          conversationId: conversationId,
          content: trimmed,
          status: TodoStatus.fromStorage(status),
          position: i,
          createdAt: prior?.createdAt ?? now,
          updatedAt: now,
        ),
      );
    }

    await _todos.replaceAll(workspaceId, conversationId, items);
    final dropped = [
      for (final e in existing)
        if (!claimed.contains(e.id)) e,
    ];
    return CallResult.success(_render(items, dropped: dropped));
  }

  /// Renders the persisted list, then the hygiene notes the model needs to act
  /// on. The notes are the correction channel for the "only ever appends"
  /// failure mode: they are read on every call, unlike the tool description.
  String _render(List<TodoItem> items, {required List<TodoItem> dropped}) {
    final buf = StringBuffer();
    if (items.isEmpty) {
      buf.write('Task list is empty.');
    } else {
      final done = items.where((t) => t.status == TodoStatus.completed).length;
      buf.writeln('Task list ($done/${items.length} done):');
      for (final t in items) {
        buf.writeln('${_box(t.status)} ${t.content}');
      }
    }

    final notes = <String>[];
    if (dropped.isNotEmpty) {
      final names = dropped.map((t) => '"${t.content}"').join(', ');
      notes.add(
        'Removed ${dropped.length} item(s) absent from this call: $names. If '
        'that was not deliberate, re-send the full list including them.',
      );
    }
    final active = items
        .where((t) => t.status == TodoStatus.inProgress)
        .toList();
    final pending = items.where((t) => t.status == TodoStatus.pending).toList();
    if (active.length > 1) {
      notes.add(
        '${active.length} items are in_progress. Keep exactly one — re-send '
        'the list with the others back to pending.',
      );
    } else if (active.isEmpty && pending.isNotEmpty) {
      notes.add(
        'Nothing is in_progress. Before you start the next item '
        '("${pending.first.content}"), call `todo_write` again with it marked '
        'in_progress and mark it completed as soon as it is done.',
      );
    } else if (active.isEmpty && pending.isEmpty && items.isNotEmpty) {
      notes.add('Every item is complete.');
    }
    for (final note in notes) {
      buf
        ..writeln()
        ..writeln(note);
    }
    return buf.toString().trimRight();
  }

  String _box(TodoStatus status) => switch (status) {
    TodoStatus.completed => '[x]',
    TodoStatus.inProgress => '[~]',
    TodoStatus.pending => '[ ]',
  };
}
