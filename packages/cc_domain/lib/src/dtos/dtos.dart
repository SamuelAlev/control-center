/// Wire DTOs for the Control Center RPC surface.
///
/// Each tool emits a JSON document (the `text` of its single `CallResult`
/// content piece). These DTOs are the **typed view** the `cc_remote` PWA uses
/// to parse those documents. They mirror the exact shapes the tools emit today
/// (the `cc_mcp` package, `packages/cc_mcp/lib/src/tools/*`); changing a tool's
/// output shape means changing the matching DTO here.
library;

import 'dart:convert';

import 'package:cc_domain/core/domain/value_objects/agent_role.dart'
    show AgentRole;
import 'package:cc_domain/features/fonts/domain/entities/font_family_info.dart'
    show FontFamilyInfo;
import 'package:cc_domain/features/guardrails/domain/entities/action_policy_rule.dart'
    show ActionPolicyRule;
import 'package:cc_domain/features/guardrails/domain/value_objects/action_decision.dart'
    show ActionDecision, ActionScopeType;
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_trigger.dart'
    show CronCatchUpPolicy;
import 'package:cc_domain/features/ticketing/domain/entities/project.dart'
    show Project;
import 'package:cc_domain/features/ticketing/domain/entities/ticket_link.dart'
    show TicketLink;
import 'package:cc_domain/features/weather/domain/entities/weather_snapshot.dart'
    show WeatherCondition, WeatherSnapshot;
import 'package:cc_harness/tools.dart' show ActionClass;

/// Thrown when a remote tool call returns an MCP error envelope.
class RemoteToolException implements Exception {
  RemoteToolException(this.message);

  final String message;

  @override
  String toString() => 'RemoteToolException: $message';
}

/// Parses the MCP tool-call result envelope returned inside a JSON-RPC
/// `tools/call` response.
///
/// The envelope is `{content: [{type: "text", text: "<json>"}], isError: bool}`.
/// This unwraps the first content text and, when it is JSON, decodes it.
/// Throws [RemoteToolException] when [isError] is true (the desktop's way of
/// signalling a tool-level failure such as a missing argument or a workspace
/// mismatch), so the caller surfaces it instead of treating it as data.
class McpToolResult {
  McpToolResult({required this.isError, required this.text, this.json});

  /// Unwraps an MCP result envelope ([result]).
  ///
  /// [result] is the `result` field of a JSON-RPC `tools/call` response.
  factory McpToolResult.fromEnvelope(Map<String, dynamic> result) {
    final content = result['content'];
    String text = '';
    if (content is List && content.isNotEmpty) {
      final first = content.first;
      if (first is Map) {
        text = first['text'] as String? ?? '';
      }
    }
    final isError = result['isError'] == true;
    Object? decoded;
    if (text.isNotEmpty) {
      try {
        decoded = jsonDecode(text);
      } catch (_) {
        decoded = null;
      }
    }
    return McpToolResult(isError: isError, text: text, json: decoded);
  }

  /// Whether the desktop marked this result as an error.
  final bool isError;

  /// The raw text payload (the first content piece).
  final String text;

  /// The text decoded as JSON, when it was valid JSON; otherwise null.
  final Object? json;

  /// Returns the decoded JSON as a [Map], or null when the payload was not a
  /// JSON object.
  Map<String, dynamic>? get asMap =>
      json is Map<String, dynamic> ? json as Map<String, dynamic> : null;

  /// Throws [RemoteToolException] when the desktop reported an error; otherwise
  /// returns this result.
  McpToolResult ensureOk() {
    if (isError) {
      throw RemoteToolException(text);
    }
    return this;
  }
}

/// Workspace wire DTO: `{id, name, created_at}`.
class WorkspaceDto {
  WorkspaceDto({
    required this.id,
    required this.name,
    this.logoPath,
    this.ownerUserId,
    this.secretExcludeGlobs = const [],
    this.reviewConcurrency,
    this.autoPublishReview,
    this.deletedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory WorkspaceDto.fromJson(Map<String, dynamic> json) => WorkspaceDto(
    id: json['id'] as String,
    name: json['name'] as String,
    logoPath: json['logo_path'] as String?,
    ownerUserId: json['owner_user_id'] as String?,
    secretExcludeGlobs:
        (json['secret_exclude_globs'] as List?)?.whereType<String>().toList() ??
        const [],
    reviewConcurrency: (json['review_concurrency'] as num?)?.toInt(),
    autoPublishReview: json['auto_publish_review'] is bool
        ? json['auto_publish_review'] as bool
        : null,
    deletedAt: json['deleted_at'] is String
        ? DateTime.tryParse(json['deleted_at'] as String)
        : null,
    createdAt: json['created_at'] is String
        ? DateTime.tryParse(json['created_at'] as String)
        : null,
    updatedAt: json['updated_at'] is String
        ? DateTime.tryParse(json['updated_at'] as String)
        : null,
  );

  final String id;
  final String name;

  /// Optional local logo path (host-resolved; null on a remote client).
  final String? logoPath;

  /// The owning user (holds the `owner` membership role).
  final String? ownerUserId;

  /// Secret-exclusion globs (paths hidden from guest/viewer roles).
  final List<String> secretExcludeGlobs;

  /// Default reviewer fan-out; null when the host omits it (older surfaces).
  final int? reviewConcurrency;

  /// Whether completed reviews auto-publish to GitHub; null when the host
  /// omits it (older surfaces).
  final bool? autoPublishReview;

  /// Soft-delete timestamp; non-null when the workspace is deleted.
  final DateTime? deletedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    if (logoPath != null) 'logo_path': logoPath,
    if (ownerUserId != null) 'owner_user_id': ownerUserId,
    'secret_exclude_globs': secretExcludeGlobs,
    if (reviewConcurrency != null) 'review_concurrency': reviewConcurrency,
    if (autoPublishReview != null) 'auto_publish_review': autoPublishReview,
    if (deletedAt != null) 'deleted_at': deletedAt!.toIso8601String(),
    if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
  };
}

/// Ticket wire DTO — the FULL shape needed to reconstruct a `Ticket` entity on
/// a thin client without losing any field.
///
/// The thin-client write path runs the domain `TicketWorkflowService` over the
/// RPC repository: it reads a ticket, applies a `copyWith` and writes the
/// result back with `expectedVersion`. That read-modify-write is only safe if
/// the wire round-trip is LOSSLESS — every persisted field (the mirror, the
/// Control-Center overlay, the lifecycle timestamps and `version`) must
/// survive the trip, or an update would silently clobber whatever the DTO
/// dropped. Enum fields travel as their `.name`; timestamps as ISO-8601.
class TicketDto {
  TicketDto({
    required this.id,
    required this.key,
    required this.title,
    required this.status,
    required this.priority,
    required this.provider,
    this.assignee,
    this.assigneeType,
    this.createdByType,
    this.createdById,
    this.url,
    this.workspaceId,
    this.description,
    this.rawStatus,
    this.labels = const [],
    this.parentTicketId,
    this.projectId,
    this.assignedTeamId,
    this.delegatedByAgentId,
    this.spaceId,
    this.errorMessage,
    this.linkedPrIds = const [],
    this.metadata = const {},
    this.version = 0,
    this.originKind,
    this.createdAt,
    this.startedAt,
    this.blockedAt,
    this.cancelledAt,
    this.completedAt,
    this.finishedAt,
    this.updatedAt,
  });

  factory TicketDto.fromJson(Map<String, dynamic> json) => TicketDto(
    id: json['ticket_id'] as String,
    key: json['key'] as String? ?? '',
    title: json['title'] as String? ?? '',
    status: json['status'] as String? ?? '',
    priority: json['priority'] as String? ?? '',
    provider: json['provider'] as String? ?? '',
    assignee: json['assignee'] as String?,
    assigneeType: json['assignee_type'] as String?,
    createdByType: json['created_by_type'] as String?,
    createdById: json['created_by_id'] as String?,
    url: json['url'] as String?,
    workspaceId: json['workspace_id'] as String?,
    description: json['description'] as String?,
    rawStatus: json['raw_status'] as String?,
    labels: (json['labels'] as List?)?.whereType<String>().toList() ?? const [],
    parentTicketId: json['parent_ticket_id'] as String?,
    projectId: json['project_id'] as String?,
    assignedTeamId: json['assigned_team_id'] as String?,
    delegatedByAgentId: json['delegated_by_agent_id'] as String?,
    spaceId: json['space_id'] as String?,
    errorMessage: json['error_message'] as String?,
    linkedPrIds:
        (json['linked_pr_ids'] as List?)?.whereType<String>().toList() ??
        const [],
    metadata: (json['metadata'] as Map?)?.cast<String, dynamic>() ?? const {},
    version: (json['version'] as num?)?.toInt() ?? 0,
    originKind: json['origin_kind'] as String?,
    createdAt: json['created_at'] as String?,
    startedAt: json['started_at'] as String?,
    blockedAt: json['blocked_at'] as String?,
    cancelledAt: json['cancelled_at'] as String?,
    completedAt: json['completed_at'] as String?,
    finishedAt: json['finished_at'] as String?,
    updatedAt: json['updated_at'] as String?,
  );

  final String id;
  final String key;
  final String title;
  final String status;
  final String priority;
  final String provider;
  final String? assignee;

  /// `agent` or `user` — which kind of principal [assignee] names.
  final String? assigneeType;

  /// `agent` / `user` / `system` — the creating principal's kind.
  final String? createdByType;

  /// Id of the creating principal, when known.
  final String? createdById;
  final String? url;

  /// Owning workspace (the server binds it; lets a client rebuild the entity).
  final String? workspaceId;
  final String? description;

  /// The provider's native status string, preserved verbatim for remote
  /// tickets (the canonical [status] is the normalized enum name).
  final String? rawStatus;
  final List<String> labels;

  // ---- Control-Center overlay (never touched by a remote refresh) ----
  final String? parentTicketId;
  final String? projectId;
  final String? assignedTeamId;
  final String? delegatedByAgentId;
  final String? spaceId;
  final String? errorMessage;
  final List<String> linkedPrIds;
  final Map<String, dynamic> metadata;

  /// Optimistic-concurrency version. The client echoes this back as
  /// `expectedVersion` so a stale write is rejected server-side.
  final int version;

  /// How the ticket came to exist (`TicketOriginKind.name`).
  final String? originKind;

  /// ISO-8601 timestamps, when the host includes them.
  final String? createdAt;
  final String? startedAt;
  final String? blockedAt;
  final String? cancelledAt;
  final String? completedAt;
  final String? finishedAt;
  final String? updatedAt;

  Map<String, dynamic> toJson() => {
    'ticket_id': id,
    'key': key,
    'title': title,
    'status': status,
    'priority': priority,
    'provider': provider,
    'assignee': ?assignee,
    'assignee_type': ?assigneeType,
    'created_by_type': ?createdByType,
    'created_by_id': ?createdById,
    'url': ?url,
    'workspace_id': ?workspaceId,
    'description': ?description,
    'raw_status': ?rawStatus,
    'labels': labels,
    'parent_ticket_id': ?parentTicketId,
    'project_id': ?projectId,
    'assigned_team_id': ?assignedTeamId,
    'delegated_by_agent_id': ?delegatedByAgentId,
    'space_id': ?spaceId,
    'error_message': ?errorMessage,
    'linked_pr_ids': linkedPrIds,
    'metadata': metadata,
    'version': version,
    'origin_kind': ?originKind,
    'created_at': ?createdAt,
    'started_at': ?startedAt,
    'blocked_at': ?blockedAt,
    'cancelled_at': ?cancelledAt,
    'completed_at': ?completedAt,
    'finished_at': ?finishedAt,
    'updated_at': ?updatedAt,
  };
}

/// Agent wire DTO — the full shape needed to reconstruct an `Agent` entity on a
/// thin client (richer than the lossy `list_agents` MCP tool output).
class AgentDto {
  AgentDto({
    required this.id,
    required this.name,
    required this.title,
    required this.agentMdPath,
    required this.workspaceId,
    required this.skills,
    this.reportsTo,
    this.persona,
    this.systemPrompt,
    this.adapterId,
    this.modelId,
    this.strictMode = false,
    this.effort,
    this.contextSize,
    this.role,
    this.capabilities,
    this.monthlyBudgetCents = 0,
    this.silenceTimeoutMinutes,
    this.maxConcurrentTasks = 1,
    this.visibility = 'workspace',
    this.lifecycleStatus = 'active',
    this.budgetPolicyId,
    this.runtimeProfileId,
    this.createdAt,
  });

  factory AgentDto.fromJson(Map<String, dynamic> json) => AgentDto(
    id: json['id'] as String,
    name: json['name'] as String? ?? '',
    title: json['title'] as String? ?? '',
    agentMdPath: json['agent_md_path'] as String? ?? '',
    workspaceId: json['workspace_id'] as String? ?? '',
    skills: ((json['skills'] as List?) ?? const [])
        .map((s) => s.toString())
        .toList(),
    reportsTo: json['reports_to'] as String?,
    persona: json['persona'] as String?,
    systemPrompt: json['system_prompt'] as String?,
    adapterId: json['adapter_id'] as String?,
    modelId: json['model_id'] as String?,
    strictMode: json['strict_mode'] as bool? ?? false,
    effort: json['effort'] as String?,
    contextSize: (json['context_size'] as num?)?.toInt(),
    role: json['role'] as String?,
    capabilities: json['capabilities'] is Map
        ? (json['capabilities'] as Map).cast<String, dynamic>()
        : null,
    monthlyBudgetCents: (json['monthly_budget_cents'] as num?)?.toInt() ?? 0,
    silenceTimeoutMinutes: (json['silence_timeout_minutes'] as num?)?.toInt(),
    maxConcurrentTasks: (json['max_concurrent_tasks'] as num?)?.toInt() ?? 1,
    visibility: json['visibility'] as String? ?? 'workspace',
    lifecycleStatus: json['lifecycle_status'] as String? ?? 'active',
    budgetPolicyId: json['budget_policy_id'] as String?,
    runtimeProfileId: json['runtime_profile_id'] as String?,
    createdAt: json['created_at'] as String?,
  );

  final String id;
  final String name;
  final String title;
  final String agentMdPath;
  final String workspaceId;
  final List<String> skills;
  final String? reportsTo;
  final String? persona;
  final String? systemPrompt;
  final String? adapterId;
  final String? modelId;
  final bool strictMode;
  final String? effort;
  final int? contextSize;
  final String? role;
  final Map<String, dynamic>? capabilities;
  final int monthlyBudgetCents;
  final int? silenceTimeoutMinutes;

  /// Governance capability profile (PRD 09).
  final int maxConcurrentTasks;
  final String visibility;
  final String lifecycleStatus;
  final String? budgetPolicyId;
  final String? runtimeProfileId;

  /// ISO-8601 creation timestamp, when the host includes it.
  final String? createdAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'title': title,
    'agent_md_path': agentMdPath,
    'workspace_id': workspaceId,
    'skills': skills,
    'reports_to': ?reportsTo,
    'persona': ?persona,
    'system_prompt': ?systemPrompt,
    'adapter_id': ?adapterId,
    'model_id': ?modelId,
    'strict_mode': strictMode,
    'effort': ?effort,
    'context_size': ?contextSize,
    'role': ?role,
    'capabilities': ?capabilities,
    'monthly_budget_cents': monthlyBudgetCents,
    'silence_timeout_minutes': ?silenceTimeoutMinutes,
    'max_concurrent_tasks': maxConcurrentTasks,
    'visibility': visibility,
    'lifecycle_status': lifecycleStatus,
    'budget_policy_id': ?budgetPolicyId,
    'runtime_profile_id': ?runtimeProfileId,
    'created_at': ?createdAt,
  };
}

/// Repo wire DTO — a Git repository registration.
///
/// Workspace-scoped: every `repos.*` op names its `workspace_id` and an [id] is
/// meaningful only inside its workspace.
class RepoDto {
  RepoDto({
    required this.id,
    required this.name,
    required this.path,
    required this.remoteOwner,
    required this.remoteName,
    this.forge = 'github',
    this.createdAt,
    this.updatedAt,
  });

  factory RepoDto.fromJson(Map<String, dynamic> json) => RepoDto(
    id: json['id'] as String,
    name: json['name'] as String? ?? '',
    path: json['path'] as String? ?? '',
    forge: json['forge'] as String? ?? 'github',
    remoteOwner: json['remote_owner'] as String? ?? '',
    remoteName: json['remote_name'] as String? ?? '',
    createdAt: json['created_at'] as String?,
    updatedAt: json['updated_at'] as String?,
  );

  final String id;
  final String name;
  final String path;

  /// The forge wire value (`github` / `gitlab` / `bitbucket` / `local`).
  final String forge;
  final String remoteOwner;
  final String remoteName;
  final String? createdAt;
  final String? updatedAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'path': path,
    'forge': forge,
    'remote_owner': remoteOwner,
    'remote_name': remoteName,
    'created_at': ?createdAt,
    'updated_at': ?updatedAt,
  };
}

/// Space wire DTO: `{id, name, workspace_id, mode?, pipeline_run_id?,
/// created_at?, updated_at?}`.
class SpaceDto {
  SpaceDto({
    required this.id,
    required this.name,
    required this.workspaceId,
    this.mode,
    this.provisioningStatus,
    this.provisioningStep,
    this.pipelineRunId,
    this.kind,
    this.createdAt,
    this.updatedAt,
    this.archivedAt,
  });

  factory SpaceDto.fromJson(Map<String, dynamic> json) => SpaceDto(
    id: json['id'] as String,
    name: json['name'] as String? ?? '',
    workspaceId: json['workspace_id'] as String? ?? '',
    mode: json['mode'] as String?,
    provisioningStatus: json['provisioning_status'] as String?,
    provisioningStep: json['provisioning_step'] as String?,
    pipelineRunId: json['pipeline_run_id'] as String?,
    kind: json['kind'] as String?,
    createdAt: json['created_at'] is String
        ? DateTime.tryParse(json['created_at'] as String)
        : null,
    updatedAt: json['updated_at'] is String
        ? DateTime.tryParse(json['updated_at'] as String)
        : null,
    archivedAt: json['archived_at'] is String
        ? DateTime.tryParse(json['archived_at'] as String)
        : null,
  );

  final String id;
  final String name;
  final String workspaceId;

  /// Conversation mode (`Mode.toDbValue()` string); null ⇒ default.
  final String? mode;

  /// Provisioning status (`SpaceProvisioningStatus.toDbValue()` string);
  /// null ⇒ `ready` (legacy rows / older servers).
  final String? provisioningStatus;

  /// Granular in-flight provisioning step
  /// (`SpaceProvisioningStep.toDbValue()` JSON string); null ⇒ no step
  /// (not provisioning, or an older server).
  final String? provisioningStep;

  /// Owning pipeline run when spawned by a pipeline step (hidden from sidebar).
  final String? pipelineRunId;

  /// How the space came to exist (`SpaceKind.wire` string); null ⇒ `user`
  /// (legacy rows / older servers). Lets clients section agent-DM spaces.
  final String? kind;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Soft-archive stamp (`Space.archivedAt`); null ⇒ active. Older servers
  /// never send it, which correctly reads as "not archived".
  final DateTime? archivedAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'workspace_id': workspaceId,
    if (mode != null) 'mode': mode,
    if (provisioningStatus != null) 'provisioning_status': provisioningStatus,
    if (provisioningStep != null) 'provisioning_step': provisioningStep,
    if (pipelineRunId != null) 'pipeline_run_id': pipelineRunId,
    if (kind != null) 'kind': kind,
    if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    if (archivedAt != null) 'archived_at': archivedAt!.toIso8601String(),
  };
}

/// Message wire DTO: `{id, content, sender_id, sender_type, message_type,
/// metadata, space_id?, conversation_id?, compacted?, created_at?}`.
class MessageDto {
  MessageDto({
    required this.id,
    required this.content,
    required this.senderId,
    required this.senderType,
    required this.messageType,
    this.metadata,
    this.spaceId,
    this.conversationId,
    this.compacted = false,
    this.createdAt,
  });

  factory MessageDto.fromJson(Map<String, dynamic> json) => MessageDto(
    id: json['id'] as String,
    content: json['content'] as String? ?? '',
    senderId: json['sender_id'] as String? ?? '',
    senderType: json['sender_type'] as String? ?? '',
    messageType: json['message_type'] as String? ?? '',
    metadata: json['metadata'],
    spaceId: json['space_id'] as String?,
    conversationId: json['conversation_id'] as String?,
    compacted: json['compacted'] as bool? ?? false,
    createdAt: json['created_at'] is String
        ? DateTime.tryParse(json['created_at'] as String)
        : null,
  );

  final String id;
  final String content;
  final String senderId;
  final String senderType;
  final String messageType;
  final Object? metadata;

  /// Parent space id; null on lossy/older surfaces (the UI scopes by space).
  final String? spaceId;

  /// The conversation (stream) inside the space; null on lossy surfaces (the
  /// UI then resolves the space's STANDING conversation — its oldest active
  /// one, never a row keyed on the space id).
  final String? conversationId;

  /// Whether the message has been compacted out of the live context window.
  final bool compacted;
  final DateTime? createdAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'content': content,
    'sender_id': senderId,
    'sender_type': senderType,
    'message_type': messageType,
    if (metadata != null) 'metadata': metadata,
    if (spaceId != null) 'space_id': spaceId,
    if (conversationId != null) 'conversation_id': conversationId,
    if (compacted) 'compacted': compacted,
    if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
  };
}

/// Space participant wire DTO: `{id, space_id, agent_id, role, joined_at,
/// last_read_at?}`.
class SpaceParticipantDto {
  SpaceParticipantDto({
    required this.id,
    required this.spaceId,
    required this.principalId,
    required this.participantType,
    required this.role,
    this.joinedAt,
    this.lastReadAt,
  });

  factory SpaceParticipantDto.fromJson(Map<String, dynamic> json) =>
      SpaceParticipantDto(
        id: json['id'] as String,
        spaceId: json['space_id'] as String? ?? '',
        principalId: json['principal_id'] as String? ?? '',
        participantType: json['participant_type'] as String? ?? 'agent',
        role: json['role'] as String? ?? '',
        joinedAt: json['joined_at'] is String
            ? DateTime.tryParse(json['joined_at'] as String)
            : null,
        lastReadAt: json['last_read_at'] is String
            ? DateTime.tryParse(json['last_read_at'] as String)
            : null,
      );

  final String id;
  final String spaceId;

  /// Agent id or user id, per [participantType].
  final String principalId;

  /// `agent` or `user`.
  final String participantType;
  final String role;
  final DateTime? joinedAt;
  final DateTime? lastReadAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'space_id': spaceId,
    'principal_id': principalId,
    'participant_type': participantType,
    'role': role,
    if (joinedAt != null) 'joined_at': joinedAt!.toIso8601String(),
    if (lastReadAt != null) 'last_read_at': lastReadAt!.toIso8601String(),
  };
}

/// User wire DTO — global identity rows for authorship display, member
/// pickers and the profile editor.
class UserDto {
  UserDto({
    required this.id,
    required this.handle,
    required this.displayName,
    this.email,
    this.avatarRef,
    this.gitAuthorName,
    this.gitAuthorEmail,
    this.onboardingFinishedAt,
    this.createdAt,
  });

  factory UserDto.fromJson(Map<String, dynamic> json) => UserDto(
    id: json['id'] as String,
    handle: json['handle'] as String? ?? '',
    displayName: json['display_name'] as String? ?? '',
    email: json['email'] as String?,
    avatarRef: json['avatar_ref'] as String?,
    gitAuthorName: json['git_author_name'] as String?,
    gitAuthorEmail: json['git_author_email'] as String?,
    onboardingFinishedAt: json['onboarding_finished_at'] is String
        ? DateTime.tryParse(json['onboarding_finished_at'] as String)
        : null,
    createdAt: json['created_at'] is String
        ? DateTime.tryParse(json['created_at'] as String)
        : null,
  );

  final String id;
  final String handle;
  final String displayName;
  final String? email;
  final String? avatarRef;
  final String? gitAuthorName;
  final String? gitAuthorEmail;

  /// When this user finished first-run setup — carried only on the CALLER'S
  /// OWN user (`identity.me`, `users.updateProfile`), never on the directory
  /// rows of co-members, who have no reason to publish their setup state.
  ///
  /// Null therefore means either "has not onboarded" or "this is somebody
  /// else's row"; only read it off `IdentityMe.user`.
  final DateTime? onboardingFinishedAt;
  final DateTime? createdAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'handle': handle,
    'display_name': displayName,
    if (email != null) 'email': email,
    if (avatarRef != null) 'avatar_ref': avatarRef,
    if (gitAuthorName != null) 'git_author_name': gitAuthorName,
    if (gitAuthorEmail != null) 'git_author_email': gitAuthorEmail,
    if (onboardingFinishedAt != null)
      'onboarding_finished_at': onboardingFinishedAt!.toIso8601String(),
    if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
  };
}

/// Workspace member wire DTO.
class WorkspaceMemberDto {
  WorkspaceMemberDto({
    required this.id,
    required this.workspaceId,
    required this.userId,
    required this.role,
    this.roleWire,
    this.invitedBy,
    this.joinedAt,
  });

  factory WorkspaceMemberDto.fromJson(Map<String, dynamic> json) =>
      WorkspaceMemberDto(
        id: json['id'] as String,
        workspaceId: json['workspace_id'] as String? ?? '',
        userId: json['user_id'] as String? ?? '',
        role: json['role'] as String? ?? 'guest',
        roleWire: json['role_wire'] as String?,
        invitedBy: json['invited_by'] as String?,
        joinedAt: json['joined_at'] is String
            ? DateTime.tryParse(json['joined_at'] as String)
            : null,
      );

  final String id;
  final String workspaceId;
  final String userId;

  /// `WorkspaceRole` wire name — for a CUSTOM role, its base preset.
  ///
  /// Deliberately always a parseable preset: every existing consumer reads
  /// this to decide what to render, and handing them `custom:<id>` would make
  /// a custom-role holder look like no role at all.
  final String role;

  /// The stored membership value: a preset name, or `custom:<id>`.
  ///
  /// Null on servers that predate custom roles, so callers read
  /// `roleWire ?? role`.
  final String? roleWire;
  final String? invitedBy;
  final DateTime? joinedAt;

  /// The value to send back when assigning: the custom role when there is
  /// one, else the preset.
  String get effectiveRoleWire => roleWire ?? role;

  Map<String, dynamic> toJson() => {
    'id': id,
    'workspace_id': workspaceId,
    'user_id': userId,
    'role': role,
    if (roleWire != null) 'role_wire': roleWire,
    if (invitedBy != null) 'invited_by': invitedBy,
    if (joinedAt != null) 'joined_at': joinedAt!.toIso8601String(),
  };
}

/// Workspace invite wire DTO (never carries the code — only metadata; the
/// one-time code is returned exactly once by `invites.create`).
class WorkspaceInviteDto {
  WorkspaceInviteDto({
    required this.id,
    required this.workspaceId,
    required this.role,
    this.repoGrants = const {},
    this.createdBy,
    this.createdAt,
    this.expiresAt,
    this.usedAt,
    this.usedBy,
    this.revokedAt,
  });

  factory WorkspaceInviteDto.fromJson(Map<String, dynamic> json) =>
      WorkspaceInviteDto(
        id: json['id'] as String,
        workspaceId: json['workspace_id'] as String? ?? '',
        role: json['role'] as String? ?? 'guest',
        repoGrants:
            (json['repo_grants'] as Map?)?.map(
              (k, v) => MapEntry(k as String, v as String),
            ) ??
            const {},
        createdBy: json['created_by'] as String?,
        createdAt: json['created_at'] is String
            ? DateTime.tryParse(json['created_at'] as String)
            : null,
        expiresAt: json['expires_at'] is String
            ? DateTime.tryParse(json['expires_at'] as String)
            : null,
        usedAt: json['used_at'] is String
            ? DateTime.tryParse(json['used_at'] as String)
            : null,
        usedBy: json['used_by'] as String?,
        revokedAt: json['revoked_at'] is String
            ? DateTime.tryParse(json['revoked_at'] as String)
            : null,
      );

  final String id;
  final String workspaceId;

  /// `WorkspaceRole` wire name granted on redemption.
  final String role;

  /// Repo id → `RepoGrantLevel` wire name shared by the invite.
  final Map<String, String> repoGrants;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? expiresAt;
  final DateTime? usedAt;
  final String? usedBy;
  final DateTime? revokedAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'workspace_id': workspaceId,
    'role': role,
    'repo_grants': repoGrants,
    if (createdBy != null) 'created_by': createdBy,
    if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    if (expiresAt != null) 'expires_at': expiresAt!.toIso8601String(),
    if (usedAt != null) 'used_at': usedAt!.toIso8601String(),
    if (usedBy != null) 'used_by': usedBy,
    if (revokedAt != null) 'revoked_at': revokedAt!.toIso8601String(),
  };
}

/// Per-user audit trail entry wire DTO.
class UserActivityDto {
  UserActivityDto({
    required this.id,
    required this.workspaceId,
    required this.userId,
    required this.action,
    this.targetType,
    this.targetId,
    this.deviceId,
    this.ip,
    this.countryCode,
    this.createdAt,
  });

  factory UserActivityDto.fromJson(Map<String, dynamic> json) =>
      UserActivityDto(
        id: json['id'] as String,
        workspaceId: json['workspace_id'] as String? ?? '',
        userId: json['user_id'] as String? ?? '',
        action: json['action'] as String? ?? '',
        targetType: json['target_type'] as String?,
        targetId: json['target_id'] as String?,
        deviceId: json['device_id'] as String?,
        ip: json['ip'] as String?,
        countryCode: json['country_code'] as String?,
        createdAt: json['created_at'] is String
            ? DateTime.tryParse(json['created_at'] as String)
            : null,
      );

  final String id;
  final String workspaceId;
  final String userId;
  final String action;
  final String? targetType;
  final String? targetId;
  final String? deviceId;
  final String? ip;
  final String? countryCode;
  final DateTime? createdAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'workspace_id': workspaceId,
    'user_id': userId,
    'action': action,
    if (targetType != null) 'target_type': targetType,
    if (targetId != null) 'target_id': targetId,
    if (deviceId != null) 'device_id': deviceId,
    if (ip != null) 'ip': ip,
    if (countryCode != null) 'country_code': countryCode,
    if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
  };
}

/// RSS feed wire DTO.
class FeedDto {
  FeedDto({
    required this.id,
    required this.name,
    required this.url,
    this.description,
    this.iconUrl,
    this.userAgent,
    this.enabled = true,
    this.lastFetchedAt,
    this.lastError,
  });

  factory FeedDto.fromJson(Map<String, dynamic> json) => FeedDto(
    id: json['id'] as String,
    name: json['name'] as String? ?? '',
    url: json['url'] as String? ?? '',
    description: json['description'] as String?,
    iconUrl: json['icon_url'] as String?,
    userAgent: json['user_agent'] as String?,
    enabled: json['enabled'] as bool? ?? true,
    lastFetchedAt: json['last_fetched_at'] is String
        ? DateTime.tryParse(json['last_fetched_at'] as String)
        : null,
    lastError: json['last_error'] as String?,
  );

  final String id;
  final String name;
  final String url;
  final String? description;
  final String? iconUrl;
  final String? userAgent;
  final bool enabled;
  final DateTime? lastFetchedAt;
  final String? lastError;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'url': url,
    if (description != null) 'description': description,
    if (iconUrl != null) 'icon_url': iconUrl,
    if (userAgent != null) 'user_agent': userAgent,
    'enabled': enabled,
    if (lastFetchedAt != null)
      'last_fetched_at': lastFetchedAt!.toIso8601String(),
    if (lastError != null) 'last_error': lastError,
  };
}

/// RSS article wire DTO.
class ArticleDto {
  ArticleDto({
    required this.id,
    required this.feedId,
    required this.title,
    this.url,
    this.imageUrl,
    this.summary,
    this.author,
    this.publishedAt,
    this.isRead = false,
    this.isSaved = false,
  });

  factory ArticleDto.fromJson(Map<String, dynamic> json) => ArticleDto(
    id: json['id'] as String,
    feedId: json['feed_id'] as String? ?? '',
    title: json['title'] as String? ?? '',
    url: json['url'] as String?,
    imageUrl: json['image_url'] as String?,
    summary: json['summary'] as String? ?? json['description'] as String?,
    author: json['author'] as String?,
    publishedAt: (json['published_at'] ?? json['publishedAt']) is String
        ? DateTime.tryParse(
            (json['published_at'] ?? json['publishedAt']) as String,
          )
        : null,
    isRead: json['is_read'] as bool? ?? false,
    isSaved: json['is_saved'] as bool? ?? false,
  );

  final String id;
  final String feedId;
  final String title;
  final String? url;

  /// Cover image URL, when the feed advertised one. The thin client renders it
  /// as the article thumbnail (routed through the host image proxy on web —
  /// arbitrary feed-image hosts send no CORS headers, so CanvasKit can't fetch
  /// them directly).
  final String? imageUrl;
  final String? summary;
  final String? author;
  final DateTime? publishedAt;
  final bool isRead;
  final bool isSaved;

  Map<String, dynamic> toJson() => {
    'id': id,
    'feed_id': feedId,
    'title': title,
    if (url != null) 'url': url,
    if (imageUrl != null) 'image_url': imageUrl,
    if (summary != null) 'summary': summary,
    if (author != null) 'author': author,
    if (publishedAt != null) 'published_at': publishedAt!.toIso8601String(),
    'is_read': isRead,
    'is_saved': isSaved,
  };
}

/// Space read-cursor wire DTO — the user participant's `lastReadAt` for a
/// single space. The cursor is keyed by `space_id` (the space is the
/// workspace-scoped entity); `last_read_at` is null when the space has never
/// been opened under the user.
class SpaceReadDto {
  SpaceReadDto({required this.spaceId, this.lastReadAt});

  factory SpaceReadDto.fromJson(Map<String, dynamic> json) => SpaceReadDto(
    spaceId: json['space_id'] as String? ?? '',
    lastReadAt: json['last_read_at'] as String?,
  );

  final String spaceId;

  /// ISO-8601 read-cursor timestamp, or null when never set.
  final String? lastReadAt;

  Map<String, dynamic> toJson() => {
    'space_id': spaceId,
    if (lastReadAt != null) 'last_read_at': lastReadAt,
  };
}

/// MemoryDomain wire DTO — a named, labelled memory domain (workspace-scoped).
class MemoryDomainDto {
  MemoryDomainDto({
    required this.id,
    required this.workspaceId,
    required this.name,
    required this.label,
    this.description,
    required this.createdByRole,
    this.createdAt,
  });

  factory MemoryDomainDto.fromJson(Map<String, dynamic> json) =>
      MemoryDomainDto(
        id: json['id'] as String,
        workspaceId: json['workspace_id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        label: json['label'] as String? ?? '',
        description: json['description'] as String?,
        createdByRole: json['created_by_role'] as String? ?? '',
        createdAt: json['created_at'] as String?,
      );

  final String id;
  final String workspaceId;
  final String name;
  final String label;
  final String? description;
  final String createdByRole;

  /// ISO-8601 creation timestamp, when the host includes it.
  final String? createdAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'workspace_id': workspaceId,
    'name': name,
    'label': label,
    if (description != null) 'description': description,
    'created_by_role': createdByRole,
    if (createdAt != null) 'created_at': createdAt,
  };
}

/// MemoryAccessGrant wire DTO — an access-grant entry controlling which
/// [AgentRole] may read/write a memory domain (workspace-scoped; enum fields
/// encoded as `.name`).
class MemoryAccessGrantDto {
  MemoryAccessGrantDto({
    required this.workspaceId,
    required this.agentRole,
    required this.memoryDomain,
    required this.permission,
  });

  factory MemoryAccessGrantDto.fromJson(Map<String, dynamic> json) =>
      MemoryAccessGrantDto(
        workspaceId: json['workspace_id'] as String? ?? '',
        agentRole: json['agent_role'] as String? ?? '',
        memoryDomain: json['memory_domain'] as String? ?? '',
        permission: json['permission'] as String? ?? '',
      );

  final String workspaceId;
  final String agentRole;
  final String memoryDomain;
  final String permission;

  Map<String, dynamic> toJson() => {
    'workspace_id': workspaceId,
    'agent_role': agentRole,
    'memory_domain': memoryDomain,
    'permission': permission,
  };
}

/// Agent working-memory wire DTO — the full shape needed to reconstruct an
/// `AgentWorkingMemory` entity on a thin client (a serialized memory blob
/// scoped to one agent within a workspace).
class AgentWorkingMemoryDto {
  AgentWorkingMemoryDto({
    required this.id,
    required this.workspaceId,
    required this.agentId,
    required this.content,
    this.updatedAt,
  });

  factory AgentWorkingMemoryDto.fromJson(Map<String, dynamic> json) =>
      AgentWorkingMemoryDto(
        id: json['id'] as String,
        workspaceId: json['workspace_id'] as String? ?? '',
        agentId: json['agent_id'] as String? ?? '',
        content: json['content'] as String? ?? '',
        updatedAt: json['updated_at'] as String?,
      );

  final String id;
  final String workspaceId;
  final String agentId;
  final String content;

  /// ISO-8601 last-updated timestamp, when the host includes it.
  final String? updatedAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'workspace_id': workspaceId,
    'agent_id': agentId,
    'content': content,
    'updated_at': ?updatedAt,
  };
}

/// Review-space-association wire DTO — the full shape needed to reconstruct a
/// `ReviewSpaceAssociation` entity on a thin client. Enum `status` is encoded
/// as `.name`; timestamps are ISO-8601 strings.
class ReviewSpaceAssociationDto {
  ReviewSpaceAssociationDto({
    required this.id,
    required this.spaceId,
    required this.workspaceId,
    required this.prExternalId,
    required this.prNumber,
    required this.repoFullName,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory ReviewSpaceAssociationDto.fromJson(Map<String, dynamic> json) =>
      ReviewSpaceAssociationDto(
        id: json['id'] as String,
        spaceId: json['space_id'] as String? ?? '',
        workspaceId: json['workspace_id'] as String? ?? '',
        prExternalId: json['pr_external_id'] as String? ?? '',
        prNumber: (json['pr_number'] as num?)?.toInt() ?? 0,
        repoFullName: json['repo_full_name'] as String? ?? '',
        status: json['status'] as String? ?? '',
        createdAt: json['created_at'] as String?,
        updatedAt: json['updated_at'] as String?,
      );

  final String id;
  final String spaceId;
  final String workspaceId;
  final String prExternalId;
  final int prNumber;
  final String repoFullName;
  final String status;

  /// ISO-8601 timestamps, when the host includes them.
  final String? createdAt;
  final String? updatedAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'space_id': spaceId,
    'workspace_id': workspaceId,
    'pr_external_id': prExternalId,
    'pr_number': prNumber,
    'repo_full_name': repoFullName,
    'status': status,
    'created_at': ?createdAt,
    'updated_at': ?updatedAt,
  };
}

/// Memory-policy wire DTO — a workspace-scoped rule governing agent access or
/// behavior within a memory domain. `required_role` is encoded as the
/// [AgentRole] `.name`; `source_fact_ids` is a JSON array of fact ids.
class MemoryPolicyDto {
  MemoryPolicyDto({
    required this.id,
    required this.workspaceId,
    required this.domain,
    required this.rule,
    this.sourceFactIds = const [],
    this.requiredRole,
    this.active = true,
    this.createdAt,
    this.updatedAt,
  });

  factory MemoryPolicyDto.fromJson(Map<String, dynamic> json) =>
      MemoryPolicyDto(
        id: json['id'] as String,
        workspaceId: json['workspace_id'] as String? ?? '',
        domain: json['domain'] as String? ?? '',
        rule: json['rule'] as String? ?? '',
        sourceFactIds: ((json['source_fact_ids'] as List?) ?? const [])
            .map((s) => s.toString())
            .toList(),
        requiredRole: json['required_role'] as String?,
        active: json['active'] as bool? ?? true,
        createdAt: json['created_at'] as String?,
        updatedAt: json['updated_at'] as String?,
      );

  final String id;
  final String workspaceId;
  final String domain;
  final String rule;
  final List<String> sourceFactIds;
  final String? requiredRole;
  final bool active;

  /// ISO-8601 creation timestamp, when the host includes it.
  final String? createdAt;

  /// ISO-8601 last-updated timestamp, when the host includes it.
  final String? updatedAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'workspace_id': workspaceId,
    'domain': domain,
    'rule': rule,
    'source_fact_ids': sourceFactIds,
    'required_role': ?requiredRole,
    'active': active,
    'created_at': ?createdAt,
    'updated_at': ?updatedAt,
  };
}

/// Provider-policy wire DTO (PRD 05) — one allow/deny governance statement.
/// Mirrors `providerPolicyToWire`/`providerPolicyFromWire` in the host catalog.
class ProviderPolicyDto {
  ProviderPolicyDto({
    required this.id,
    required this.workspaceId,
    required this.action,
    required this.resource,
    required this.effect,
    this.layer = 'workspace',
  });

  factory ProviderPolicyDto.fromJson(Map<String, dynamic> json) =>
      ProviderPolicyDto(
        id: json['id'] as String,
        workspaceId: json['workspace_id'] as String? ?? '',
        action: json['action'] as String? ?? 'provider.use',
        resource: json['resource'] as String? ?? '*',
        effect: json['effect'] as String? ?? 'deny',
        layer: json['layer'] as String? ?? 'workspace',
      );

  final String id;
  final String workspaceId;
  final String action;
  final String resource;
  final String effect;
  final String layer;

  Map<String, dynamic> toJson() => {
    'id': id,
    'workspace_id': workspaceId,
    'action': action,
    'resource': resource,
    'effect': effect,
    'layer': layer,
  };
}

/// Action-guardrail rule wire DTO (PRD 24 §4). Mirrors `actionPolicyRuleToWire`
/// in the host catalog and round-trips an [ActionPolicyRule] over RPC for the
/// agent-permissions policy surface.
class ActionPolicyRuleDto {
  ActionPolicyRuleDto({
    required this.id,
    required this.workspaceId,
    required this.scopeType,
    required this.scopeId,
    required this.decision,
    this.actionClass,
    this.commandPrefix,
    this.provenance = 'user',
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  factory ActionPolicyRuleDto.fromJson(Map<String, dynamic> json) =>
      ActionPolicyRuleDto(
        id: json['id'] as String? ?? '',
        workspaceId: json['workspace_id'] as String? ?? '',
        scopeType: json['scope_type'] as String? ?? 'workspace',
        scopeId: json['scope_id'] as String? ?? '',
        decision: json['decision'] as String? ?? 'prompt',
        actionClass: json['action_class'] as String?,
        commandPrefix: json['command_prefix'] as String?,
        provenance: json['provenance'] as String? ?? 'user',
        createdBy: json['created_by'] as String?,
        createdAt: json['created_at'] as String?,
        updatedAt: json['updated_at'] as String?,
      );

  factory ActionPolicyRuleDto.fromEntity(ActionPolicyRule r) =>
      ActionPolicyRuleDto(
        id: r.id,
        workspaceId: r.workspaceId,
        scopeType: r.scopeType.wire,
        scopeId: r.scopeId,
        decision: r.decision.wire,
        actionClass: r.actionClass?.wire,
        commandPrefix: r.commandPrefix,
        provenance: r.provenance,
        createdBy: r.createdBy,
        createdAt: r.createdAt.toIso8601String(),
        updatedAt: r.updatedAt.toIso8601String(),
      );

  final String id;
  final String workspaceId;
  final String scopeType;
  final String scopeId;
  final String decision;
  final String? actionClass;
  final String? commandPrefix;
  final String provenance;
  final String? createdBy;
  final String? createdAt;
  final String? updatedAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'workspace_id': workspaceId,
    'scope_type': scopeType,
    'scope_id': scopeId,
    'decision': decision,
    if (actionClass != null) 'action_class': actionClass,
    if (commandPrefix != null) 'command_prefix': commandPrefix,
    'provenance': provenance,
    if (createdBy != null) 'created_by': createdBy,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };

  /// Rebuilds the domain entity. [workspaceId] is forced by the caller (the
  /// server injects the session workspace; the client passes the active one) so
  /// a client can never write a rule into a foreign workspace.
  ActionPolicyRule toEntity({String? workspaceId, DateTime? now}) {
    final ts = now ?? DateTime.fromMillisecondsSinceEpoch(0);
    return ActionPolicyRule(
      id: id,
      workspaceId: workspaceId ?? this.workspaceId,
      scopeType: ActionScopeType.fromWire(scopeType),
      scopeId: scopeId,
      decision: ActionDecision.fromWire(decision),
      actionClass: actionClass == null
          ? null
          : ActionClass.fromWire(actionClass!),
      commandPrefix: commandPrefix,
      provenance: provenance,
      createdBy: createdBy,
      createdAt: createdAt == null ? ts : DateTime.tryParse(createdAt!) ?? ts,
      updatedAt: updatedAt == null ? ts : DateTime.tryParse(updatedAt!) ?? ts,
    );
  }
}

/// Cost-summary wire DTO (PRD 05) — aggregated spend over a window for the
/// usage dashboard. Mirrors `costSummaryToWire` in the host catalog.
class CostSummaryDto {
  CostSummaryDto({
    required this.totalUsd,
    required this.requestCount,
    this.windowStart,
    this.nextResetAt,
    this.byProvider = const {},
    this.byModel = const {},
  });

  factory CostSummaryDto.fromJson(Map<String, dynamic> json) => CostSummaryDto(
    totalUsd: (json['total_usd'] as num?)?.toDouble() ?? 0,
    requestCount: (json['request_count'] as num?)?.toInt() ?? 0,
    windowStart: json['window_start'] as String?,
    nextResetAt: json['next_reset_at'] as String?,
    byProvider: ((json['by_provider'] as Map?) ?? const {}).map(
      (k, v) => MapEntry(k.toString(), (v as num).toDouble()),
    ),
    byModel: ((json['by_model'] as Map?) ?? const {}).map(
      (k, v) => MapEntry(k.toString(), (v as num).toDouble()),
    ),
  );

  final double totalUsd;
  final int requestCount;

  /// ISO-8601 window start.
  final String? windowStart;

  /// ISO-8601 nearest quota reset, when known.
  final String? nextResetAt;

  final Map<String, double> byProvider;
  final Map<String, double> byModel;

  Map<String, dynamic> toJson() => {
    'total_usd': totalUsd,
    'request_count': requestCount,
    'window_start': ?windowStart,
    'next_reset_at': ?nextResetAt,
    'by_provider': byProvider,
    'by_model': byModel,
  };
}

/// Agent run log wire DTO — a single agent execution record. Mirrors
/// `agentRunLogToWire`/`agentRunLogFromWire` in the host catalog. Enum fields
/// (`status`, `liveness`, `error_family`, `output_contract_mode`) are encoded
/// as `.name`; timestamps are ISO-8601 strings; the structured-output payloads
/// (`expected_output_schema`, `output_json`) travel as raw JSON maps.
class AgentRunLogDto {
  AgentRunLogDto({
    required this.id,
    required this.agentId,
    this.workspaceId,
    this.conversationId,
    this.ticketId,
    this.spaceId,
    required this.startedAt,
    this.completedAt,
    required this.status,
    this.summary,
    this.adapter,
    this.modelId,
    this.pid,
    this.logPath,
    this.inputTokens = 0,
    this.outputTokens = 0,
    this.thoughtTokens = 0,
    this.cachedReadTokens = 0,
    this.cachedWriteTokens = 0,
    this.estimatedCostCents = 0,
    this.childCostCents = 0,
    this.agentRole,
    this.durationMs,
    this.timeToFirstTokenMs,
    this.liveness,
    this.errorFamily,
    this.lastOutputAt,
    this.continuationSummary,
    this.contextSnapshotJson,
    this.pipelineRunId,
    this.pipelineStepId,
    this.errorCode,
    this.expectedOutputSchema,
    this.outputContractMode = 'strict',
    this.outputJson,
    this.outputRejections = 0,
    this.retryOfRunId,
    this.retryAttempt = 0,
    this.parentRunId,
    this.spawnToolCallId,
  });

  factory AgentRunLogDto.fromJson(Map<String, dynamic> json) => AgentRunLogDto(
    id: json['id'] as String,
    agentId: json['agent_id'] as String? ?? '',
    workspaceId: json['workspace_id'] as String?,
    conversationId: json['conversation_id'] as String?,
    ticketId: json['ticket_id'] as String?,
    spaceId: json['space_id'] as String?,
    startedAt: json['started_at'] as String? ?? '',
    completedAt: json['completed_at'] as String?,
    status: json['status'] as String? ?? 'pending',
    summary: json['summary'] as String?,
    adapter: json['adapter'] as String?,
    modelId: json['model_id'] as String?,
    pid: (json['pid'] as num?)?.toInt(),
    logPath: json['log_path'] as String?,
    inputTokens: (json['input_tokens'] as num?)?.toInt() ?? 0,
    outputTokens: (json['output_tokens'] as num?)?.toInt() ?? 0,
    thoughtTokens: (json['thought_tokens'] as num?)?.toInt() ?? 0,
    cachedReadTokens: (json['cached_read_tokens'] as num?)?.toInt() ?? 0,
    cachedWriteTokens: (json['cached_write_tokens'] as num?)?.toInt() ?? 0,
    estimatedCostCents: (json['estimated_cost_cents'] as num?)?.toInt() ?? 0,
    childCostCents: (json['child_cost_cents'] as num?)?.toInt() ?? 0,
    agentRole: json['agent_role'] as String?,
    durationMs: (json['duration_ms'] as num?)?.toInt(),
    timeToFirstTokenMs: (json['time_to_first_token_ms'] as num?)?.toInt(),
    liveness: json['liveness'] as String?,
    errorFamily: json['error_family'] as String?,
    lastOutputAt: json['last_output_at'] as String?,
    continuationSummary: json['continuation_summary'] as String?,
    contextSnapshotJson: json['context_snapshot_json'] as String?,
    pipelineRunId: json['pipeline_run_id'] as String?,
    pipelineStepId: json['pipeline_step_id'] as String?,
    errorCode: json['error_code'] as String?,
    expectedOutputSchema: json['expected_output_schema'] is Map
        ? (json['expected_output_schema'] as Map).cast<String, dynamic>()
        : null,
    outputContractMode: json['output_contract_mode'] as String? ?? 'strict',
    outputJson: json['output_json'] is Map
        ? (json['output_json'] as Map).cast<String, dynamic>()
        : null,
    outputRejections: (json['output_rejections'] as num?)?.toInt() ?? 0,
    retryOfRunId: json['retry_of_run_id'] as String?,
    retryAttempt: (json['retry_attempt'] as num?)?.toInt() ?? 0,
    parentRunId: json['parent_run_id'] as String?,
    spawnToolCallId: json['spawn_tool_call_id'] as String?,
  );

  final String id;
  final String agentId;
  final String? workspaceId;
  final String? conversationId;
  final String? ticketId;
  final String? spaceId;
  final String startedAt;
  final String? completedAt;
  final String status;
  final String? summary;
  final String? adapter;
  final String? modelId;
  final int? pid;
  final String? logPath;
  final int inputTokens;
  final int outputTokens;
  final int thoughtTokens;
  final int cachedReadTokens;
  final int cachedWriteTokens;
  final int estimatedCostCents;
  final int childCostCents;

  /// Run role for per-role cost attribution: `main` | `sub` | `advisor`.
  final String? agentRole;
  final int? durationMs;
  final int? timeToFirstTokenMs;
  final String? liveness;
  final String? errorFamily;
  final String? lastOutputAt;
  final String? continuationSummary;
  final String? contextSnapshotJson;
  final String? pipelineRunId;
  final String? pipelineStepId;
  final String? errorCode;
  final Map<String, dynamic>? expectedOutputSchema;
  final String outputContractMode;
  final Map<String, dynamic>? outputJson;
  final int outputRejections;
  final String? retryOfRunId;
  final int retryAttempt;

  /// Run id of the parent run that spawned this one as an ephemeral subagent.
  final String? parentRunId;

  /// Id of the parent's `task` tool call that spawned this subagent run.
  final String? spawnToolCallId;

  Map<String, dynamic> toJson() => {
    'id': id,
    'agent_id': agentId,
    'workspace_id': ?workspaceId,
    'conversation_id': ?conversationId,
    'ticket_id': ?ticketId,
    'space_id': ?spaceId,
    'started_at': startedAt,
    'completed_at': ?completedAt,
    'status': status,
    'summary': ?summary,
    'adapter': ?adapter,
    'model_id': ?modelId,
    'pid': ?pid,
    'log_path': ?logPath,
    'input_tokens': inputTokens,
    'output_tokens': outputTokens,
    'thought_tokens': thoughtTokens,
    'cached_read_tokens': cachedReadTokens,
    'cached_write_tokens': cachedWriteTokens,
    'estimated_cost_cents': estimatedCostCents,
    'child_cost_cents': childCostCents,
    'agent_role': ?agentRole,
    'duration_ms': ?durationMs,
    'time_to_first_token_ms': ?timeToFirstTokenMs,
    'liveness': ?liveness,
    'error_family': ?errorFamily,
    'last_output_at': ?lastOutputAt,
    'continuation_summary': ?continuationSummary,
    'context_snapshot_json': ?contextSnapshotJson,
    'pipeline_run_id': ?pipelineRunId,
    'pipeline_step_id': ?pipelineStepId,
    'error_code': ?errorCode,
    'expected_output_schema': ?expectedOutputSchema,
    'output_contract_mode': outputContractMode,
    'output_json': ?outputJson,
    'output_rejections': outputRejections,
    'retry_of_run_id': ?retryOfRunId,
    'retry_attempt': retryAttempt,
    'parent_run_id': ?parentRunId,
    'spawn_tool_call_id': ?spawnToolCallId,
  };
}

/// IsolatedRepo wire DTO — a workspace-scoped CoW worktree of a registered repo
/// provisioned for one conversation. Full shape needed to reconstruct an
/// `IsolatedRepo` entity on a thin client. The enum `backend` is encoded as
/// `.name`.
class IsolatedRepoDto {
  IsolatedRepoDto({
    required this.id,
    required this.workspaceId,
    required this.spaceId,
    required this.repoId,
    required this.path,
    required this.branch,
    required this.backend,
    required this.sourcePath,
    this.ticketId,
    this.createdAt,
  });

  factory IsolatedRepoDto.fromJson(Map<String, dynamic> json) =>
      IsolatedRepoDto(
        id: json['id'] as String,
        workspaceId: json['workspace_id'] as String? ?? '',
        spaceId: json['space_id'] as String? ?? '',
        repoId: json['repo_id'] as String? ?? '',
        path: json['path'] as String? ?? '',
        branch: json['branch'] as String? ?? '',
        backend: json['backend'] as String? ?? '',
        sourcePath: json['source_path'] as String? ?? '',
        ticketId: json['ticket_id'] as String?,
        createdAt: json['created_at'] as String?,
      );

  final String id;
  final String workspaceId;
  final String spaceId;
  final String repoId;
  final String path;
  final String branch;

  /// The `RepoIsolationBackend` name (`.name`): `rift` | `gitWorktree`.
  final String backend;
  final String sourcePath;
  final String? ticketId;

  /// ISO-8601 creation timestamp, when the host includes it.
  final String? createdAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'workspace_id': workspaceId,
    'space_id': spaceId,
    'repo_id': repoId,
    'path': path,
    'branch': branch,
    'backend': backend,
    'source_path': sourcePath,
    'ticket_id': ?ticketId,
    'created_at': ?createdAt,
  };
}

/// MemoryFact wire DTO: a long-term memory fact (workspace-scoped). Enum field
/// `authored_by_role` travels as `.name`; `source_observation_ids` as a JSON
/// list of strings. The host owns embedding computation, so no embedding bytes
/// cross the wire.
class MemoryFactDto {
  MemoryFactDto({
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
    this.memoryType = 'fact',
    this.veracity = 'stated',
    this.mentionCount = 1,
    this.createdAt,
    this.updatedAt,
  });

  factory MemoryFactDto.fromJson(Map<String, dynamic> json) => MemoryFactDto(
    id: json['id'] as String,
    workspaceId: json['workspace_id'] as String? ?? '',
    domain: json['domain'] as String? ?? '',
    topic: json['topic'] as String? ?? '',
    content: json['content'] as String? ?? '',
    sourceObservationIds:
        ((json['source_observation_ids'] as List?) ?? const [])
            .map((s) => s.toString())
            .toList(),
    confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
    supersededBy: json['superseded_by'] as String?,
    authoredByAgentId: json['authored_by_agent_id'] as String?,
    authoredByRole: json['authored_by_role'] as String?,
    memoryType: json['memory_type'] as String? ?? 'fact',
    veracity: json['veracity'] as String? ?? 'stated',
    mentionCount: (json['mention_count'] as num?)?.toInt() ?? 1,
    createdAt: json['created_at'] as String?,
    updatedAt: json['updated_at'] as String?,
  );

  final String id;
  final String workspaceId;
  final String domain;
  final String topic;
  final String content;
  final List<String> sourceObservationIds;
  final double confidence;
  final String? supersededBy;
  final String? authoredByAgentId;
  final String? authoredByRole;

  /// Typed classification slug (e.g. `fact`, `decision`, `preference`).
  final String memoryType;

  /// Provenance slug (e.g. `stated`, `inferred`, `tool`).
  final String veracity;

  /// How many times the fact has been (re-)asserted.
  final int mentionCount;

  /// ISO-8601 creation timestamp, when the host includes it.
  final String? createdAt;

  /// ISO-8601 last-updated timestamp, when the host includes it.
  final String? updatedAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'workspace_id': workspaceId,
    'domain': domain,
    'topic': topic,
    'content': content,
    'source_observation_ids': sourceObservationIds,
    'confidence': confidence,
    'superseded_by': ?supersededBy,
    'authored_by_agent_id': ?authoredByAgentId,
    'authored_by_role': ?authoredByRole,
    'memory_type': memoryType,
    'veracity': veracity,
    'mention_count': mentionCount,
    'created_at': ?createdAt,
    'updated_at': ?updatedAt,
  };
}

/// VoiceProfile wire DTO — a persistent, cross-meeting voiceprint.
///
/// Workspace-scoped (the host binds the authoritative workspace per session).
/// The [embedding] is the running centroid weighted by [sampleCount]; both
/// travel on the wire so the entity can be reconstructed without re-deriving
/// the encoded blob. Mirrors the `voice_profile.*` ops in the host catalog.
class VoiceProfileDto {
  VoiceProfileDto({
    required this.id,
    required this.workspaceId,
    required this.displayName,
    required this.embedding,
    this.sampleCount = 1,
    this.createdAt,
    this.updatedAt,
  });

  factory VoiceProfileDto.fromJson(Map<String, dynamic> json) =>
      VoiceProfileDto(
        id: json['id'] as String,
        workspaceId: json['workspace_id'] as String? ?? '',
        displayName: json['display_name'] as String? ?? '',
        embedding: ((json['embedding'] as List?) ?? const [])
            .map((e) => (e as num).toDouble())
            .toList(),
        sampleCount: (json['sample_count'] as num?)?.toInt() ?? 1,
        createdAt: json['created_at'] as String?,
        updatedAt: json['updated_at'] as String?,
      );

  final String id;
  final String workspaceId;
  final String displayName;
  final List<double> embedding;
  final int sampleCount;

  /// ISO-8601 creation timestamp, when the host includes it.
  final String? createdAt;

  /// ISO-8601 last-update timestamp, when the host includes it.
  final String? updatedAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'workspace_id': workspaceId,
    'display_name': displayName,
    'embedding': embedding,
    'sample_count': sampleCount,
    'created_at': ?createdAt,
    'updated_at': ?updatedAt,
  };
}

/// Project wire DTO — a workspace-scoped grouping of tickets. Enum fields
/// (`color`, `status`) are encoded as `.name`; timestamps are ISO-8601
/// strings. Reconstructs a [Project] losslessly.
class ProjectDto {
  ProjectDto({
    required this.id,
    required this.workspaceId,
    required this.name,
    this.description,
    this.color = 'gray',
    this.status = 'active',
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProjectDto.fromJson(Map<String, dynamic> json) => ProjectDto(
    id: json['id'] as String,
    workspaceId: json['workspace_id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    description: json['description'] as String?,
    color: json['color'] as String? ?? 'gray',
    status: json['status'] as String? ?? 'active',
    createdAt: json['created_at'] as String? ?? '',
    updatedAt: json['updated_at'] as String? ?? '',
  );

  final String id;
  final String workspaceId;
  final String name;
  final String? description;
  final String color;
  final String status;
  final String createdAt;
  final String updatedAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'workspace_id': workspaceId,
    'name': name,
    if (description != null) 'description': description,
    'color': color,
    'status': status,
    'created_at': createdAt,
    'updated_at': updatedAt,
  };
}

/// TicketLink wire DTO — a directional ticket dependency edge
/// (workspace-scoped). `type` is the canonical stored snake_case string
/// (`blocks` / `relates_to` / `duplicate_of`); `createdAt` is ISO-8601. Holds
/// the FULL entity shape so the client rebuilds [TicketLink] losslessly.
class TicketLinkDto {
  TicketLinkDto({
    required this.id,
    required this.workspaceId,
    required this.sourceTicketId,
    required this.targetTicketId,
    required this.type,
    required this.createdAt,
  });

  factory TicketLinkDto.fromJson(Map<String, dynamic> json) => TicketLinkDto(
    id: json['id'] as String,
    workspaceId: json['workspace_id'] as String? ?? '',
    sourceTicketId: json['source_ticket_id'] as String? ?? '',
    targetTicketId: json['target_ticket_id'] as String? ?? '',
    type: json['type'] as String? ?? '',
    createdAt: json['created_at'] as String? ?? '',
  );

  final String id;
  final String workspaceId;
  final String sourceTicketId;
  final String targetTicketId;

  /// Canonical stored link type (snake_case: `blocks` / `relates_to` /
  /// `duplicate_of`).
  final String type;

  /// ISO-8601 creation timestamp.
  final String createdAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'workspace_id': workspaceId,
    'source_ticket_id': sourceTicketId,
    'target_ticket_id': targetTicketId,
    'type': type,
    'created_at': createdAt,
  };
}

// ---- Pipeline runs ----

/// PipelineRun wire DTO — a single execution of a pipeline template
/// (workspace-scoped). Reconstructs losslessly: enum `status` as its `.name`,
/// timestamps as ISO-8601 strings, `state`/`trigger_payload` as raw JSON maps.
class PipelineRunDto {
  PipelineRunDto({
    required this.id,
    required this.templateId,
    required this.workspaceId,
    required this.status,
    Map<String, dynamic>? state,
    this.triggerEventType,
    this.triggerPayload,
    this.dedupKey,
    required this.startedAt,
    this.attemptStartedAt,
    this.attemptCount = 1,
    this.finishedAt,
    this.activeMs = 0,
    this.lastResumedAt,
    this.errorMessage,
    this.errorStackTrace,
    this.parentPipelineRunId,
    this.parentStepId,
    this.templateVersion = 1,
    this.totalCostCents = 0,
    this.totalTokens = 0,
    this.dryRun = false,
  }) : state = state ?? <String, dynamic>{};

  factory PipelineRunDto.fromJson(Map<String, dynamic> json) => PipelineRunDto(
    id: json['id'] as String,
    templateId: json['template_id'] as String? ?? '',
    workspaceId: json['workspace_id'] as String? ?? '',
    status: json['status'] as String? ?? 'pending',
    state: json['state'] is Map
        ? (json['state'] as Map).cast<String, dynamic>()
        : <String, dynamic>{},
    triggerEventType: json['trigger_event_type'] as String?,
    triggerPayload: json['trigger_payload'] is Map
        ? (json['trigger_payload'] as Map).cast<String, dynamic>()
        : null,
    dedupKey: json['dedup_key'] as String?,
    startedAt: json['started_at'] as String? ?? '',
    attemptStartedAt: json['attempt_started_at'] as String?,
    attemptCount: (json['attempt_count'] as num?)?.toInt() ?? 1,
    finishedAt: json['finished_at'] as String?,
    activeMs: (json['active_ms'] as num?)?.toInt() ?? 0,
    lastResumedAt: json['last_resumed_at'] as String?,
    errorMessage: json['error_message'] as String?,
    errorStackTrace: json['error_stack_trace'] as String?,
    parentPipelineRunId: json['parent_pipeline_run_id'] as String?,
    parentStepId: json['parent_step_id'] as String?,
    templateVersion: (json['template_version'] as num?)?.toInt() ?? 1,
    totalCostCents: (json['total_cost_cents'] as num?)?.toInt() ?? 0,
    totalTokens: (json['total_tokens'] as num?)?.toInt() ?? 0,
    dryRun: json['dry_run'] as bool? ?? false,
  );

  final String id;
  final String templateId;
  final String workspaceId;
  final String status;
  final Map<String, dynamic> state;
  final String? triggerEventType;
  final Map<String, dynamic>? triggerPayload;
  final String? dedupKey;
  final String startedAt;
  final String? attemptStartedAt;
  final int attemptCount;
  final String? finishedAt;
  final int activeMs;
  final String? lastResumedAt;
  final String? errorMessage;
  final String? errorStackTrace;
  final String? parentPipelineRunId;
  final String? parentStepId;
  final int templateVersion;
  final int totalCostCents;
  final int totalTokens;
  final bool dryRun;

  Map<String, dynamic> toJson() => {
    'id': id,
    'template_id': templateId,
    'workspace_id': workspaceId,
    'status': status,
    'state': state,
    if (triggerEventType != null) 'trigger_event_type': triggerEventType,
    if (triggerPayload != null) 'trigger_payload': triggerPayload,
    if (dedupKey != null) 'dedup_key': dedupKey,
    'started_at': startedAt,
    if (attemptStartedAt != null) 'attempt_started_at': attemptStartedAt,
    'attempt_count': attemptCount,
    if (finishedAt != null) 'finished_at': finishedAt,
    'active_ms': activeMs,
    if (lastResumedAt != null) 'last_resumed_at': lastResumedAt,
    if (errorMessage != null) 'error_message': errorMessage,
    if (errorStackTrace != null) 'error_stack_trace': errorStackTrace,
    if (parentPipelineRunId != null)
      'parent_pipeline_run_id': parentPipelineRunId,
    if (parentStepId != null) 'parent_step_id': parentStepId,
    'template_version': templateVersion,
    'total_cost_cents': totalCostCents,
    'total_tokens': totalTokens,
    'dry_run': dryRun,
  };
}

/// PipelineStepRun wire DTO — a single step execution within a PipelineRun.
/// Owned (workspace-wise) through its parent run. Enum `status` as its `.name`,
/// timestamps as ISO-8601 strings.
class PipelineStepRunDto {
  PipelineStepRunDto({
    required this.id,
    required this.pipelineRunId,
    required this.stepId,
    required this.status,
    this.inputJson,
    this.outputJson,
    this.spaceId,
    this.errorMessage,
    this.branchIndex,
    this.attemptCount = 0,
    this.priorAttempts = const [],
    required this.startedAt,
    this.finishedAt,
  });

  factory PipelineStepRunDto.fromJson(Map<String, dynamic> json) =>
      PipelineStepRunDto(
        id: json['id'] as String,
        pipelineRunId: json['pipeline_run_id'] as String? ?? '',
        stepId: json['step_id'] as String? ?? '',
        status: json['status'] as String? ?? 'pending',
        inputJson: json['input_json'] as String?,
        outputJson: json['output_json'] as String?,
        spaceId: json['space_id'] as String?,
        errorMessage: json['error_message'] as String?,
        branchIndex: (json['branch_index'] as num?)?.toInt(),
        attemptCount: (json['attempt_count'] as num?)?.toInt() ?? 0,
        priorAttempts: ((json['prior_attempts'] as List?) ?? const [])
            .whereType<Map>()
            .map((a) => a.cast<String, dynamic>())
            .toList(),
        startedAt: json['started_at'] as String? ?? '',
        finishedAt: json['finished_at'] as String?,
      );

  final String id;
  final String pipelineRunId;
  final String stepId;
  final String status;
  final String? inputJson;
  final String? outputJson;
  final String? spaceId;
  final String? errorMessage;
  final int? branchIndex;
  final int attemptCount;

  /// Archived previous firings of the step (oldest first), each a
  /// `PipelineStepAttempt.toJson()` map. Empty until the row is retried.
  final List<Map<String, dynamic>> priorAttempts;
  final String startedAt;
  final String? finishedAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'pipeline_run_id': pipelineRunId,
    'step_id': stepId,
    'status': status,
    if (inputJson != null) 'input_json': inputJson,
    if (outputJson != null) 'output_json': outputJson,
    if (spaceId != null) 'space_id': spaceId,
    if (errorMessage != null) 'error_message': errorMessage,
    if (branchIndex != null) 'branch_index': branchIndex,
    'attempt_count': attemptCount,
    if (priorAttempts.isNotEmpty) 'prior_attempts': priorAttempts,
    'started_at': startedAt,
    if (finishedAt != null) 'finished_at': finishedAt,
  };
}

/// Wire shape for a pipeline template (`PipelineDefinition`). The graph shape —
/// `steps` (each carrying its nested `triggers`/`config` as inline maps) and
/// declared `inputs` — round-trips losslessly so the client can reconstruct the
/// full entity. Enums travel as `.name`; the host owns version bumping.
class PipelineTemplateDto {
  PipelineTemplateDto({
    required this.templateId,
    required this.workspaceId,
    required this.name,
    this.description,
    this.steps = const [],
    this.inputs = const [],
    this.isBuiltIn = false,
    this.isEnabled = true,
    this.version = 1,
  });

  factory PipelineTemplateDto.fromJson(Map<String, dynamic> json) =>
      PipelineTemplateDto(
        templateId: json['template_id'] as String,
        workspaceId: json['workspace_id'] as String,
        name: json['name'] as String? ?? '',
        description: json['description'] as String?,
        steps: ((json['steps'] as List?) ?? const [])
            .whereType<Map>()
            .map((s) => s.cast<String, dynamic>())
            .toList(),
        inputs: ((json['inputs'] as List?) ?? const [])
            .whereType<Map>()
            .map((i) => i.cast<String, dynamic>())
            .toList(),
        isBuiltIn: json['is_built_in'] as bool? ?? false,
        isEnabled: json['is_enabled'] as bool? ?? true,
        version: (json['version'] as num?)?.toInt() ?? 1,
      );

  final String templateId;
  final String workspaceId;
  final String name;
  final String? description;
  final List<Map<String, dynamic>> steps;
  final List<Map<String, dynamic>> inputs;
  final bool isBuiltIn;
  final bool isEnabled;
  final int version;

  Map<String, dynamic> toJson() => {
    'template_id': templateId,
    'workspace_id': workspaceId,
    'name': name,
    if (description != null) 'description': description,
    'steps': steps,
    'inputs': inputs,
    'is_built_in': isBuiltIn,
    'is_enabled': isEnabled,
    'version': version,
  };
}

/// PipelineTrigger wire DTO — a workspace-scoped declarative trigger that
/// auto-starts a pipeline template when a domain event fires (or on a
/// schedule). Reconstructs losslessly: enums are plain strings, `match` is a
/// JSON object, timestamps are ISO-8601 strings.
class PipelineTriggerDto {
  PipelineTriggerDto({
    required this.id,
    required this.eventType,
    required this.templateId,
    required this.workspaceId,
    required this.createdAt,
    this.enabled = false,
    this.cronExpression,
    this.timezone,
    this.nextRunAt,
    this.webhookToken,
    this.eventFilters = const {},
    this.match = const {},
    this.lastFiredAt,
    this.catchUpPolicy = 'catchUpLatestOnly',
  });

  factory PipelineTriggerDto.fromJson(Map<String, dynamic> json) =>
      PipelineTriggerDto(
        id: json['id'] as String? ?? '',
        eventType: json['event_type'] as String? ?? '',
        templateId: json['template_id'] as String? ?? '',
        workspaceId: json['workspace_id'] as String? ?? '',
        enabled: json['enabled'] as bool? ?? false,
        cronExpression: json['cron_expression'] as String?,
        timezone: json['timezone'] as String?,
        nextRunAt: json['next_run_at'] as String?,
        webhookToken: json['webhook_token'] as String?,
        eventFilters: json['event_filters'] is Map
            ? (json['event_filters'] as Map).cast<String, dynamic>()
            : const {},
        match: json['match'] is Map
            ? (json['match'] as Map).cast<String, dynamic>()
            : const {},
        lastFiredAt: json['last_fired_at'] as String?,
        catchUpPolicy:
            json['catch_up_policy'] as String? ?? 'catchUpLatestOnly',
        createdAt: json['created_at'] as String? ?? '',
      );

  final String id;
  final String eventType;
  final String templateId;
  final String workspaceId;
  final bool enabled;

  /// Schedule expression for time-based triggers (`every:<seconds>` or a
  /// standard 5-field cron), or null.
  final String? cronExpression;

  /// IANA timezone the cron expression is evaluated in (null/empty = UTC).
  final String? timezone;

  /// ISO-8601 timestamp of the next cron fire, or null.
  final String? nextRunAt;

  /// Secret path token for webhook triggers, or null.
  final String? webhookToken;

  /// Per-event action filters for webhook triggers. Empty fires on every
  /// delivery.
  final Map<String, dynamic> eventFilters;

  /// Value filter applied to the event payload before firing. Empty means
  /// "fire on every matching event".
  final Map<String, dynamic> match;

  /// ISO-8601 timestamp of the last firing, or null until first fired.
  final String? lastFiredAt;

  /// The [CronCatchUpPolicy] name for missed scheduled fires
  /// (`catchUpLatestOnly` default, or `skip`).
  final String catchUpPolicy;

  /// ISO-8601 creation timestamp.
  final String createdAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'event_type': eventType,
    'template_id': templateId,
    'workspace_id': workspaceId,
    'enabled': enabled,
    if (cronExpression != null) 'cron_expression': cronExpression,
    if (timezone != null) 'timezone': timezone,
    if (nextRunAt != null) 'next_run_at': nextRunAt,
    if (webhookToken != null) 'webhook_token': webhookToken,
    'event_filters': eventFilters,
    'match': match,
    if (lastFiredAt != null) 'last_fired_at': lastFiredAt,
    'catch_up_policy': catchUpPolicy,
    'created_at': createdAt,
  };
}

/// Team wire DTO — a workspace-scoped named group of agents. Full shape needed
/// to reconstruct a `Team` entity on a thin client. The timestamp is encoded
/// as an ISO-8601 string.
class TeamDto {
  TeamDto({
    required this.id,
    required this.workspaceId,
    required this.name,
    this.description,
    this.leaderId,
    this.instructions,
    required this.createdAt,
  });

  factory TeamDto.fromJson(Map<String, dynamic> json) => TeamDto(
    id: json['id'] as String,
    workspaceId: json['workspace_id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    description: json['description'] as String?,
    leaderId: json['leader_id'] as String?,
    instructions: json['instructions'] as String?,
    createdAt: json['created_at'] as String? ?? '',
  );

  final String id;
  final String workspaceId;
  final String name;
  final String? description;
  final String? leaderId;
  final String? instructions;
  final String createdAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'workspace_id': workspaceId,
    'name': name,
    if (description != null) 'description': description,
    if (leaderId != null) 'leader_id': leaderId,
    if (instructions != null) 'instructions': instructions,
    'created_at': createdAt,
  };
}

/// TeamMember wire DTO — links an agent to a team with a role. Keyed by
/// `(team_id, agent_id)`; the `role` enum is encoded as `.name`.
class TeamMemberDto {
  TeamMemberDto({
    required this.teamId,
    required this.agentId,
    this.role = 'member',
  });

  factory TeamMemberDto.fromJson(Map<String, dynamic> json) => TeamMemberDto(
    teamId: json['team_id'] as String? ?? '',
    agentId: json['agent_id'] as String? ?? '',
    role: json['role'] as String? ?? 'member',
  );

  final String teamId;
  final String agentId;
  final String role;

  Map<String, dynamic> toJson() => {
    'team_id': teamId,
    'agent_id': agentId,
    'role': role,
  };
}

/// Wire DTO for an `Orchestration` (snake_case JSON). The structured proposal
/// travels as its canonical JSON string (`proposal_json`) so it reconstructs
/// losslessly; status is an enum `.name`; timestamps are ISO-8601 strings;
/// `hired_agent_ids` is a plain string list.
class OrchestrationDto {
  OrchestrationDto({
    required this.id,
    required this.workspaceId,
    required this.proposalJson,
    this.parentTicketId,
    this.spaceId,
    this.orchestratorAgentId,
    this.status = 'proposed',
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
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
  });

  factory OrchestrationDto.fromJson(Map<String, dynamic> json) =>
      OrchestrationDto(
        id: json['id'] as String,
        workspaceId: json['workspace_id'] as String? ?? '',
        proposalJson: json['proposal_json'] as String? ?? '{}',
        parentTicketId: json['parent_ticket_id'] as String?,
        spaceId: json['space_id'] as String?,
        orchestratorAgentId: json['orchestrator_agent_id'] as String?,
        status: json['status'] as String? ?? 'proposed',
        revision: (json['revision'] as num?)?.toInt() ?? 1,
        approvedRevision: (json['approved_revision'] as num?)?.toInt(),
        pipelineTemplateId: json['pipeline_template_id'] as String?,
        pipelineRunId: json['pipeline_run_id'] as String?,
        teamId: json['team_id'] as String?,
        projectId: json['project_id'] as String?,
        estimatedCostCents: (json['estimated_cost_cents'] as num?)?.toInt(),
        maxCostCents: (json['max_cost_cents'] as num?)?.toInt(),
        hiredAgentIds:
            (json['hired_agent_ids'] as List?)?.whereType<String>().toList() ??
            const [],
        errorMessage: json['error_message'] as String?,
        createdAt: json['created_at'] as String? ?? '',
        updatedAt: json['updated_at'] as String? ?? '',
        completedAt: json['completed_at'] as String?,
      );

  final String id;
  final String workspaceId;
  final String proposalJson;
  final String? parentTicketId;
  final String? spaceId;
  final String? orchestratorAgentId;
  final String status;
  final int revision;
  final int? approvedRevision;
  final String? pipelineTemplateId;
  final String? pipelineRunId;
  final String? teamId;
  final String? projectId;
  final int? estimatedCostCents;
  final int? maxCostCents;
  final List<String> hiredAgentIds;
  final String? errorMessage;
  final String createdAt;
  final String updatedAt;
  final String? completedAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'workspace_id': workspaceId,
    'proposal_json': proposalJson,
    if (parentTicketId != null) 'parent_ticket_id': parentTicketId,
    if (spaceId != null) 'space_id': spaceId,
    if (orchestratorAgentId != null)
      'orchestrator_agent_id': orchestratorAgentId,
    'status': status,
    'revision': revision,
    if (approvedRevision != null) 'approved_revision': approvedRevision,
    if (pipelineTemplateId != null) 'pipeline_template_id': pipelineTemplateId,
    if (pipelineRunId != null) 'pipeline_run_id': pipelineRunId,
    if (teamId != null) 'team_id': teamId,
    if (projectId != null) 'project_id': projectId,
    if (estimatedCostCents != null) 'estimated_cost_cents': estimatedCostCents,
    if (maxCostCents != null) 'max_cost_cents': maxCostCents,
    'hired_agent_ids': hiredAgentIds,
    if (errorMessage != null) 'error_message': errorMessage,
    'created_at': createdAt,
    'updated_at': updatedAt,
    if (completedAt != null) 'completed_at': completedAt,
  };
}

// ---- PR review ----
//
// The PR-review surface is per-`(owner, repo)`, unlike the workspace-scoped
// CRUD verticals: the host binds the workspace per session, but the GitHub
// repository coordinates (`owner`/`repo`) travel in the op/watch args because a
// workspace can review PRs across several repos. These DTOs reconstruct the
// `cc_domain` pr_review entities losslessly so the thin client renders the diff
// viewer, reviewer rail, comment threads and check runs without a database.

/// PrUser wire DTO — a GitHub login + avatar (the minimal user shape the PR
/// surface needs), plus an optional display [name] for picker labels.
class PrUserDto {
  PrUserDto({required this.login, required this.avatarUrl, this.name});

  factory PrUserDto.fromJson(Map<String, dynamic> json) => PrUserDto(
    login: json['login'] as String? ?? '',
    avatarUrl: json['avatar_url'] as String? ?? '',
    name: json['name'] as String?,
  );

  final String login;
  final String avatarUrl;
  final String? name;

  Map<String, dynamic> toJson() => {
    'login': login,
    'avatar_url': avatarUrl,
    'name': ?name,
  };
}

/// ReactionGroup wire DTO — an aggregated emoji reaction (`content`/`count` plus
/// the viewer's `user_reacted` flag and the reacting `usernames`). The emoji is
/// derived client-side from `content`, so it is not carried.
class ReactionGroupDto {
  ReactionGroupDto({
    required this.content,
    this.count = 0,
    this.userReacted = false,
    this.usernames = const [],
  });

  factory ReactionGroupDto.fromJson(Map<String, dynamic> json) =>
      ReactionGroupDto(
        content: json['content'] as String? ?? '',
        count: (json['count'] as num?)?.toInt() ?? 0,
        userReacted: json['user_reacted'] as bool? ?? false,
        usernames: ((json['usernames'] as List?) ?? const [])
            .map((u) => u.toString())
            .toList(),
      );

  final String content;
  final int count;
  final bool userReacted;
  final List<String> usernames;

  Map<String, dynamic> toJson() => {
    'content': content,
    'count': count,
    'user_reacted': userReacted,
    'usernames': usernames,
  };
}

/// PullRequest wire DTO — the full PR detail shape needed to reconstruct a
/// `PullRequest` entity on a thin client. Enum fields (`state`, `checks_status`,
/// `mergeable_state`, `review_decision`) travel as their stored strings;
/// timestamps are ISO-8601; nested users + reactions use their own DTOs.
class PullRequestDto {
  PullRequestDto({
    required this.id,
    required this.number,
    required this.title,
    required this.body,
    required this.state,
    required this.isDraft,
    required this.repoFullName,
    required this.htmlUrl,
    this.author,
    this.createdAt,
    this.updatedAt,
    this.mergedAt,
    this.externalId = '',
    this.headSha = '',
    this.baseRef = '',
    this.baseSha = '',
    this.headRef = '',
    this.requestedReviewers = const [],
    this.requestedTeamSlugs = const [],
    this.assignees = const [],
    this.reviewedByMe = false,
    this.reactions = const [],
    this.bodyHtml,
    this.changedFiles = 0,
    this.commitsCount = 0,
    this.additions = 0,
    this.deletions = 0,
    this.commentsCount = 0,
    this.checksStatus = 'none',
    this.mergeableState = 'unknown',
    this.reviewDecision = 'none',
  });

  factory PullRequestDto.fromJson(Map<String, dynamic> json) => PullRequestDto(
    id: (json['id'] as num?)?.toInt() ?? 0,
    number: (json['number'] as num?)?.toInt() ?? 0,
    title: json['title'] as String? ?? '',
    body: json['body'] as String? ?? '',
    state: json['state'] as String? ?? 'open',
    isDraft: json['is_draft'] as bool? ?? false,
    repoFullName: json['repo_full_name'] as String? ?? '',
    htmlUrl: json['html_url'] as String? ?? '',
    author: json['author'] is Map
        ? PrUserDto.fromJson((json['author'] as Map).cast<String, dynamic>())
        : null,
    createdAt: json['created_at'] as String?,
    updatedAt: json['updated_at'] as String?,
    mergedAt: json['merged_at'] as String?,
    externalId: json['external_id'] as String? ?? '',
    headSha: json['head_sha'] as String? ?? '',
    baseRef: json['base_ref'] as String? ?? '',
    baseSha: json['base_sha'] as String? ?? '',
    headRef: json['head_ref'] as String? ?? '',
    requestedReviewers: ((json['requested_reviewers'] as List?) ?? const [])
        .whereType<Map>()
        .map((u) => PrUserDto.fromJson(u.cast<String, dynamic>()))
        .toList(),
    requestedTeamSlugs: ((json['requested_team_slugs'] as List?) ?? const [])
        .whereType<String>()
        .toList(),
    assignees: ((json['assignees'] as List?) ?? const [])
        .whereType<Map>()
        .map((u) => PrUserDto.fromJson(u.cast<String, dynamic>()))
        .toList(),
    reviewedByMe: json['reviewed_by_me'] as bool? ?? false,
    reactions: ((json['reactions'] as List?) ?? const [])
        .whereType<Map>()
        .map((r) => ReactionGroupDto.fromJson(r.cast<String, dynamic>()))
        .toList(),
    bodyHtml: json['body_html'] as String?,
    changedFiles: (json['changed_files'] as num?)?.toInt() ?? 0,
    commitsCount: (json['commits_count'] as num?)?.toInt() ?? 0,
    additions: (json['additions'] as num?)?.toInt() ?? 0,
    deletions: (json['deletions'] as num?)?.toInt() ?? 0,
    commentsCount: (json['comments_count'] as num?)?.toInt() ?? 0,
    checksStatus: json['checks_status'] as String? ?? 'none',
    mergeableState: json['mergeable_state'] as String? ?? 'unknown',
    reviewDecision: json['review_decision'] as String? ?? 'none',
  );

  final int id;
  final int number;
  final String title;
  final String body;
  final String state;
  final bool isDraft;
  final String repoFullName;
  final String htmlUrl;
  final PrUserDto? author;
  final String? createdAt;
  final String? updatedAt;
  final String? mergedAt;
  final String externalId;
  final String headSha;
  final String baseRef;
  final String baseSha;
  final String headRef;
  final List<PrUserDto> requestedReviewers;
  final List<String> requestedTeamSlugs;
  final List<PrUserDto> assignees;
  final bool reviewedByMe;
  final List<ReactionGroupDto> reactions;
  final String? bodyHtml;
  final int changedFiles;
  final int commitsCount;
  final int additions;
  final int deletions;
  final int commentsCount;
  final String checksStatus;
  final String mergeableState;
  final String reviewDecision;

  Map<String, dynamic> toJson() => {
    'id': id,
    'number': number,
    'title': title,
    'body': body,
    'state': state,
    'is_draft': isDraft,
    'repo_full_name': repoFullName,
    'html_url': htmlUrl,
    'author': ?author?.toJson(),
    'created_at': ?createdAt,
    'updated_at': ?updatedAt,
    'merged_at': ?mergedAt,
    'external_id': externalId,
    'head_sha': headSha,
    'base_ref': baseRef,
    'base_sha': baseSha,
    'head_ref': headRef,
    'requested_reviewers': requestedReviewers.map((u) => u.toJson()).toList(),
    'requested_team_slugs': requestedTeamSlugs,
    'assignees': assignees.map((u) => u.toJson()).toList(),
    'reviewed_by_me': reviewedByMe,
    'reactions': reactions.map((r) => r.toJson()).toList(),
    'body_html': ?bodyHtml,
    'changed_files': changedFiles,
    'commits_count': commitsCount,
    'additions': additions,
    'deletions': deletions,
    'comments_count': commentsCount,
    'checks_status': checksStatus,
    'mergeable_state': mergeableState,
    'review_decision': reviewDecision,
  };
}

/// PrStackEntry wire DTO — one PR's membership in a stack, bottom-to-top
/// order inside [PrStackDto.pullRequests]. `state` travels as the API string
/// (`open`/`closed`); `merged_at` is ISO-8601 or null.
class PrStackEntryDto {
  PrStackEntryDto({
    required this.number,
    required this.state,
    required this.isDraft,
    required this.headRef,
    required this.headSha,
    this.mergedAt,
  });

  factory PrStackEntryDto.fromJson(Map<String, dynamic> json) =>
      PrStackEntryDto(
        number: (json['number'] as num?)?.toInt() ?? 0,
        state: json['state'] as String? ?? 'closed',
        isDraft: json['is_draft'] as bool? ?? false,
        headRef: json['head_ref'] as String? ?? '',
        headSha: json['head_sha'] as String? ?? '',
        mergedAt: json['merged_at'] as String?,
      );

  final int number;
  final String state;
  final bool isDraft;
  final String headRef;
  final String headSha;
  final String? mergedAt;

  Map<String, dynamic> toJson() => {
    'number': number,
    'state': state,
    'is_draft': isDraft,
    'head_ref': headRef,
    'head_sha': headSha,
    'merged_at': ?mergedAt,
  };
}

/// PrStack wire DTO — a GitHub pull request stack as served by the
/// `pr_review.*Stack` ops. Timestamps are ISO-8601.
class PrStackDto {
  PrStackDto({
    required this.id,
    required this.number,
    required this.externalId,
    required this.url,
    required this.baseRef,
    required this.open,
    this.createdAt,
    this.pullRequests = const [],
  });

  factory PrStackDto.fromJson(Map<String, dynamic> json) => PrStackDto(
    id: (json['id'] as num?)?.toInt() ?? 0,
    number: (json['number'] as num?)?.toInt() ?? 0,
    externalId: json['external_id'] as String? ?? '',
    url: json['url'] as String? ?? '',
    baseRef: json['base_ref'] as String? ?? '',
    open: json['open'] as bool? ?? true,
    createdAt: json['created_at'] as String?,
    pullRequests: ((json['pull_requests'] as List?) ?? const [])
        .whereType<Map>()
        .map((e) => PrStackEntryDto.fromJson(e.cast<String, dynamic>()))
        .toList(),
  );

  final int id;
  final int number;
  final String externalId;
  final String url;
  final String baseRef;
  final bool open;
  final String? createdAt;
  final List<PrStackEntryDto> pullRequests;

  Map<String, dynamic> toJson() => {
    'id': id,
    'number': number,
    'external_id': externalId,
    'url': url,
    'base_ref': baseRef,
    'open': open,
    'created_at': ?createdAt,
    'pull_requests': pullRequests.map((e) => e.toJson()).toList(),
  };
}

/// PrFile wire DTO — one changed file in a PR/commit. `status` and
/// `viewer_viewed_state` travel as their stored strings.
class PrFileDto {
  PrFileDto({
    required this.filename,
    required this.status,
    this.additions = 0,
    this.deletions = 0,
    this.patch = '',
    this.previousFilename,
    this.viewerViewedState = 'UNVIEWED',
  });

  factory PrFileDto.fromJson(Map<String, dynamic> json) => PrFileDto(
    filename: json['filename'] as String? ?? '',
    status: json['status'] as String? ?? 'modified',
    additions: (json['additions'] as num?)?.toInt() ?? 0,
    deletions: (json['deletions'] as num?)?.toInt() ?? 0,
    patch: json['patch'] as String? ?? '',
    previousFilename: json['previous_filename'] as String?,
    viewerViewedState: json['viewer_viewed_state'] as String? ?? 'UNVIEWED',
  );

  final String filename;
  final String status;
  final int additions;
  final int deletions;
  final String patch;
  final String? previousFilename;
  final String viewerViewedState;

  Map<String, dynamic> toJson() => {
    'filename': filename,
    'status': status,
    'additions': additions,
    'deletions': deletions,
    'patch': patch,
    'previous_filename': ?previousFilename,
    'viewer_viewed_state': viewerViewedState,
  };
}

/// PrCommit wire DTO — a single commit in a PR.
class PrCommitDto {
  PrCommitDto({
    required this.sha,
    required this.message,
    this.author,
    this.date,
  });

  factory PrCommitDto.fromJson(Map<String, dynamic> json) => PrCommitDto(
    sha: json['sha'] as String? ?? '',
    message: json['message'] as String? ?? '',
    author: json['author'] is Map
        ? PrUserDto.fromJson((json['author'] as Map).cast<String, dynamic>())
        : null,
    date: json['date'] as String?,
  );

  final String sha;
  final String message;
  final PrUserDto? author;
  final String? date;

  Map<String, dynamic> toJson() => {
    'sha': sha,
    'message': message,
    'author': ?author?.toJson(),
    'date': ?date,
  };
}

/// PrReviewSubmission wire DTO — a submitted review verdict (`state` as `.name`)
/// with its author and body.
class PrReviewSubmissionDto {
  PrReviewSubmissionDto({
    required this.state,
    this.author,
    this.body = '',
    this.id = 0,
    this.submittedAt,
    this.reactions = const [],
  });

  factory PrReviewSubmissionDto.fromJson(Map<String, dynamic> json) =>
      PrReviewSubmissionDto(
        state: json['state'] as String? ?? 'commented',
        author: json['author'] is Map
            ? PrUserDto.fromJson(
                (json['author'] as Map).cast<String, dynamic>(),
              )
            : null,
        body: json['body'] as String? ?? '',
        id: (json['id'] as num?)?.toInt() ?? 0,
        submittedAt: json['submitted_at'] as String?,
        reactions: ((json['reactions'] as List?) ?? const [])
            .whereType<Map>()
            .map((r) => ReactionGroupDto.fromJson(r.cast<String, dynamic>()))
            .toList(),
      );

  final int id;
  final String state;
  final PrUserDto? author;
  final String body;
  final String? submittedAt;
  final List<ReactionGroupDto> reactions;

  Map<String, dynamic> toJson() => {
    'id': id,
    'state': state,
    'author': ?author?.toJson(),
    'body': body,
    'submitted_at': ?submittedAt,
    'reactions': reactions.map((r) => r.toJson()).toList(),
  };
}

/// PrTimelineEvent wire DTO — a conversation-timeline event (review requested
/// / review request removed) for the PR Overview activity feed.
class PrTimelineEventDto {
  PrTimelineEventDto({
    required this.kind,
    this.actor,
    this.reviewerName = '',
    this.reviewerIsTeam = false,
    this.reviewerAvatarUrl = '',
    this.createdAt,
  });

  factory PrTimelineEventDto.fromJson(Map<String, dynamic> json) =>
      PrTimelineEventDto(
        kind: json['kind'] as String? ?? '',
        actor: json['actor'] is Map
            ? PrUserDto.fromJson((json['actor'] as Map).cast<String, dynamic>())
            : null,
        reviewerName: json['reviewer_name'] as String? ?? '',
        reviewerIsTeam: json['reviewer_is_team'] as bool? ?? false,
        reviewerAvatarUrl: json['reviewer_avatar_url'] as String? ?? '',
        createdAt: json['created_at'] as String?,
      );

  final String kind;
  final PrUserDto? actor;
  final String reviewerName;
  final bool reviewerIsTeam;
  final String reviewerAvatarUrl;
  final String? createdAt;

  Map<String, dynamic> toJson() => {
    'kind': kind,
    'actor': ?actor?.toJson(),
    'reviewer_name': reviewerName,
    'reviewer_is_team': reviewerIsTeam,
    'reviewer_avatar_url': reviewerAvatarUrl,
    'created_at': ?createdAt,
  };
}

/// PrCodeReviewComment wire DTO — an inline review comment anchored to a diff
/// line. Carries the reply chain, anchor lines, diff hunk and reactions.
class PrCodeReviewCommentDto {
  PrCodeReviewCommentDto({
    required this.id,
    required this.body,
    required this.path,
    this.user,
    this.position,
    this.createdAt,
    this.side = 'RIGHT',
    this.inReplyToId,
    this.reviewId,
    this.startLine,
    this.diffHunk = '',
    this.line,
    this.originalLine,
    this.reactions = const [],
    this.threadId,
    this.isResolved = false,
  });

  factory PrCodeReviewCommentDto.fromJson(Map<String, dynamic> json) =>
      PrCodeReviewCommentDto(
        id: (json['id'] as num?)?.toInt() ?? 0,
        body: json['body'] as String? ?? '',
        path: json['path'] as String? ?? '',
        user: json['user'] is Map
            ? PrUserDto.fromJson((json['user'] as Map).cast<String, dynamic>())
            : null,
        position: (json['position'] as num?)?.toInt(),
        createdAt: json['created_at'] as String?,
        side: json['side'] as String? ?? 'RIGHT',
        inReplyToId: (json['in_reply_to_id'] as num?)?.toInt(),
        reviewId: (json['review_id'] as num?)?.toInt(),
        startLine: (json['start_line'] as num?)?.toInt(),
        diffHunk: json['diff_hunk'] as String? ?? '',
        line: (json['line'] as num?)?.toInt(),
        originalLine: (json['original_line'] as num?)?.toInt(),
        threadId: json['thread_id'] as String?,
        isResolved: json['is_resolved'] as bool? ?? false,
        reactions: ((json['reactions'] as List?) ?? const [])
            .whereType<Map>()
            .map((r) => ReactionGroupDto.fromJson(r.cast<String, dynamic>()))
            .toList(),
      );

  final int id;
  final String body;
  final String path;
  final PrUserDto? user;
  final int? position;
  final String? createdAt;
  final String side;
  final int? inReplyToId;
  final int? reviewId;
  final int? startLine;
  final String diffHunk;
  final int? line;
  final int? originalLine;

  /// Forge thread id (GitHub's GraphQL `PullRequestReviewThread` id), null when
  /// the forge has no thread object or the state could not be resolved.
  final String? threadId;

  /// Whether the thread this comment belongs to is resolved on the forge.
  final bool isResolved;
  final List<ReactionGroupDto> reactions;

  Map<String, dynamic> toJson() => {
    'id': id,
    'body': body,
    'path': path,
    'user': ?user?.toJson(),
    'position': ?position,
    'created_at': ?createdAt,
    'side': side,
    'in_reply_to_id': ?inReplyToId,
    'review_id': ?reviewId,
    'start_line': ?startLine,
    'diff_hunk': diffHunk,
    'line': ?line,
    'original_line': ?originalLine,
    'thread_id': ?threadId,
    if (isResolved) 'is_resolved': true,
    'reactions': reactions.map((r) => r.toJson()).toList(),
  };
}

/// IssueComment wire DTO — a top-level (timeline) PR comment with reactions.
class IssueCommentDto {
  IssueCommentDto({
    required this.id,
    required this.body,
    this.user,
    this.createdAt,
    this.reactions = const [],
  });

  factory IssueCommentDto.fromJson(Map<String, dynamic> json) =>
      IssueCommentDto(
        id: (json['id'] as num?)?.toInt() ?? 0,
        body: json['body'] as String? ?? '',
        user: json['user'] is Map
            ? PrUserDto.fromJson((json['user'] as Map).cast<String, dynamic>())
            : null,
        createdAt: json['created_at'] as String?,
        reactions: ((json['reactions'] as List?) ?? const [])
            .whereType<Map>()
            .map((r) => ReactionGroupDto.fromJson(r.cast<String, dynamic>()))
            .toList(),
      );

  final int id;
  final String body;
  final PrUserDto? user;
  final String? createdAt;
  final List<ReactionGroupDto> reactions;

  Map<String, dynamic> toJson() => {
    'id': id,
    'body': body,
    'user': ?user?.toJson(),
    'created_at': ?createdAt,
    'reactions': reactions.map((r) => r.toJson()).toList(),
  };
}

/// CheckRun wire DTO — a single CI check run. `status`/`conclusion` travel as
/// their stored strings; the resolved parent `workflow_name` rides along.
class CheckRunDto {
  CheckRunDto({
    required this.name,
    required this.status,
    this.conclusion,
    this.htmlUrl = '',
    this.startedAt,
    this.completedAt,
    this.output = '',
    this.workflowName,
    this.checkSuiteId,
    this.jobId,
    this.workflowRunId,
  });

  factory CheckRunDto.fromJson(Map<String, dynamic> json) => CheckRunDto(
    name: json['name'] as String? ?? '',
    status: json['status'] as String? ?? 'queued',
    conclusion: json['conclusion'] as String?,
    htmlUrl: json['html_url'] as String? ?? '',
    startedAt: json['started_at'] as String?,
    completedAt: json['completed_at'] as String?,
    output: json['output'] as String? ?? '',
    workflowName: json['workflow_name'] as String?,
    checkSuiteId: (json['check_suite_id'] as num?)?.toInt(),
    jobId: (json['job_id'] as num?)?.toInt(),
    workflowRunId: (json['workflow_run_id'] as num?)?.toInt(),
  );

  final String name;
  final String status;
  final String? conclusion;
  final String htmlUrl;
  final String? startedAt;
  final String? completedAt;
  final String output;
  final String? workflowName;
  final int? checkSuiteId;
  final int? jobId;
  final int? workflowRunId;

  Map<String, dynamic> toJson() => {
    'name': name,
    'status': status,
    'conclusion': ?conclusion,
    'html_url': htmlUrl,
    'started_at': ?startedAt,
    'completed_at': ?completedAt,
    'output': output,
    'workflow_name': ?workflowName,
    'check_suite_id': ?checkSuiteId,
    'job_id': ?jobId,
    'workflow_run_id': ?workflowRunId,
  };
}

/// JobRunStep wire DTO — enums travel as .name strings.
class JobRunStepDto {
  /// Creates a [JobRunStepDto].
  JobRunStepDto({
    required this.number,
    required this.name,
    required this.status,
    this.conclusion,
    this.startedAt,
    this.completedAt,
  });

  /// Decodes from the wire JSON shape.
  factory JobRunStepDto.fromJson(Map<String, dynamic> json) => JobRunStepDto(
    number: (json['number'] as num?)?.toInt() ?? 0,
    name: json['name'] as String? ?? '',
    status: json['status'] as String? ?? 'queued',
    conclusion: json['conclusion'] as String?,
    startedAt: json['started_at'] as String?,
    completedAt: json['completed_at'] as String?,
  );

  /// 1-based step index within the job.
  final int number;

  /// Step display name.
  final String name;

  /// Raw status string.
  final String status;

  /// Raw conclusion string when completed.
  final String? conclusion;

  /// Started-at ISO-8601 string.
  final String? startedAt;

  /// Completed-at ISO-8601 string.
  final String? completedAt;

  /// Serializes to the wire JSON shape.
  Map<String, dynamic> toJson() => {
    'number': number,
    'name': name,
    'status': status,
    'conclusion': ?conclusion,
    'started_at': ?startedAt,
    'completed_at': ?completedAt,
  };
}

/// JobRunDetail wire DTO — `logs` is null until GitHub publishes them.
class JobRunDetailDto {
  /// Creates a [JobRunDetailDto].
  JobRunDetailDto({
    required this.jobId,
    required this.status,
    this.conclusion,
    this.htmlUrl = '',
    this.steps = const [],
    this.logs,
    this.logsTruncated = false,
  });

  /// Decodes from the wire JSON shape.
  factory JobRunDetailDto.fromJson(Map<String, dynamic> json) =>
      JobRunDetailDto(
        jobId: (json['job_id'] as num?)?.toInt() ?? 0,
        status: json['status'] as String? ?? 'queued',
        conclusion: json['conclusion'] as String?,
        htmlUrl: json['html_url'] as String? ?? '',
        steps: ((json['steps'] as List?) ?? const [])
            .whereType<Map>()
            .map((s) => JobRunStepDto.fromJson(s.cast<String, dynamic>()))
            .toList(growable: false),
        logs: json['logs'] as String?,
        logsTruncated: json['logs_truncated'] as bool? ?? false,
      );

  /// Job id.
  final int jobId;

  /// Raw status string.
  final String status;

  /// Raw conclusion string when completed.
  final String? conclusion;

  /// Link to the job on GitHub.
  final String htmlUrl;

  /// Step progress.
  final List<JobRunStepDto> steps;

  /// Plain-text job logs (tail-truncated), null until published.
  final String? logs;

  /// Whether [logs] was tail-truncated to the byte cap.
  final bool logsTruncated;

  /// Serializes to the wire JSON shape.
  Map<String, dynamic> toJson() => {
    'job_id': jobId,
    'status': status,
    'conclusion': ?conclusion,
    'html_url': htmlUrl,
    'steps': steps.map((s) => s.toJson()).toList(),
    'logs': ?logs,
    'logs_truncated': logsTruncated,
  };
}

/// WorkflowJobNode wire DTO.
class WorkflowJobNodeDto {
  /// Creates a [WorkflowJobNodeDto].
  WorkflowJobNodeDto({
    required this.id,
    required this.name,
    this.needs = const [],
  });

  /// Decodes from the wire JSON shape.
  factory WorkflowJobNodeDto.fromJson(Map<String, dynamic> json) =>
      WorkflowJobNodeDto(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        needs: ((json['needs'] as List?) ?? const [])
            .map((e) => '$e')
            .toList(growable: false),
      );

  /// Job id (the YAML key under `jobs:`).
  final String id;

  /// Display name.
  final String name;

  /// Upstream job ids.
  final List<String> needs;

  /// Serializes to the wire JSON shape.
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'needs': needs};
}

/// WorkflowGraph wire DTO.
class WorkflowGraphDto {
  /// Creates a [WorkflowGraphDto].
  WorkflowGraphDto({required this.name, this.jobs = const []});

  /// Decodes from the wire JSON shape.
  factory WorkflowGraphDto.fromJson(Map<String, dynamic> json) =>
      WorkflowGraphDto(
        name: json['name'] as String? ?? '',
        jobs: ((json['jobs'] as List?) ?? const [])
            .whereType<Map>()
            .map((j) => WorkflowJobNodeDto.fromJson(j.cast<String, dynamic>()))
            .toList(growable: false),
      );

  /// Workflow display name.
  final String name;

  /// Job nodes.
  final List<WorkflowJobNodeDto> jobs;

  /// Serializes to the wire JSON shape.
  Map<String, dynamic> toJson() => {
    'name': name,
    'jobs': jobs.map((j) => j.toJson()).toList(),
  };
}

/// Commit-status wire DTO — one status context for a PR head SHA. Carries the
/// `target_url` that deploy-preview integrations publish through.
class CommitStatusDto {
  /// Creates a [CommitStatusDto].
  CommitStatusDto({
    required this.context,
    required this.state,
    this.targetUrl = '',
    this.description = '',
    this.updatedAt,
  });

  /// Decodes from the wire JSON shape.
  factory CommitStatusDto.fromJson(Map<String, dynamic> json) =>
      CommitStatusDto(
        context: json['context'] as String? ?? '',
        state: json['state'] as String? ?? 'pending',
        targetUrl: json['target_url'] as String? ?? '',
        description: json['description'] as String? ?? '',
        updatedAt: json['updated_at'] as String?,
      );

  /// Status context.
  final String context;

  /// Raw state string.
  final String state;

  /// Target URL.
  final String targetUrl;

  /// Description.
  final String description;

  /// Updated-at ISO-8601 string.
  final String? updatedAt;

  /// Serializes to the wire JSON shape.
  Map<String, dynamic> toJson() => {
    'context': context,
    'state': state,
    'target_url': targetUrl,
    'description': description,
    'updated_at': ?updatedAt,
  };
}

/// PrReviewer wire DTO — an enriched reviewer row (a tagged union of user/team).
/// `kind` is `user` | `team`; `state` is the review-submission `.name`;
/// `is_code_owner` drives the shield. Team rows may carry a `reviewed_by` user
/// (the member who reviewed on the team's behalf).
class PrReviewerDto {
  PrReviewerDto({
    required this.kind,
    required this.isCodeOwner,
    required this.state,
    this.user,
    this.name = '',
    this.slug = '',
    this.avatarUrl = '',
    this.reviewedBy,
  });

  factory PrReviewerDto.fromJson(Map<String, dynamic> json) => PrReviewerDto(
    kind: json['kind'] as String? ?? 'user',
    isCodeOwner: json['is_code_owner'] as bool? ?? false,
    state: json['state'] as String? ?? 'pending',
    user: json['user'] is Map
        ? PrUserDto.fromJson((json['user'] as Map).cast<String, dynamic>())
        : null,
    name: json['name'] as String? ?? '',
    slug: json['slug'] as String? ?? '',
    avatarUrl: json['avatar_url'] as String? ?? '',
    reviewedBy: json['reviewed_by'] is Map
        ? PrUserDto.fromJson(
            (json['reviewed_by'] as Map).cast<String, dynamic>(),
          )
        : null,
  );

  /// `user` or `team`.
  final String kind;
  final bool isCodeOwner;
  final String state;

  /// Set for `kind == 'user'`.
  final PrUserDto? user;

  /// Set for `kind == 'team'`.
  final String name;
  final String slug;
  final String avatarUrl;

  /// The member who reviewed on the team's behalf (`kind == 'team'`), if any.
  final PrUserDto? reviewedBy;

  Map<String, dynamic> toJson() => {
    'kind': kind,
    'is_code_owner': isCodeOwner,
    'state': state,
    'user': ?user?.toJson(),
    if (kind == 'team') 'name': name,
    if (kind == 'team') 'slug': slug,
    if (kind == 'team' && avatarUrl.isNotEmpty) 'avatar_url': avatarUrl,
    'reviewed_by': ?reviewedBy?.toJson(),
  };
}

/// PrReviewerCandidate wire DTO — a selectable reviewer/assignee picker entry.
/// `kind` is `user` | `team`; `key` is the login (users) or slug (teams).
class PrReviewerCandidateDto {
  PrReviewerCandidateDto({
    required this.kind,
    required this.key,
    required this.label,
    this.avatarUrl,
  });

  factory PrReviewerCandidateDto.fromJson(Map<String, dynamic> json) =>
      PrReviewerCandidateDto(
        kind: json['kind'] as String? ?? 'user',
        key: json['key'] as String? ?? '',
        label: json['label'] as String? ?? '',
        avatarUrl: json['avatar_url'] as String?,
      );

  final String kind;
  final String key;
  final String label;
  final String? avatarUrl;

  Map<String, dynamic> toJson() => {
    'kind': kind,
    'key': key,
    'label': label,
    'avatar_url': ?avatarUrl,
  };
}

/// PR preview wire DTO — the lightweight `(title, state, draft, merged, url)`
/// shape backing the inline `#`-reference chip. `null` over the wire means the
/// PR couldn't be resolved (404/network); the client falls back to a plain link.
class PrPreviewDto {
  PrPreviewDto({
    required this.title,
    required this.state,
    required this.isDraft,
    required this.isMerged,
    required this.htmlUrl,
  });

  factory PrPreviewDto.fromJson(Map<String, dynamic> json) => PrPreviewDto(
    title: json['title'] as String? ?? '',
    state: json['state'] as String? ?? 'open',
    isDraft: json['is_draft'] as bool? ?? false,
    isMerged: json['is_merged'] as bool? ?? false,
    htmlUrl: json['html_url'] as String? ?? '',
  );

  final String title;
  final String state;
  final bool isDraft;
  final bool isMerged;
  final String htmlUrl;

  Map<String, dynamic> toJson() => {
    'title': title,
    'state': state,
    'is_draft': isDraft,
    'is_merged': isMerged,
    'html_url': htmlUrl,
  };
}

/// Commit preview wire DTO — the `(title, short_sha)` shape backing the inline
/// commit-reference chip. `null` over the wire means the commit couldn't be
/// resolved.
class CommitPreviewDto {
  CommitPreviewDto({required this.title, required this.shortSha});

  factory CommitPreviewDto.fromJson(Map<String, dynamic> json) =>
      CommitPreviewDto(
        title: json['title'] as String? ?? '',
        shortSha: json['short_sha'] as String? ?? '',
      );

  final String title;
  final String shortSha;

  Map<String, dynamic> toJson() => {'title': title, 'short_sha': shortSha};
}

// ---- Calendar (events + connected accounts) ----
//
// The calendar feature is workspace-scoped at the repository (the per-workspace
// Google account, not id uniqueness, is the isolation boundary). The thin
// client only READS this surface — synced events + connected accounts; the
// writes (account connect/disconnect, RSVP, the sync reconciler, alerts) depend
// on the host-resident OAuth tokens + Google API client, so they have no RPC
// surface. These DTOs are the typed wire view the client parses back; the host
// injects the authoritative workspace per session, so no `workspace_id` travels
// on the wire. Enum-free shapes → plain scalars; timestamps are ISO-8601.
//
// NOTE: OAuth tokens are NOT part of this surface — they live in the platform
// secure store (`GoogleCredentialsRepository`), never in the calendar
// repository, so nothing secret is carried here.

/// CalendarAttendee wire DTO — one attendee on a [CalendarEventDto].
class CalendarAttendeeDto {
  CalendarAttendeeDto({
    required this.email,
    this.displayName,
    this.responseStatus,
    this.self = false,
    this.organizer = false,
  });

  factory CalendarAttendeeDto.fromJson(Map<String, dynamic> json) =>
      CalendarAttendeeDto(
        email: json['email'] as String? ?? '',
        displayName: json['display_name'] as String?,
        responseStatus: json['response_status'] as String?,
        self: json['self'] as bool? ?? false,
        organizer: json['organizer'] as bool? ?? false,
      );

  final String email;
  final String? displayName;
  final String? responseStatus;
  final bool self;
  final bool organizer;

  Map<String, dynamic> toJson() => {
    'email': email,
    'display_name': ?displayName,
    'response_status': ?responseStatus,
    'self': self,
    'organizer': organizer,
  };
}

/// CalendarEvent wire DTO — a calendar event synced (read-only) from a provider.
/// Carries no `workspace_id` (the host binds it per session).
class CalendarEventDto {
  CalendarEventDto({
    required this.id,
    required this.accountId,
    required this.externalEventId,
    required this.calendarId,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.updatedAt,
    this.description,
    this.location,
    this.meetingUrl,
    this.recurringEventId,
    this.alertedAt,
    this.isAllDay = false,
    this.status = 'confirmed',
    this.attendees = const [],
  });

  factory CalendarEventDto.fromJson(Map<String, dynamic> json) =>
      CalendarEventDto(
        id: json['id'] as String,
        accountId: json['account_id'] as String? ?? '',
        externalEventId: json['external_event_id'] as String? ?? '',
        calendarId: json['calendar_id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        startTime: json['start_time'] as String? ?? '',
        endTime: json['end_time'] as String? ?? '',
        updatedAt: json['updated_at'] as String? ?? '',
        description: json['description'] as String?,
        location: json['location'] as String?,
        meetingUrl: json['meeting_url'] as String?,
        recurringEventId: json['recurring_event_id'] as String?,
        alertedAt: json['alerted_at'] as String?,
        isAllDay: json['is_all_day'] as bool? ?? false,
        status: json['status'] as String? ?? 'confirmed',
        attendees: ((json['attendees'] as List?) ?? const [])
            .whereType<Map>()
            .map((a) => CalendarAttendeeDto.fromJson(a.cast<String, dynamic>()))
            .toList(),
      );

  final String id;
  final String accountId;
  final String externalEventId;
  final String calendarId;
  final String title;

  /// ISO-8601 start timestamp — or a bare `YYYY-MM-DD` civil date when
  /// [isAllDay] (an all-day event is a day, not an instant: a bare date
  /// parses as the READER's local midnight, so the day never shifts with the
  /// reader's timezone).
  final String startTime;

  /// ISO-8601 end timestamp — bare `YYYY-MM-DD` (exclusive) when [isAllDay].
  final String endTime;

  /// ISO-8601 last-updated timestamp.
  final String updatedAt;
  final String? description;
  final String? location;
  final String? meetingUrl;
  final String? recurringEventId;

  /// ISO-8601 timestamp when the "starting soon" alert fired, or null.
  final String? alertedAt;
  final bool isAllDay;

  /// `confirmed` / `tentative` / `cancelled`.
  final String status;
  final List<CalendarAttendeeDto> attendees;

  Map<String, dynamic> toJson() => {
    'id': id,
    'account_id': accountId,
    'external_event_id': externalEventId,
    'calendar_id': calendarId,
    'title': title,
    'start_time': startTime,
    'end_time': endTime,
    'updated_at': updatedAt,
    'description': ?description,
    'location': ?location,
    'meeting_url': ?meetingUrl,
    'recurring_event_id': ?recurringEventId,
    'alerted_at': ?alertedAt,
    'is_all_day': isAllDay,
    'status': status,
    'attendees': attendees.map((a) => a.toJson()).toList(),
  };
}

/// CalendarAccount wire DTO — a connected calendar account (per workspace).
/// Carries no `workspace_id` (the host binds it per session) and, by design, no
/// OAuth tokens — only the non-secret display/sync metadata.
class CalendarAccountDto {
  CalendarAccountDto({
    required this.id,
    required this.providerId,
    required this.accountEmail,
    this.displayName,
    this.lastSyncedAt,
    this.authExpiredAt,
  });

  factory CalendarAccountDto.fromJson(Map<String, dynamic> json) =>
      CalendarAccountDto(
        id: json['id'] as String,
        providerId: json['provider_id'] as String? ?? 'google',
        accountEmail: json['account_email'] as String? ?? '',
        displayName: json['display_name'] as String?,
        lastSyncedAt: json['last_synced_at'] as String?,
        authExpiredAt: json['auth_expired_at'] as String?,
      );

  final String id;
  final String providerId;
  final String accountEmail;
  final String? displayName;

  /// ISO-8601 last-synced timestamp, or null.
  final String? lastSyncedAt;

  /// ISO-8601 timestamp when the OAuth refresh token was found dead, or null.
  final String? authExpiredAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'provider_id': providerId,
    'account_email': accountEmail,
    'display_name': ?displayName,
    'last_synced_at': ?lastSyncedAt,
    'auth_expired_at': ?authExpiredAt,
  };
}

/// CalendarSource wire DTO — one of a connected account's calendars (the
/// sidebar's per-account calendar list). Carries no `workspace_id` (the host
/// binds it per session); `account_id` is stamped host→client so a viewer can
/// group sources by owning account even when watching across accounts.
class CalendarSourceDto {
  CalendarSourceDto({
    required this.accountId,
    required this.id,
    required this.summary,
    required this.primary,
    required this.writable,
    this.backgroundColor,
  });

  factory CalendarSourceDto.fromJson(Map<String, dynamic> json) =>
      CalendarSourceDto(
        accountId: json['account_id'] as String? ?? '',
        id: json['id'] as String,
        summary: json['summary'] as String? ?? '',
        primary: json['primary'] as bool? ?? false,
        writable: json['writable'] as bool? ?? false,
        backgroundColor: json['background_color'] as String?,
      );

  /// Owning connected account id.
  final String accountId;

  /// Provider calendar id (`primary` for the account's main calendar).
  final String id;

  /// Display name.
  final String summary;

  /// The calendar's accent color as a `#rrggbb` hex string, or null.
  final String? backgroundColor;

  /// Whether this is the account's primary calendar.
  final bool primary;

  /// Whether the user can write to it (owner/writer access role).
  final bool writable;

  Map<String, dynamic> toJson() => {
    'account_id': accountId,
    'id': id,
    'summary': summary,
    'primary': primary,
    'writable': writable,
    'background_color': ?backgroundColor,
  };
}

// ---- PR lifecycle (the local PR-draft → published → created record) ----
//
// `PullRequests` is a workspace-scoped table (every row carries `workspace_id`).
// The thin client BOTH reads (the compose-PR screen's draft list + a draft by
// id) AND writes (create a draft, update it, publish it to GitHub via the
// host-resident token, delete a draft) this surface over RPC — every op sources
// the bound session's workspace server-side and the host validates an id-keyed
// row belongs to it before mutating. This DTO is the typed wire view the client
// parses back. The `workspace_id` it carries is the AUTHORITATIVE one the host
// stamps on each emitted row (a host→client field, never accepted as a client
// arg), so the client can faithfully rebuild the entity even on the id-keyed
// `getById` path (the entity's `workspaceId` is non-null). Timestamps are
// ISO-8601; the lifecycle status is the plain `draft` / `published` / `created`
// name.

/// PrGeneration wire DTO — one local PR-lifecycle record (a generated PR draft
/// and its publish state). [workspaceId] is the authoritative scope the host
/// stamps on the wire (never a client-supplied arg).
class PrGenerationDto {
  PrGenerationDto({
    required this.id,
    required this.workspaceId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.title,
    this.body,
    this.branch,
  });

  factory PrGenerationDto.fromJson(Map<String, dynamic> json) =>
      PrGenerationDto(
        id: json['id'] as String,
        workspaceId: json['workspace_id'] as String? ?? '',
        status: json['status'] as String? ?? 'draft',
        createdAt: json['created_at'] as String? ?? '',
        updatedAt: json['updated_at'] as String? ?? '',
        title: json['title'] as String?,
        body: json['body'] as String?,
        branch: json['branch'] as String?,
      );

  final String id;

  /// The authoritative workspace scope (host-stamped on the wire).
  final String workspaceId;

  /// Lifecycle status name: `draft` / `published` / `created`.
  final String status;

  /// ISO-8601 created timestamp.
  final String createdAt;

  /// ISO-8601 last-updated timestamp.
  final String updatedAt;
  final String? title;
  final String? body;
  final String? branch;

  Map<String, dynamic> toJson() => {
    'id': id,
    'workspace_id': workspaceId,
    'status': status,
    'created_at': createdAt,
    'updated_at': updatedAt,
    'title': ?title,
    'body': ?body,
    'branch': ?branch,
  };
}

// ---- Activity log (the audit trail for one entity) ----
//
// The `activity_log` table is workspace-scoped (every row carries
// `workspace_id`). The thin client only READS this surface — the audit-trail
// stream for a single entity (e.g. the timeline on a ticket / run) — over the
// `activity.watchForEntity` subscription. The writes happen server-side (the
// domain-event audit bridge persists `ActivityLogged` events), so they have no
// RPC surface. The host injects the authoritative workspace per session and
// scopes the query by it, so no `workspace_id` travels on the wire; the client
// refills it from the bound workspace it already holds. Timestamp is ISO-8601.

/// ActivityEntry wire DTO — one audit-trail row for an entity. Carries no
/// `workspace_id` (the host binds it per session); the client refills it from
/// the bound workspace it already holds.
class ActivityEntryDto {
  ActivityEntryDto({
    required this.id,
    required this.actorType,
    required this.action,
    required this.entityType,
    required this.createdAt,
    this.actorId,
    this.entityId,
    this.details,
    this.runId,
  });

  factory ActivityEntryDto.fromJson(Map<String, dynamic> json) =>
      ActivityEntryDto(
        id: json['id'] as String,
        actorType: json['actor_type'] as String? ?? '',
        action: json['action'] as String? ?? '',
        entityType: json['entity_type'] as String? ?? '',
        createdAt: json['created_at'] as String? ?? '',
        actorId: json['actor_id'] as String?,
        entityId: json['entity_id'] as String?,
        details: json['details'] as String?,
        runId: json['run_id'] as String?,
      );

  final String id;

  /// `agent` / `user` / `system`.
  final String actorType;

  /// The action performed (e.g. `ticket_assigned`, `run_completed`).
  final String action;

  /// Entity type acted on (`ticket` / `run` / …).
  final String entityType;

  /// ISO-8601 timestamp when it happened.
  final String createdAt;
  final String? actorId;
  final String? entityId;
  final String? details;
  final String? runId;

  Map<String, dynamic> toJson() => {
    'id': id,
    'actor_type': actorType,
    'action': action,
    'entity_type': entityType,
    'created_at': createdAt,
    'actor_id': ?actorId,
    'entity_id': ?entityId,
    'details': ?details,
    'run_id': ?runId,
  };
}

/// Weather-snapshot wire DTO (soundscapes) — the point-in-time observation the
/// host fetches from Open-Meteo and thin clients read over RPC. Mirrors
/// [WeatherSnapshot]: the condition travels as its enum `.name`, timestamps as
/// ISO-8601 strings and numeric fields as `num` on the wire.
class WeatherSnapshotDto {
  WeatherSnapshotDto({
    required this.latitude,
    required this.longitude,
    required this.condition,
    required this.isDay,
    required this.temperatureCelsius,
    required this.windSpeedKmh,
    required this.observedAt,
    this.locationLabel,
    this.sunrise,
    this.sunset,
  });

  factory WeatherSnapshotDto.fromJson(Map<String, dynamic> json) =>
      WeatherSnapshotDto(
        latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
        longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
        condition: json['condition'] as String? ?? '',
        isDay: json['is_day'] as bool? ?? true,
        temperatureCelsius:
            (json['temperature_celsius'] as num?)?.toDouble() ?? 0,
        windSpeedKmh: (json['wind_speed_kmh'] as num?)?.toDouble() ?? 0,
        observedAt: json['observed_at'] as String?,
        locationLabel: json['location_label'] as String?,
        sunrise: json['sunrise'] as String?,
        sunset: json['sunset'] as String?,
      );

  factory WeatherSnapshotDto.fromEntity(WeatherSnapshot s) =>
      WeatherSnapshotDto(
        latitude: s.latitude,
        longitude: s.longitude,
        condition: s.condition.name,
        isDay: s.isDay,
        temperatureCelsius: s.temperatureCelsius,
        windSpeedKmh: s.windSpeedKmh,
        observedAt: s.observedAt.toIso8601String(),
        locationLabel: s.locationLabel,
        sunrise: s.sunrise?.toIso8601String(),
        sunset: s.sunset?.toIso8601String(),
      );

  final double latitude;
  final double longitude;

  /// The condition bucket, as [WeatherCondition]'s enum `.name`.
  final String condition;
  final bool isDay;
  final double temperatureCelsius;
  final double windSpeedKmh;

  /// Optional resolved place name.
  final String? locationLabel;

  /// ISO-8601 sunrise, when known.
  final String? sunrise;

  /// ISO-8601 sunset, when known.
  final String? sunset;

  /// ISO-8601 observation time; null only on a malformed payload.
  final String? observedAt;

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'condition': condition,
    'is_day': isDay,
    'temperature_celsius': temperatureCelsius,
    'wind_speed_kmh': windSpeedKmh,
    if (observedAt != null) 'observed_at': observedAt,
    if (locationLabel != null) 'location_label': locationLabel,
    if (sunrise != null) 'sunrise': sunrise,
    if (sunset != null) 'sunset': sunset,
  };

  /// Rebuilds the domain entity. An unrecognized/absent [condition] falls back
  /// to [WeatherCondition.clouds]; an absent [observedAt] to the Unix epoch.
  WeatherSnapshot toEntity() => WeatherSnapshot(
    latitude: latitude,
    longitude: longitude,
    condition: WeatherCondition.fromName(condition),
    isDay: isDay,
    temperatureCelsius: temperatureCelsius,
    windSpeedKmh: windSpeedKmh,
    observedAt: observedAt == null
        ? DateTime.fromMillisecondsSinceEpoch(0)
        : DateTime.tryParse(observedAt!) ??
              DateTime.fromMillisecondsSinceEpoch(0),
    locationLabel: locationLabel,
    sunrise: sunrise == null ? null : DateTime.tryParse(sunrise!),
    sunset: sunset == null ? null : DateTime.tryParse(sunset!),
  );
}

/// Wire shape of a selectable font family (`fonts.list`).
class FontFamilyDto {
  FontFamilyDto({
    required this.id,
    required this.family,
    required this.category,
    required this.weights,
    required this.styles,
    required this.subsets,
    required this.defSubset,
    required this.variable,
  });

  factory FontFamilyDto.fromJson(Map<String, dynamic> json) => FontFamilyDto(
    id: json['id'] as String? ?? '',
    family: json['family'] as String? ?? '',
    category: json['category'] as String? ?? 'sans-serif',
    weights:
        (json['weights'] as List?)
            ?.map((w) => (w as num).toInt())
            .toList(growable: false) ??
        const [400],
    styles:
        (json['styles'] as List?)
            ?.map((s) => s as String)
            .toList(growable: false) ??
        const ['normal'],
    subsets:
        (json['subsets'] as List?)
            ?.map((s) => s as String)
            .toList(growable: false) ??
        const ['latin'],
    defSubset: json['def_subset'] as String? ?? 'latin',
    variable: json['variable'] as bool? ?? false,
  );

  factory FontFamilyDto.fromEntity(FontFamilyInfo info) => FontFamilyDto(
    id: info.id,
    family: info.family,
    category: info.category,
    weights: info.weights,
    styles: info.styles,
    subsets: info.subsets,
    defSubset: info.defSubset,
    variable: info.variable,
  );

  final String id;
  final String family;
  final String category;
  final List<int> weights;
  final List<String> styles;
  final List<String> subsets;
  final String defSubset;
  final bool variable;

  Map<String, dynamic> toJson() => {
    'id': id,
    'family': family,
    'category': category,
    'weights': weights,
    'styles': styles,
    'subsets': subsets,
    'def_subset': defSubset,
    'variable': variable,
  };

  /// Rebuilds the domain entity. A payload with no weights/styles (a malformed
  /// or truncated catalogue row) is normalised to the regular upright variant
  /// rather than rejected, because the entity requires at least one of each.
  FontFamilyInfo toEntity() => FontFamilyInfo(
    id: id,
    family: family,
    category: category,
    weights: weights.isEmpty ? const [400] : weights,
    styles: styles.isEmpty ? const ['normal'] : styles,
    subsets: subsets.isEmpty ? const ['latin'] : subsets,
    defSubset: defSubset,
    variable: variable,
  );
}
