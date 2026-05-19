import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_collaborator.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_origin_kind.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_priority.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_provider.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_status.dart';

/// A dumb issue-tracking artifact — a unit of work the agents and humans track,
/// but no longer the surface agents execute against.
///
/// One `Ticket` aggregate spans two persisted concerns (kept on a single row;
/// see `TicketsTable`):
///
/// * the **mirror** — provider / externalKey / url / title / description /
///   priority / labels / rawStatus / status / timestamps. For remote providers
///   this is a cache; the remote is the source of truth and a refresh rewrites
///   only these fields.
/// * the **overlay** — Control-Center-only metadata the remote knows nothing
///   about: assignedAgentId / assignedTeamId / delegatedByAgentId / channelId /
///   parentTicketId / projectId / linkedPrIds. A remote refresh never touches
///   these.
///
/// Assignment is pure metadata: setting `assignedAgentId` records ownership but
/// dispatches nothing. Agent work lives in conversations (a hidden one when a
/// pipeline spawns it) and the structured-output contract lives on the
/// `AgentRunLog`. The optional `channelId` links a ticket to the conversation
/// it was spun out of (the "create ticket from conversation" path).
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
    this.assigneeType = PrincipalType.agent,
    this.createdByType,
    this.createdById,
    this.assignedTeamId,
    this.delegatedByAgentId,
    this.delegationDepth = 0,
    this.delegationRootTicketId,
    this.channelId,
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
    this.collaborators = const [],
  }) {
    if (title.isEmpty) {
      throw ArgumentError('Ticket title must not be empty');
    }
  }

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

  /// Principal this ticket is assigned to — an agent id or a user id per
  /// [assigneeType] (metadata only — assigning dispatches nothing). Nullable —
  /// remote tickets may have no Control-Center assignee.
  final String? assignedAgentId;

  /// Which kind of principal [assignedAgentId] names.
  final PrincipalType assigneeType;

  /// The kind of principal that created the ticket (`agent` / `user`), or
  /// null when unknown (legacy/system rows).
  final PrincipalType? createdByType;

  /// Id of the creating principal, when known.
  final String? createdById;

  /// Whether the ticket is assigned to a human user.
  bool get isAssignedToUser =>
      assignedAgentId != null && assigneeType == PrincipalType.user;

  /// Team this ticket is assigned to (metadata only).
  final String? assignedTeamId;

  /// Agent that delegated this ticket (for the delegation tree).
  final String? delegatedByAgentId;

  /// Depth of this ticket in the delegation chain (PRD 22 §3). A root ticket is
  /// `0`; each delegated child is `parent.delegationDepth + 1`. Enforced against
  /// the `DelegationGuards` max-depth cap at the delegation chokepoint.
  final int delegationDepth;

  /// The id of the root ticket of this delegation chain (PRD 22 §3), or null
  /// for a root ticket. Lets the whole delegation tree be found from any node
  /// without walking the parent chain.
  final String? delegationRootTicketId;

  /// Conversation this ticket was spun out of ("create ticket from
  /// conversation"), or the channel a delegating agent associated it with.
  /// Nullable — most tickets have no linked conversation.
  final String? channelId;

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
    PrincipalType? assigneeType,
    PrincipalType? createdByType,
    String? createdById,
    String? assignedTeamId,
    bool removeAssignedTeamId = false,
    String? delegatedByAgentId,
    bool removeDelegatedByAgentId = false,
    int? delegationDepth,
    String? delegationRootTicketId,
    bool removeDelegationRootTicketId = false,
    String? channelId,
    bool removeChannelId = false,
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
      parentTicketId: removeParentTicketId
          ? null
          : (parentTicketId ?? this.parentTicketId),
      projectId: removeProjectId ? null : (projectId ?? this.projectId),
      assignedAgentId: removeAssignedAgentId
          ? null
          : (assignedAgentId ?? this.assignedAgentId),
      assigneeType: removeAssignedAgentId
          ? PrincipalType.agent
          : (assigneeType ?? this.assigneeType),
      createdByType: createdByType ?? this.createdByType,
      createdById: createdById ?? this.createdById,
      assignedTeamId: removeAssignedTeamId
          ? null
          : (assignedTeamId ?? this.assignedTeamId),
      delegatedByAgentId: removeDelegatedByAgentId
          ? null
          : (delegatedByAgentId ?? this.delegatedByAgentId),
      delegationDepth: delegationDepth ?? this.delegationDepth,
      delegationRootTicketId: removeDelegationRootTicketId
          ? null
          : (delegationRootTicketId ?? this.delegationRootTicketId),
      channelId: removeChannelId ? null : (channelId ?? this.channelId),
      errorMessage: removeErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
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
