import 'package:cc_domain/core/domain/value_objects/agent_capabilities.dart';
import 'package:cc_domain/core/domain/value_objects/agent_lifecycle_status.dart';
import 'package:cc_domain/core/domain/value_objects/agent_role.dart';
import 'package:cc_domain/core/domain/value_objects/agent_skills.dart';
import 'package:cc_domain/core/domain/value_objects/agent_visibility.dart';

/// Agent entity representing an AI worker in the domain.
///
/// Agents have a hierarchy (via `reportsTo`), a skill set and optional
/// persona / prompt overrides. They are instantiated from `.md` files on disk.
class Agent {
  /// Creates a new [Agent].
  Agent({
    required this.id,
    required this.name,
    required this.title,
    required this.agentMdPath,
    required this.workspaceId,
    this.reportsTo,
    required this.skills,
    this.persona,
    this.systemPrompt,
    this.adapterId,
    this.modelId,
    this.strictMode = false,
    this.effort,
    this.contextSize,
    this.role,
    this.capabilities,
    this.monthlyBudgetCents = 0,
    this.silenceTimeoutMinutes,
    this.maxConcurrentTasks = 1,
    this.visibility = AgentVisibility.workspace,
    this.lifecycleStatus = AgentLifecycleStatus.active,
    this.budgetPolicyId,
    this.runtimeProfileId,
    required this.createdAt,
  }) {
    if (name.isEmpty) {
      throw ArgumentError('Agent name must not be empty');
    }
    if (title.isEmpty) {
      throw ArgumentError('Agent title must not be empty');
    }
    final silence = silenceTimeoutMinutes;
    if (silence != null && (silence < 1 || silence > 240)) {
      throw ArgumentError('silenceTimeoutMinutes must be null or in 1..240');
    }
  }

  /// Unique agent identifier.
  final String id;

  /// Display name.
  final String name;

  /// Job title (e.g., "Senior Flutter Engineer").
  final String title;

  /// Absolute path to the agent's `.md` definition file.
  final String agentMdPath;

  /// Id of the workspace this agent belongs to. Every agent is owned by exactly
  /// one workspace — this is the isolation boundary, so it is never null.
  final String workspaceId;

  /// Id of the agent this one reports to, if any.
  final String? reportsTo;

  /// Skills assigned to this agent.
  final AgentSkills skills;

  /// Optional persona description.
  final String? persona;

  /// Optional system prompt override.
  final String? systemPrompt;

  /// Inference adapter id, if any.
  final String? adapterId;

  /// Model id, if any.
  final String? modelId;

  /// Whether the agent runs in strict mode.
  final bool strictMode;

  /// Reasoning level id (e.g. 'low', 'xhigh'), sourced from the selected
  /// model's `thinkingLevels`. Per-adapter vocabularies come from the model
  /// spec; the column stores the raw id string.
  final String? effort;

  /// Context window size, if configured.
  final int? contextSize;

  /// Per-agent sandbox capability default. When null, the user-level default
  /// applies at dispatch time. Individual conversations can still override.
  final AgentCapabilities? capabilities;

  /// Agent role (e.g. ceo, coder, reviewer). Null for legacy agents.
  final AgentRole? role;

  /// Monthly budget in cents. Defaults to zero (unlimited).
  final int monthlyBudgetCents;

  /// Per-agent silence-timeout override in minutes (1..240). When null the
  /// per-mode default applies at dispatch time.
  final int? silenceTimeoutMinutes;

  /// Maximum tasks this agent may run concurrently (drives the presence
  /// workload model). Defaults to one.
  final int maxConcurrentTasks;

  /// Whether the agent is shared across the workspace or kept private.
  final AgentVisibility visibility;

  /// Governance lifecycle status. A non-active agent is not dispatchable.
  final AgentLifecycleStatus lifecycleStatus;

  /// Shared budget policy id this agent draws from, if any. Null means the
  /// per-agent [monthlyBudgetCents] applies directly.
  final String? budgetPolicyId;

  /// Custom runtime profile id backing this agent, if any.
  final String? runtimeProfileId;

  /// When the agent was created.
  final DateTime createdAt;

  /// Whether this agent may currently be dispatched (lifecycle is active).
  bool get isDispatchable => lifecycleStatus.isDispatchable;

  /// True when the agent has a non-empty persona.
  bool get hasPersona => persona != null && persona!.isNotEmpty;

  /// True when this agent has no reporting line (top-level).
  bool get isTopLevel => reportsTo == null;

  /// True when the agent has the named skill (case-insensitive).
  bool hasSkill(String skillName) => skills.hasSkill(skillName);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Agent &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          title == other.title &&
          agentMdPath == other.agentMdPath &&
          workspaceId == other.workspaceId &&
          reportsTo == other.reportsTo &&
          skills == other.skills &&
          persona == other.persona &&
          systemPrompt == other.systemPrompt &&
          adapterId == other.adapterId &&
          modelId == other.modelId &&
          strictMode == other.strictMode &&
          effort == other.effort &&
          contextSize == other.contextSize &&
          capabilities == other.capabilities &&
          role == other.role &&
          monthlyBudgetCents == other.monthlyBudgetCents &&
          silenceTimeoutMinutes == other.silenceTimeoutMinutes &&
          maxConcurrentTasks == other.maxConcurrentTasks &&
          visibility == other.visibility &&
          lifecycleStatus == other.lifecycleStatus &&
          budgetPolicyId == other.budgetPolicyId &&
          runtimeProfileId == other.runtimeProfileId &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hashAll([
    id,
    name,
    title,
    agentMdPath,
    workspaceId,
    reportsTo,
    skills,
    persona,
    systemPrompt,
    adapterId,
    modelId,
    strictMode,
    effort,
    contextSize,
    capabilities,
    role,
    monthlyBudgetCents,
    silenceTimeoutMinutes,
    maxConcurrentTasks,
    visibility,
    lifecycleStatus,
    budgetPolicyId,
    runtimeProfileId,
    createdAt,
  ]);

  /// Copy with.
  Agent copyWith({
    String? id,
    String? name,
    String? title,
    String? agentMdPath,
    String? workspaceId,
    String? reportsTo,
    bool removeReportsTo = false,
    AgentSkills? skills,
    String? persona,
    bool removePersona = false,
    String? systemPrompt,
    bool removeSystemPrompt = false,
    String? adapterId,
    bool removeAdapterId = false,
    String? modelId,
    bool removeModelId = false,
    bool? strictMode,
    String? effort,
    bool removeEffort = false,
    int? contextSize,
    bool removeContextSize = false,
    AgentCapabilities? capabilities,
    bool removeCapabilities = false,
    AgentRole? role,
    bool removeRole = false,
    int? monthlyBudgetCents,
    int? silenceTimeoutMinutes,
    bool removeSilenceTimeoutMinutes = false,
    int? maxConcurrentTasks,
    AgentVisibility? visibility,
    AgentLifecycleStatus? lifecycleStatus,
    String? budgetPolicyId,
    bool removeBudgetPolicyId = false,
    String? runtimeProfileId,
    bool removeRuntimeProfileId = false,
    DateTime? createdAt,
  }) {
    return Agent(
      id: id ?? this.id,
      name: name ?? this.name,
      title: title ?? this.title,
      agentMdPath: agentMdPath ?? this.agentMdPath,
      workspaceId: workspaceId ?? this.workspaceId,
      reportsTo: removeReportsTo ? null : (reportsTo ?? this.reportsTo),
      skills: skills ?? this.skills,
      persona: removePersona ? null : (persona ?? this.persona),
      systemPrompt: removeSystemPrompt
          ? null
          : (systemPrompt ?? this.systemPrompt),
      adapterId: removeAdapterId ? null : (adapterId ?? this.adapterId),
      modelId: removeModelId ? null : (modelId ?? this.modelId),
      strictMode: strictMode ?? this.strictMode,
      effort: removeEffort ? null : (effort ?? this.effort),
      contextSize: removeContextSize ? null : (contextSize ?? this.contextSize),
      capabilities: removeCapabilities
          ? null
          : (capabilities ?? this.capabilities),
      role: removeRole ? null : (role ?? this.role),
      monthlyBudgetCents: monthlyBudgetCents ?? this.monthlyBudgetCents,
      silenceTimeoutMinutes: removeSilenceTimeoutMinutes
          ? null
          : (silenceTimeoutMinutes ?? this.silenceTimeoutMinutes),
      maxConcurrentTasks: maxConcurrentTasks ?? this.maxConcurrentTasks,
      visibility: visibility ?? this.visibility,
      lifecycleStatus: lifecycleStatus ?? this.lifecycleStatus,
      budgetPolicyId: removeBudgetPolicyId
          ? null
          : (budgetPolicyId ?? this.budgetPolicyId),
      runtimeProfileId: removeRuntimeProfileId
          ? null
          : (runtimeProfileId ?? this.runtimeProfileId),
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
