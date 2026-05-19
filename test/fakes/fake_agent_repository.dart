import 'dart:async';

import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';

class FakeAgentRepository implements AgentRepository {
  final List<Agent> _agents = [];
  final _controller = StreamController<List<Agent>>.broadcast();

  List<Agent> get saved => List.unmodifiable(_agents);

  void emit() => _controller.add(List.unmodifiable(_agents));

  @override
  Stream<List<Agent>> watchAll() => _controller.stream;

  @override
  Stream<List<Agent>> watchByWorkspace(String workspaceId) =>
      _controller.stream.map(
        (agents) => agents.where((a) => a.workspaceId == workspaceId).toList(),
      );

  @override
  Future<Agent?> getById(String workspaceId, String id) async {
    for (final a in _agents) {
      // Scoped, not id-only: an agent id from another workspace must not
      // resolve, mirroring the per-workspace database file.
      if (a.id == id && a.workspaceId == workspaceId) {
        return a;
      }
    }
    return null;
  }

  @override
  Future<Agent?> findByWorkspaceAndName(String workspaceId, String name) async {
    for (final a in _agents) {
      if (a.workspaceId == workspaceId && a.name == name) {
        return a;
      }
    }
    return null;
  }

  @override
  Future<void> upsert(Agent agent) async {
    final index = _agents.indexWhere((a) => a.id == agent.id);
    if (index >= 0) {
      _agents[index] = agent;
    } else {
      _agents.add(agent);
    }
    emit();
  }

  @override
  Future<void> delete(String workspaceId, String id) async {
    _agents.removeWhere((a) => a.id == id && a.workspaceId == workspaceId);
    emit();
  }

  void dispose() => _controller.close();
}
