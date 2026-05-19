// Value objects keep their named JSON factories next to the fields they map,
// which reads more clearly than hoisting every factory above the data.
// ignore_for_file: sort_constructors_first

import 'dart:convert';

/// A role the orchestration needs. Either an existing agent fills it
/// ([existingAgentId] set) or it is hired from [hireSpec].
class ProposedRole {
  /// Creates a [ProposedRole].
  const ProposedRole({
    required this.roleKey,
    required this.title,
    this.existingAgentId,
    this.hireSpec,
  });

  /// Stable key referenced by sub-tickets and the synthesis step.
  final String roleKey;

  /// Human-readable role title (e.g. "Market analyst").
  final String title;

  /// When set, an existing agent fills this role.
  final String? existingAgentId;

  /// When set, a new agent is hired for this role on approval.
  final ProposedHire? hireSpec;

  /// Builds from JSON.
  factory ProposedRole.fromJson(Map<String, dynamic> json) => ProposedRole(
        roleKey: json['roleKey'] as String? ?? '',
        title: json['title'] as String? ?? '',
        existingAgentId: json['existingAgentId'] as String?,
        hireSpec: json['hireSpec'] is Map
            ? ProposedHire.fromJson(
                (json['hireSpec'] as Map).cast<String, dynamic>())
            : null,
      );

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
        'roleKey': roleKey,
        'title': title,
        if (existingAgentId != null) 'existingAgentId': existingAgentId,
        if (hireSpec != null) 'hireSpec': hireSpec!.toJson(),
      };

  /// Returns a copy with [existingAgentId] / [hireSpec] swapped (UI editing).
  ProposedRole copyWith({
    String? title,
    String? existingAgentId,
    bool clearExistingAgentId = false,
    ProposedHire? hireSpec,
    bool clearHireSpec = false,
  }) =>
      ProposedRole(
        roleKey: roleKey,
        title: title ?? this.title,
        existingAgentId:
            clearExistingAgentId ? null : (existingAgentId ?? this.existingAgentId),
        hireSpec: clearHireSpec ? null : (hireSpec ?? this.hireSpec),
      );
}

/// Spec for an agent to hire when materializing the orchestration.
class ProposedHire {
  /// Creates a [ProposedHire].
  const ProposedHire({
    required this.name,
    required this.title,
    this.skills = const [],
    this.persona = '',
    this.role,
  });

  /// Proposed agent name (slugified on hire).
  final String name;

  /// Agent title.
  final String title;

  /// Skill slugs to attach.
  final List<String> skills;

  /// Persona markdown body.
  final String persona;

  /// Optional semantic role (e.g. `coder`, `pm`).
  final String? role;

  /// Builds from JSON.
  factory ProposedHire.fromJson(Map<String, dynamic> json) => ProposedHire(
        name: json['name'] as String? ?? '',
        title: json['title'] as String? ?? '',
        skills: (json['skills'] as List?)?.whereType<String>().toList() ??
            const [],
        persona: json['persona'] as String? ?? '',
        role: json['role'] as String?,
      );

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
        'name': name,
        'title': title,
        'skills': skills,
        'persona': persona,
        if (role != null) 'role': role,
      };
}

/// A sub-ticket in the orchestration's work DAG.
class ProposedSubTicket {
  /// Creates a [ProposedSubTicket].
  const ProposedSubTicket({
    required this.key,
    required this.title,
    required this.roleKey,
    this.description = '',
    this.dependsOn = const [],
    this.expectedOutputSchema,
    this.priority = 'none',
  });

  /// Stable key for dependency wiring + the `out_<key>` state slot.
  final String key;

  /// Sub-ticket title.
  final String title;

  /// Role responsible (must resolve to a [ProposedRole.roleKey]).
  final String roleKey;

  /// Work description / prompt for the assigned agent.
  final String description;

  /// Keys of sub-tickets that must complete before this one starts.
  final List<String> dependsOn;

  /// Output contract the sub-ticket's `complete_ticket` payload must satisfy.
  final Map<String, dynamic>? expectedOutputSchema;

  /// Priority name (`none`/`low`/`medium`/`high`/`urgent`).
  final String priority;

  /// Builds from JSON.
  factory ProposedSubTicket.fromJson(Map<String, dynamic> json) =>
      ProposedSubTicket(
        key: json['key'] as String? ?? '',
        title: json['title'] as String? ?? '',
        roleKey: json['roleKey'] as String? ?? '',
        description: json['description'] as String? ?? '',
        dependsOn:
            (json['dependsOn'] as List?)?.whereType<String>().toList() ??
                const [],
        expectedOutputSchema: (json['expectedOutputSchema'] as Map?)
            ?.cast<String, dynamic>(),
        priority: json['priority'] as String? ?? 'none',
      );

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
        'key': key,
        'title': title,
        'roleKey': roleKey,
        'description': description,
        'dependsOn': dependsOn,
        if (expectedOutputSchema != null)
          'expectedOutputSchema': expectedOutputSchema,
        'priority': priority,
      };
}

/// Optional research phase that runs before the work DAG.
class ResearchSpec {
  /// Creates a [ResearchSpec].
  const ResearchSpec({required this.enabled, this.prompt = '', this.roleKey});

  /// Whether a research step is included.
  final bool enabled;

  /// Research prompt.
  final String prompt;

  /// Role that performs research (defaults to the synthesis role).
  final String? roleKey;

  /// Builds from JSON.
  factory ResearchSpec.fromJson(Map<String, dynamic> json) => ResearchSpec(
        enabled: json['enabled'] == true,
        prompt: json['prompt'] as String? ?? '',
        roleKey: json['roleKey'] as String?,
      );

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'prompt': prompt,
        if (roleKey != null) 'roleKey': roleKey,
      };
}

/// Optional bounded discussion round (each role posts a structured position).
class DiscussionSpec {
  /// Creates a [DiscussionSpec].
  const DiscussionSpec({required this.enabled, this.prompt = ''});

  /// Whether a discussion round is included. Default off (highest token cost).
  final bool enabled;

  /// Discussion prompt shared by all roles.
  final String prompt;

  /// Builds from JSON.
  factory DiscussionSpec.fromJson(Map<String, dynamic> json) => DiscussionSpec(
        enabled: json['enabled'] == true,
        prompt: json['prompt'] as String? ?? '',
      );

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {'enabled': enabled, 'prompt': prompt};
}

/// The final synthesis step that produces the deliverable.
class SynthesisSpec {
  /// Creates a [SynthesisSpec].
  const SynthesisSpec({
    required this.roleKey,
    required this.prompt,
    required this.outputSchema,
  });

  /// Role that performs synthesis (also the team leader).
  final String roleKey;

  /// Synthesis prompt.
  final String prompt;

  /// Output contract for the deliverable (must include a `gaps` array).
  final Map<String, dynamic> outputSchema;

  /// Builds from JSON.
  factory SynthesisSpec.fromJson(Map<String, dynamic> json) => SynthesisSpec(
        roleKey: json['roleKey'] as String? ?? '',
        prompt: json['prompt'] as String? ?? '',
        outputSchema:
            (json['outputSchema'] as Map?)?.cast<String, dynamic>() ?? const {},
      );

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
        'roleKey': roleKey,
        'prompt': prompt,
        'outputSchema': outputSchema,
      };
}

/// Budget for the whole orchestration.
class BudgetSpec {
  /// Creates a [BudgetSpec].
  const BudgetSpec({this.estimatedCostCents, this.maxCostCents});

  /// Estimated total cost in US cents.
  final int? estimatedCostCents;

  /// Hard spending limit in US cents.
  final int? maxCostCents;

  /// Builds from JSON.
  factory BudgetSpec.fromJson(Map<String, dynamic> json) => BudgetSpec(
        estimatedCostCents: (json['estimatedCostCents'] as num?)?.toInt(),
        maxCostCents: (json['maxCostCents'] as num?)?.toInt(),
      );

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
        if (estimatedCostCents != null) 'estimatedCostCents': estimatedCostCents,
        if (maxCostCents != null) 'maxCostCents': maxCostCents,
      };
}

/// The full structured plan an orchestrator proposes for one upfront approval.
class OrchestrationProposal {
  /// Creates an [OrchestrationProposal].
  const OrchestrationProposal({
    required this.goal,
    required this.roles,
    required this.subTickets,
    required this.synthesis,
    this.research = const ResearchSpec(enabled: false),
    this.discussion = const DiscussionSpec(enabled: false),
    this.budget = const BudgetSpec(),
  });

  /// The user's high-level goal.
  final String goal;

  /// Roles the orchestration uses.
  final List<ProposedRole> roles;

  /// Sub-tickets making up the work DAG.
  final List<ProposedSubTicket> subTickets;

  /// Optional research phase.
  final ResearchSpec research;

  /// Optional discussion round.
  final DiscussionSpec discussion;

  /// Final synthesis step.
  final SynthesisSpec synthesis;

  /// Budget.
  final BudgetSpec budget;

  /// Number of roles that need hiring.
  int get hireCount => roles.where((r) => r.hireSpec != null).length;

  /// Builds from a decoded JSON map.
  factory OrchestrationProposal.fromJson(Map<String, dynamic> json) =>
      OrchestrationProposal(
        goal: json['goal'] as String? ?? '',
        roles: (json['roles'] as List? ?? const [])
            .whereType<Map>()
            .map((m) => ProposedRole.fromJson(m.cast<String, dynamic>()))
            .toList(),
        subTickets: (json['subTickets'] as List? ?? const [])
            .whereType<Map>()
            .map((m) => ProposedSubTicket.fromJson(m.cast<String, dynamic>()))
            .toList(),
        research: json['research'] is Map
            ? ResearchSpec.fromJson((json['research'] as Map).cast())
            : const ResearchSpec(enabled: false),
        discussion: json['discussion'] is Map
            ? DiscussionSpec.fromJson((json['discussion'] as Map).cast())
            : const DiscussionSpec(enabled: false),
        synthesis: SynthesisSpec.fromJson(
            (json['synthesis'] as Map?)?.cast<String, dynamic>() ?? const {}),
        budget: json['budget'] is Map
            ? BudgetSpec.fromJson((json['budget'] as Map).cast())
            : const BudgetSpec(),
      );

  /// Parses from a JSON string.
  factory OrchestrationProposal.fromJsonString(String raw) =>
      OrchestrationProposal.fromJson(
          jsonDecode(raw) as Map<String, dynamic>);

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
        'goal': goal,
        'roles': roles.map((r) => r.toJson()).toList(),
        'subTickets': subTickets.map((s) => s.toJson()).toList(),
        'research': research.toJson(),
        'discussion': discussion.toJson(),
        'synthesis': synthesis.toJson(),
        'budget': budget.toJson(),
      };

  /// Serializes to a JSON string.
  String toJsonString() => jsonEncode(toJson());

  // Value identity is by canonical serialized form — two proposals are equal
  // iff they encode identically. (The nested value objects are immutable data
  // carriers reconstructed from JSON; deep per-field equality would duplicate
  // this.)
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrchestrationProposal && toJsonString() == other.toJsonString();

  @override
  int get hashCode => toJsonString().hashCode;

  /// Returns a copy replacing roles / sub-tickets / budget (UI editing).
  OrchestrationProposal copyWith({
    List<ProposedRole>? roles,
    List<ProposedSubTicket>? subTickets,
    BudgetSpec? budget,
    ResearchSpec? research,
    DiscussionSpec? discussion,
  }) =>
      OrchestrationProposal(
        goal: goal,
        roles: roles ?? this.roles,
        subTickets: subTickets ?? this.subTickets,
        synthesis: synthesis,
        research: research ?? this.research,
        discussion: discussion ?? this.discussion,
        budget: budget ?? this.budget,
      );
}
