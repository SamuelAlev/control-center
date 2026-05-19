import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/calendar/presentation/providers/calendar_ui_providers.dart';
import 'package:control_center/features/meetings/providers/meeting_providers.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/newsfeed/providers/newsfeed_providers.dart';
import 'package:control_center/features/pipelines/providers/pipeline_providers.dart';
import 'package:control_center/features/pr_review/presentation/utils/relative_time.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view/fast_diff_view/worker_pool_indicator.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_status_badge.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:control_center/features/ticketing/providers/ticketing_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Builds the breadcrumb trail for a single route. Runs inside the title bar
/// widget's build, so ref/context/l10n are all live — builders may watch async
/// providers and use context.go for link targets.
typedef BreadcrumbBuilder =
    List<CcBreadcrumbItem> Function(
      WidgetRef ref,
      BuildContext context,
      GoRouterState state,
      AppLocalizations l10n,
    );

/// Route `fullPath` pattern → builder. Patterns mirror go_router's
/// `GoRouterState.fullPath` (with `:param` placeholders, not concrete values).
/// A missing entry means the title bar shows no breadcrumb for that route.
final Map<String, BreadcrumbBuilder> breadcrumbRegistry = {
  dashboardRoute: _dashboardCrumbs,
  pullRequestsRoute: _pullRequestsListCrumbs,
  '$pullRequestsRoute/:prNumber': _pullRequestDetailCrumbs,
  agentsRoute: _agentsCrumbs,
  analyticsRoute: _analyticsCrumbs,
  '$analyticsRoute/agents/:agentId': _analyticsAgentDetailCrumbs,
  messagingRoute: _messagingCrumbs,
  ticketsRoute: _ticketsCrumbs,
  '$ticketsRoute/:ticketId': _ticketDetailCrumbs,
  '/projects/:projectId': _projectOverviewCrumbs,
  pipelinesRoute: _pipelinesCrumbs,
  runPipelineRoute: _runPipelineCrumbs,
  '$pipelinesRoute/:runId': _pipelineRunDetailCrumbs,
  newsfeedRoute: _newsfeedHomeCrumbs,
  newsfeedSettingsRoute: _newsfeedSettingsCrumbs,
  '$newsfeedRoute/article/:articleId': _newsfeedArticleCrumbs,
  meetingsRoute: _meetingsCrumbs,
  '$meetingsRoute/record': _meetingRecordCrumbs,
  '$meetingsRoute/:meetingId': _meetingDetailCrumbs,
  calendarRoute: _calendarCrumbs,
  '$calendarRoute/:eventId': _calendarEventDetailCrumbs,
  memoryRoute: _memoryCrumbs,
  apiKeysRoute: _apiKeysCrumbs,
  workspaceListRoute: _workspaceListCrumbs,
  '$workspaceListRoute/:workspaceId': _workspaceDetailCrumbs,
  settingsAppearanceRoute: _settingsAppearanceCrumbs,
  settingsNotificationsRoute: _settingsNotificationsCrumbs,
  settingsIntegrationsRoute: _settingsIntegrationsCrumbs,
  settingsAdvancedRoute: _settingsAdvancedCrumbs,
  settingsAdaptersRoute: _settingsAdaptersCrumbs,
  settingsAgentsRoute: _settingsAgentsCrumbs,
  settingsReposRoute: _settingsReposCrumbs,
  settingsSkillsRoute: _settingsSkillsCrumbs,
  settingsKeybindingsRoute: _settingsKeybindingsCrumbs,
  settingsSandboxingRoute: _settingsSandboxingCrumbs,
  settingsPipelinesRoute: _settingsPipelinesCrumbs,
  '$settingsPipelinesRoute/:templateId': _pipelineTemplateEditorCrumbs,
  teamsRoute: _settingsTeamsCrumbs,
  '/users/:login': _userProfileCrumbs,
};

// ─── Dashboard / Agents / Analytics / Newsfeed home ───────────────────────────

List<CcBreadcrumbItem> _dashboardCrumbs(
  WidgetRef ref,
  BuildContext context,
  GoRouterState state,
  AppLocalizations l10n,
) => [CcBreadcrumbItem(current: true, child: Text(l10n.navDashboard))];

List<CcBreadcrumbItem> _agentsCrumbs(
  WidgetRef ref,
  BuildContext context,
  GoRouterState state,
  AppLocalizations l10n,
) => [CcBreadcrumbItem(current: true, child: Text(l10n.agents))];

List<CcBreadcrumbItem> _analyticsCrumbs(
  WidgetRef ref,
  BuildContext context,
  GoRouterState state,
  AppLocalizations l10n,
) => [CcBreadcrumbItem(current: true, child: Text(l10n.navAnalytics))];

List<CcBreadcrumbItem> _analyticsAgentDetailCrumbs(
  WidgetRef ref,
  BuildContext context,
  GoRouterState state,
  AppLocalizations l10n,
) {
  final agentId = state.pathParameters['agentId'] ?? '';
  final base = CcBreadcrumbItem(
    onPress: () => context.go(analyticsRoute),
    child: Text(l10n.navAnalytics),
  );
  if (agentId.isEmpty) {
    return [base, CcBreadcrumbItem(current: true, child: Text(l10n.agent))];
  }
  final agentAsync = ref.watch(agentDetailProvider(agentId));
  final label = agentAsync.value?.name ?? l10n.agent;
  return [base, CcBreadcrumbItem(current: true, child: Text(label))];
}

List<CcBreadcrumbItem> _messagingCrumbs(
  WidgetRef ref,
  BuildContext context,
  GoRouterState state,
  AppLocalizations l10n,
) {
  final selectedId = ref.watch(selectedChannelIdProvider);
  if (selectedId == null) {
    return [CcBreadcrumbItem(current: true, child: Text(l10n.messagingLabel))];
  }
  final workspaceId = ref.watch(activeWorkspaceIdProvider);
  final channels = workspaceId != null
      ? ref.watch(workspaceChannelsProvider(workspaceId)).value ?? const []
      : ref.watch(channelsProvider).value ?? const [];
  final channel = channels.where((c) => c.id == selectedId).firstOrNull;
  if (channel == null) {
    return [CcBreadcrumbItem(current: true, child: Text(l10n.messagingLabel))];
  }
  String label;
  if (channel.isDm) {
    final participants =
        ref.watch(channelParticipantsProvider(selectedId)).value ?? const [];
    final agentParticipant = participants.where((p) => !p.isUser).firstOrNull;
    if (agentParticipant != null) {
      final agent = ref.watch(agentDetailProvider(agentParticipant.agentId));
      label = agent.value?.name ?? '…';
    } else {
      label = l10n.directMessage;
    }
  } else {
    label = channel.name.isNotEmpty ? channel.name : l10n.groupLabel;
  }
  return [
    CcBreadcrumbItem(
      onPress: () {
        ref.read(selectedChannelIdProvider.notifier).select(null);
        context.go(messagingRoute);
      },
      child: Text(l10n.messagingLabel),
    ),
    CcBreadcrumbItem(current: true, child: Text(label)),
  ];
}

List<CcBreadcrumbItem> _newsfeedHomeCrumbs(
  WidgetRef ref,
  BuildContext context,
  GoRouterState state,
  AppLocalizations l10n,
) => [CcBreadcrumbItem(current: true, child: Text(l10n.newsfeedLabel))];

List<CcBreadcrumbItem> _newsfeedSettingsCrumbs(
  WidgetRef ref,
  BuildContext context,
  GoRouterState state,
  AppLocalizations l10n,
) => [
  CcBreadcrumbItem(
    onPress: () => context.go(newsfeedRoute),
    child: Text(l10n.newsfeedLabel),
  ),
  CcBreadcrumbItem(current: true, child: Text(l10n.settingsLabel)),
];

List<CcBreadcrumbItem> _newsfeedArticleCrumbs(
  WidgetRef ref,
  BuildContext context,
  GoRouterState state,
  AppLocalizations l10n,
) {
  final base = CcBreadcrumbItem(
    onPress: () => context.go(newsfeedRoute),
    child: Text(l10n.newsfeedLabel),
  );
  final id = state.pathParameters['articleId'] ?? '';
  if (id.isEmpty) {
    return [
      base,
      CcBreadcrumbItem(current: true, child: Text(l10n.newsfeedLabel)),
    ];
  }
  final articleAsync = ref.watch(articleByIdProvider(id));
  return articleAsync.maybeWhen(
    data: (article) {
      final title = (article != null && article.title.isNotEmpty)
          ? article.title
          : l10n.newsfeedLabel;
      return [base, CcBreadcrumbItem(current: true, child: Text(title))];
    },
    orElse: () => [
      base,
      CcBreadcrumbItem(current: true, child: Text(l10n.newsfeedLabel)),
    ],
  );
}

// ─── Meetings ─────────────────────────────────────────────────────────────────

List<CcBreadcrumbItem> _meetingsCrumbs(
  WidgetRef ref,
  BuildContext context,
  GoRouterState state,
  AppLocalizations l10n,
) => [CcBreadcrumbItem(current: true, child: Text(l10n.navMeetings))];

List<CcBreadcrumbItem> _meetingRecordCrumbs(
  WidgetRef ref,
  BuildContext context,
  GoRouterState state,
  AppLocalizations l10n,
) => [
  CcBreadcrumbItem(
    onPress: () => context.go(meetingsRoute),
    child: Text(l10n.navMeetings),
  ),
  CcBreadcrumbItem(current: true, child: Text(l10n.meetingsRecordingCrumb)),
];

List<CcBreadcrumbItem> _meetingDetailCrumbs(
  WidgetRef ref,
  BuildContext context,
  GoRouterState state,
  AppLocalizations l10n,
) {
  final meetingId = state.pathParameters['meetingId'] ?? '';
  final base = CcBreadcrumbItem(
    onPress: () => context.go(meetingsRoute),
    child: Text(l10n.navMeetings),
  );
  final workspaceId = ref.watch(activeWorkspaceIdProvider);
  if (meetingId.isEmpty || workspaceId == null) {
    return [base, const CcBreadcrumbItem(current: true, child: Text('…'))];
  }
  final meetingAsync = ref.watch(
    meetingDetailProvider((workspaceId: workspaceId, meetingId: meetingId)),
  );
  return meetingAsync.maybeWhen(
    data: (meeting) {
      final title = (meeting != null && meeting.title.isNotEmpty)
          ? meeting.title
          : l10n.navMeetings;
      return [base, CcBreadcrumbItem(current: true, child: Text(title))];
    },
    orElse: () => [
      base,
      const CcBreadcrumbItem(current: true, child: Text('…')),
    ],
  );
}

// ─── Calendar ─────────────────────────────────────────────────────────────────

List<CcBreadcrumbItem> _calendarCrumbs(
  WidgetRef ref,
  BuildContext context,
  GoRouterState state,
  AppLocalizations l10n,
) => [CcBreadcrumbItem(current: true, child: Text(l10n.navCalendar))];

List<CcBreadcrumbItem> _calendarEventDetailCrumbs(
  WidgetRef ref,
  BuildContext context,
  GoRouterState state,
  AppLocalizations l10n,
) {
  final eventId = state.pathParameters['eventId'] ?? '';
  final base = CcBreadcrumbItem(
    onPress: () => context.go(calendarRoute),
    child: Text(l10n.navCalendar),
  );
  final workspaceId = ref.watch(activeWorkspaceIdProvider);
  if (eventId.isEmpty || workspaceId == null) {
    return [
      base,
      CcBreadcrumbItem(current: true, child: Text(l10n.calendarEventLabel)),
    ];
  }
  final eventAsync = ref.watch(
    calendarEventByIdProvider((workspaceId: workspaceId, eventId: eventId)),
  );
  return eventAsync.maybeWhen(
    data: (event) {
      final title = (event != null && event.title.isNotEmpty)
          ? event.title
          : l10n.calendarEventLabel;
      return [base, CcBreadcrumbItem(current: true, child: Text(title))];
    },
    orElse: () => [
      base,
      CcBreadcrumbItem(current: true, child: Text(l10n.calendarEventLabel)),
    ],
  );
}

// ─── Top-level: memory / API keys / workspaces list ───────────────────────────

List<CcBreadcrumbItem> _memoryCrumbs(
  WidgetRef ref,
  BuildContext context,
  GoRouterState state,
  AppLocalizations l10n,
) => [CcBreadcrumbItem(current: true, child: Text(l10n.navMemory))];

List<CcBreadcrumbItem> _apiKeysCrumbs(
  WidgetRef ref,
  BuildContext context,
  GoRouterState state,
  AppLocalizations l10n,
) => [CcBreadcrumbItem(current: true, child: Text(l10n.apiKeys))];

List<CcBreadcrumbItem> _workspaceListCrumbs(
  WidgetRef ref,
  BuildContext context,
  GoRouterState state,
  AppLocalizations l10n,
) => [CcBreadcrumbItem(current: true, child: Text(l10n.workspaces))];

// ─── Ticketing / Projects ─────────────────────────────────────────────────────

List<CcBreadcrumbItem> _ticketsCrumbs(
  WidgetRef ref,
  BuildContext context,
  GoRouterState state,
  AppLocalizations l10n,
) => [CcBreadcrumbItem(current: true, child: Text(l10n.navTickets))];

List<CcBreadcrumbItem> _ticketDetailCrumbs(
  WidgetRef ref,
  BuildContext context,
  GoRouterState state,
  AppLocalizations l10n,
) {
  final ticketId = state.pathParameters['ticketId'] ?? '';
  final base = CcBreadcrumbItem(
    onPress: () => context.go(ticketsRoute),
    child: Text(l10n.navTickets),
  );
  final workspaceId = ref.watch(activeWorkspaceIdProvider);
  if (ticketId.isEmpty || workspaceId == null) {
    return [base, const CcBreadcrumbItem(current: true, child: Text('…'))];
  }
  final ticketAsync = ref.watch(
    ticketByIdProvider((workspaceId: workspaceId, ticketId: ticketId)),
  );
  return ticketAsync.maybeWhen(
    data: (ticket) => [
      base,
      CcBreadcrumbItem(current: true, child: Text(ticket?.title ?? '…')),
    ],
    orElse: () => [
      base,
      const CcBreadcrumbItem(current: true, child: Text('…')),
    ],
  );
}

List<CcBreadcrumbItem> _projectOverviewCrumbs(
  WidgetRef ref,
  BuildContext context,
  GoRouterState state,
  AppLocalizations l10n,
) {
  final projectId = state.pathParameters['projectId'] ?? '';
  final base = CcBreadcrumbItem(
    onPress: () => context.go(ticketsRoute),
    child: Text(l10n.navTickets),
  );
  final workspaceId = ref.watch(activeWorkspaceIdProvider);
  if (projectId.isEmpty || workspaceId == null) {
    return [base, const CcBreadcrumbItem(current: true, child: Text('…'))];
  }
  final project = ref.watch(
    projectByIdProvider((workspaceId: workspaceId, projectId: projectId)),
  );
  return [
    base,
    CcBreadcrumbItem(current: true, child: Text(project?.name ?? '…')),
  ];
}

// ─── Pipelines ────────────────────────────────────────────────────────────────

List<CcBreadcrumbItem> _pipelinesCrumbs(
  WidgetRef ref,
  BuildContext context,
  GoRouterState state,
  AppLocalizations l10n,
) => [CcBreadcrumbItem(current: true, child: Text(l10n.pipelinesScreenTitle))];

List<CcBreadcrumbItem> _runPipelineCrumbs(
  WidgetRef ref,
  BuildContext context,
  GoRouterState state,
  AppLocalizations l10n,
) => [
  CcBreadcrumbItem(
    onPress: () => context.go(pipelinesRoute),
    child: Text(l10n.pipelinesScreenTitle),
  ),
  CcBreadcrumbItem(current: true, child: Text(l10n.pipelinesRunPipeline)),
];

List<CcBreadcrumbItem> _pipelineRunDetailCrumbs(
  WidgetRef ref,
  BuildContext context,
  GoRouterState state,
  AppLocalizations l10n,
) {
  final runId = state.pathParameters['runId'] ?? '';
  final base = CcBreadcrumbItem(
    onPress: () => context.go(pipelinesRoute),
    child: Text(l10n.pipelinesScreenTitle),
  );
  if (runId.isEmpty) {
    return [base];
  }
  // PipelineRun carries no display name of its own — only id, templateId and
  // workspaceId. The human-readable label lives on the matching
  // PipelineDefinition (keyed by templateId), so we first load the run, then
  // its workspace's templates, falling back to the templateId while pending.
  final run = ref.watch(pipelineRunProvider(runId)).value;
  if (run == null) {
    return [base, const CcBreadcrumbItem(current: true, child: Text('…'))];
  }
  final definition = ref
      .watch(pipelineTemplatesProvider(run.workspaceId))
      .value
      ?.where((t) => t.templateId == run.templateId)
      .firstOrNull;
  final label = definition?.name ?? run.templateId;
  return [base, CcBreadcrumbItem(current: true, child: Text(label))];
}

// ─── Pull requests ────────────────────────────────────────────────────────────

List<CcBreadcrumbItem> _pullRequestsListCrumbs(
  WidgetRef ref,
  BuildContext context,
  GoRouterState state,
  AppLocalizations l10n,
) => [CcBreadcrumbItem(current: true, child: Text(l10n.pullRequests))];

List<CcBreadcrumbItem> _pullRequestDetailCrumbs(
  WidgetRef ref,
  BuildContext context,
  GoRouterState state,
  AppLocalizations l10n,
) {
  final raw = state.pathParameters['prNumber'] ?? '';
  final prNumber = int.tryParse(raw);
  final base = CcBreadcrumbItem(
    onPress: () => context.go(pullRequestsRoute),
    child: Text(l10n.pullRequests),
  );
  if (prNumber == null) {
    return [base, CcBreadcrumbItem(current: true, child: Text('#$raw'))];
  }
  final prAsync = ref.watch(prDetailProvider(prNumber));
  return prAsync.maybeWhen(
    data: (pr) {
      if (pr == null) {
        return [
          base,
          CcBreadcrumbItem(current: true, child: Text('#$prNumber')),
        ];
      }
      final created = pr.createdAt;
      final timeStr = created != null ? ', ${formatRelative(created)}' : '';
      final login = pr.author?.login ?? '';
      final label = '#${pr.number} opened by $login$timeStr';
      return [
        base,
        CcBreadcrumbItem(
          current: true,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label),
              const SizedBox(width: 10),
              PrStatusBadge(pr: pr),
              const SizedBox(width: 10),
              const DiffWorkerPoolIndicator(),
            ],
          ),
        ),
      ];
    },
    orElse: () => [
      base,
      CcBreadcrumbItem(current: true, child: Text('#$prNumber')),
    ],
  );
}

// ─── Settings subtree ─────────────────────────────────────────────────────────

CcBreadcrumbItem _settingsRoot(BuildContext context, AppLocalizations l10n) =>
    CcBreadcrumbItem(
      onPress: () => context.go(settingsAppearanceRoute),
      child: Text(l10n.settingsLabel),
    );

List<CcBreadcrumbItem> _settingsAppearanceCrumbs(
  WidgetRef ref,
  BuildContext context,
  GoRouterState state,
  AppLocalizations l10n,
) => [
  _settingsRoot(context, l10n),
  CcBreadcrumbItem(current: true, child: Text(l10n.appearance)),
];

List<CcBreadcrumbItem> _settingsNotificationsCrumbs(
  WidgetRef ref,
  BuildContext context,
  GoRouterState state,
  AppLocalizations l10n,
) => [
  _settingsRoot(context, l10n),
  CcBreadcrumbItem(current: true, child: Text(l10n.notifications)),
];

List<CcBreadcrumbItem> _settingsIntegrationsCrumbs(
  WidgetRef ref,
  BuildContext context,
  GoRouterState state,
  AppLocalizations l10n,
) => [
  _settingsRoot(context, l10n),
  CcBreadcrumbItem(current: true, child: Text(l10n.integrations)),
];

List<CcBreadcrumbItem> _settingsAdvancedCrumbs(
  WidgetRef ref,
  BuildContext context,
  GoRouterState state,
  AppLocalizations l10n,
) => [
  _settingsRoot(context, l10n),
  CcBreadcrumbItem(current: true, child: Text(l10n.advanced)),
];

List<CcBreadcrumbItem> _settingsAdaptersCrumbs(
  WidgetRef ref,
  BuildContext context,
  GoRouterState state,
  AppLocalizations l10n,
) => [
  _settingsRoot(context, l10n),
  CcBreadcrumbItem(current: true, child: Text(l10n.adapters)),
];

List<CcBreadcrumbItem> _settingsAgentsCrumbs(
  WidgetRef ref,
  BuildContext context,
  GoRouterState state,
  AppLocalizations l10n,
) => [
  _settingsRoot(context, l10n),
  CcBreadcrumbItem(current: true, child: Text(l10n.agentRegistry)),
];

List<CcBreadcrumbItem> _settingsReposCrumbs(
  WidgetRef ref,
  BuildContext context,
  GoRouterState state,
  AppLocalizations l10n,
) => [
  _settingsRoot(context, l10n),
  CcBreadcrumbItem(current: true, child: Text(l10n.repositories)),
];

List<CcBreadcrumbItem> _settingsSkillsCrumbs(
  WidgetRef ref,
  BuildContext context,
  GoRouterState state,
  AppLocalizations l10n,
) => [
  _settingsRoot(context, l10n),
  CcBreadcrumbItem(current: true, child: Text(l10n.skills)),
];

List<CcBreadcrumbItem> _settingsKeybindingsCrumbs(
  WidgetRef ref,
  BuildContext context,
  GoRouterState state,
  AppLocalizations l10n,
) => [
  _settingsRoot(context, l10n),
  CcBreadcrumbItem(current: true, child: Text(l10n.keybindings)),
];

List<CcBreadcrumbItem> _settingsSandboxingCrumbs(
  WidgetRef ref,
  BuildContext context,
  GoRouterState state,
  AppLocalizations l10n,
) => [
  _settingsRoot(context, l10n),
  CcBreadcrumbItem(current: true, child: Text(l10n.sandboxing)),
];

List<CcBreadcrumbItem> _settingsPipelinesCrumbs(
  WidgetRef ref,
  BuildContext context,
  GoRouterState state,
  AppLocalizations l10n,
) => [
  _settingsRoot(context, l10n),
  CcBreadcrumbItem(current: true, child: Text(l10n.pipelineTemplatesTitle)),
];

List<CcBreadcrumbItem> _pipelineTemplateEditorCrumbs(
  WidgetRef ref,
  BuildContext context,
  GoRouterState state,
  AppLocalizations l10n,
) {
  final templateId = state.pathParameters['templateId'] ?? '';
  final base = [
    _settingsRoot(context, l10n),
    CcBreadcrumbItem(
      onPress: () => context.go(settingsPipelinesRoute),
      child: Text(l10n.pipelineTemplatesTitle),
    ),
  ];
  final workspaceId = ref.watch(activeWorkspaceIdProvider);
  if (workspaceId == null || templateId.isEmpty) {
    return [...base, CcBreadcrumbItem(current: true, child: Text(templateId))];
  }
  final templatesAsync = ref.watch(pipelineTemplatesProvider(workspaceId));
  return templatesAsync.maybeWhen(
    data: (templates) {
      final template = templates
          .where((t) => t.templateId == templateId)
          .firstOrNull;
      return [
        ...base,
        CcBreadcrumbItem(
          current: true,
          child: Text(template?.name ?? templateId),
        ),
      ];
    },
    orElse: () => [
      ...base,
      CcBreadcrumbItem(current: true, child: Text(templateId)),
    ],
  );
}

List<CcBreadcrumbItem> _settingsTeamsCrumbs(
  WidgetRef ref,
  BuildContext context,
  GoRouterState state,
  AppLocalizations l10n,
) => [
  _settingsRoot(context, l10n),
  CcBreadcrumbItem(current: true, child: Text(l10n.teamsTitle)),
];

// ─── User profile ─────────────────────────────────────────────────────────────

List<CcBreadcrumbItem> _userProfileCrumbs(
  WidgetRef ref,
  BuildContext context,
  GoRouterState state,
  AppLocalizations l10n,
) {
  final login = state.pathParameters['login'] ?? '';
  return [
    CcBreadcrumbItem(child: Text(l10n.usersLabel)),
    CcBreadcrumbItem(current: true, child: Text(login)),
  ];
}

// ─── Workspace detail ─────────────────────────────────────────────────────────

List<CcBreadcrumbItem> _workspaceDetailCrumbs(
  WidgetRef ref,
  BuildContext context,
  GoRouterState state,
  AppLocalizations l10n,
) {
  final id = state.pathParameters['workspaceId'] ?? '';
  final base = CcBreadcrumbItem(
    onPress: () => context.go(workspaceListRoute),
    child: Text(l10n.workspaces),
  );
  if (id.isEmpty) {
    return [base];
  }
  final workspaceAsync = ref.watch(workspaceDetailProvider(id));
  final reposAsync = ref.watch(reposForWorkspaceProvider(id));
  final workspace = workspaceAsync.value;
  if (workspace == null) {
    return [base];
  }
  final repos = reposAsync.value ?? const [];
  final label = repos.isEmpty
      ? workspace.name
      : repos.map((r) => r.name).join(', ');
  return [base, CcBreadcrumbItem(current: true, child: Text(label))];
}
