import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/channel_origin.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/channel_provisioning_status.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/channel_provisioning_step.dart';

/// A messaging channel: a named conversation with zero or more agents.
class Channel {
  /// Creates a new [Channel].
  Channel({
    required this.id,
    required this.name,
    this.workspaceId,
    required this.createdAt,
    required this.updatedAt,
    this.mode = Mode.chat,
    this.provisioningStatus = ChannelProvisioningStatus.ready,
    this.provisioningStep,
    this.pipelineRunId,
    this.origin = ChannelOrigin.user,
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
  /// `.mcp.json`). Dispatch is gated on [ChannelProvisioningStatus.ready].
  final ChannelProvisioningStatus provisioningStatus;

  /// The granular step an in-flight provision is currently on ("cloning repo
  /// X", "setting up agent Y"). Non-null only while [provisioningStatus] is
  /// [ChannelProvisioningStatus.provisioning].
  final ChannelProvisioningStep? provisioningStep;

  /// Conversation mode (sandbox + tool-allowlist + system-prompt scope).
  final Mode mode;

  /// Owning pipeline run when this conversation was spawned by a pipeline
  /// step. Non-null ⇒ pipeline-managed: hidden from the sidebar, surfaced only
  /// from the pipeline run / step detail. Null for user-facing conversations.
  final String? pipelineRunId;

  /// How this channel came to exist (PRD 22 §1). Defaults to
  /// [ChannelOrigin.user]; agent↔agent peer channels carry
  /// [ChannelOrigin.agentDm] so clients can section them separately and
  /// mute them by default.
  final ChannelOrigin origin;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Channel &&
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
          origin == other.origin;

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
    origin,
  );

  /// Returns a copy with optional overrides.
  Channel copyWith({
    String? id,
    String? name,
    String? workspaceId,
    bool removeWorkspaceId = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    ChannelProvisioningStatus? provisioningStatus,
    ChannelProvisioningStep? provisioningStep,
    bool removeProvisioningStep = false,
    Mode? mode,
    String? pipelineRunId,
    bool removePipelineRunId = false,
    ChannelOrigin? origin,
  }) {
    return Channel(
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
      origin: origin ?? this.origin,
    );
  }
}
