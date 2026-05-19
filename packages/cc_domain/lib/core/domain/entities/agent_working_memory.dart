/// Snapshot of an agent's current working memory, serialized as a string blob.
class AgentWorkingMemory {
  /// Creates a new [AgentWorkingMemory].
  AgentWorkingMemory({
    required this.id,
    required this.workspaceId,
    required this.agentId,
    required this.content,
    required this.updatedAt,
  }) : assert(agentId.isNotEmpty, 'AgentWorkingMemory agentId must not be empty'),
       assert(workspaceId.isNotEmpty, 'AgentWorkingMemory workspaceId must not be empty');

  /// Unique identifier.
  final String id;
  /// Id of the workspace this memory belongs to.
  final String workspaceId;
  /// Id of the agent this memory belongs to.
  final String agentId;
  /// Serialized working memory content blob.
  final String content;
  /// When the content was last updated.
  final DateTime updatedAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AgentWorkingMemory &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          workspaceId == other.workspaceId &&
          agentId == other.agentId &&
          content == other.content &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(id, workspaceId, agentId, content, updatedAt);

  /// Returns a copy with optional field overrides.
  AgentWorkingMemory copyWith({
    String? id,
    String? workspaceId,
    String? agentId,
    String? content,
    DateTime? updatedAt,
  }) {
    return AgentWorkingMemory(
      id: id ?? this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      agentId: agentId ?? this.agentId,
      content: content ?? this.content,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
