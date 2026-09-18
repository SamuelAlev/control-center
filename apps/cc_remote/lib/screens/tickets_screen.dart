import 'package:cc_domain/cc_domain.dart';
import 'package:cc_remote/app_icons.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/providers.dart';
import 'package:cc_remote/screens/session_utils.dart';
import 'package:cc_remote/widgets/ticket_status_badge.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Tickets tab: live tickets (`tickets.watchForWorkspace`) with a status filter,
/// and pushes a detail route for status change / assignment.
class TicketsScreen extends ConsumerStatefulWidget {
  /// Creates a [TicketsScreen].
  const TicketsScreen({super.key});

  @override
  ConsumerState<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends ConsumerState<TicketsScreen> {
  final List<String> _filters = <String>[
    '',
    'open',
    'inProgress',
    'blocked',
    'done',
  ];
  int _filterIndex = 0;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final async = ref.watch(ticketsProvider);
    final status = _filters[_filterIndex];
    final tickets = (async.value ?? const <TicketDto>[])
        .where((tk) => status.isEmpty || tk.status == status)
        .toList();

    return ColoredBox(
      color: t.canvas,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _filterBar(t),
          Expanded(
            child: async.when(
              loading: () => const Center(child: CcSpinner(size: 24)),
              error: (e, _) => CcEmptyState(
                icon: AppIcons.triangleAlert,
                message: AppLocalizations.of(context).ticketsLoadFailed,
                description: e.toString(),
              ),
              data: (_) {
                if (tickets.isEmpty) {
                  return CcEmptyState(
                    icon: AppIcons.ticket,
                    message: AppLocalizations.of(context).noTickets,
                    description: AppLocalizations.of(
                      context,
                    ).ticketsEmptyDescription,
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: tickets.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) => _ticketCard(t, tickets[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _ticketCard(DesignSystemTokens t, TicketDto ticket) {
    return CcCard(
      interactive: true,
      semanticLabel: ticket.title,
      onPressed: () => context.push('/ticket/${ticket.id}'),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(AppIcons.ticket, size: 18, color: t.fgSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (ticket.key.isNotEmpty)
                  Text(
                    ticket.key,
                    style: TextStyle(fontSize: 12, color: t.textTertiary),
                  ),
                Text(
                  ticket.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: t.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    TicketStatusBadge(status: ticket.status),
                    if (ticket.assignee != null)
                      CcBadge(
                        label: ticket.assignee!,
                        variant: CcBadgeVariant.neutral,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterBar(DesignSystemTokens t) {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          for (var i = 0; i < _filters.length; i++)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8, top: 8),
              child: CcChip(
                label: _filters[i].isEmpty
                    ? l10n.all
                    : ticketStatusLabel(l10n, _filters[i]),
                selected: _filterIndex == i,
                onPressed: () => setState(() => _filterIndex = i),
              ),
            ),
        ],
      ),
    );
  }
}
