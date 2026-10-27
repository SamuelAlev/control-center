// ignore_for_file: avoid_classes_with_only_static_members — the tracking plan reads best as one namespace.

import 'package:cc_domain/features/telemetry/domain/entities/analytics_event.dart';
import 'package:cc_domain/features/telemetry/domain/value_objects/analytics_id.dart';

/// The tracking plan: every event Control Center records, in one place.
///
/// Call sites build events only through these factories, so names, property
/// keys and value shapes are reviewed here rather than scattered through the
/// UI. Conventions:
///
/// - names are `<object>_<past-tense verb>` in snake_case;
/// - IDs go in `*_id` properties wrapped in [AnalyticsId] (pseudonymized
///   before sending);
/// - strings are closed vocabularies (enum wire values, command IDs, model
///   IDs), never user-authored text;
/// - quantities are raw numbers (`*_count`, `*_ms`, `*_s`, `*_tokens`) so
///   they can be summed and averaged.
///
/// Every event also carries the context properties (`app_type`,
/// `app_version`, `platform`, `server_mode`, `install_id`, `user_id`,
/// `device_id`, `launch_id`, `event_seq`, …). Adding an event means adding a
/// factory here and a row to the manual's telemetry reference.
abstract final class AnalyticsEvents {
  // ---------------------------------------------------------------- lifecycle

  /// The app finished booting and is connected to a server.
  static AnalyticsEvent appOpened({required int startupMs}) =>
      AnalyticsEvent('app_opened', {'startup_ms': startupMs});

  /// The app returned to the foreground after [backgroundS] seconds away.
  static AnalyticsEvent appForegrounded({required int backgroundS}) =>
      AnalyticsEvent('app_foregrounded', {'background_s': backgroundS});

  /// The app went to the background after [foregroundS] seconds in front.
  static AnalyticsEvent appBackgrounded({required int foregroundS}) =>
      AnalyticsEvent('app_backgrounded', {'foreground_s': foregroundS});

  // --------------------------------------------------------------- connection

  /// A session with the server was established ([reconnect] after a drop).
  static AnalyticsEvent serverConnected({required bool reconnect}) =>
      AnalyticsEvent('server_connected', {'reconnect': reconnect});

  /// The connection to the server dropped.
  static AnalyticsEvent serverDisconnected() =>
      AnalyticsEvent('server_disconnected');

  /// The user switched this client to another server.
  static AnalyticsEvent serverSwitched() => AnalyticsEvent('server_switched');

  /// The phone finished pairing with a server.
  static AnalyticsEvent devicePaired() => AnalyticsEvent('device_paired');

  // --------------------------------------------------------------- onboarding

  /// An onboarding step was shown ([step] is the step's stable ID).
  static AnalyticsEvent onboardingStepViewed({
    required String step,
    required int stepIndex,
  }) => AnalyticsEvent('onboarding_step_viewed', {
    'step': step,
    'step_index': stepIndex,
  });

  /// Onboarding finished after [durationS] seconds.
  static AnalyticsEvent onboardingCompleted({
    required int durationS,
    required int stepCount,
    String? workspaceId,
  }) => AnalyticsEvent('onboarding_completed', {
    'duration_s': durationS,
    'step_count': stepCount,
    'workspace_id': AnalyticsId.maybe(workspaceId),
  });

  // ---------------------------------------------------------------- workspace

  /// The user opened a different workspace.
  static AnalyticsEvent workspaceSwitched({
    required String workspaceId,
    String? previousWorkspaceId,
  }) => AnalyticsEvent('workspace_switched', {
    'workspace_id': AnalyticsId(workspaceId),
    'previous_workspace_id': AnalyticsId.maybe(previousWorkspaceId),
  });

  // ---------------------------------------------------------------- messaging

  /// How a composer submission left the client.
  static const messageDeliverySend = 'send';

  /// Queued as steering for a run in progress.
  static const messageDeliverySteer = 'steer';

  /// Parked until the space finishes provisioning.
  static const messageDeliveryQueued = 'queued';

  /// The user sent a message from a composer.
  ///
  /// [delivery] is one of [messageDeliverySend], [messageDeliverySteer],
  /// [messageDeliveryQueued].
  static AnalyticsEvent messageSent({
    required String workspaceId,
    required String spaceId,
    required String delivery,
    required int charCount,
    required int attachmentCount,
    required int agentMentionCount,
    required int otherMentionCount,
    String? conversationId,
    String? slashCommand,
  }) => AnalyticsEvent('message_sent', {
    'workspace_id': AnalyticsId(workspaceId),
    'space_id': AnalyticsId(spaceId),
    'conversation_id': AnalyticsId.maybe(conversationId),
    'delivery': delivery,
    'char_count': charCount,
    'attachment_count': attachmentCount,
    'agent_mention_count': agentMentionCount,
    'other_mention_count': otherMentionCount,
    'slash_command': slashCommand,
  });

  /// The user ran a client-side slash command (`/clear`, `/help`, …).
  static AnalyticsEvent slashCommandRun({
    required String command,
    String? workspaceId,
    String? spaceId,
  }) => AnalyticsEvent('slash_command_run', {
    'command': command,
    'workspace_id': AnalyticsId.maybe(workspaceId),
    'space_id': AnalyticsId.maybe(spaceId),
  });

  // ---------------------------------------------------------------- approvals

  /// The user answered an agent's approval request.
  static AnalyticsEvent approvalDecided({
    required bool approved,
    required bool remembered,
    required String surface,
    required List<String> actionClasses,
    String? workspaceId,
    String? spaceId,
    String? conversationId,
    String? severity,
  }) => AnalyticsEvent('approval_decided', {
    'decision': approved ? 'approved' : 'denied',
    'remembered': remembered,
    'surface': surface,
    'action_classes': actionClasses.isEmpty
        ? null
        : (actionClasses.toList()..sort()).join('+'),
    'action_class_count': actionClasses.length,
    'severity': severity,
    'workspace_id': AnalyticsId.maybe(workspaceId),
    'space_id': AnalyticsId.maybe(spaceId),
    'conversation_id': AnalyticsId.maybe(conversationId),
  });

  // --------------------------------------------------------------- navigation

  /// The command palette opened.
  static AnalyticsEvent commandPaletteOpened() =>
      AnalyticsEvent('command_palette_opened');

  /// A command ran from the palette or a keybinding.
  ///
  /// [command] must be a static command ID; dynamic entries (a PR, a member,
  /// a conversation) report only their [category].
  static AnalyticsEvent commandExecuted({
    required String source,
    String? command,
    String? category,
  }) => AnalyticsEvent('command_executed', {
    'source': source,
    'command': command,
    'category': category,
  });

  // -------------------------------------------------------------------- work

  /// The user submitted a pull-request review.
  static AnalyticsEvent reviewSubmitted({
    required String verdict,
    required int commentCount,
    String? workspaceId,
  }) => AnalyticsEvent('review_submitted', {
    'verdict': verdict,
    'comment_count': commentCount,
    'workspace_id': AnalyticsId.maybe(workspaceId),
  });

  /// A search ran. Only its scope and outcome are recorded, never the query.
  static AnalyticsEvent searchPerformed({
    required String scope,
    required int resultCount,
    required int queryLength,
    String? workspaceId,
    String? spaceId,
  }) => AnalyticsEvent('search_performed', {
    'scope': scope,
    'result_count': resultCount,
    'query_length': queryLength,
    'workspace_id': AnalyticsId.maybe(workspaceId),
    'space_id': AnalyticsId.maybe(spaceId),
  });

  /// A meeting recording started.
  static AnalyticsEvent meetingRecordingStarted({
    String? mode,
    String? workspaceId,
    String? meetingId,
  }) => AnalyticsEvent('meeting_recording_started', {
    'mode': mode,
    'workspace_id': AnalyticsId.maybe(workspaceId),
    'meeting_id': AnalyticsId.maybe(meetingId),
  });

  /// A meeting recording stopped after [durationS] seconds.
  static AnalyticsEvent meetingRecordingStopped({
    required int durationS,
    String? workspaceId,
    String? meetingId,
  }) => AnalyticsEvent('meeting_recording_stopped', {
    'duration_s': durationS,
    'workspace_id': AnalyticsId.maybe(workspaceId),
    'meeting_id': AnalyticsId.maybe(meetingId),
  });

  // ----------------------------------------------------------- soundscape

  /// The soundscape started playing ([source]: `user` from the controls,
  /// `focus` when focus mode started it).
  static AnalyticsEvent soundscapeStarted({
    required String mood,
    required String source,
  }) => AnalyticsEvent('soundscape_started', {'mood': mood, 'source': source});

  /// The soundscape stopped after [listenedS] seconds.
  static AnalyticsEvent soundscapeStopped({
    required String mood,
    required String source,
    required int listenedS,
  }) => AnalyticsEvent('soundscape_stopped', {
    'mood': mood,
    'source': source,
    'listened_s': listenedS,
  });

  /// The user picked another soundscape mood.
  static AnalyticsEvent soundscapeMoodChanged({
    required String from,
    required String to,
    required bool playing,
  }) => AnalyticsEvent('soundscape_mood_changed', {
    'from_mood': from,
    'to_mood': to,
    'playing': playing,
  });

  // ----------------------------------------------------------- focus mode

  /// Focus mode started.
  static AnalyticsEvent focusModeStarted({
    required bool blockNotifications,
    required bool hasGoal,
    int? plannedMinutes,
  }) => AnalyticsEvent('focus_mode_started', {
    'planned_minutes': plannedMinutes,
    'has_goal': hasGoal,
    'block_notifications': blockNotifications,
  });

  /// Focus mode ended after [elapsedS] seconds ([completed] when the planned
  /// time ran out rather than being ended early).
  static AnalyticsEvent focusModeEnded({
    required int elapsedS,
    required bool completed,
    int? plannedMinutes,
  }) => AnalyticsEvent('focus_mode_ended', {
    'elapsed_s': elapsedS,
    'planned_minutes': plannedMinutes,
    'completed': completed,
  });

  // ------------------------------------------------------------ dictation

  /// Composer dictation started.
  static AnalyticsEvent dictationStarted() =>
      AnalyticsEvent('dictation_started');

  /// Dictation ended ([outcome]: `completed`, `cancelled`, `failed`).
  /// Only the transcript's length is recorded.
  static AnalyticsEvent dictationEnded({
    required String outcome,
    required int durationS,
    int? transcriptChars,
    String? errorKind,
  }) => AnalyticsEvent('dictation_ended', {
    'outcome': outcome,
    'duration_s': durationS,
    'transcript_chars': transcriptChars,
    'error_kind': errorKind,
  });

  // ------------------------------------------------------------ pipelines

  /// A client asked the server to run a pipeline ([trigger] as the client
  /// passed it, `manual` for the run screen). [started] is false when the
  /// server refused (disabled template, dedup).
  static AnalyticsEvent pipelineRunRequested({
    required String workspaceId,
    required String templateId,
    required String trigger,
    required bool dryRun,
    required bool started,
  }) => AnalyticsEvent('pipeline_run_requested', {
    'workspace_id': AnalyticsId(workspaceId),
    'template_id': AnalyticsId(templateId),
    'trigger': trigger,
    'dry_run': dryRun,
    'started': started,
  });

  /// How a pipeline run started, as a closed-vocabulary token: `manual`
  /// without a trigger, the event type for a domain-event trigger, or only
  /// the kind prefix of a scoped one (`webhook:<name>` → `webhook`), whose
  /// remainder is user-named.
  static String pipelineTriggerKind(String? triggerEventType) {
    if (triggerEventType == null || triggerEventType.isEmpty) {
      return 'manual';
    }
    final kind = triggerEventType.split(RegExp('[:/]')).first;
    return RegExp(r'^[A-Za-z][A-Za-z0-9_]{0,60}$').hasMatch(kind)
        ? kind
        : 'other';
  }

  /// A failed pipeline run was retried.
  static AnalyticsEvent pipelineRunRetried({
    required String workspaceId,
    required String pipelineRunId,
  }) => AnalyticsEvent('pipeline_run_retried', {
    'workspace_id': AnalyticsId(workspaceId),
    'pipeline_run_id': AnalyticsId(pipelineRunId),
  });

  /// A pipeline run was cancelled from a client.
  static AnalyticsEvent pipelineRunCancelRequested({
    required String workspaceId,
    required String pipelineRunId,
  }) => AnalyticsEvent('pipeline_run_cancel_requested', {
    'workspace_id': AnalyticsId(workspaceId),
    'pipeline_run_id': AnalyticsId(pipelineRunId),
  });

  /// A running pipeline step was killed.
  static AnalyticsEvent pipelineStepKilled({
    required String workspaceId,
    required String stepRunId,
  }) => AnalyticsEvent('pipeline_step_killed', {
    'workspace_id': AnalyticsId(workspaceId),
    'step_run_id': AnalyticsId(stepRunId),
  });

  // ------------------------------------------------------------- calendar

  /// A calendar sign-in attempt ended ([outcome]: `connected`, `denied`,
  /// `expired`, `failed`, `cancelled`).
  static AnalyticsEvent calendarConnectFinished({
    required String outcome,
    required bool builtinClient,
    required int durationS,
  }) => AnalyticsEvent('calendar_connect_finished', {
    'outcome': outcome,
    'builtin_client': builtinClient,
    'duration_s': durationS,
  });

  /// A calendar account was disconnected.
  static AnalyticsEvent calendarDisconnected({String? workspaceId}) =>
      AnalyticsEvent('calendar_disconnected', {
        'workspace_id': AnalyticsId.maybe(workspaceId),
      });

  /// The user answered a calendar invitation.
  static AnalyticsEvent calendarRsvpSent({
    required String calendarEventId,
    required String response,
    String? previousResponse,
    String? workspaceId,
  }) => AnalyticsEvent('calendar_rsvp_sent', {
    'calendar_event_id': AnalyticsId(calendarEventId),
    'response': response,
    'previous_response': previousResponse,
    'workspace_id': AnalyticsId.maybe(workspaceId),
  });

  /// The user started recording a meeting straight from a calendar event.
  static AnalyticsEvent calendarEventRecorded({
    required String workspaceId,
    required String calendarEventId,
  }) => AnalyticsEvent('calendar_event_recorded', {
    'workspace_id': AnalyticsId(workspaceId),
    'calendar_event_id': AnalyticsId(calendarEventId),
  });

  /// The user opened a calendar event's meeting link ([provider] from the
  /// link's host: `meet`, `zoom`, `teams`, `webex`, `other`).
  static AnalyticsEvent calendarMeetingJoined({
    required String provider,
    String? workspaceId,
    String? calendarEventId,
  }) => AnalyticsEvent('calendar_meeting_joined', {
    'provider': provider,
    'workspace_id': AnalyticsId.maybe(workspaceId),
    'calendar_event_id': AnalyticsId.maybe(calendarEventId),
  });

  /// The conferencing provider behind a meeting URL, as a closed token. Only
  /// the host is inspected; the URL itself is never recorded.
  static String meetingProvider(String? url) {
    final host = Uri.tryParse(url ?? '')?.host.toLowerCase() ?? '';
    return switch (host) {
      final h when h.endsWith('meet.google.com') => 'meet',
      final h when h.contains('zoom.') => 'zoom',
      final h when h.contains('teams.microsoft') || h.contains('teams.live') =>
        'teams',
      final h when h.contains('webex') => 'webex',
      _ => 'other',
    };
  }

  // -------------------------------------------------------- notifications

  /// The user acted on the notification center ([action]: `read`, `unread`,
  /// `dismiss`, `mark_all_read`, `clear_all`).
  static AnalyticsEvent notificationAction({
    required String action,
    String? category,
    String? workspaceId,
  }) => AnalyticsEvent('notification_action', {
    'action': action,
    'category': category,
    'workspace_id': AnalyticsId.maybe(workspaceId),
  });

  // ------------------------------------------------------- agents & tools

  /// The user created an agent from the registry.
  static AnalyticsEvent agentCreated({
    required String workspaceId,
    required String agentId,
    String? adapter,
    String? model,
  }) => AnalyticsEvent('agent_created', {
    'workspace_id': AnalyticsId(workspaceId),
    'agent_id': AnalyticsId(agentId),
    'adapter': adapter,
    'model': model,
  });

  /// An editor tab opened in a space ([kind]: `terminal`, `browser`, `rig`,
  /// `codeServer`, `file`, `chat`, …).
  static AnalyticsEvent tabOpened({required String kind}) =>
      AnalyticsEvent('tab_opened', {'kind': kind});

  /// The user changed a workspace's skills ([action]: `install`, `update`,
  /// `uninstall`, `source_added`, `source_removed`). Skill slugs are
  /// pseudonymized.
  static AnalyticsEvent skillAction({
    required String action,
    String? skillSlug,
    bool? blocked,
  }) => AnalyticsEvent('skill_action', {
    'action': action,
    'skill_id': AnalyticsId.maybe(skillSlug),
    'blocked': blocked,
  });

  /// The user answered an orchestration proposal (`approved`, `cancelled`).
  static AnalyticsEvent orchestrationDecided({
    required String decision,
    required String workspaceId,
    required String orchestrationId,
  }) => AnalyticsEvent('orchestration_decided', {
    'decision': decision,
    'workspace_id': AnalyticsId(workspaceId),
    'orchestration_id': AnalyticsId(orchestrationId),
  });

  /// The user approved or rejected a plan ([partial] when only some nodes
  /// were approved).
  static AnalyticsEvent planDecided({
    required String decision,
    required String planId,
    String? workspaceId,
    bool? partial,
    int? nodeCount,
  }) => AnalyticsEvent('plan_decided', {
    'decision': decision,
    'plan_id': AnalyticsId(planId),
    'workspace_id': AnalyticsId.maybe(workspaceId),
    'partial': partial,
    'node_count': nodeCount,
  });

  /// The user started a supervised goal or loop from the phone.
  static AnalyticsEvent goalStarted({
    required String kind,
    required String workspaceId,
    required String spaceId,
    required bool accepted,
    String? conversationId,
    String? agentId,
    int? budgetCents,
  }) => AnalyticsEvent('goal_started', {
    'kind': kind,
    'workspace_id': AnalyticsId(workspaceId),
    'space_id': AnalyticsId(spaceId),
    'conversation_id': AnalyticsId.maybe(conversationId),
    'agent_id': AnalyticsId.maybe(agentId),
    'budget_cents': budgetCents,
    'accepted': accepted,
  });

  // -------------------------------------------------------- conversations

  /// A conversation was created ([source]: `new`, `fork`).
  static AnalyticsEvent conversationCreated({
    required String workspaceId,
    required String spaceId,
    required String conversationId,
    required String source,
  }) => AnalyticsEvent('conversation_created', {
    'workspace_id': AnalyticsId(workspaceId),
    'space_id': AnalyticsId(spaceId),
    'conversation_id': AnalyticsId(conversationId),
    'source': source,
  });

  /// A conversation was rewound to an earlier message in place.
  static AnalyticsEvent conversationRewound({required String conversationId}) =>
      AnalyticsEvent('conversation_rewound', {
        'conversation_id': AnalyticsId(conversationId),
      });

  /// A space was archived.
  static AnalyticsEvent spaceArchived({
    required String workspaceId,
    required String spaceId,
  }) => AnalyticsEvent('space_archived', {
    'workspace_id': AnalyticsId(workspaceId),
    'space_id': AnalyticsId(spaceId),
  });

  // ----------------------------------------------------------------- settings

  /// A setting changed. [setting] is a stable setting ID and [value] a
  /// closed-vocabulary value (`dark`, `true`, `fr_FR`).
  static AnalyticsEvent settingChanged({
    required String setting,
    required String value,
  }) => AnalyticsEvent('setting_changed', {'setting': setting, 'value': value});

  // ------------------------------------------------------------------- server

  /// The server finished starting.
  static AnalyticsEvent serverStarted({
    required int workspaceCount,
    required int startupMs,
  }) => AnalyticsEvent('server_started', {
    'workspace_count': workspaceCount,
    'startup_ms': startupMs,
  });

  /// A workspace was created.
  static AnalyticsEvent workspaceCreated({required String workspaceId}) =>
      AnalyticsEvent('workspace_created', {
        'workspace_id': AnalyticsId(workspaceId),
      });

  /// A space was created.
  static AnalyticsEvent spaceCreated({
    required String workspaceId,
    required String spaceId,
  }) => AnalyticsEvent('space_created', {
    'workspace_id': AnalyticsId(workspaceId),
    'space_id': AnalyticsId(spaceId),
  });

  /// A repository was linked to a workspace.
  static AnalyticsEvent repoAdded({
    required String workspaceId,
    required String repoId,
  }) => AnalyticsEvent('repo_added', {
    'workspace_id': AnalyticsId(workspaceId),
    'repo_id': AnalyticsId(repoId),
  });

  /// A ticket was created (by a person or an agent).
  static AnalyticsEvent ticketCreated({
    required String workspaceId,
    required String ticketId,
  }) => AnalyticsEvent('ticket_created', {
    'workspace_id': AnalyticsId(workspaceId),
    'ticket_id': AnalyticsId(ticketId),
  });

  /// An agent run finished.
  ///
  /// Strings are closed vocabularies: [status] and [errorFamily] are
  /// `RunStatus` / `RunErrorFamily` names, [role] an `AgentRunRole` name,
  /// [adapter] the adapter ID and [model] the provider's model ID.
  static AnalyticsEvent agentRunCompleted({
    required String agentId,
    String? workspaceId,
    String? conversationId,
    String? runId,
    String? status,
    String? errorFamily,
    String? role,
    String? adapter,
    String? model,
    String? effort,
    String? taskFamily,
    bool? subagent,
    bool? pipeline,
    bool? resumedNativeSession,
    int? durationMs,
    int? timeToFirstTokenMs,
    int? inputTokens,
    int? outputTokens,
    int? thoughtTokens,
    int? cacheReadTokens,
    int? cacheWriteTokens,
    int? outputRejections,
    double? costUsd,
  }) => AnalyticsEvent('agent_run_completed', {
    'agent_id': AnalyticsId(agentId),
    'workspace_id': AnalyticsId.maybe(workspaceId),
    'conversation_id': AnalyticsId.maybe(conversationId),
    'run_id': AnalyticsId.maybe(runId),
    'status': status,
    'error_family': errorFamily,
    'role': role,
    'adapter': adapter,
    'model': model,
    'effort': effort,
    'task_family': taskFamily,
    'subagent': subagent,
    'pipeline': pipeline,
    'resumed_native_session': resumedNativeSession,
    'duration_ms': durationMs,
    'time_to_first_token_ms': timeToFirstTokenMs,
    'input_tokens': inputTokens,
    'output_tokens': outputTokens,
    'thought_tokens': thoughtTokens,
    'cache_read_tokens': cacheReadTokens,
    'cache_write_tokens': cacheWriteTokens,
    'output_rejections': outputRejections,
    'cost_usd': costUsd,
  });

  /// An agent stopped to wait on a person ([kind] is an `AgentInputKind`
  /// wire value).
  static AnalyticsEvent agentAwaitingInput({
    required String kind,
    required String workspaceId,
    String? agentId,
    String? conversationId,
  }) => AnalyticsEvent('agent_awaiting_input', {
    'kind': kind,
    'workspace_id': AnalyticsId(workspaceId),
    'agent_id': AnalyticsId.maybe(agentId),
    'conversation_id': AnalyticsId.maybe(conversationId),
  });

  /// Action policy refused an agent's action.
  static AnalyticsEvent agentActionBlocked({
    required String workspaceId,
    String? agentId,
    String? spaceId,
    String? source,
  }) => AnalyticsEvent('agent_action_blocked', {
    'workspace_id': AnalyticsId(workspaceId),
    'agent_id': AnalyticsId.maybe(agentId),
    'space_id': AnalyticsId.maybe(spaceId),
    'source': source,
  });

  /// A pipeline run reached a terminal state. [trigger] is how it started
  /// (`manual`, a domain-event type such as `TicketCreated`, or the kind
  /// prefix of a scoped trigger such as `webhook`).
  static AnalyticsEvent pipelineRunFinished({
    required String workspaceId,
    required String pipelineRunId,
    required String templateId,
    required String outcome,
    String? trigger,
    int? durationMs,
    int? activeMs,
    int? attemptCount,
    int? templateVersion,
    int? costCents,
    int? tokens,
    bool? dryRun,
    bool? subPipeline,
  }) => AnalyticsEvent('pipeline_run_finished', {
    'workspace_id': AnalyticsId(workspaceId),
    'pipeline_run_id': AnalyticsId(pipelineRunId),
    'template_id': AnalyticsId(templateId),
    'outcome': outcome,
    'trigger': trigger,
    'duration_ms': durationMs,
    'active_ms': activeMs,
    'attempt_count': attemptCount,
    'template_version': templateVersion,
    'cost_cents': costCents,
    'tokens': tokens,
    'dry_run': dryRun,
    'sub_pipeline': subPipeline,
  });

  /// A pull request was published from a space.
  static AnalyticsEvent pullRequestPublished({
    required String workspaceId,
    required String prId,
  }) => AnalyticsEvent('pull_request_published', {
    'workspace_id': AnalyticsId(workspaceId),
    'pr_id': AnalyticsId(prId),
  });

  /// A pull request an agent opened was merged.
  static AnalyticsEvent pullRequestMerged({
    required String workspaceId,
    required String prId,
    String? agentId,
  }) => AnalyticsEvent('pull_request_merged', {
    'workspace_id': AnalyticsId(workspaceId),
    'pr_id': AnalyticsId(prId),
    'agent_id': AnalyticsId.maybe(agentId),
  });

  /// A ticket moved between workflow statuses (`TicketStatus` names).
  static AnalyticsEvent ticketStatusChanged({
    required String workspaceId,
    required String ticketId,
    required String from,
    required String to,
  }) => AnalyticsEvent('ticket_status_changed', {
    'workspace_id': AnalyticsId(workspaceId),
    'ticket_id': AnalyticsId(ticketId),
    'from_status': from,
    'to_status': to,
  });

  /// A ticket was assigned ([assigneeType]: `agent`, `team`, `human`).
  static AnalyticsEvent ticketAssigned({
    required String workspaceId,
    required String ticketId,
    required String assigneeType,
    String? agentId,
    String? teamId,
  }) => AnalyticsEvent('ticket_assigned', {
    'workspace_id': AnalyticsId(workspaceId),
    'ticket_id': AnalyticsId(ticketId),
    'assignee_type': assigneeType,
    'agent_id': AnalyticsId.maybe(agentId),
    'team_id': AnalyticsId.maybe(teamId),
  });

  /// A ticket moved from one agent to another.
  static AnalyticsEvent ticketReassigned({
    required String workspaceId,
    required String ticketId,
    String? fromAgentId,
    String? toAgentId,
  }) => AnalyticsEvent('ticket_reassigned', {
    'workspace_id': AnalyticsId(workspaceId),
    'ticket_id': AnalyticsId(ticketId),
    'from_agent_id': AnalyticsId.maybe(fromAgentId),
    'to_agent_id': AnalyticsId.maybe(toAgentId),
  });

  /// A ticket's delegated work ended (`completed`, `failed`, `cancelled`).
  static AnalyticsEvent ticketWorkFinished({
    required String ticketId,
    required String outcome,
  }) => AnalyticsEvent('ticket_work_finished', {
    'ticket_id': AnalyticsId(ticketId),
    'outcome': outcome,
  });

  /// A space was deleted.
  static AnalyticsEvent spaceDeleted({
    required String workspaceId,
    required String spaceId,
  }) => AnalyticsEvent('space_deleted', {
    'workspace_id': AnalyticsId(workspaceId),
    'space_id': AnalyticsId(spaceId),
  });

  /// Workspace membership changed ([change]: `added`, `removed`,
  /// `role_changed`; [role] a `WorkspaceRole` name).
  static AnalyticsEvent workspaceMemberChanged({
    required String workspaceId,
    required String memberUserId,
    required String change,
    String? role,
  }) => AnalyticsEvent('workspace_member_changed', {
    'workspace_id': AnalyticsId(workspaceId),
    'member_user_id': AnalyticsId(memberUserId),
    'change': change,
    'role': role,
  });

  /// A rig (sandboxed browser/terminal/desktop) closed (`RigCloseReason`
  /// name); [reaped] when the reaper, not a person, closed it.
  static AnalyticsEvent rigClosed({
    required String workspaceId,
    required String rigId,
    required String reason,
    required bool reaped,
    String? agentId,
  }) => AnalyticsEvent('rig_closed', {
    'workspace_id': AnalyticsId(workspaceId),
    'rig_id': AnalyticsId(rigId),
    'reason': reason,
    'reaped': reaped,
    'agent_id': AnalyticsId.maybe(agentId),
  });

  /// A workspace skill was written ([origin]: `registry`, `github`,
  /// `manual`, `watch`; [scanVerdict]: `pass`, `warn`, `quarantine`). The
  /// skill's slug can name a project, so it is pseudonymized.
  static AnalyticsEvent skillUpdated({
    required String workspaceId,
    required String skillSlug,
    required String origin,
    String? scanVerdict,
  }) => AnalyticsEvent('skill_updated', {
    'workspace_id': AnalyticsId(workspaceId),
    'skill_id': AnalyticsId(skillSlug),
    'origin': origin,
    'scan_verdict': scanVerdict,
  });

  /// A calendar connection's credentials expired. The account's address is
  /// never recorded.
  static AnalyticsEvent calendarAuthExpired({required String workspaceId}) =>
      AnalyticsEvent('calendar_auth_expired', {
        'workspace_id': AnalyticsId(workspaceId),
      });

  /// A calendar event is about to start.
  static AnalyticsEvent calendarMeetingStartingSoon({
    required String workspaceId,
    required String calendarEventId,
    required bool hasMeetingLink,
    required int leadS,
  }) => AnalyticsEvent('calendar_meeting_starting_soon', {
    'workspace_id': AnalyticsId(workspaceId),
    'calendar_event_id': AnalyticsId(calendarEventId),
    'has_meeting_link': hasMeetingLink,
    'lead_s': leadS,
  });

  /// Spending crossed a budget threshold ([scopeType]: `workspace`,
  /// `agent`, `goal`, …).
  static AnalyticsEvent budgetThresholdCrossed({
    required String scopeType,
    required String scopeId,
    required int spentCents,
    required int budgetCents,
    required bool hardStop,
  }) => AnalyticsEvent('budget_threshold_crossed', {
    'scope_type': scopeType,
    'scope_id': AnalyticsId(scopeId),
    'spent_cents': spentCents,
    'budget_cents': budgetCents,
    'hard_stop': hardStop,
  });

  /// A review was requested on a tracked pull request. The repository is
  /// pseudonymized; its name is never sent.
  static AnalyticsEvent pullRequestReviewRequested({
    required String workspaceId,
    required String repoFullName,
  }) => AnalyticsEvent('pull_request_review_requested', {
    'workspace_id': AnalyticsId(workspaceId),
    'repo_id': AnalyticsId(repoFullName),
  });

  /// A tracked pull request's review decision changed ([decision]:
  /// `APPROVED`, `CHANGES_REQUESTED`, `REVIEW_REQUIRED`, …).
  static AnalyticsEvent pullRequestReviewDecisionChanged({
    required String workspaceId,
    required String repoFullName,
    required String decision,
    required int reviewersRemaining,
  }) => AnalyticsEvent('pull_request_review_decision_changed', {
    'workspace_id': AnalyticsId(workspaceId),
    'repo_id': AnalyticsId(repoFullName),
    'decision': decision,
    'reviewers_remaining': reviewersRemaining,
  });

  /// A pull request not opened by an agent merged in a linked repository.
  static AnalyticsEvent externalPullRequestMerged({
    required String workspaceId,
    required String repoFullName,
  }) => AnalyticsEvent('external_pull_request_merged', {
    'workspace_id': AnalyticsId(workspaceId),
    'repo_id': AnalyticsId(repoFullName),
  });

  /// A meeting recording was saved on the server.
  static AnalyticsEvent meetingRecorded({
    required String workspaceId,
    required String meetingId,
    required int transcriptChars,
  }) => AnalyticsEvent('meeting_recorded', {
    'workspace_id': AnalyticsId(workspaceId),
    'meeting_id': AnalyticsId(meetingId),
    'transcript_chars': transcriptChars,
  });
}
