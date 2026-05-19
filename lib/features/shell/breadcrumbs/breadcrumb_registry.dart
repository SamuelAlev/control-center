import 'package:control_center/features/agents/providers/agent_providers.dart';
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
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

/// Builds the breadcrumb trail for a single route. Runs inside the title bar
/// widget's build, so ref/context/l10n are all live — builders may watch async
/// providers and use context.go for link targets.
typedef BreadcrumbBuilder =
    List<FBreadcrumbItem> Function(
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

List<FBreadcrumbItem> _dashboardCrumbs(
  WidgetRef ref,
  BuildContext context,
  GoRouterState state,
  AppLocalizations l10n,
) => [FBreadcrumbItem(current: true, child: Text(l10n.navDashboard))];

List<FBreadcrumbItem> _agentsCrumbs(
  WidgetRef ref,
  BuildContext context,
  GoRouterState state,
  AppLocalizations l10n,
) => [FBreadcrumbItem(current: true, child: Text(l10n.agents))];

List<FBreadcrumbItem> _analyticsCrumbs(
  WidgetRef ref,
  BuildContext context,
  GoRouterState state,
  AppLocalizations l10n,
) => [FBreadcrumbItem(current: true, child: Text(l10n.navAnalytics))];

List<FBreadcrumbItem> _analyticsAgentDetailCrumbs(
  WidgetRef ref,
  BuildContext context,
  GoRouterState state,
  AppLocalizations l10n,
) {
  final agentId = state.pathParameters['agentId'] ?? '';
  final base = FBreadcrumbItem(
    onPress: () => context.go(analyticsRoute),
    child: Text(l10n.navAnalytics),
  );
  if (agentId.isEmpty) {
    return [base, FBreadcrumbItem(current: true, child: Text(l10n.agent))];
  }
  final agentAsync = ref.watch(agentDetailProvider(agentId));
  final label = agentAsync.value?.name ?? l10n.agent;
  return [base, FBreadcrumbItem(current: true, child: Text(label))];
}

List<FBreadcrumbItem> _messagingCrumbs(
  WidgetRef ref,
  BuildContext context,
  GoRouterState state,
  AppLocalizations l10n,
) {
  final selectedId = ref.watch(selectedChannelIdProvider);
  if (selectedId == null) {
    return [FBreadcrumbItem(current: true, child: Text(l10n.messagingLabel))];
  }
  final workspaceId = ref.watch(activeWorkspaceIdProvider);
  final channels = workspaceId != null
      ? ref.watch(workspaceChannelsProvider(workspaceId)).value ?? const []
      : ref.watch(channelsProvider).value ?? const [];
  final channel = channels.where((c) => c.id == selectedId).firstOrNull;
  if (channel == null) {
    return [FBreadcrumbItem(current: true, child: Text(l10n.messagingLabel))];
  }
  String label;
  if (channel.isDm) {
    final participants =
        ref.watch(channelParticipantsProvider(selectedId)).value ?? const [];
    final agentParticipant = participants
        .where((p) => !p.isUser)
        .firstOrNull;
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
    FBreadcrumbItem(
      onPress: () {
        ref.read(selectedChannelIdProvider.notifier).select(null);
        context.go(messagingRoute);
      },
      child: Text(l10n.messagingLabel),
    ),
    FBreadcrumbItem(current: true, child: Text(label)),
  ];
}

List<FBreadcrumbItem> _newsfeedHomeCrumbs(
  WidgetRef ref,
  BuildContext context,
  GoRouterState state,
  AppLocalizations l10n,
) => [FBreadcrumbItem(current: true, child: Text(l10n.newsfeedLabel))];

List<FBreadcrumbItem> _newsfeedSettingsCrumbs(
  WidgetRef ref,
  BuildContext context,
  GoRouterState state,
  AppLocalizations l10n,
) => [
  FBreadcrumbItem(
    onPress: () => context.go(newsfeedRoute),
    child: Text(l10n.newsfeedLabel),
  ),
  FBreadcrumbItem(current: true, child: Text(l10n.settingsLabel)),
];

List<FBreadcrumbItem> _newsfeedArticleCrumbs(
  WidgetRef ref,
  BuildContext context,
  GoRouterState state,
  AppLocalizations l10n,
) {
  final base = FBreadcrumbItem(
    onPress: () => context.go(newsfeedRoute),
    child: Text(l10n.newsfeedLabel),
  );
  final id = state.pathParameters['articleId'] ?? '';
  if (id.isEmpty) {
    return [
      base,
      FBreadcrumbItem(current: true, child: Text(l10n.newsfeedLabel)),
    ];
  }
  final articleAsync = ref.watch(articleByIdProvider(id));
  return articleAsync.maybeWhen(
    data: (article) {
      final title = (article != null && article.title.isNotEmpty)
          ? article.title
          : l10n.newsfeedLabel;
      return [base, FBreadcrumbItem(current: true, child: Text(title))];
    },
    orElse: () => [
      base,
      FBreadcrumbItem(current: true, child: Text(l10n.newsfeedLabel)),
    ],
  );
}

// ─── Top-level: memory / API keys / workspaces list ───────────────────────────

List<FBreadcrumbItem> _memoryCrumbs(
  WidgetRef ref,
  BuildContext context,
  GoRouterState state,
  AppLocalizations l10n,
) => [FBreadcrumbItem(current: true, child: Text(l10n.navMemory))];

List<FBreadcrumbItem> _apiKeysCrumbs(
  WidgetRef ref,
  BuildContext context,
  GoRouterState state,
  AppLocalizations l10n,
) => [FBreadcrumbItem(current: true, child: Text(l10n.apiKeys))];

List<FBreadcrumbItem> _workspaceListCrumbs(
  WidgetRef ref,
  BuildContext context,
  GoRouterState state,
  AppLocalizations l10n,
) => [FBreadcrumbItem(current: true, child: Text(l10n.workspaces))];

// ─── Ticketing / Projects ─────────────────────────────────────────────────────

List<FBreadcrumbItem> _ticketsCrumbs(
  WidgetRef ref,
  BuildContext context,
  GoRouterState state,
  AppLocalizations l10n,
) => [FBreadcrumbItem(current: true, child: Text(l10n.navTickets))];

List<FBreadcrumbItem> _ticketDetailCrumbs(
  WidgetRef ref,
  BuildContext context,
  GoRouterState state,
  AppLocalizations l10n,
) {
  final ticketId = state.pathParameters['ticketId'] ?? '';
  final base = FBreadcrumbItem(
    onPress: () => context.go(ticketsRoute),
    child: Text(l10n.navTickets),
  );
  final workspaceId = ref.watch(activeWorkspaceIdProvider);
  if (ticketId.isEmpty || workspaceId == null) {
    return [base, const FBreadcrumbItem(current: true, child: Text('…'))];
  }
  final ticketAsync = ref.watch(
    ticketByIdProvider((workspaceId: workspaceId, ticketId: ticketId)),
  );
  return ticketAsync.maybeWhen(
    data: (ticket) => [
      base,
      FBreadcrumbItem(current: true, child: Text(ticket?.title ?? '…')),
    ],
    orElse: () => [base, const FBreadcrumbItem(current: true, child: Text('…'))],
  );
}

List<FBreadcrumbItem> _projectOverviewCrumbs(
  WidgetRef ref,
  BuildContext context,
  GoRouterState state,
  AppLocalizations l10n,
) {
  final projectId = state.pathParameters['projectId'] ?? '';
  final base = FBreadcrumbItem(
    onPress: () => context.go(ticketsRoute),
    child: Text(l10n.navTickets),
  );
  final workspaceId = ref.watch(activeWorkspaceIdProvider);
  if (projectId.isEmpty || workspaceId == null) {
    return [base, const FBreadcrumbItem(current: true, child: Text('…'))];
  }
  final project = ref.watch(
    projectByIdProvider((workspaceId: workspaceId, projectId: projectId)),
  );
  return [
    base,
    FBreadcrumbItem(current: true, child: Text(project?.name ?? '…')),
  ];
}

// ─── Pipelines ────────────────────────────────────────────────────────────────

List<FBreadcrumbItem> _pipelinesCrumbs(
  WidgetRef ref,
  BuildContext context,
  GoRouterState state,
  AppLocalizations l10n,
) => [FBreadcrumbItem(current: true, child: Text(l10n.pipelinesScreenTitle))];

List<FBreadcrumbItem> _runPipelineCrumbs(
  WidgetRef ref,
  BuildContext context,
  GoRouterState state,
  AppLocalizations l10n,
) => [
  FBreadcrumbItem(
    onPress: () => context.go(pipelinesRoute),
    child: Text(l10n.pipelinesScreenTitle),
  ),
  FBreadcrumbItem(current: true, child: Text(l10n.pipelinesRunPipeline)),
];

List<FBreadcrumbItem> _pipelineRunDetailCrumbs(
  WidgetRef ref,
  BuildContext context,
  GoRouterState state,
  AppLocalizations l10n,
) {
  final runId = state.pathParameters['runId'] ?? '';
  final base = FBreadcrumbItem(
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
    return [base, const FBreadcrumbItem(current: true, child: Text('…'))];
  }
  final definition = ref
      .watch(pipelineTemplatesProvider(run.workspaceId))
      .value
      ?.where((t) => t.templateId == run.templateId)
      .firstOrNull;
  final label = definition?.name ?? run.templateId;
  return [base, FBreadcrumbItem(current: true, child: Text(label))];
}

// ─── Pull requests ────────────────────────────────────────────────────────────

List<FBreadcrumbItem> _pullRequestsListCrumbs(
  WidgetRef ref,
  BuildContext context,
  GoRouterState state,
  AppLocalizations l10n,
) => [FBreadcrumbItem(current: true, child: Text(l10n.pullRequests))];

List<FBreadcrumbItem> _pullRequestDetailCrumbs(
  WidgetRef ref,
  BuildContext context,
  GoRouterState state,
  AppLocalizations l10n,
) {
  final raw = state.pathParameters['prNumber'] ?? '';
  final prNumber = int.tryParse(raw);
  final base = FBreadcrumbItem(
    onPress: () => context.go(pullRequestsRoute),
    child: Text(l10n.pullRequests),
  );
  if (prNumber == null) {
    return [base, FBreadcrumbItem(current: true, child: Text('#$raw'))];
  }
  final prAsync = ref.watch(prDetailProvider(prNumber));
  return prAsync.maybeWhen(
    data: (pr) {
      if (pr == null) {
        return [
          base,
          FBreadcrumbItem(current: true, child: Text('#$prNumber')),
        ];
      }
      final created = pr.createdAt;
      final timeStr = created != null ? ', ${formatRelative(created)}' : '';
      final login = pr.author?.login ?? '';
      final label = '#${pr.number} opened by $login$timeStr';
      return [
        base,
        FBreadcrumbItem(
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
      FBreadcrumbItem(current: true, child: Text('#$prNumber')),
    ],
  );
}

// ─── Settings subtree ─────────────────────────────────────────────────────────

FBreadcrumbItem _settingsRoot(BuildContext context, AppLocalizations l10n) =>
    FBreadcrumbItem(
      onPress: () => context.go(settingsAppearanceRoute),
      child: Text(l10n.settingsLabel),
    );

List<FBreadcrumbItem> _settingsAppearanceCrumbs(
  WidgetRef ref,
  BuildContext context,
  GoRouterState state,
  AppLocalizations l10n,
) => [
  _settingsRoot(context, l10n),
  FBreadcrumbItem(current: true, child: Text(l10n.appearance)),
];

List<FBreadcrumbItem> _settingsNotificationsCrumbs(
  WidgetRef ref,
  BuildContext context,
  GoRouterState state,
  AppLocalizations l10n,
) => [
  _settingsRoot(context, l10n),
  FBreadcrumbItem(current: true, child: Text(l10n.notifications)),
];

List<FBreadcrumbItem> _settingsIntegrationsCrumbs(
  WidgetRef ref,
  BuildContext context,
  GoRouterState state,
  AppLocalizations l10n,
) => [
  _settingsRoot(context, l10n),
  FBreadcrumbItem(current: true, child: Text(l10n.integrations)),
];

List<FBreadcrumbItem> _settingsAdvancedCrumbs(
  WidgetRef ref,
  BuildContext context,
  GoRouterState state,
  AppLocalizations l10n,
) => [
  _settingsRoot(context, l10n),
  FBreadcrumbItem(current: true, child: Text(l10n.advanced)),
];

List<FBreadcrumbItem> _settingsAdaptersCrumbs(
  WidgetRef ref,
  BuildContext context,
  GoRouterState state,
  AppLocalizations l10n,
) => [
  _settingsRoot(context, l10n),
  FBreadcrumbItem(current: true, child: Text(l10n.adapters)),
];

List<FBreadcrumbItem> _settingsAgentsCrumbs(
  WidgetRef ref,
  BuildContext context,
  GoRouterState state,
  AppLocalizations l10n,
) => [
  _settingsRoot(context, l10n),
  FBreadcrumbItem(current: true, child: Text(l10n.agentRegistry)),
];

List<FBreadcrumbItem> _settingsReposCrumbs(
  WidgetRef ref,
  BuildContext context,
  GoRouterState state,
  AppLocalizations l10n,
) => [
  _settingsRoot(context, l10n),
  FBreadcrumbItem(current: true, child: Text(l10n.repositories)),
];

List<FBreadcrumbItem> _settingsSkillsCrumbs(
  WidgetRef ref,
  BuildContext context,
  GoRouterState state,
  AppLocalizations l10n,
) => [
  _settingsRoot(context, l10n),
  FBreadcrumbItem(current: true, child: Text(l10n.skills)),
];

List<FBreadcrumbItem> _settingsKeybindingsCrumbs(
  WidgetRef ref,
  BuildContext context,
  GoRouterState state,
  AppLocalizations l10n,
) => [
  _settingsRoot(context, l10n),
  FBreadcrumbItem(current: true, child: Text(l10n.keybindings)),
];

List<FBreadcrumbItem> _settingsSandboxingCrumbs(
  WidgetRef ref,
  BuildContext context,
  GoRouterState state,
  AppLocalizations l10n,
) => [
  _settingsRoot(context, l10n),
  FBreadcrumbItem(current: true, child: Text(l10n.sandboxing)),
];

List<FBreadcrumbItem> _settingsPipelinesCrumbs(
  WidgetRef ref,
  BuildContext context,
  GoRouterState state,
  AppLocalizations l10n,
) => [
  _settingsRoot(context, l10n),
  FBreadcrumbItem(current: true, child: Text(l10n.pipelineTemplatesTitle)),
];

List<FBreadcrumbItem> _pipelineTemplateEditorCrumbs(
  WidgetRef ref,
  BuildContext context,
  GoRouterState state,
  AppLocalizations l10n,
) {
  final templateId = state.pathParameters['templateId'] ?? '';
  final base = [
    _settingsRoot(context, l10n),
    FBreadcrumbItem(
      onPress: () => context.go(settingsPipelinesRoute),
      child: Text(l10n.pipelineTemplatesTitle),
    ),
  ];
  final workspaceId = ref.watch(activeWorkspaceIdProvider);
  if (workspaceId == null || templateId.isEmpty) {
    return [...base, FBreadcrumbItem(current: true, child: Text(templateId))];
  }
  final templatesAsync = ref.watch(pipelineTemplatesProvider(workspaceId));
  return templatesAsync.maybeWhen(
    data: (templates) {
      final template = templates
          .where((t) => t.templateId == templateId)
          .firstOrNull;
      return [
        ...base,
        FBreadcrumbItem(
          current: true,
          child: Text(template?.name ?? templateId),
        ),
      ];
    },
    orElse: () => [
      ...base,
      FBreadcrumbItem(current: true, child: Text(templateId)),
    ],
  );
}

List<FBreadcrumbItem> _settingsTeamsCrumbs(
  WidgetRef ref,
  BuildContext context,
  GoRouterState state,
  AppLocalizations l10n,
) => [
  _settingsRoot(context, l10n),
  FBreadcrumbItem(current: true, child: Text(l10n.teamsTitle)),
];

// ─── User profile ─────────────────────────────────────────────────────────────

List<FBreadcrumbItem> _userProfileCrumbs(
  WidgetRef ref,
  BuildContext context,
  GoRouterState state,
  AppLocalizations l10n,
) {
  final login = state.pathParameters['login'] ?? '';
  return [
    FBreadcrumbItem(child: Text(l10n.usersLabel)),
    FBreadcrumbItem(current: true, child: Text(login)),
  ];
}

// ─── Workspace detail ─────────────────────────────────────────────────────────

List<FBreadcrumbItem> _workspaceDetailCrumbs(
  WidgetRef ref,
  BuildContext context,
  GoRouterState state,
  AppLocalizations l10n,
) {
  final id = state.pathParameters['workspaceId'] ?? '';
  final base = FBreadcrumbItem(
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
  return [base, FBreadcrumbItem(current: true, child: Text(label))];
}
