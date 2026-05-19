import 'package:cc_domain/core/domain/entities/memory_policy.dart';
import 'package:cc_domain/core/domain/value_objects/agent_role.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_policy_repository.dart';
import 'package:cc_mcp/src/tools/list_policies_tool.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeMemoryPolicyRepository implements MemoryPolicyRepository {
  final List<MemoryPolicy> _policies = [];

  @override
  Future<List<MemoryPolicy>> getActiveByWorkspace(String workspaceId, {String? domain}) async {
    var results = _policies.where((p) => p.active).toList();
    if (domain != null) {
      results = results.where((p) => p.domain == domain).toList();
    }
    return results;
  }

  @override
  Future<void> upsert(MemoryPolicy policy) async {
    _policies.add(policy);
  }

  @override
  Stream<List<MemoryPolicy>> watchByWorkspace(String workspaceId) => Stream.value(_policies);

  @override
  Future<List<MemoryPolicy>> getByWorkspace(String workspaceId) async => _policies;

  @override
  Future<MemoryPolicy?> getById(String workspaceId, String id) async => null;

  @override
  Future<void> delete(String workspaceId, String id) async {}
}

void main() {
  group('ListPoliciesTool', () {
    late FakeMemoryPolicyRepository fakeRepo;
    late ListPoliciesTool tool;

    setUp(() {
      fakeRepo = FakeMemoryPolicyRepository();
      tool = ListPoliciesTool(repository: fakeRepo);
    });

    test('name is list_policies', () {
      expect(tool.name, 'list_policies');
    });

    test('returns empty list when no policies', () async {
      final result = await tool.run({'workspace_id': 'ws-1'});
      expect(result.isError, isFalse);
      expect(result.content.first.text, contains('"policies":[]'));
    });

    test('returns policies as JSON', () async {
      final now = DateTime(2026, 5, 22);
      fakeRepo._policies.add(MemoryPolicy(
        id: 'p-1', workspaceId: 'ws-1', domain: 'tech-stack',
        rule: 'Use Drift for DB', active: true, createdAt: now, updatedAt: now,
      ));

      final result = await tool.run({'workspace_id': 'ws-1'});
      expect(result.isError, isFalse);
      expect(result.content.first.text, contains('Use Drift for DB'));
      expect(result.content.first.text, contains('tech-stack'));
    });

    test('filters by domain', () async {
      final now = DateTime(2026, 5, 22);
      fakeRepo._policies.addAll([
        MemoryPolicy(
          id: 'p-1', workspaceId: 'ws-1', domain: 'tech-stack',
          rule: 'Tech rule', active: true, createdAt: now, updatedAt: now,
        ),
        MemoryPolicy(
          id: 'p-2', workspaceId: 'ws-1', domain: 'security',
          rule: 'Sec rule', active: true, createdAt: now, updatedAt: now,
        ),
      ]);

      final result = await tool.run({
        'workspace_id': 'ws-1',
        'domain': 'security',
      });
      expect(result.isError, isFalse);
      expect(result.content.first.text, contains('Sec rule'));
    });

    test('returns error for missing workspace_id', () async {
      final result = await tool.run({});
      expect(result.isError, isTrue);
    });
    test('inputSchema is a valid JSON Schema object', () {
      final schema = tool.inputSchema;
      expect(schema['type'], 'object');
      expect(schema['required'], contains('workspace_id'));
      expect(schema['required'], isNot(contains('domain')));
      expect(schema['properties'], contains('workspace_id'));
      expect(schema['properties'], contains('domain'));
      final schemaProps = schema['properties'] as Map<String, dynamic>;
      final wsProp = schemaProps['workspace_id'] as Map<String, dynamic>;
      expect(wsProp['type'], 'string');
      final domainProp = schemaProps['domain'] as Map<String, dynamic>;
      expect(domainProp['type'], 'string');
    });

    test('description is non-empty', () {
      expect(tool.description, isNotEmpty);
    });

    test('workspace_id as int returns error', () async {
      final result = await tool.run({'workspace_id': 42});
      expect(result.isError, isTrue);
      expect(result.content.first.text, contains('Missing workspace_id'));
    });

    test('workspace_id as null returns error', () async {
      final result = await tool.run({'workspace_id': null});
      expect(result.isError, isTrue);
      expect(result.content.first.text, contains('Missing workspace_id'));
    });

    test('workspace_id as bool returns error', () async {
      final result = await tool.run({'workspace_id': true});
      expect(result.isError, isTrue);
      expect(result.content.first.text, contains('Missing workspace_id'));
    });

    test('domain filter as empty string returns no matches', () async {
      final now = DateTime(2026, 5, 22);
      fakeRepo._policies.add(MemoryPolicy(
        id: 'p-1', workspaceId: 'ws-1', domain: 'tech-stack',
        rule: 'Use Drift for DB', active: true, createdAt: now, updatedAt: now,
      ));

      final result = await tool.run({
        'workspace_id': 'ws-1',
        'domain': '',
      });
      expect(result.isError, isFalse);
      expect(result.content.first.text, contains('"policies":[]'));
    });

    test('domain filter as null returns all policies', () async {
      final now = DateTime(2026, 5, 22);
      fakeRepo._policies.addAll([
        MemoryPolicy(
          id: 'p-1', workspaceId: 'ws-1', domain: 'tech-stack',
          rule: 'Tech rule', active: true, createdAt: now, updatedAt: now,
        ),
        MemoryPolicy(
          id: 'p-2', workspaceId: 'ws-1', domain: 'security',
          rule: 'Sec rule', active: true, createdAt: now, updatedAt: now,
        ),
      ]);

      final result = await tool.run({
        'workspace_id': 'ws-1',
        'domain': null,
      });
      expect(result.isError, isFalse);
      expect(result.content.first.text, contains('Tech rule'));
      expect(result.content.first.text, contains('Sec rule'));
    });

    test('inactive policies are excluded', () async {
      final now = DateTime(2026, 5, 22);
      fakeRepo._policies.addAll([
        MemoryPolicy(
          id: 'p-1', workspaceId: 'ws-1', domain: 'tech-stack',
          rule: 'Active rule', active: true, createdAt: now, updatedAt: now,
        ),
        MemoryPolicy(
          id: 'p-2', workspaceId: 'ws-1', domain: 'tech-stack',
          rule: 'Inactive rule', active: false, createdAt: now, updatedAt: now,
        ),
      ]);

      final result = await tool.run({'workspace_id': 'ws-1'});
      expect(result.isError, isFalse);
      expect(result.content.first.text, contains('Active rule'));
      expect(result.content.first.text, isNot(contains('Inactive rule')));
    });

    test('multiple domains, filter only returns matching domain', () async {
      final now = DateTime(2026, 5, 22);
      fakeRepo._policies.addAll([
        MemoryPolicy(
          id: 'p-1', workspaceId: 'ws-1', domain: 'tech-stack',
          rule: 'Tech rule', active: true, createdAt: now, updatedAt: now,
        ),
        MemoryPolicy(
          id: 'p-2', workspaceId: 'ws-1', domain: 'security',
          rule: 'Sec rule', active: true, createdAt: now, updatedAt: now,
        ),
        MemoryPolicy(
          id: 'p-3', workspaceId: 'ws-1', domain: 'code-style',
          rule: 'Style rule', active: true, createdAt: now, updatedAt: now,
        ),
      ]);

      final result = await tool.run({
        'workspace_id': 'ws-1',
        'domain': 'security',
      });
      expect(result.isError, isFalse);
      final text = result.content.first.text;
      expect(text, contains('Sec rule'));
      expect(text, isNot(contains('Tech rule')));
      expect(text, isNot(contains('Style rule')));
    });

    test('policy JSON includes all expected fields', () async {
      final now = DateTime(2026, 5, 22);
      fakeRepo._policies.add(MemoryPolicy(
        id: 'p-1', workspaceId: 'ws-1', domain: 'tech-stack',
        rule: 'Use Drift for DB', active: true, createdAt: now, updatedAt: now,
        sourceFactIds: ['f-1', 'f-2'],
        requiredRole: AgentRole.coder,
      ));

      final result = await tool.run({'workspace_id': 'ws-1'});
      expect(result.isError, isFalse);
      final text = result.content.first.text;
      expect(text, contains('"id"'));
      expect(text, contains('"domain"'));
      expect(text, contains('"rule"'));
      expect(text, contains('"required_role"'));
      expect(text, contains('"source_fact_count"'));
      expect(text, contains('"active"'));
    });

    test('policy with required_role returns role name in JSON', () async {
      final now = DateTime(2026, 5, 22);
      fakeRepo._policies.add(MemoryPolicy(
        id: 'p-1', workspaceId: 'ws-1', domain: 'tech-stack',
        rule: 'Use Drift for DB', active: true, createdAt: now, updatedAt: now,
        requiredRole: AgentRole.reviewer,
      ));

      final result = await tool.run({'workspace_id': 'ws-1'});
      expect(result.isError, isFalse);
      expect(result.content.first.text, contains('"required_role":"reviewer"'));
    });

    test('policy with no required_role returns null', () async {
      final now = DateTime(2026, 5, 22);
      fakeRepo._policies.add(MemoryPolicy(
        id: 'p-1', workspaceId: 'ws-1', domain: 'tech-stack',
        rule: 'Use Drift for DB', active: true, createdAt: now, updatedAt: now,
      ));

      final result = await tool.run({'workspace_id': 'ws-1'});
      expect(result.isError, isFalse);
      expect(result.content.first.text, contains('"required_role":null'));
    });

    test('large number of policies all returned', () async {
      final now = DateTime(2026, 5, 22);
      for (var i = 0; i < 15; i++) {
        fakeRepo._policies.add(MemoryPolicy(
          id: 'p-$i', workspaceId: 'ws-1', domain: 'd-$i',
          rule: 'Rule $i', active: true, createdAt: now, updatedAt: now,
        ));
      }

      final result = await tool.run({'workspace_id': 'ws-1'});
      expect(result.isError, isFalse);
      final text = result.content.first.text;
      for (var i = 0; i < 15; i++) {
        expect(text, contains('"Rule $i"'));
      }
    });

    test('domain filter with no matches returns empty list', () async {
      final now = DateTime(2026, 5, 22);
      fakeRepo._policies.add(MemoryPolicy(
        id: 'p-1', workspaceId: 'ws-1', domain: 'tech-stack',
        rule: 'Tech rule', active: true, createdAt: now, updatedAt: now,
      ));

      final result = await tool.run({
        'workspace_id': 'ws-1',
        'domain': 'nonexistent',
      });
      expect(result.isError, isFalse);
      expect(result.content.first.text, contains('"policies":[]'));
    });

    test('response wraps policies in a policies key', () async {
      final now = DateTime(2026, 5, 22);
      fakeRepo._policies.add(MemoryPolicy(
        id: 'p-1', workspaceId: 'ws-1', domain: 'tech-stack',
        rule: 'Tech rule', active: true, createdAt: now, updatedAt: now,
      ));

      final result = await tool.run({'workspace_id': 'ws-1'});
      expect(result.isError, isFalse);
      final text = result.content.first.text;
      expect(text, contains('"policies":[{'));
    });
  });
}
