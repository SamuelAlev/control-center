import 'package:control_center/core/domain/value_objects/conversation_mode.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket_collaborator.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket_origin_kind.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket_priority.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket_provider.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket_status.dart';
import 'package:control_center/features/ticketing/domain/value_objects/output_contract_mode.dart';

/// A unit of work — the nervous system agents read from and act on.
///
/// One `Ticket` aggregate spans two persisted concerns (kept on a single row;
/// see `TicketsTable`):
///
/// * the **mirror** — provider / externalKey / url / title / description /
///   priority / labels / rawStatus / status / timestamps. For remote providers
///   this is a cache; the remote is the source of truth and a refresh rewrites
///   only these fields.
/// * the **overlay** — Control-Center-only orchestration the remote knows
///   nothing about: assignedAgentId / assignedTeamId / delegatedByAgentId /
///   channelId / mode / pipeline coupling / linkedPrIds. A remote refresh never
///   touches these.
///
/// It also absorbs the legacy `Task`: the pipeline-coupling fields
/// (`pipelineRunId`, `pipelineStepId`, `expectedOutputSchema`, `outputJson`,
/// `errorMessage`, `parentTicketId`, `delegatedByAgentId`) and the terminal
/// semantics ([isTerminal]) are preserved so the engine's suspend/resume keeps
/// working.
class Ticket {
  /// Creates a [Ticket].
  Ticket({
    required this.id,
    required this.workspaceId,
    this.provider = TicketProvider.local,
    this.externalKey,
    this.url,
    required this.title,
    this.description,
    this.priority = TicketPriority.none,
    this.labels = const [],
    required this.status,
    this.rawStatus,
    this.parentTicketId,
    this.projectId,
    this.assignedAgentId,
    this.assignedTeamId,
    this.delegatedByAgentId,
    this.channelId,
    this.mode = ConversationMode.chat,
    this.pipelineRunId,
    this.pipelineStepId,
    this.expectedOutputSchema,
    this.outputContractMode = OutputContractMode.strict,
    this.outputJson,
    this.errorMessage,
    this.linkedPrIds = const [],
    this.metadata = const {},
    required this.createdAt,
    this.startedAt,
    this.blockedAt,
    this.cancelledAt,
    this.completedAt,
    this.finishedAt,
    required this.updatedAt,
    this.version = 0,
    this.originKind = TicketOriginKind.manual,
    this.checkoutRunId,
    this.executionLockedAt,
    this.checkoutAgentId,
    this.executionPolicyJson,
    this.executionStateJson,
    this.recoveryActionsJson,
    this.collaborators = const [],
  }) : assert(title.isNotEmpty, 'Ticket title must not be empty');

  // --- identity / mirror ---

  /// Unique ticket identifier (UUID v4). For local tickets this is also the
  /// `externalKey`.
  final String id;

  /// Workspace scope.
  final String workspaceId;

  /// The backend that owns this ticket's canonical data.
  final TicketProvider provider;

  /// Provider-native key (e.g. `LIN-123`). Null for unsynced local tickets.
  final String? externalKey;

  /// Web URL of the ticket on the remote provider, if any.
  final String? url;

  /// Short human-readable title.
  final String title;

  /// Optional longer description / body.
  final String? description;

  /// Priority.
  final TicketPriority priority;

  /// Free-form labels.
  final List<String> labels;

  /// Canonical normalized status.
  final TicketStatus status;

  /// The remote provider's native state name, preserved for lossless display.
  final String? rawStatus;

  /// Parent ticket in the delegation / breakdown tree.
  final String? parentTicketId;

  // --- overlay (Control-Center only) ---

  /// Owning project (a workspace-scoped grouping), or null when the ticket is
  /// not part of any project. Control-Center-only — never pushed to a remote
  /// provider.
  final String? projectId;

  /// Agent this ticket is assigned to (nullable — remote tickets may have no
  /// Control-Center agent).
  final String? assignedAgentId;

  /// Team this ticket is assigned to.
  final String? assignedTeamId;

  /// Agent that delegated this ticket (for the delegation tree).
  final String? delegatedByAgentId;

  /// Discussion channel linked to this ticket, if one has been opened.
  final String? channelId;

  /// Conversation mode used when dispatching agents on this ticket.
  final ConversationMode mode;

  /// Parent pipeline run, when this ticket is pipeline-tracked.
  final String? pipelineRunId;

  /// Pipeline step that created this ticket, used by the resume listener.
  final String? pipelineStepId;

  /// Optional JSON schema the output should conform to.
  final Map<String, dynamic>? expectedOutputSchema;

  /// How strictly [outputJson] is validated against [expectedOutputSchema] at
  /// the `complete_ticket` boundary. Only meaningful when a schema is declared.
  final OutputContractMode outputContractMode;

  /// JSON-serialized output produced by the agent. Null until done.
  final Map<String, dynamic>? outputJson;

  /// Error message when [status] is [TicketStatus.failed].
  final String? errorMessage;

  /// PR node ids this ticket is linked to.
  final List<String> linkedPrIds;

  /// Free-form metadata bag.
  final Map<String, dynamic> metadata;

  // --- timestamps ---

  /// When this ticket was created.
  final DateTime createdAt;

  /// When work started.
  final DateTime? startedAt;

  /// When the ticket was blocked.
  final DateTime? blockedAt;

  /// When the ticket was cancelled.
  final DateTime? cancelledAt;

  /// When the ticket was completed successfully.
  final DateTime? completedAt;

  /// When this ticket reached a terminal state.
  final DateTime? finishedAt;

  /// Last mutation time (mirror refresh or overlay change).
  final DateTime updatedAt;

  // --- optimistic concurrency ---

  /// Version column for optimistic concurrency control.
  /// Incremented on every state mutation.
  final int version;

  // --- origin & provenance ---

  /// How this ticket was created.
  final TicketOriginKind originKind;

  // --- execution lock ---

  /// The heartbeat run that currently owns (checked out) this ticket.
  final String? checkoutRunId;

  /// When the execution lock was acquired.
  final DateTime? executionLockedAt;

  /// Agent that checked out the ticket (redundant, useful for queries).
  final String? checkoutAgentId;

  // --- execution policy ---

  /// JSON-encoded execution policy (list of stages with participants).
  final String? executionPolicyJson;

  /// JSON-encoded execution state (current stage, decisions, etc.).
  final String? executionStateJson;

  // --- recovery ---

  /// JSON-encoded list of recovery actions taken on this ticket.
  final String? recoveryActionsJson;

  // --- collaborators ---

  /// Collaborators (1:N). Default empty; hydrated by the repository on demand.
  final List<TicketCollaborator> collaborators;

  /// Whether this ticket is in a terminal state.
  bool get isTerminal => status.isTerminal;

  /// Whether the canonical data lives on a remote provider.
  bool get isRemote => provider.isRemote;

  /// Key to show in the UI — the provider key when synced, else the id.
  String get displayKey => externalKey ?? id;

  /// Returns a copy with the given fields replaced. Pass-through for nullable
  /// fields uses the current value when the argument is omitted; to explicitly
  /// clear a nullable field, the repository writes the column directly.
  Ticket copyWith({
    TicketProvider? provider,
    String? externalKey,
    bool removeExternalKey = false,
    String? url,
    bool removeUrl = false,
    String? title,
    String? description,
    bool removeDescription = false,
    TicketPriority? priority,
    List<String>? labels,
    TicketStatus? status,
    String? rawStatus,
    bool removeRawStatus = false,
    String? parentTicketId,
    bool removeParentTicketId = false,
    String? projectId,
    bool removeProjectId = false,
    String? assignedAgentId,
    bool removeAssignedAgentId = false,
    String? assignedTeamId,
    bool removeAssignedTeamId = false,
    String? delegatedByAgentId,
    bool removeDelegatedByAgentId = false,
    String? channelId,
    bool removeChannelId = false,
    ConversationMode? mode,
    String? pipelineRunId,
    bool removePipelineRunId = false,
    String? pipelineStepId,
    bool removePipelineStepId = false,
    Map<String, dynamic>? expectedOutputSchema,
    bool removeExpectedOutputSchema = false,
    OutputContractMode? outputContractMode,
    Map<String, dynamic>? outputJson,
    bool removeOutputJson = false,
    String? errorMessage,
    bool removeErrorMessage = false,
    List<String>? linkedPrIds,
    Map<String, dynamic>? metadata,
    DateTime? startedAt,
    bool removeStartedAt = false,
    DateTime? blockedAt,
    bool removeBlockedAt = false,
    DateTime? cancelledAt,
    bool removeCancelledAt = false,
    DateTime? completedAt,
    bool removeCompletedAt = false,
    DateTime? finishedAt,
    bool removeFinishedAt = false,
    DateTime? updatedAt,
    int? version,
    TicketOriginKind? originKind,
    String? checkoutRunId,
    bool removeCheckoutRunId = false,
    DateTime? executionLockedAt,
    bool removeExecutionLockedAt = false,
    String? checkoutAgentId,
    bool removeCheckoutAgentId = false,
    String? executionPolicyJson,
    bool removeExecutionPolicyJson = false,
    String? executionStateJson,
    bool removeExecutionStateJson = false,
    String? recoveryActionsJson,
    bool removeRecoveryActionsJson = false,
    List<TicketCollaborator>? collaborators,
  }) {
    return Ticket(
      id: id,
      workspaceId: workspaceId,
      provider: provider ?? this.provider,
      externalKey: removeExternalKey ? null : (externalKey ?? this.externalKey),
      url: removeUrl ? null : (url ?? this.url),
      title: title ?? this.title,
      description: removeDescription ? null : (description ?? this.description),
      priority: priority ?? this.priority,
      labels: labels ?? this.labels,
      status: status ?? this.status,
      rawStatus: removeRawStatus ? null : (rawStatus ?? this.rawStatus),
      parentTicketId: removeParentTicketId ? null : (parentTicketId ?? this.parentTicketId),
      projectId: removeProjectId ? null : (projectId ?? this.projectId),
      assignedAgentId: removeAssignedAgentId ? null : (assignedAgentId ?? this.assignedAgentId),
      assignedTeamId: removeAssignedTeamId ? null : (assignedTeamId ?? this.assignedTeamId),
      delegatedByAgentId: removeDelegatedByAgentId ? null : (delegatedByAgentId ?? this.delegatedByAgentId),
      channelId: removeChannelId ? null : (channelId ?? this.channelId),
      mode: mode ?? this.mode,
      pipelineRunId: removePipelineRunId ? null : (pipelineRunId ?? this.pipelineRunId),
      pipelineStepId: removePipelineStepId ? null : (pipelineStepId ?? this.pipelineStepId),
      expectedOutputSchema: removeExpectedOutputSchema ? null : (expectedOutputSchema ?? this.expectedOutputSchema),
      outputContractMode: outputContractMode ?? this.outputContractMode,
      outputJson: removeOutputJson ? null : (outputJson ?? this.outputJson),
      errorMessage: removeErrorMessage ? null : (errorMessage ?? this.errorMessage),
      linkedPrIds: linkedPrIds ?? this.linkedPrIds,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt,
      startedAt: removeStartedAt ? null : (startedAt ?? this.startedAt),
      blockedAt: removeBlockedAt ? null : (blockedAt ?? this.blockedAt),
      cancelledAt: removeCancelledAt ? null : (cancelledAt ?? this.cancelledAt),
      completedAt: removeCompletedAt ? null : (completedAt ?? this.completedAt),
      finishedAt: removeFinishedAt ? null : (finishedAt ?? this.finishedAt),
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
      originKind: originKind ?? this.originKind,
      checkoutRunId: removeCheckoutRunId ? null : (checkoutRunId ?? this.checkoutRunId),
      executionLockedAt: removeExecutionLockedAt ? null : (executionLockedAt ?? this.executionLockedAt),
      checkoutAgentId: removeCheckoutAgentId ? null : (checkoutAgentId ?? this.checkoutAgentId),
      executionPolicyJson: removeExecutionPolicyJson ? null : (executionPolicyJson ?? this.executionPolicyJson),
      executionStateJson: removeExecutionStateJson ? null : (executionStateJson ?? this.executionStateJson),
      recoveryActionsJson: removeRecoveryActionsJson ? null : (recoveryActionsJson ?? this.recoveryActionsJson),
      collaborators: collaborators ?? this.collaborators,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Ticket &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          status == other.status &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(id, status, updatedAt);
}
