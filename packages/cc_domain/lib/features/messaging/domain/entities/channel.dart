import 'package:cc_domain/core/domain/value_objects/conversation_mode.dart';

/// A messaging channel (DM or group).
/// A DM has exactly 2 participants (user + 1 agent). A group has 3+ participants.
class Channel {
  /// Creates a new [Channel].
  Channel({
    required this.id,
    required this.name,
    required this.isDm,
    this.workspaceId,
    required this.createdAt,
    required this.updatedAt,
    this.mode = ConversationMode.chat,
    this.pipelineRunId,
  });

  /// Unique identifier.
  final String id;
  /// Display name (empty for DMs; their title is dynamically derived from the other participant).
  final String name;
  /// Whether this is a DM channel (exactly 2 participants).
  final bool isDm;
  /// Optional workspace identifier.
  final String? workspaceId;
  /// Creation timestamp.
  final DateTime createdAt;
  /// Last update timestamp.
  final DateTime updatedAt;
  /// Conversation mode (sandbox + tool-allowlist + system-prompt scope).
  final ConversationMode mode;

  /// Owning pipeline run when this conversation was spawned by a pipeline
  /// step. Non-null ⇒ pipeline-managed: hidden from the sidebar, surfaced only
  /// from the pipeline run / step detail. Null for user-facing conversations.
  final String? pipelineRunId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Channel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          isDm == other.isDm &&
          workspaceId == other.workspaceId &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt &&
          mode == other.mode &&
          pipelineRunId == other.pipelineRunId;

  @override
  int get hashCode =>
      Object.hash(id, name, isDm, workspaceId, createdAt, updatedAt, mode, pipelineRunId);

  /// Returns a copy with optional overrides.
  Channel copyWith({
    String? id,
    String? name,
    bool? isDm,
    String? workspaceId,
    bool removeWorkspaceId = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    ConversationMode? mode,
    String? pipelineRunId,
    bool removePipelineRunId = false,
  }) {
    return Channel(
      id: id ?? this.id,
      name: name ?? this.name,
      isDm: isDm ?? this.isDm,
      workspaceId: removeWorkspaceId ? null : (workspaceId ?? this.workspaceId),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      mode: mode ?? this.mode,
      pipelineRunId: removePipelineRunId ? null : (pipelineRunId ?? this.pipelineRunId),
    );
  }
}
