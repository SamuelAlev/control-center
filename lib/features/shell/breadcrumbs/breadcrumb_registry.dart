import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/calendar/presentation/providers/calendar_ui_providers.dart';
import 'package:control_center/features/meetings/providers/meeting_providers.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/newsfeed/providers/newsfeed_providers.dart';
import 'package:control_center/features/pipelines/presentation/widgets/pipeline_status_badge.dart';
import 'package:control_center/features/pipelines/providers/pipeline_providers.dart';
import 'package:control_center/features/pr_review/presentation/utils/review_status_palette.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_status_badge.dart';
import 'package:control_center/features/pr_review/providers/pr_ref_route.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/features/settings/settings_nav.dart';
import 'package:control_center/features/ticketing/providers/ticketing_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/widgets/pr_title_text.dart';
import 'package:flutter/widgets.dart';
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
  inboxRoute(workspaceIdParam): _inboxCrumbs,
  pullRequestsRoute(workspaceIdParam): _pullRequestsListCrumbs,
  '${pullRequestsRoute(workspaceIdParam)}/:owner/:repo/:prNumber':
      _pullRequestDetailCrumbs,
  spacesRoute(workspaceIdParam): _spacesCrumbs,
  '${spacesRoute(workspaceIdParam)}/:spaceId': _spacesCrumbs,
  ticketsRoute(workspaceIdParam): _ticketsCrumbs,
  '${ticketsRoute(workspaceIdParam)}/:ticketId': _ticketDetailCrumbs,
  projectOverviewRoute(workspaceIdParam, ':projectId'): _projectOverviewCrumbs,
  pipelinesRoute(workspaceIdParam): _pipelinesCrumbs,
  runPipelineRoute(workspaceIdParam): _runPipelineCrumbs,
  '${pipelinesRoute(workspaceIdParam)}/:runId': _pipelineRunDetailCrumbs,
  plansRoute(workspaceIdParam): _plansCrumbs,
  '${plansRoute(workspaceIdParam)}/:kind/:id': _planStudioCrumbs,
  newsfeedRoute(workspaceIdParam): _newsfeedHomeCrumbs,
  '${newsfeedRoute(workspaceIdParam)}/article/:articleId':
      _newsfeedArticleCrumbs,
  meetingsRoute(workspaceIdParam): _meetingsCrumbs,
  '${meetingsRoute(workspaceIdParam)}/record': _meetingRecordCrumbs,
  '${meetingsRoute(workspaceIdParam)}/:meetingId': _meetingDetailCrumbs,
  calendarRoute(workspaceIdParam): _calendarCrumbs,
  '${calendarRoute(workspaceIdParam)}/:eventId': _calendarEventDetailCrumbs,
  memoryRoute(workspaceIdParam): _memoryCrumbs,
  apiKeysRoute(workspaceIdParam): _apiKeysCrumbs,
  // Settings breadcrumbs are DERIVED from `kSettingsNav`, so a page cannot
  // move between scopes and leave a stale trail. Each is three deep —
  // Settings › <scope> › <page> — which is what makes the scope legible from
  // the crumb alone, not just from the sidebar you may have navigated away
  // from. Pipelines keeps a bespoke builder: a foreign feature that merely
  // lives under `/settings` and has a child route.
  for (final group in kSettingsNav)
    for (final entry in group.items)
      if (entry.id != 'workspace.pipelines')
        entry.route(workspaceIdParam): _settingsCrumbsFor(group, entry),
  settingsPipelinesRoute(workspaceIdParam): _settingsPipelinesCrumbs,
  '${settingsPipelinesRoute(workspaceIdParam)}/:templateId':
      _pipelineTemplateEditorCrumbs,
  userProfileRoute(workspaceIdParam, ':login'): _userProfileCrumbs,
  workspaceListRoute: _manageWorkspacesCrumbs,
};

// ─── Inbox ──────────────────────────────────────────────────────────────────

List<CcBreadcrumbItem> _inboxCrumbs(
  WidgetRef ref,
  BuildContext context,
  GoRouterState state,
  AppLocalizations l10n,
) => [CcBreadcrumbItem(current: true, child: Text(l10n.inboxTitle))];

List<CcBreadcrumbItem> _spacesCrumbs(
  WidgetRef ref,
  BuildContext context,
  GoRouterState state,
  AppLocalizations l10n,
) {
  final w = state.pathParameters['workspaceId']!;
  // The URL is the source of truth for the open space.
  final selectedId = state.pathParameters['spaceId'];
  if (selectedId == null) {
    return [
      CcBreadcrumbItem(current: true, child: Text(l10n.navConversations)),
    ];
  }
  final workspaceId = ref.watch(activeWorkspaceIdProvider);
  final spaces = workspaceId != null
      ? ref.watch(workspaceSpacesProvider(workspaceId)).value ?? const []
      : ref.watch(spacesProvider).value ?? const [];
  final space = spaces.where((c) => c.id == selectedId).firstOrNull;
  if (space == null) {
    return [
      CcBreadcrumbItem(current: true, child: Text(l10n.navConversations)),
    ];
  }
  final label = space.name.isNotEmpty ? space.name : l10n.spaceLabel;
  return [
    CcBreadcrumbItem(
      onPress: () => context.go(spacesRoute(w)),
      child: Text(l10n.navConversations),
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

List<CcBreadcrumbItem> _newsfeedArticleCrumbs(
  WidgetRef ref,
  BuildContext context,
  GoRouterState state,
  AppLocalizations l10n,
) {
  final base = CcBreadcrumbItem(
    onPress: () =>
        context.go(newsfeedRoute(state.pathParameters['workspaceId']!)),
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
    onPress: () =>
        context.go(meetingsRoute(state.pathParameters['workspaceId']!)),
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
    onPress: () =>
        context.go(meetingsRoute(state.pathParameters['workspaceId']!)),
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
    onPress: () =>
        context.go(calendarRoute(state.pathParameters['workspaceId']!)),
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
) => [
  _settingsRoot(context, state, l10n),
  CcBreadcrumbItem(current: true, child: Text(l10n.navMemory)),
];

List<CcBreadcrumbItem> _apiKeysCrumbs(
  WidgetRef ref,
  BuildContext context,
  GoRouterState state,
  AppLocalizations l10n,
) => [CcBreadcrumbItem(current: true, child: Text(l10n.apiKeys))];

List<CcBreadcrumbItem> _manageWorkspacesCrumbs(
  WidgetRef ref,
  BuildContext context,
  GoRouterState state,
  AppLocalizations l10n,
) => [CcBreadcrumbItem(current: true, child: Text(l10n.manageWorkspaces))];

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
    onPress: () =>
        context.go(ticketsRoute(state.pathParameters['workspaceId']!)),
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
    onPress: () =>
        context.go(ticketsRoute(state.pathParameters['workspaceId']!)),
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

List<CcBreadcrumbItem> _plansCrumbs(
  WidgetRef ref,
  BuildContext context,
  GoRouterState state,
  AppLocalizations l10n,
) => [CcBreadcrumbItem(current: true, child: Text(l10n.plansTitle))];

List<CcBreadcrumbItem> _planStudioCrumbs(
  WidgetRef ref,
  BuildContext context,
  GoRouterState state,
  AppLocalizations l10n,
) => [
  CcBreadcrumbItem(
    onPress: () => context.go(plansRoute(state.pathParameters['workspaceId']!)),
    child: Text(l10n.plansTitle),
  ),
  CcBreadcrumbItem(current: true, child: Text(l10n.planStudioTitle)),
];

List<CcBreadcrumbItem> _runPipelineCrumbs(
  WidgetRef ref,
  BuildContext context,
  GoRouterState state,
  AppLocalizations l10n,
) => [
  CcBreadcrumbItem(
    onPress: () =>
        context.go(pipelinesRoute(state.pathParameters['workspaceId']!)),
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
    onPress: () =>
        context.go(pipelinesRoute(state.pathParameters['workspaceId']!)),
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
  return [
    base,
    CcBreadcrumbItem(
      current: true,
      // The run page has no title header of its own, so this segment carries
      // both identities: what ran and how it ended. The label flexes so it
      // ellipsizes rather than pushing the status pill off the bar.
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 8),
          PipelineStatusBadge.forRun(status: run.status),
        ],
      ),
    ),
  ];
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
  final prRef = prRefFromRouteState(state);
  final base = CcBreadcrumbItem(
    onPress: () =>
        context.go(pullRequestsRoute(state.pathParameters['workspaceId']!)),
    child: Text(l10n.pullRequests),
  );
  if (prRef == null) {
    return [base, CcBreadcrumbItem(current: true, child: Text('#$raw'))];
  }
  final prAsync = ref.watch(prDetailProvider(prRef));
  return prAsync.maybeWhen(
    data: (pr) {
      if (pr == null) {
        return [
          base,
          CcBreadcrumbItem(current: true, child: Text('#${prRef.number}')),
        ];
      }
      final hasDelta = pr.additions > 0 || pr.deletions > 0;
      return [
        base,
        CcBreadcrumbItem(
          current: true,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Status (draft/open/closed/merged) as a colour-coded icon only —
              // no badge chrome — leading the segment.
              PrStatusIcon(pr: pr, size: 14),
              const SizedBox(width: 8),
              // The title is the only variable-length part; let it flex so it
              // ellipsizes to fit and never pushes the line counts off the edge.
              // (CcBreadcrumb makes this final segment width-bounded.)
              Flexible(
                child: PrTitleText(
                  pr.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Diff size (+added −removed), colour-coded, after the title.
              if (hasDelta) ...[
                const SizedBox(width: 10),
                Text(
                  '+${pr.additions}',
                  style: const TextStyle(
                    color: ReviewStatusColors.success,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '−${pr.deletions}',
                  style: const TextStyle(
                    color: ReviewStatusColors.failure,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
      ];
    },
    orElse: () => [
      base,
      CcBreadcrumbItem(current: true, child: Text('#${prRef.number}')),
    ],
  );
}

// ─── Settings subtree ─────────────────────────────────────────────────────────

CcBreadcrumbItem _settingsRoot(
  BuildContext context,
  GoRouterState state,
  AppLocalizations l10n,
) => CcBreadcrumbItem(
  onPress: () =>
      context.go(settingsProfileRoute(state.pathParameters['workspaceId']!)),
  child: Text(l10n.settingsLabel),
);

/// Builds `Settings › <scope> › <page>` for one nav entry.
///
/// Replaces seventeen near-identical hand-written builders. The scope crumb is
/// new: it states who a change on this page affects even when you arrived by
/// deep link and never saw the sidebar grouping. It links back to the scope's
/// first page rather than being inert, so the trail stays navigable.
BreadcrumbBuilder _settingsCrumbsFor(
  SettingsNavGroup group,
  SettingsNavItem entry,
) =>
    (ref, context, state, l10n) => [
      _settingsRoot(context, state, l10n),
      CcBreadcrumbItem(
        onPress: () => context.go(
          group.items.first.route(state.pathParameters['workspaceId']!),
        ),
        child: Text(group.label(l10n)),
      ),
      CcBreadcrumbItem(current: true, child: Text(entry.label(l10n))),
    ];

List<CcBreadcrumbItem> _settingsPipelinesCrumbs(
  WidgetRef ref,
  BuildContext context,
  GoRouterState state,
  AppLocalizations l10n,
) => [
  _settingsRoot(context, state, l10n),
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
    _settingsRoot(context, state, l10n),
    CcBreadcrumbItem(
      onPress: () => context.go(
        settingsPipelinesRoute(state.pathParameters['workspaceId']!),
      ),
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
