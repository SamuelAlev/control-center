import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/meeting_events.dart';
import 'package:cc_domain/core/domain/events/messaging_events.dart';
import 'package:cc_domain/core/domain/events/observability_events.dart';
import 'package:cc_domain/core/domain/events/pr_events.dart';
import 'package:cc_domain/core/domain/events/repo_events.dart';
import 'package:cc_domain/core/domain/events/ticketing_events.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_context.dart' show PipelineContext;
import 'package:cc_domain/features/pipelines/domain/services/pipeline_trigger_dispatcher.dart' show PipelineTriggerDispatcher;

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
        'repoOwner': event.repoOwner,
        'repoName': event.repoName,
        'prNumber': event.prNumber,
        'prTitle': event.prTitle,
        'author': event.author,
      };
    }
    if (event is PullRequestPublished) {
      return {
        'prId': event.prId,
        'workspaceId': event.workspaceId,
        'repoOwner': event.repoOwner,
        'repoName': event.repoName,
      };
    }
    if (event is PrMerged) {
      return {
        'prId': event.prId,
        'workspaceId': event.workspaceId,
        'agentId': event.agentId,
      };
    }
    if (event is PullRequestStatusChanged) {
      return {
        'status': event.status,
        if (event.prId != null) 'prId': event.prId,
        if (event.workspaceId != null) 'workspaceId': event.workspaceId,
        if (event.repoFullName != null) 'repoFullName': event.repoFullName,
        if (event.prNumber != null) 'prNumber': event.prNumber,
      };
    }
    if (event is MessageReceived) {
      return {
        'channelId': event.channelId,
        'messageId': event.messageId,
        'senderName': event.senderName,
        'contentPreview': event.contentPreview,
        'isAgentMessage': event.isAgentMessage,
      };
    }
    if (event is TicketCompleted) {
      return {
        'ticketId': event.ticketId,
      };
    }
    if (event is TicketFailed) {
      return {
        'ticketId': event.ticketId,
        'errorMessage': event.errorMessage,
      };
    }
    if (event is TicketCancelled) {
      return {
        'ticketId': event.ticketId,
      };
    }
    if (event is BudgetThresholdCrossed) {
      return {
        'scopeType': event.scopeType,
        'scopeId': event.scopeId,
        'spentCents': event.spentCents,
        'budgetCents': event.budgetCents,
        'isHardStop': event.isHardStop,
      };
    }
    if (event is TicketAssigned) {
      return {
        'ticketId': event.ticketId,
        'ticketTitle': event.ticketTitle,
        if (event.ticketBody != null) 'ticketBody': event.ticketBody,
        if (event.ticketUrl != null) 'ticketUrl': event.ticketUrl,
        if (event.workspaceId != null) 'workspaceId': event.workspaceId,
      };
    }
    if (event is RepoAdded) {
      return {
        'repoId': event.repoId,
        'repoLocalPath': event.path,
        'workspaceId': event.workspaceId,
      };
    }
    if (event is MeetingRecordingStopped) {
      return {
        'workspaceId': event.workspaceId,
        'meetingId': event.meetingId,
        'title': event.title,
        'userNotes': event.userNotes,
        'transcript': event.transcript,
        'summaryInstructions': event.summaryInstructions ?? '',
      };
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
      final key = event.prId ??
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
    return null;
  }
}
