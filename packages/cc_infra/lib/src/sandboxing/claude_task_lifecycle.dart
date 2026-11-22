part of 'claude_stream_json.dart';

/// A background Bash task of the Claude Code CLI (a `Bash` call with
/// `run_in_background`), as its `system` task lifecycle lines report it.
///
/// Evidence for the field names, from this repository's stream fixtures
/// (`test/dispatch/claude_subagent_runs_test.dart`): the task starts with
/// `{"type":"system","subtype":"task_started","task_id":…,"tool_use_id":…,
/// "task_type":"local_bash"}` and ends with a `task_notification` carrying
/// `status` (`completed`), or a `task_updated` whose `patch.status` is
/// terminal (`completed`, `failed`, `stopped`, `killed`). No fixture carries
/// the task's own timeout, so none is read here.
sealed class ClaudeBackgroundTaskEvent {
  const ClaudeBackgroundTaskEvent(this.taskId);

  /// The CLI's task id.
  final String taskId;
}

/// A background Bash task started.
final class ClaudeBackgroundTaskStarted extends ClaudeBackgroundTaskEvent {
  /// Creates the event.
  const ClaudeBackgroundTaskStarted(super.taskId, {this.description});

  /// The CLI's description of the task, when it gave one.
  final String? description;
}

/// A background Bash task ended.
final class ClaudeBackgroundTaskEnded extends ClaudeBackgroundTaskEvent {
  /// Creates the event.
  const ClaudeBackgroundTaskEnded(super.taskId, {this.status});

  /// The status the CLI reported (`completed`, `failed`, `stopped`,
  /// `killed`), when it reported one.
  final String? status;
}

/// The task lifecycle lines of the stream: background subagents (an agent
/// row each) and background Bash tasks (never a row; reported through
/// [ClaudeStreamJsonCallbacks.onBackgroundTask]).
extension _ClaudeTaskLifecycle on ClaudeStreamJsonParser {
  static const Set<String> _terminal = {
    'completed',
    'failed',
    'stopped',
    'killed',
  };

  /// A `task_started` of a background Bash task: tracked and reported.
  bool _bashTaskStarted(Map<String, dynamic> obj) {
    final taskId = obj['task_id'];
    if (obj['task_type'] != 'local_bash' ||
        taskId is! String ||
        taskId.isEmpty) {
      return false;
    }
    if (_bashTasks.add(taskId)) {
      final description = obj['description'];
      _callbacks.onBackgroundTask?.call(
        ClaudeBackgroundTaskStarted(
          taskId,
          description: description is String ? description : null,
        ),
      );
    }
    return true;
  }

  /// A `task_notification` (the task finished) or a `task_updated` with a
  /// terminal status, for a tracked background Bash task.
  bool _bashTaskEnded(String subtype, Map<String, dynamic> obj) {
    final taskId = obj['task_id'];
    if (taskId is! String || !_bashTasks.contains(taskId)) {
      return false;
    }
    final patch = obj['patch'];
    final data = subtype == 'task_updated' && patch is Map ? patch : obj;
    final status = data['status'];
    if (subtype == 'task_updated' && !_terminal.contains(status)) {
      return true;
    }
    _bashTasks.remove(taskId);
    _callbacks.onBackgroundTask?.call(
      ClaudeBackgroundTaskEnded(
        taskId,
        status: status is String ? status : null,
      ),
    );
    return true;
  }

  bool _handleSubagentTask(Map<String, dynamic> obj) {
    final subtype = obj['subtype'];
    if (subtype == 'task_started') {
      if (_bashTaskStarted(obj)) {
        return true;
      }
      final spawnId = obj['tool_use_id'];
      final subagentType = obj['subagent_type'];
      // Bash tasks share this lane but must never open an agent row.
      if (spawnId is String &&
          spawnId.isNotEmpty &&
          (subagentType is String || obj['task_type'] == 'local_agent')) {
        _subagentSpawnIds.add(spawnId);
        final taskId = obj['task_id'];
        if (taskId is String && taskId.isNotEmpty) {
          _subagentTasks[taskId] = (
            spawnId: spawnId,
            runId: obj['run_id'] as String?,
          );
        }
        _callbacks.onSubagent?.call(
          ClaudeSubagentStarted(
            spawnId,
            description: obj['description'] as String?,
            subagentType: subagentType is String ? subagentType : null,
          ),
        );
      }
      return true;
    }
    if (subtype != 'task_notification' && subtype != 'task_updated') {
      return false;
    }
    if (_bashTaskEnded(subtype as String, obj)) {
      return true;
    }
    final task = _subagentTasks[obj['task_id']];
    final runId = obj['run_id'];
    if (task != null &&
        task.runId != null &&
        runId is String &&
        runId != task.runId) {
      return true;
    }
    final spawnId = obj['tool_use_id'] ?? task?.spawnId;
    if (spawnId is! String || !_subagentSpawnIds.contains(spawnId)) {
      return true;
    }
    final patch = obj['patch'];
    final data = subtype == 'task_updated' && patch is Map ? patch : obj;
    final status = switch (data['status']) {
      'completed' => ClaudeSubagentStatus.completed,
      'failed' => ClaudeSubagentStatus.failed,
      'stopped' || 'killed' => ClaudeSubagentStatus.stopped,
      _ => null,
    };
    if (status != null) {
      _callbacks.onSubagent?.call(
        ClaudeSubagentFinished(
          spawnId,
          status: status,
          summary: (data['summary'] ?? data['error']) as String?,
        ),
      );
    }
    return true;
  }

  /// Routes one subagent line: its `assistant` blocks become text, thinking
  /// and tool calls, its `user` tool results close them. The `user` text that
  /// opens a subagent is the parent's prompt, already on the spawn call.
  void _handleSubagentLine(
    String spawnId,
    Object? type,
    Map<String, dynamic> obj,
  ) {
    final onSubagent = _callbacks.onSubagent;
    final message = obj['message'];
    if (onSubagent == null || message is! Map<String, dynamic>) {
      return;
    }
    final content = message['content'];
    if (content is! List) {
      return;
    }
    _subagentSpawnIds.add(spawnId);
    for (final block in content) {
      if (block is! Map<String, dynamic>) {
        continue;
      }
      switch ((type, block['type'])) {
        case ('assistant', 'text'):
          final text = block['text'] as String? ?? '';
          if (text.isNotEmpty) {
            onSubagent(ClaudeSubagentText(spawnId, text));
          }
        case ('assistant', 'thinking'):
          final text = block['thinking'] as String? ?? '';
          if (text.isNotEmpty) {
            onSubagent(ClaudeSubagentThinking(spawnId, text));
          }
        case ('assistant', 'tool_use'):
          final toolId = block['id'];
          if (toolId is String) {
            _openToolNames[toolId] = block['name'] as String? ?? '';
          }
          onSubagent(
            ClaudeSubagentToolCall(
              spawnId,
              ClaudeToolUse(
                id: block['id'] as String? ?? '',
                name: block['name'] as String? ?? '',
                input: block['input'],
              ),
            ),
          );
        case ('user', 'tool_result'):
          final toolId = block['tool_use_id'] as String? ?? '';
          final toolName = _openToolNames.remove(toolId);
          onSubagent(
            ClaudeSubagentToolResult(
              spawnId,
              ClaudeToolResult(
                id: block['tool_use_id'] as String? ?? '',
                outputs: ClaudeStreamJsonParser._flattenResult(
                  block['content'],
                ),
                images: renderMediaImageRefs(toolName, block['content']),
                isError: block['is_error'] == true,
                isAsync: ClaudeStreamJsonParser._isAsyncResult(
                  obj['tool_use_result'],
                ),
              ),
            ),
          );
      }
    }
  }
}
