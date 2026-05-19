import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/features/ticketing/domain/entities/project.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_collaborator.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_link.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_provider.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_status.dart';
import 'package:cc_domain/features/ticketing/domain/repositories/project_repository.dart';
import 'package:cc_domain/features/ticketing/domain/repositories/ticket_link_repository.dart';
import 'package:cc_domain/features/ticketing/domain/repositories/ticket_repository.dart';
import 'package:cc_domain/features/ticketing/domain/services/project_service.dart';
import 'package:cc_domain/features/ticketing/domain/services/ticket_link_service.dart';
import 'package:cc_domain/features/ticketing/domain/services/ticket_workflow_service.dart';
import 'package:control_center/core/constants/app_constants.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/features/auth/providers/auth_providers.dart';
import 'package:control_center/features/ticketing/presentation/ticket_view_mode.dart';
import 'package:control_center/features/ticketing/ticketing_bindings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides the [TicketRepository] over the unified RPC client seam — the
/// in-process host on desktop self-serve, a connected remote client on web /
/// desktop-connected-to-remote. Never touches Drift directly.
final ticketRepositoryProvider = Provider<TicketRepository>(
  (ref) => RpcTicketRepository(ref.watch(rpcClientProvider)),
);

/// Provides the [TicketLinkRepository] over the in-process RPC server (flipped
/// from Drift to the cc_data RpcX adapter as part of the composition flip).
final ticketLinkRepositoryProvider = Provider<TicketLinkRepository>((ref) {
  return RpcTicketLinkRepository(ref.watch(rpcClientProvider));
});

/// Provides the [ProjectRepository] over the in-process RPC server.
final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  return RpcProjectRepository(ref.watch(rpcClientProvider));
});

/// Provides the [TicketLinkService] (ticket dependency-link write path).
///
/// DECLARED here (web-safe; the service is pure cc_domain logic over repository
/// interfaces) and RESOLVED through the ticketing seam: on the VM it binds to
/// the server-side Drift `dao*` repos (the in-process MCP write path; routing it
/// over RPC would cycle through the host), on web it binds to the RPC repos so
/// the write works over RPC.
final ticketLinkServiceProvider = Provider<TicketLinkService>(
  buildTicketLinkService,
);

/// Provides the [ProjectService] (project write path; seamed like
/// [ticketLinkServiceProvider]).
final projectServiceProvider = Provider<ProjectService>(buildProjectService);

/// The active ticket provider chosen during onboarding.
final activeTicketProviderProvider = Provider<TicketProvider>((ref) {
  final creds = ref.watch(credentialsProvider).maybeWhen(
        data: (c) => c,
        orElse: () => null,
      );
  return TicketProvider.fromStorage(creds?.ticketingProviderId);
});

/// Provides the [TicketWorkflowService] — the ticket WRITE path
/// (create/update/assign/close). Seamed like [ticketLinkServiceProvider]: VM
/// binds Dao-backed (consumed by the MCP registry, so it can't go over RPC
/// there), web binds over RPC. Writes hit the same DB the in-process server
/// reads, so the UI's RPC-backed ticket streams still update live.
final ticketWorkflowServiceProvider = Provider<TicketWorkflowService>(
  buildTicketWorkflowService,
);

// --- UI providers (mirror messaging_providers.dart shapes) ---

/// Watches all tickets in a workspace.
final workspaceTicketsProvider =
    StreamProvider.family<List<Ticket>, String>((ref, workspaceId) {
  // Trigger a remote pull on first watch (local provider is a no-op; on web
  // the server owns the mirror so this is a no-op there).
  triggerTicketSync(ref, workspaceId);
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
/// `ThemeNotifier` AppPreferences pattern.
class TicketViewModeNotifier extends Notifier<TicketViewMode> {
  late AppPreferences _prefs;

  @override
  TicketViewMode build() {
    _prefs = ref.watch(appPreferencesProvider);
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
