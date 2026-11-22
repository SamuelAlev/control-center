/// The `AgentDto` wire shape of an agent: what the `agents.*` ops send and
/// what `agents.upsert` reads back.
library;

import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/value_objects/agent_lifecycle_status.dart';
import 'package:cc_domain/core/domain/value_objects/agent_role.dart';
import 'package:cc_domain/core/domain/value_objects/agent_skills.dart';
import 'package:cc_domain/core/domain/value_objects/agent_visibility.dart';

/// Maps an [Agent] to the `AgentDto` wire shape (enum fields as `.name`).
Map<String, dynamic> agentToWire(Agent a) => {
  'id': a.id,
  'name': a.name,
  'title': a.title,
  'agent_md_path': a.agentMdPath,
  'workspace_id': a.workspaceId,
  'skills': a.skills.toList(),
  'reports_to': ?a.reportsTo,
  'persona': ?a.persona,
  'system_prompt': ?a.systemPrompt,
  'adapter_id': ?a.adapterId,
  'model_id': ?a.modelId,
  'strict_mode': a.strictMode,
  'effort': ?a.effort,
  'context_size': ?a.contextSize,
  'role': ?a.role?.name,
  'monthly_budget_micros': a.monthlyBudgetMicros,
  'silence_timeout_minutes': ?a.silenceTimeoutMinutes,
  'max_concurrent_tasks': a.maxConcurrentTasks,
  'visibility': a.visibility.name,
  'lifecycle_status': a.lifecycleStatus.name,
  'budget_policy_id': ?a.budgetPolicyId,
  'runtime_profile_id': ?a.runtimeProfileId,
  'created_at': a.createdAt.toIso8601String(),
};

/// Reconstructs an [Agent] from an `AgentDto` wire map (the inverse of
/// [agentToWire]), used by the `agents.upsert` op.
Agent agentFromWire(Map<String, dynamic> w) {
  return Agent(
    id: w['id'] as String,
    name: w['name'] as String? ?? '',
    title: w['title'] as String? ?? '',
    agentMdPath: w['agent_md_path'] as String? ?? '',
    workspaceId: w['workspace_id'] as String? ?? '',
    skills: AgentSkills(
      ((w['skills'] as List?) ?? const []).map((s) => s.toString()).toList(),
    ),
    reportsTo: w['reports_to'] as String?,
    persona: w['persona'] as String?,
    systemPrompt: w['system_prompt'] as String?,
    adapterId: w['adapter_id'] as String?,
    modelId: w['model_id'] as String?,
    strictMode: w['strict_mode'] as bool? ?? false,
    effort: w['effort'] as String?,
    contextSize: (w['context_size'] as num?)?.toInt(),
    role: w['role'] == null ? null : AgentRole.values.asNameMap()[w['role']],
    monthlyBudgetMicros: (w['monthly_budget_micros'] as num?)?.toInt() ?? 0,
    silenceTimeoutMinutes: (w['silence_timeout_minutes'] as num?)?.toInt(),
    maxConcurrentTasks: (w['max_concurrent_tasks'] as num?)?.toInt() ?? 1,
    visibility: AgentVisibility.fromStorage(w['visibility'] as String?),
    lifecycleStatus: AgentLifecycleStatus.fromStorage(
      w['lifecycle_status'] as String?,
    ),
    budgetPolicyId: w['budget_policy_id'] as String?,
    runtimeProfileId: w['runtime_profile_id'] as String?,
    createdAt: w['created_at'] is String
        ? DateTime.parse(w['created_at'] as String)
        : DateTime.fromMillisecondsSinceEpoch(0),
  );
}
