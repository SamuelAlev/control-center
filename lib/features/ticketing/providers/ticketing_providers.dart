import 'package:control_center/core/constants/app_constants.dart';
import 'package:control_center/core/network/app_network.dart';
import 'package:control_center/core/providers/provider.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/agents/domain/services/agent_readiness_checker.dart';
import 'package:control_center/features/auth/providers/auth_providers.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/pipelines/providers/pipeline_providers.dart';
import 'package:control_center/features/ticketing/data/providers/clickup/clickup_ticket_adapter.dart';
import 'package:control_center/features/ticketing/data/providers/jira/jira_ticket_adapter.dart';
import 'package:control_center/features/ticketing/data/providers/linear/linear_ticket_adapter.dart';
import 'package:control_center/features/ticketing/data/providers/local/local_ticket_adapter.dart';
import 'package:control_center/features/ticketing/data/repositories/dao_project_repository.dart';
import 'package:control_center/features/ticketing/data/repositories/dao_ticket_link_repository.dart';
import 'package:control_center/features/ticketing/data/repositories/dao_ticket_repository.dart';
import 'package:control_center/features/ticketing/data/services/ticket_sync_service.dart';
import 'package:control_center/features/ticketing/domain/entities/project.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket_collaborator.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket_link.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket_provider.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket_status.dart';
import 'package:control_center/features/ticketing/domain/ports/ticket_provider_port.dart';
import 'package:control_center/features/ticketing/domain/repositories/project_repository.dart';
import 'package:control_center/features/ticketing/domain/repositories/ticket_link_repository.dart';
import 'package:control_center/features/ticketing/domain/repositories/ticket_repository.dart';
import 'package:control_center/features/ticketing/domain/services/project_service.dart';
import 'package:control_center/features/ticketing/domain/services/ticket_channel_service.dart';
import 'package:control_center/features/ticketing/domain/services/ticket_dispatcher.dart';
import 'package:control_center/features/ticketing/domain/services/ticket_link_service.dart';
import 'package:control_center/features/ticketing/domain/services/ticket_remote_sync_handler.dart';
import 'package:control_center/features/ticketing/domain/services/ticket_resume_listener.dart';
import 'package:control_center/features/ticketing/domain/services/ticket_workflow_service.dart';
import 'package:control_center/features/ticketing/presentation/ticket_view_mode.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provides the [TicketRepository].
final ticketRepositoryProvider = Provider<TicketRepository>((ref) {
  return DaoTicketRepository(ref.watch(ticketDaoProvider));
});

/// Provides the [TicketLinkRepository].
final ticketLinkRepositoryProvider = Provider<TicketLinkRepository>((ref) {
  return DaoTicketLinkRepository(ref.watch(ticketLinkDaoProvider));
});

/// Provides the [ProjectRepository].
final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  return DaoProjectRepository(ref.watch(projectDaoProvider));
});

/// Provides the [TicketLinkService].
final ticketLinkServiceProvider = Provider<TicketLinkService>((ref) {
  return TicketLinkService(
    linkRepository: ref.watch(ticketLinkRepositoryProvider),
    ticketRepository: ref.watch(ticketRepositoryProvider),
  );
});

/// Provides the [ProjectService].
final projectServiceProvider = Provider<ProjectService>((ref) {
  return ProjectService(repository: ref.watch(projectRepositoryProvider));
});

/// Dio for the Linear adapter, authorized with the stored ticketing key.
/// Adapter-scoped — only the Linear adapter pool entry consumes it.
final _linearTicketDioProvider = Provider<Dio>((ref) {
  final dio = createDio(baseUrl: 'https://api.linear.app/graphql');
  final creds = ref.watch(credentialsProvider).maybeWhen(
        data: (c) => c,
        orElse: () => null,
      );
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final key = creds?.ticketingApiKey ?? '';
        if (key.isNotEmpty) {
          options.headers['Authorization'] = key;
        }
        handler.next(options);
      },
    ),
  );
  return dio;
});

/// The active ticket provider chosen during onboarding.
final activeTicketProviderProvider = Provider<TicketProvider>((ref) {
  final creds = ref.watch(credentialsProvider).maybeWhen(
        data: (c) => c,
        orElse: () => null,
      );
  return TicketProvider.fromStorage(creds?.ticketingProviderId);
});

/// All adapter implementations (the `SandboxPort` pool analogue).
final ticketProviderAdaptersPoolProvider =
    Provider<List<TicketProviderPort>>((ref) {
  return <TicketProviderPort>[
    LocalTicketAdapter(ref.watch(ticketRepositoryProvider)),
    LinearTicketAdapter(ref.watch(_linearTicketDioProvider)),
    const JiraTicketAdapter(),
    const ClickUpTicketAdapter(),
  ];
});

/// Resolves the [TicketProviderPort] for the active provider, falling back to
/// the always-available local adapter.
final ticketProviderPortProvider = Provider<TicketProviderPort>((ref) {
  final active = ref.watch(activeTicketProviderProvider);
  final pool = ref.watch(ticketProviderAdaptersPoolProvider);
  return pool.firstWhere(
    (a) => a.provider == active,
    orElse: () =>
        pool.firstWhere((a) => a.provider == TicketProvider.local),
  );
});

/// Provides the [TicketWorkflowService].
final ticketWorkflowServiceProvider = Provider<TicketWorkflowService>((ref) {
  return TicketWorkflowService(
    repository: ref.watch(ticketRepositoryProvider),
    eventBus: ref.watch(domainEventBusProvider),
  );
});

/// Pushes local ticket changes to the active remote provider.
final ticketRemoteSyncHandlerProvider = Provider<TicketRemoteSyncHandler>((ref) {
  final handler = TicketRemoteSyncHandler(
    eventBus: ref.watch(domainEventBusProvider),
    repository: ref.watch(ticketRepositoryProvider),
    providerPort: ref.watch(ticketProviderPortProvider),
  );
  handler.start();
  ref.onDispose(handler.dispose);
  return handler;
});

/// Keeps the ticket remote sync handler alive across the app lifetime.
final ticketRemoteSyncAliveProvider = Provider<void>((ref) {
  ref.watch(ticketRemoteSyncHandlerProvider);
});

/// Pulls remote tickets into the local mirror (no-op for the local provider).
final ticketSyncServiceProvider = Provider<TicketSyncService>((ref) {
  return TicketSyncService(
    port: ref.watch(ticketProviderPortProvider),
    repository: ref.watch(ticketRepositoryProvider),
  );
});

/// Resumes suspended pipeline steps when their tickets reach terminal state.
final ticketResumeListenerProvider = Provider<TicketResumeListener>((ref) {
  final listener = TicketResumeListener(
    eventBus: ref.watch(domainEventBusProvider),
    ticketRepository: ref.watch(ticketRepositoryProvider),
    engine: ref.watch(pipelineEngineProvider),
  );
  listener.start();
  ref.onDispose(listener.dispose);
  return listener;
});

/// Keeps the ticket resume listener alive across the app lifetime.
final ticketResumeListenerAliveProvider = Provider<void>((ref) {
  ref.watch(ticketResumeListenerProvider);
});

/// Hooks tickets into messaging (lazy discussion channels + participants).
final ticketChannelServiceProvider = Provider<TicketChannelService>((ref) {
  final service = TicketChannelService(
    eventBus: ref.watch(domainEventBusProvider),
    ticketRepository: ref.watch(ticketRepositoryProvider),
    messagingPort: ref.watch(messagingServiceProvider),
  );
  service.start();
  ref.onDispose(service.dispose);
  return service;
});

/// Keeps the ticket channel service alive across the app lifetime.
final ticketChannelServiceAliveProvider = Provider<void>((ref) {
  ref.watch(ticketChannelServiceProvider);
});

/// Gates agent dispatch on readiness (adapter configured, etc.).
final agentReadinessCheckerProvider = Provider<AgentReadinessChecker>((ref) {
  return AgentReadinessChecker(
    agentRepository: ref.watch(agentRepositoryProvider),
  );
});

/// The single owner of "assigned ticket → dispatched agent". Listens to
/// `TicketAssigned` and runs readiness → channel → start → dispatch exactly
/// once per assignment.
final ticketDispatcherProvider = Provider<TicketDispatcher>((ref) {
  final dispatcher = TicketDispatcher(
    eventBus: ref.watch(domainEventBusProvider),
    ticketRepository: ref.watch(ticketRepositoryProvider),
    ticketWorkflow: ref.watch(ticketWorkflowServiceProvider),
    messagingPort: ref.watch(messagingServiceProvider),
    readinessChecker: ref.watch(agentReadinessCheckerProvider),
    repoProvisioner: ref.watch(repoWorkspaceProvisionerProvider),
  );
  dispatcher.start();
  ref.onDispose(dispatcher.dispose);
  return dispatcher;
});

/// Keeps the ticket dispatcher alive across the app lifetime.
final ticketDispatcherAliveProvider = Provider<void>((ref) {
  ref.watch(ticketDispatcherProvider);
});

// --- UI providers (mirror messaging_providers.dart shapes) ---

/// Watches all tickets in a workspace.
final workspaceTicketsProvider =
    StreamProvider.family<List<Ticket>, String>((ref, workspaceId) {
  // Trigger a remote pull on first watch (local provider is a no-op).
  ref.watch(ticketSyncServiceProvider).sync(workspaceId);
  return ref.watch(ticketRepositoryProvider).watchForWorkspace(workspaceId);
});

/// Watches a single ticket by id.
final ticketByIdProvider =
    StreamProvider.family<Ticket?, ({String workspaceId, String ticketId})>(
        (ref, args) {
  return ref
      .watch(ticketRepositoryProvider)
      .watchForWorkspace(args.workspaceId)
      .map((tickets) =>
          tickets.where((t) => t.id == args.ticketId).firstOrNull);
});

/// Watches the collaborators of a ticket.
final ticketCollaboratorsProvider = StreamProvider.autoDispose
    .family<List<TicketCollaborator>, String>((ref, ticketId) {
  return ref.watch(ticketRepositoryProvider).watchCollaborators(ticketId);
});

/// Watches all projects in a workspace (newest first, includes archived).
final workspaceProjectsProvider =
    StreamProvider.family<List<Project>, String>((ref, workspaceId) {
  return ref.watch(projectRepositoryProvider).watchForWorkspace(workspaceId);
});

/// Resolves a single project from the workspace projects stream.
final projectByIdProvider =
    Provider.family<Project?, ({String workspaceId, String projectId})>(
        (ref, args) {
  final projects =
      ref.watch(workspaceProjectsProvider(args.workspaceId)).asData?.value ??
          const <Project>[];
  return projects.where((p) => p.id == args.projectId).firstOrNull;
});

/// Watches the dependency links touching a ticket, scoped to its workspace.
final ticketLinksProvider = StreamProvider.autoDispose
    .family<List<TicketLink>, ({String workspaceId, String ticketId})>(
        (ref, args) {
  return ref
      .watch(ticketLinkRepositoryProvider)
      .watchForTicket(args.workspaceId, args.ticketId);
});

/// Watches tickets assigned to the human user (`user` sentinel).
final myAssignedTicketsProvider =
    StreamProvider.family<List<Ticket>, String>((ref, workspaceId) {
  return ref.watch(ticketRepositoryProvider).watchForWorkspace(workspaceId).map(
        (tickets) => tickets
            .where((t) => t.assignedAgentId == TicketCollaborator.userSentinel)
            .toList(),
      );
});

/// The currently selected ticket id (drives the detail pane).
final selectedTicketIdProvider =
    NotifierProvider<SelectedTicketNotifier, String?>(
  SelectedTicketNotifier.new,
);

/// Holds the selected ticket id.
class SelectedTicketNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  /// Selects [ticketId] (or clears with null).
  void select(String? ticketId) => state = ticketId;
}

/// Groups a workspace's tickets by the board columns shown in the UI.
final ticketBoardProvider = Provider.family<
    AsyncValue<Map<TicketStatus, List<Ticket>>>, String>((ref, workspaceId) {
  return ref.watch(workspaceTicketsProvider(workspaceId)).whenData((tickets) {
    final board = <TicketStatus, List<Ticket>>{
      for (final column in ticketBoardColumns) column: <Ticket>[],
    };
    for (final ticket in tickets) {
      final column = ticketBoardColumnFor(ticket.status);
      board[column]!.add(ticket);
    }
    return board;
  });
});

/// The ordered board columns shown in the UI.
const ticketBoardColumns = <TicketStatus>[
  TicketStatus.backlog,
  TicketStatus.open,
  TicketStatus.inProgress,
  TicketStatus.inReview,
  TicketStatus.done,
];

/// Folds the eight statuses onto the five visible columns (blocked → in
/// progress; failed/cancelled → done).
TicketStatus ticketBoardColumnFor(TicketStatus status) => switch (status) {
      TicketStatus.blocked => TicketStatus.inProgress,
      TicketStatus.failed => TicketStatus.done,
      TicketStatus.cancelled => TicketStatus.done,
      _ => status,
    };

/// The persisted tickets-screen view mode (list vs board). Defaults to
/// [TicketViewMode.list]; the user's choice is the saved default.
final ticketViewModeProvider =
    NotifierProvider<TicketViewModeNotifier, TicketViewMode>(
  TicketViewModeNotifier.new,
);

/// Reads/writes the tickets-screen view mode preference, mirroring the
/// `ThemeNotifier` SharedPreferences pattern.
class TicketViewModeNotifier extends Notifier<TicketViewMode> {
  late SharedPreferences _prefs;

  @override
  TicketViewMode build() {
    _prefs = ref.watch(sharedPreferencesProvider);
    return TicketViewMode.fromStorage(_prefs.getString(ticketsViewModeKey));
  }

  /// Sets the view mode and persists it as the new default.
  void setMode(TicketViewMode mode) {
    if (mode == state) {
      return;
    }
    _prefs.setString(ticketsViewModeKey, mode.toStorageString());
    state = mode;
  }
}

/// The set of ticket ids currently selected for a bulk action in the list view.
/// Ephemeral (not persisted); cleared after a bulk action or a view switch.
final ticketSelectionProvider =
    NotifierProvider<TicketSelectionNotifier, Set<String>>(
  TicketSelectionNotifier.new,
);

/// Holds the multi-select set for bulk ticket actions.
class TicketSelectionNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  /// Toggles [ticketId] in/out of the selection.
  void toggle(String ticketId) {
    final next = Set<String>.from(state);
    if (!next.add(ticketId)) {
      next.remove(ticketId);
    }
    state = next;
  }

  /// Clears the selection.
  void clear() {
    if (state.isNotEmpty) {
      state = const {};
    }
  }
}
