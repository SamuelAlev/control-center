import 'dart:convert';

import 'package:cc_domain/core/domain/entities/memory_belief.dart';
import 'package:cc_domain/core/domain/entities/memory_fact.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_belief_repository.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_fact_repository.dart';
import 'package:cc_domain/features/memory/domain/usecases/harmonize_memory_use_case.dart';
import 'package:cc_mcp/src/tools/harmonize_memory_tool.dart';
import 'package:test/test.dart';

void main() {
  late HarmonizeMemoryTool tool;

  setUp(() {
    tool = HarmonizeMemoryTool(
      useCase: HarmonizeMemoryUseCase(
        factRepository: _FakeFacts(),
        beliefRepository: _FakeBeliefs(),
      ),
    );
  });

  test('missing workspace_id is refused', () async {
    final result = await tool.run(const {});
    expect(result.isError, isTrue);
    expect(result.content.first.text, contains('workspace_id'));
  });

  test('empty workspace emits no beliefs', () async {
    final result = await tool.run({'workspace_id': 'ws-1'});
    expect(result.isError, isFalse);
    final body = jsonDecode(result.content.first.text) as Map<String, dynamic>;
    expect(body['beliefs_emitted'], 0);
  });
}

class _FakeFacts implements MemoryFactRepository {
  @override
  Future<List<MemoryFact>> getActiveByWorkspace(String workspaceId) async =>
      const <MemoryFact>[];

  @override
  dynamic noSuchMethod(Invocation invocation) {}
}

class _FakeBeliefs implements MemoryBeliefRepository {
  @override
  Future<void> replaceWorkspace(
    String workspaceId,
    List<MemoryBelief> beliefs,
  ) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) {}
}
