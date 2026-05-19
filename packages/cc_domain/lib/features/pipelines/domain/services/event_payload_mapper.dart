import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/meeting_events.dart';
import 'package:cc_domain/core/domain/events/messaging_events.dart';
import 'package:cc_domain/core/domain/events/observability_events.dart';
import 'package:cc_domain/core/domain/events/pr_events.dart';
import 'package:cc_domain/core/domain/events/repo_events.dart';
import 'package:cc_domain/core/domain/events/skill_events.dart';
import 'package:cc_domain/core/domain/events/ticketing_events.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_context.dart'
    show PipelineContext;
import 'package:cc_domain/features/pipelines/domain/services/pipeline_trigger_dispatcher.dart'
    show PipelineTriggerDispatcher;

/// The last non-empty segment of a filesystem [path], for either separator.
/// Empty when the path is empty or all separators.
String _lastPathSegment(String path) {
  final segments = path
      .split(RegExp(r'[/\\]'))
      .where((s) => s.trim().isNotEmpty)
      .toList();
  return segments.isEmpty ? '' : segments.last;
}

/// Maps domain events to flat [Map<String, dynamic>] payloads that pipeline
/// step bodies can read via [PipelineContext.triggerPayload].
///
/// Compile-time curated — no reflection. Add new event types here as
/// new pipeline templates are introduced.
class EventPayloadMapper {
  EventPayloadMapper._();

  /// Converts a [DomainEvent] to a trigger payload map.
  /// Returns null if the event type is not mapped.
  static Map<String, dynamic>? toPayload(DomainEvent event) {
    if (event is ExternalPrDetected) {
      return {
        'repo_owner': event.repoOwner,
        'repo_name': event.repoName,
        'pr_number': event.prNumber,
        'pr_title': event.prTitle,
        'author': event.author,
      };
    }
    if (event is PullRequestPublished) {
      return {
        'pr_id': event.prId,
        'workspace_id': event.workspaceId,
        'repo_owner': event.repoOwner,
        'repo_name': event.repoName,
      };
    }
    if (event is PrMerged) {
      return {
        'pr_id': event.prId,
        'workspace_id': event.workspaceId,
        'agent_id': event.agentId,
      };
    }
    if (event is PullRequestStatusChanged) {
      return {
        'status': event.status,
        if (event.prId != null) 'pr_id': event.prId,
        'workspace_id': event.workspaceId,
        if (event.repoFullName != null) 'repo_full_name': event.repoFullName,
        if (event.prNumber != null) 'pr_number': event.prNumber,
      };
    }
    if (event is MessageReceived) {
      return {
        'space_id': event.spaceId,
        'message_id': event.messageId,
        'sender_name': event.senderName,
        'content_preview': event.contentPreview,
        'is_agent_message': event.isAgentMessage,
      };
    }
    if (event is TicketCompleted) {
      return {'ticket_id': event.ticketId};
    }
    if (event is TicketFailed) {
      return {'ticket_id': event.ticketId, 'error_message': event.errorMessage};
    }
    if (event is TicketCancelled) {
      return {'ticket_id': event.ticketId};
    }
    if (event is BudgetThresholdCrossed) {
      return {
        'scope_type': event.scopeType,
        'scope_id': event.scopeId,
        'spent_cents': event.spentCents,
        'budget_cents': event.budgetCents,
        'is_hard_stop': event.isHardStop,
      };
    }
    if (event is TicketAssigned) {
      return {
        'ticket_id': event.ticketId,
        'ticket_title': event.ticketTitle,
        if (event.ticketBody != null) 'ticket_body': event.ticketBody,
        if (event.ticketUrl != null) 'ticket_url': event.ticketUrl,
        'workspace_id': event.workspaceId,
      };
    }
    if (event is RepoAdded) {
      return {
        'repo_id': event.repoId,
        'repo_local_path': event.path,
        // The checkout's folder name. The event carries no repo name and the
        // forge one may not exist (a local-only checkout), but `index_code`
        // names its conversation after the repo — and the same room name three
        // times over says nothing about which repo is being read.
        'repo_name': _lastPathSegment(event.path),
        'workspace_id': event.workspaceId,
      };
    }
    if (event is MeetingRecordingStopped) {
      return {
        'workspace_id': event.workspaceId,
        'meeting_id': event.meetingId,
        'title': event.title,
        'user_notes': event.userNotes,
        'transcript': event.transcript,
        'summary_instructions': event.summaryInstructions ?? '',
      };
    }
    if (event is SkillUpdated) {
      return {
        'workspace_id': event.workspaceId,
        'slug': event.slug,
        'origin': event.origin,
        'computed_hash': event.computedHash,
        if (event.scanVerdict != null) 'scan_verdict': event.scanVerdict!.wire,
      };
    }
    // The built-in worktree-cleanup pipeline triggers on this and reads
    // `spaceId` to reclaim exactly that space's trees; without the branch it
    // saw an empty payload and fell through to a whole-workspace sweep.
    if (event is SpaceDeleted) {
      return {'workspace_id': event.workspaceId, 'space_id': event.spaceId};
    }
    return null;
  }

  /// Returns the fully-qualified type name for a [DomainEvent].
  /// Used for trigger matching.
  static String typeName(DomainEvent event) => event.runtimeType.toString();

  /// All event types that can trigger pipelines.
  /// Used by the automation settings screen to offer choices.
  static const List<String> knownEventTypes = [
    'ExternalPrDetected',
    'PullRequestPublished',
    'PullRequestStatusChanged',
    'PrMerged',
    'MessageReceived',
    'TicketCreated',
    'TicketCompleted',
    'TicketFailed',
    'TicketCancelled',
    'TicketStatusChanged',
    'BudgetThresholdCrossed',
    'TicketAssigned',
    'RepoAdded',
    'MeetingRecordingStopped',
    'SkillUpdated',
    'SpaceDeleted',
  ];

  /// Idempotency key for [event], or null if the event has no natural key.
  ///
  /// Used by [PipelineTriggerDispatcher] to skip duplicate runs when the
  /// same event fires multiple times (e.g. PR polling tick).
  static String? dedupKeyFor(DomainEvent event) {
    if (event is ExternalPrDetected) {
      return '${event.repoOwner}/${event.repoName}#${event.prNumber}';
    }
    if (event is PullRequestPublished) {
      return event.prId;
    }
    if (event is PrMerged) {
      return event.prId;
    }
    if (event is PullRequestStatusChanged) {
      final key =
          event.prId ??
          (event.repoFullName != null && event.prNumber != null
              ? '${event.repoFullName}#${event.prNumber}'
              : null);
      return key == null ? null : '$key:${event.status}';
    }
    if (event is MessageReceived) {
      return event.messageId;
    }
    if (event is TicketCompleted) {
      return event.ticketId;
    }
    if (event is TicketFailed) {
      return event.ticketId;
    }
    if (event is TicketCancelled) {
      return event.ticketId;
    }
    if (event is BudgetThresholdCrossed) {
      return '${event.scopeType}/${event.scopeId}';
    }
    if (event is TicketAssigned) {
      return event.ticketId;
    }
    if (event is RepoAdded) {
      // Scoped per workspace: the same repo added to two workspaces (distinct
      // worktrees) must each trigger its own index — they own separate graphs.
      return '${event.workspaceId}:${event.repoId}';
    }
    if (event is MeetingRecordingStopped) {
      // One active summary run per meeting; a re-run is allowed once the
      // previous run is terminal.
      return event.meetingId;
    }
    if (event is SkillUpdated) {
      // Content-addressed per skill: re-writing identical bytes (e.g. a
      // no-op re-save) doesn't deserve a second analysis run.
      return '${event.workspaceId}:${event.slug}:${event.computedHash}';
    }
    return null;
  }
}
