import 'package:cc_domain/core/domain/value_objects/agent_role.dart';
import 'package:cc_domain/features/memory/domain/value_objects/memory_type.dart';
import 'package:cc_domain/features/memory/domain/value_objects/memory_veracity.dart';
import 'package:collection/collection.dart';

/// A fact stored in an agent's long-term (episodic) memory.
class MemoryFact {
  /// Creates a new [MemoryFact].
  MemoryFact({
    required this.id,
    required this.workspaceId,
    required this.domain,
    required this.topic,
    required this.content,
    this.sourceObservationIds = const [],
    this.confidence = 1.0,
    this.supersededBy,
    this.authoredByAgentId,
    this.authoredByRole,
    this.memoryType = MemoryType.fact,
    this.veracity = MemoryVeracity.stated,
    this.validUntil,
    this.recallCount = 0,
    this.lastRecalledAt,
    this.temporalTags = const [],
    this.mentionCount = 1,
    required this.createdAt,
    required this.updatedAt,
  }) : assert(workspaceId.isNotEmpty, 'MemoryFact workspaceId must not be empty'),
       assert(topic.isNotEmpty, 'MemoryFact topic must not be empty'),
       assert(confidence >= 0 && confidence <= 1, 'MemoryFact confidence must be 0-1');

  /// Unique identifier.
  final String id;
  /// Workspace this fact belongs to.
  final String workspaceId;
  /// Memory domain (e.g. "preferences", "codebase").
  final String domain;
  /// Topic within the domain.
  final String topic;
  /// Fact content.
  final String content;
  /// Ids of observations that sourced this fact.
  final List<String> sourceObservationIds;
  /// Confidence score, 0.0 to 1.0.
  final double confidence;
  /// Id of the fact that superseded this one, if any.
  final String? supersededBy;
  /// Id of the agent that authored this fact, if known.
  final String? authoredByAgentId;
  /// Role of the authoring agent, if known.
  final AgentRole? authoredByRole;
  /// Typed classification, driving Weibull decay and surfacing.
  final MemoryType memoryType;
  /// Provenance, driving the Bayesian confidence weight.
  final MemoryVeracity veracity;
  /// Explicit expiry: the fact is treated as expired/superseded past this time.
  final DateTime? validUntil;
  /// How many times this fact has been returned by recall.
  final int recallCount;
  /// When the fact was last returned by recall.
  final DateTime? lastRecalledAt;
  /// Free-form temporal tags extracted from the content (e.g. "last week").
  final List<String> temporalTags;
  /// How many times this fact has been (re-)asserted; feeds Bayesian updates.
  final int mentionCount;
  /// When the fact was created.
  final DateTime createdAt;
  /// When the fact was last updated.
  final DateTime updatedAt;

  /// Whether this fact has been superseded.
  bool get isSuperseded => supersededBy != null;

  /// Whether this fact's explicit [validUntil] expiry has passed as of [now].
  bool isExpired([DateTime? now]) {
    final until = validUntil;
    if (until == null) {
      return false;
    }
    return (now ?? DateTime.now()).isAfter(until);
  }

  /// Structural equality check (excludes recall churn + timestamps).
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MemoryFact &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          workspaceId == other.workspaceId &&
          domain == other.domain &&
          topic == other.topic &&
          content == other.content &&
          const ListEquality<String>().equals(sourceObservationIds, other.sourceObservationIds) &&
          supersededBy == other.supersededBy &&
          confidence == other.confidence &&
          authoredByAgentId == other.authoredByAgentId &&
          authoredByRole == other.authoredByRole &&
          memoryType == other.memoryType &&
          veracity == other.veracity &&
          validUntil == other.validUntil &&
          mentionCount == other.mentionCount &&
          const ListEquality<String>().equals(temporalTags, other.temporalTags);

  /// Hash code based on the equality fields.
  @override
  int get hashCode => Object.hash(
    id, workspaceId, domain, topic, content,
    Object.hashAll(sourceObservationIds),
    supersededBy, confidence,
    authoredByAgentId, authoredByRole,
    memoryType, veracity, validUntil, mentionCount,
    Object.hashAll(temporalTags),
  );

  /// Returns a copy with optional field overrides.
  MemoryFact copyWith({
    String? id,
    String? workspaceId,
    String? domain,
    String? topic,
    String? content,
    List<String>? sourceObservationIds,
    double? confidence,
    String? supersededBy,
    bool clearSupersededBy = false,
    String? authoredByAgentId,
    AgentRole? authoredByRole,
    MemoryType? memoryType,
    MemoryVeracity? veracity,
    DateTime? validUntil,
    bool clearValidUntil = false,
    int? recallCount,
    DateTime? lastRecalledAt,
    List<String>? temporalTags,
    int? mentionCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MemoryFact(
      id: id ?? this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      domain: domain ?? this.domain,
      topic: topic ?? this.topic,
      content: content ?? this.content,
      sourceObservationIds: sourceObservationIds ?? this.sourceObservationIds,
      confidence: confidence ?? this.confidence,
      supersededBy: clearSupersededBy ? null : (supersededBy ?? this.supersededBy),
      authoredByAgentId: authoredByAgentId ?? this.authoredByAgentId,
      authoredByRole: authoredByRole ?? this.authoredByRole,
      memoryType: memoryType ?? this.memoryType,
      veracity: veracity ?? this.veracity,
      validUntil: clearValidUntil ? null : (validUntil ?? this.validUntil),
      recallCount: recallCount ?? this.recallCount,
      lastRecalledAt: lastRecalledAt ?? this.lastRecalledAt,
      temporalTags: temporalTags ?? this.temporalTags,
      mentionCount: mentionCount ?? this.mentionCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}