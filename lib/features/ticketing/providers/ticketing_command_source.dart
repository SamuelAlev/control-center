import 'package:cc_domain/features/ticketing/domain/entities/ticket.dart';
import 'package:control_center/features/ticketing/presentation/widgets/new_ticket_dialog.dart';
import 'package:control_center/features/ticketing/presentation/widgets/ticket_visuals.dart';
import 'package:control_center/features/ticketing/providers/ticketing_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/command_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Dynamic [CommandSource] that contributes ticketing items.
class TicketingCommandSource implements CommandSource {
  /// Test-only: override the tickets list directly to bypass StreamProvider timing.
  @visibleForTesting
  List<Ticket>? testTickets;

  @override
  String get id => 'ticketing';
  @override
  String get category => 'Tickets';
  @override
  bool get isDynamic => true;

  @override
  List<CommandItem> buildItems(BuildContext context, WidgetRef ref) {
    final router = GoRouter.of(context);
    final l10n = AppLocalizations.of(context);
    // Capture the setter at build time — the command palette pops (disposing
    // its element) before invoking onExecute, so `ref`/`context` must not be
    // used inside the callbacks.
    final selectTicket = ref.read(selectedTicketIdProvider.notifier).select;
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    final tickets = testTickets ??
        (workspaceId != null
            ? ref.watch(workspaceTicketsProvider(workspaceId)).value
            : null) ??
        const <Ticket>[];
    final items = <CommandItem>[];

    // Static "Go to tickets" entry.
    items.add(
      CommandItem(
        id: 'go-tickets',
        label: 'Go to Tickets',
        description: 'Navigate to the tickets board',
        icon: AppIcons.ticket,
        category: category,
        onExecute: () => router.go(
          workspaceId == null ? workspaceListRoute : ticketsRoute(workspaceId),
        ),
      ),
    );

    // Static "New ticket" entry.
    items.add(
      CommandItem(
        id: 'new-ticket',
        label: 'New ticket',
        description: 'Create a new ticket in the active workspace',
        icon: AppIcons.ticket,
        category: category,
        onExecute: () {
          final ctx = rootNavigatorKey.currentContext;
          if (ctx != null && workspaceId != null) {
            showNewTicketDialog(ctx, workspaceId: workspaceId);
          }
        },
      ),
    );

    // Map each ticket to a command item.
    for (final ticket in tickets) {
      final statusLabel = ticketStatusLabel(l10n, ticket.status);
      final desc = ticket.externalKey != null
          ? '${ticket.externalKey} · $statusLabel'
          : statusLabel;

      items.add(
        CommandItem(
          id: 'ticket-${ticket.id}',
          label: ticket.title,
          description: desc,
          icon: AppIcons.ticketCheck,
          category: category,
          onExecute: () {
            selectTicket(ticket.id);
            if (workspaceId != null) {
              router.go(ticketDetailRoute(workspaceId, ticket.id));
            }
          },
        ),
      );
    }

    return items;
  }
}

/// Provider for the ticketing command source.
final ticketingCommandSourceProvider = Provider<CommandSource>(
  (_) => TicketingCommandSource(),
);
