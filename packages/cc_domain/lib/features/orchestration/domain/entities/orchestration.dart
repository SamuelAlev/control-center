import 'package:cc_domain/features/orchestration/domain/entities/orchestration_proposal.dart';
import 'package:cc_domain/features/orchestration/domain/entities/orchestration_status.dart';

/// An autonomous multi-agent orchestration: one "big ask" the system proposes
/// a whole-team plan for, the user approves once, and a deterministic
/// materializer executes via a generated pipeline.
class Orchestration {
  /// Creates an [Orchestration].
  Orchestration({
    required this.id,
    required this.workspaceId,
    required this.proposal,
    required this.createdAt,
    required this.updatedAt,
    this.parentTicketId,
    this.channelId,
    this.orchestratorAgentId,
    this.status = OrchestrationStatus.proposed,
    this.revision = 1,
    this.approvedRevision,
    this.pipelineTemplateId,
    this.pipelineRunId,
    this.teamId,
    this.projectId,
    this.estimatedCostCents,
    this.maxCostCents,
    this.hiredAgentIds = const [],
    this.errorMessage,
    this.completedAt,
  })  : assert(id != '', 'Orchestration id must not be empty'),
        assert(workspaceId != '', 'Orchestration workspaceId must not be empty'),
        assert(revision >= 1, 'revision must be >= 1');

  /// Unique id (UUID v4).
  final String id;

  /// Workspace scope.
  final String workspaceId;

  /// The parsed proposal (current [revision]).
  final OrchestrationProposal proposal;

  /// Anchor ticket the orchestration was opened against.
  final String? parentTicketId;

  /// Shared discussion channel.
  final String? channelId;

  /// Orchestrator agent that produced/revises the proposal.
  final String? orchestratorAgentId;

  /// Lifecycle status.
  final OrchestrationStatus status;

  /// Monotonic proposal revision.
  final int revision;

  /// The revision the user approved, if any.
  final int? approvedRevision;

  /// Generated pipeline template id (set on approval).
  final String? pipelineTemplateId;

  /// Pipeline run id (set when execution starts).
  final String? pipelineRunId;

  /// Team created on approval.
  final String? teamId;

  /// Project created on approval.
  final String? projectId;

  /// Estimated total cost in US cents.
  final int? estimatedCostCents;

  /// Hard spending limit in US cents.
  final int? maxCostCents;

  /// Agent ids hired specifically for this orchestration.
  final List<String> hiredAgentIds;

  /// Error message when failed.
  final String? errorMessage;

  /// Creation timestamp.
  final DateTime createdAt;

  /// Last mutation time.
  final DateTime updatedAt;

  /// When the orchestration reached a terminal state.
  final DateTime? completedAt;

  /// Returns a copy with the given fields replaced.
  Orchestration copyWith({
    OrchestrationProposal? proposal,
    String? parentTicketId,
    String? channelId,
    String? orchestratorAgentId,
    OrchestrationStatus? status,
    int? revision,
    int? approvedRevision,
    String? pipelineTemplateId,
    String? pipelineRunId,
    String? teamId,
    String? projectId,
    int? estimatedCostCents,
    int? maxCostCents,
    List<String>? hiredAgentIds,
    String? errorMessage,
    DateTime? updatedAt,
    DateTime? completedAt,
  }) =>
      Orchestration(
        id: id,
        workspaceId: workspaceId,
        proposal: proposal ?? this.proposal,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        parentTicketId: parentTicketId ?? this.parentTicketId,
        channelId: channelId ?? this.channelId,
        orchestratorAgentId: orchestratorAgentId ?? this.orchestratorAgentId,
        status: status ?? this.status,
        revision: revision ?? this.revision,
        approvedRevision: approvedRevision ?? this.approvedRevision,
        pipelineTemplateId: pipelineTemplateId ?? this.pipelineTemplateId,
        pipelineRunId: pipelineRunId ?? this.pipelineRunId,
        teamId: teamId ?? this.teamId,
        projectId: projectId ?? this.projectId,
        estimatedCostCents: estimatedCostCents ?? this.estimatedCostCents,
        maxCostCents: maxCostCents ?? this.maxCostCents,
        hiredAgentIds: hiredAgentIds ?? this.hiredAgentIds,
        errorMessage: errorMessage ?? this.errorMessage,
        completedAt: completedAt ?? this.completedAt,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Orchestration &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          status == other.status &&
          revision == other.revision &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(id, status, revision, updatedAt);
}
