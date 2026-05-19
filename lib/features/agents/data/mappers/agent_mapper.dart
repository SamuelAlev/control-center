import 'package:control_center/core/database/app_database.dart';
import 'package:control_center/core/domain/entities/agent.dart';
import 'package:control_center/core/domain/value_objects/agent_capabilities.dart';
import 'package:control_center/core/domain/value_objects/agent_role.dart';
import 'package:control_center/core/domain/value_objects/agent_skills.dart';

/// Agent mapper.
class AgentMapper {
  /// Creates a new [AgentMapper].
  const AgentMapper();

  /// To domain.
  Agent toDomain(AgentsTableData row) {
    final skillsList = row.skills
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList(growable: false);
    return Agent(
      id: row.id,
      name: row.name,
      title: row.title,
      agentMdPath: row.agentMdPath,
      workspaceId: row.workspaceId,
      reportsTo: row.reportsTo,
      skills: AgentSkills(skillsList),
      persona: row.persona,
      systemPrompt: row.systemPrompt,
      adapterId: row.adapterId,
      modelId: row.modelId,
      strictMode: row.strictMode,
      effort: AgentEffort.tryParse(row.effort),
      contextSize: row.contextSize,
      capabilities: row.sandboxCapabilitiesJson.isEmpty
          ? null
          : AgentCapabilities.fromJsonString(row.sandboxCapabilitiesJson),
      role: AgentRole.tryParse(row.role),
      monthlyBudgetCents: row.monthlyBudgetCents,
      createdAt: row.createdAt,
    );
  }

  /// To domain list.
  List<Agent> toDomainList(List<AgentsTableData> rows) =>
      rows.map(toDomain).toList(growable: false);
}

