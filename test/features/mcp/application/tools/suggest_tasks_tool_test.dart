import 'package:control_center/features/mcp/application/tools/suggest_tasks_tool.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SuggestTasksTool', () {
    late SuggestTasksTool tool;

    setUp(() {
      tool = SuggestTasksTool(repository: null);
    });

    // ── metadata ──────────────────────────────────────────────────────

    test('has correct name', () {
      expect(tool.name, 'suggest_tasks');
    });

    test('has non-empty description', () {
      expect(tool.description, isNotEmpty);
    });

    test('inputSchema requires tasks', () {
      final schema = tool.inputSchema;
      expect(schema['type'], 'object');
      expect(schema['required'], ['tasks']);
    });

    // ── arg validation ────────────────────────────────────────────────

    test('null tasks → error', () async {
      final result = await tool.call({'tasks': null});

      expect(result.isError, isTrue);
      expect(result.content.first.text, 'At least one task is required');
    });

    test('empty tasks → error', () async {
      final result = await tool.call({'tasks': []});

      expect(result.isError, isTrue);
      expect(result.content.first.text, 'At least one task is required');
    });

    test('missing tasks key → error via catch', () async {
      final result = await tool.call({});

      expect(result.isError, isTrue);
    });

    test('tasks not a list → error via catch', () async {
      final result = await tool.call({'tasks': 'not-a-list'});

      expect(result.isError, isTrue);
    });

    // ── success: minimal tasks ────────────────────────────────────────

    test('single task with title and description', () async {
      final result = await tool.call({
        'tasks': [
          {'title': 'Add login', 'description': 'Implement OAuth flow'},
        ],
      });

      expect(result.isError, isFalse);
      final text = result.content.first.text;
      expect(text, contains('## Task Suggestions'));
      expect(text, contains('### 1. Add login'));
      expect(text, contains('Implement OAuth flow'));
    });

    test('multiple tasks', () async {
      final result = await tool.call({
        'tasks': [
          {'title': 'Task A', 'description': 'First step'},
          {'title': 'Task B', 'description': 'Second step'},
          {'title': 'Task C', 'description': 'Third step'},
        ],
      });

      expect(result.isError, isFalse);
      final text = result.content.first.text;
      expect(text, contains('### 1. Task A'));
      expect(text, contains('### 2. Task B'));
      expect(text, contains('### 3. Task C'));
    });

    // ── success: with context ─────────────────────────────────────────

    test('context is rendered when provided', () async {
      final result = await tool.call({
        'tasks': [
          {'title': 'Do thing', 'description': 'Do it'},
        ],
        'context': 'Getting started on the auth module',
      });

      expect(result.isError, isFalse);
      final text = result.content.first.text;
      expect(text, contains('**Context:** Getting started on the auth module'));
    });

    test('context is absent when not provided', () async {
      final result = await tool.call({
        'tasks': [
          {'title': 'Do thing', 'description': 'Do it'},
        ],
      });

      expect(result.isError, isFalse);
      final text = result.content.first.text;
      expect(text, isNot(contains('**Context:**')));
    });

    // ── success: optional fields ──────────────────────────────────────

    test('task with assignee', () async {
      final result = await tool.call({
        'tasks': [
          {
            'title': 'Review PR',
            'description': 'Code review for #42',
            'assignee': 'alice',
          },
        ],
      });

      expect(result.isError, isFalse);
      final text = result.content.first.text;
      expect(text, contains('**Assignee:** alice'));
    });

    test('task with priority', () async {
      final result = await tool.call({
        'tasks': [
          {
            'title': 'Fix bug',
            'description': 'Critical crash',
            'priority': 'high',
          },
        ],
      });

      expect(result.isError, isFalse);
      final text = result.content.first.text;
      expect(text, contains('**Priority:** high'));
    });

    test('task with dependencies', () async {
      final result = await tool.call({
        'tasks': [
          {
            'title': 'Deploy',
            'description': 'Push to prod',
            'dependencies': ['Build', 'Test'],
          },
        ],
      });

      expect(result.isError, isFalse);
      final text = result.content.first.text;
      expect(text, contains('**Depends on:** Build, Test'));
    });

    test('task with all optional fields', () async {
      final result = await tool.call({
        'tasks': [
          {
            'title': 'Ship feature',
            'description': 'End-to-end delivery',
            'assignee': 'bob',
            'priority': 'medium',
            'dependencies': ['Design', 'Implement'],
          },
        ],
        'context': 'Sprint 3 deliverables',
      });

      expect(result.isError, isFalse);
      final text = result.content.first.text;
      expect(text, contains('**Context:** Sprint 3 deliverables'));
      expect(text, contains('### 1. Ship feature'));
      expect(text, contains('End-to-end delivery'));
      expect(text, contains('**Assignee:** bob'));
      expect(text, contains('**Priority:** medium'));
      expect(text, contains('**Depends on:** Design, Implement'));
    });

    // ── edge cases: null / missing fields ─────────────────────────────

    test('null title → "Untitled"', () async {
      final result = await tool.call({
        'tasks': [
          {'title': null, 'description': 'Some work'},
        ],
      });

      expect(result.isError, isFalse);
      final text = result.content.first.text;
      expect(text, contains('### 1. Untitled'));
    });

    test('null description → empty', () async {
      final result = await tool.call({
        'tasks': [
          {'title': 'Task', 'description': null},
        ],
      });

      expect(result.isError, isFalse);
      final text = result.content.first.text;
      // Description is present in the output as empty string
      expect(text, contains('### 1. Task'));
    });

    test('null assignee → omitted', () async {
      final result = await tool.call({
        'tasks': [
          {
            'title': 'Task',
            'description': 'Desc',
            'assignee': null,
          },
        ],
      });

      expect(result.isError, isFalse);
      final text = result.content.first.text;
      expect(text, isNot(contains('**Assignee:**')));
    });

    test('null priority → omitted', () async {
      final result = await tool.call({
        'tasks': [
          {
            'title': 'Task',
            'description': 'Desc',
            'priority': null,
          },
        ],
      });

      expect(result.isError, isFalse);
      final text = result.content.first.text;
      expect(text, isNot(contains('**Priority:**')));
    });

    test('null dependencies → omitted', () async {
      final result = await tool.call({
        'tasks': [
          {
            'title': 'Task',
            'description': 'Desc',
            'dependencies': null,
          },
        ],
      });

      expect(result.isError, isFalse);
      final text = result.content.first.text;
      expect(text, isNot(contains('**Depends on:**')));
    });

    test('empty dependencies array → omitted', () async {
      final result = await tool.call({
        'tasks': [
          {
            'title': 'Task',
            'description': 'Desc',
            'dependencies': [],
          },
        ],
      });

      expect(result.isError, isFalse);
      final text = result.content.first.text;
      expect(text, isNot(contains('**Depends on:**')));
    });

    test('missing optional fields in task → rendered without them', () async {
      final result = await tool.call({
        'tasks': [
          {'title': 'Minimal task', 'description': 'Just the essentials'},
        ],
      });

      expect(result.isError, isFalse);
      final text = result.content.first.text;
      expect(text, contains('### 1. Minimal task'));
      expect(text, contains('Just the essentials'));
      expect(text, isNot(contains('**Assignee:**')));
      expect(text, isNot(contains('**Priority:**')));
      expect(text, isNot(contains('**Depends on:**')));
    });
  });
}
