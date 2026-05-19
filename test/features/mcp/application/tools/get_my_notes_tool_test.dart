import 'dart:convert';

import 'package:cc_domain/core/domain/entities/agent_working_memory.dart';
import 'package:cc_mcp/src/tools/get_my_notes_tool.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../fakes/fake_memory_repositories.dart';

void main() {
  group('GetMyNotesTool', () {
    late FakeAgentWorkingMemoryRepository fakeRepo;
    late GetMyNotesTool tool;

    setUp(() {
      fakeRepo = FakeAgentWorkingMemoryRepository();
      tool = GetMyNotesTool(repository: fakeRepo);
    });

    test('name is get_my_notes', () {
      expect(tool.name, 'get_my_notes');
    });

    test('description is non-empty', () {
      expect(tool.description, isNotEmpty);
    });

    test('inputSchema has correct structure', () {
      final schema = tool.inputSchema;
      expect(schema['type'], 'object');

      final required = schema['required'] as List<dynamic>;
      expect(required, contains('workspace_id'));
      expect(required, contains('agent_id'));

      final properties = schema['properties'] as Map<String, dynamic>;
      expect(properties.containsKey('workspace_id'), isTrue);
      expect((properties['workspace_id'] as Map<String, dynamic>)['type'], 'string');
      expect(properties.containsKey('agent_id'), isTrue);
      expect((properties['agent_id'] as Map<String, dynamic>)['type'], 'string');
    });

    test('returns error for missing workspace_id', () async {
      final result = await tool.run({'agent_id': 'a-1'});
      expect(result.isError, isTrue);
    });

    test('returns error for missing agent_id', () async {
      final result = await tool.run({'workspace_id': 'ws-1'});
      expect(result.isError, isTrue);
    });

    test('returns error when workspace_id is int', () async {
      final result = await tool.run({
        'workspace_id': 42,
        'agent_id': 'a-1',
      });
      expect(result.isError, isTrue);
    });

    test('returns error when agent_id is int', () async {
      final result = await tool.run({
        'workspace_id': 'ws-1',
        'agent_id': 7,
      });
      expect(result.isError, isTrue);
    });

    test('returns error when workspace_id is double', () async {
      final result = await tool.run({
        'workspace_id': 3.14,
        'agent_id': 'a-1',
      });
      expect(result.isError, isTrue);
    });

    test('returns error when agent_id is bool', () async {
      final result = await tool.run({
        'workspace_id': 'ws-1',
        'agent_id': false,
      });
      expect(result.isError, isTrue);
    });

    test('returns error when workspace_id is null', () async {
      final result = await tool.run({
        'workspace_id': null,
        'agent_id': 'a-1',
      });
      expect(result.isError, isTrue);
    });

    test('returns error when agent_id is null', () async {
      final result = await tool.run({
        'workspace_id': 'ws-1',
        'agent_id': null,
      });
      expect(result.isError, isTrue);
    });

    test('returns null content when no memory found', () async {
      final result = await tool.run({
        'workspace_id': 'ws-1',
        'agent_id': 'a-1',
      });
      expect(result.isError, isFalse);
      expect(result.content.first.text, contains('"content":null'));
      expect(result.content.first.text, contains('No working memory found'));
    });

    test('returns content when memory exists', () async {
      final now = DateTime(2026, 6, 1);
      fakeRepo.seed([
        AgentWorkingMemory(
          id: 'mem-1',
          workspaceId: 'ws-1',
          agentId: 'a-1',
          content: '# My notes\nSome markdown',
          updatedAt: now,
        ),
      ]);

      final result = await tool.run({
        'workspace_id': 'ws-1',
        'agent_id': 'a-1',
      });
      expect(result.isError, isFalse);
      expect(result.content.first.text, contains('"content":"# My notes\\nSome markdown"'));
      expect(result.content.first.text, contains(now.toIso8601String()));
    });

    test('returns null for different workspace_id', () async {
      fakeRepo.seed([
        AgentWorkingMemory(
          id: 'mem-1',
          workspaceId: 'ws-2',
          agentId: 'a-1',
          content: 'secret',
          updatedAt: DateTime(2026),
        ),
      ]);

      final result = await tool.run({
        'workspace_id': 'ws-1',
        'agent_id': 'a-1',
      });
      expect(result.isError, isFalse);
      expect(result.content.first.text, contains('"content":null'));
    });

    test('returns null for different agent_id', () async {
      fakeRepo.seed([
        AgentWorkingMemory(
          id: 'mem-1',
          workspaceId: 'ws-1',
          agentId: 'a-2',
          content: 'other agent notes',
          updatedAt: DateTime(2026),
        ),
      ]);

      final result = await tool.run({
        'workspace_id': 'ws-1',
        'agent_id': 'a-1',
      });
      expect(result.isError, isFalse);
      expect(result.content.first.text, contains('"content":null'));
    });

    test('empty string workspace_id is valid and returns null content', () async {
      final result = await tool.run({
        'workspace_id': '',
        'agent_id': 'a-1',
      });
      expect(result.isError, isFalse);
      expect(result.content.first.text, contains('"content":null'));
      expect(result.content.first.text, contains('No working memory found'));
    });

    test('empty string agent_id is valid and returns null content', () async {
      final result = await tool.run({
        'workspace_id': 'ws-1',
        'agent_id': '',
      });
      expect(result.isError, isFalse);
      expect(result.content.first.text, contains('"content":null'));
      expect(result.content.first.text, contains('No working memory found'));
    });

    test('both empty strings returns null content', () async {
      final result = await tool.run({
        'workspace_id': '',
        'agent_id': '',
      });
      expect(result.isError, isFalse);
      expect(result.content.first.text, contains('"content":null'));
      expect(result.content.first.text, contains('No working memory found'));
    });

    test('null-content response has all expected fields', () async {
      final result = await tool.run({
        'workspace_id': 'ws-42',
        'agent_id': 'a-99',
      });
      expect(result.isError, isFalse);

      final json = jsonDecode(result.content.first.text) as Map<String, dynamic>;
      expect(json['workspace_id'], 'ws-42');
      expect(json['agent_id'], 'a-99');
      expect(json['content'], isNull);
      expect(json['message'], 'No working memory found for this agent.');
    });

    test('content response has all expected fields', () async {
      final now = DateTime(2025, 12, 25, 10, 30, 45, 123);
      fakeRepo.seed([
        AgentWorkingMemory(
          id: 'mem-full',
          workspaceId: 'ws-X',
          agentId: 'a-Y',
          content: '**bold** notes',
          updatedAt: now,
        ),
      ]);

      final result = await tool.run({
        'workspace_id': 'ws-X',
        'agent_id': 'a-Y',
      });
      expect(result.isError, isFalse);

      final json = jsonDecode(result.content.first.text) as Map<String, dynamic>;
      expect(json['workspace_id'], 'ws-X');
      expect(json['agent_id'], 'a-Y');
      expect(json['content'], '**bold** notes');
      expect(json['updated_at'], now.toIso8601String());
      expect(json.containsKey('message'), isFalse);
    });

    test('correct entry returned when multiple memories seeded', () async {
      fakeRepo.seed([
        AgentWorkingMemory(
          id: 'mem-1',
          workspaceId: 'ws-1',
          agentId: 'a-1',
          content: 'notes for a-1 in ws-1',
          updatedAt: DateTime(2026, 1, 1),
        ),
        AgentWorkingMemory(
          id: 'mem-2',
          workspaceId: 'ws-1',
          agentId: 'a-2',
          content: 'notes for a-2 in ws-1',
          updatedAt: DateTime(2026, 1, 2),
        ),
        AgentWorkingMemory(
          id: 'mem-3',
          workspaceId: 'ws-2',
          agentId: 'a-1',
          content: 'notes for a-1 in ws-2',
          updatedAt: DateTime(2026, 1, 3),
        ),
      ]);

      final result = await tool.run({
        'workspace_id': 'ws-1',
        'agent_id': 'a-2',
      });
      expect(result.isError, isFalse);

      final json = jsonDecode(result.content.first.text) as Map<String, dynamic>;
      expect(json['workspace_id'], 'ws-1');
      expect(json['agent_id'], 'a-2');
      expect(json['content'], 'notes for a-2 in ws-1');
    });

    test('updated_at is in ISO 8601 format', () async {
      final now = DateTime.utc(2026, 6, 11, 14, 30, 0, 0); // noon UTC
      fakeRepo.seed([
        AgentWorkingMemory(
          id: 'mem-iso',
          workspaceId: 'ws-iso',
          agentId: 'a-iso',
          content: 'iso test',
          updatedAt: now,
        ),
      ]);

      final result = await tool.run({
        'workspace_id': 'ws-iso',
        'agent_id': 'a-iso',
      });
      expect(result.isError, isFalse);

      final json = jsonDecode(result.content.first.text) as Map<String, dynamic>;
      final updatedAtStr = json['updated_at'] as String;

      // ISO 8601 regex: YYYY-MM-DDTHH:mm:ss.mmmZ or with timezone offset
      final iso8601Pattern = RegExp(
        r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?([+-]\d{2}:\d{2}|Z)$',
      );
      expect(updatedAtStr, matches(iso8601Pattern));

      // Also verify it round-trips correctly
      final parsed = DateTime.parse(updatedAtStr);
      expect(parsed, now);
    });
  });
}
