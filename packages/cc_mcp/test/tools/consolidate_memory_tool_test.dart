import 'dart:convert';

import 'package:cc_domain/core/domain/entities/working_memory_item.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_access_grant_repository.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_domain_repository.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_fact_repository.dart';
import 'package:cc_domain/features/memory/domain/repositories/working_memory_item_repository.dart';
import 'package:cc_domain/features/memory/domain/services/memory_consolidation_service.dart';
import 'package:cc_domain/features/memory/domain/usecases/record_memory_fact_use_case.dart';
import 'package:cc_domain/features/memory/domain/usecases/resolve_or_create_domain_use_case.dart';
import 'package:cc_mcp/src/tools/consolidate_memory_tool.dart';
import 'package:test/test.dart';

void main() {
  late ConsolidateMemoryTool tool;

  setUp(() {
    tool = ConsolidateMemoryTool(
      service: MemoryConsolidationService(
        workingMemory: _FakeWorkingMemory(),
        recordFact: RecordMemoryFactUseCase(
          factRepository: _FakeFacts(),
          resolveDomainUseCase: ResolveOrCreateDomainUseCase(
            domainRepository: _FakeDomains(),
            grantRepository: _FakeGrants(),
          ),
        ),
      ),
    );
  });

  test('missing workspace_id is refused', () async {
    final result = await tool.run(const {});
    expect(result.isError, isTrue);
    expect(result.content.first.text, contains('workspace_id'));
  });

  test('sleep on an empty workspace creates no facts', () async {
    final result = await tool.run({'workspace_id': 'ws-1'});
    expect(result.isError, isFalse);
    final body = jsonDecode(result.content.first.text) as Map<String, dynamic>;
    expect(body['facts_created'], 0);
  });
}

class _FakeWorkingMemory implements WorkingMemoryItemRepository {
  @override
  Future<int> deleteExpired(String workspaceId, DateTime now) async => 0;

  @override
  Future<List<WorkingMemoryItem>> getForWorkspace(String workspaceId) async =>
      const <WorkingMemoryItem>[];

  @override
  Future<List<WorkingMemoryItem>> getForAgent(
    String workspaceId,
    String agentId,
  ) async => const <WorkingMemoryItem>[];

  @override
  Future<void> recordConsolidationPass(ConsolidationPassReport report) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) {}
}

class _FakeFacts implements MemoryFactRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) {}
}

class _FakeDomains implements MemoryDomainRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) {}
}

class _FakeGrants implements MemoryAccessGrantRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) {}
}
