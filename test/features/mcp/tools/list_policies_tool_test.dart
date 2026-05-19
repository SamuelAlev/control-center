import 'package:control_center/core/domain/entities/memory_policy.dart';
import 'package:control_center/features/mcp/application/tools/list_policies_tool.dart';
import 'package:control_center/features/memory/domain/repositories/memory_policy_repository.dart';
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
  Future<MemoryPolicy?> getById(String id) async => null;

  @override
  Future<void> delete(String id) async {}
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
  });
}
