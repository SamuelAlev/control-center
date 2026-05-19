import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/space_kind.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/space_provisioning_status.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/space_provisioning_step.dart';

/// A messaging space: a named conversation with zero or more agents.
class Space {
  /// Creates a new [Space].
  Space({
    required this.id,
    required this.name,
    this.workspaceId,
    required this.createdAt,
    required this.updatedAt,
    this.mode = Mode.chat,
    this.provisioningStatus = SpaceProvisioningStatus.ready,
    this.provisioningStep,
    this.pipelineRunId,
    this.kind = SpaceKind.topic,
    this.archivedAt,
  });

  /// Unique identifier.
  final String id;

  /// Display name.
  final String name;

  /// Optional workspace identifier.
  final String? workspaceId;

  /// Creation timestamp.
  final DateTime createdAt;

  /// Last update timestamp.
  final DateTime updatedAt;

  /// Provisioning state of the conversation workspace (repos + overlay +
  /// `.mcp.json`). Dispatch is gated on [SpaceProvisioningStatus.ready].
  final SpaceProvisioningStatus provisioningStatus;

  /// The granular step an in-flight provision is currently on ("cloning repo
  /// X", "setting up agent Y"). Non-null only while [provisioningStatus] is
  /// [SpaceProvisioningStatus.provisioning].
  final SpaceProvisioningStep? provisioningStep;

  /// Conversation mode (sandbox + tool-allowlist + system-prompt scope).
  final Mode mode;

  /// Owning pipeline run when this conversation was spawned by a pipeline
  /// step. Non-null ⇒ pipeline-managed: hidden from the sidebar, surfaced only
  /// from the pipeline run / step detail. Null for user-facing conversations.
  final String? pipelineRunId;

  /// How this space came to exist (PRD 22 §1). Defaults to
  /// [SpaceKind.topic]; agent↔agent peer spaces carry
  /// [SpaceKind.agentPeer] so clients can section them separately and
  /// mute them by default.
  final SpaceKind kind;

  /// Soft-archive timestamp. Non-null ⇒ archived: hidden from the sidebar,
  /// the space-activity feed and agent-facing space lists, restorable from
  /// the archived-spaces dialog. Everything underneath (messages,
  /// participants, worktrees) survives — archiving is a hide, not a delete.
  final DateTime? archivedAt;

  /// Whether this space is archived (soft-hidden).
  bool get isArchived => archivedAt != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Space &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          workspaceId == other.workspaceId &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt &&
          provisioningStatus == other.provisioningStatus &&
          provisioningStep == other.provisioningStep &&
          mode == other.mode &&
          pipelineRunId == other.pipelineRunId &&
          kind == other.kind &&
          archivedAt == other.archivedAt;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    workspaceId,
    createdAt,
    updatedAt,
    provisioningStatus,
    provisioningStep,
    mode,
    pipelineRunId,
    kind,
    archivedAt,
  );

  /// Returns a copy with optional overrides.
  Space copyWith({
    String? id,
    String? name,
    String? workspaceId,
    bool removeWorkspaceId = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    SpaceProvisioningStatus? provisioningStatus,
    SpaceProvisioningStep? provisioningStep,
    bool removeProvisioningStep = false,
    Mode? mode,
    String? pipelineRunId,
    bool removePipelineRunId = false,
    SpaceKind? kind,
    DateTime? archivedAt,
    bool removeArchivedAt = false,
  }) {
    return Space(
      id: id ?? this.id,
      name: name ?? this.name,
      workspaceId: removeWorkspaceId ? null : (workspaceId ?? this.workspaceId),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      provisioningStatus: provisioningStatus ?? this.provisioningStatus,
      provisioningStep: removeProvisioningStep
          ? null
          : (provisioningStep ?? this.provisioningStep),
      mode: mode ?? this.mode,
      pipelineRunId: removePipelineRunId
          ? null
          : (pipelineRunId ?? this.pipelineRunId),
      kind: kind ?? this.kind,
      archivedAt: removeArchivedAt ? null : (archivedAt ?? this.archivedAt),
    );
  }
}
