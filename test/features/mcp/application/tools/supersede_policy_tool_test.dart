import 'dart:convert';

import 'package:control_center/core/domain/entities/memory_policy.dart';
import 'package:control_center/features/mcp/application/tools/supersede_policy_tool.dart';
import 'package:control_center/features/memory/domain/usecases/supersede_policy_use_case.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../fakes/fake_memory_repositories.dart';

void main() {
  group('SupersedePolicyTool', () {
    late FakeMemoryPolicyRepository fakePolicyRepo;
    late SupersedePolicyUseCase useCase;
    late SupersedePolicyTool tool;
    late DateTime now;

    setUp(() {
      now = DateTime(2026, 6, 1);
      fakePolicyRepo = FakeMemoryPolicyRepository();
      useCase = SupersedePolicyUseCase(policyRepository: fakePolicyRepo);
      tool = SupersedePolicyTool(useCase: useCase);
    });

    MemoryPolicy seedPolicy({
      String id = 'p-1',
      String workspaceId = 'ws-1',
    }) {
      final policy = MemoryPolicy(
        id: id,
        workspaceId: workspaceId,
        domain: 'architecture',
        rule: 'Use Clean Architecture layering.',
        createdAt: now,
        updatedAt: now,
      );
      fakePolicyRepo.seed([policy]);
      return policy;
    }

    test('name is supersede_policy', () {
      expect(tool.name, 'supersede_policy');
    });

    test('inputSchema requires workspace_id and policy_id', () {
      final schema = tool.inputSchema;
      expect(schema['type'], 'object');
      expect(schema['required'], containsAll(['workspace_id', 'policy_id']));
    });

    test('returns error for missing workspace_id', () async {
      final result = await tool.run({'policy_id': 'p-1'});
      expect(result.isError, isTrue);
    });

    test('returns error for missing policy_id', () async {
      final result = await tool.run({'workspace_id': 'ws-1'});
      expect(result.isError, isTrue);
    });

    test('returns error for non-string workspace_id', () async {
      final result = await tool.run({'workspace_id': 42, 'policy_id': 'p-1'});
      expect(result.isError, isTrue);
    });

    test('returns error for non-string policy_id', () async {
      final result = await tool.run({'workspace_id': 'ws-1', 'policy_id': 7});
      expect(result.isError, isTrue);
    });

    test('retires a policy and returns the superseded record', () async {
      seedPolicy(id: 'p-1');

      final result =
          await tool.run({'workspace_id': 'ws-1', 'policy_id': 'p-1'});

      expect(result.isError, isFalse);
      final response =
          jsonDecode(result.content.first.text) as Map<String, dynamic>;
      expect(response['policy_id'], 'p-1');
      expect(response['domain'], 'architecture');
      expect(response['status'], 'superseded');

      final stored = await fakePolicyRepo.getById('ws-1', 'p-1');
      expect(stored!.active, isFalse);
    });

    test('returns error when the policy is not found', () async {
      final result =
          await tool.run({'workspace_id': 'ws-1', 'policy_id': 'nope'});

      expect(result.isError, isTrue);
      expect(result.content.first.text, contains('Policy not found'));
    });

    test('scopes lookup to workspace_id — no cross-workspace retire', () async {
      seedPolicy(id: 'p-1', workspaceId: 'ws-2');

      final result =
          await tool.run({'workspace_id': 'ws-1', 'policy_id': 'p-1'});

      expect(result.isError, isTrue);
      expect(result.content.first.text, contains('Policy not found'));

      // The foreign workspace's policy stays active.
      final stored = await fakePolicyRepo.getById('ws-2', 'p-1');
      expect(stored!.active, isTrue);
    });
  });
}
