import 'package:control_center/features/mcp/domain/ports/mcp_tool_port.dart';

class SuggestTasksTool extends McpTool {
  SuggestTasksTool({required this.repository});

  final dynamic repository;

  @override
  String get name => 'suggest_tasks';

  @override
  String get description =>
      'Propose a task breakdown for the current work. '
      'Returns structured task cards that the user can approve, modify, or reject.';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'tasks': {
            'type': 'array',
            'description': 'List of proposed tasks',
            'items': {
              'type': 'object',
              'properties': {
                'title': {
                  'type': 'string',
                  'description': 'Task title',
                },
                'description': {
                  'type': 'string',
                  'description': 'What this task involves',
                },
                'assignee': {
                  'type': 'string',
                  'description':
                      'Agent name to assign (or "user" for human task)',
                },
                'priority': {
                  'type': 'string',
                  'enum': ['high', 'medium', 'low'],
                  'description': 'Task priority',
                },
                'dependencies': {
                  'type': 'array',
                  'items': {'type': 'string'},
                  'description': 'Titles of tasks that must complete first',
                },
              },
              'required': ['title', 'description'],
            },
          },
          'context': {
            'type': 'string',
            'description': 'Why these tasks are being suggested',
          },
        },
        'required': ['tasks'],
      };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final tasks = arguments['tasks'] as List<dynamic>?;
    if (tasks == null || tasks.isEmpty) {
      return CallResult.error('At least one task is required');
    }

    final buf = StringBuffer();
    buf.writeln('## Task Suggestions');
    if (arguments['context'] != null) {
      buf.writeln('\n**Context:** ${arguments['context']}\n');
    }

    for (var i = 0; i < tasks.length; i++) {
      final task = tasks[i] as Map<String, dynamic>;
      buf.writeln('### ${i + 1}. ${task['title'] ?? 'Untitled'}');
      buf.writeln('${task['description'] ?? ''}');
      if (task['assignee'] != null) {
        buf.writeln('**Assignee:** ${task['assignee']}');
      }
      if (task['priority'] != null) {
        buf.writeln('**Priority:** ${task['priority']}');
      }
      final deps = task['dependencies'] as List<dynamic>?;
      if (deps != null && deps.isNotEmpty) {
        buf.writeln('**Depends on:** ${deps.join(', ')}');
      }
      buf.writeln();
    }

    return CallResult.success(buf.toString());
  }
}
