part of 'dtos.dart';

/// Agent wire DTO — the full shape needed to reconstruct an `Agent` entity on a
/// thin client (richer than the lossy `list_agents` MCP tool output).
class AgentDto {
  AgentDto({
    required this.id,
    required this.name,
    required this.title,
    required this.agentMdPath,
    required this.workspaceId,
    required this.skills,
    this.reportsTo,
    this.persona,
    this.systemPrompt,
    this.adapterId,
    this.modelId,
    this.strictMode = false,
    this.effort,
    this.contextSize,
    this.role,
    this.monthlyBudgetMicros = 0,
    this.silenceTimeoutMinutes,
    this.maxConcurrentTasks = 1,
    this.visibility = 'workspace',
    this.lifecycleStatus = 'active',
    this.budgetPolicyId,
    this.runtimeProfileId,
    this.createdAt,
  });

  factory AgentDto.fromJson(Map<String, dynamic> json) => AgentDto(
    id: json['id'] as String,
    name: json['name'] as String? ?? '',
    title: json['title'] as String? ?? '',
    agentMdPath: json['agent_md_path'] as String? ?? '',
    workspaceId: json['workspace_id'] as String? ?? '',
    skills: ((json['skills'] as List?) ?? const [])
        .map((s) => s.toString())
        .toList(),
    reportsTo: json['reports_to'] as String?,
    persona: json['persona'] as String?,
    systemPrompt: json['system_prompt'] as String?,
    adapterId: json['adapter_id'] as String?,
    modelId: json['model_id'] as String?,
    strictMode: json['strict_mode'] as bool? ?? false,
    effort: json['effort'] as String?,
    contextSize: (json['context_size'] as num?)?.toInt(),
    role: json['role'] as String?,
    monthlyBudgetMicros: (json['monthly_budget_micros'] as num?)?.toInt() ?? 0,
    silenceTimeoutMinutes: (json['silence_timeout_minutes'] as num?)?.toInt(),
    maxConcurrentTasks: (json['max_concurrent_tasks'] as num?)?.toInt() ?? 1,
    visibility: json['visibility'] as String? ?? 'workspace',
    lifecycleStatus: json['lifecycle_status'] as String? ?? 'active',
    budgetPolicyId: json['budget_policy_id'] as String?,
    runtimeProfileId: json['runtime_profile_id'] as String?,
    createdAt: json['created_at'] as String?,
  );

  final String id;
  final String name;
  final String title;
  final String agentMdPath;
  final String workspaceId;
  final List<String> skills;
  final String? reportsTo;
  final String? persona;
  final String? systemPrompt;
  final String? adapterId;
  final String? modelId;
  final bool strictMode;
  final String? effort;
  final int? contextSize;
  final String? role;
  final int monthlyBudgetMicros;
  final int? silenceTimeoutMinutes;

  /// Governance capability profile (PRD 09).
  final int maxConcurrentTasks;
  final String visibility;
  final String lifecycleStatus;
  final String? budgetPolicyId;
  final String? runtimeProfileId;

  /// ISO-8601 creation timestamp, when the host includes it.
  final String? createdAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'title': title,
    'agent_md_path': agentMdPath,
    'workspace_id': workspaceId,
    'skills': skills,
    'reports_to': ?reportsTo,
    'persona': ?persona,
    'system_prompt': ?systemPrompt,
    'adapter_id': ?adapterId,
    'model_id': ?modelId,
    'strict_mode': strictMode,
    'effort': ?effort,
    'context_size': ?contextSize,
    'role': ?role,
    'monthly_budget_micros': monthlyBudgetMicros,
    'silence_timeout_minutes': ?silenceTimeoutMinutes,
    'max_concurrent_tasks': maxConcurrentTasks,
    'visibility': visibility,
    'lifecycle_status': lifecycleStatus,
    'budget_policy_id': ?budgetPolicyId,
    'runtime_profile_id': ?runtimeProfileId,
    'created_at': ?createdAt,
  };
}
