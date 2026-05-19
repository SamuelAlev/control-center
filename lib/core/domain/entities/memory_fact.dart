import 'package:collection/collection.dart';
import 'package:control_center/core/domain/value_objects/agent_role.dart';

/// A fact stored in an agent's long-term memory.
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
  /// When the fact was created.
  final DateTime createdAt;
  /// When the fact was last updated.
  final DateTime updatedAt;

  /// Whether this fact has been superseded.
  bool get isSuperseded => supersededBy != null;

  /// Structural equality check.
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
          authoredByRole == other.authoredByRole;

  /// Hash code based on all fields.
  @override
  int get hashCode => Object.hash(
    id, workspaceId, domain, topic, content,
    Object.hashAll(sourceObservationIds),
    supersededBy, confidence,
    authoredByAgentId, authoredByRole,
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
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
