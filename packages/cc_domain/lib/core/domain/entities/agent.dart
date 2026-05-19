import 'package:cc_domain/core/domain/value_objects/agent_capabilities.dart';
import 'package:cc_domain/core/domain/value_objects/agent_role.dart';
import 'package:cc_domain/core/domain/value_objects/agent_skills.dart';

/// Agent entity representing an AI worker in the domain.
///
/// Agents have a hierarchy (via `reportsTo`), a skill set, and optional
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
    required this.createdAt,
  }) : assert(name.isNotEmpty, 'Agent name must not be empty'),
       assert(title.isNotEmpty, 'Agent title must not be empty'),
       assert(
         silenceTimeoutMinutes == null ||
             (silenceTimeoutMinutes >= 1 && silenceTimeoutMinutes <= 240),
         'silenceTimeoutMinutes must be null or in 1..240',
       );

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

  /// When the agent was created.
  final DateTime createdAt;

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
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
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
    createdAt,
  );

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
      monthlyBudgetCents:
          monthlyBudgetCents ?? this.monthlyBudgetCents,
      silenceTimeoutMinutes: removeSilenceTimeoutMinutes
          ? null
          : (silenceTimeoutMinutes ?? this.silenceTimeoutMinutes),
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
