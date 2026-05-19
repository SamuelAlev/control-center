import 'dart:async';

import 'package:control_center/core/domain/entities/agent.dart';
import 'package:control_center/core/domain/repositories/agent_repository.dart';

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
        (agents) =>
            agents.where((a) => a.workspaceId == workspaceId).toList(),
      );

  @override
  Future<Agent?> getById(String id) async {
    try {
      return _agents.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Agent?> findByWorkspaceAndName(
    String workspaceId,
    String name,
  ) async {
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
  Future<void> delete(String id) async {
    _agents.removeWhere((a) => a.id == id);
    emit();
  }

  void dispose() => _controller.close();
}
