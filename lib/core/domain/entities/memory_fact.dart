import 'package:collection/collection.dart';
import 'package:control_center/core/domain/value_objects/agent_role.dart';

class MemoryFact {
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

  final String id;
  final String workspaceId;
  final String domain;
  final String topic;
  final String content;
  final List<String> sourceObservationIds;
  final double confidence;
  final String? supersededBy;
  final String? authoredByAgentId;
  final AgentRole? authoredByRole;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isSuperseded => supersededBy != null;

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

  @override
  int get hashCode => Object.hash(
    id, workspaceId, domain, topic, content,
    Object.hashAll(sourceObservationIds),
    supersededBy, confidence,
    authoredByAgentId, authoredByRole,
  );

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
