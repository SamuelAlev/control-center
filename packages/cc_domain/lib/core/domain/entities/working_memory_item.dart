import 'package:cc_domain/features/memory/domain/value_objects/memory_type.dart';
import 'package:cc_domain/features/memory/domain/value_objects/memory_veracity.dart';

/// An item in the hot, session-scoped working-memory tier. A consolidation
/// `sleep()` pass rolls consolidatable items into durable `MemoryFact`s and
/// evicts the rest by TTL/limit. Ported from oh-my-pi mnemopi `working_memory`.
class WorkingMemoryItem {
  /// Creates a [WorkingMemoryItem].
  WorkingMemoryItem({
    required this.id,
    required this.workspaceId,
    required this.agentId,
    required this.content,
    this.sessionId,
    this.memoryType = MemoryType.observation,
    this.veracity = MemoryVeracity.inferred,
    this.importance = 0.5,
    required this.createdAt,
    this.expiresAt,
  })  : assert(workspaceId.isNotEmpty, 'WorkingMemoryItem workspaceId must not be empty'),
        assert(agentId.isNotEmpty, 'WorkingMemoryItem agentId must not be empty');

  /// Unique identifier.
  final String id;
  /// Owning workspace.
  final String workspaceId;
  /// Agent this hot item belongs to.
  final String agentId;
  /// Item content.
  final String content;
  /// Optional session/run grouping key.
  final String? sessionId;
  /// Inferred memory type.
  final MemoryType memoryType;
  /// Provenance.
  final MemoryVeracity veracity;
  /// Importance in `[0,1]`.
  final double importance;
  /// When created.
  final DateTime createdAt;
  /// Optional TTL expiry.
  final DateTime? expiresAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkingMemoryItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          workspaceId == other.workspaceId &&
          agentId == other.agentId &&
          content == other.content &&
          sessionId == other.sessionId &&
          memoryType == other.memoryType &&
          veracity == other.veracity &&
          importance == other.importance;

  @override
  int get hashCode => Object.hash(
        id,
        workspaceId,
        agentId,
        content,
        sessionId,
        memoryType,
        veracity,
        importance,
      );
}