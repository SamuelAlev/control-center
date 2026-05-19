import 'dart:async';
import 'dart:typed_data';

import 'package:control_center/core/domain/entities/agent_working_memory.dart';
import 'package:control_center/core/domain/entities/memory_fact.dart';
import 'package:control_center/core/domain/entities/memory_policy.dart';
import 'package:control_center/features/memory/domain/repositories/agent_working_memory_repository.dart';
import 'package:control_center/features/memory/domain/repositories/memory_fact_repository.dart';
import 'package:control_center/features/memory/domain/repositories/memory_policy_repository.dart';

/// In-memory fake [MemoryFactRepository].
class FakeMemoryFactRepository implements MemoryFactRepository {
  final List<MemoryFact> _facts = [];

  /// Seed facts.
  void seed(List<MemoryFact> facts) => _facts.addAll(facts);

  @override
  Future<List<MemoryFact>> getByWorkspace(String workspaceId) async =>
      _facts.where((f) => f.workspaceId == workspaceId).toList();

  @override
  Stream<List<MemoryFact>> watchByWorkspace(String workspaceId) async* {
    yield _facts.where((f) => f.workspaceId == workspaceId).toList();
  }

  @override
  Future<MemoryFact?> getById(String id) async =>
      _facts.where((f) => f.id == id).firstOrNull;

  @override
  Future<void> upsert(MemoryFact fact) async {
    final idx = _facts.indexWhere((f) => f.id == fact.id);
    if (idx >= 0) {
      _facts[idx] = fact;
    } else {
      _facts.add(fact);
    }
  }

  @override
  Future<List<MemoryFact>> getActiveByTopic(
    String workspaceId,
    String topic,
  ) async =>
      _facts
          .where(
            (f) => f.workspaceId == workspaceId && f.topic == topic && !f.isSuperseded,
          )
          .toList();

  @override
  Future<List<MemoryFact>> search(
    String workspaceId,
    String query, {
    Float32List? queryEmbedding,
  }) async =>
      const [];

  @override
  Future<List<MemoryFact>> getByAuthor(String workspaceId, String agentId) async =>
      _facts
          .where(
            (f) => f.workspaceId == workspaceId && f.authoredByAgentId == agentId,
          )
          .toList();

  @override
  Future<void> delete(String id) async {
    _facts.removeWhere((f) => f.id == id);
  }
}

/// In-memory fake [MemoryPolicyRepository].
class FakeMemoryPolicyRepository implements MemoryPolicyRepository {
  final List<MemoryPolicy> _policies = [];

  /// Seed policies.
  void seed(List<MemoryPolicy> policies) => _policies.addAll(policies);

  @override
  Future<List<MemoryPolicy>> getByWorkspace(String workspaceId) async =>
      _policies.where((p) => p.workspaceId == workspaceId).toList();

  @override
  Stream<List<MemoryPolicy>> watchByWorkspace(String workspaceId) async* {
    yield _policies.where((p) => p.workspaceId == workspaceId).toList();
  }

  @override
  Future<MemoryPolicy?> getById(String id) async =>
      _policies.where((p) => p.id == id).firstOrNull;

  @override
  Future<void> upsert(MemoryPolicy policy) async {
    final idx = _policies.indexWhere((p) => p.id == policy.id);
    if (idx >= 0) {
      _policies[idx] = policy;
    } else {
      _policies.add(policy);
    }
  }

  @override
  Future<List<MemoryPolicy>> getActiveByWorkspace(
    String workspaceId, {
    String? domain,
  }) async {
    var result = _policies
        .where((p) => p.workspaceId == workspaceId && p.active);
    if (domain != null) {
      result = result.where((p) => p.domain == domain);
    }
    return result.toList();
  }

  @override
  Future<void> delete(String id) async {
    _policies.removeWhere((p) => p.id == id);
  }
}

/// In-memory fake [AgentWorkingMemoryRepository].
class FakeAgentWorkingMemoryRepository
    implements AgentWorkingMemoryRepository {
  final List<AgentWorkingMemory> _memories = [];

  /// Seed memories.
  void seed(List<AgentWorkingMemory> memories) => _memories.addAll(memories);

  @override
  Future<AgentWorkingMemory?> getByAgent(
    String workspaceId,
    String agentId,
  ) async {
    return _memories
        .where((m) => m.workspaceId == workspaceId && m.agentId == agentId)
        .firstOrNull;
  }

  @override
  Stream<AgentWorkingMemory?> watchByAgent(
    String workspaceId,
    String agentId,
  ) async* {
    yield await getByAgent(workspaceId, agentId);
  }

  @override
  Stream<List<AgentWorkingMemory>> watchByWorkspace(String workspaceId) async* {
    yield _memories.where((m) => m.workspaceId == workspaceId).toList();
  }

  @override
  Future<void> upsert(AgentWorkingMemory memory) async {
    final idx = _memories.indexWhere((m) => m.id == memory.id);
    if (idx >= 0) {
      _memories[idx] = memory;
    } else {
      _memories.add(memory);
    }
  }
}
