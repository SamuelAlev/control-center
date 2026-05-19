/// Wire DTOs for the Control Center RPC surface.
///
/// Each tool emits a JSON document (the `text` of its single `CallResult`
/// content piece). These DTOs are the **typed view** the `cc_remote` PWA uses
/// to parse those documents. They mirror the exact shapes the tools emit today
/// (the `cc_mcp` package, `packages/cc_mcp/lib/src/tools/*`); changing a tool's
/// output shape means changing the matching DTO here.
library;

import 'dart:convert';

import 'package:cc_domain/core/domain/value_objects/agent_role.dart' show AgentRole;

import 'package:cc_domain/features/ticketing/domain/entities/project.dart' show Project;

import 'package:cc_domain/features/ticketing/domain/entities/ticket_link.dart' show TicketLink;

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
    this.reviewConcurrency,
    this.deletedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory WorkspaceDto.fromJson(Map<String, dynamic> json) => WorkspaceDto(
    id: json['id'] as String,
    name: json['name'] as String,
    logoPath: json['logo_path'] as String?,
    reviewConcurrency: (json['review_concurrency'] as num?)?.toInt(),
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

  /// Default reviewer fan-out; null when the host omits it (older surfaces).
  final int? reviewConcurrency;

  /// Soft-delete timestamp; non-null when the workspace is deleted.
  final DateTime? deletedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    if (logoPath != null) 'logo_path': logoPath,
    if (reviewConcurrency != null) 'review_concurrency': reviewConcurrency,
    if (deletedAt != null) 'deleted_at': deletedAt!.toIso8601String(),
    if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
  };
}

/// Ticket wire DTO — the FULL shape needed to reconstruct a `Ticket` entity on
/// a thin client without losing any field.
///
/// The thin-client write path runs the domain `TicketWorkflowService` over the
/// RPC repository: it reads a ticket, applies a `copyWith`, and writes the
/// result back with `expectedVersion`. That read-modify-write is only safe if
/// the wire round-trip is LOSSLESS — every persisted field (the mirror, the
/// Control-Center overlay, the lifecycle timestamps, and `version`) must
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
    this.url,
    this.workspaceId,
    this.description,
    this.rawStatus,
    this.labels = const [],
    this.parentTicketId,
    this.projectId,
    this.assignedTeamId,
    this.delegatedByAgentId,
    this.channelId,
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
    url: json['url'] as String?,
    workspaceId: json['workspace_id'] as String?,
    description: json['description'] as String?,
    rawStatus: json['raw_status'] as String?,
    labels:
        (json['labels'] as List?)?.whereType<String>().toList() ?? const [],
    parentTicketId: json['parent_ticket_id'] as String?,
    projectId: json['project_id'] as String?,
    assignedTeamId: json['assigned_team_id'] as String?,
    delegatedByAgentId: json['delegated_by_agent_id'] as String?,
    channelId: json['channel_id'] as String?,
    errorMessage: json['error_message'] as String?,
    linkedPrIds:
        (json['linked_pr_ids'] as List?)?.whereType<String>().toList() ??
        const [],
    metadata:
        (json['metadata'] as Map?)?.cast<String, dynamic>() ?? const {},
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
  final String? channelId;
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
    'url': ?url,
    'workspace_id': ?workspaceId,
    'description': ?description,
    'raw_status': ?rawStatus,
    'labels': labels,
    'parent_ticket_id': ?parentTicketId,
    'project_id': ?projectId,
    'assigned_team_id': ?assignedTeamId,
    'delegated_by_agent_id': ?delegatedByAgentId,
    'channel_id': ?channelId,
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
    'created_at': ?createdAt,
  };
}

/// Repo wire DTO — a Git repository registration (global, not workspace-scoped;
/// the workspace link lives in WorkspaceRepos).
class RepoDto {
  RepoDto({
    required this.id,
    required this.name,
    required this.path,
    required this.githubOwner,
    required this.githubRepoName,
    this.createdAt,
    this.updatedAt,
  });

  factory RepoDto.fromJson(Map<String, dynamic> json) => RepoDto(
    id: json['id'] as String,
    name: json['name'] as String? ?? '',
    path: json['path'] as String? ?? '',
    githubOwner: json['github_owner'] as String? ?? '',
    githubRepoName: json['github_repo_name'] as String? ?? '',
    createdAt: json['created_at'] as String?,
    updatedAt: json['updated_at'] as String?,
  );

  final String id;
  final String name;
  final String path;
  final String githubOwner;
  final String githubRepoName;
  final String? createdAt;
  final String? updatedAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'path': path,
    'github_owner': githubOwner,
    'github_repo_name': githubRepoName,
    'created_at': ?createdAt,
    'updated_at': ?updatedAt,
  };
}

/// Channel wire DTO: `{id, name, is_dm, workspace_id, mode?, pipeline_run_id?,
/// created_at?, updated_at?}`.
class ChannelDto {
  ChannelDto({
    required this.id,
    required this.name,
    required this.isDm,
    required this.workspaceId,
    this.mode,
    this.pipelineRunId,
    this.createdAt,
    this.updatedAt,
  });

  factory ChannelDto.fromJson(Map<String, dynamic> json) => ChannelDto(
    id: json['id'] as String,
    name: json['name'] as String? ?? '',
    isDm: json['is_dm'] as bool? ?? false,
    workspaceId: json['workspace_id'] as String? ?? '',
    mode: json['mode'] as String?,
    pipelineRunId: json['pipeline_run_id'] as String?,
    createdAt: json['created_at'] is String
        ? DateTime.tryParse(json['created_at'] as String)
        : null,
    updatedAt: json['updated_at'] is String
        ? DateTime.tryParse(json['updated_at'] as String)
        : null,
  );

  final String id;
  final String name;
  final bool isDm;
  final String workspaceId;

  /// Conversation mode (`ConversationMode.toDbValue()` string); null ⇒ default.
  final String? mode;

  /// Owning pipeline run when spawned by a pipeline step (hidden from sidebar).
  final String? pipelineRunId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'is_dm': isDm,
    'workspace_id': workspaceId,
    if (mode != null) 'mode': mode,
    if (pipelineRunId != null) 'pipeline_run_id': pipelineRunId,
    if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
  };
}

/// Message wire DTO: `{id, content, sender_id, sender_type, message_type,
/// metadata, channel_id?, parent_message_id?, compacted?, created_at?}`.
class MessageDto {
  MessageDto({
    required this.id,
    required this.content,
    required this.senderId,
    required this.senderType,
    required this.messageType,
    this.metadata,
    this.channelId,
    this.parentMessageId,
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
    channelId: json['channel_id'] as String?,
    parentMessageId: json['parent_message_id'] as String?,
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

  /// Parent channel id; null on lossy/older surfaces (the UI scopes by channel).
  final String? channelId;

  /// Parent message id when this is a thread reply; null for top-level.
  final String? parentMessageId;

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
    if (channelId != null) 'channel_id': channelId,
    if (parentMessageId != null) 'parent_message_id': parentMessageId,
    if (compacted) 'compacted': compacted,
    if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
  };
}

/// Channel participant wire DTO: `{id, channel_id, agent_id, role, joined_at,
/// last_read_at?}`.
class ChannelParticipantDto {
  ChannelParticipantDto({
    required this.id,
    required this.channelId,
    required this.agentId,
    required this.role,
    this.joinedAt,
    this.lastReadAt,
  });

  factory ChannelParticipantDto.fromJson(Map<String, dynamic> json) =>
      ChannelParticipantDto(
        id: json['id'] as String,
        channelId: json['channel_id'] as String? ?? '',
        agentId: json['agent_id'] as String? ?? '',
        role: json['role'] as String? ?? '',
        joinedAt: json['joined_at'] is String
            ? DateTime.tryParse(json['joined_at'] as String)
            : null,
        lastReadAt: json['last_read_at'] is String
            ? DateTime.tryParse(json['last_read_at'] as String)
            : null,
      );

  final String id;
  final String channelId;
  final String agentId;
  final String role;
  final DateTime? joinedAt;
  final DateTime? lastReadAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'channel_id': channelId,
    'agent_id': agentId,
    'role': role,
    if (joinedAt != null) 'joined_at': joinedAt!.toIso8601String(),
    if (lastReadAt != null) 'last_read_at': lastReadAt!.toIso8601String(),
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

/// Channel read-cursor wire DTO — the user participant's `lastReadAt` for a
/// single channel. The cursor is keyed by `channel_id` (the channel is the
/// workspace-scoped entity); `last_read_at` is null when the channel has never
/// been opened under the user.
class ChannelReadDto {
  ChannelReadDto({required this.channelId, this.lastReadAt});

  factory ChannelReadDto.fromJson(Map<String, dynamic> json) => ChannelReadDto(
    channelId: json['channel_id'] as String? ?? '',
    lastReadAt: json['last_read_at'] as String?,
  );

  final String channelId;

  /// ISO-8601 read-cursor timestamp, or null when never set.
  final String? lastReadAt;

  Map<String, dynamic> toJson() => {
    'channel_id': channelId,
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

/// Review-channel-association wire DTO — the full shape needed to reconstruct a
/// `ReviewChannelAssociation` entity on a thin client. Enum `status` is encoded
/// as `.name`; timestamps are ISO-8601 strings.
class ReviewChannelAssociationDto {
  ReviewChannelAssociationDto({
    required this.id,
    required this.channelId,
    required this.workspaceId,
    required this.prNodeId,
    required this.prNumber,
    required this.repoFullName,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory ReviewChannelAssociationDto.fromJson(Map<String, dynamic> json) =>
      ReviewChannelAssociationDto(
        id: json['id'] as String,
        channelId: json['channel_id'] as String? ?? '',
        workspaceId: json['workspace_id'] as String? ?? '',
        prNodeId: json['pr_node_id'] as String? ?? '',
        prNumber: (json['pr_number'] as num?)?.toInt() ?? 0,
        repoFullName: json['repo_full_name'] as String? ?? '',
        status: json['status'] as String? ?? '',
        createdAt: json['created_at'] as String?,
        updatedAt: json['updated_at'] as String?,
      );

  final String id;
  final String channelId;
  final String workspaceId;
  final String prNodeId;
  final int prNumber;
  final String repoFullName;
  final String status;

  /// ISO-8601 timestamps, when the host includes them.
  final String? createdAt;
  final String? updatedAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'channel_id': channelId,
    'workspace_id': workspaceId,
    'pr_node_id': prNodeId,
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

/// Agent run log wire DTO — a single agent execution record. Mirrors
/// [agentRunLogToWire]/[agentRunLogFromWire] in the host catalog. Enum fields
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
    this.channelId,
    required this.startedAt,
    this.completedAt,
    required this.status,
    this.summary,
    this.adapter,
    this.pid,
    this.logPath,
    this.inputTokens = 0,
    this.outputTokens = 0,
    this.thoughtTokens = 0,
    this.cachedReadTokens = 0,
    this.cachedWriteTokens = 0,
    this.estimatedCostCents = 0,
    this.durationMs,
    this.timeToFirstTokenMs,
    this.liveness,
    this.errorFamily,
    this.lastOutputAt,
    this.continuationSummary,
    this.contextSnapshotJson,
    this.pipelineRunId,
    this.pipelineStepRunId,
    this.errorCode,
    this.expectedOutputSchema,
    this.outputContractMode = 'strict',
    this.outputJson,
    this.outputRejections = 0,
    this.retryOfRunId,
    this.retryAttempt = 0,
  });

  factory AgentRunLogDto.fromJson(Map<String, dynamic> json) => AgentRunLogDto(
    id: json['id'] as String,
    agentId: json['agent_id'] as String? ?? '',
    workspaceId: json['workspace_id'] as String?,
    conversationId: json['conversation_id'] as String?,
    ticketId: json['ticket_id'] as String?,
    channelId: json['channel_id'] as String?,
    startedAt: json['started_at'] as String? ?? '',
    completedAt: json['completed_at'] as String?,
    status: json['status'] as String? ?? 'pending',
    summary: json['summary'] as String?,
    adapter: json['adapter'] as String?,
    pid: (json['pid'] as num?)?.toInt(),
    logPath: json['log_path'] as String?,
    inputTokens: (json['input_tokens'] as num?)?.toInt() ?? 0,
    outputTokens: (json['output_tokens'] as num?)?.toInt() ?? 0,
    thoughtTokens: (json['thought_tokens'] as num?)?.toInt() ?? 0,
    cachedReadTokens: (json['cached_read_tokens'] as num?)?.toInt() ?? 0,
    cachedWriteTokens: (json['cached_write_tokens'] as num?)?.toInt() ?? 0,
    estimatedCostCents: (json['estimated_cost_cents'] as num?)?.toInt() ?? 0,
    durationMs: (json['duration_ms'] as num?)?.toInt(),
    timeToFirstTokenMs: (json['time_to_first_token_ms'] as num?)?.toInt(),
    liveness: json['liveness'] as String?,
    errorFamily: json['error_family'] as String?,
    lastOutputAt: json['last_output_at'] as String?,
    continuationSummary: json['continuation_summary'] as String?,
    contextSnapshotJson: json['context_snapshot_json'] as String?,
    pipelineRunId: json['pipeline_run_id'] as String?,
    pipelineStepRunId: json['pipeline_step_run_id'] as String?,
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
  );

  final String id;
  final String agentId;
  final String? workspaceId;
  final String? conversationId;
  final String? ticketId;
  final String? channelId;
  final String startedAt;
  final String? completedAt;
  final String status;
  final String? summary;
  final String? adapter;
  final int? pid;
  final String? logPath;
  final int inputTokens;
  final int outputTokens;
  final int thoughtTokens;
  final int cachedReadTokens;
  final int cachedWriteTokens;
  final int estimatedCostCents;
  final int? durationMs;
  final int? timeToFirstTokenMs;
  final String? liveness;
  final String? errorFamily;
  final String? lastOutputAt;
  final String? continuationSummary;
  final String? contextSnapshotJson;
  final String? pipelineRunId;
  final String? pipelineStepRunId;
  final String? errorCode;
  final Map<String, dynamic>? expectedOutputSchema;
  final String outputContractMode;
  final Map<String, dynamic>? outputJson;
  final int outputRejections;
  final String? retryOfRunId;
  final int retryAttempt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'agent_id': agentId,
    'workspace_id': ?workspaceId,
    'conversation_id': ?conversationId,
    'ticket_id': ?ticketId,
    'channel_id': ?channelId,
    'started_at': startedAt,
    'completed_at': ?completedAt,
    'status': status,
    'summary': ?summary,
    'adapter': ?adapter,
    'pid': ?pid,
    'log_path': ?logPath,
    'input_tokens': inputTokens,
    'output_tokens': outputTokens,
    'thought_tokens': thoughtTokens,
    'cached_read_tokens': cachedReadTokens,
    'cached_write_tokens': cachedWriteTokens,
    'estimated_cost_cents': estimatedCostCents,
    'duration_ms': ?durationMs,
    'time_to_first_token_ms': ?timeToFirstTokenMs,
    'liveness': ?liveness,
    'error_family': ?errorFamily,
    'last_output_at': ?lastOutputAt,
    'continuation_summary': ?continuationSummary,
    'context_snapshot_json': ?contextSnapshotJson,
    'pipeline_run_id': ?pipelineRunId,
    'pipeline_step_run_id': ?pipelineStepRunId,
    'error_code': ?errorCode,
    'expected_output_schema': ?expectedOutputSchema,
    'output_contract_mode': outputContractMode,
    'output_json': ?outputJson,
    'output_rejections': outputRejections,
    'retry_of_run_id': ?retryOfRunId,
    'retry_attempt': retryAttempt,
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
    required this.channelId,
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
        channelId: json['channel_id'] as String? ?? '',
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
  final String channelId;
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
    'channel_id': channelId,
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
    sourceObservationIds: ((json['source_observation_ids'] as List?) ?? const [])
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
    this.finishedAt,
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
    finishedAt: json['finished_at'] as String?,
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
  final String? finishedAt;
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
    if (finishedAt != null) 'finished_at': finishedAt,
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
    this.channelId,
    this.errorMessage,
    this.branchIndex,
    this.attemptCount = 0,
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
        channelId: json['channel_id'] as String?,
        errorMessage: json['error_message'] as String?,
        branchIndex: (json['branch_index'] as num?)?.toInt(),
        attemptCount: (json['attempt_count'] as num?)?.toInt() ?? 0,
        startedAt: json['started_at'] as String? ?? '',
        finishedAt: json['finished_at'] as String?,
      );

  final String id;
  final String pipelineRunId;
  final String stepId;
  final String status;
  final String? inputJson;
  final String? outputJson;
  final String? channelId;
  final String? errorMessage;
  final int? branchIndex;
  final int attemptCount;
  final String startedAt;
  final String? finishedAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'pipeline_run_id': pipelineRunId,
    'step_id': stepId,
    'status': status,
    if (inputJson != null) 'input_json': inputJson,
    if (outputJson != null) 'output_json': outputJson,
    if (channelId != null) 'channel_id': channelId,
    if (errorMessage != null) 'error_message': errorMessage,
    if (branchIndex != null) 'branch_index': branchIndex,
    'attempt_count': attemptCount,
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
    this.match = const {},
    this.lastFiredAt,
  });

  factory PipelineTriggerDto.fromJson(Map<String, dynamic> json) =>
      PipelineTriggerDto(
        id: json['id'] as String? ?? '',
        eventType: json['event_type'] as String? ?? '',
        templateId: json['template_id'] as String? ?? '',
        workspaceId: json['workspace_id'] as String? ?? '',
        enabled: json['enabled'] as bool? ?? false,
        cronExpression: json['cron_expression'] as String?,
        match: json['match'] is Map
            ? (json['match'] as Map).cast<String, dynamic>()
            : const {},
        lastFiredAt: json['last_fired_at'] as String?,
        createdAt: json['created_at'] as String? ?? '',
      );

  final String id;
  final String eventType;
  final String templateId;
  final String workspaceId;
  final bool enabled;

  /// Schedule expression for time-based triggers (`every:<seconds>`), or null.
  final String? cronExpression;

  /// Value filter applied to the event payload before firing. Empty means
  /// "fire on every matching event".
  final Map<String, dynamic> match;

  /// ISO-8601 timestamp of the last firing, or null until first fired.
  final String? lastFiredAt;

  /// ISO-8601 creation timestamp.
  final String createdAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'event_type': eventType,
    'template_id': templateId,
    'workspace_id': workspaceId,
    'enabled': enabled,
    if (cronExpression != null) 'cron_expression': cronExpression,
    'match': match,
    if (lastFiredAt != null) 'last_fired_at': lastFiredAt,
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
    required this.createdAt,
  });

  factory TeamDto.fromJson(Map<String, dynamic> json) => TeamDto(
    id: json['id'] as String,
    workspaceId: json['workspace_id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    description: json['description'] as String?,
    createdAt: json['created_at'] as String? ?? '',
  );

  final String id;
  final String workspaceId;
  final String name;
  final String? description;
  final String createdAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'workspace_id': workspaceId,
    'name': name,
    if (description != null) 'description': description,
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
    this.channelId,
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
        channelId: json['channel_id'] as String?,
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
  final String? channelId;
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
    if (channelId != null) 'channel_id': channelId,
    if (orchestratorAgentId != null) 'orchestrator_agent_id': orchestratorAgentId,
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
// viewer, reviewer rail, comment threads, and check runs without a database.

/// PrUser wire DTO — a GitHub login + avatar (the minimal user shape the PR
/// surface needs).
class PrUserDto {
  PrUserDto({required this.login, required this.avatarUrl});

  factory PrUserDto.fromJson(Map<String, dynamic> json) => PrUserDto(
    login: json['login'] as String? ?? '',
    avatarUrl: json['avatar_url'] as String? ?? '',
  );

  final String login;
  final String avatarUrl;

  Map<String, dynamic> toJson() => {'login': login, 'avatar_url': avatarUrl};
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
/// `mergeable_state`) travel as their stored strings; timestamps are ISO-8601;
/// nested users + reactions use their own DTOs.
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
    this.nodeId = '',
    this.headSha = '',
    this.baseRef = '',
    this.baseSha = '',
    this.headRef = '',
    this.requestedReviewers = const [],
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
    nodeId: json['node_id'] as String? ?? '',
    headSha: json['head_sha'] as String? ?? '',
    baseRef: json['base_ref'] as String? ?? '',
    baseSha: json['base_sha'] as String? ?? '',
    headRef: json['head_ref'] as String? ?? '',
    requestedReviewers: ((json['requested_reviewers'] as List?) ?? const [])
        .whereType<Map>()
        .map((u) => PrUserDto.fromJson(u.cast<String, dynamic>()))
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
  final String nodeId;
  final String headSha;
  final String baseRef;
  final String baseSha;
  final String headRef;
  final List<PrUserDto> requestedReviewers;
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
    'node_id': nodeId,
    'head_sha': headSha,
    'base_ref': baseRef,
    'base_sha': baseSha,
    'head_ref': headRef,
    'requested_reviewers':
        requestedReviewers.map((u) => u.toJson()).toList(),
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
  PrReviewSubmissionDto({required this.state, this.author, this.body = ''});

  factory PrReviewSubmissionDto.fromJson(Map<String, dynamic> json) =>
      PrReviewSubmissionDto(
        state: json['state'] as String? ?? 'commented',
        author: json['author'] is Map
            ? PrUserDto.fromJson(
                (json['author'] as Map).cast<String, dynamic>(),
              )
            : null,
        body: json['body'] as String? ?? '',
      );

  final String state;
  final PrUserDto? author;
  final String body;

  Map<String, dynamic> toJson() => {
    'state': state,
    'author': ?author?.toJson(),
    'body': body,
  };
}

/// PrCodeReviewComment wire DTO — an inline review comment anchored to a diff
/// line. Carries the reply chain, anchor lines, diff hunk, and reactions.
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
    this.startLine,
    this.diffHunk = '',
    this.line,
    this.originalLine,
    this.reactions = const [],
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
        startLine: (json['start_line'] as num?)?.toInt(),
        diffHunk: json['diff_hunk'] as String? ?? '',
        line: (json['line'] as num?)?.toInt(),
        originalLine: (json['original_line'] as num?)?.toInt(),
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
  final int? startLine;
  final String diffHunk;
  final int? line;
  final int? originalLine;
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
    'start_line': ?startLine,
    'diff_hunk': diffHunk,
    'line': ?line,
    'original_line': ?originalLine,
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

  factory IssueCommentDto.fromJson(Map<String, dynamic> json) => IssueCommentDto(
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
    this.completedAt,
    this.output = '',
    this.workflowName,
    this.checkSuiteId,
  });

  factory CheckRunDto.fromJson(Map<String, dynamic> json) => CheckRunDto(
    name: json['name'] as String? ?? '',
    status: json['status'] as String? ?? 'queued',
    conclusion: json['conclusion'] as String?,
    htmlUrl: json['html_url'] as String? ?? '',
    completedAt: json['completed_at'] as String?,
    output: json['output'] as String? ?? '',
    workflowName: json['workflow_name'] as String?,
    checkSuiteId: (json['check_suite_id'] as num?)?.toInt(),
  );

  final String name;
  final String status;
  final String? conclusion;
  final String htmlUrl;
  final String? completedAt;
  final String output;
  final String? workflowName;
  final int? checkSuiteId;

  Map<String, dynamic> toJson() => {
    'name': name,
    'status': status,
    'conclusion': ?conclusion,
    'html_url': htmlUrl,
    'completed_at': ?completedAt,
    'output': output,
    'workflow_name': ?workflowName,
    'check_suite_id': ?checkSuiteId,
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

  /// The member who reviewed on the team's behalf (`kind == 'team'`), if any.
  final PrUserDto? reviewedBy;

  Map<String, dynamic> toJson() => {
    'kind': kind,
    'is_code_owner': isCodeOwner,
    'state': state,
    'user': ?user?.toJson(),
    if (kind == 'team') 'name': name,
    if (kind == 'team') 'slug': slug,
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

  Map<String, dynamic> toJson() => {
    'title': title,
    'short_sha': shortSha,
  };
}

// ---- Analytics / achievements / streaks ----
//
// The analytics cluster (`AgentDailyStats`, `Achievement`, `Streak`,
// `AgentScorecard`, `LeaderboardEntry`, `WorkspaceHealth`) is workspace-scoped
// at the repository (every read JOINs Agents on the bound workspace). These
// DTOs are the typed wire view the thin client parses back; the host injects
// the authoritative workspace per session, so no `workspace_id` travels on the
// wire. The UI only READS this surface, so these are read-shaped DTOs. Enum-free
// entities → plain scalars; timestamps are ISO-8601 strings.

/// AgentDailyStats wire DTO — one day's performance counters for a single agent.
class AgentDailyStatsDto {
  AgentDailyStatsDto({
    required this.id,
    required this.agentId,
    required this.date,
    this.runsCompleted = 0,
    this.runsErrored = 0,
    this.totalRunDurationMs = 0,
    this.prsCreated = 0,
    this.prsMerged = 0,
    this.reviewsCompleted = 0,
    this.blockingComments = 0,
    this.linesAdded = 0,
    this.linesDeleted = 0,
    this.xpEarned = 0,
    this.createdAt,
  });

  factory AgentDailyStatsDto.fromJson(Map<String, dynamic> json) =>
      AgentDailyStatsDto(
        id: json['id'] as String,
        agentId: json['agent_id'] as String? ?? '',
        date: json['date'] as String? ?? '',
        runsCompleted: (json['runs_completed'] as num?)?.toInt() ?? 0,
        runsErrored: (json['runs_errored'] as num?)?.toInt() ?? 0,
        totalRunDurationMs: (json['total_run_duration_ms'] as num?)?.toInt() ?? 0,
        prsCreated: (json['prs_created'] as num?)?.toInt() ?? 0,
        prsMerged: (json['prs_merged'] as num?)?.toInt() ?? 0,
        reviewsCompleted: (json['reviews_completed'] as num?)?.toInt() ?? 0,
        blockingComments: (json['blocking_comments'] as num?)?.toInt() ?? 0,
        linesAdded: (json['lines_added'] as num?)?.toInt() ?? 0,
        linesDeleted: (json['lines_deleted'] as num?)?.toInt() ?? 0,
        xpEarned: (json['xp_earned'] as num?)?.toInt() ?? 0,
        createdAt: json['created_at'] as String?,
      );

  final String id;
  final String agentId;

  /// ISO-8601 date the stats cover.
  final String date;
  final int runsCompleted;
  final int runsErrored;
  final int totalRunDurationMs;
  final int prsCreated;
  final int prsMerged;
  final int reviewsCompleted;
  final int blockingComments;
  final int linesAdded;
  final int linesDeleted;
  final int xpEarned;

  /// ISO-8601 creation timestamp, when the host includes it.
  final String? createdAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'agent_id': agentId,
    'date': date,
    'runs_completed': runsCompleted,
    'runs_errored': runsErrored,
    'total_run_duration_ms': totalRunDurationMs,
    'prs_created': prsCreated,
    'prs_merged': prsMerged,
    'reviews_completed': reviewsCompleted,
    'blocking_comments': blockingComments,
    'lines_added': linesAdded,
    'lines_deleted': linesDeleted,
    'xp_earned': xpEarned,
    'created_at': ?createdAt,
  };
}

/// Achievement wire DTO — a badge unlocked by an agent.
class AchievementDto {
  AchievementDto({
    required this.id,
    required this.agentId,
    required this.badgeKey,
    required this.unlockedAt,
    this.metadata,
  });

  factory AchievementDto.fromJson(Map<String, dynamic> json) => AchievementDto(
    id: json['id'] as String,
    agentId: json['agent_id'] as String? ?? '',
    badgeKey: json['badge_key'] as String? ?? '',
    unlockedAt: json['unlocked_at'] as String? ?? '',
    metadata: json['metadata'] as String?,
  );

  final String id;
  final String agentId;
  final String badgeKey;

  /// ISO-8601 unlock timestamp.
  final String unlockedAt;
  final String? metadata;

  Map<String, dynamic> toJson() => {
    'id': id,
    'agent_id': agentId,
    'badge_key': badgeKey,
    'unlocked_at': unlockedAt,
    'metadata': ?metadata,
  };
}

/// Streak wire DTO — consecutive-activity counter for an agent.
class StreakDto {
  StreakDto({
    required this.id,
    required this.agentId,
    required this.streakType,
    this.currentCount = 0,
    this.bestCount = 0,
    this.lastDate,
    required this.updatedAt,
  });

  factory StreakDto.fromJson(Map<String, dynamic> json) => StreakDto(
    id: json['id'] as String,
    agentId: json['agent_id'] as String? ?? '',
    streakType: json['streak_type'] as String? ?? '',
    currentCount: (json['current_count'] as num?)?.toInt() ?? 0,
    bestCount: (json['best_count'] as num?)?.toInt() ?? 0,
    lastDate: json['last_date'] as String?,
    updatedAt: json['updated_at'] as String? ?? '',
  );

  final String id;
  final String agentId;
  final String streakType;
  final int currentCount;
  final int bestCount;

  /// ISO-8601 date of the most recent activity that extended the streak, or null.
  final String? lastDate;

  /// ISO-8601 last-updated timestamp.
  final String updatedAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'agent_id': agentId,
    'streak_type': streakType,
    'current_count': currentCount,
    'best_count': bestCount,
    'last_date': ?lastDate,
    'updated_at': updatedAt,
  };
}

/// AgentScorecard wire DTO — an agent's aggregated lifetime scorecard. Nests the
/// agent's active [StreakDto]s and unlocked [AchievementDto]s.
class AgentScorecardDto {
  AgentScorecardDto({
    required this.agentId,
    required this.agentName,
    this.totalRuns = 0,
    this.totalErrored = 0,
    this.successRate = 0,
    this.avgRunDurationMs = 0,
    this.totalPrsCreated = 0,
    this.totalPrsMerged = 0,
    this.totalReviews = 0,
    this.totalBlockingComments = 0,
    this.totalXp = 0,
    this.level = 0,
    this.levelProgress = 0,
    this.currentStreaks = const [],
    this.achievements = const [],
  });

  factory AgentScorecardDto.fromJson(Map<String, dynamic> json) =>
      AgentScorecardDto(
        agentId: json['agent_id'] as String? ?? '',
        agentName: json['agent_name'] as String? ?? '',
        totalRuns: (json['total_runs'] as num?)?.toInt() ?? 0,
        totalErrored: (json['total_errored'] as num?)?.toInt() ?? 0,
        successRate: (json['success_rate'] as num?)?.toDouble() ?? 0,
        avgRunDurationMs: (json['avg_run_duration_ms'] as num?)?.toInt() ?? 0,
        totalPrsCreated: (json['total_prs_created'] as num?)?.toInt() ?? 0,
        totalPrsMerged: (json['total_prs_merged'] as num?)?.toInt() ?? 0,
        totalReviews: (json['total_reviews'] as num?)?.toInt() ?? 0,
        totalBlockingComments:
            (json['total_blocking_comments'] as num?)?.toInt() ?? 0,
        totalXp: (json['total_xp'] as num?)?.toInt() ?? 0,
        level: (json['level'] as num?)?.toInt() ?? 0,
        levelProgress: (json['level_progress'] as num?)?.toDouble() ?? 0,
        currentStreaks: ((json['current_streaks'] as List?) ?? const [])
            .whereType<Map>()
            .map((s) => StreakDto.fromJson(s.cast<String, dynamic>()))
            .toList(),
        achievements: ((json['achievements'] as List?) ?? const [])
            .whereType<Map>()
            .map((a) => AchievementDto.fromJson(a.cast<String, dynamic>()))
            .toList(),
      );

  final String agentId;
  final String agentName;
  final int totalRuns;
  final int totalErrored;
  final double successRate;
  final int avgRunDurationMs;
  final int totalPrsCreated;
  final int totalPrsMerged;
  final int totalReviews;
  final int totalBlockingComments;
  final int totalXp;
  final int level;
  final double levelProgress;
  final List<StreakDto> currentStreaks;
  final List<AchievementDto> achievements;

  Map<String, dynamic> toJson() => {
    'agent_id': agentId,
    'agent_name': agentName,
    'total_runs': totalRuns,
    'total_errored': totalErrored,
    'success_rate': successRate,
    'avg_run_duration_ms': avgRunDurationMs,
    'total_prs_created': totalPrsCreated,
    'total_prs_merged': totalPrsMerged,
    'total_reviews': totalReviews,
    'total_blocking_comments': totalBlockingComments,
    'total_xp': totalXp,
    'level': level,
    'level_progress': levelProgress,
    'current_streaks': currentStreaks.map((s) => s.toJson()).toList(),
    'achievements': achievements.map((a) => a.toJson()).toList(),
  };
}

/// LeaderboardEntry wire DTO — one ranked agent in the workspace leaderboard.
class LeaderboardEntryDto {
  LeaderboardEntryDto({
    required this.agentId,
    required this.agentName,
    this.score = 0,
    this.rank = 0,
  });

  factory LeaderboardEntryDto.fromJson(Map<String, dynamic> json) =>
      LeaderboardEntryDto(
        agentId: json['agent_id'] as String? ?? '',
        agentName: json['agent_name'] as String? ?? '',
        score: (json['score'] as num?)?.toInt() ?? 0,
        rank: (json['rank'] as num?)?.toInt() ?? 0,
      );

  final String agentId;
  final String agentName;
  final int score;
  final int rank;

  Map<String, dynamic> toJson() => {
    'agent_id': agentId,
    'agent_name': agentName,
    'score': score,
    'rank': rank,
  };
}

/// WorkspaceHealth wire DTO — aggregated health metrics for a workspace. Carries
/// the workspace id/name (unlike the per-agent DTOs) because the cross-org
/// dashboard view lists several at once.
class WorkspaceHealthDto {
  WorkspaceHealthDto({
    required this.workspaceId,
    required this.workspaceName,
    this.score = 0,
    this.activityScore = 0,
    this.throughputScore = 0,
    this.reviewHealthScore = 0,
    this.successRateScore = 0,
    this.activeAgents = 0,
    this.totalAgents = 0,
    this.prsMergedThisWeek = 0,
    this.openPRs = 0,
    this.stalePRs = 0,
    this.totalRuns = 0,
    this.erroredRuns = 0,
  });

  factory WorkspaceHealthDto.fromJson(Map<String, dynamic> json) =>
      WorkspaceHealthDto(
        workspaceId: json['workspace_id'] as String? ?? '',
        workspaceName: json['workspace_name'] as String? ?? '',
        score: (json['score'] as num?)?.toDouble() ?? 0,
        activityScore: (json['activity_score'] as num?)?.toDouble() ?? 0,
        throughputScore: (json['throughput_score'] as num?)?.toDouble() ?? 0,
        reviewHealthScore: (json['review_health_score'] as num?)?.toDouble() ?? 0,
        successRateScore: (json['success_rate_score'] as num?)?.toDouble() ?? 0,
        activeAgents: (json['active_agents'] as num?)?.toInt() ?? 0,
        totalAgents: (json['total_agents'] as num?)?.toInt() ?? 0,
        prsMergedThisWeek: (json['prs_merged_this_week'] as num?)?.toInt() ?? 0,
        openPRs: (json['open_prs'] as num?)?.toInt() ?? 0,
        stalePRs: (json['stale_prs'] as num?)?.toInt() ?? 0,
        totalRuns: (json['total_runs'] as num?)?.toInt() ?? 0,
        erroredRuns: (json['errored_runs'] as num?)?.toInt() ?? 0,
      );

  final String workspaceId;
  final String workspaceName;
  final double score;
  final double activityScore;
  final double throughputScore;
  final double reviewHealthScore;
  final double successRateScore;
  final int activeAgents;
  final int totalAgents;
  final int prsMergedThisWeek;
  final int openPRs;
  final int stalePRs;
  final int totalRuns;
  final int erroredRuns;

  Map<String, dynamic> toJson() => {
    'workspace_id': workspaceId,
    'workspace_name': workspaceName,
    'score': score,
    'activity_score': activityScore,
    'throughput_score': throughputScore,
    'review_health_score': reviewHealthScore,
    'success_rate_score': successRateScore,
    'active_agents': activeAgents,
    'total_agents': totalAgents,
    'prs_merged_this_week': prsMergedThisWeek,
    'open_prs': openPRs,
    'stale_prs': stalePRs,
    'total_runs': totalRuns,
    'errored_runs': erroredRuns,
  };
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

  /// ISO-8601 start time.
  final String startTime;

  /// ISO-8601 end time.
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
