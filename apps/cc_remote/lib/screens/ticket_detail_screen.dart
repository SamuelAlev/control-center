import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_remote/app_icons.dart';
import 'package:cc_remote/external_link.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/providers.dart';
import 'package:cc_remote/screens/session_utils.dart';
import 'package:cc_remote/widgets/messaging/detail_header.dart';
import 'package:cc_remote/widgets/ticket_status_badge.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'ticket_agent_chooser.dart';

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
            DetailHeader(
              title: ticket?.key ?? AppLocalizations.of(context).ticket,
            ),
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
                  message: AppLocalizations.of(context).ticketLoadFailed,
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
    final l10n = AppLocalizations.of(context);
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
            TicketStatusBadge(status: ticket.status),
            CcBadge(label: ticket.priority, variant: CcBadgeVariant.neutral),
            CcBadge(label: ticket.provider, variant: CcBadgeVariant.brand),
            if (ticket.assignee != null)
              CcBadge(label: l10n.assignedTo(ticket.assignee!)),
          ],
        ),
        if (ticket.description != null && ticket.description!.isNotEmpty) ...[
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
            onPressed: () => openExternal(ticket.url),
            child: Text(l10n.openInBrowser),
          ),
        ],
        const SizedBox(height: 24),
        Text(
          l10n.status,
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
                label: ticketStatusLabel(l10n, s),
                selected: ticket.status == s,
                onPressed: _acting ? null : () => _changeStatus(ticket, s),
              ),
          ],
        ),
        const SizedBox(height: 20),
        CcButton(
          fullWidth: true,
          variant: CcButtonVariant.secondary,
          loading: _acting,
          icon: AppIcons.userCheck,
          onPressed: _acting
              ? null
              : () => setState(() => _choosingAgent = true),
          child: Text(ticket.assignee == null ? l10n.assign : l10n.reassign),
        ),
      ],
    );
  }
}
