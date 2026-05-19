import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_remote/app_icons.dart';
import 'package:cc_remote/providers.dart';
import 'package:cc_remote/screens/session_utils.dart';
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
                message: "Couldn't load tickets",
                description: e.toString(),
              ),
              data: (_) {
                if (tickets.isEmpty) {
                  return const CcEmptyState(
                    icon: AppIcons.ticket,
                    message: 'No tickets',
                    description: 'Tickets in this workspace appear here.',
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
                    _StatusBadge(status: ticket.status),
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
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          for (var i = 0; i < _filters.length; i++)
            Padding(
              padding: const EdgeInsets.only(right: 8, top: 8),
              child: CcChip(
                label: _filters[i].isEmpty
                    ? 'All'
                    : ticketStatusLabel(_filters[i]),
                selected: _filterIndex == i,
                onTap: () => setState(() => _filterIndex = i),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final variant = switch (status) {
      'done' => CcBadgeVariant.success,
      'blocked' => CcBadgeVariant.danger,
      'inReview' => CcBadgeVariant.info,
      'inProgress' => CcBadgeVariant.brand,
      _ => CcBadgeVariant.neutral,
    };
    return CcBadge(label: ticketStatusLabel(status), variant: variant);
  }
}

/// `/tickets/:id` — detail view with status change and assign/reassign. The
/// ticket is resolved from the live ticket stream so it updates in place.
class TicketDetailScreen extends ConsumerStatefulWidget {
  /// Creates a [TicketDetailScreen].
  const TicketDetailScreen({required this.ticketId, super.key});

  /// The ticket id from the route.
  final String ticketId;

  @override
  ConsumerState<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends ConsumerState<TicketDetailScreen> {
  bool _acting = false;
  bool _choosingAgent = false;
  String? _error;

  RemoteTicketRepository? _repo() {
    final client = ref.read(rpcClientProvider).value;
    return client == null ? null : RemoteTicketRepository(client);
  }

  Future<void> _changeStatus(TicketDto ticket, String status) async {
    if (ticket.status == status) {
      return;
    }
    await _run(() async {
      // tickets.update carries the FULL ticket + an optimistic-concurrency
      // version; round-trip the current row through JSON with the new status.
      final json = ticket.toJson()..['status'] = status;
      await _repo()?.update(
        TicketDto.fromJson(json),
        expectedVersion: ticket.version,
      );
    });
  }

  Future<void> _assign(AgentDto agent) async {
    final repo = _repo();
    if (repo == null) {
      return;
    }
    await _run(() async {
      await repo.assign(widget.ticketId, agentId: agent.id);
      if (mounted) {
        setState(() => _choosingAgent = false);
      }
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _acting = true;
      _error = null;
    });
    try {
      await action();
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _acting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final ticket = ref
        .watch(ticketsProvider)
        .value
        ?.where((tk) => tk.id == widget.ticketId)
        .firstOrNull;

    return SafeArea(
      child: ColoredBox(
        color: t.canvas,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _DetailHeader(title: ticket?.key ?? 'Ticket'),
            if (_choosingAgent)
              _AgentChooser(
                agents: ref.watch(agentsProvider).value ?? const [],
                onPick: _assign,
                onCancel: () => setState(() => _choosingAgent = false),
              )
            else if (ticket == null && _error == null)
              const Expanded(child: Center(child: CcSpinner(size: 24)))
            else if (ticket == null && _error != null)
              Expanded(
                child: CcEmptyState(
                  icon: AppIcons.triangleAlert,
                  message: "Couldn't load ticket",
                  description: _error,
                ),
              )
            else
              Expanded(child: _body(t, ticket!)),
          ],
        ),
      ),
    );
  }

  Widget _body(DesignSystemTokens t, TicketDto ticket) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          ticket.title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: t.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _StatusBadge(status: ticket.status),
            CcBadge(label: ticket.priority, variant: CcBadgeVariant.neutral),
            CcBadge(label: ticket.provider, variant: CcBadgeVariant.brand),
            if (ticket.assignee != null)
              CcBadge(label: 'Assigned to ${ticket.assignee}'),
          ],
        ),
        if (ticket.description != null &&
            ticket.description!.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(
            ticket.description!,
            style: TextStyle(fontSize: 14, height: 1.5, color: t.textSecondary),
          ),
        ],
        if (ticket.url != null) ...[
          const SizedBox(height: 16),
          CcButton(
            variant: CcButtonVariant.secondary,
            size: CcButtonSize.sm,
            icon: AppIcons.externalLink,
            onPressed: () => {},
            child: const Text('Open in browser'),
          ),
        ],
        const SizedBox(height: 24),
        Text(
          'Status',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: t.textTertiary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final s in ticketStatuses)
              CcChip(
                label: s.label,
                selected: ticket.status == s.value,
                onTap: _acting ? null : () => _changeStatus(ticket, s.value),
              ),
          ],
        ),
        const SizedBox(height: 20),
        CcButton(
          fullWidth: true,
          variant: CcButtonVariant.secondary,
          loading: _acting,
          icon: AppIcons.userCheck,
          onPressed: _acting ? null : () => setState(() => _choosingAgent = true),
          child: Text(ticket.assignee == null ? 'Assign' : 'Reassign'),
        ),
      ],
    );
  }
}

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.topbar,
        border: Border(bottom: BorderSide(color: t.borderSoft)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            CcTappable(
              onPressed: () => context.pop(),
              semanticLabel: 'Back',
              builder: (context, _) => Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(AppIcons.arrowLeft, color: t.fgSecondary),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: t.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AgentChooser extends StatelessWidget {
  const _AgentChooser({
    required this.agents,
    required this.onPick,
    required this.onCancel,
  });

  final List<AgentDto> agents;
  final ValueChanged<AgentDto> onPick;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Expanded(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (agents.isEmpty)
            const CcEmptyState(
              icon: AppIcons.user,
              message: 'No agents',
              description: 'Assign an agent from this workspace.',
            ),
          for (final a in agents)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: CcCard(
                interactive: true,
                semanticLabel: a.name,
                onPressed: () => onPick(a),
                child: Row(
                  children: [
                    Icon(AppIcons.user, size: 18, color: t.fgSecondary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        a.name,
                        style: TextStyle(fontSize: 15, color: t.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          CcButton(
            variant: CcButtonVariant.secondary,
            onPressed: onCancel,
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
